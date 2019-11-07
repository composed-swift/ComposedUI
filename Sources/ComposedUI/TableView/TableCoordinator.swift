import UIKit
import Composed

open class TableCoordinator: NSObject, UITableViewDataSource, SectionProviderMappingDelegate {

    private let mapper: SectionProviderMapping
    private let tableView: UITableView

    private var cachedProviders: [TableProvider] = []

    public init(tableView: UITableView, sectionProvider: SectionProvider) {
        self.tableView = tableView
        mapper = SectionProviderMapping(provider: sectionProvider)

        super.init()

        tableView.dataSource = self
        tableView.delegate = self

        prepareSections()
    }

    private func prepareSections() {
        mapper.delegate = self
        cachedProviders.removeAll()

        let container = Environment.LayoutContainer(contentSize: tableView.bounds.size, effectiveContentSize: tableView.bounds.size)
        let env = Environment(container: container, traitCollection: tableView.traitCollection)

        for index in 0..<mapper.numberOfSections {
            guard let section = (mapper.provider.sections[index] as? TableSectionProvider)?.section(with: env) else {
                fatalError("No provider available for section: \(index), or it does not conform to CollectionSectionProvider")
            }

            if let header = section.header {
                let type = header.prototypeType

                switch header.dequeueMethod {
                case .nib:
                    let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                    tableView.register(nib, forHeaderFooterViewReuseIdentifier: header.reuseIdentifier)
                case .class:
                    tableView.register(type, forHeaderFooterViewReuseIdentifier: header.reuseIdentifier)
                case .storyboard:
                    break
                }
            }

            if let footer = section.footer {
                let type = footer.prototypeType

                switch footer.dequeueMethod {
                case .nib:
                    let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                    tableView.register(nib, forHeaderFooterViewReuseIdentifier: footer.reuseIdentifier)
                case .class:
                    tableView.register(type, forHeaderFooterViewReuseIdentifier: footer.reuseIdentifier)
                case .storyboard:
                    break
                }
            }

            let type = section.prototypeType
            switch section.dequeueMethod {
            case .nib:
                let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                tableView.register(nib, forCellReuseIdentifier: section.reuseIdentifier)
            case .class:
                tableView.register(type, forCellReuseIdentifier: section.reuseIdentifier)
            case .storyboard:
                break
            }

            cachedProviders.append(section)
        }
    }

    // MARK: - SectionProviderMappingDelegate

    public func mappingsDidUpdate(_ mapping: SectionProviderMapping) {
        prepareSections()
        tableView.reloadData()
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertSections sections: IndexSet) {
        prepareSections()
        tableView.insertSections(sections, with: .automatic)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveSections sections: IndexSet) {
        prepareSections()
        tableView.deleteSections(sections, with: .automatic)
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateSections sections: IndexSet) {
        prepareSections()
        tableView.reloadSections(sections, with: .automatic)
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertElementsAt indexPaths: [IndexPath]) {
        tableView.insertRows(at: indexPaths, with: .automatic)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveElementsAt indexPaths: [IndexPath]) {
        tableView.deleteRows(at: indexPaths, with: .automatic)
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
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: header.reuseIdentifier) else { return nil }
        header.configure(view, IndexPath(row: 0, section: section), .sizing)
        return view
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = tableSection(for: section)?.footer else { return nil }
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
        guard let section = tableSection(for: indexPath.section) else {
            fatalError("No UI configuration available for section \(indexPath.section)")
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: section.reuseIdentifier, for: indexPath)
        section.configure(cell: cell, at: indexPath.row, context: .presentation)
        return cell
    }

    private func tableSection(for section: Int) -> TableProvider? {
        guard cachedProviders.indices.contains(section) else { return nil }
        return cachedProviders[section]
    }

}

extension TableCoordinator: UITableViewDelegate {

//    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        guard let section = tableSection(for: indexPath.section), let cell = section.prototype else { return 0 }
//
//        section.configure(cell: cell, at: indexPath.row, context: .sizing)
//
//        let target = CGSize(width: tableView.bounds.width, height: 0)
//        return cell.contentView.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
//    }

}
