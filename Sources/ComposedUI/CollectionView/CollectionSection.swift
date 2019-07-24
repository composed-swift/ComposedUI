import UIKit
import Composed

open class CollectionSection: CollectionProvider {

    public let header: CollectionElement?
    public let footer: CollectionElement?
    public let background: CollectionElement?

    open var numberOfElements: Int {
        return section?.numberOfElements ?? 0
    }

    public private(set) lazy var reuseIdentifier: String = {
        let identifier = prototype.reuseIdentifier ?? type(of: prototype).reuseIdentifier
        return identifier.isEmpty ? type(of: prototype).reuseIdentifier : identifier
    }()

    public let dequeueMethod: DequeueMethod

    private let prototypeProvider: () -> UICollectionReusableView
    public private(set) lazy var prototype: UICollectionReusableView = {
        return prototypeProvider()
    }()

    private weak var section: Section?
    private let configureCell: (UICollectionViewCell, Int, CollectionElement.Context) -> Void

    public init<Cell: UICollectionViewCell, Section: Composed.Section>(section: Section,
                                                                       prototype: @escaping @autoclosure () -> Cell,
                                                                       cellDequeueMethod: DequeueMethod,
                                                                       cellReuseIdentifier: String? = nil,
                                                                       cellConfigurator: @escaping (Cell, Int, Section, CollectionElement.Context) -> Void,
                                                                       header: CollectionElement? = nil,
                                                                       footer: CollectionElement? = nil,
                                                                       background: CollectionElement? = nil) {
        self.section = section
        self.prototypeProvider = prototype
        self.dequeueMethod = cellDequeueMethod
        self.configureCell = { [weak section] c, index, context in
            guard let cell = c as? Cell else {
                assertionFailure("Got an unknown cell. Expecting cell of type \(Cell.self), got \(c)")
                return
            }
            guard let section = section else {
                assertionFailure("Asked to configure cell after section has been deallocated")
                return
            }
            cellConfigurator(cell, index, section, context)
        }
        self.header = header
        self.footer = footer
        self.background = background

        if let reuseIdentifier = cellReuseIdentifier {
            self.reuseIdentifier = reuseIdentifier
        }
    }

    public func configure(cell: UICollectionViewCell, at index: Int, context: CollectionElement.Context) {
        configureCell(cell, index, context)
    }

}
