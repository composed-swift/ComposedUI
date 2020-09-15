import UIKit
import Composed

/// Conform to this protocol to receive `TableCoordinator` events
public protocol TableCoordinatorDelegate: class {

    /// Return a background view to be shown in the `UITableView` when its content is empty. Defaults to nil
    /// - Parameters:
    ///   - coordinator: The coordinator that manages this table view
    ///   - tableView: The table view that will show this background view
    func coordinator(_ coordinator: TableCoordinator, backgroundViewInTableView tableView: UITableView) -> UIView?

    /// Called whenever the coordinator's content updates
    /// - Parameter coordinator: The coordinator that manages the updates
    func coordinatorDidUpdate(_ coordinator: TableCoordinator)

}

/// The coordinator that provides the 'glue' between a section provider and a `UITableView`
public extension TableCoordinatorDelegate {
    func coordinator(_ coordinator: TableCoordinator, backgroundViewInTableView tableView: UITableView) -> UIView? { return nil }
    func coordinatorDidUpdate(_ coordinator: TableCoordinator) { }
}

open class TableCoordinator: NSObject {

    /// Get/set the delegate for this coordinator
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
    private var delegateObserver: NSKeyValueObservation?

    private weak var originalDataSource: UITableViewDataSource?
    private var dataSourceObserver: NSKeyValueObservation?

    private var cachedProviders: [TableElementsProvider] = []

    /// Make a new coordinator with the specified tableView and sectionProvider
    /// - Parameters:
    ///   - tableView: The tableView to associate with this coordinator
    ///   - sectionProvider: The sectionProvider to associate with this coordinator
    public init(tableView: UITableView, sectionProvider: SectionProvider) {
        self.tableView = tableView
        mapper = SectionProviderMapping(provider: sectionProvider)

        super.init()

        tableView.dataSource = self
        prepareSections()

        delegateObserver = tableView.observe(\.delegate, options: [.initial, .new]) { [weak self] tableView, _ in
            guard tableView.delegate !== self else { return }
            self?.originalDelegate = tableView.delegate
            tableView.delegate = self
        }

        dataSourceObserver = tableView.observe(\.dataSource, options: [.initial, .new]) { [weak self] tableView, _ in
            guard tableView.dataSource !== self else { return }
            self?.originalDataSource = tableView.dataSource
            tableView.dataSource = self
        }
    }

    open func replace(sectionProvider: SectionProvider) {
        mapper = SectionProviderMapping(provider: sectionProvider)
        prepareSections()
        tableView.reloadData()
    }

    public func setEditing(_ editing: Bool, animated: Bool) {
        tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: animated) }

        for (index, section) in sectionProvider.sections.enumerated() {
            guard let handler = section as? EditingHandler else { continue }
            handler.didSetEditing(editing)

            for item in 0..<section.numberOfElements {
                let indexPath = IndexPath(item: item, section: index)

                if let handler = handler as? TableEditingHandler, let cell = tableView.cellForRow(at: indexPath) {
                    handler.didSetEditing(editing, at: item, cell: cell, animated: animated)
                } else {
                    handler.didSetEditing(editing, at: item)
                }
            }
        }
    }


    private func prepareSections() {
        mapper.delegate = self
        cachedProviders.removeAll()

        for index in 0..<mapper.numberOfSections {
            guard let section = (mapper.provider.sections[index] as? TableSectionProvider)?.section(with: tableView.traitCollection) else {
                fatalError("No provider available for section: \(index), or it does not conform to TableSectionProvider")
            }

            switch section.cell.dequeueMethod {
            case let .fromNib(type):
                let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                tableView.register(nib, forCellReuseIdentifier: section.cell.reuseIdentifier)
            case let .fromClass(type):
                tableView.register(type, forCellReuseIdentifier: section.cell.reuseIdentifier)
            case .fromStoryboard:
                break
            }

            [section.header, section.footer].compactMap { $0 }.forEach {
                switch $0.dequeueMethod {
                case let .fromNib(type):
                    let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                    tableView.register(nib, forHeaderFooterViewReuseIdentifier: $0.reuseIdentifier)
                case let .fromClass(type):
                    tableView.register(type, forHeaderFooterViewReuseIdentifier: $0.reuseIdentifier)
                case .fromStoryboard:
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

    public func mappingDidInvalidate(_ mapping: SectionProviderMapping) {
        assert(Thread.isMainThread)
        reset()
        prepareSections()
        tableView.reloadData()
    }

    public func mappingWillBeginUpdating(_ mapping: SectionProviderMapping) {
        reset()
        defersUpdate = true
    }

    public func mappingDidEndUpdating(_ mapping: SectionProviderMapping) {
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
            self?.reset()
            self?.defersUpdate = false
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
        mappingDidEndUpdating(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertSections sections: IndexSet) {
        assert(Thread.isMainThread)
        sectionInserts.append { [weak self] in
            guard let self = self else { return }
            if !self.defersUpdate { self.prepareSections() }
            self.tableView.insertSections(sections, with: .fade)
        }
        if defersUpdate { return }
        mappingDidEndUpdating(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveSections sections: IndexSet) {
        assert(Thread.isMainThread)
        sectionRemoves.append { [weak self] in
            guard let self = self else { return }
            if !self.defersUpdate { self.prepareSections() }
            self.tableView.deleteSections(sections, with: .fade)
        }
        if defersUpdate { return }
        mappingDidEndUpdating(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertElementsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)
        inserts.append { [weak self] in
            guard let self = self else { return }
            self.tableView.insertRows(at: indexPaths, with: .automatic)
        }
        if defersUpdate { return }
        mappingDidEndUpdating(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveElementsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)
        removes.append { [weak self] in
            guard let self = self else { return }
            self.tableView.deleteRows(at: indexPaths, with: .automatic)
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
                guard let section = self.sectionProvider.sections[indexPath.section] as? TableUpdateHandler,
                    !section.prefersReload(forElementAt: indexPath.item),
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
        mappingDidEndUpdating(mapping)
    }

    public func mapping(_ mapping: SectionProviderMapping, didMoveElementsAt moves: [(IndexPath, IndexPath)]) {
        assert(Thread.isMainThread)
        self.moves.append { [weak self] in
            guard let self = self else { return }
            moves.forEach { self.tableView.moveRow(at: $0.0, to: $0.1) }
        }
        if defersUpdate { return }
        mappingDidEndUpdating(mapping)
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

    public func mapping(_ mapping: SectionProviderMapping, move sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
    }
    
}

// MARK: - UITableViewDataSource

extension TableCoordinator: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        assert(Thread.isMainThread)
        defer {
            originalDelegate?.tableView?(tableView, willDisplayHeaderView: view, forSection: section)
        }

        let elements = elementsProvider(for: section)
        let s = mapper.provider.sections[section]
        elements.header?.willAppear(view, section, s)
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = elementsProvider(for: section).header else {
            return originalDelegate?.tableView?(tableView, viewForHeaderInSection: section) ?? nil
        }
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: header.reuseIdentifier) else { return nil }
        header.configure(view, section, mapper.provider.sections[section])
        return view
    }

    public func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
        assert(Thread.isMainThread)
        defer {
            originalDelegate?.tableView?(tableView, didEndDisplayingHeaderView: view, forSection: section)
        }

        guard section < sectionProvider.numberOfSections else { return }
        let elements = elementsProvider(for: section)
        let s = mapper.provider.sections[section]
        elements.header?.didDisappear(view, section, s)
    }

    public func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        assert(Thread.isMainThread)
        defer {
            originalDelegate?.tableView?(tableView, willDisplayFooterView: view, forSection: section)
        }

        let elements = elementsProvider(for: section)
        let s = mapper.provider.sections[section]
        elements.footer?.willAppear(view, section, s)
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = elementsProvider(for: section).footer else {
            return originalDelegate?.tableView?(tableView, viewForFooterInSection: section) ?? nil
        }

        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: footer.reuseIdentifier) else { return nil }
        footer.configure(view, section, mapper.provider.sections[section])
        return view
    }

    public func tableView(_ tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int) {
        assert(Thread.isMainThread)
        defer {
            originalDelegate?.tableView?(tableView, didEndDisplayingFooterView: view, forSection: section)
        }

        let elements = elementsProvider(for: section)
        let s = mapper.provider.sections[section]
        elements.footer?.didDisappear(view, section, s)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return mapper.numberOfSections
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return elementsProvider(for: section).numberOfElements
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        assert(Thread.isMainThread)
        defer {
            originalDelegate?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
        }

        let elements = elementsProvider(for: indexPath.section)
        let section = mapper.provider.sections[indexPath.section]
        elements.cell.willAppear(cell, indexPath.item, section)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let elements = elementsProvider(for: indexPath.section)
        let cell = tableView.dequeueReusableCell(withIdentifier: elements.cell.reuseIdentifier, for: indexPath)

        if let handler = sectionProvider.sections[indexPath.section] as? EditingHandler {
            if let handler = sectionProvider.sections[indexPath.section] as? TableEditingHandler {
                handler.didSetEditing(tableView.isEditing, at: indexPath.item, cell: cell, animated: false)
            } else {
                handler.didSetEditing(tableView.isEditing, at: indexPath.item)
            }
        }

        elements.cell.configure(cell, indexPath.row, mapper.provider.sections[indexPath.section])
        return cell
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        assert(Thread.isMainThread)
        defer {
            originalDelegate?.tableView?(tableView, didEndDisplaying: cell, forRowAt: indexPath)
        }

        guard indexPath.section < sectionProvider.numberOfSections else { return }
        let elements = elementsProvider(for: indexPath.section)
        let section = mapper.provider.sections[indexPath.section]
        elements.cell.didDisappear(cell, indexPath.item, section)
    }

    private func elementsProvider(for section: Int) -> TableElementsProvider {
        guard cachedProviders.indices.contains(section) else {
            fatalError("No UI configuration available for section \(section)")
        }
        return cachedProviders[section]
    }

}

@available(iOS 13.0, *)
extension TableCoordinator {

    // MARK: - Context Menus

    open func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let provider = mapper.provider.sections[indexPath.section] as? TableContextMenuHandler,
              provider.allowsContextMenu(forElementAt: indexPath.item),
              let cell = tableView.cellForRow(at: indexPath) else {
            return originalDelegate?.tableView?(tableView, contextMenuConfigurationForRowAt: indexPath, point: point) ?? nil
        }

        let preview = provider.contextMenu(previewForElementAt: indexPath.item, cell: cell)
        return UIContextMenuConfiguration(identifier: indexPath.string, previewProvider: preview) { suggestedElements in
            return provider.contextMenu(forElementAt: indexPath.item, cell: cell, suggestedActions: suggestedElements)
        }
    }

    open func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else {
            return originalDelegate?.tableView?(tableView, previewForHighlightingContextMenuWithConfiguration: configuration) ?? nil
        }

        guard let cell = tableView.cellForRow(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? TableContextMenuHandler else { return nil }
        return provider.contextMenu(previewForHighlightingElementAt: indexPath.item, cell: cell)
    }

    open func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else {
            return originalDelegate?.tableView?(tableView, previewForDismissingContextMenuWithConfiguration: configuration) ?? nil
        }

        guard let cell = tableView.cellForRow(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? TableContextMenuHandler else { return nil }
        return provider.contextMenu(previewForDismissingElementAt: indexPath.item, cell: cell)
    }

    open func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        defer {
            originalDelegate?.tableView?(tableView, willPerformPreviewActionForMenuWith: configuration, animator: animator)
        }

        guard let identifier = configuration.identifier as? String, let indexPath = IndexPath(string: identifier) else { return }
        guard let cell = tableView.cellForRow(at: indexPath),
            let provider = mapper.provider.sections[indexPath.section] as? TableContextMenuHandler else { return }

        provider.contextMenu(willPerformPreviewActionForElementAt: indexPath.item, cell: cell, animator: animator)
    }

}

extension TableCoordinator: UITableViewDelegate {

    // MARK: - Editing

    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let handler = mapper.provider.sections[indexPath.section] as? TableEditingHandler else {
            return originalDataSource?.tableView?(tableView, canEditRowAt: indexPath) ?? false
        }
        return handler.allowsEditing(at: indexPath.item)
    }

    open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard let handler = mapper.provider.sections[indexPath.section] as? TableEditingHandler else {
            return originalDelegate?.tableView?(tableView, editingStyleForRowAt: indexPath) ?? .none
        }
        return handler.editingStyle(at: indexPath.item)
    }

    open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        defer {
            originalDataSource?.tableView?(tableView, commit: editingStyle, forRowAt: indexPath)
        }

        guard let handler = mapper.provider.sections[indexPath.section] as? TableEditingHandler else { return }
        handler.commitEditing(at: indexPath.item, editingStyle: editingStyle)
    }

    open func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        defer {
            originalDelegate?.tableView?(tableView, willBeginEditingRowAt: indexPath)
        }

        guard let handler = mapper.provider.sections[indexPath.section] as? EditingHandler else { return }

        if let handler = handler as? TableEditingHandler, let cell = tableView.cellForRow(at: indexPath) {
            handler.didSetEditing(true, at: indexPath.item, cell: cell, animated: true)
        } else {
            handler.didSetEditing(true, at: indexPath.item)
        }
    }

    open func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        defer {
            originalDelegate?.tableView?(tableView, didEndEditingRowAt: indexPath)
        }

        guard let indexPath = indexPath, let handler = mapper.provider.sections[indexPath.section] as? EditingHandler else { return }

        if let handler = handler as? TableEditingHandler, let cell = tableView.cellForRow(at: indexPath) {
            handler.didSetEditing(false, at: indexPath.item, cell: cell, animated: true)
        } else {
            handler.didSetEditing(true, at: indexPath.item)
        }
    }

    // MARK: - Moving

    public func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard sourceIndexPath.section == proposedDestinationIndexPath.section else { return sourceIndexPath }
        let item = (mapper.provider.sections[sourceIndexPath.section] as? MoveHandler)?
            .targetIndex(sourceIndex: sourceIndexPath.item, proposedIndex: proposedDestinationIndexPath.item)
            ?? proposedDestinationIndexPath.item
        return IndexPath(item: item, section: sourceIndexPath.section)
    }

    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return (mapper.provider.sections[indexPath.section] as? MoveHandler)?.canMove(index: indexPath.item) ?? false
    }

    open func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        guard let handler = mapper.provider.sections[indexPath.section] as? TableEditingHandler else {
            return originalDelegate?.tableView?(tableView, shouldIndentWhileEditingRowAt: indexPath) ?? true
        }

        return handler.editingStyle(at: indexPath.item) == .none ? false : handler.shouldIndentWhileEditing(at: indexPath.item)
    }

    open func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        defer {
            originalDataSource?.tableView?(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
        }

        guard sourceIndexPath.section == destinationIndexPath.section,
            let handler = mapper.provider.sections[sourceIndexPath.section] as? MoveHandler else {
                return
        }

        handler.didMove(sourceIndexes: IndexSet(integer: sourceIndexPath.item), to: destinationIndexPath.item)
    }

    // MARK: - Selection

    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if tableView.isEditing,
            let handler = mapper.provider.sections[indexPath.section] as? TableEditingHandler,
            !handler.allowsSelectionDuringEditing(at: indexPath.item) {
            return originalDelegate?.tableView?(tableView, shouldHighlightRowAt: indexPath) ?? false
        }

        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else { return false }
        return handler.shouldHighlight(at: indexPath.item)
    }

    open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else {
            return originalDelegate?.tableView?(tableView, willSelectRowAt: indexPath) ?? nil
        }
        return handler.shouldSelect(at: indexPath.item) ? indexPath : nil
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            originalDelegate?.tableView?(tableView, didSelectRowAt: indexPath)
        }

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
        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else {
            return originalDelegate?.tableView?(tableView, willDeselectRowAt: indexPath) ?? nil
        }
        return handler.shouldDeselect(at: indexPath.item) ? indexPath : nil
    }

    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        defer {
            originalDelegate?.tableView?(tableView, didDeselectRowAt: indexPath)
        }

        guard let handler = mapper.provider.sections[indexPath.section] as? SelectionHandler else { return }
        if let tableHandler = handler as? TableSelectionHandler, let cell = tableView.cellForRow(at: indexPath) {
            tableHandler.didDeselect(at: indexPath.item, cell: cell)
        } else {
            handler.didDeselect(at: indexPath.item)
        }
    }

    // MARK: - Actions

    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let handler = mapper.provider.sections[indexPath.section] as? TableActionsHandler else {
            return originalDelegate?.tableView?(tableView, leadingSwipeActionsConfigurationForRowAt: indexPath) ?? nil
        }
        return handler.leadingSwipeActions(at: indexPath.item)
    }

    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let handler = mapper.provider.sections[indexPath.section] as? TableActionsHandler else {
            return originalDelegate?.tableView?(tableView, trailingSwipeActionsConfigurationForRowAt: indexPath) ?? nil
        }
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

    public func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if destinationIndexPath == nil {
            return (originalDelegate as? UITableViewDropDelegate)?
                .tableView?(tableView, dropSessionDidUpdate: session, withDestinationIndexPath: destinationIndexPath)
                ?? UITableViewDropProposal(operation: .forbidden)
        }

        guard let indexPath = destinationIndexPath, let section = sectionProvider.sections[indexPath.section] as? TableDropHandler else {
            return (originalDelegate as? UITableViewDropDelegate)?
                .tableView?(tableView, dropSessionDidUpdate: session, withDestinationIndexPath: destinationIndexPath)
                ?? UITableViewDropProposal(operation: .forbidden)
        }

        return section.dropSessionDidUpdate(session, destinationIndex: indexPath.item)
    }

    public func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        (originalDelegate as? UITableViewDropDelegate)?.tableView(tableView, performDropWith: coordinator)
    }

    public func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let section = sectionProvider.sections[indexPath.section] as? TableDropHandler else {
            return (originalDelegate as? UITableViewDropDelegate)?.tableView?(tableView, dropPreviewParametersForRowAt: indexPath)
        }
        return section.dropSesion(previewParametersForItemAt: indexPath.item)
    }

}

public extension TableCoordinator {

    /// A convenience initializer that allows creation without a provider
    /// - Parameters:
    ///   - collectionView: The collectionView associated with this coordinator
    ///   - sections: The sections associated with this coordinator
    convenience init(tableView: UITableView, sections: Section...) {
        let provider = ComposedSectionProvider()
        sections.forEach(provider.append(_:))
        self.init(tableView: tableView, sectionProvider: provider)
    }

}
