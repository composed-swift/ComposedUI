import UIKit

open class ComposedView: UIView {

    open override var backgroundColor: UIColor? {
        didSet {
            contentView.backgroundColor = backgroundColor
            scrollView.backgroundColor = backgroundColor
        }
    }

    private let stackView = ComposedStackView()
    private let scrollView = UIScrollView()
    private let contentView = ComposedContentView()

    @IBInspectable
    open var interSectionSpacing: CGFloat = 20 {
        didSet { stackView.spacing = interSectionSpacing }
    }

    open var contentInsets: UIEdgeInsets = .zero {
        didSet { scrollView.contentInset = contentInsets }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        prepare()
    }

    private func prepare() {
        scrollView.alwaysBounceVertical = true

        if backgroundColor == nil {
            if #available(iOS 13.0, *) {
                backgroundColor = .systemBackground
            } else {
                backgroundColor = .white
            }
        }

        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = interSectionSpacing

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        [scrollView, contentView, stackView].forEach { $0?.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    open var sections: [ComposedSectionView] {
        return stackView.arrangedSubviews.compactMap { $0 as? ComposedSectionView }
    }

    public func appendSection(_ section: ComposedSectionView, with animation: ComposedStackView.Animation = .fade) {
        insertSection(section, at: stackView.arrangedSubviews.count, with: animation)
    }

    public func insertSection(_ section: ComposedSectionView, at index: Int, with animation: ComposedStackView.Animation = .fade) {
        stackView.insertArrangedSubview(section, at: index, with: animation)
    }

    public func removeSection(_ section: ComposedSectionView, animation: ComposedStackView.Animation = .fade) {
        guard let index = stackView.arrangedSubviews.firstIndex(of: section) else { return }
        removeSection(at: index, animation: animation)
    }

    public func removeSection(at index: Int, animation: ComposedStackView.Animation = .fade) {
        guard stackView.arrangedSubviews.indices.contains(index) else { return }
        stackView.removeArrangedSubview(stackView.arrangedSubviews[index], with: animation)
    }

    public func removeAllSections() {
        fatalError("Unimplemented")
    }

}

private final class ComposedContentView: UIView { }
