import UIKit
import Composed

open class CollectionSectionFlowLayout: CollectionSection {

    public let header: CollectionElement<UICollectionReusableView>?
    public let footer: CollectionElement<UICollectionReusableView>?

    public init<Section, Header, Footer, Cell>(section: Section,
                                               cell: CollectionElement<Cell>,
                                               header: CollectionElement<Header>? = nil,
                                               footer: CollectionElement<Footer>? = nil,
                                               background: CollectionElement<UICollectionReusableView>? = nil)
        where Header: UICollectionReusableView, Footer: UICollectionReusableView, Cell: UICollectionViewCell, Section: Composed.Section {

            self.header = header as? CollectionElement<UICollectionReusableView>
            self.footer = footer as? CollectionElement<UICollectionReusableView>

            super.init(section: section, cell: cell, background: background)
    }

}
