//
//  NavigationTitleStatusView.swift
//  NavigationTitleStatusView
//
//  Created by Corey Roberts on 7/22/21.
//

import UIKit

public class NavigationTitleStatusView: UIView {
    
    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    var subtitle: String? {
        get { subtitleLabel.text }
        set { subtitleLabel.text = newValue }
    }
    
    private let titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 4.0
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        return stackView
    }()
    
    private let labelStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4.0
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        return stackView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.minimumScaleFactor = 0.25
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    private let menuImageView: UIImageView = {
        let image = UIImage(systemName: "chevron.down")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.font = .systemFont(ofSize: 12.0)
        return label
    }()
    
    public func setSubtitle(_ subtitle: String?, animated: Bool = true, hideAfter: TimeInterval = 5.0) {
        
        self.subtitle = subtitle
        
        guard subtitle != nil else {
            animate(hideSubtitle: true)
            return
        }
        
        let animation = CATransition()
        animation.duration = 0.3
        animation.type = .push
        animation.subtype = .fromTop
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        subtitleLabel.layer.add(animation, forKey: "updateTitle")
        subtitleLabel.isHidden = false
    }
    
    private func animate(hideSubtitle: Bool) {
        
        guard subtitleLabel.isHidden != hideSubtitle else { return }
        
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 1,
                       options: [],
                       animations: {
                        self.subtitleLabel.isHidden = hideSubtitle
                        self.layoutIfNeeded()
                       },
                       completion: nil)
    }
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Configuration Methods
    
    private func setup() {

        backgroundColor = .systemBlue
        clipsToBounds = true
        
        addSubview(labelStackView)
        
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(menuImageView)
        labelStackView.addArrangedSubview(titleStackView)
        labelStackView.addArrangedSubview(subtitleLabel)

        titleStackView.backgroundColor = .systemGray
        menuImageView.backgroundColor = .green
        subtitleLabel.backgroundColor = .systemOrange
        
        NSLayoutConstraint.activate([
            labelStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            labelStackView.topAnchor.constraint(equalTo: topAnchor),
            labelStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }

    // MARK: - Title Update Methods
    
    func update(subtitle: String, duration: TimeInterval) {
        self.subtitle = subtitle
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.subtitle = nil
        }
    }
    
}
