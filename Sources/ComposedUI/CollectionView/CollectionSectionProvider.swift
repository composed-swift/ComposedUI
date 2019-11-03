import UIKit
import Composed

public protocol CollectionProvider {
    var cell: CollectionElement<UICollectionViewCell> { get }
    var background: CollectionElement<UICollectionReusableView>? { get }
    var numberOfElements: Int { get }
}

public protocol CollectionSectionProvider {
    func sizingStrategy(with environment: Environment) -> CollectionSizingStrategy?
    func section(with environment: Environment) -> CollectionSection
}
