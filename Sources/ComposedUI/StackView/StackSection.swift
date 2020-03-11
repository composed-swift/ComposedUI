import UIKit
import Composed

open class StackSection: StackElementsProvider {

    public var cell: StackCellElement<ComposedViewCell>

    public var numberOfElements: Int {
        return section?.numberOfElements ?? 0
    }

    private weak var section: Section?

    public init<Section, Cell>(section: Section, cell: StackCellElement<Cell>) where Section: Composed.Section, Cell: ComposedViewCell {
        self.section = section

        let loadingMethod: StackLoadingMethod<ComposedViewCell>
        switch cell.loadingMethod {
        case .fromClass: loadingMethod = .fromClass(Cell.self)
        case .fromNib: loadingMethod = .fromNib(Cell.self)
        }

        self.cell = StackCellElement(section: section, loadingMethod: loadingMethod, configure: cell.configure)
    }

}
