import UIKit
import Composed

open class CollectionSection: CollectionProvider {

    public let header: CollectionElement<UICollectionReusableView>?
    public let footer: CollectionElement<UICollectionReusableView>?
    public let background: CollectionElement<UICollectionReusableView>?

    open var numberOfElements: Int {
        return section?.numberOfElements ?? 0
    }

    public private(set) lazy var reuseIdentifier: String = {
        let identifier = prototype.reuseIdentifier ?? type(of: prototype).reuseIdentifier
        return identifier.isEmpty ? type(of: prototype).reuseIdentifier : identifier
    }()

    public let dequeueMethod: DequeueMethod<UICollectionViewCell>

    private let prototypeProvider: () -> UICollectionReusableView
    public private(set) lazy var prototype: UICollectionReusableView = {
        return prototypeProvider()
    }()

    private weak var section: Section?
    private let configureCell: (UICollectionViewCell, Int, CollectionElement<UICollectionViewCell>.Context) -> Void

    public init<Cell: UICollectionViewCell, Section: Composed.Section>(section: Section,
                                                                       prototype: @escaping @autoclosure () -> Cell,
                                                                       cellDequeueMethod: DequeueMethod<UICollectionViewCell>,
                                                                       cellReuseIdentifier: String? = nil,
                                                                       cellConfigurator: @escaping (Cell, Int, Section, CollectionElement<UICollectionViewCell>.Context) -> Void,
                                                                       header: CollectionElement<UICollectionReusableView>? = nil,
                                                                       footer: CollectionElement<UICollectionReusableView>? = nil,
                                                                       background: CollectionElement<UICollectionReusableView>? = nil) {
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

    public func configure(cell: UICollectionViewCell, at index: Int, context: CollectionElement<UICollectionViewCell>.Context) {
        configureCell(cell, index, context)
    }

}

open class CollectionSectionFlowLayout: CollectionSection {

    public let sectionInsets: UIEdgeInsets
    public let minimumLineSpacing: CGFloat
    public let minimumInteritemSpacing: CGFloat

    public init<Cell: UICollectionViewCell, Section: Composed.Section>(section: Section,
                                                                       prototype: @escaping @autoclosure () -> Cell,
                                                                       cellDequeueMethod: DequeueMethod<UICollectionViewCell>,
                                                                       cellReuseIdentifier: String? = nil,
                                                                       cellConfigurator: @escaping (Cell, Int, Section, CollectionElement<UICollectionViewCell>.Context) -> Void,
                                                                       header: CollectionElement<UICollectionReusableView>? = nil,
                                                                       footer: CollectionElement<UICollectionReusableView>? = nil,
                                                                       background: CollectionElement<UICollectionReusableView>? = nil,
                                                                       sectionInsets: UIEdgeInsets = .zero,
                                                                       minimumLineSpacing: CGFloat = 0,
                                                                       minimumInteritemSpacing: CGFloat = 0) {
        self.sectionInsets = sectionInsets
        self.minimumLineSpacing = minimumLineSpacing
        self.minimumInteritemSpacing = minimumInteritemSpacing
        super.init(section: section, prototype: prototype(), cellDequeueMethod: cellDequeueMethod, cellReuseIdentifier: cellReuseIdentifier,
                   cellConfigurator: cellConfigurator, header: header, footer: footer, background: background)
    }

}
