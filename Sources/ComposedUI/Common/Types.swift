import UIKit

/// The method to use when dequeuing a view from a UICollectionView
///
/// - nib: Load from a XIB
/// - `class`: Load from a class
public enum DequeueMethod<View: UIView> {
    /// Load from a nib
    case fromNib(View.Type)
    // Load from a class
    case fromClass(View.Type)
    /// Load from a storyboard
    case fromStoryboard(View.Type)
}
