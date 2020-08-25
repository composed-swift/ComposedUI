import UIKit
import Composed

open class StackCoordinator: NSObject {

    public var sectionProvider: SectionProvider {
        return mapper.provider
    }

    private var mapper: SectionProviderMapping
    private let composedView: ComposedView

    private var cachedProviders: [StackElementsProvider] = []

    public init(composedView: ComposedView, sectionProvider: SectionProvider) {
        if !composedView.sections.isEmpty {
            assertionFailure("The stackView must not contain any existing arranged subviews")
            composedView.removeAllSections()
        }

        self.composedView = composedView
        self.mapper = SectionProviderMapping(provider: sectionProvider)

        super.init()

        prepareSections()
        reloadComposedView()
    }

    open func replace(sectionProvider: SectionProvider) {
        mapper = SectionProviderMapping(provider: sectionProvider)
        prepareSections()
    }

    private func prepareSections() {
        mapper.delegate = self
        cachedProviders.removeAll()

        for index in 0..<mapper.numberOfSections {
            guard let section = (mapper.provider.sections[index] as? StackSectionProvider)?.section(with: composedView.traitCollection) else {
                fatalError("No provider available for section: \(index), or it does not conform to StackSectionProvider")
            }

            cachedProviders.append(section)
        }
    }

    public func reloadData() {
        prepareSections()
        composedView.removeAllSections()
        reloadComposedView()
    }

    private func reloadComposedView() {
        for section in 0..<sectionProvider.sections.count {
            insertSection(at: section, with: .none)
        }
    }

}

extension StackCoordinator: SectionProviderMappingDelegate {

    public func mappingDidInvalidate(_ mapping: SectionProviderMapping) {
        reloadData()
    }

    private func insertSection(at sectionIndex: Int, with animation: ComposedStackView.Animation = .fade) {
        let section = ComposedSectionView()
        let provider = self.cachedProviders[sectionIndex]

        if let appearance = sectionProvider.sections[sectionIndex] as? StackSectionAppearanceHandler {
            section.separatorInsets = appearance.separatorInsets(suggested: section.separatorInsets, traitCollection: composedView.traitCollection)
            section.separatorColor = appearance.separatorColor(suggested: section.separatorColor, traitCollection: composedView.traitCollection)
        }

        for itemIndex in 0..<provider.numberOfElements {
            let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
            insertItem(at: indexPath, into: section)
        }

        composedView.insertSection(section, at: sectionIndex, with: animation)
    }

    private func insertItem(at indexPath: IndexPath, into section: ComposedSectionView) {
        let cell: ComposedViewCell
        let provider = cachedProviders[indexPath.section]

        switch provider.cell.loadingMethod {
        case let .fromClass(classType):
            cell = classType.init()
        case let .fromNib(nibType):
            guard let nibCell = UINib(nibName: String(describing: nibType), bundle: Bundle(for: nibType)).instantiate(withOwner: nil, options: nil).first as? ComposedViewCell else {
                fatalError("No nib with the name '\(String(describing: nibType))' found or the nib did not contain a single view of type `ComposedViewCell`")
            }

            cell = nibCell
        }

        provider.cell.configure(cell, indexPath.item, sectionProvider.sections[indexPath.section])
        section.insertItem(cell, at: indexPath.item)
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertSections sections: IndexSet) {
        prepareSections()
        sections.forEach { insertSection(at: $0) }
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertElementsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { insertItem(at: $0, into: composedView.sections[$0.section]) }
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateElementsAt indexPaths: [IndexPath]) {
        indexPaths.forEach {
            let provider = cachedProviders[$0.section].cell
            let cell = composedView.sections[$0.section].visibleCells[$0.item]
            provider.configure(cell, $0.item, sectionProvider.sections[$0.section])
        }
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveSections sections: IndexSet) {
        prepareSections()
        sections.forEach { composedView.removeSection(at: $0) }
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveElementsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { composedView.sections[$0.section].deleteItem(at: $0.item) }
    }

    public func mappingWillBeginUpdating(_ mapping: SectionProviderMapping) { }
    public func mappingDidEndUpdating(_ mapping: SectionProviderMapping) { }
    public func mapping(_ mapping: SectionProviderMapping, didUpdateSections sections: IndexSet) { }
    public func mapping(_ mapping: SectionProviderMapping, didMoveElementsAt moves: [(IndexPath, IndexPath)]) { }
    public func mapping(_ mapping: SectionProviderMapping, selectedIndexesIn section: Int) -> [Int] { return [] }
    public func mapping(_ mapping: SectionProviderMapping, select indexPath: IndexPath) { }
    public func mapping(_ mapping: SectionProviderMapping, deselect indexPath: IndexPath) { }
    public func mapping(_ mapping: SectionProviderMapping, move sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) { }

}

public extension StackCoordinator {

    /// A convenience initializer that allows creation without a provider
    /// - Parameters:
    ///   - composedView: The `ComposedView` associated with this coordinator
    ///   - sections: The sections associated with this coordinator
    convenience init(composedView: ComposedView, sections: Section...) {
        let provider = ComposedSectionProvider()
        sections.forEach(provider.append(_:))
        self.init(composedView: composedView, sectionProvider: provider)
    }

}
