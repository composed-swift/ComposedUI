import UIKit

public struct CollectionSizingContext {
    public let index: Int
    public let layoutSize: CGSize
    public let adjustedContentInset: UIEdgeInsets
    public let prototype: UICollectionReusableView
}

public protocol CollectionSizingStrategy {
    func size(forElementAt index: Int, context: CollectionSizingContext) -> CGSize
}

public struct NoSizingStrategy: CollectionSizingStrategy {
    public func size(forElementAt index: Int, context: CollectionSizingContext) -> CGSize { return .zero }
}
