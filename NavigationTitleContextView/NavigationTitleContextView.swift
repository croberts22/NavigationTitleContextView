//
//  NavigationTitleContextView.swift
//  NavigationTitleContextView
//
//  Created by Corey Roberts on 7/22/21.
//

import Combine
import UIKit

public class NavigationTitleContextView: UIView {

    // MARK: - Properties

    /// The title of the view.
    public var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    /// The subtitle of the view. Depending on the properties set on this view,
    /// the subtitle updates will animate in for a select duration of time.
    public var subtitle: String? {
        get { subtitleLabel.text }
        set {
            subtitleLabel.text = newValue

            if animateSubtitleUpdates {
                performAnimation(hideAfter: subtitleDisplayDuration)
            }
        }
    }

    /// Determines if the subtitle should be animated. Defaults to `true`.
    public var animateSubtitleUpdates: Bool = true

    /// The length at which the subtitle should remain visible before it disappears. Defaults to `3.0` seconds.
    public var subtitleDisplayDuration: TimeInterval = 3.0

    /// The animation duration for animating the subtitle. Defaults to `0.3` seconds.
    public var animationDuration: TimeInterval = 0.3

    /// The animation curve for animating the subtitle. Defaults to `.easeInOut`.
    public var animationCurve: UIView.AnimationCurve = .easeInOut

    /// An image that is displayed to the trailing edge of the navigation title in order to denote a tappable action.
    public var contextMenuImage: UIImage? = UIImage(systemName: "chevron.down")

    /// Determines if the context menu image should be visible. Defaults to `true`.
    public lazy var shouldShowContextMenu: Bool = true {
        didSet {
            menuButton.isHidden = !shouldShowContextMenu
        }
    }

    public lazy var userInteractionPublisher: AnyPublisher<Void, Never> = {
        userInteractionSubject.eraseToAnyPublisher()
    }()

    private var userInteractionSubject = PassthroughSubject<Void, Never>()

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

    private let menuButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.required, for: .horizontal)

        let image = UIImage(systemName: "chevron.down")
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
        return button
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

    private lazy var displayAnimator = UIViewPropertyAnimator(duration: subtitleDisplayDuration,
                                                              curve: animationCurve,
                                                              animations: nil)

    private lazy var hideAnimator = UIViewPropertyAnimator(duration: subtitleDisplayDuration,
                                                           curve: animationCurve,
                                                           animations: nil)

    private func performAnimation(hideAfter duration: TimeInterval) {
        subtitle == nil ? hideSubtitle() : displaySubtitle(hideAfter: duration)
    }

    private func displaySubtitle(hideAfter duration: TimeInterval? = nil) {

        let displayDuration = duration ?? subtitleDisplayDuration

        print("Displaying subtitle for \(displayDuration) seconds...")

        // If the hiding animator is queued up, let's stop it and re-queue it.
        // This implies that there is already text we're displaying. In this case,
        // we simply just replace the copy and reset the animation timer.
        if hideAnimator.isRunning {
            hideAnimator.stopAnimation(false)
            hideAnimator.finishAnimation(at: .start)
        }

        subtitleLabel.isHidden = false

        prepareDisplayAnimator()
        prepareHideAnimator()

        displayAnimator.addCompletion { [weak self] _ in
            guard let self = self else { return }
            self.hideAnimator.startAnimation(afterDelay: displayDuration)
        }

        displayAnimator.startAnimation()
    }

    private func hideSubtitle() {
        prepareHideAnimator()
        hideAnimator.startAnimation()
    }

    private func resetAnimators() {
        let runningAnimators = [displayAnimator, hideAnimator].filter(\.isRunning)
        runningAnimators.forEach { animator in
            print("Animation is running currently, forcing it to end!")
            animator.stopAnimation(false)
            animator.finishAnimation(at: .end)
        }
    }

    public func setSubtitle(_ subtitle: String?, animated _: Bool = true, hideAfter duration: TimeInterval = 5.0) {
        self.subtitle = subtitle
        performAnimation(hideAfter: duration)
    }

    private func animator(with animations: (() -> Void)?) -> UIViewPropertyAnimator {
        UIViewPropertyAnimator(duration: animateSubtitleUpdates ? animationDuration : 0.00001,
                               curve: .easeInOut,
                               animations: animations)
    }

    private func prepareDisplayAnimator() {
        resetAnimators()
        displayAnimator = animator { [weak self] in
            guard let self = self else { return }
            print("Queuing displaying subtitle animation.")
            self.subtitleLabel.isHidden = false
            self.subtitleLabel.alpha = 1.0
            self.layoutIfNeeded()
        }
    }

    private func prepareHideAnimator() {
        resetAnimators()
        hideAnimator = animator { [weak self] in
            guard let self = self else { return }
            print("Queuing hiding subtitle animation.")
            self.subtitleLabel.alpha = 0.0
            self.subtitleLabel.isHidden = true
            self.layoutIfNeeded()
        }
    }

    // MARK: - User Interaction Methods

    @objc private func menuTapped() {
        userInteractionSubject.send()
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

        clipsToBounds = true

        addSubview(labelStackView)

        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(menuButton)
        labelStackView.addArrangedSubview(titleStackView)
        labelStackView.addArrangedSubview(subtitleLabel)

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
