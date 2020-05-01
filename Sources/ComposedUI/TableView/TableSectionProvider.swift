import UIKit

/// Provides a section to a table view. Conform to this protool to use your section with a `UITableView`
public protocol TableSectionProvider {

    /// Return a section cofiguration for the table view.
    /// - Parameter traitCollection: The trait collection being applied to the view
    func section(with traitCollection: UITraitCollection) -> TableSection

}

internal protocol TableElementsProvider {
    var cell: TableElement<UITableViewCell> { get }
    var header: TableElement<UITableViewHeaderFooterView>? { get }
    var footer: TableElement<UITableViewHeaderFooterView>? { get }
    var numberOfElements: Int { get }
}

extension TableElementsProvider {
    var isEmpty: Bool { return numberOfElements == 0 }
}
