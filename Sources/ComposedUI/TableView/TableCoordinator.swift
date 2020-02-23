import UIKit
import Composed

public protocol TableCoordinatorDelegate: class {
    func coordinator(_ coordinator: TableCoordinator, didScroll tableView: UITableView)
    func coordinator(_ coordinator: TableCoordinator, backgroundViewInTableView tableView: UITableView) -> UIView?
    func coordinatorDidUpdate(_ coordinator: TableCoordinator)

    func coordinator(_ coordinator: TableCoordinator, canHandleDropSession session: UIDropSession) -> Bool
    func coordinator(_ coordinator: TableCoordinator, dropSessionDidEnter: UIDropSession)
    func coordinator(_ coordinator: TableCoordinator, dropSessionDidExit session: UIDropSession)
    func coordinator(_ coordinator: TableCoordinator, dropSessionDidEnd session: UIDropSession)
    func coordinator(_ coordinator: TableCoordinator, performDropWith dropCoordinator: UITableViewDropCoordinator)
}

public extension TableCoordinatorDelegate {
    func coordinator(_ coordinator: TableCoordinator, didScroll tableView: UITableView) { }
    func coordinator(_ coordinator: TableCoordinator, backgroundViewInCollectionView tableView: UITableView) -> UIView? { return nil }
    func coordinatorDidUpdate(_ coordinator: TableCoordinator) { }

    func coordinator(_ coordinator: TableCoordinator, canHandleDropSession session: UIDropSession) -> Bool { return false }
    func coordinator(_ coordinator: TableCoordinator, dropSessionDidEnter: UIDropSession) { }
    func coordinator(_ coordinator: TableCoordinator, dropSessionDidExit session: UIDropSession) { }
    func coordinator(_ coordinator: TableCoordinator, dropSessionDidEnd session: UIDropSession) { }
    func coordinator(_ coordinator: TableCoordinator, performDropWith dropCoordinator: UITableViewDropCoordinator) { }
}

open class TableCoordinator: NSObject {

    public weak var delegate: TableCoordinatorDelegate? {
        didSet { tableView.backgroundView = delegate?.coordinator(self, backgroundViewInTableView: tableView) }
    }

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

    private let tableView: UITableView

    private weak var originalDelegate: UITableViewDelegate?
    private var observer: NSKeyValueObservation?

    private var cachedProviders: [TableElementsProvider] = []

    public init(tableView: UITableView, sectionProvider: SectionProvider) {
        self.tableView = tableView
        mapper = SectionProviderMapping(provider: sectionProvider)

        super.init()

        tableView.dataSource = self
        prepareSections()

        observer = tableView.observe(\.delegate, options: [.initial, .new]) { [weak self] tableView, _ in
            guard tableView.delegate !== self else { return }
            self?.originalDelegate = tableView.delegate
            tableView.delegate = self
        }
    }

    open func replace(sectionProvider: SectionProvider) {
        mapper = SectionProviderMapping(provider: sectionProvider)
        prepareSections()
        tableView.reloadData()
    }

    private func prepareSections() {
        mapper.delegate = self
        cachedProviders.removeAll()

        for index in 0..<mapper.numberOfSections {
            guard let section = (mapper.provider.sections[index] as? TableSectionProvider)?.section(with: tableView.traitCollection) else {
                fatalError("No provider available for section: \(index), or it does not conform to TableSectionProvider")
            }

            switch section.cell.dequeueMethod {
            case let .nib(type):
                let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                tableView.register(nib, forCellReuseIdentifier: section.cell.reuseIdentifier)
            case let .class(type):
                tableView.register(type, forCellReuseIdentifier: section.cell.reuseIdentifier)
            case .storyboard:
                break
            }

            [section.header, section.footer].compactMap { $0 }.forEach {
                switch $0.dequeueMethod {
                case let .nib(type):
                    let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                    tableView.register(nib, forHeaderFooterViewReuseIdentifier: $0.reuseIdentifier)
                case let .class(type):
                    tableView.register(type, forHeaderFooterViewReuseIdentifier: $0.reuseIdentifier)
                case .storyboard:
                    break
                }
            }

            cachedProviders.append(section)
        }

        tableView.allowsMultipleSelection = mapper.provider.sections
            .compactMap { $0 as? SelectionHandler }
            .contains { $0.allowsMultipleSelection }

        tableView.allowsSelectionDuringEditing = true
    }

}

// MARK: - SectionProviderMappingDelegate

extension TableCoordinator: SectionProviderMappingDelegate {

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
        tableView.reloadData()
    }

    public func mapping(_ mapping: SectionProviderMapping, performBatchUpdates: () -> Void) {
        reset()
        defersUpdate = true

        tableView.performBatchUpdates({
            performBatchUpdates()
        }) { [weak self] _ in
            self?.reset()
            self?.defersUpdate = false
        }
    }

    public func mappingWillUpdate(_ mapping: SectionProviderMapping) {
        reset()
        defersUpdate = true
    }

    public func mappingDidUpdate(_ mapping: SectionProviderMapping) {
        assert(Thread.isMainThread)
        tableView.performBatchUpdates({
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
            guard let self = self else { return }
            self.reset()
            self.defersUpdate = false
        })
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateSections sections: IndexSet) {
        assert(Thread.isMainThread)
        sectionUpdates.append { [weak self] in
            guard let self = self else { return }
            if !self.defersUpdate { self.prepareSections() }
            self.tableView.reloadSections(sections, with: .fade)
        }
        if defersUpdate { return }
        mappingDidUpdate(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertSections sections: IndexSet) {
        assert(Thread.isMainThread)
        sectionInserts.append { [weak self] in
            guard let self = self else { return }
            if !self.defersUpdate { self.prepareSections() }
            self.tableView.insertSections(sections, with: .fade)
        }
        if defersUpdate { return }
        mappingDidUpdate(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveSections sections: IndexSet) {
        assert(Thread.isMainThread)
        sectionRemoves.append { [weak self] in
            guard let self = self else { return }
            if !self.defersUpdate { self.prepareSections() }
            self.tableView.deleteSections(sections, with: .fade)
        }
        if defersUpdate { return }
        mappingDidUpdate(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertElementsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)
        inserts.append { [weak self] in
            guard let self = self else { return }
            self.tableView.insertRows(at: indexPaths, with: .automatic)
        }
        if defersUpdate { return }
        mappingDidUpdate(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveElementsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)
        removes.append { [weak self] in
            guard let self = self else { return }
            self.tableView.deleteRows(at: indexPaths, with: .automatic)
        }
        if defersUpdate { return }
        mappingDidUpdate(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateElementsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)
        changes.append { [weak self] in
            guard let self = self else { return }

            var indexPathsToReload: [IndexPath] = []
            for indexPath in indexPaths {
                guard let section = self.sectionProvider.sections[indexPath.section] as? TableUpdateHandling,
                    !section.allowsReload(forItemAt: indexPath.item),
                    let cell = self.tableView.cellForRow(at: indexPath) else {
                        indexPathsToReload.append(indexPath)
                        continue
                }

                self.cachedProviders[indexPath.section].cell.configure(cell, indexPath.item, self.mapper.provider.sections[indexPath.section])
            }

            guard !indexPathsToReload.isEmpty else { return }

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.tableView.reloadRows(at: indexPaths, with: .automatic)
            CATransaction.setDisableActions(false)
            CATransaction.commit()
        }
        if defersUpdate { return }
        mappingDidUpdate(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didMoveElementsAt moves: [(IndexPath, IndexPath)]) {
        assert(Thread.isMainThread)
        self.moves.append { [weak self] in
            guard let self = self else { return }
            moves.forEach { self.tableView.moveRow(at: $0.0, to: $0.1) }
        }
        if defersUpdate { return }
        mappingDidUpdate(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, selectedIndexesIn section: Int) -> [Int] {
        let indexPaths = tableView.indexPathsForSelectedRows ?? []
        return indexPaths.filter { $0.section == section }.map { $0.item }
    }

    public func mapping(_ mapping: SectionProviderMapping, select indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }

    public func mapping(_ mapping: SectionProviderMapping, deselect indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    public func mapping(_ mapping: SectionProviderMapping, isEditingIn section: Int) -> Bool {
        return tableView.isEditing
    }
    
}

// MARK: - UITableViewDataSource

extension TableCoordinator: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableSection(for: section)?.header else { return nil }
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: header.reuseIdentifier) else { return nil }
        header.configure(view, section, mapper.provider.sections[section])
        return view
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = tableSection(for: section)?.footer else { return nil }
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: footer.reuseIdentifier) else { return nil }
        footer.configure(view, section, mapper.provider.sections[section])
        return view
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return mapper.numberOfSections
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableSection(for: section)?.numberOfElements ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = tableSection(for: indexPath.section) else {
            fatalError("No UI configuration available for section \(indexPath.section)")
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: section.cell.reuseIdentifier, for: indexPath)
        section.cell.configure(cell, indexPath.row, mapper.provider.sections[indexPath.section])
        return cell
    }

    private func tableSection(for section: Int) -> TableElementsProvider? {
        guard cachedProviders.indices.contains(section) else { return nil }
        return cachedProviders[section]
    }

}

@available(iOS 13.0, *)
extension TableCoordinator {

    // MARK: - Context Menus

    open func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? TableContextMenuHandler else { return nil }
        let preview = provider.contextMenu(previewForItemAt: indexPath.item, cell: cell)
        return UIContextMenuConfiguration(identifier: indexPath.string, previewProvider: preview) { suggestedElements in
            return provider.contextMenu(forItemAt: indexPath.item, cell: cell, suggestedActions: suggestedElements)
        }
    }

    open func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else { return nil }
        guard let cell = tableView.cellForRow(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? TableContextMenuHandler else { return nil }
        return provider.contextMenu(previewForHighlightingItemAt: indexPath.item, cell: cell)
    }

    open func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else { return nil }
        guard let cell = tableView.cellForRow(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? TableContextMenuHandler else { return nil }
        return provider.contextMenu(previewForDismissingItemAt: indexPath.item, cell: cell)
    }

    open func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else { return }
        guard let cell = tableView.cellForRow(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? TableContextMenuHandler else { return }
        provider.contextMenu(willPerformPreviewActionForItemAt: indexPath.item, cell: cell, animator: animator)
    }

}

extension TableCoordinator: UITableViewDelegate {

    // MARK: - Editing

    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let handler = mapper.provider.sections[indexPath.section] as? TableEditingHandler else { return false }
        return handler.allowsEditing(at: indexPath.item)
    }

    open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard let handler = mapper.provider.sections[indexPath.section] as? TableEditingHandler else { return .none }
        return handler.editingStyle(at: indexPath.item)
    }

    open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let handler = mapper.provider.sections[indexPath.section] as? TableEditingHandler else { return }
        handler.commitEditing(at: indexPath.item, editingStyle: editingStyle)
    }

    open func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        guard let handler = mapper.provider.sections[indexPath.section] as? TableEditingHandler else { return }
        handler.willBeginEditing(at: indexPath.item)
    }

    open func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        guard let indexPath = indexPath,
            let handler = mapper.provider.sections[indexPath.section] as? TableEditingHandler else {
                return
        }

        handler.didEndEditing(at: indexPath.item)
    }

    // MARK: - Moving

    open func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        guard let handler = mapper.provider.sections[indexPath.section] as? TableEditingHandler else { return true }
        return handler.editingStyle(at: indexPath.item) == .none ? false : handler.shouldIndentWhileEditing(at: indexPath.item)
    }

    open func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard let handler = mapper.provider.sections[indexPath.section] as? TableMovingHandler else { return false }
        return handler.allowsMove(at: indexPath.item)
    }

    open func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard sourceIndexPath.section == destinationIndexPath.section,
            let handler = mapper.provider.sections[sourceIndexPath.section] as? TableMovingHandler else { return }
        handler.didMove(from: sourceIndexPath.item, to: destinationIndexPath.item)
    }

    open func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard sourceIndexPath.section == proposedDestinationIndexPath.section,
            let handler = mapper.provider.sections[sourceIndexPath.section] as? TableMovingHandler else { return proposedDestinationIndexPath }
        return IndexPath(item: handler.targetIndex(forMoveFrom: sourceIndexPath.item, to: proposedDestinationIndexPath.item), section: sourceIndexPath.section)
    }

    // MARK: - Selection

    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if tableView.isEditing,
            let handler = mapper.provider.sections[indexPath.section] as? TableEditingHandler,
            !handler.allowsSelectionDuringEditing(at: indexPath.item) {
            return false
        }

        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else { return false }
        return handler.shouldHighlight(at: indexPath.item)
    }

    open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else { return nil }
        return handler.shouldSelect(at: indexPath.item) ? indexPath : nil
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else { return }

        if let tableHandler = handler as? TableSelectionHandler, let cell = tableView.cellForRow(at: indexPath) {
            tableHandler.didSelect(at: indexPath.item, cell: cell)
        } else {
            handler.didSelect(at: indexPath.item)
        }

        guard tableView.allowsMultipleSelection, !handler.allowsMultipleSelection else { return }

        let indexPaths = mapping(mapper, selectedIndexesIn: indexPath.section)
            .map { IndexPath(item: $0, section: indexPath.section ) }
            .filter { $0 != indexPath }
        indexPaths.forEach { tableView.deselectRow(at: $0, animated: true) }
    }

    open func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let handler = mapper.provider.sections[indexPath.section] as? TableAccessoryHandler else { return }
        handler.didSelectAccessory(at: indexPath.item)
    }

    open func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else { return nil }
        return handler.shouldDeselect(at: indexPath.item) ? indexPath : nil
    }

    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else { return }
        if let tableHandler = handler as? TableSelectionHandler, let cell = tableView.cellForRow(at: indexPath) {
            tableHandler.didDeselect(at: indexPath.item, cell: cell)
        } else {
            handler.didDeselect(at: indexPath.item)
        }
    }

    // MARK: - Actions

    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let handler = mapper.provider.sections[indexPath.section] as? TableActionsHandler else { return nil }
        return handler.leadingSwipeActions(at: indexPath.item)
    }

    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let handler = mapper.provider.sections[indexPath.section] as? TableActionsHandler else { return nil }
        return handler.trailingSwipeActions(at: indexPath.item)
    }

    // MARK: - Metrics

    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let suggested = tableView.estimatedSectionHeaderHeight == .zero ? tableView.sectionHeaderHeight : tableView.estimatedSectionHeaderHeight
        guard let section = sectionProvider.sections[section] as? TableSectionLayoutHandler else { return suggested }
        let height = section.estimatedHeightForHeader(suggested: suggested, traitCollection: tableView.traitCollection)
        return height < 0 ? section.heightForHeader(suggested: suggested, traitCollection: tableView.traitCollection) : height
    }

    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let suggested = tableView.estimatedSectionFooterHeight == .zero ? tableView.sectionFooterHeight : tableView.estimatedSectionFooterHeight
        guard let section = sectionProvider.sections[section] as? TableSectionLayoutHandler else { return suggested }
        let height = section.estimatedHeightForFooter(suggested: suggested, traitCollection: tableView.traitCollection)
        return height < 0 ? section.heightForFooter(suggested: suggested, traitCollection: tableView.traitCollection) : height
    }

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let suggested = tableView.estimatedRowHeight == .zero ? tableView.rowHeight : tableView.estimatedRowHeight
        guard let section = sectionProvider.sections[indexPath.section] as? TableSectionLayoutHandler else { return suggested }
        let height = section.estimatedHeightForItem(at: indexPath.item, suggested: suggested, traitCollection: tableView.traitCollection)
        return height < 0 ? section.heightForItem(at: indexPath.item, suggested: suggested, traitCollection: tableView.traitCollection) : height
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

extension TableCoordinator: UITableViewDropDelegate {

    public func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return delegate?.coordinator(self, canHandleDropSession: session) ?? false
    }

    public func tableView(_ tableView: UITableView, dropSessionDidEnter session: UIDropSession) {
        delegate?.coordinator(self, dropSessionDidEnter: session)
    }

    public func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        delegate?.coordinator(self, performDropWith: coordinator)
    }

    public func tableView(_ tableView: UITableView, dropSessionDidExit session: UIDropSession) {
        delegate?.coordinator(self, dropSessionDidExit: session)
    }

    public func tableView(_ tableView: UITableView, dropSessionDidEnd session: UIDropSession) {
        delegate?.coordinator(self, dropSessionDidEnd: session)
    }

    public func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        return (sectionProvider.sections[indexPath.section] as? TableDropHandler)?.dropSesion(previewParametersForItemAt: indexPath.item)
    }

}
