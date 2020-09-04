import UIKit
import Composed

open class UITableSection<S>: UISection, TableSectionProvider where S: Section {

    public let section: S
    public var numberOfElements: Int { return section.numberOfElements }
    public weak var updateDelegate: SectionUpdateDelegate?

    private let cell: TableElement<UITableViewCell>
    private var header: TableElement<UITableViewHeaderFooterView>?
    private var footer: TableElement<UITableViewHeaderFooterView>?

    public lazy var selectionHandlers = SelectionHandlers()
    public lazy var editingHandlers = EditingHandlers()
    public lazy var reoderingHandlers = ReorderingHandlers()

    public init<Cell>(section: S, dequeueMethod: DequeueMethod<Cell>, _ cellHandler: @escaping (Cell, Int, S) -> Void) where Cell: UITableViewCell {
        self.section = section

        cell = TableElement(section: section, dequeueMethod: dequeueMethod.map()) { cell, index, section in
            cellHandler(cell as! Cell, index, section)
        }
    }

    public func headerProvider<View>(configuration: UISectionView<S, View>?) -> UITableSection<S> where View: UITableViewHeaderFooterView {
        header = supplementaryViewProvider(configuration: configuration)
        return self
    }

    public func footerProvider<View>(configuration: UISectionView<S, View>?) -> UITableSection<S> where View: UITableViewHeaderFooterView {
        footer = supplementaryViewProvider(configuration: configuration)
        return self
    }

    private func supplementaryViewProvider<View>(configuration: UISectionView<S, View>?) -> TableElement<UITableViewHeaderFooterView>? where View: UITableViewHeaderFooterView {
        guard let configuration = configuration else { return nil }
        return TableElement(section: section, dequeueMethod: configuration.dequeueMethod.map()) { view, index, section in
            configuration.viewHandler(view as! View, index, section)
        }
    }

    public func section(with traitCollection: UITraitCollection) -> TableSection {
        return TableSection(section: section, cell: cell)
    }

}
