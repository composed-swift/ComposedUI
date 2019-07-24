import UIKit

public extension UICollectionViewFlowLayout {

    func columnWidth(forColumnCount columnCount: Int, inSection section: Int) -> CGFloat {
        guard let collectionView = collectionView else { return 0 }
        guard let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout else { return 0 }

        let insets = delegate.collectionView?(collectionView, layout: self, insetForSectionAt: section)
            ?? sectionInset

        let itemSpacing = delegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: section)
            ?? minimumInteritemSpacing

        let interitemSpacing = CGFloat(columnCount - 1) * itemSpacing
        let availableWiwdth = collectionView.bounds.width - insets.left - insets.right - interitemSpacing

        return (availableWiwdth / CGFloat(columnCount)).rounded(.down)
    }

}
