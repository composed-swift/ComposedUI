import UIKit
import Composed

open class CollectionSection: CollectionElementsProvider {

    public let cell: CollectionElement<UICollectionViewCell>
    public let header: CollectionElement<UICollectionReusableView>?
    public let footer: CollectionElement<UICollectionReusableView>?

    open var numberOfElements: Int {
        return section?.numberOfElements ?? 0
    }

    private weak var section: Section?

    public init<Section, Cell, Header, Footer>(section: Section,
                                               cell: CollectionElement<Cell>,
                                               header: CollectionElement<Header>? = nil,
                                               footer: CollectionElement<Footer>? = nil)
        where Header: UICollectionReusableView, Footer: UICollectionReusableView, Cell: UICollectionViewCell, Section: Composed.Section {
            self.section = section
            
            let dequeueMethod: DequeueMethod<UICollectionViewCell>
            switch cell.dequeueMethod {
            case .class: dequeueMethod = .class(Cell.self)
            case .nib: dequeueMethod = .nib(Cell.self)
            case .storyboard: dequeueMethod = .storyboard(Cell.self)
            }

            self.cell = CollectionElement(section: section, dequeueMethod: dequeueMethod, reuseIdentifier: cell.reuseIdentifier, cell.configure)

            if let header = header {
                let dequeueMethod: DequeueMethod<UICollectionReusableView>
                switch header.dequeueMethod {
                case .class: dequeueMethod = .class(Header.self)
                case .nib: dequeueMethod = .nib(Header.self)
                case .storyboard: dequeueMethod = .storyboard(Header.self)
                }

                self.header = CollectionElement(section: section, dequeueMethod: dequeueMethod, reuseIdentifier: header.reuseIdentifier, header.configure)
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

                self.footer = CollectionElement(section: section, dequeueMethod: dequeueMethod, reuseIdentifier: footer.reuseIdentifier, footer.configure)
            } else {
                self.footer = nil
            }
    }

}
