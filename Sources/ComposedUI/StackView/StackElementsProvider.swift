import UIKit

public protocol StackElementsProvider {
    var cell: StackCellElement<ComposedViewCell> { get }
    var numberOfElements: Int { get }
}

public extension StackElementsProvider {
    var isEmpty: Bool { return numberOfElements == 0 }
}

public protocol StackSectionProvider {
    func section(with traitCollection: UITraitCollection) -> StackSection
}

public protocol StackSectionAppearanceHandler: StackSectionProvider {
    func separatorInsets(suggested: UIEdgeInsets, traitCollection: UITraitCollection) -> UIEdgeInsets
    func separatorColor(suggested: UIColor?, traitCollection: UITraitCollection) -> UIColor?
}

public extension StackSectionAppearanceHandler {
    func separatorInsets(suggested: UIEdgeInsets, traitCollection: UITraitCollection) -> UIEdgeInsets { return suggested }
    func separatorColor(suggested: UIColor?, traitCollection: UITraitCollection) -> UIColor? { return suggested }
}
