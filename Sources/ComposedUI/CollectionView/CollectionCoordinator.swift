import UIKit
import Composed

/// Conform to this protocol to receive `CollectionCoordinator` events
public protocol CollectionCoordinatorDelegate: class {

    /// Return a background view to be shown in the `UICollectionView` when its content is empty. Defaults to nil
    /// - Parameters:
    ///   - coordinator: The coordinator that manages this collection view
    ///   - collectionView: The collection view that will show this background view
    func coordinator(_ coordinator: CollectionCoordinator, backgroundViewInCollectionView collectionView: UICollectionView) -> UIView?

    /// Called whenever the coordinator's content updates
    /// - Parameter coordinator: The coordinator that manages the updates
    func coordinatorDidUpdate(_ coordinator: CollectionCoordinator)
}

public extension CollectionCoordinatorDelegate {
    func coordinator(_ coordinator: CollectionCoordinator, backgroundViewInCollectionView collectionView: UICollectionView) -> UIView? { return nil }
    func coordinatorDidUpdate(_ coordinator: CollectionCoordinator) { }
}

/// The coordinator that provides the 'glue' between a section provider and a `UICollectionView`
open class CollectionCoordinator: NSObject {

    /// Get/set the delegate for this coordinator
    public weak var delegate: CollectionCoordinatorDelegate? {
        didSet { collectionView.backgroundView = delegate?.coordinator(self, backgroundViewInCollectionView: collectionView) }
    }

    /// Returns the root section provider associated with this coordinator
    public var sectionProvider: SectionProvider {
        return mapper.provider
    }

    private var mapper: SectionProviderMapping

    private var defersUpdate: Bool = false
    private var sectionRemoves: [() -> Void] = []
    private var sectionInserts: [() -> Void] = []
    private var sectionUpdates: [() -> Void] = []

    private var removes: [() -> Void] = []
    private var inserts: [() -> Void] = []
    private var changes: [() -> Void] = []
    private var moves: [() -> Void] = []

    private let collectionView: UICollectionView

    private weak var originalDelegate: UICollectionViewDelegate?
    private var delegateObserver: NSKeyValueObservation?

    private weak var originalDataSource: UICollectionViewDataSource?
    private var dataSourceObserver: NSKeyValueObservation?

    private weak var originalDragDelegate: UICollectionViewDragDelegate?
    private var dragDelegateObserver: NSKeyValueObservation?

    private weak var originalDropDelegate: UICollectionViewDropDelegate?
    private var dropDelegateObserver: NSKeyValueObservation?

    private var cachedProviders: [CollectionElementsProvider] = []

    @available(iOS 13.0, *)
    private lazy var diffableDataSource: UICollectionViewDiffableDataSource<Int, AnyHashable> = {
        let dataSource = UICollectionViewDiffableDataSource<Int, AnyHashable>(collectionView: collectionView) { collectionView, indexPath, _ in
            return self.collectionView(collectionView, cellForItemAt: indexPath)
        }

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            return self.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        }

        return dataSource
    }()

    /// Make a new coordinator with the specified collectionView and sectionProvider
    /// - Parameters:
    ///   - collectionView: The collectionView to associate with this coordinator
    ///   - sectionProvider: The sectionProvider to associate with this coordinator
    public init(collectionView: UICollectionView, sectionProvider: SectionProvider) {
        self.collectionView = collectionView
        mapper = SectionProviderMapping(provider: sectionProvider)

        super.init()
        prepareSections(animated: false)

        if #available(iOS 13, *) {
            // do nothing
        } else {
            dataSourceObserver = collectionView.observe(\.dataSource, options: [.initial, .new]) { [weak self] collectionView, _ in
                guard collectionView.dataSource !== self else { return }
                self?.originalDataSource = collectionView.dataSource
                collectionView.dataSource = self
            }
        }

        delegateObserver = collectionView.observe(\.delegate, options: [.initial, .new]) { [weak self] collectionView, _ in
            guard collectionView.delegate !== self else { return }
            self?.originalDelegate = collectionView.delegate
            collectionView.delegate = self
        }

        dragDelegateObserver = collectionView.observe(\.dragDelegate, options: [.initial, .new]) { [weak self] collectionView, _ in
            guard collectionView.dragDelegate !== self else { return }
            self?.originalDragDelegate = collectionView.dragDelegate
            collectionView.dragDelegate = self
        }

        dropDelegateObserver = collectionView.observe(\.dropDelegate, options: [.initial, .new]) { [weak self] collectionView, _ in
            guard collectionView.dropDelegate !== self else { return }
            self?.originalDropDelegate = collectionView.dropDelegate
            collectionView.dropDelegate = self
        }

        collectionView.register(PlaceholderSupplementaryView.self,
                                forSupplementaryViewOfKind: PlaceholderSupplementaryView.kind,
                                withReuseIdentifier: PlaceholderSupplementaryView.reuseIdentifier)
    }

    /// Replaces the current sectionProvider with the specified provider
    /// - Parameter sectionProvider: The new sectionProvider
    open func replace(sectionProvider: SectionProvider) {
        mapper = SectionProviderMapping(provider: sectionProvider)
        prepareSections()

        if #available(iOS 13, *) {
            // do nothing
        } else {
            collectionView.reloadData()
        }
    }

    /// Enables / disables editing on this coordinator
    /// - Parameters:
    ///   - editing: True if editing should be enabled, false otherwise
    ///   - animated: If true, the change should be animated
    public func setEditing(_ editing: Bool, animated: Bool) {
        collectionView.indexPathsForSelectedItems?.forEach { collectionView.deselectItem(at: $0, animated: animated) }

        for (index, section) in sectionProvider.sections.enumerated() {
            guard let handler = section as? EditingHandler else { continue }
            handler.didSetEditing(editing)

            for item in 0..<section.numberOfElements {
                let indexPath = IndexPath(item: item, section: index)

                if let handler = handler as? CollectionEditingHandler, let cell = collectionView.cellForItem(at: indexPath) {
                    handler.didSetEditing(editing, at: item, cell: cell, animated: animated)
                } else {
                    handler.didSetEditing(editing, at: item)
                }
            }
        }
    }

    /// Invalidates the current layout with the specified context
    /// - Parameter context: The invalidation context to apply during the invalidate (optional)
    open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext? = nil) {
        guard collectionView.window != nil else { return }

        if let context = context {
            collectionView.collectionViewLayout.invalidateLayout(with: context)
        } else {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    open func invalidateVisibleCells() {
        for (indexPath, cell) in zip(collectionView.indexPathsForVisibleItems, collectionView.visibleCells) {
            let elements = elementsProvider(for: indexPath.section)
            elements.cell.configure(cell, indexPath.item, mapper.provider.sections[indexPath.section])
        }
    }

    // Prepares and caches the section to improve performance
    private func prepareSections(animated: Bool = true) {
        cachedProviders.removeAll()
        mapper.delegate = self

        for index in 0..<mapper.numberOfSections {
            guard let section = (mapper.provider.sections[index] as? CollectionSectionProvider)?.section(with: collectionView.traitCollection) else {
                fatalError("No provider available for section: \(index), or it does not conform to CollectionSectionProvider")
            }

            switch section.cell.dequeueMethod {
            case let .fromNib(type):
                let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                collectionView.register(nib, forCellWithReuseIdentifier: section.cell.reuseIdentifier)
            case let .fromClass(type):
                collectionView.register(type, forCellWithReuseIdentifier: section.cell.reuseIdentifier)
            case .fromStoryboard:
                break
            }

            [section.header, section.footer].compactMap { $0 }.forEach {
                switch $0.dequeueMethod {
                case let .fromNib(type):
                    let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                    collectionView.register(nib, forSupplementaryViewOfKind: $0.kind.rawValue, withReuseIdentifier: $0.reuseIdentifier)
                case let .fromClass(type):
                    collectionView.register(type, forSupplementaryViewOfKind: $0.kind.rawValue, withReuseIdentifier: $0.reuseIdentifier)
                case .fromStoryboard:
                    break
                }
            }

            cachedProviders.append(section)
        }

        if #available(iOS 13.0, *) {
            var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()

            (0..<mapper.numberOfSections).forEach { sectionIdentifier in
                let section = mapper.provider.sections[sectionIdentifier]
                snapshot.appendSections([sectionIdentifier])
                let identifiers = section.itemIdentifiers
                snapshot.appendItems(identifiers, toSection: sectionIdentifier)
            }

            diffableDataSource.apply(snapshot, animatingDifferences: animated)
        }

        collectionView.allowsMultipleSelection = true
        collectionView.backgroundView = delegate?.coordinator(self, backgroundViewInCollectionView: collectionView)
        collectionView.dragInteractionEnabled = sectionProvider.sections.contains { $0 is MoveHandler || $0 is CollectionDragHandler || $0 is CollectionDropHandler }
        delegate?.coordinatorDidUpdate(self)
    }

}

// MARK: - SectionProviderMappingDelegate

extension CollectionCoordinator: SectionProviderMappingDelegate {

    private func reset() {
        removes.removeAll()
        inserts.removeAll()
        changes.removeAll()
        moves.removeAll()
        sectionInserts.removeAll()
        sectionRemoves.removeAll()
    }

    public func mappingDidInvalidate(_ mapping: SectionProviderMapping) {
        assert(Thread.isMainThread)

        if #available(iOS 13, *) {
            prepareSections(animated: false)
            defersUpdate = false
        } else {
            reset()
            prepareSections(animated: false)
            collectionView.reloadData()
        }
    }

    public func mappingWillBeginUpdating(_ mapping: SectionProviderMapping) {
        reset()
        defersUpdate = true
    }

    public func mappingDidEndUpdating(_ mapping: SectionProviderMapping) {
        assert(Thread.isMainThread)

        if #available(iOS 13, *) {
            prepareSections()
            defersUpdate = false
        } else {
            collectionView.performBatchUpdates({
                if defersUpdate {
                    prepareSections()
                }

                removes.forEach { $0() }
                inserts.forEach { $0() }
                changes.forEach { $0() }
                moves.forEach { $0() }
                sectionRemoves.forEach { $0() }
                sectionInserts.forEach { $0() }
                sectionUpdates.forEach { $0() }
            }, completion: { [weak self] _ in
                self?.reset()
                self?.defersUpdate = false
            })
        }
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateSections sections: IndexSet) {
        assert(Thread.isMainThread)
        if #available(iOS 13, *) {
            if defersUpdate { return }
            else { return prepareSections() }
        }

        sectionUpdates.append { [weak self] in
            guard let self = self else { return }
            if !self.defersUpdate { self.prepareSections() }
            self.collectionView.reloadSections(sections)
        }
        if defersUpdate { return }
        mappingDidEndUpdating(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertSections sections: IndexSet) {
        assert(Thread.isMainThread)
        if #available(iOS 13, *) {
            if defersUpdate { return }
            else { return prepareSections() }
        }

        sectionInserts.append { [weak self] in
            guard let self = self else { return }
            if !self.defersUpdate { self.prepareSections() }
            self.collectionView.insertSections(sections)
        }
        if defersUpdate { return }
        mappingDidEndUpdating(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveSections sections: IndexSet) {
        assert(Thread.isMainThread)
        if #available(iOS 13, *) {
            if defersUpdate { return }
            else { return prepareSections() }
        }

        sectionRemoves.append { [weak self] in
            guard let self = self else { return }
            if !self.defersUpdate { self.prepareSections() }
            self.collectionView.deleteSections(sections)
        }
        if defersUpdate { return }
        mappingDidEndUpdating(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertElementsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)
        if #available(iOS 13, *) {
            if defersUpdate { return }
            else { return prepareSections() }
        }

        inserts.append { [weak self] in
            guard let self = self else { return }
            self.collectionView.insertItems(at: indexPaths)
        }
        if defersUpdate { return }
        mappingDidEndUpdating(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveElementsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)
        if #available(iOS 13, *) {
            if defersUpdate { return }
            else { return prepareSections() }
        }

        removes.append { [weak self] in
            guard let self = self else { return }
            self.collectionView.deleteItems(at: indexPaths)
        }
        if defersUpdate { return }
        mappingDidEndUpdating(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateElementsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)
        if #available(iOS 13, *) {
            if defersUpdate { return }
            else { return prepareSections() }
        }

        changes.append { [weak self] in
            guard let self = self else { return }
            
            var indexPathsToReload: [IndexPath] = []
            for indexPath in indexPaths {
                guard let section = self.sectionProvider.sections[indexPath.section] as? CollectionUpdateHandler,
                    !section.prefersReload(forElementAt: indexPath.item),
                    let cell = self.collectionView.cellForItem(at: indexPath) else {
                        indexPathsToReload.append(indexPath)
                        continue
                }

                self.cachedProviders[indexPath.section].cell.configure(cell, indexPath.item, self.mapper.provider.sections[indexPath.section])
            }

            guard !indexPathsToReload.isEmpty else { return }

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.collectionView.reloadItems(at: indexPathsToReload)
            CATransaction.setDisableActions(false)
            CATransaction.commit()
        }
        if defersUpdate { return }
        mappingDidEndUpdating(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didMoveElementsAt moves: [(IndexPath, IndexPath)]) {
        assert(Thread.isMainThread)
        if #available(iOS 13, *) {
            if defersUpdate { return }
            else { return prepareSections() }
        }

        self.moves.append { [weak self] in
            guard let self = self else { return }
            moves.forEach { self.collectionView.moveItem(at: $0.0, to: $0.1) }
        }
        if defersUpdate { return }
        mappingDidEndUpdating(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, selectedIndexesIn section: Int) -> [Int] {
        assert(Thread.isMainThread)
        let indexPaths = collectionView.indexPathsForSelectedItems ?? []
        return indexPaths.filter { $0.section == section }.map { $0.item }
    }

    public func mapping(_ mapping: SectionProviderMapping, select indexPath: IndexPath) {
        assert(Thread.isMainThread)
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
    }

    public func mapping(_ mapping: SectionProviderMapping, deselect indexPath: IndexPath) {
        assert(Thread.isMainThread)
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    public func mapping(_ mapping: SectionProviderMapping, move sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
    }

}

// MARK: - UICollectionViewDataSource

extension CollectionCoordinator: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return mapper.numberOfSections
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return elementsProvider(for: section).numberOfElements
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        assert(Thread.isMainThread)
        defer {
            originalDelegate?.collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath)
        }

        let elements = elementsProvider(for: indexPath.section)
        let section = mapper.provider.sections[indexPath.section]
        elements.cell.willAppear(cell, indexPath.item, section)
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        assert(Thread.isMainThread)
        defer {
            originalDelegate?.collectionView?(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
        }

        guard indexPath.count == 2 else { return }

        guard indexPath.section < sectionProvider.numberOfSections else { return }
        let elements = elementsProvider(for: indexPath.section)
        let section = mapper.provider.sections[indexPath.section]
        elements.cell.didDisappear(cell, indexPath.item, section)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        assert(Thread.isMainThread)
        let elements = elementsProvider(for: indexPath.section)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: elements.cell.reuseIdentifier, for: indexPath)

        if let handler = sectionProvider.sections[indexPath.section] as? EditingHandler {
            if let handler = sectionProvider.sections[indexPath.section] as? CollectionEditingHandler {
                handler.didSetEditing(collectionView.isEditing, at: indexPath.item, cell: cell, animated: false)
            } else {
                handler.didSetEditing(collectionView.isEditing, at: indexPath.item)
            }
        }

        elements.cell.configure(cell, indexPath.item, mapper.provider.sections[indexPath.section])
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        assert(Thread.isMainThread)
        defer {
            originalDelegate?.collectionView?(collectionView, willDisplaySupplementaryView: view, forElementKind: elementKind, at: indexPath)
        }

        guard indexPath.section > sectionProvider.numberOfSections else { return }
        let elements = elementsProvider(for: indexPath.section)
        let section = mapper.provider.sections[indexPath.section]

        if let header = elements.header, header.kind.rawValue == elementKind {
            elements.header?.willAppear?(view, indexPath.section, section)
        } else if let footer = elements.footer, footer.kind.rawValue == elementKind {
            elements.footer?.willAppear?(view, indexPath.section, section)
        } else {
            // the original delegate can handle this
        }
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        assert(Thread.isMainThread)
        let elements = elementsProvider(for: indexPath.section)
        let section = mapper.provider.sections[indexPath.section]

        if let header = elements.header, header.kind.rawValue == kind {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: header.reuseIdentifier, for: indexPath)
            header.configure(view, indexPath.section, section)
            return view
        } else if let footer = elements.footer, footer.kind.rawValue == kind {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footer.reuseIdentifier, for: indexPath)
            footer.configure(view, indexPath.section, section)
            return view
        } else {
            guard let view = originalDataSource?.collectionView?(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath) else {
                // when in production its better to return 'something' to prevent crashing
                assertionFailure("Unsupported supplementary kind: \(kind) at indexPath: \(indexPath). Did you forget to register your header or footer?")
                return collectionView.dequeue(supplementary: PlaceholderSupplementaryView.self, ofKind: PlaceholderSupplementaryView.kind, for: indexPath)
            }

            return view
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        assert(Thread.isMainThread)
        defer {
            originalDelegate?.collectionView?(collectionView, didEndDisplayingSupplementaryView: view, forElementOfKind: elementKind, at: indexPath)
        }

        guard indexPath.count == 2 else { return }

        guard indexPath.section < sectionProvider.numberOfSections else { return }
        let elements = elementsProvider(for: indexPath.section)
        let section = mapper.provider.sections[indexPath.section]

        if let header = elements.header, header.kind.rawValue == elementKind {
            elements.header?.didDisappear?(view, indexPath.section, section)
        } else if let footer = elements.footer, footer.kind.rawValue == elementKind {
            elements.footer?.didDisappear?(view, indexPath.section, section)
        } else {
            // the original delegate can handle this
        }
    }

    private func elementsProvider(for section: Int) -> CollectionElementsProvider {
        guard cachedProviders.indices.contains(section) else {
            fatalError("No UI configuration available for section \(section)")
        }
        return cachedProviders[section]
    }
    
}

@available(iOS 13.0, *)
extension CollectionCoordinator {

    // MARK: - Context Menus

    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = collectionView.cellForItem(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? CollectionContextMenuHandler else { return nil }
        let preview = provider.contextMenu(previewForElementAt: indexPath.item, cell: cell)
        return UIContextMenuConfiguration(identifier: indexPath.string, previewProvider: preview) { suggestedElements in
            return provider.contextMenu(forElementAt: indexPath.item, cell: cell, suggestedActions: suggestedElements)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else { return nil }
        guard let cell = collectionView.cellForItem(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? CollectionContextMenuHandler else { return nil }
        return provider.contextMenu(previewForHighlightingElementAt: indexPath.item, cell: cell)
    }

    public func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else { return nil }
        guard let cell = collectionView.cellForItem(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? CollectionContextMenuHandler else { return nil }
        return provider.contextMenu(previewForDismissingElementAt: indexPath.item, cell: cell)
    }

    public func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else { return }
        guard let cell = collectionView.cellForItem(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? CollectionContextMenuHandler else { return }
        provider.contextMenu(willPerformPreviewActionForElementAt: indexPath.item, cell: cell, animator: animator)
    }

}

extension CollectionCoordinator: UICollectionViewDelegate {

    // MARK: - Selection

    open func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else {
            return originalDelegate?.collectionView?(collectionView, shouldHighlightItemAt: indexPath) ?? true
        }

        return handler.shouldHighlight(at: indexPath.item)
    }

    open func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else {
            return originalDelegate?.collectionView?(collectionView, shouldSelectItemAt: indexPath) ?? false
        }

        return handler.shouldSelect(at: indexPath.item)
    }

    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defer {
            originalDelegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
        }

        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else { return }
        if let handler = handler as? CollectionSelectionHandler, let cell = collectionView.cellForItem(at: indexPath) {
            handler.didSelect(at: indexPath.item, cell: cell)
        } else {
            handler.didSelect(at: indexPath.item)
        }

        guard collectionView.allowsMultipleSelection, !handler.allowsMultipleSelection else { return }

        let indexPaths = mapping(mapper, selectedIndexesIn: indexPath.section)
            .map { IndexPath(item: $0, section: indexPath.section ) }
            .filter { $0 != indexPath }
        indexPaths.forEach { collectionView.deselectItem(at: $0, animated: true) }
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        originalDelegate?.scrollViewDidScroll?(scrollView)
    }

    open func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else {
            return originalDelegate?.collectionView?(collectionView, shouldDeselectItemAt: indexPath) ?? true
        }

        return handler.shouldDeselect(at: indexPath.item)
    }

    open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        defer {
            originalDelegate?.collectionView?(collectionView, didDeselectItemAt: indexPath)
        }

        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else { return }
        if let collectionHandler = handler as? CollectionSelectionHandler, let cell = collectionView.cellForItem(at: indexPath) {
            collectionHandler.didDeselect(at: indexPath.item, cell: cell)
        } else {
            handler.didDeselect(at: indexPath.item)
        }
    }

    // MARK: - Forwarding

    open override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        if originalDelegate?.responds(to: aSelector) ?? false { return true }
        return false
    }

    open override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if super.responds(to: aSelector) { return self }
        return originalDelegate
    }

}

// MARK: - UICollectionViewDragDelegate

extension CollectionCoordinator: UICollectionViewDragDelegate {

    public func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        sectionProvider.sections
            .compactMap { $0 as? CollectionDragHandler }
            .forEach { $0.dragSessionWillBegin(session) }

        originalDragDelegate?.collectionView?(collectionView, dragSessionWillBegin: session)
    }

    public func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        sectionProvider.sections
            .compactMap { $0 as? CollectionDragHandler }
            .forEach { $0.dragSessionDidEnd(session) }

        originalDragDelegate?.collectionView?(collectionView, dragSessionDidEnd: session)
    }

    public func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        return originalDragDelegate?.collectionView?(collectionView, dragSessionIsRestrictedToDraggingApplication: session) ?? false
    }

    public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let provider = sectionProvider.sections[indexPath.section] as? CollectionDragHandler else {
            return originalDragDelegate?.collectionView(collectionView, itemsForBeginning: session, at: indexPath) ?? []
        }

        session.localContext = indexPath.section
        return provider.dragSession(session, dragItemsForBeginning: indexPath.item)
    }

    public func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        guard let provider = sectionProvider.sections[indexPath.section] as? CollectionDragHandler else {
            return originalDragDelegate?.collectionView(collectionView, itemsForBeginning: session, at: indexPath) ?? []
        }

        return provider.dragSession(session, dragItemsForAdding: indexPath.item)
    }

    public func collectionView(_ collectionView: UICollectionView, dragSessionAllowsMoveOperation session: UIDragSession) -> Bool {
        let sections = sectionProvider.sections.compactMap { $0 as? MoveHandler }
        return originalDragDelegate?.collectionView?(collectionView, dragSessionAllowsMoveOperation: session) ?? !sections.isEmpty
    }

}

// MARK: - UICollectionViewDropDelegate

extension CollectionCoordinator: UICollectionViewDropDelegate {

    public func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        if collectionView.hasActiveDrag { return true }
        return originalDropDelegate?.collectionView?(collectionView, canHandle: session) ?? false
    }

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidEnter session: UIDropSession) {
        if !collectionView.hasActiveDrag {
            sectionProvider.sections
                .compactMap { $0 as? CollectionDropHandler }
                .forEach { $0.dropSessionWillBegin(session) }
        }

        originalDropDelegate?.collectionView?(collectionView, dropSessionDidEnter: session)
    }

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidExit session: UIDropSession) {
        originalDropDelegate?.collectionView?(collectionView, dropSessionDidExit: session)
    }

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        sectionProvider.sections
            .compactMap { $0 as? CollectionDropHandler }
            .forEach { $0.dropSessionDidEnd(session) }

        originalDropDelegate?.collectionView?(collectionView, dropSessionDidEnd: session)
    }

    public func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        // this seems to happen sometimes when iOS gets interrupted
        guard !indexPath.isEmpty else { return nil }

        guard let section = sectionProvider.sections[indexPath.section] as? CollectionDragHandler,
            let cell = collectionView.cellForItem(at: indexPath) else {
                return originalDragDelegate?.collectionView?(collectionView, dragPreviewParametersForItemAt: indexPath)
        }

        return section.dragSession(previewParametersForElementAt: indexPath.item, cell: cell)
    }
    
    public func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let section = sectionProvider.sections[indexPath.section] as? CollectionDropHandler,
            let cell = collectionView.cellForItem(at: indexPath) else {
            return originalDropDelegate?
                .collectionView?(collectionView, dropPreviewParametersForItemAt: indexPath)
        }

        return section.dropSesion(previewParametersForElementAt: indexPath.item, cell: cell)
    }

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let section = session.localDragSession?.localContext as? Int, section != destinationIndexPath?.section {
            return UICollectionViewDropProposal(operation: .forbidden)
        }

        if collectionView.hasActiveDrag || session.localDragSession != nil {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }

        if destinationIndexPath == nil {
            return originalDropDelegate?.collectionView?(collectionView, dropSessionDidUpdate: session, withDestinationIndexPath: destinationIndexPath) ?? UICollectionViewDropProposal(operation: .forbidden)
        }

        guard let indexPath = destinationIndexPath, let section = sectionProvider.sections[indexPath.section] as? CollectionDropHandler else {
            return originalDropDelegate?
                .collectionView?(collectionView, dropSessionDidUpdate: session, withDestinationIndexPath: destinationIndexPath)
                ?? UICollectionViewDropProposal(operation: .forbidden)
        }

        return section.dropSessionDidUpdate(session, destinationIndex: indexPath.item)
    }

    public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        defer {
            originalDropDelegate?.collectionView(collectionView, performDropWith: coordinator)
        }

        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)

        guard coordinator.proposal.operation == .move,
            let section = sectionProvider.sections[destinationIndexPath.section] as? MoveHandler else {
                return
        }

        let item = coordinator.items.lazy
            .filter { $0.sourceIndexPath != nil }
            .filter { $0.sourceIndexPath?.section == destinationIndexPath.section }
            .compactMap { ($0, $0.sourceIndexPath!) }
            .first!

        collectionView.performBatchUpdates({
            let indexes = IndexSet(integer: item.1.item)
            section.didMove(sourceIndexes: indexes, to: destinationIndexPath.item)

            collectionView.deleteItems(at: [item.1])
            collectionView.insertItems(at: [destinationIndexPath])
        }, completion: nil)

        coordinator.drop(item.0.dragItem, toItemAt: destinationIndexPath)
    }

}

private final class PlaceholderSupplementaryView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        widthAnchor.constraint(greaterThanOrEqualToConstant: 1).isActive = true
        heightAnchor.constraint(greaterThanOrEqualToConstant: 1).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension CollectionCoordinator {

    /// A convenience initializer that allows creation without a provider
    /// - Parameters:
    ///   - collectionView: The collectionView associated with this coordinator
    ///   - sections: The sections associated with this coordinator
    convenience init(collectionView: UICollectionView, sections: Section...) {
        let provider = ComposedSectionProvider()
        sections.forEach(provider.append(_:))
        self.init(collectionView: collectionView, sectionProvider: provider)
    }

}
