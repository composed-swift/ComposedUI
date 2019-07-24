import UIKit
import Composed

open class CollectionCoordinator: NSObject, UICollectionViewDataSource, SectionProviderMappingDelegate {

    private let mapper: SectionProviderMapping
    private let collectionView: UICollectionView

    private var cachedProviders: [CollectionProvider] = []

    public var sections: [Section] {
        return mapper.provider.sections
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

            cachedProviders.append(section)

            let type = section.prototypeType
            switch section.dequeueMethod {
            case .nib:
                let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                collectionView.register(nib, forCellWithReuseIdentifier: section.reuseIdentifier)
            case .class:
                collectionView.register(type, forCellWithReuseIdentifier: section.reuseIdentifier)
            case .storyboard:
                break
            }
        }
    }

    // MARK: - SectionProviderMappingDelegate

    public func mappingsDidUpdate(_ mapping: SectionProviderMapping) {
        collectionView.reloadData()
        prepareSections()
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
        return collectionSection(for: section)?.numberOfElements ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = collectionSection(for: indexPath.section) else {
            fatalError("No UI configuration available for section \(indexPath.section)")
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: section.reuseIdentifier, for: indexPath)
        section.configure(cell: cell, at: indexPath.row, context: .presentation)
        return cell
    }

    private func collectionSection(for section: Int) -> CollectionProvider? {
        guard cachedProviders.indices.contains(section) else { return nil }
        return cachedProviders[section]
    }

}

extension CollectionCoordinator: UICollectionViewDelegateFlowLayout {

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let section = collectionSection(for: section) as? CollectionSectionFlowLayout,
            let strategy = section.sizingStrategy as? CollectionSizingStrategyFlowLayout else {
            return (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
        }
        
        return strategy.metrics.sectionInsets
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let section = collectionSection(for: section) as? CollectionSectionFlowLayout,
            let strategy = section.sizingStrategy as? CollectionSizingStrategyFlowLayout else {
                return (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? 0
        }

        return strategy.metrics.minimumInteritemSpacing
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let section = collectionSection(for: section) as? CollectionSectionFlowLayout,
            let strategy = section.sizingStrategy as? CollectionSizingStrategyFlowLayout else {
                return (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing ?? 0
        }

        return strategy.metrics.minimumLineSpacing
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }

        guard let section = collectionSection(for: indexPath.section), let cell = section.prototype else {
            // if the configuration doesn't provide a prototype, we can't auto-size so we fall back to the layout size
            return layout.itemSize
        }

        section.configure(cell: cell, at: indexPath.row, context: .sizing)

        let context = CollectionSizingContext(index: indexPath.row, layoutSize: collectionView.bounds.size, prototype: cell)
        return section.sizingStrategy.size(forElementAt: indexPath.row, context: context)
    }

}
