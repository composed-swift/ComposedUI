/// The method to use when dequeuing a view from a UICollectionView
///
/// - nib: Load from a XIB
/// - `class`: Load from a class
public enum DequeueMethod {
    /// Load from a nib
    case nib
    /// Load from a class
    case `class`
}
