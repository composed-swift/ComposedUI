import UIKit
import Composed

open class CollectionCoordinator: NSObject, UICollectionViewDataSource, SectionProviderMappingDelegate {

    private let mapper: SectionProviderMapping
    private let collectionView: UICollectionView

    public var sections: [Section] {
        return mapper.provider.sections
    }

    public init(collectionView: UICollectionView, sectionProvider: SectionProvider) {
        self.collectionView = collectionView
        mapper = SectionProviderMapping(provider: sectionProvider)

        super.init()

        collectionView.dataSource = self
        collectionView.delegate = self
    }

    // MARK: - SectionProviderMappingDelegate

    public func mappingsDidUpdate(_ mapping: SectionProviderMapping) {
        collectionView.reloadData()
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertSections sections: IndexSet) {
        collectionView.insertSections(sections)
    }

    public func mapping(_ mapping: SectionProviderMapping, didInsertElementsAt indexPaths: [IndexPath]) {
        collectionView.insertItems(at: indexPaths)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveSections sections: IndexSet) {
        collectionView.deleteSections(sections)
    }

    public func mapping(_ mapping: SectionProviderMapping, didRemoveElementsAt indexPaths: [IndexPath]) {
        collectionView.deleteItems(at: indexPaths)
    }

    public func mapping(_ mapping: SectionProviderMapping, didUpdateSections sections: IndexSet) {
        collectionView.reloadSections(sections)
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
        guard let configuration = collectionSection(for: indexPath.section) else {
            fatalError("No UI configuration available for section \(indexPath.section)")
        }

        let type = configuration.prototypeType
        switch configuration.dequeueMethod {
        case .nib:
            let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
            collectionView.register(nib, forCellWithReuseIdentifier: configuration.reuseIdentifier)
        case .class:
            collectionView.register(type, forCellWithReuseIdentifier: configuration.reuseIdentifier)
        case .storyboard:
            break
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: configuration.reuseIdentifier, for: indexPath)
        configuration.configure(cell: cell, at: indexPath.row, context: .presentation)
        return cell
    }

    private func collectionSection(for section: Int) -> CollectionProvider? {
        guard mapper.provider.sections.indices.contains(section) else { return nil }
        let env = Environment(bounds: collectionView.bounds, traitCollection: collectionView.traitCollection)
        return (mapper.provider.sections[section] as? CollectionSectionProvider)?.section(with: env)
    }

}

extension CollectionCoordinator: UICollectionViewDelegateFlowLayout {

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let configuration = collectionSection(for: section) as? CollectionSectionFlowLayout,
            let strategy = configuration.sizingStrategy as? CollectionSizingStrategyFlowLayout else {
            return (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
        }
        
        return strategy.metrics.sectionInsets
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let configuration = collectionSection(for: section) as? CollectionSectionFlowLayout,
            let strategy = configuration.sizingStrategy as? CollectionSizingStrategyFlowLayout else {
                return (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? 0
        }

        return strategy.metrics.minimumInteritemSpacing
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let configuration = collectionSection(for: section) as? CollectionSectionFlowLayout,
            let strategy = configuration.sizingStrategy as? CollectionSizingStrategyFlowLayout else {
                return (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing ?? 0
        }

        return strategy.metrics.minimumLineSpacing
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }

        guard let configuration = collectionSection(for: indexPath.section), let cell = configuration.prototype else {
            // if the configuration doesn't provide a prototype, we can't auto-size so we fall back to the layout size
            return layout.itemSize
        }

        configuration.configure(cell: cell, at: indexPath.row, context: .presentation)
        
        let context = CollectionSizingContext(index: indexPath.row, layoutSize: collectionView.bounds.size, prototype: cell)
        return configuration.sizingStrategy.size(forElementAt: indexPath.row, context: context)
    }

}
