import UIKit

open class ComposedStackView: UIScrollView {

    internal let stackView = UIStackView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        prepare()
    }

    private func prepare() {
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(scrollView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([

        ])
    }

}
