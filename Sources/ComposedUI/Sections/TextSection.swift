import UIKit
import Composed

open class TextSection: SingleElementSection<String>, CollectionSectionProvider {

    public let configurationBlock: ((UILabel) -> Void)?

    public init(text: String, configurationBlock: ((UILabel) -> Void)? = nil) {
        self.configurationBlock = configurationBlock
        super.init(element: text)
    }

    public func section(with traitCollection: UITraitCollection) -> CollectionSection {
        let cell = CollectionElement(section: self, dequeueMethod: .class(TextCell.self)) { [unowned self] cell, _, section, _ in
            cell.label.text = section.element
            self.configurationBlock?(cell.label)
        }
        return CollectionSection(section: self, cell: cell)
    }

}

private final class TextCell: UICollectionViewCell {

    fileprivate lazy var label = UILabel(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .body)

        if #available(iOS 13.0, *) {
            label.textColor = .label
        }

        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            label.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
