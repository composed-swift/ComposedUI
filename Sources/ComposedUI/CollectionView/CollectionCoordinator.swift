import UIKit
import Composed

open class CollectionCoordinator: NSObject, UICollectionViewDataSource, SectionProviderMappingDelegate {

    private let mapper: SectionProviderMapping
    private let collectionView: UICollectionView

    private var cachedProviders: [Int: CollectionProvider] = [:]
    private var cachedStrategies: [Int: CollectionSizingStrategy] = [:]
    private var flowLayoutSizeObserver: NSKeyValueObservation?
    private var layoutObserver: NSKeyValueObservation?


    deinit {
        layoutObserver?.invalidate()
        flowLayoutSizeObserver?.invalidate()
    }

    public init(collectionView: UICollectionView, sectionProvider: SectionProvider) {
        self.collectionView = collectionView
        mapper = SectionProviderMapping(provider: sectionProvider)

        super.init()

        collectionView.dataSource = self
        collectionView.delegate = self

        prepareSections()
    }

    private func prepareSections() {
        cachedProviders.removeAll()

        let env = Environment(bounds: collectionView.bounds, traitCollection: collectionView.traitCollection)

        for index in 0..<mapper.numberOfSections {
            guard let section = (mapper.provider.sections[index] as? CollectionSectionProvider)?.section(with: env) else {
                fatalError("No provider available for section: \(index), or it does not conform to CollectionSectionProvider")
            }

            cachedProviders[index] = section

            switch section.cell.dequeueMethod {
            case let .nib(type):
                let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                collectionView.register(nib, forCellWithReuseIdentifier: section.cell.reuseIdentifier)
            case let .class(type):
                collectionView.register(type, forCellWithReuseIdentifier: section.cell.reuseIdentifier)
            case .storyboard:
                break
            }
        }
    }

    // MARK: - SectionProviderMappingDelegate

    public func mappingsDidUpdate(_ mapping: SectionProviderMapping) {
        prepareSections()
        collectionView.reloadData()
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertSections sections: IndexSet) {
        prepareSections()
        collectionView.insertSections(sections)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveSections sections: IndexSet) {
        prepareSections()
        collectionView.deleteSections(sections)
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateSections sections: IndexSet) {
        prepareSections()
        collectionView.reloadSections(sections)
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertElementsAt indexPaths: [IndexPath]) {
        collectionView.insertItems(at: indexPaths)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveElementsAt indexPaths: [IndexPath]) {
        collectionView.deleteItems(at: indexPaths)
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateElementsAt indexPaths: [IndexPath]) {
        collectionView.reloadItems(at: indexPaths)
    }

    public func mapping(_ mapping: SectionProviderMapping, didMoveElementsAt moves: [(IndexPath, IndexPath)]) {
        moves.forEach {
            collectionView.moveItem(at: $0.0, to: $0.1)
        }
    }

    // MARK: - UICollectionViewDataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return mapper.numberOfSections
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionProvider(for: section)?.numberOfElements ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = collectionProvider(for: indexPath.section) else {
            fatalError("No UI configuration available for section \(indexPath.section)")
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: section.cell.reuseIdentifier, for: indexPath)
        section.cell.configure(cell, indexPath.row, mapper.provider.sections[indexPath.section], CollectionElementContext(isSizing: false))

        return cell
    }

    private func collectionProvider(for section: Int) -> CollectionProvider? {
        return cachedProviders[section]
    }

}

extension CollectionCoordinator: UICollectionViewDelegateFlowLayout {

    public func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext? = nil) {
        guard collectionView.window != nil else { return }

        cachedStrategies.removeAll()

        if let context = context {
            collectionView.collectionViewLayout.invalidateLayout(with: context)
        } else {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    private func flowLayoutStrategy(for section: Int) -> CollectionSizingStrategyFlowLayout? {
        if let strategy = cachedStrategies[section] as? CollectionSizingStrategyFlowLayout { return strategy }
        let env = Environment(bounds: collectionView.bounds, traitCollection: collectionView.traitCollection)
        cachedStrategies[section] = (mapper.provider.sections[section] as? CollectionSectionProvider)?.sizingStrategy(with: env) as? CollectionSizingStrategyFlowLayout
        return cachedStrategies[section] as? CollectionSizingStrategyFlowLayout
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return flowLayoutStrategy(for: section)?.metrics.sectionInsets ?? .zero
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return flowLayoutStrategy(for: section)?.metrics.minimumInteritemSpacing ?? 0
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return flowLayoutStrategy(for: section)?.metrics.minimumLineSpacing ?? 0
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }

        guard let strategy = flowLayoutStrategy(for: indexPath.section),
            let section = collectionProvider(for: indexPath.section),
            let cell = section.cell.prototype else {
                // if the configuration doesn't provide a prototype, we can't auto-size so we fall back to the layout size
                return layout.itemSize
        }

        section.cell.configure(cell, indexPath.row, mapper.provider.sections[indexPath.section], CollectionElementContext(isSizing: true))

        var layoutSize = collectionView.bounds.size

        switch layout.sectionInsetReference {
        case .fromContentInset:
            layoutSize.width = collectionView.bounds.width
                - collectionView.adjustedContentInset.left
                - collectionView.adjustedContentInset.right
        case .fromSafeArea:
            layoutSize.width = collectionView.bounds.width
                - collectionView.safeAreaInsets.left
                - collectionView.safeAreaInsets.right
        case .fromLayoutMargins:
            layoutSize.width = collectionView.bounds.width
                - collectionView.layoutMargins.left
                - collectionView.layoutMargins.right
        default:
            layoutSize.width = collectionView.bounds.width
        }

        let context = CollectionSizingContext(index: indexPath.row, layoutSize: layoutSize, adjustedContentInset: collectionView.adjustedContentInset, prototype: cell)
        return strategy.size(forElementAt: indexPath.row, context: context)
    }

}
