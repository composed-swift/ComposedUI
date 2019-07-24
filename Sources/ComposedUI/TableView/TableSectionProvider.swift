import UIKit

public protocol TableProvider {
    var header: TableElement<UITableViewHeaderFooterView>? { get }
    var footer: TableElement<UITableViewHeaderFooterView>? { get }
    var numberOfElements: Int { get }
    var reuseIdentifier: String { get }
    var prototype: UITableViewCell { get }
    var dequeueMethod: DequeueMethod { get }
    func configure(cell: UITableViewCell, at index: Int, context: TableElement<UITableViewCell>.Context)
}

public protocol TableSectionProvider {
    var tableSection: TableSection { get }
}
