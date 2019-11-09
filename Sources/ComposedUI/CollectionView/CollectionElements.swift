import UIKit
import Composed

public protocol CollectionElementsProvider {
    var cell: CollectionElement<UICollectionViewCell> { get }
    var header: CollectionElement<UICollectionReusableView>? { get }
    var footer: CollectionElement<UICollectionReusableView>? { get }
    var background: CollectionElement<UICollectionReusableView>? { get }
    var numberOfElements: Int { get }
}

/// Defines a provider for a view, prototype and configuration handler. Cells, headers and footers can all be configured with this provider
public final class CollectionElement<View> where View: UICollectionReusableView {

    public typealias ViewType = UICollectionReusableView

    public let dequeueMethod: DequeueMethod<View>
    public let configure: (UICollectionReusableView, Int, Section) -> Void

    public let reuseIdentifier: String

    public init<Section>(section: Section, dequeueMethod: DequeueMethod<View>, reuseIdentifier: String? = nil, _ configure: @escaping (View, Int, Section) -> Void) where Section: Composed.Section {
        self.reuseIdentifier = reuseIdentifier ?? View.reuseIdentifier
        self.dequeueMethod = dequeueMethod

        self.configure = { view, index, section in
            // swiftlint:disable force_cast
            configure(view as! View, index, section as! Section)
        }
    }

}
