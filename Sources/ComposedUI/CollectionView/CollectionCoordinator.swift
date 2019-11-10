import UIKit
import Composed

public protocol CollectionCoordinatorDelegate: class {
    func coordinator(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
}

open class CollectionCoordinator: NSObject {

    public weak var delegate: CollectionCoordinatorDelegate?

    public var sectionProvider: SectionProvider {
        return mapper.provider
    }

    private var mapper: SectionProviderMapping
    private let collectionView: UICollectionView

    private weak var originalDelegate: UICollectionViewDelegate?
    private var observer: NSKeyValueObservation?

    private var cachedProviders: [Int: CollectionElementsProvider] = [:]

    public init(collectionView: UICollectionView, sectionProvider: SectionProvider) {
        self.collectionView = collectionView
        mapper = SectionProviderMapping(provider: sectionProvider)
        originalDelegate = collectionView.delegate

        super.init()

        collectionView.dataSource = self

        prepareSections()

        observer = collectionView.observe(\.delegate, options: [.initial, .new]) { [weak self] collectionView, _ in
            guard collectionView.delegate !== self else { return }
            self?.originalDelegate = collectionView.delegate
            collectionView.delegate = self
        }
    }

    open func replace(sectionProvider: SectionProvider) {
        mapper = SectionProviderMapping(provider: sectionProvider)
        prepareSections()
        collectionView.reloadData()
    }

    open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext? = nil) {
        guard collectionView.window != nil else { return }

        collectionView.reloadData()

        if let context = context {
            collectionView.collectionViewLayout.invalidateLayout(with: context)
        } else {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }


    private func prepareSections() {
        cachedProviders.removeAll()
        mapper.delegate = self

        for index in 0..<mapper.numberOfSections {
            guard let section = (mapper.provider.sections[index] as? CollectionSectionProvider)?.section(with: collectionView.traitCollection) else {
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

            [section.header, section.footer].compactMap { $0 }.forEach {
                switch $0.dequeueMethod {
                case let .nib(type):
                    let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                    collectionView.register(nib, forSupplementaryViewOfKind: $0.kind.rawValue, withReuseIdentifier: $0.reuseIdentifier)
                case let .class(type):
                    collectionView.register(type, forSupplementaryViewOfKind: $0.kind.rawValue, withReuseIdentifier: $0.reuseIdentifier)
                case .storyboard:
                    break
                }
            }
        }
    }

}

// MARK: - SectionProviderMappingDelegate

extension CollectionCoordinator: SectionProviderMappingDelegate {

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

}

// MARK: - UICollectionViewDataSource

extension CollectionCoordinator: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return mapper.numberOfSections
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cachedProviders[section]?.numberOfElements ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = cachedProviders[indexPath.section] else {
            fatalError("No UI configuration available for section \(indexPath.section)")
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: section.cell.reuseIdentifier, for: indexPath)
        section.cell.configure(cell, indexPath.row, mapper.provider.sections[indexPath.section])

        return cell
    }

    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let provider = cachedProviders[indexPath.section] else {
            fatalError("No UI configuration available for section \(indexPath.section)")
        }

        let section = mapper.provider.sections[indexPath.section]

        if let header = provider.header, header.kind.rawValue == kind {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: header.reuseIdentifier, for: indexPath)
            header.configure(view, indexPath.section, section)
            return view
        } else if let footer = provider.footer, footer.kind.rawValue == kind {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footer.reuseIdentifier, for: indexPath)
            footer.configure(view, indexPath.section, section)
            return view
        } else {
            guard let view = delegate?.coordinator(collectionView: collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath) else {
                fatalError("Unsupported supplementary kind: \(kind) at indexPath: \(indexPath)")
            }

            return view
        }
    }

}

// MARK: - UICollectionViewDelegate

extension CollectionCoordinator: UICollectionViewDelegate {

    // MARK: - Forwarding

    open override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        if originalDelegate?.responds(to: aSelector) ?? false { return true }
        return false
    }

    open override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if super.responds(to: aSelector) { return self }
        return originalDelegate
    }

}
