import UIKit

/// The method to use when dequeuing a view from a UICollectionView or UITableView
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

extension DequeueMethod where View: UICollectionReusableView {
    public func map() -> DequeueMethod<UICollectionReusableView> {
        switch self {
        case let .fromClass(type):
            return .fromClass(type)
        case let .fromNib(type):
            return .fromNib(type)
        case let .fromStoryboard(type):
            return .fromStoryboard(type)
        }
    }
}

extension DequeueMethod where View: UICollectionViewCell {
    public func map() -> DequeueMethod<UICollectionViewCell> {
        switch self {
        case let .fromClass(type):
            return .fromClass(type)
        case let .fromNib(type):
            return .fromNib(type)
        case let .fromStoryboard(type):
            return .fromStoryboard(type)
        }
    }
}

extension DequeueMethod where View: UITableViewCell {
    public func map() -> DequeueMethod<UITableViewCell> {
        switch self {
        case let .fromClass(type):
            return .fromClass(type)
        case let .fromNib(type):
            return .fromNib(type)
        case let .fromStoryboard(type):
            return .fromStoryboard(type)
        }
    }
}

extension DequeueMethod where View: UITableViewHeaderFooterView {
    public func map() -> DequeueMethod<UITableViewHeaderFooterView> {
        switch self {
        case let .fromClass(type):
            return .fromClass(type)
        case let .fromNib(type):
            return .fromNib(type)
        case let .fromStoryboard(type):
            return .fromStoryboard(type)
        }
    }
}
