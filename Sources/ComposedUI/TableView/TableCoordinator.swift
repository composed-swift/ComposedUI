import UIKit
import Composed

public final class TableCoordinator: NSObject, UITableViewDataSource, UITableViewDelegate, SectionProviderMappingDelegate {

    private let mapper: SectionProviderMapping
    private let tableView: UITableView

    public init(tableView: UITableView, sectionProvider: SectionProvider) {
        self.tableView = tableView
        mapper = SectionProviderMapping(provider: sectionProvider)

        super.init()

        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - SectionProviderMappingDelegate

    public func mapping(_ mapping: SectionProviderMapping, didInsertSections sections: IndexSet) {
        tableView.insertSections(sections, with: .automatic)
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertElementsAt indexPaths: [IndexPath]) {
        tableView.insertRows(at: indexPaths, with: .automatic)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveSections sections: IndexSet) {
        tableView.deleteSections(sections, with: .automatic)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveElementsAt indexPaths: [IndexPath]) {
        tableView.deleteRows(at: indexPaths, with: .automatic)
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateSections sections: IndexSet) {
        tableView.reloadSections(sections, with: .automatic)
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateElementsAt indexPaths: [IndexPath]) {
        tableView.reloadRows(at: indexPaths, with: .automatic)
    }

    public func mapping(_ mapping: SectionProviderMapping, didMoveElementsAt moves: [(IndexPath, IndexPath)]) {
        moves.forEach {
            tableView.moveRow(at: $0.0, to: $0.1)
        }
    }

    // MARK: - UITableViewDataSource

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableSection(for: section)?.header else { return nil }

        let type = Swift.type(of: header.prototype)
        switch header.dequeueMethod {
        case .nib:
            let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
            tableView.register(nib, forHeaderFooterViewReuseIdentifier: header.reuseIdentifier)
        case .class:
            tableView.register(type, forHeaderFooterViewReuseIdentifier: header.reuseIdentifier)
        }

        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: header.reuseIdentifier) else { return nil }
        header.configure(view, IndexPath(row: 0, section: section), .sizing)
        return view
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = tableSection(for: section)?.footer else { return nil }

        let type = Swift.type(of: footer.prototype)
        switch footer.dequeueMethod {
        case .nib:
            let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
            tableView.register(nib, forHeaderFooterViewReuseIdentifier: footer.reuseIdentifier)
        case .class:
            tableView.register(type, forHeaderFooterViewReuseIdentifier: footer.reuseIdentifier)
        }

        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: footer.reuseIdentifier) else { return nil }
        footer.configure(view, IndexPath(row: 0, section: section), .sizing)
        return view
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return mapper.numberOfSections
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableSection(for: section)?.numberOfElements ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let configuration = tableSection(for: indexPath.section) else {
            fatalError("No UI configuration available for section \(indexPath.section)")
        }

        let type = Swift.type(of: configuration.prototype)
        switch configuration.dequeueMethod {
        case .nib:
            let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
            tableView.register(nib, forCellReuseIdentifier: configuration.reuseIdentifier)
        case .class:
            tableView.register(type, forCellReuseIdentifier: configuration.reuseIdentifier)
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: configuration.reuseIdentifier, for: indexPath)
        configuration.configure(cell: cell, at: indexPath.row)
        return cell
    }

    private func tableSection(for section: Int) -> TableProvider? {
        return (mapper.provider.sections[section] as? TableSectionProvider)?.tableSection
    }

}
