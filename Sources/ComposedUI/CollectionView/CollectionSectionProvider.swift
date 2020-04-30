import UIKit
import Composed

internal protocol CollectionElementsProvider {
    var cell: CollectionCellElement<UICollectionViewCell> { get }
    var header: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var footer: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var numberOfElements: Int { get }
}

extension CollectionElementsProvider {
    var isEmpty: Bool { return numberOfElements == 0 }
}

public protocol CollectionSectionProvider: Section {
    func section(with traitCollection: UITraitCollection) -> CollectionSection
}
