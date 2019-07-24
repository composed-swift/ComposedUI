import UIKit
import Composed

open class TableSection: TableProvider {

    public enum HeaderFooter {
        case none
        case title(String)
        case element(TableElement<UITableViewHeaderFooterView>)
    }

    public let header: TableElement<UITableViewHeaderFooterView>?
    public let footer: TableElement<UITableViewHeaderFooterView>?

    open var numberOfElements: Int {
        return section?.numberOfElements ?? 0
    }

    public private(set) lazy var reuseIdentifier: String = {
        return prototype.reuseIdentifier ?? type(of: prototype).reuseIdentifier
    }()

    public let dequeueMethod: DequeueMethod<UITableViewCell>

    private let prototypeProvider: () -> UITableViewCell
    public lazy private(set) var prototype: UITableViewCell = {
        return prototypeProvider()
    }()

    private weak var section: Section?
    private let configureCell: (UITableViewCell, Int, TableElement<UITableViewCell>.Context) -> Void

    public init<Cell: UITableViewCell, Section: Composed.Section>(section: Section,
                                                                  prototype: @escaping @autoclosure () -> Cell,
                                                                  cellDequeueMethod: DequeueMethod<Cell>,
                                                                  cellReuseIdentifier: String? = nil,
                                                                  cellConfigurator: @escaping (Cell, Int, Section, TableElement<Cell>.Context) -> Void,
                                                                  header: HeaderFooter = .none,
                                                                  footer: HeaderFooter = .none) {
        self.section = section
        self.prototypeProvider = prototype
        self.dequeueMethod = cellDequeueMethod as! DequeueMethod<UITableViewCell>

        self.configureCell = { [weak section] c, index, context in
            guard let cell = c as? Cell else {
                assertionFailure("Got an unknown cell. Expecting cell of type \(Cell.self), got \(c)")
                return
            }
            guard let section = section else {
                assertionFailure("Asked to configure cell after section has been deallocated")
                return
            }
            cellConfigurator(cell, index, section, context as! TableElement<Cell>.Context)
        }

        switch header {
        case .none:
            self.header = nil
        case let .title(text):
            self.header = TableElement(prototype: .init(frame: .zero), dequeueMethod: .class(UITableViewHeaderFooterView.self), { view, indexPath, _ in
                view.textLabel?.text = text
            })
        case let .element(element):
            self.header = element
        }

        switch footer {
        case .none:
            self.footer = nil
        case let .title(text):
            self.footer = TableElement(prototype: .init(frame: .zero), dequeueMethod: .class(UITableViewHeaderFooterView.self), { view, indexPath, _ in
                view.textLabel?.text = text
            })
        case let .element(element):
            self.footer = element
        }
    }

    public func configure(cell: UITableViewCell, at index: Int, context: TableElement<UITableViewCell>.Context) {
        configureCell(cell, index, context)
    }

}
