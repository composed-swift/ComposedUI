import UIKit

open class ComposedViewCell: UIView {

    private(set) lazy var topSeparator: UIView = {
        return SeparatorView()
    }()

    private(set) lazy var bottomSeparator: UIView = {
        return SeparatorView()
    }()

    private var leadingTopSeparatorConstraint: NSLayoutConstraint?
    private var trailingTopSeparatorConstraint: NSLayoutConstraint?

    private var leadingBottomSeparatorConstraint: NSLayoutConstraint?
    private var trailingBottomSeparatorConstraint: NSLayoutConstraint?

    internal var separatorColor: UIColor? {
        didSet { updateSeparators() }
    }

    internal var separatorInsets: UIEdgeInsets = .zero {
        didSet { updateSeparators() }
    }

    public required init() {
        super.init(frame: .zero)
        prepare()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        prepare()
    }

    private func prepare() {
        [topSeparator, bottomSeparator].forEach {
            $0.isHidden = true
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        leadingTopSeparatorConstraint = topSeparator.leadingAnchor.constraint(equalTo: leadingAnchor)
        trailingTopSeparatorConstraint = topSeparator.trailingAnchor.constraint(equalTo: trailingAnchor)
        leadingBottomSeparatorConstraint = bottomSeparator.leadingAnchor.constraint(equalTo: leadingAnchor)
        trailingBottomSeparatorConstraint = bottomSeparator.trailingAnchor.constraint(equalTo: trailingAnchor)

        NSLayoutConstraint.activate([
            topSeparator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            topSeparator.topAnchor.constraint(equalTo: topAnchor),
            leadingTopSeparatorConstraint,
            trailingTopSeparatorConstraint,

            bottomSeparator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            bottomSeparator.bottomAnchor.constraint(equalTo: bottomAnchor),
            leadingBottomSeparatorConstraint,
            trailingBottomSeparatorConstraint,
        ].compactMap { $0 })

        updateSeparators()
    }

    private func updateSeparators() {
        leadingBottomSeparatorConstraint?.constant = separatorInsets.left > 0
            ? safeAreaInsets.left + separatorInsets.left
            : separatorInsets.left
        trailingBottomSeparatorConstraint?.constant = separatorInsets.right

        [topSeparator, bottomSeparator].forEach {
            if #available(iOS 13.0, *) {
                $0.backgroundColor = separatorColor ?? .separator
            } else {
                $0.backgroundColor = separatorColor ?? UIColor(displayP3Red: 60 / 255, green: 60 / 255, blue: 67 / 255, alpha: 0.29)
            }
        }
    }

    open override func addSubview(_ view: UIView) {
        super.addSubview(view)
        bringSubviewToFront(topSeparator)
        bringSubviewToFront(bottomSeparator)
    }

    open override func insertSubview(_ view: UIView, at index: Int) {
        super.insertSubview(view, at: index)
        bringSubviewToFront(topSeparator)
        bringSubviewToFront(bottomSeparator)
    }

    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        updateSeparators()
    }

}

private final class SeparatorView: UIView { }
