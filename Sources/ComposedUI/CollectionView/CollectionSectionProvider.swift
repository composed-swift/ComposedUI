import UIKit

public protocol CollectionProvider {
    var header: CollectionElement? { get }
    var footer: CollectionElement? { get }
    var background: CollectionElement? { get }
    var numberOfElements: Int { get }
    var reuseIdentifier: String { get }
    var prototype: UICollectionReusableView { get }
    var dequeueMethod: DequeueMethod { get }
    func configure(cell: UICollectionViewCell, at index: Int, context: CollectionElement.Context)
}

public protocol CollectionSectionProvider {
    var collectionSection: CollectionSection { get }
}
