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
    public var boundarySupplementaryItems: [ComposedLayoutBoundarySupplementaryItem] = []
    public var decorationItems: [ComposedLayoutDecorationItem] = []

    internal var item: ComposedLayoutItem

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

    public static func header(heightDimension height: ComposedLayoutDimension) -> ComposedLayoutBoundarySupplementaryItem {
        return ComposedLayoutBoundarySupplementaryItem(layoutSize: ComposedLayoutSize(widthDimension: .automatic, heightDimension: height), elementKind: UICollectionView.elementKindSectionHeader, alignment: [])
    }

    public static func footer(heightDimension height: ComposedLayoutDimension) -> ComposedLayoutBoundarySupplementaryItem {
        return ComposedLayoutBoundarySupplementaryItem(layoutSize: ComposedLayoutSize(widthDimension: .automatic, heightDimension: height), elementKind: UICollectionView.elementKindSectionFooter, alignment: [])
    }
}

public class ComposedLayoutDecorationItem: ComposedLayoutItem {
    public let elementKind: String
    public var zIndex: Int = -1

    internal init(backgroundElementKind elementKind: String) {
        self.elementKind = elementKind
        let size = ComposedLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        super.init(layoutSize: size, supplementaryItems: [])
    }

    public static func background(elementKind: String) -> ComposedLayoutDecorationItem {
        return ComposedLayoutDecorationItem(backgroundElementKind: elementKind)
    }
}

public struct ComposedLayoutConfiguration {
    public var scrollDirection: UICollectionView.ScrollDirection = .vertical
    public var interSectionSpacing: CGFloat = 0
    public var globalHeaderItem: ComposedLayoutSupplementaryItem?
    public var globalFooterItem: ComposedLayoutSupplementaryItem?
    public init() { }
}

open class ComposedLayout: UICollectionViewFlowLayout {

    public typealias ComposedLayoutSectionProvider = (Int, ComposedLayoutEnvironment) -> ComposedLayoutSection?

    public var configuration: ComposedLayoutConfiguration {
        didSet { scrollDirection = configuration.scrollDirection }
    }

    internal var section: ComposedLayoutSection?
    internal var sectionProvider: ComposedLayoutSectionProvider?

    private var delegate: ComposedLayoutDelegate?

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

    open override func prepare() {
        if delegate == nil {
            delegate = ComposedLayoutDelegate(layout: self)
        }

        super.prepare()
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

internal struct LayoutContainer: ComposedLayoutContainer {
    let contentSize: CGSize
    let contentInsets: UIEdgeInsets
    var effectiveContentSize: CGSize {
        return CGRect(origin: .zero, size: contentSize).inset(by: contentInsets).size
    }
}

internal struct LayoutEnvironment: ComposedLayoutEnvironment {
    let container: ComposedLayoutContainer
    let traitCollection: UITraitCollection
}

internal final class ComposedLayoutDelegate: NSObject, UICollectionViewDelegate {

    private let layout: ComposedLayout
    private weak var originalDelegate: UICollectionViewDelegate?

    private var collectionView: UICollectionView { return layout.collectionView! }

    init(layout: ComposedLayout) {
        self.layout = layout
        super.init()
        self.originalDelegate = collectionView.delegate
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        collectionView.delegate = self
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) {
            return true
        }

        if originalDelegate?.responds(to: aSelector) ?? false {
            return true
        }

        return false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if super.responds(to: aSelector) {
            return self
        }

        return originalDelegate
    }

    private var environment: ComposedLayoutEnvironment {
        let container = LayoutContainer(contentSize: collectionView.bounds.size, contentInsets: collectionView.contentInset)
        return LayoutEnvironment(container: container, traitCollection: collectionView.traitCollection)
    }

    private func layoutSection(for section: Int) -> ComposedLayoutSection? {
        if let section = layout.section { return section }
        return layout.sectionProvider?(section, environment)
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let section = layoutSection(for: section) else { return .zero }
        return section.contentInsets
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let section = layoutSection(for: section) else { return 0 }
        switch layout.scrollDirection {
        case .horizontal: return section.yAxisSpacing
        case .vertical: return section.xAxisSpacing
        @unknown default: return 0
        }
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let section = layoutSection(for: section) else { return 0 }
        switch layout.scrollDirection {
        case .horizontal: return section.xAxisSpacing
        case .vertical: return section.yAxisSpacing
        @unknown default: return 0
        }
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLaryout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSizCe {
        guard let section = layoutSection(for: indexPath.section) else { return .zero }
        return size(for: section.item, in: section)
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let section = layoutSection(for: section) else { return .zero }
        guard let item = section.boundarySupplementaryItems.first(where: { $0.elementKind == UICollectionView.elementKindSectionHeader }) else { return .zero }
        return size(for: item, in: section)
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let section = layoutSection(for: section) else { return .zero }
        guard let item = section.boundarySupplementaryItems.first(where: { $0.elementKind == UICollectionView.elementKindSectionFooter }) else { return .zero }
        return size(for: item, in: section)
    }

    private func size(for item: ComposedLayoutItem, in section: ComposedLayoutSection) -> CGSize {
        let width: CGFloat
        let height: CGFloat

        switch item.layoutSize.width {
        case .automatic:
            width = UICollectionViewFlowLayout.automaticSize.width
        case let .absolute(dimension):
            width = dimension
        case let .fractionalWidth(fraction):
            width = environment.container.effectiveContentSize.width * fraction
        case let .fractionalHeight(fraction):
            width = environment.container.effectiveContentSize.height * fraction
        }

        switch item.layoutSize.height {
        case .automatic:
            height = UICollectionViewFlowLayout.automaticSize.height
        case let .absolute(dimension):
            height = dimension
        case let .fractionalWidth(fraction):
            height = environment.container.effectiveContentSize.width * fraction
        case let .fractionalHeight(fraction):
            height = environment.container.effectiveContentSize.height * fraction
        }

        return CGSize(width: width, height: height)
    }

}
