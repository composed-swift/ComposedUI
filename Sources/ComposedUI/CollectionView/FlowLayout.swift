import UIKit

public enum ComposedLayoutDimension {
    case automatic
    case fractionalWidth(CGFloat)
    case fractionalHeight(CGFloat)
    case absolute(CGFloat)
}

public final class ComposedLayoutSize {
    internal let width: ComposedLayoutDimension
    internal let height: ComposedLayoutDimension

    public init(widthDimension width: ComposedLayoutDimension, heightDimension height: ComposedLayoutDimension) {
        self.width = width
        self.height = height
    }
}
1
public class ComposedLayoutItem {
    internal let layoutSize: ComposedLayoutSize
    internal let supplementaryItems: [ComposedLayoutSupplementaryItem]

    public init(layoutSize: ComposedLayoutSize, supplementaryItems: [ComposedLayoutSupplementaryItem] = []) {
        self.layoutSize = layoutSize
        self.supplementaryItems = supplementaryItems
    }
}

public final class ComposedLayoutSection {
    public var contentInsets: UIEdgeInsets = .zero
    public var xAxisSpacing: CGFloat = 0
    public var yAxisSpacing: CGFloat = 0
    public var boundarySupplementaryItems: [ComposedLayoutSupplementaryItem] = []
    public var decorationItems: [ComposedLayoutDecorationItem] = []

    internal var item: ComposedLayoutItem?

    public init(item: ComposedLayoutItem) {
        self.item = item
    }
}

public enum ComposedLayoutAnchor {
    case absolute(UIRectEdge, CGPoint)
    case fractional(UIRectEdge, CGPoint)
}

public class ComposedLayoutSupplementaryItem: ComposedLayoutItem {
    public let elementKind: String
    public let containerAnchor: ComposedLayoutAnchor
    public let itemAnchor: ComposedLayoutAnchor?
    public let zIndex: Int = 1

    public init(layoutSize: ComposedLayoutSize, elementKind: String, containerAnchor: ComposedLayoutAnchor, itemAnchor: ComposedLayoutAnchor? = nil) {
        self.elementKind = elementKind
        self.containerAnchor = containerAnchor
        self.itemAnchor = itemAnchor
        super.init(layoutSize: layoutSize, supplementaryItems: [])
    }
}

public class ComposedLayoutBoundarySupplementaryItem: ComposedLayoutSupplementaryItem {

    public var pinsToVisibleBounds: Bool = false
    public let alignment: UIRectEdge
    public let offset: CGPoint

    public init(layoutSize: ComposedLayoutSize, elementKind: String, alignment: UIRectEdge, absoluteOffset: CGPoint = .zero) {
        self.offset = absoluteOffset
        self.alignment = alignment

        super.init(layoutSize: layoutSize, elementKind: elementKind, containerAnchor: .absolute(alignment, absoluteOffset), itemAnchor: nil)
    }
}

public class ComposedLayoutDecorationItem: ComposedLayoutItem {
    public let elementKind: String
    public var zIndex: Int = -1

    public init(backgroundElementKind elementKind: String) {
        self.elementKind = elementKind
        let size = ComposedLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        super.init(layoutSize: size, supplementaryItems: [])
    }
}

public final class ComposedLayoutConfiguration {
    public var scrollDirection: UICollectionView.ScrollDirection = .vertical
    public var interSectionSpacing: CGFloat = 0
    public var globalHeaderItem: ComposedLayoutSupplementaryItem?
    public var globalFooterItem: ComposedLayoutSupplementaryItem?
    public init() { }
}

open class ComposedLayout: UICollectionViewFlowLayout {

    public typealias ComposedLayoutSectionProvider = (Int, Environment) -> ComposedLayoutSection?

    internal var section: ComposedLayoutSection?
    internal var sectionProvider: ComposedLayoutSectionProvider?
    public var configuration: ComposedLayoutConfiguration

    public init(section: ComposedLayoutSection) {
        self.section = section
        self.sectionProvider = nil
        self.configuration = .init()
        super.init()
    }

    public init(sectionProvider provider: @escaping ComposedLayoutSectionProvider) {
        self.sectionProvider = provider
        self.section = nil
        self.configuration = .init()
        super.init()
    }

    public init(section: ComposedLayoutSection, configuration: ComposedLayoutConfiguration) {
        self.section = section
        self.sectionProvider = nil
        self.configuration = configuration
        super.init()
    }

    public init(sectionProvider provider: @escaping ComposedLayoutSectionProvider, configuration: ComposedLayoutConfiguration) {
        self.sectionProvider = provider
        self.section = nil
        self.configuration = configuration
        super.init()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported by ComposedLayout")
    }

}

public protocol ComposedLayoutContainer {
    var contentSize: CGSize { get }
    var effectiveContentSize: CGSize { get }
    var contentInsets: UIEdgeInsets { get }
}

public protocol ComposedLayoutEnvironment {
    var container: ComposedLayoutContainer { get }
    var traitCollection: UITraitCollection { get }
}

internal final class LayoutContainer: ComposedLayoutContainer {
    let contentSize: CGSize
    let contentInsets: UIEdgeInsets
    var effectiveContentSize: CGSize {
        return CGRect(origin: .zero, size: contentSize).inset(by: contentInsets).size
    }

    internal init(contentSize: CGSize, contentInsets: UIEdgeInsets) {
        self.contentSize = contentSize
        self.contentInsets = contentInsets
    }
}

internal final class LayoutEnvironment: ComposedLayoutEnvironment {
    let container: ComposedLayoutContainer
    let traitCollection: UITraitCollection

    internal init(container: ComposedLayoutContainer, traitCollection: UITraitCollection) {
        self.container = container
        self.traitCollection = traitCollection
    }
}
