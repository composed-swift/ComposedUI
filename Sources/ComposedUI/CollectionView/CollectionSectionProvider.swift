import UIKit
import Composed

/// Provides a section to a collection view. Conform to this protool to use your section with a `UICollectionView`
public protocol CollectionSectionProvider: Section {

    /// Return a section cofiguration for the collection view.
    /// - Parameter traitCollection: The trait collection being applied to the view
    func section(with traitCollection: UITraitCollection) -> CollectionSection

}

internal protocol CollectionElementsProvider {
    var cell: CollectionCellElement<UICollectionViewCell> { get }
    var header: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var footer: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var numberOfElements: Int { get }
}

extension CollectionElementsProvider {
    var isEmpty: Bool { return numberOfElements == 0 }
}
