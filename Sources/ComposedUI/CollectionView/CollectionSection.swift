import UIKit
import Composed

/// Defines a configuration for a section in a `UICollectionView`.
/// The section must contain a cell element, but can also optionally include a header and/or footer element.
open class CollectionSection: CollectionElementsProvider {

    /// The cell configuration element
    public let cell: CollectionCellElement<UICollectionViewCell>

    /// The header configuration element
    public let header: CollectionSupplementaryElement<UICollectionReusableView>?

    /// The footer configuration element
    public let footer: CollectionSupplementaryElement<UICollectionReusableView>?

    /// The number of elements in this section
    open var numberOfElements: Int {
        return section?.numberOfElements ?? 0
    }

    // The underlying section associated with this section
    private weak var section: Section?

    /// Makes a new configuration with the specified cell, header and/or footer elements
    /// - Parameters:
    ///   - section: The section this will be associated with
    ///   - cell: The cell configuration element
    ///   - header: The header configuration element
    ///   - footer: The footer configuration element
    public init<Section, Cell, Header, Footer>(section: Section,
                                               cell: CollectionCellElement<Cell>,
                                               header: CollectionSupplementaryElement<Header>? = nil,
                                               footer: CollectionSupplementaryElement<Footer>? = nil)
        where Header: UICollectionReusableView, Footer: UICollectionReusableView, Cell: UICollectionViewCell, Section: Composed.Section {
            self.section = section

            // The code below copies the relevent elements to erase type-safety

            self.cell = CollectionCellElement(section: section,
                                              dequeueMethod: cell.dequeueMethod.map(),
                                              reuseIdentifier: cell.reuseIdentifier,
                                              configure: { cell.configure($0 as! Cell, $1, $2) },
                                              willAppear: { cell.willAppear($0 as! Cell, $1, $2) },
                                              didDisappear: { cell.didDisappear($0 as! Cell, $1, $2) })

            if let header = header {
                let kind: CollectionElementKind
                if case .automatic = header.kind {
                    kind = .custom(kind: UICollectionView.elementKindSectionHeader)
                } else {
                    kind = header.kind
                }

                self.header = CollectionSupplementaryElement(section: section,
                                                             dequeueMethod: header.dequeueMethod.map(),
                                                             reuseIdentifier: header.reuseIdentifier,
                                                             kind: kind,
                                                             configure: { header.configure($0 as! Header, $1, $2) })
            } else {
                self.header = nil
            }

            if let footer = footer {
                let kind: CollectionElementKind
                if case .automatic = footer.kind {
                    kind = .custom(kind: UICollectionView.elementKindSectionFooter)
                } else {
                    kind = footer.kind
                }
                
                self.footer = CollectionSupplementaryElement(section: section,
                                                             dequeueMethod: footer.dequeueMethod.map(),
                                                             reuseIdentifier: footer.reuseIdentifier,
                                                             kind: kind,
                                                             configure: { footer.configure($0 as! Footer, $1, $2) })
            } else {
                self.footer = nil
            }
    }

}
