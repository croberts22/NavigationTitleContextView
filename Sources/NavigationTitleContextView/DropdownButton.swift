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

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
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
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Setup Methods

    private func setup() {
        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: iconImageView.leadingAnchor),
            iconImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            iconImageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            iconImageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
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
