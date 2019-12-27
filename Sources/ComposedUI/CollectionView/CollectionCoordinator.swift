import UIKit
import Composed

public protocol CollectionCoordinatorDataSource: class {
    func coordinator(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
}

public protocol CollectionCoordinatorDelegate: class {
    func coordinator(_ coordinator: CollectionCoordinator, didScroll collectionView: UICollectionView)
    func coordinator(_ coordinator: CollectionCoordinator, backgroundViewInCollectionView collectionView: UICollectionView) -> UIView?
    func coordinatorDidUpdate(_ coordinator: CollectionCoordinator)

    func coordinator(_ coordinator: CollectionCoordinator, canHandleDropSession session: UIDropSession) -> Bool
    func coordinator(_ coordinator: CollectionCoordinator, dropSessionDidEnter: UIDropSession)
    func coordinator(_ coordinator: CollectionCoordinator, dropSessionDidExit session: UIDropSession)
    func coordinator(_ coordinator: CollectionCoordinator, dropSessionDidEnd session: UIDropSession)
    func coordinator(_ coordinator: CollectionCoordinator, performDropWith dropCoordinator: UICollectionViewDropCoordinator)
}

public extension CollectionCoordinatorDelegate {
    func coordinator(_ coordinator: CollectionCoordinator, didScroll collectionView: UICollectionView) { }
    func coordinator(_ coordinator: CollectionCoordinator, backgroundViewInCollectionView collectionView: UICollectionView) -> UIView? { return nil }
    func coordinatorDidUpdate(_ coordinator: CollectionCoordinator) { }

    func coordinator(_ coordinator: CollectionCoordinator, canHandleDropSession session: UIDropSession) -> Bool { return false }
    func coordinator(_ coordinator: CollectionCoordinator, dropSessionDidEnter: UIDropSession) { }
    func coordinator(_ coordinator: CollectionCoordinator, dropSessionDidExit session: UIDropSession) { }
    func coordinator(_ coordinator: CollectionCoordinator, dropSessionDidEnd session: UIDropSession) { }
    func coordinator(_ coordinator: CollectionCoordinator, performDropWith dropCoordinator: UICollectionViewDropCoordinator) { }
}

open class CollectionCoordinator: NSObject {

    public weak var dataSource: CollectionCoordinatorDataSource?
    public weak var delegate: CollectionCoordinatorDelegate? {
        didSet { collectionView.backgroundView = delegate?.coordinator(self, backgroundViewInCollectionView: collectionView) }
    }

    public var sectionProvider: SectionProvider {
        return mapper.provider
    }

    private var mapper: SectionProviderMapping

    private var defersUpdate: Bool = false
    private var sectionRemoves: [() -> Void] = []
    private var sectionInserts: [() -> Void] = []

    private var removes: [() -> Void] = []
    private var inserts: [() -> Void] = []
    private var changes: [() -> Void] = []
    private var moves: [() -> Void] = []

    private let collectionView: UICollectionView

    private weak var originalDelegate: UICollectionViewDelegate?
    private var observer: NSKeyValueObservation?

    private var cachedProviders: [CollectionSectionElementsProvider] = []

    public init(collectionView: UICollectionView, sectionProvider: SectionProvider) {
        self.collectionView = collectionView
        mapper = SectionProviderMapping(provider: sectionProvider)
        originalDelegate = collectionView.delegate

        super.init()

        collectionView.dataSource = self
        collectionView.dropDelegate = self
        prepareSections()

        observer = collectionView.observe(\.delegate, options: [.initial, .new]) { [weak self] collectionView, _ in
            guard collectionView.delegate !== self else { return }
            self?.originalDelegate = collectionView.delegate
            collectionView.delegate = self
        }
    }

    open func replace(sectionProvider: SectionProvider) {
        mapper = SectionProviderMapping(provider: sectionProvider)
        prepareSections()
        collectionView.reloadData()
    }

    open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext? = nil) {
        guard collectionView.window != nil else { return }

        if let context = context {
            collectionView.collectionViewLayout.invalidateLayout(with: context)
        } else {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    private func prepareSections() {
        cachedProviders.removeAll()
        mapper.delegate = self

        for index in 0..<mapper.numberOfSections {
            guard let section = (mapper.provider.sections[index] as? CollectionSectionProvider)?.section(with: collectionView.traitCollection) else {
                fatalError("No provider available for section: \(index), or it does not conform to CollectionSectionProvider")
            }

            switch section.cell.dequeueMethod {
            case let .nib(type):
                let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                collectionView.register(nib, forCellWithReuseIdentifier: section.cell.reuseIdentifier)
            case let .class(type):
                collectionView.register(type, forCellWithReuseIdentifier: section.cell.reuseIdentifier)
            case .storyboard:
                break
            }

            [section.header, section.footer].compactMap { $0 }.forEach {
                switch $0.dequeueMethod {
                case let .nib(type):
                    let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                    collectionView.register(nib, forSupplementaryViewOfKind: $0.kind.rawValue, withReuseIdentifier: $0.reuseIdentifier)
                case let .class(type):
                    collectionView.register(type, forSupplementaryViewOfKind: $0.kind.rawValue, withReuseIdentifier: $0.reuseIdentifier)
                case .storyboard:
                    break
                }
            }

            cachedProviders.append(section)
        }

        collectionView.allowsMultipleSelection = mapper.provider.sections
            .compactMap { $0 as? SelectionHandler }
            .contains { $0.allowsMultipleSelection }

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

    public func mappingDidReload(_ mapping: SectionProviderMapping) {
        assert(Thread.isMainThread)
        reset()
        prepareSections()
        collectionView.reloadData()
    }

    public func mappingWillUpdate(_ mapping: SectionProviderMapping) {
        reset()
        defersUpdate = true
    }

    public func mappingDidUpdate(_ mapping: SectionProviderMapping) {
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
        }, completion: { [unowned self] _ in
            self.reset()
            self.defersUpdate = false
        })
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertSections sections: IndexSet) {
        assert(Thread.isMainThread)
        sectionInserts.append { [unowned self] in
            if !self.defersUpdate { self.prepareSections() }
            self.collectionView.insertSections(sections)
        }
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveSections sections: IndexSet) {
        assert(Thread.isMainThread)
        sectionRemoves.append { [unowned self] in
            if !self.defersUpdate { self.prepareSections() }
            self.collectionView.deleteSections(sections)
        }
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertElementsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)
        inserts.append { [unowned self] in
            self.collectionView.insertItems(at: indexPaths)
        }
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveElementsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)
        removes.append { [unowned self] in
            self.collectionView.deleteItems(at: indexPaths)
        }
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateElementsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)
        changes.append { [unowned self] in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.collectionView.reloadItems(at: indexPaths)
            CATransaction.setDisableActions(false)
            CATransaction.commit()
        }
    }

    public func mapping(_ mapping: SectionProviderMapping, didMoveElementsAt moves: [(IndexPath, IndexPath)]) {
        assert(Thread.isMainThread)
        self.moves.append { [unowned self] in
            moves.forEach { self.collectionView.moveItem(at: $0.0, to: $0.1) }
        }
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

    public func mapping(_ mapping: SectionProviderMapping, isEditingIn section: Int) -> Bool {
        assert(Thread.isMainThread)
        return collectionView.isEditing
    }

}

// MARK: - UICollectionViewDataSource

extension CollectionCoordinator: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return mapper.numberOfSections
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionSection(for: section)?.numberOfElements ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = collectionSection(for: indexPath.section) else {
            fatalError("No UI configuration available for section \(indexPath.section)")
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: section.cell.reuseIdentifier, for: indexPath)
        section.cell.configure(cell, indexPath.item, mapper.provider.sections[indexPath.section])

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let provider = collectionSection(for: indexPath.section) else {
            fatalError("No UI configuration available for section \(indexPath.section)")
        }

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
            guard let view = dataSource?.coordinator(collectionView: collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath) else {
                fatalError("Unsupported supplementary kind: \(kind) at indexPath: \(indexPath)")
            }

            return view
        }
    }

    private func collectionSection(for section: Int) -> CollectionSectionElementsProvider? {
        guard cachedProviders.indices.contains(section) else { return nil }
        return cachedProviders[section]
    }

}

@available(iOS 13.0, *)
extension CollectionCoordinator {

    // MARK: - Context Menus

    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = collectionView.cellForItem(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? CollectionContextMenuHandler else { return nil }
        let preview = provider.contextMenu(previewForItemAt: indexPath.item, cell: cell)
        return UIContextMenuConfiguration(identifier: indexPath.string, previewProvider: preview) { suggestedElements in
            return provider.contextMenu(forItemAt: indexPath.item, cell: cell, suggestedActions: suggestedElements)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else { return nil }
        guard let cell = collectionView.cellForItem(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? CollectionContextMenuHandler else { return nil }
        return provider.contextMenu(previewForHighlightingItemAt: indexPath.item, cell: cell)
    }

    public func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else { return nil }
        guard let cell = collectionView.cellForItem(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? CollectionContextMenuHandler else { return nil }
        return provider.contextMenu(previewForDismissingItemAt: indexPath.item, cell: cell)
    }

    public func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else { return }
        guard let provider = mapper.provider.sections[indexPath.section] as? CollectionContextMenuHandler else { return }
        provider.contextMenu(willPerformPreviewActionForItemAt: indexPath.item, animator: animator)
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
        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else { return }
        if let collectionHandler = handler as? CollectionSelectionHandler, let cell = collectionView.cellForItem(at: indexPath) {
            collectionHandler.didSelect(at: indexPath.item, cell: cell)
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
        delegate?.coordinator(self, didScroll: collectionView)
    }

    open func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else { return true }
        return handler.shouldDeselect(at: indexPath.item)
    }

    open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
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

    public func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return delegate?.coordinator(self, canHandleDropSession: session) ?? false
    }

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidEnter session: UIDropSession) {
        delegate?.coordinator(self, dropSessionDidEnter: session)
    }

    public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        delegate?.coordinator(self, performDropWith: coordinator)
    }

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidExit session: UIDropSession) {
        delegate?.coordinator(self, dropSessionDidExit: session)
    }

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        delegate?.coordinator(self, dropSessionDidEnd: session)
    }

    public func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        return (sectionProvider.sections[indexPath.section] as? CollectionDropHandler)?.dropSesion(previewParametersForItemAt: indexPath.item)
    }

}
