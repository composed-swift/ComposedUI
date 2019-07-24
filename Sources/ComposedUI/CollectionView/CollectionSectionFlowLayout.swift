import UIKit
import Composed

open class CollectionSectionFlowLayout: CollectionSection {

    public let header: CollectionElement<UICollectionReusableView>?
    public let footer: CollectionElement<UICollectionReusableView>?

    public init<Cell: UICollectionViewCell, Section: Composed.Section>(section: Section,
                                                                       sizingStrategy: CollectionSizingStrategyFlowLayout,
                                                                       cellDequeueMethod: DequeueMethod<Cell>,
                                                                       cellReuseIdentifier: String? = nil,
                                                                       cellConfigurator: @escaping (Cell, Int, Section, CollectionElement<Cell>.Context) -> Void,
                                                                       background: CollectionElement<UICollectionReusableView>? = nil,
                                                                       header: CollectionElement<UICollectionReusableView>? = nil,
                                                                       footer: CollectionElement<UICollectionReusableView>? = nil) {
        self.header = header
        self.footer = footer

        super.init(section: section,
                   sizingStrategy: sizingStrategy,
                   cellDequeueMethod: cellDequeueMethod,
                   cellReuseIdentifier: cellReuseIdentifier,
                   cellConfigurator: cellConfigurator,
                   background: background)
    }

}
