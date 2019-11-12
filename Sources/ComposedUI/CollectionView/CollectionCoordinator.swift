import UIKit
import Composed

public protocol CollectionCoordinatorDataSource: class {
    func coordinator(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
}

public protocol CollectionCoordinatorDelegate: class {
    func coordinator(_ coordinator: CollectionCoordinator, backgroundViewInCollectionView collectionView: UICollectionView) -> UIView?
}

public extension CollectionCoordinatorDelegate {
    func coordinator(_ coordinator: CollectionCoordinator, backgroundViewInCollectionView collectionView: UICollectionView) -> UIView? { return nil }
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
    private var updateOperation: BlockOperation?
    private let collectionView: UICollectionView

    private weak var originalDelegate: UICollectionViewDelegate?
    private var observer: NSKeyValueObservation?

    private var cachedProviders: [Int: CollectionSectionElementsProvider] = [:]

    public init(collectionView: UICollectionView, sectionProvider: SectionProvider) {
        self.collectionView = collectionView
        mapper = SectionProviderMapping(provider: sectionProvider)
        originalDelegate = collectionView.delegate

        super.init()

        collectionView.dataSource = self
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

            cachedProviders[index] = section

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
        }

        collectionView.allowsMultipleSelection = mapper.provider.sections
            .compactMap { $0 as? SelectionProvider }
            .contains { $0.allowsMultipleSelection }

        collectionView.backgroundView = delegate?.coordinator(self, backgroundViewInCollectionView: collectionView)
    }

}

// MARK: - SectionProviderMappingDelegate

extension CollectionCoordinator: SectionProviderMappingDelegate {

    private func dispatchIfNecessary(_ block: @escaping () -> Void) {
        if Thread.isMainThread { block() }
        else { DispatchQueue.main.async(execute: block) }
    }

    public func mappingDidReload(_ mapping: SectionProviderMapping) {
        prepareSections()
        collectionView.reloadData()
    }

    public func mappingWillUpdate(_ mapping: SectionProviderMapping) {
        updateOperation = BlockOperation()
    }

    public func mappingDidUpdate(_ mapping: SectionProviderMapping) {
        collectionView.performBatchUpdates({
            prepareSections()
            updateOperation?.start()
        }, completion: nil)
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertSections sections: IndexSet) {
        let block = { [unowned self] in
            self.self.dispatchIfNecessary {
                self.prepareSections()
                self.collectionView.insertSections(sections)
            }
        }
        updateOperation.flatMap { $0.addExecutionBlock(block) } ?? block()
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveSections sections: IndexSet) {
        let block = { [unowned self] in
            self.dispatchIfNecessary {
                self.prepareSections()
                self.collectionView.deleteSections(sections)
            }
        }
        updateOperation.flatMap { $0.addExecutionBlock(block) } ?? block()
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateSections sections: IndexSet) {
        let block = { [unowned self] in
            self.dispatchIfNecessary {
                self.prepareSections()
                self.collectionView.reloadSections(sections)
            }
        }
        updateOperation.flatMap { $0.addExecutionBlock(block) } ?? block()
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertElementsAt indexPaths: [IndexPath]) {
        let block = { [unowned self] in
            self.dispatchIfNecessary {
                self.collectionView.insertItems(at: indexPaths)
            }
        }
        updateOperation.flatMap { $0.addExecutionBlock(block) } ?? block()
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveElementsAt indexPaths: [IndexPath]) {
        let block = { [unowned self] in
            self.dispatchIfNecessary {
                self.collectionView.deleteItems(at: indexPaths)
            }
        }
        updateOperation.flatMap { $0.addExecutionBlock(block) } ?? block()
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateElementsAt indexPaths: [IndexPath]) {
        let block = { [unowned self] in
            self.dispatchIfNecessary {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.collectionView.reloadItems(at: indexPaths)
                CATransaction.setDisableActions(false)
                CATransaction.commit()
            }
        }
        updateOperation.flatMap { $0.addExecutionBlock(block) } ?? block()
    }

    public func mapping(_ mapping: SectionProviderMapping, didMoveElementsAt moves: [(IndexPath, IndexPath)]) {
        let block = { [unowned self] in
            self.dispatchIfNecessary {
                moves.forEach {
                    self.collectionView.moveItem(at: $0.0, to: $0.1)
                }
            }
        }
        updateOperation.flatMap { $0.addExecutionBlock(block) } ?? block()
    }

    public func mapping(_ mapping: SectionProviderMapping, selectedIndexesIn section: Int) -> [Int] {
        let indexPaths = collectionView.indexPathsForSelectedItems ?? []
        return indexPaths.filter { $0.section == section }.map { $0.item }
    }

}

// MARK: - UICollectionViewDataSource

extension CollectionCoordinator: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return mapper.numberOfSections
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cachedProviders[section]?.numberOfElements ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = cachedProviders[indexPath.section] else {
            fatalError("No UI configuration available for section \(indexPath.section)")
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: section.cell.reuseIdentifier, for: indexPath)
        section.cell.configure(cell, indexPath.item, mapper.provider.sections[indexPath.section])

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let provider = cachedProviders[indexPath.section] else {
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

}

private extension IndexPath {
    init?(string: String) {
        let components = string.components(separatedBy: ".").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        self.init(item: components[1], section: components[0])
    }

    var string: NSString {
        return "\(section).\(item)" as NSString
    }
}

// MARK: - Context Menus

@available(iOS 13.0, *)
extension CollectionCoordinator {

    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = collectionView.cellForItem(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? CollectionSectionContextMenuProvider else { return nil }
        let preview = provider.contextMenu(previewForItemAt: indexPath.item, cell: cell)
        return UIContextMenuConfiguration(identifier: indexPath.string, previewProvider: preview) { suggestedElements in
            return provider.contextMenu(forItemAt: indexPath.item, suggestedActions: suggestedElements)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else { return nil }
        guard let cell = collectionView.cellForItem(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? CollectionSectionContextMenuProvider else { return nil }
        return provider.contextMenu(previewForHighlightingItemAt: indexPath.item, cell: cell)
    }

    public func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else { return nil }
        guard let cell = collectionView.cellForItem(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? CollectionSectionContextMenuProvider else { return nil }
        return provider.contextMenu(previewForDismissingItemAt: indexPath.item, cell: cell)
    }

    public func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else { return }
        guard let provider = mapper.provider.sections[indexPath.section] as? CollectionSectionContextMenuProvider else { return }
        provider.contextMenu(willPerformPreviewActionForItemAt: indexPath.item, animator: animator)
    }

}

// MARK: - UICollectionViewDelegate

extension CollectionCoordinator: UICollectionViewDelegate {

    open func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let provider = mapper.provider.sections[indexPath.section] as? SelectionProvider else { return true }
        return provider.shouldHighlight(at: indexPath.item)
    }

    open func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let provider = mapper.provider.sections[indexPath.section] as? SelectionProvider else { return true }
        return provider.shouldSelect(at: indexPath.item)
    }

    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let provider = mapper.provider.sections[indexPath.section] as? SelectionProvider else { return }
        provider.didSelect(at: indexPath.item)

        guard collectionView.allowsMultipleSelection, !provider.allowsMultipleSelection else { return }

        let indexPaths = mapping(mapper, selectedIndexesIn: indexPath.section)
            .map { IndexPath(item: $0, section: indexPath.section ) }
            .filter { $0 != indexPath }
        indexPaths.forEach { collectionView.deselectItem(at: $0, animated: true) }
    }

    open func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard let provider = mapper.provider.sections[indexPath.section] as? SelectionProvider else { return true }
        return provider.shouldDeselect(at: indexPath.item)
    }

    open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let provider = mapper.provider.sections[indexPath.section] as? SelectionProvider else { return }
        provider.didDeselect(at: indexPath.item)
        guard collectionView.allowsMultipleSelection else { return }
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
