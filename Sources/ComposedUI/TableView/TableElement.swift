import UIKit
import Composed

public final class TableElement<View> where View: UIView & ReusableCell {

    public let dequeueMethod: DequeueMethod<View>
    public let configure: (UIView, Int, Section) -> Void
    public let reuseIdentifier: String

    /// A closure that will be called before the cell is appeared
    public let willAppear: (UIView, Int, Section) -> Void
    /// A closure that will be called after the cell has disappeared
    public let didDisappear: (UIView, Int, Section) -> Void

    public init<Section>(section: Section, dequeueMethod: DequeueMethod<View>, reuseIdentifier: String? = nil, configure: @escaping (View, Int, Section) -> Void) where Section: Composed.Section {
        self.reuseIdentifier = reuseIdentifier ?? View.reuseIdentifier
        self.dequeueMethod = dequeueMethod

        // swiftlint:disable force_cast

        self.configure = { view, index, section in
            configure(view as! View, index, section as! Section)
        }

        willAppear = { _, _, _ in }
        didDisappear = { _, _, _ in }
    }

    public init<Section>(section: Section,
                         dequeueMethod: DequeueMethod<View>,
                         reuseIdentifier: String? = nil,
                         configure: @escaping (View, Int, Section) -> Void,
                         willAppear: ((View, Int, Section) -> Void)? = nil,
                         didDisappear: ((View, Int, Section) -> Void)? = nil)
        where Section: Composed.Section {
            self.reuseIdentifier = reuseIdentifier ?? View.reuseIdentifier
            self.dequeueMethod = dequeueMethod

            // swiftlint:disable force_cast

            self.configure = { view, index, section in
                configure(view as! View, index, section as! Section)
            }

            self.willAppear = { view, index, section in
                willAppear?(view as! View, index, section as! Section)
            }

            self.didDisappear = { view, index, section in
                didDisappear?(view as! View, index, section as! Section)
            }
    }

}
