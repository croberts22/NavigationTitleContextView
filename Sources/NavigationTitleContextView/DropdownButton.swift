//
//  DropdownButton.swift
//
//
//  Created by Corey Roberts on 12/20/23.
//

import UIKit

public final class DropdownButton: UIControl {

    public var menu: UIMenu? {
        didSet {
            print("did set")
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

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.minimumScaleFactor = 0.5
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
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
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
    }

    // MARK: - Configuration Methods

    public func configure(title: String?) {
        titleLabel.text = title
    }

    public func configure(icon: UIImage?) {
        iconImageView.image = icon
    }

    public func configure(title: String?, icon: UIImage?) {
        configure(title: title)
        configure(icon: icon)
    }
}
