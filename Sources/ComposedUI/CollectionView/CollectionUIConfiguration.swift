import UIKit

public protocol CollectionUIConfiguration {
    var header: CollectionUIViewProvider? { get }
    var footer: CollectionUIViewProvider? { get }
    var background: CollectionUIViewProvider? { get }
    var numberOfElements: Int { get }
    var reuseIdentifier: String { get }
    var prototype: UICollectionReusableView { get }
    var dequeueMethod: CollectionUIViewProvider.DequeueMethod { get }
    func configure(cell: UICollectionViewCell, at index: Int)
}

public protocol CollectionUIConfigurationProvider {
    var collectionUIConfiguration: CollectionUIConfiguration { get }
}
