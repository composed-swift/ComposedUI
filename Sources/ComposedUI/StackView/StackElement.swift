import UIKit
import Composed

public enum StackLoadingMethod<Cell: ComposedViewCell> {
    case fromNib(Cell.Type)
    case fromClass(Cell.Type)
}

public final class StackCellElement<Cell> where Cell: ComposedViewCell {

    internal let loadingMethod: StackLoadingMethod<Cell>
    internal let configure: (ComposedViewCell, Int, Section) -> Void

    public init<Section>(section: Section, loadingMethod: StackLoadingMethod<Cell>, configure: @escaping (Cell, Int, Section) -> Void) where Section: Composed.Section {
        self.loadingMethod = loadingMethod
        self.configure = { cell, index, section in
            configure(cell as! Cell, index, section as! Section)
        }
    }

}
