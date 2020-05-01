import UIKit
import Composed

/// A table view can provide headers and footers via custom views or a simple string, this provides a solution for specifying which option to use
public enum TableHeaderFooter<View> where View: UITableViewHeaderFooterView {
    /// A title will be usef for this element
    case title(String)
    /// A custom view will be used for this element
    case element(TableElement<View>)
}

/// Defines a configuration for a section in a `UITableView`.
/// The section must contain a cell element, but can also optionally include a header and/or footer element.
open class TableSection: TableElementsProvider {

    /// The cell configuration element
    public let cell: TableElement<UITableViewCell>

    /// The header configuration element
    public let header: TableElement<UITableViewHeaderFooterView>?

    /// The footer configuration element
    public let footer: TableElement<UITableViewHeaderFooterView>?

    /// The number of elements in this section
    open var numberOfElements: Int {
        return section?.numberOfElements ?? 0
    }

    // The underlying section associated with this section
    private weak var section: Section?

    /// Makes a new configuration with the specified cell, header and/or footer elements
    /// - Parameters:
    ///   - section: The section this will be associated with
    ///   - cell: The cell configuration element
    ///   - header: The header configuration element
    ///   - footer: The footer configuration element
    public init<Section, Cell, Header, Footer>(section: Section,
                                               cell: TableElement<Cell>,
                                               header: TableHeaderFooter<Header>? = nil,
                                               footer: TableHeaderFooter<Footer>? = nil)
        where Section: Composed.Section, Cell: UITableViewCell, Header: UITableViewHeaderFooterView, Footer: UITableViewHeaderFooterView {
            self.section = section

            let dequeueMethod: DequeueMethod<UITableViewCell>
            switch cell.dequeueMethod {
            case .fromClass: dequeueMethod = .fromClass(Cell.self)
            case .fromNib: dequeueMethod = .fromNib(Cell.self)
            case .fromStoryboard: dequeueMethod = .fromStoryboard(Cell.self)
            }

            self.cell = TableElement(section: section,
                                     dequeueMethod: dequeueMethod,
                                     reuseIdentifier: cell.reuseIdentifier,
                                     configure: cell.configure)

            switch header {
            case .none:
                self.header = nil
            case let .title(title):
                self.header = TableElement(section: section, dequeueMethod: .fromClass(Header.self)) { view, _, _ in
                    view.textLabel?.text = title
                }
            case let .element(element):
                let dequeueMethod: DequeueMethod<UITableViewHeaderFooterView>
                switch element.dequeueMethod {
                case .fromClass: dequeueMethod = .fromClass(Header.self)
                case .fromNib: dequeueMethod = .fromNib(Header.self)
                case .fromStoryboard: dequeueMethod = .fromStoryboard(Header.self)
                }

                self.header = TableElement(section: section,
                                           dequeueMethod: dequeueMethod,
                                           reuseIdentifier: element.reuseIdentifier,
                                           configure: element.configure)
            }

            switch footer {
            case .none:
                self.footer = nil
            case let .title(title):
                self.footer = TableElement(section: section, dequeueMethod: .fromClass(Footer.self)) { view, _, _ in
                    view.textLabel?.text = title
                }
            case let .element(element):
                let dequeueMethod: DequeueMethod<UITableViewHeaderFooterView>
                switch element.dequeueMethod {
                case .fromClass: dequeueMethod = .fromClass(Footer.self)
                case .fromNib: dequeueMethod = .fromNib(Footer.self)
                case .fromStoryboard: dequeueMethod = .fromStoryboard(Footer.self)
                }

                self.footer = TableElement(section: section,
                                           dequeueMethod: dequeueMethod,
                                           reuseIdentifier: element.reuseIdentifier,
                                           configure: element.configure)
            }
    }

}
