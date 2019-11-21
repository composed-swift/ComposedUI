import UIKit
import Composed

public protocol CollectionSectionElementsProvider {
    var cell: CollectionCellElement<UICollectionViewCell> { get }
    var header: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var footer: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var numberOfElements: Int { get }
}

public extension CollectionSectionElementsProvider {
    var isEmpty: Bool { return numberOfElements == 0 }
}

public protocol CollectionSectionProvider: Section {
    func section(with traitCollection: UITraitCollection) -> CollectionSection
}
