import UIKit
import Composed

open class StackCoordinator: NSObject {

    public var sectionProvider: SectionProvider {
        return mapper.provider
    }

    private var mapper: SectionProviderMapping
    private let stackView: UIStackView

    public init(stackView: UIStackView, sectionProvider: SectionProvider) {
        precondition(stackView.arrangedSubviews.isEmpty, "The stackView must not contain any existing arranged subviews")
        self.stackView = stackView
        self.mapper = SectionProviderMapping(provider: sectionProvider)
        super.init()
        prepareSections()
    }

    private func prepareSections() {

    }

}

public extension StackCoordinator {

    convenience init(stackView: ComposedStackView, sectionProvider: SectionProvider) {
        self.init(stackView: stackView.stackView, sectionProvider: sectionProvider)
    }

}
