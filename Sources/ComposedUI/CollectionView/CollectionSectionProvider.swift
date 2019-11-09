import UIKit
import Composed

public protocol CollectionSectionProvider {
    func section(with traitCollection: UITraitCollection) -> CollectionSection
}
