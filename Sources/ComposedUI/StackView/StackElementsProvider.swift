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
