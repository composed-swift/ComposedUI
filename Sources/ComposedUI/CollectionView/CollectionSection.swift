import UIKit
import Composed

open class CollectionSection: CollectionSectionElementsProvider {

    public let cell: CollectionCellElement<UICollectionViewCell>
    public let header: CollectionSupplementaryElement<UICollectionReusableView>?
    public let footer: CollectionSupplementaryElement<UICollectionReusableView>?

    open var numberOfElements: Int {
        return section?.numberOfElements ?? 0
    }

    private weak var section: Section?

    public init<Section, Cell, Header, Footer>(section: Section,
                                               cell: CollectionCellElement<Cell>,
                                               header: CollectionSupplementaryElement<Header>? = nil,
                                               footer: CollectionSupplementaryElement<Footer>? = nil)
        where Header: UICollectionReusableView, Footer: UICollectionReusableView, Cell: UICollectionViewCell, Section: Composed.Section {
            self.section = section

            // The code below copies the relevent elements to erase type-safety
            
            let dequeueMethod: DequeueMethod<UICollectionViewCell>
            switch cell.dequeueMethod {
            case .class: dequeueMethod = .class(Cell.self)
            case .nib: dequeueMethod = .nib(Cell.self)
            case .storyboard: dequeueMethod = .storyboard(Cell.self)
            }

            self.cell = CollectionCellElement(section: section,
                                              dequeueMethod: dequeueMethod,
                                              reuseIdentifier: cell.reuseIdentifier,
                                              configure: cell.configure)

            if let header = header {
                let dequeueMethod: DequeueMethod<UICollectionReusableView>
                switch header.dequeueMethod {
                case .class: dequeueMethod = .class(Header.self)
                case .nib: dequeueMethod = .nib(Header.self)
                case .storyboard: dequeueMethod = .storyboard(Header.self)
                }

                let kind: CollectionElementKind
                if case .automatic = header.kind {
                    kind = .custom(kind: UICollectionView.elementKindSectionHeader)
                } else {
                    kind = header.kind
                }

                self.header = CollectionSupplementaryElement(section: section,
                                                             dequeueMethod: dequeueMethod,
                                                             reuseIdentifier: header.reuseIdentifier,
                                                             kind: kind,
                                                             configure: header.configure)
            } else {
                self.header = nil
            }

            if let footer = footer {
                let dequeueMethod: DequeueMethod<UICollectionReusableView>
                switch footer.dequeueMethod {
                case .class: dequeueMethod = .class(Footer.self)
                case .nib: dequeueMethod = .nib(Footer.self)
                case .storyboard: dequeueMethod = .storyboard(Footer.self)
                }

                let kind: CollectionElementKind
                if case .automatic = footer.kind {
                    kind = .custom(kind: UICollectionView.elementKindSectionFooter)
                } else {
                    kind = footer.kind
                }
                
                self.footer = CollectionSupplementaryElement(section: section,
                                                             dequeueMethod: dequeueMethod,
                                                             reuseIdentifier: footer.reuseIdentifier,
                                                             kind: kind,
                                                             configure: footer.configure)
            } else {
                self.footer = nil
            }
    }

}
