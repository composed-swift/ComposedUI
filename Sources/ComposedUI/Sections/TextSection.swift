import UIKit
import Composed

open class TextSection: SingleElementSection<String>, CollectionSectionProvider {

    public let configurationBlock: ((UILabel) -> Void)?
    public let insets: UIEdgeInsets

    public init(text: String, insets: UIEdgeInsets = .zero, configurationBlock: ((UILabel) -> Void)? = nil) {
        self.insets = insets
        self.configurationBlock = configurationBlock
        super.init(element: text)
    }

    open func sizingStrategy(with environment: Environment) -> CollectionSizingStrategy? {
        let metrics = CollectionSectionMetrics(sectionInsets: insets, minimumInteritemSpacing: 0, minimumLineSpacing: 0)
        return ColumnCollectionSizingStrategy(columnCount: 1, sizingMode: .automatic(isUniform: false), metrics: metrics)
    }

    open func section(with environment: Environment) -> CollectionSection {
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
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
