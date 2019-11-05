import UIKit
import Composed

public protocol CollectionSectionProvider {
    func sizingStrategy(with environment: Environment) -> CollectionSizingStrategy?
    func section(with environment: Environment) -> CollectionSection
}
