import UIKit
import Composed

/// Provides a section to a collection view. Conform to this protool to use your section with a `UICollectionView`
public protocol CollectionSectionProvider: CollectionElementsProviderProvider {

    /// Return a section cofiguration for the collection view.
    /// - Parameter traitCollection: The trait collection being applied to the view
    func section(with traitCollection: UITraitCollection) -> CollectionSection

}

extension CollectionSectionProvider {
    public func collectionElementsProvider(with traitCollection: UITraitCollection) -> CollectionElementsProvider {
        return section(with: traitCollection)
    }
}

/// Provides a section to a collection view. Conform to this protool to use your section with a `UICollectionView`
public protocol CollectionElementsProviderProvider: Section {

    /// Return an elements provider for the collection view.
    /// - Parameter traitCollection: The trait collection being applied to the view
    func collectionElementsProvider(with traitCollection: UITraitCollection) -> CollectionElementsProvider

}

public protocol CollectionElementsProvider {
    var uniqueCells: [(dequeueMethod: DequeueMethod<UICollectionViewCell>, resuseIdentifier: String)] { get }
    var header: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var footer: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var numberOfElements: Int { get }

    func cellForIndex(_ index: Int) -> CollectionCellElement<UICollectionViewCell>
}

extension CollectionElementsProvider {
    var isEmpty: Bool { return numberOfElements == 0 }
}
