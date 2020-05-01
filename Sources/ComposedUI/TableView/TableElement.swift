import UIKit
import Composed

public final class TableElement<View> where View: UIView & ReusableCell {

    /// The method to use for registering and dequeueing a view for this element
    public let dequeueMethod: DequeueMethod<View>

    /// A closure that will be called whenever the elements view needs to be configured
    public let configure: (UIView, Int, Section) -> Void

    /// The reuseIdentifier to use for this element
    public let reuseIdentifier: String

    /// The closure that will be called before the elements view appears
    public let willAppear: (UIView, Int, Section) -> Void
    /// The closure that will be called after the elements view disappears
    public let didDisappear: (UIView, Int, Section) -> Void

    /// Makes a new element for representing a view
    /// - Parameters:
    ///   - section: The section where this element's view will be shown in
    ///   - dequeueMethod: The method to use for registering and dequeueing a view for this element
    ///   - reuseIdentifier: The reuseIdentifier to use for this element
    ///   - configure: A closure that will be called whenever the elements view needs to be configured
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

    /// Makes a new element for representing a view
    /// - Parameters:
    ///   - section: The section where this element's view will be shown in
    ///   - dequeueMethod: The method to use for registering and dequeueing a view for this element
    ///   - reuseIdentifier: The reuseIdentifier to use for this element
    ///   - configure: A closure that will be called whenever the elements view needs to be configured
    ///   - willAppear: A closure that will be called before the elements view appears
    ///   - didDisappear: A closure that will be called after the elements view disappears
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
