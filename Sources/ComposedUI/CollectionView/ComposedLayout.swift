import UIKit

internal enum ComposedLayoutDimension {
    case automatic
    case fractionalWidth(CGFloat)
    case fractionalHeight(CGFloat)
    case absolute(CGFloat)
}

internal final class ComposedLayoutSize {
    internal let width: ComposedLayoutDimension
    internal let height: ComposedLayoutDimension

    internal init(widthDimension width: ComposedLayoutDimension, heightDimension height: ComposedLayoutDimension) {
        self.width = width
        self.height = height
    }
}

internal class ComposedLayoutItem {
    internal let layoutSize: ComposedLayoutSize
    internal let supplementaryItems: [ComposedLayoutSupplementaryItem]

    internal init(layoutSize: ComposedLayoutSize, supplementaryItems: [ComposedLayoutSupplementaryItem] = []) {
        self.layoutSize = layoutSize
        self.supplementaryItems = supplementaryItems
    }
}

internal final class ComposedLayoutSection {
    internal var contentInsets: UIEdgeInsets = .zero
    internal var xAxisSpacing: CGFloat = 0
    internal var yAxisSpacing: CGFloat = 0
    internal var boundarySupplementaryItems: [ComposedLayoutBoundarySupplementaryItem] = []
    internal var decorationItems: [ComposedLayoutDecorationItem] = []

    internal var item: ComposedLayoutItem

    internal init(item: ComposedLayoutItem) {
        self.item = item
    }
}

internal enum ComposedLayoutAnchor {
    case absolute(UIRectEdge, CGPoint)
    case fractional(UIRectEdge, CGPoint)
}

internal class ComposedLayoutSupplementaryItem: ComposedLayoutItem {
    internal let elementKind: String
    internal let containerAnchor: ComposedLayoutAnchor
    internal let itemAnchor: ComposedLayoutAnchor?
    internal let zIndex: Int = 1

    internal init(layoutSize: ComposedLayoutSize, elementKind: String, containerAnchor: ComposedLayoutAnchor, itemAnchor: ComposedLayoutAnchor? = nil) {
        self.elementKind = elementKind
        self.containerAnchor = containerAnchor
        self.itemAnchor = itemAnchor
        super.init(layoutSize: layoutSize, supplementaryItems: [])
    }
}

internal class ComposedLayoutBoundarySupplementaryItem: ComposedLayoutSupplementaryItem {
    internal var pinsToVisibleBounds: Bool = false
    internal let alignment: UIRectEdge
    internal let offset: CGPoint

    internal init(layoutSize: ComposedLayoutSize, elementKind: String, alignment: UIRectEdge, absoluteOffset: CGPoint = .zero) {
        self.offset = absoluteOffset
        self.alignment = alignment

        super.init(layoutSize: layoutSize, elementKind: elementKind, containerAnchor: .absolute(alignment, absoluteOffset), itemAnchor: nil)
    }

    internal static func header(heightDimension height: ComposedLayoutDimension) -> ComposedLayoutBoundarySupplementaryItem {
        return ComposedLayoutBoundarySupplementaryItem(layoutSize: ComposedLayoutSize(widthDimension: .automatic, heightDimension: height), elementKind: UICollectionView.elementKindSectionHeader, alignment: [])
    }

    internal static func footer(heightDimension height: ComposedLayoutDimension) -> ComposedLayoutBoundarySupplementaryItem {
        return ComposedLayoutBoundarySupplementaryItem(layoutSize: ComposedLayoutSize(widthDimension: .automatic, heightDimension: height), elementKind: UICollectionView.elementKindSectionFooter, alignment: [])
    }
}

internal class ComposedLayoutDecorationItem: ComposedLayoutItem {
    internal let elementKind: String
    internal var zIndex: Int = -1

    internal init(backgroundElementKind elementKind: String) {
        self.elementKind = elementKind
        let size = ComposedLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        super.init(layoutSize: size, supplementaryItems: [])
    }

    internal static func background(elementKind: String) -> ComposedLayoutDecorationItem {
        return ComposedLayoutDecorationItem(backgroundElementKind: elementKind)
    }
}

internal struct ComposedLayoutConfiguration {
    internal var scrollDirection: UICollectionView.ScrollDirection = .vertical
    internal var globalHeaderItem: ComposedLayoutSupplementaryItem?
    internal var globalFooterItem: ComposedLayoutSupplementaryItem?
    internal init() { }
}

internal class ComposedLayout: UICollectionViewFlowLayout {

    internal typealias ComposedLayoutSectionProvider = (Int, ComposedLayoutEnvironment) -> ComposedLayoutSection?

    internal var configuration: ComposedLayoutConfiguration {
        didSet { scrollDirection = configuration.scrollDirection }
    }

    internal var section: ComposedLayoutSection?
    internal var sectionProvider: ComposedLayoutSectionProvider?

    private var delegate: ComposedLayoutDelegate?

    internal init(section: ComposedLayoutSection) {
        self.section = section
        self.sectionProvider = nil
        self.configuration = .init()
        super.init()
    }

    internal init(sectionProvider provider: @escaping ComposedLayoutSectionProvider) {
        self.sectionProvider = provider
        self.section = nil
        self.configuration = .init()
        super.init()
    }

    internal init(section: ComposedLayoutSection, configuration: ComposedLayoutConfiguration) {
        self.section = section
        self.sectionProvider = nil
        self.configuration = configuration
        super.init()
    }

    internal init(sectionProvider provider: @escaping ComposedLayoutSectionProvider, configuration: ComposedLayoutConfiguration) {
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
            estimatedItemSize = CGSize(width: 1, height: 1)
        }

        super.prepare()
    }

    private func environment(for collectionView: UICollectionView, additionalInsets: UIEdgeInsets) -> ComposedLayoutEnvironment {
        let insets = UIEdgeInsets(top: collectionView.contentInset.top + additionalInsets.top,
                                  left: collectionView.contentInset.left + additionalInsets.left,
                                  bottom: collectionView.contentInset.bottom + additionalInsets.bottom,
                                  right: collectionView.contentInset.right + additionalInsets.right)
        let container = LayoutContainer(contentSize: collectionView.bounds.size, contentInsets: insets)
        return LayoutEnvironment(container: container, traitCollection: collectionView.traitCollection)
    }

    private func layoutSection(in index: Int, collectionView: UICollectionView) -> ComposedLayoutSection? {
        if let section = section { return section }
        return sectionProvider?(index, environment(for: collectionView, additionalInsets: .zero))
    }

    open override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
//        let should = super.shouldInvalidateLayout(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
        guard let section = layoutSection(in: preferredAttributes.indexPath.section, collectionView: collectionView!) else { return false }

        if case .automatic = section.item.layoutSize.height {
            let preferredWidth = collectionView!.bounds.width - 10 - 10 - 10
            if originalAttributes.size.height == preferredAttributes.size.height { return false }

            let attributes = preferredAttributes.copy() as! UICollectionViewLayoutAttributes
            attributes.size.width = preferredWidth

            return super.shouldInvalidateLayout(forPreferredLayoutAttributes: attributes, withOriginalAttributes: originalAttributes)
        }

        return false
    }

    open override func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
        return context
    }

}

internal protocol ComposedLayoutContainer {
    var contentSize: CGSize { get }
    var effectiveContentSize: CGSize { get }
    var contentInsets: UIEdgeInsets { get }
}

internal protocol ComposedLayoutEnvironment {
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

internal final class ComposedLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout {

    private let layout: ComposedLayout
    private weak var originalDelegate: UICollectionViewDelegate?

    private var observer: NSKeyValueObservation?

    init(layout: ComposedLayout) {
        self.layout = layout
        super.init()

        observer = layout.observe(\.collectionView, options: [.initial, .new]) { [unowned self] layout, _ in
            self.originalDelegate = layout.collectionView!.delegate
            layout.collectionView!.delegate = self
        }
    }

    private func environment(for collectionView: UICollectionView, additionalInsets: UIEdgeInsets) -> ComposedLayoutEnvironment {
        let insets = UIEdgeInsets(top: collectionView.contentInset.top + additionalInsets.top,
                                  left: collectionView.contentInset.left + additionalInsets.left,
                                  bottom: collectionView.contentInset.bottom + additionalInsets.bottom,
                                  right: collectionView.contentInset.right + additionalInsets.right)
        let container = LayoutContainer(contentSize: collectionView.bounds.size, contentInsets: insets)
        return LayoutEnvironment(container: container, traitCollection: collectionView.traitCollection)
    }

    private func layoutSection(for collectionView: UICollectionView, in section: Int) -> ComposedLayoutSection? {
        if let section = layout.section { return section }
        return layout.sectionProvider?(section, environment(for: collectionView, additionalInsets: .zero))
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let section = layoutSection(for: collectionView, in: section) else { return .zero }
        return section.contentInsets
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let section = layoutSection(for: collectionView, in: section) else { return 0 }
        switch layout.scrollDirection {
        case .horizontal: return section.yAxisSpacing
        case .vertical: return section.xAxisSpacing
        @unknown default: return 0
        }
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let section = layoutSection(for: collectionView, in: section) else { return 0 }
        switch layout.scrollDirection {
        case .horizontal: return section.xAxisSpacing
        case .vertical: return section.yAxisSpacing
        @unknown default: return 0
        }
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let section = layoutSection(for: collectionView, in: indexPath.section) else { return .zero }
        return size(for: section.item, in: section, collectionView: collectionView)
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let section = layoutSection(for: collectionView, in: section) else { return .zero }
        guard let item = section.boundarySupplementaryItems.first(where: { $0.elementKind == UICollectionView.elementKindSectionHeader }) else { return .zero }
        return size(for: item, in: section, collectionView: collectionView)
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let section = layoutSection(for: collectionView, in: section) else { return .zero }
        guard let item = section.boundarySupplementaryItems.first(where: { $0.elementKind == UICollectionView.elementKindSectionFooter }) else { return .zero }
        return size(for: item, in: section, collectionView: collectionView)
    }

    private func size(for item: ComposedLayoutItem, in section: ComposedLayoutSection, collectionView: UICollectionView) -> CGSize {
        let width: CGFloat
        let height: CGFloat

        switch item.layoutSize.width {
        case .automatic:
            width = environment(for: collectionView, additionalInsets: section.contentInsets)
                .container.effectiveContentSize.width
        case let .absolute(dimension):
            width = dimension
        case let .fractionalWidth(fraction):
            width = environment(for: collectionView, additionalInsets: section.contentInsets)
                .container.effectiveContentSize.width * fraction - 10
        case let .fractionalHeight(fraction):
            width = environment(for: collectionView, additionalInsets: section.contentInsets)
                .container.effectiveContentSize.height * fraction
        }

        switch item.layoutSize.height {
        case .automatic:
            height = 1
        case let .absolute(dimension):
            height = dimension
        case let .fractionalWidth(fraction):
            height = environment(for: collectionView, additionalInsets: section.contentInsets)
                .container.effectiveContentSize.width * fraction
        case let .fractionalHeight(fraction):
            height = environment(for: collectionView, additionalInsets: section.contentInsets)
                .container.effectiveContentSize.height * fraction
        }

        return CGSize(width: width, height: height)
    }

    // MARK: - Delegate forwarding

    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        if originalDelegate?.responds(to: aSelector) ?? false { return true }
        return false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if super.responds(to: aSelector) { return self }
        return originalDelegate
    }

}
