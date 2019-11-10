import UIKit

public protocol TableElementsProvider {
    var cell: TableElement<UITableViewCell> { get }
    var header: TableElement<UITableViewHeaderFooterView>? { get }
    var footer: TableElement<UITableViewHeaderFooterView>? { get }
    var numberOfElements: Int { get }
}

public extension TableElementsProvider {
    var isEmpty: Bool { return numberOfElements == 0 }
}

public protocol TableSectionProvider {
    func section(with traitCollection: UITraitCollection) -> TableSection
}
