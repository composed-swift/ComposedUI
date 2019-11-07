import UIKit

public struct CollectionFlowLayoutSizingContext {
    public let index: Int
    public let layoutSize: CGSize
    public let adjustedContentInset: UIEdgeInsets
    public let prototype: UICollectionReusableView
}

public protocol CollectionFlowLayoutSizingStrategy {
    func size(forElementAt index: Int, context: CollectionFlowLayoutSizingContext) -> CGSize
}
