import UIKit
import Composed

open class CollectionSection: CollectionProvider {

    public let background: CollectionElement<UICollectionReusableView>?

    open var numberOfElements: Int {
        return section?.numberOfElements ?? 0
    }

    public private(set) lazy var reuseIdentifier: String = {
        let identifier = prototype?.reuseIdentifier ?? prototypeType.reuseIdentifier
        return identifier.isEmpty ? prototypeType.reuseIdentifier : identifier
    }()

    public let dequeueMethod: DequeueMethod<UICollectionViewCell>

    private let prototypeProvider: () -> UICollectionViewCell?
    public private(set) lazy var prototype: UICollectionViewCell? = {
        return prototypeProvider()
    }()

    public let prototypeType: UICollectionViewCell.Type

    private weak var section: Section?
    private let configureCell: (UICollectionViewCell, Int, CollectionElement<UICollectionViewCell>.Context) -> Void

    public init<Cell: UICollectionViewCell, Section: Composed.Section>(section: Section,
                                                                       cellDequeueMethod: DequeueMethod<Cell>,
                                                                       cellReuseIdentifier: String? = nil,
                                                                       cellConfigurator: @escaping (Cell, Int, Section, CollectionElement<Cell>.Context) -> Void,
                                                                       background: CollectionElement<UICollectionReusableView>? = nil) {
        self.prototypeType = Cell.self
        self.section = section

        self.prototypeProvider = {
            switch cellDequeueMethod {
            case let .class(type):
                return type.init()
            case let .nib(type):
                let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                return nib.instantiate(withOwner: nil, options: nil).first as? UICollectionViewCell
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

            let cellContext: CollectionElement<Cell>.Context
            switch context {
            case .sizing: cellContext = .sizing
            case .presentation: cellContext = .presentation
            }

            cellConfigurator(cell, index, section, cellContext)
        }

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

    public let header: CollectionElement<UICollectionReusableView>?
    public let footer: CollectionElement<UICollectionReusableView>?

    public let sectionInsets: UIEdgeInsets
    public let minimumLineSpacing: CGFloat
    public let minimumInteritemSpacing: CGFloat

    public init<Cell: UICollectionViewCell, Section: Composed.Section>(section: Section,
                                                                       cellDequeueMethod: DequeueMethod<Cell>,
                                                                       cellReuseIdentifier: String? = nil,
                                                                       cellConfigurator: @escaping (Cell, Int, Section, CollectionElement<Cell>.Context) -> Void,
                                                                       background: CollectionElement<UICollectionReusableView>? = nil,
                                                                       header: CollectionElement<UICollectionReusableView>? = nil,
                                                                       footer: CollectionElement<UICollectionReusableView>? = nil,
                                                                       sectionInsets: UIEdgeInsets = .zero,
                                                                       minimumLineSpacing: CGFloat = 0,
                                                                       minimumInteritemSpacing: CGFloat = 0) {
        self.sectionInsets = sectionInsets
        self.minimumLineSpacing = minimumLineSpacing
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.header = header
        self.footer = footer

        super.init(section: section,
                   cellDequeueMethod: cellDequeueMethod,
                   cellReuseIdentifier: cellReuseIdentifier,
                   cellConfigurator: cellConfigurator,
                   background: background)
    }

}
