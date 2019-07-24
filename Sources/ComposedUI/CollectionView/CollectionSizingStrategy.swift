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

public struct CollectionSizingContext {
    public let index: Int
    public let layoutSize: CGSize
    public let prototype: UICollectionReusableView
}

public protocol CollectionSizingStrategy {
    func size(forElementAt index: Int, context: CollectionSizingContext) -> CGSize
}

public struct NoSizingStrategy: CollectionSizingStrategy {
    public func size(forElementAt index: Int, context: CollectionSizingContext) -> CGSize { return .zero }
}
