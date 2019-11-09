import UIKit

public protocol CompositionalLayoutSection {
    @available(iOS 13.0, *)
    func compositionalLayoutSection() -> NSCollectionLayoutSection
}

public protocol FlowLayoutSection {
    func sizeForItem(at index: Int) -> CGSize
}
