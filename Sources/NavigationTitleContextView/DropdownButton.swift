//
//  DropdownButton.swift
//
//
//  Created by Corey Roberts on 12/20/23.
//

import UIKit

// MARK: - DropdownButton

public final class DropdownButton: UIControl {

    override public var isHighlighted: Bool {
        didSet {
            print("*** did highlight")
        }
    }

    public var font: UIFont {
        get { titleLabel.font }
        set { titleLabel.font = newValue }
    }

    public var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    public var color: UIColor {
        get { titleLabel.textColor }
        set {
            titleLabel.textColor = newValue
            iconImageView.tintColor = newValue
        }
    }

    public var contextMenuConfiguration: UIContextMenuConfiguration?

    private var iconWidthAnchor: NSLayoutConstraint?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.minimumScaleFactor = 0.5
        label.allowsDefaultTighteningForTruncation = true
        label.adjustsFontSizeToFitWidth = true
        label.font = .boldSystemFont(ofSize: 14.0)
        return label
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override public func tintColorDidChange() {
        super.tintColorDidChange()
        titleLabel.tintColor = tintColor
        iconImageView.tintColor = tintColor
    }

    // MARK: - Setup Methods

    private func setup() {
        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        isUserInteractionEnabled = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        addSubview(titleLabel)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: iconImageView.leadingAnchor),
            iconImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 16.0)
        ])

        iconWidthAnchor = iconImageView.widthAnchor.constraint(equalToConstant: 16.0)
        iconWidthAnchor?.isActive = true
    }

    // MARK: - Configuration Methods

    public func configure(title: String?) {
        titleLabel.text = title
    }

    public func configure(icon: UIImage?) {
        iconImageView.image = icon
        iconWidthAnchor?.constant = icon != nil ? 16.0 : 0.0
        layoutIfNeeded()
    }

    public func configure(title: String?, icon: UIImage?) {
        configure(title: title)
        configure(icon: icon)
    }
}

public extension DropdownButton {
    override func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        contextMenuConfiguration
    }
}
