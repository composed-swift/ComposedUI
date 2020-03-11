import UIKit
import Composed

public enum TableHeaderFooter<View> where View: UITableViewHeaderFooterView {
    case title(String)
    case element(TableElement<View>)
}

open class TableSection: TableElementsProvider {

    public let cell: TableElement<UITableViewCell>
    public let header: TableElement<UITableViewHeaderFooterView>?
    public let footer: TableElement<UITableViewHeaderFooterView>?

    open var numberOfElements: Int {
        return section?.numberOfElements ?? 0
    }

    private weak var section: Section?

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
