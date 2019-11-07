import UIKit
import Composed

public protocol CollectionSectionProvider {
    func section(with environment: Environment) -> CollectionSection
}

public protocol CollectionSectionProviderFlowLayout: CollectionSectionProvider {
    func sizingStrategy(with environment: Environment) -> CollectionFlowLayoutSizingStrategy?
}
