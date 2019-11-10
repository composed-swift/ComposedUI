import UIKit
import Composed

public protocol CollectionElementsProvider {
    var cell: CollectionElement<UICollectionViewCell> { get }
    var header: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var footer: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var numberOfElements: Int { get }
}

public extension CollectionElementsProvider {
    var isEmpty: Bool { return numberOfElements == 0 }
}

public protocol CollectionSectionProvider {
    func section(with traitCollection: UITraitCollection) -> CollectionSection
}
