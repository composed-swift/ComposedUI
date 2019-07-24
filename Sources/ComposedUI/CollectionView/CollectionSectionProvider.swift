import UIKit

public protocol CollectionProvider {
    var header: CollectionElement<UICollectionReusableView>? { get }
    var footer: CollectionElement<UICollectionReusableView>? { get }
    var background: CollectionElement<UICollectionReusableView>? { get }
    var numberOfElements: Int { get }
    var reuseIdentifier: String { get }
    var prototype: UICollectionReusableView { get }
    var dequeueMethod: DequeueMethod<UICollectionViewCell> { get }
    func configure(cell: UICollectionViewCell, at index: Int, context: CollectionElement<UICollectionViewCell>.Context)
}

public protocol CollectionSectionProvider {
    func section(with environment: Environment) -> CollectionSection
}
