import UIKit
import Composed

public final class TableElement<View> where View: UIView & ReusableCell {

    public typealias ViewType = View

    internal let dequeueMethod: DequeueMethod<View>
    internal let configure: (UIView, Int, Section) -> Void

    internal let reuseIdentifier: String

    internal init<Section>(section: Section, dequeueMethod: DequeueMethod<View>, reuseIdentifier: String? = nil, configure: @escaping (View, Int, Section) -> Void) where Section: Composed.Section {
        self.reuseIdentifier = reuseIdentifier ?? View.reuseIdentifier
        self.dequeueMethod = dequeueMethod

        self.configure = { view, index, section in
            // swiftlint:disable force_cast
            configure(view as! View, index, section as! Section)
        }
    }

}
