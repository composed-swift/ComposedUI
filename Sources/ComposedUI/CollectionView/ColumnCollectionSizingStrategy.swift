import UIKit

public struct CollectionSectionMetrics {

    public let sectionInsets: UIEdgeInsets
    public let minimumLineSpacing: CGFloat
    public let minimumInteritemSpacing: CGFloat

    public init(sectionInsets: UIEdgeInsets, minimumInteritemSpacing: CGFloat, minimumLineSpacing: CGFloat) {
        self.sectionInsets = sectionInsets
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
    }

    public static let zero = CollectionSectionMetrics(sectionInsets: .zero, minimumInteritemSpacing: 0, minimumLineSpacing: 0)

}

public protocol CollectionSizingStrategyFlowLayout: CollectionFlowLayoutSizingStrategy {
    var metrics: CollectionSectionMetrics { get }
}

open class ColumnCollectionSizingStrategy: CollectionSizingStrategyFlowLayout {

    public enum SizingMode {
        case fixed(height: CGFloat)
        case automatic(isUniform: Bool)
        case aspect(ratio: CGFloat)
    }

    public let columnCount: Int
    public let sizingMode: SizingMode
    public let metrics: CollectionSectionMetrics

    public init(columnCount: Int, sizingMode: SizingMode, metrics: CollectionSectionMetrics) {
        self.columnCount = columnCount
        self.sizingMode = sizingMode
        self.metrics = metrics
    }

    private var cachedSizes: [Int: CGSize] = [:]
    private func cachedSize(forElementAt index: Int) -> CGSize? {
        switch sizingMode {
        case .aspect:
            return cachedSizes[index]
        case .fixed:
            return cachedSizes.values.first
        case let .automatic(isUniform):
            return isUniform ? cachedSizes.values.first : cachedSizes[index]
        }
    }

    open func size(forElementAt index: Int, context: CollectionFlowLayoutSizingContext) -> CGSize {
        if let size = cachedSize(forElementAt: index) { return size }

        var width: CGFloat {
            let interitemSpacing = CGFloat(columnCount - 1) * metrics.minimumInteritemSpacing
            let availableWidth = context.layoutSize.width
                - metrics.sectionInsets.left - metrics.sectionInsets.right
                - interitemSpacing
            return (availableWidth / CGFloat(columnCount)).rounded(.down)
        }

        switch sizingMode {
        case let .aspect(ratio):
            let size = CGSize(width: width, height: width * ratio)
            cachedSizes[index] = size
            return size
        case let .fixed(height):
            let size = CGSize(width: width, height: height)
            cachedSizes[index] = size
            return size
        case .automatic:
            let targetView: UIView
            let targetSize = CGSize(width: width, height: 0)

            if let cell = context.prototype as? UICollectionViewCell {
                targetView = cell.contentView
            } else {
                targetView = context.prototype
            }

            let size = targetView.systemLayoutSizeFitting(
                targetSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel)

            cachedSizes[index] = size
            return size
        }
    }

}
