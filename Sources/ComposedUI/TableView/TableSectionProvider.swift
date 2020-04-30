import UIKit

internal protocol TableElementsProvider {
    var cell: TableElement<UITableViewCell> { get }
    var header: TableElement<UITableViewHeaderFooterView>? { get }
    var footer: TableElement<UITableViewHeaderFooterView>? { get }
    var numberOfElements: Int { get }
}

extension TableElementsProvider {
    var isEmpty: Bool { return numberOfElements == 0 }
}

public protocol TableSectionProvider {
    func section(with traitCollection: UITraitCollection) -> TableSection
}

public protocol TableSectionLayoutHandler: TableSectionProvider {
    func estimatedHeightForHeader(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat
    func estimatedHeightForFooter(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat
    func estimatedHeightForItem(at index: Int, suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat

    func heightForHeader(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat
    func heightForFooter(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat
    func heightForItem(at index: Int, suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat
}

public extension TableSectionLayoutHandler {
    func estimatedHeightForHeader(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat { return suggested }
    func estimatedHeightForFooter(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat { return suggested }
    func estimatedHeightForItem(at index: Int, suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat { return suggested }

    func heightForHeader(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat { return suggested }
    func heightForFooter(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat { return suggested }
    func heightForItem(at index: Int, suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat { return suggested }
}
