import UIKit
import Composed

public protocol TableCoordinatorDelegate: class {
    func coordinator(tableView: UITableView, heightForHeaderIn section: Int) -> CGFloat
    func coordinator(tableView: UITableView, heightForFooterIn section: Int) -> CGFloat
    func coordinator(tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
}

open class TableCoordinator: NSObject {

    public weak var delegate: TableCoordinatorDelegate?

    private var mapper: SectionProviderMapping
    private var updateOperation: BlockOperation?
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
                fatalError("No provider available for section: \(index), or it does not conform to CollectionSectionProvider")
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
            .compactMap { $0 as? SelectionProvider }
            .contains { $0.allowsMultipleSelection }
    }

}

// MARK: - SectionProviderMappingDelegate

extension TableCoordinator: SectionProviderMappingDelegate {

    public func mappingDidReload(_ mapping: SectionProviderMapping) {
        prepareSections()
        tableView.reloadData()
    }

    public func mappingWillUpdate(_ mapping: SectionProviderMapping) {
        updateOperation = BlockOperation()
    }

    public func mappingDidUpdate(_ mapping: SectionProviderMapping) {
        tableView.performBatchUpdates({
            prepareSections()
            updateOperation?.start()
        }, completion: nil)
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertSections sections: IndexSet) {
        let block = { [unowned self] in
            self.prepareSections()
            self.tableView.insertSections(sections, with: .automatic)
        }
        updateOperation.flatMap { $0.addExecutionBlock(block) } ?? block()
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveSections sections: IndexSet) {
        let block = { [unowned self] in
            self.prepareSections()
            self.tableView.deleteSections(sections, with: .automatic)
        }
        updateOperation.flatMap { $0.addExecutionBlock(block) } ?? block()
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateSections sections: IndexSet) {
        let block = { [unowned self] in
            self.prepareSections()
            self.tableView.reloadSections(sections, with: .automatic)
        }
        updateOperation.flatMap { $0.addExecutionBlock(block) } ?? block()
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertElementsAt indexPaths: [IndexPath]) {
        let block = { [unowned self] in
            self.tableView.insertRows(at: indexPaths, with: .automatic)
        }
        updateOperation.flatMap { $0.addExecutionBlock(block) } ?? block()
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveElementsAt indexPaths: [IndexPath]) {
        let block = { [unowned self] in
            self.tableView.deleteRows(at: indexPaths, with: .automatic)
        }
        updateOperation.flatMap { $0.addExecutionBlock(block) } ?? block()
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateElementsAt indexPaths: [IndexPath]) {
        let block = { [unowned self] in
            self.tableView.reloadRows(at: indexPaths, with: .automatic)
        }
        updateOperation.flatMap { $0.addExecutionBlock(block) } ?? block()
    }

    public func mapping(_ mapping: SectionProviderMapping, didMoveElementsAt moves: [(IndexPath, IndexPath)]) {
        let block = { [unowned self] in
            moves.forEach {
                self.tableView.moveRow(at: $0.0, to: $0.1)
            }
        }
        updateOperation.flatMap { $0.addExecutionBlock(block) } ?? block()
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

extension TableCoordinator: UITableViewDelegate {

    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let provider = mapper.provider.sections[indexPath.section] as? SelectionProvider else { return true }
        return provider.shouldHighlight(at: indexPath.item)
    }

    open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let provider = mapper.provider.sections[indexPath.section] as? SelectionProvider else { return nil }
        return provider.shouldSelect(at: indexPath.item) ? indexPath : nil
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let provider = mapper.provider.sections[indexPath.section] as? SelectionProvider else { return }
        provider.didSelect(at: indexPath.item)
        guard tableView.allowsMultipleSelection else { return }
    }

    open func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let provider = mapper.provider.sections[indexPath.section] as? SelectionProvider else { return nil }
        return provider.shouldDeselect(at: indexPath.item) ? indexPath : nil
    }

    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let provider = mapper.provider.sections[indexPath.section] as? SelectionProvider else { return }
        provider.didDeselect(at: indexPath.item)

        guard tableView.allowsMultipleSelection, !provider.allowsMultipleSelection else { return }

        let indexPaths = mapping(mapper, selectedIndexesIn: indexPath.section)
            .map { IndexPath(item: $0, section: indexPath.section ) }
            .filter { $0 != indexPath }
        indexPaths.forEach { tableView.deselectRow(at: $0, animated: true) }
    }

    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let delegate = delegate else { return UITableView.automaticDimension }
        return delegate.coordinator(tableView: tableView, heightForHeaderIn: section)
    }

    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let delegate = delegate else { return UITableView.automaticDimension }
        return delegate.coordinator(tableView: tableView, heightForFooterIn: section)
    }

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let delegate = delegate else { return UITableView.automaticDimension }
        return delegate.coordinator(tableView: tableView, heightForRowAt: indexPath)
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
