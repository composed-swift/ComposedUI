import UIKit
import Composed

open class StackCoordinator: NSObject {

    public var sectionProvider: SectionProvider {
        return mapper.provider
    }

    private var mapper: SectionProviderMapping
    private let composedView: ComposedView

    public init(composedView: ComposedView, sectionProvider: SectionProvider) {
        if !composedView.sections.isEmpty {
//            assertionFailure("The stackView must not contain any existing arranged subviews")
//            composedView.removeAllSections()
        }

        self.composedView = composedView
        self.mapper = SectionProviderMapping(provider: sectionProvider)
        super.init()
        prepareSections()
    }

    private func prepareSections() {

    }

}
