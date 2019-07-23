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
        return prototype.reuseIdentifier ?? type(of: prototype).reuseIdentifier
    }()

    public let dequeueMethod: CollectionElement.DequeueMethod

    private let prototypeProvider: () -> UICollectionReusableView
    private var _prototypeView: UICollectionReusableView?

    public var prototype: UICollectionReusableView {
        if let view = _prototypeView { return view }
        let view = prototypeProvider()
        _prototypeView = view
        return view
    }

    private weak var section: Section?
    private let configureCell: (UICollectionViewCell, Int) -> Void

    public init<Cell: UICollectionViewCell, Section: Composed.Section>(section: Section,
                                                                       prototype: @escaping @autoclosure () -> Cell,
                                                                       cellDequeueMethod: CollectionElement.DequeueMethod,
                                                                       cellReuseIdentifier: String? = nil,
                                                                       cellConfigurator: @escaping (Cell, Int, Section) -> Void,
                                                                       header: CollectionElement? = nil,
                                                                       footer: CollectionElement? = nil,
                                                                       background: CollectionElement? = nil) {
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
        self.background = background
    }

    public func configure(cell: UICollectionViewCell, at index: Int) {
        configureCell(cell, index)
    }

}
