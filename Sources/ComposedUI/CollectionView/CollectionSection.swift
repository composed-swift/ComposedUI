import UIKit
import Composed

/// Defines a configuration for a section in a `UICollectionView`.
/// The section must contain a cell element, but can also optionally include a header and/or footer element.
open class CollectionSection: CollectionElementsProvider {

    /// The cell configuration element
    public let cell: CollectionCellElement<UICollectionViewCell>

    public var uniqueCells: [(dequeueMethod: DequeueMethod<UICollectionViewCell>, resuseIdentifier: String)] {
        [(cell.dequeueMethod, cell.reuseIdentifier)]
    }

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
            
            let dequeueMethod: DequeueMethod<UICollectionViewCell>
            switch cell.dequeueMethod {
            case .fromClass: dequeueMethod = .fromClass(Cell.self)
            case .fromNib: dequeueMethod = .fromNib(Cell.self)
            case .fromStoryboard: dequeueMethod = .fromStoryboard(Cell.self)
            }

            self.cell = CollectionCellElement(section: section,
                                              dequeueMethod: dequeueMethod,
                                              reuseIdentifier: cell.reuseIdentifier,
                                              configure: cell.configure,
                                              willAppear: cell.willAppear,
                                              didDisappear: cell.didDisappear)

            if let header = header {
                let dequeueMethod: DequeueMethod<UICollectionReusableView>
                switch header.dequeueMethod {
                case .fromClass: dequeueMethod = .fromClass(Header.self)
                case .fromNib: dequeueMethod = .fromNib(Header.self)
                case .fromStoryboard: dequeueMethod = .fromStoryboard(Header.self)
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
                case .fromClass: dequeueMethod = .fromClass(Footer.self)
                case .fromNib: dequeueMethod = .fromNib(Footer.self)
                case .fromStoryboard: dequeueMethod = .fromStoryboard(Footer.self)
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

    public func cellForIndex(_ index: Int) -> CollectionCellElement<UICollectionViewCell> {
        return cell
    }

}
