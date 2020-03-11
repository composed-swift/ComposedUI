import UIKit

public final class ComposedSectionView: UIView {

    private lazy var stackView = ComposedStackView()

    public var visibleCells: [ComposedViewCell] {
        return stackView.arrangedSubviews
            .compactMap { $0 as? ComposedViewCell }
            .filter { !$0.isHidden }
    }

    public var separatorInsets: UIEdgeInsets = .zero
    public var separatorColor: UIColor?

    public init() {
        super.init(frame: .zero)
        prepare()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func prepare() {
        preservesSuperviewLayoutMargins = true

        stackView.preservesSuperviewLayoutMargins = true
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        super.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public func addItemView(_ view: ComposedViewCell, with animation: ComposedStackView.Animation = .slide) {
        stackView.addArrangedSubview(view, with: animation)
        updateSeparators()
    }

    public func insertItem(_ view: ComposedViewCell, at index: Int, with animation: ComposedStackView.Animation = .slide) {
        stackView.insertArrangedSubview(view, at: index, with: animation)
        updateSeparators()
    }

    public func removeItemView(_ view: ComposedViewCell, with animation: ComposedStackView.Animation = .slide) {
        stackView.removeArrangedSubview(view, with: animation)
        updateSeparators()
    }

    public func deleteItem(at index: Int, with animation: ComposedStackView.Animation = .slide) {
        stackView.removeArrangedSubvew(at: index, with: animation)
        updateSeparators()
    }

    private func updateSeparators() {
        for (index, cell) in visibleCells.enumerated() {
            if index == visibleCells.count - 1 {
                cell.separatorInsets = .zero
            } else {
                cell.separatorInsets = separatorInsets
            }

            cell.separatorColor = separatorColor
            cell.topSeparator.isHidden = index > 0
            cell.bottomSeparator.isHidden = false
        }
    }

}
