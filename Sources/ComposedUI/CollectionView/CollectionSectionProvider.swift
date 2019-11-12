import UIKit
import Composed

public protocol CollectionSectionElementsProvider {
    var cell: CollectionElement<UICollectionViewCell> { get }
    var header: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var footer: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var numberOfElements: Int { get }
}

public extension CollectionSectionElementsProvider {
    var isEmpty: Bool { return numberOfElements == 0 }
}

public protocol CollectionSectionProvider: Section {
    var queryDelegate: CollectionQueryDelegate? { get set }
    func section(with traitCollection: UITraitCollection) -> CollectionSection
}

public protocol CollectionQueryDelegate {
    func section(_ section: Section, indexFor location: CGPoint) -> Int?
    func section(_ section: Section, cellFor index: Int) -> UICollectionViewCell?
}
