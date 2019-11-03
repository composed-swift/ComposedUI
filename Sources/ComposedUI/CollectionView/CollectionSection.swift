import UIKit
import Composed

open class CollectionSection: CollectionProvider {

    public let cell: CollectionElement<UICollectionViewCell>
    public let background: CollectionElement<UICollectionReusableView>?

    open var numberOfElements: Int {
        return section?.numberOfElements ?? 0
    }

    private weak var section: Section?

    public init<Section, Cell, Background>(section: Section,
                                           cell: CollectionElement<Cell>,
                                           background: CollectionElement<Background>? = nil)
        where Cell: UICollectionViewCell, Background: UICollectionReusableView, Section: Composed.Section {
            self.section = section

            let cellDequeueMethod: DequeueMethod<UICollectionViewCell>
            switch cell.dequeueMethod {
            case .class: cellDequeueMethod = .class(Cell.self)
            case .nib: cellDequeueMethod = .nib(Cell.self)
            case .storyboard: cellDequeueMethod = .storyboard(Cell.self)
            }

            self.cell = CollectionElement(section: section, dequeueMethod: cellDequeueMethod, reuseIdentifier: cell.reuseIdentifier, cell.configure)
            self.background = background as? CollectionElement<UICollectionReusableView>
    }

}
