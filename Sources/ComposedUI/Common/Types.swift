import UIKit

/// The method to use when dequeuing a view from a UICollectionView
///
/// - nib: Load from a XIB
/// - `class`: Load from a class
public enum DequeueMethod<View: UIView> {
    /// Load from a nib
    case nib(View.Type)
    /// Load from a class
    case `class`(View.Type)
    /// Load from a storyboard
    case storyboard(View.Type)
}
