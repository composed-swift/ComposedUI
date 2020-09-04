import UIKit
import Composed

open class UICollectionSection<S>: UISection, CollectionSectionProvider, Identifiable where S: Section {

    public let section: S
    public var numberOfElements: Int { return section.numberOfElements }
    public weak var updateDelegate: SectionUpdateDelegate?

    private var cell: CollectionCellElement<UICollectionViewCell>?
    private var header: CollectionSupplementaryElement<UICollectionReusableView>?
    private var footer: CollectionSupplementaryElement<UICollectionReusableView>?
    private var viewProvider: CollectionSupplementaryElement<UICollectionReusableView>?

    public lazy var layoutHandlers = LayoutHandlers()
    public lazy var selectionHandlers = SelectionHandlers()
    public lazy var editingHandlers = EditingHandlers()
    public lazy var reoderingHandlers = ReorderingHandlers()

    public init<Cell>(section: S, dequeueMethod: DequeueMethod<Cell>, _ cellHandler: @escaping (Cell, Int, S) -> Void) where Cell: UICollectionViewCell {
        self.section = section

        cell = CollectionCellElement(section: section, dequeueMethod: dequeueMethod.map()) { cell, index, section in
            cellHandler(cell as! Cell, index, section)
        }
    }
 
    public func headerProvider<View>(deqeueMethod: DequeueMethod<View>, _ provider: @escaping (View, Int, S) -> Void) where View: UICollectionReusableView {
        header = supplementaryView(configuration: UISectionView(dequeueMethod: deqeueMethod, viewHandler: provider))
    }

    public func footerProvider<View>(deqeueMethod: DequeueMethod<View>, _ provider: @escaping (View, Int, S) -> Void) where View: UICollectionReusableView {
        footer = supplementaryView(configuration: UISectionView(dequeueMethod: deqeueMethod, viewHandler: provider))
    }

    public func supplementaryViewProvider<View>(dequeueMethod: DequeueMethod<View>, kind: String? = nil, reuseIdentifier: String? = nil, _ provider: @escaping (View, Int, S) -> Void) where View: UICollectionReusableView {
        viewProvider = supplementaryView(configuration: UISectionView(dequeueMethod: dequeueMethod, kind: kind == nil ? .automatic : .custom(kind: kind!), reuseIdentifier: reuseIdentifier, viewHandler: provider))
    }

    private func supplementaryView<View>(configuration: UISectionView<S, View>?) -> CollectionSupplementaryElement<UICollectionReusableView>? where View: UICollectionReusableView {
        guard let configuration = configuration else { return nil }
        return CollectionSupplementaryElement(section: section, dequeueMethod: configuration.dequeueMethod.map(), reuseIdentifier: configuration.reuseIdentifier, kind: configuration.kind) { view, index, section in
            configuration.viewHandler(view as! View, index, section)
        }
    }

    public func section(with traitCollection: UITraitCollection) -> CollectionSection {
        return CollectionSection(section: section, cell: cell!, header: header, footer: footer)
    }

}
