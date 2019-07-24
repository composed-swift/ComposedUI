import UIKit
import Composed

open class TableSection: TableProvider {

    public let header: TableElement<UITableViewHeaderFooterView>?
    public let footer: TableElement<UITableViewHeaderFooterView>?

    open var numberOfElements: Int {
        return section?.numberOfElements ?? 0
    }

    public private(set) lazy var reuseIdentifier: String = {
        return prototype.reuseIdentifier ?? type(of: prototype).reuseIdentifier
    }()

    public let dequeueMethod: DequeueMethod

    private let prototypeProvider: () -> UITableViewCell
    private var _prototypeView: UITableViewCell?

    public var prototype: UITableViewCell {
        if let view = _prototypeView { return view }
        let view = prototypeProvider()
        _prototypeView = view
        return view
    }

    private weak var section: Section?
    private let configureCell: (UITableViewCell, Int) -> Void

    public init<Cell: UITableViewCell, Section: Composed.Section>(section: Section,
                                                                  prototype: @escaping @autoclosure () -> Cell,
                                                                  cellDequeueMethod: DequeueMethod,
                                                                  cellReuseIdentifier: String? = nil,
                                                                  cellConfigurator: @escaping (Cell, Int, Section) -> Void,
                                                                  header: String?,
                                                                  footer: String?) {
        self.section = section
        self.prototypeProvider = prototype
        self.dequeueMethod = cellDequeueMethod
        self.configureCell = { [weak section] c, index in
            guard let cell = c as? Cell else {
                assertionFailure("Got an unknown cell. Expecting cell of type \(Cell.self), got \(c)")
                return
            }
            guard let section = section else {
                assertionFailure("Asked to configure cell after section has been deallocated")
                return
            }
            cellConfigurator(cell, index, section)
        }

        if let header = header {
            self.header = TableElement<UITableViewHeaderFooterView>(prototype: UITableViewHeaderFooterView(frame: .zero), dequeueMethod: .class, { view, indexPath, _ in
                view.textLabel?.text = header
            })
        } else {
            self.header = nil
        }

        if let footer = footer {
            self.footer = TableElement<UITableViewHeaderFooterView>(prototype: UITableViewHeaderFooterView(frame: .zero), dequeueMethod: .class, { view, indexPath, _ in
                view.textLabel?.text = footer
            })
        } else {
            self.footer = nil
        }
    }

    public init<Cell: UITableViewCell, Section: Composed.Section>(section: Section,
                                                                  prototype: @escaping @autoclosure () -> Cell,
                                                                  cellDequeueMethod: DequeueMethod,
                                                                  cellReuseIdentifier: String? = nil,
                                                                  cellConfigurator: @escaping (Cell, Int, Section) -> Void,
                                                                  header: TableElement<UITableViewHeaderFooterView>?,
                                                                  footer: TableElement<UITableViewHeaderFooterView>?) {
        self.section = section
        self.prototypeProvider = prototype
        self.dequeueMethod = cellDequeueMethod
        self.configureCell = { [weak section] c, index in
            guard let cell = c as? Cell else {
                assertionFailure("Got an unknown cell. Expecting cell of type \(Cell.self), got \(c)")
                return
            }
            guard let section = section else {
                assertionFailure("Asked to configure cell after section has been deallocated")
                return
            }
            cellConfigurator(cell, index, section)
        }
        self.header = header
        self.footer = footer
    }

    public func configure(cell: UITableViewCell, at index: Int) {
        configureCell(cell, index)
    }

}
