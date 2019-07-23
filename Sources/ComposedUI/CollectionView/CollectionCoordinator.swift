import UIKit
import Composed

public final class CollectionCoordinator: NSObject, UICollectionViewDataSource, SectionProviderMappingDelegate {

    private let mapper: SectionProviderMapping
    private let collectionView: UICollectionView

    public init(collectionView: UICollectionView, sectionProvider: SectionProvider) {
        self.collectionView = collectionView
        mapper = SectionProviderMapping(provider: sectionProvider)

        super.init()

        collectionView.dataSource = self
    }

    // MARK: - SectionProviderMappingDelegate

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
        return sectionInfo(for: section)?.numberOfElements ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let configuration = sectionInfo(for: indexPath.section) else {
            fatalError("No UI configuration available for section \(indexPath.section)")
        }

        let type = Swift.type(of: configuration.prototype)
        switch configuration.dequeueMethod {
        case .nib:
            let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
            collectionView.register(nib, forCellWithReuseIdentifier: configuration.reuseIdentifier)
        case .class:
            collectionView.register(type, forCellWithReuseIdentifier: configuration.reuseIdentifier)
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: configuration.reuseIdentifier, for: indexPath)
        configuration.configure(cell: cell, at: indexPath.row)
        return cell
    }

    private func sectionInfo(for section: Int) -> CollectionProvider? {
        return (mapper.provider.sections[section] as? CollectionSectionProvider)?.collectionSection
    }

}
