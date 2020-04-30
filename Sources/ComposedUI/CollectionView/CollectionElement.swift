import UIKit
import Composed

/// A `UICollectionView` supports different elementKind's for supplementary view, this provides a solution
/// A collection view can provide headers and footers via custom elementKind's or it using built-in definitions, this provides a solution for specifying which option to use
public enum CollectionElementKind {
    /// Either `elementKindSectionHeader` or `elementKindSectionFooter` will be used
    case automatic
    /// The custom `kind` value will be used
    case custom(kind: String)

    internal var rawValue: String {
        switch self {
        case .automatic: return "automatic"
        case let .custom(kind): return kind
        }
    }
}

/// Defines an element used by a `CollectionSection` to provide configurations for a cell, header and/or footer.
public protocol CollectionElement {

    /// A typealias for representing a `UICollectionReusableView`
    associatedtype View: UICollectionReusableView

    /// The method to use for registering and dequeueing a view for this element
    var dequeueMethod: DequeueMethod<View> { get }

    /// A closure that will be called whenever the elements view needs to be configured
    var configure: (UICollectionReusableView, Int, Section) -> Void { get }

    /// The reuseIdentifier to use for this element
    var reuseIdentifier: String { get }

}

/// Defines a cell element to be used by a `CollectionSection` to provide a configuration for a cell
public final class CollectionCellElement<View>: CollectionElement where View: UICollectionViewCell {

    public let dequeueMethod: DequeueMethod<View>
    public let configure: (UICollectionReusableView, Int, Section) -> Void
    public let reuseIdentifier: String

    /// The closure that will be called before the elements view appears
    public let willAppear: (UICollectionReusableView, Int, Section) -> Void
    /// The closure that will be called after the elements view disappears
    public let didDisappear: (UICollectionReusableView, Int, Section) -> Void

    /// Makes a new element for representing a cell
    /// - Parameters:
    ///   - section: The section where this element's cell will be shown in
    ///   - dequeueMethod: The method to use for registering and dequeueing a cell for this element
    ///   - reuseIdentifier: The reuseIdentifier to use for this element
    ///   - configure: A closure that will be called whenever the elements view needs to be configured
    public init<Section>(section: Section,
                         dequeueMethod: DequeueMethod<View>,
                         reuseIdentifier: String? = nil,
                         configure: @escaping (View, Int, Section) -> Void)
        where Section: Composed.Section {
            self.reuseIdentifier = reuseIdentifier ?? View.reuseIdentifier
            self.dequeueMethod = dequeueMethod

            // swiftlint:disable force_cast

            self.configure = { view, index, section in
                configure(view as! View, index, section as! Section)
            }

            willAppear = { _, _, _ in }
            didDisappear = { _, _, _ in }
    }

    /// Makes a new element for representing a cell
    /// - Parameters:
    ///   - section: The section where this element's cell will be shown in
    ///   - dequeueMethod: The method to use for registering and dequeueing a cell for this element
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

/// Defines a supplementary element to be used by a `CollectionSection` to provide a configuration for a supplementary view
public final class CollectionSupplementaryElement<View>: CollectionElement where View: UICollectionReusableView {

    public let dequeueMethod: DequeueMethod<View>
    public let configure: (UICollectionReusableView, Int, Section) -> Void
    public let reuseIdentifier: String

    /// The `elementKind` this element represents
    public let kind: CollectionElementKind

    /// A closure that will be called before the elements view is appeared
    public let willAppear: ((UICollectionReusableView, Int, Section) -> Void)?
    /// A closure that will be called after the elements view has disappeared
    public let didDisappear: ((UICollectionReusableView, Int, Section) -> Void)?

    /// Makes a new element for representing a supplementary view
    /// - Parameters:
    ///   - section: The section where this element's view will be shown in
    ///   - dequeueMethod: The method to use for registering and dequeueing a view for this element
    ///   - reuseIdentifier: The reuseIdentifier to use for this element
    ///   - kind: The `elementKind` this element represents
    ///   - configure: A closure that will be called whenever the elements view needs to be configured
    public init<Section>(section: Section,
                         dequeueMethod: DequeueMethod<View>,
                         reuseIdentifier: String? = nil,
                         kind: CollectionElementKind = .automatic,
                         configure: @escaping (View, Int, Section) -> Void)
        where Section: Composed.Section {
            self.kind = kind
            self.reuseIdentifier = reuseIdentifier ?? View.reuseIdentifier
            self.dequeueMethod = dequeueMethod

            self.configure = { view, index, section in
                // swiftlint:disable force_cast
                configure(view as! View, index, section as! Section)
            }

            willAppear = nil
            didDisappear = nil
    }

    /// Makes a new element for representing a supplementary view
    /// - Parameters:
    ///   - section: The section where this element's view will be shown in
    ///   - dequeueMethod: The method to use for registering and dequeueing a view for this element
    ///   - reuseIdentifier: The reuseIdentifier to use for this element
    ///   - kind: The `elementKind` this element represents
    ///   - configure: A closure that will be called whenever the elements view needs to be configured
    ///   - willAppear: A closure that will be called before the elements view appears
    ///   - didDisappear: A closure that will be called after the elements view disappears
    public init<Section>(section: Section,
                         dequeueMethod: DequeueMethod<View>,
                         reuseIdentifier: String? = nil,
                         kind: CollectionElementKind = .automatic,
                         configure: @escaping (View, Int, Section) -> Void,
                         willAppear: ((View, Int, Section) -> Void)? = nil,
                         didDisappear: ((View, Int, Section) -> Void)? = nil)
        where Section: Composed.Section {
            self.kind = kind
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
