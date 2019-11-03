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
        let identifier = prototype?.reuseIdentifier ?? prototypeType.reuseIdentifier
        return identifier.isEmpty ? prototypeType.reuseIdentifier : identifier
    }()

    public let dequeueMethod: DequeueMethod<UITableViewCell>

    private let prototypeProvider: () -> UITableViewCell?
    public let prototypeType: UITableViewCell.Type

    public lazy private(set) var prototype: UITableViewCell? = {
        return prototypeProvider()
    }()

    private weak var section: Section?
    private let configureCell: (UITableViewCell, Int, TableElement<UITableViewCell>.Context) -> Void

    public init<Cell: UITableViewCell, Section: Composed.Section>(section: Section,
                                                                  cellDequeueMethod: DequeueMethod<Cell>,
                                                                  cellReuseIdentifier: String? = nil,
                                                                  cellConfigurator: @escaping (Cell, Int, Section, TableElement<Cell>.Context) -> Void,
                                                                  header: HeaderFooter = .none,
                                                                  footer: HeaderFooter = .none) {
        self.prototypeType = Cell.self
        self.section = section

        self.prototypeProvider = {
            switch cellDequeueMethod {
            case let .class(type):
                return type.init(frame: .zero)
            case let .nib(type):
                let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                return nib.instantiate(withOwner: nil, options: nil).first as? UITableViewCell
            case .storyboard:
                return nil
            }
        }

        switch cellDequeueMethod {
        case let .class(type): self.dequeueMethod = .class(type)
        case let .nib(type): self.dequeueMethod = .nib(type)
        case let .storyboard(type): self.dequeueMethod = .storyboard(type)
        }

        self.configureCell = { [weak section] c, index, context in
            guard let cell = c as? Cell else {
                assertionFailure("Got an unknown cell. Expecting cell of type \(Cell.self), got \(c)")
                return
            }
            guard let section = section else {
                assertionFailure("Asked to configure cell after section has been deallocated")
                return
            }

            let cellContext: TableElement<Cell>.Context
            switch context {
            case .sizing: cellContext = .sizing
            case .presentation: cellContext = .presentation
            }
            
            cellConfigurator(cell, index, section, cellContext)
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

        if let identifier = cellReuseIdentifier {
            self.reuseIdentifier = identifier
        }
    }

    public func configure(cell: UITableViewCell, at index: Int, context: TableElement<UITableViewCell>.Context) {
        configureCell(cell, index, context)
    }

}
