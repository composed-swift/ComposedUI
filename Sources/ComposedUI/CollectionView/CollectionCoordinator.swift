import UIKit
import Composed

public protocol CollectionCoordinatorDelegate: class {
    func coordinator(_ coordinator: CollectionCoordinator, backgroundViewInCollectionView collectionView: UICollectionView) -> UIView?
    func coordinatorDidUpdate(_ coordinator: CollectionCoordinator)

//    func coordinator(_ coordinator: CollectionCoordinator, canHandleDropSession session: UIDropSession) -> Bool
//    func coordinator(_ coordinator: CollectionCoordinator, dropSessionDidEnter: UIDropSession)
//    func coordinator(_ coordinator: CollectionCoordinator, dropSessionDidExit session: UIDropSession)
//    func coordinator(_ coordinator: CollectionCoordinator, dropSessionDidEnd session: UIDropSession)
//    func coordinator(_ coordinator: CollectionCoordinator, performDropWith dropCoordinator: UICollectionViewDropCoordinator)
}

public extension CollectionCoordinatorDelegate {
    func coordinator(_ coordinator: CollectionCoordinator, backgroundViewInCollectionView collectionView: UICollectionView) -> UIView? { return nil }
    func coordinatorDidUpdate(_ coordinator: CollectionCoordinator) { }

//    func coordinator(_ coordinator: CollectionCoordinator, canHandleDropSession session: UIDropSession) -> Bool { return false }
//    func coordinator(_ coordinator: CollectionCoordinator, dropSessionDidEnter: UIDropSession) { }
//    func coordinator(_ coordinator: CollectionCoordinator, dropSessionDidExit session: UIDropSession) { }
//    func coordinator(_ coordinator: CollectionCoordinator, dropSessionDidEnd session: UIDropSession) { }
//    func coordinator(_ coordinator: CollectionCoordinator, performDropWith dropCoordinator: UICollectionViewDropCoordinator) { }
}

/// The coordinator that provides the 'glue' between a section provider and a collection view
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
    private var dataSourceObserver: NSKeyValueObservation?

    private weak var originalDataSource: UICollectionViewDataSource?
    private var delegateObserver: NSKeyValueObservation?

    private var cachedProviders: [CollectionSectionElementsProvider] = []

    /// Make a new coordinator with the specified collectionView and sectionProvider
    /// - Parameters:
    ///   - collectionView: The collectionView to associate with this coordinator
    ///   - sectionProvider: The sectionProvider to associate with this coordinator
    public init(collectionView: UICollectionView, sectionProvider: SectionProvider) {
        self.collectionView = collectionView
        mapper = SectionProviderMapping(provider: sectionProvider)
        originalDelegate = collectionView.delegate

        super.init()

        collectionView.dataSource = self
        collectionView.dropDelegate = self
        prepareSections()

        delegateObserver = collectionView.observe(\.delegate, options: [.initial, .new]) { [weak self] collectionView, _ in
            guard collectionView.delegate !== self else { return }
            self?.originalDelegate = collectionView.delegate
            collectionView.delegate = self
        }

        dataSourceObserver = collectionView.observe(\.dataSource, options: [.initial, .new]) { [weak self] collectionView, _ in
            guard collectionView.dataSource !== self else { return }
            self?.originalDataSource = collectionView.dataSource
            collectionView.dataSource = self
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
        collectionView.reloadData()
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

    // Prepares and caches the section to improve performance
    private func prepareSections() {
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

        collectionView.allowsMultipleSelection = true
        collectionView.backgroundView = delegate?.coordinator(self, backgroundViewInCollectionView: collectionView)
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
        reset()
        prepareSections()
        collectionView.reloadData()
    }

    public func mappingWillBeginUpdating(_ mapping: SectionProviderMapping) {
        reset()
        defersUpdate = true
    }

    public func mappingDidEndUpdating(_ mapping: SectionProviderMapping) {
        assert(Thread.isMainThread)
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

    public func mapping(_ mapping: SectionProviderMapping, didUpdateSections sections: IndexSet) {
        assert(Thread.isMainThread)
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
        inserts.append { [weak self] in
            guard let self = self else { return }
            self.collectionView.insertItems(at: indexPaths)
        }
        if defersUpdate { return }
        mappingDidEndUpdating(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveElementsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)
        removes.append { [weak self] in
            guard let self = self else { return }
            self.collectionView.deleteItems(at: indexPaths)
        }
        if defersUpdate { return }
        mappingDidEndUpdating(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateElementsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)
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

}

// MARK: - UICollectionViewDataSource

extension CollectionCoordinator: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return mapper.numberOfSections
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionSection(for: section).numberOfElements
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        assert(Thread.isMainThread)
        defer {
            originalDelegate?.collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath)
        }

        let provider = collectionSection(for: indexPath.section)
        let section = mapper.provider.sections[indexPath.section]
        provider.cell.willDisplay(cell, indexPath.item, section)
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        assert(Thread.isMainThread)
        defer {
            originalDelegate?.collectionView?(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
        }

        guard indexPath.section > sectionProvider.numberOfSections else { return }
        let provider = collectionSection(for: indexPath.section)
        let section = mapper.provider.sections[indexPath.section]
        provider.cell.didEndDisplay(cell, indexPath.item, section)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        assert(Thread.isMainThread)
        let section = collectionSection(for: indexPath.section)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: section.cell.reuseIdentifier, for: indexPath)

        if let handler = sectionProvider.sections[indexPath.section] as? EditingHandler {
            if let handler = sectionProvider.sections[indexPath.section] as? CollectionEditingHandler {
                handler.didSetEditing(collectionView.isEditing, at: indexPath.item, cell: cell, animated: false)
            } else {
                handler.didSetEditing(collectionView.isEditing, at: indexPath.item)
            }
        }

        section.cell.configure(cell, indexPath.item, mapper.provider.sections[indexPath.section])
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        assert(Thread.isMainThread)
        let provider = collectionSection(for: indexPath.section)
        let section = mapper.provider.sections[indexPath.section]

        if let header = provider.header, header.kind.rawValue == kind {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: header.reuseIdentifier, for: indexPath)
            header.configure(view, indexPath.section, section)
            return view
        } else if let footer = provider.footer, footer.kind.rawValue == kind {
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

    private func collectionSection(for section: Int) -> CollectionSectionElementsProvider {
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
        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else { return true }
        return handler.shouldHighlight(at: indexPath.item)
    }

    open func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else { return false }
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
        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else { return true }
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

extension CollectionCoordinator: UICollectionViewDropDelegate {

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if destinationIndexPath == nil {
            return (originalDelegate as? UICollectionViewDropDelegate)?
                .collectionView?(collectionView, dropSessionDidUpdate: session, withDestinationIndexPath: destinationIndexPath)
                ?? UICollectionViewDropProposal(operation: .forbidden)
        }

        guard let indexPath = destinationIndexPath, let section = sectionProvider.sections[indexPath.section] as? CollectionDropHandler else {
            return (originalDelegate as? UICollectionViewDropDelegate)?
                .collectionView?(collectionView, dropSessionDidUpdate: session, withDestinationIndexPath: destinationIndexPath)
                ?? UICollectionViewDropProposal(operation: .forbidden)
        }

        return section.dropSessionDidUpdate(session, destinationIndex: indexPath.item)
    }

    public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        (originalDelegate as? UICollectionViewDropDelegate)?.collectionView(collectionView, performDropWith: coordinator)
    }

    public func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let section = sectionProvider.sections[indexPath.section] as? CollectionDropHandler else {
            return (originalDelegate as? UICollectionViewDropDelegate)?
                .collectionView?(collectionView, dropPreviewParametersForItemAt: indexPath)
        }

        return section.dropSesion(previewParametersForElementAt: indexPath.item)
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

    /// A convenience initializer that allow creation without a provider
    /// - Parameters:
    ///   - collectionView: The collectionView associated with this coordinator
    ///   - sections: The sections associated with this coordinator
    convenience init(collectionView: UICollectionView, sections: Section...) {
        let provider = ComposedSectionProvider()
        self.init(collectionView: collectionView, sectionProvider: provider)
    }

}
