import UIKit
import Composed

public protocol CompositionalLayoutSection: CollectionSectionProvider {
    @available(iOS 13.0, *)
    func compositionalLayoutSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection?
}

public protocol FlowLayoutSection: CollectionSectionProvider {
    func sizeForItem(at index: Int) -> CGSize
}
