import UIKit

/// A stack view that supports animating showing/hiding arranged subviews,
/// and has the option of dynamically creating separators when arranged subviews are added.
open class ComposedStackView: UIStackView {

    /// Types of animations that are applied to the stack view.
    ///
    /// - fade: Animate opacity.
    /// - hidden: Animate the isHidden property.
    enum AnimationType {
        case fade, hidden
    }

    public enum Animation {
        case slide
        case fade
        case none
    }

    /// The style of the stack view.
    public var animationDuration: TimeInterval = 0.2

    // MARK: Life Cycle

    /// Create the stack view with a style. A plain style is a typical stack view. A separated
    /// style will automatically create separators between arranged subviews whenever they're
    /// added.
    ///
    /// - Parameter style: The style for the stack view.
    public init() {
        super.init(frame: .zero)
        axis = .vertical
        preservesSuperviewLayoutMargins = true
    }

    public required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: Methods

    /// Add a subview to the end of the stack view. If the style is separated,
    /// separators will automatically be added. Provides the option to animate
    /// showing the new view.
    ///
    /// - Parameters:
    ///   - view: The view to add.
    ///   - animated: Flag that determines if the view should animated on screen.
    open func addArrangedSubview(_ view: UIView, with animation: Animation) {
        insertArrangedSubview(view, at: arrangedSubviews.count, with: animation)
    }

    /// Insert an arranged subview at a particular index in the stack view. If the style is
    /// separated, separators will be automatically added.  Provides the option to animate
    /// showing the new view.
    ///
    /// - Parameters:
    ///   - view: The view to add.
    ///   - stackIndex: Index in the stack view to add the view.
    ///   - animated: Flag that determines if the view should animated on screen.
    open func insertArrangedSubview(_ view: UIView, at stackIndex: Int, with animation: Animation) {
        guard animation != .none else {
            insertArrangedSubview(view, at: stackIndex)
            return
        }

        view.isHidden = true
        view.alpha = animation == .fade ? 0 : 1
        super.insertArrangedSubview(view, at: stackIndex)
        toggleViews([view], shouldShow: true, animation: animation)
    }

    /// Remove an arranged subview from the stack view. If the style is separated,
    /// the separators will be automatically removed. Option to animated the removal of the
    /// view.
    ///
    /// - Parameters:
    ///     - view: The view to remove.
    ///     - animated: Flag that determines if the view removal should be animated.
    open func removeArrangedSubview(_ view: UIView, with animation: Animation) {
        let viewsToRemove = [view]

        let removeBlock = {
            viewsToRemove.forEach {
                $0.removeFromSuperview()
                $0.isHidden = false
                $0.alpha = 1
            }
        }

        guard UIView.areAnimationsEnabled && animation != .none else {
            removeBlock()
            return
        }

        toggleViews(viewsToRemove, shouldShow: false, animation: animation) { complete in
            guard complete else { return }
            removeBlock()
        }
    }

    open func removeArrangedSubvew(at stackIndex: Int, with animation: Animation) {
        guard arrangedSubviews.indices.contains(stackIndex) else { return }
        removeArrangedSubview(arrangedSubviews[stackIndex], with: animation)
    }

    /// Clear the views in the stack view.
    ///
    /// - Parameter animated: Flag to animate the removal of the views.
    private func clear(animation: Animation) {
        let removeViewsBlock = { [weak self] in
            self?.subviews.forEach { $0.removeFromSuperview() }
        }

        guard UIView.areAnimationsEnabled && animation != .none else {
            removeViewsBlock()
            return
        }

        toggleViews(subviews, shouldShow: false, animation: animation) { complete in
            guard complete else { return }
            removeViewsBlock()
        }
    }

    /// Hide or show the specified views in the stack view.
    ///
    /// - Parameters:
    ///   - views: The views to hide or show.
    ///   - shouldShow: True if the views should be shown, false to hide them.
    ///   - animated: Animate the visibility of the views.
    ///   - animations: The particular animations to use when toggling the visibility.
    ///   - completion: Block to run when the visibility toggling and any animations are complete.
    private func toggleViews(
        _ views: [UIView],
        shouldShow: Bool,
        animation: Animation = .slide,
        completion: ((Bool) -> Void)? = nil) {
        views.forEach { guard $0.superview == self else { return } }

        let animations: [AnimationType]

        switch animation {
        case .fade: animations = [.fade, .hidden]
        case .slide: animations = [.hidden]
        case .none: animations = []
        }

        // skip animation
        guard animation != .none else {
            views.forEach { $0.isHidden = !shouldShow }
            return
        }

        var completionWillBeCalled = false
        let options: UIView.AnimationOptions = shouldShow
            ? [.curveEaseOut, .allowUserInteraction]
            : [.curveEaseOut]

        if animations.contains(.hidden) {
            let filteredViews = views.filter { $0.isHidden == shouldShow } // only animated views that are not yet animated
            filteredViews.forEach { $0.isHidden = shouldShow }

            UIView.animate(withDuration: animationDuration, delay: 0, options: options, animations: {
                filteredViews.forEach { $0.isHidden = !shouldShow }
            }, completion: { complete in
                if !completionWillBeCalled { completion?(complete) }
                completionWillBeCalled = true
            })
        }

        if animations.contains(.fade) {
            let filteredViews = views.filter { $0.alpha == (shouldShow ? 0 : 1) } // only animated views that are not yet animated
            filteredViews.forEach { $0.alpha = shouldShow ? 0 : 1 }

            UIView.animate(withDuration: animationDuration, delay: 0, options: options, animations: {
                filteredViews.forEach { $0.alpha = shouldShow ? 1 : 0 }
            }, completion: { complete in
                if !completionWillBeCalled { completion?(complete) }
                completionWillBeCalled = true
            })
        }
    }
}
