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

public protocol CollectionSizingStrategyFlowLayout: CollectionSizingStrategy {
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

    open func size(forElementAt index: Int, context: CollectionSizingContext) -> CGSize {
        var width: CGFloat {
            let interitemSpacing = CGFloat(columnCount - 1) * metrics.minimumInteritemSpacing
            let availableWidth = context.layoutSize.width
                - metrics.sectionInsets.left - metrics.sectionInsets.right
                - interitemSpacing
            return (availableWidth / CGFloat(columnCount)).rounded(.down)
        }

        switch sizingMode {
        case let .aspect(ratio):
            return CGSize(width: width, height: width * ratio)
        case let .fixed(height):
            return CGSize(width: width, height: height)
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

            return size
        }
    }

}
