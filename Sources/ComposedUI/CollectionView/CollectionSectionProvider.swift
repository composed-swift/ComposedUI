import UIKit

public protocol CollectionProvider {
    var background: CollectionElement<UICollectionReusableView>? { get }
//    var sizingStrategy: CollectionSizingStrategy { get }
    var numberOfElements: Int { get }
    var reuseIdentifier: String { get }
    var prototype: UICollectionViewCell? { get }
    var prototypeType: UICollectionViewCell.Type { get }
    var dequeueMethod: DequeueMethod<UICollectionViewCell> { get }
    func configure(cell: UICollectionViewCell, at index: Int, context: CollectionElement<UICollectionViewCell>.Context)
}

public protocol CollectionSectionProvider {
    func sizingStrategy(with environment: Environment) -> CollectionSizingStrategy?
    func section(with environment: Environment) -> CollectionSection
}
