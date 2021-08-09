//
//  NavigationTitleContextView.swift
//  NavigationTitleContextView
//
//  Created by Corey Roberts on 7/22/21.
//

import Combine
import OSLog
import UIKit

/// A view designed to display contextual information within a `UINavigationItem`.
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
    /// Defaults to using the `chevron.down` system image.
    public var contextMenuImage: UIImage? = UIImage(systemName: "chevron.down")?.withRenderingMode(.alwaysTemplate)

    /// Determines if the context menu image should be visible. Defaults to `true`.
    public lazy var shouldShowContextMenu: Bool = true {
        didSet {
            menuButton.isHidden = !shouldShowContextMenu
        }
    }

    /// A publisher that emits user interaction updates, particularly when the user taps on the context menu.
    /// This publisher emits no events if `shouldShowContextMenu` is `false`.
    public lazy var userInteractionPublisher: AnyPublisher<Void, Never> = {
        userInteractionSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }()

    /// A subject that sends user interaction trigger updates.
    private var userInteractionSubject = PassthroughSubject<Void, Never>()

    private let lock = NSRecursiveLock()

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
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.required, for: .horizontal)

        let image = UIImage(systemName: "chevron.down")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
        return button
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alpha = 0.0
        label.isHidden = true
        label.numberOfLines = 1
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.font = .systemFont(ofSize: 12.0)
        return label
    }()

    private var displayAnimator = UIViewPropertyAnimator()
    private var hideAnimator = UIViewPropertyAnimator()

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
        tintColor = .label

        addSubview(labelStackView)

        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(menuButton)
        labelStackView.addArrangedSubview(titleStackView)
        labelStackView.addArrangedSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            menuButton.widthAnchor.constraint(equalToConstant: 10),
            labelStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            labelStackView.topAnchor.constraint(equalTo: topAnchor),
            labelStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }

    // MARK: - Public Methods

    /// Sets a subtitle to display and hide after a given duration.
    /// - Parameters:
    ///   - subtitle: The subtitle.
    ///   - duration: The length at which the subtitle should be displayed. Defaults to `5.0`.
    public func setSubtitle(_ subtitle: String?, hideAfter duration: TimeInterval = 5.0) {
        DispatchQueue.main.async {
            self.lock.lock()
            self.animateSubtitleUpdates = false
            self.subtitle = subtitle
            self.animateSubtitleUpdates = true
            self.performAnimation(hideAfter: duration)
            self.lock.unlock()
        }
    }

    // MARK: - Private Methods

    private func performAnimation(hideAfter duration: TimeInterval) {
        subtitle == nil ? hideSubtitle() : displaySubtitle(hideAfter: duration)
    }

    private func displaySubtitle(hideAfter duration: TimeInterval? = nil) {

        let displayDuration = duration ?? subtitleDisplayDuration

        os_log(.debug, "Displaying subtitle for \(displayDuration) seconds...")

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

    private func reset(animator: UIViewPropertyAnimator) {
        guard animator.isRunning else { return }
        os_log(.debug, "\(animator.description) is running currently, forcing it to end!")
        animator.stopAnimation(true)
        animator.finishAnimation(at: .end)
    }

    /// A convenience method that creates an `UIViewPropertyAnimator`.
    /// - Parameter animations: A closure with animations to perform in this property animator.
    /// - Returns: An `UIViewPropertyAnimator`.
    private func animator(with animations: (() -> Void)?) -> UIViewPropertyAnimator {
        UIViewPropertyAnimator(duration: animateSubtitleUpdates ? animationDuration : 0.00001,
                               curve: .easeInOut,
                               animations: animations)
    }

    private func prepareDisplayAnimator() {
        reset(animator: displayAnimator)
        displayAnimator = animator { [weak self] in
            guard let self = self else { return }
            os_log(.debug, "Queuing displaying subtitle animation.")

            if self.subtitleLabel.isHidden {
                self.subtitleLabel.isHidden = false
                self.layoutIfNeeded()
            }

            self.subtitleLabel.alpha = 1.0
        }

        // TODO: Figure out why this doesn't want to animate in the completion block.
        // For now, just add it into the original animator above.
//        displayAnimator.addCompletion { [weak self] _ in
//            guard let self = self else { return }
//            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: self.animationDuration,
//                                                           delay: 0.0,
//                                                           options: .curveEaseInOut) {
//                self.subtitleLabel.alpha = 1.0
//            }
//        }
    }

    private func prepareHideAnimator() {
        reset(animator: hideAnimator)
        hideAnimator = animator { [weak self] in
            guard let self = self else { return }
            os_log(.debug, "Queuing hiding subtitle animation.")
            self.subtitleLabel.alpha = 0.0
        }

        hideAnimator.addCompletion { [weak self] _ in
            guard let self = self else { return }
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: self.animationDuration,
                                                           delay: 0.0,
                                                           options: .curveEaseInOut) {
                self.subtitleLabel.isHidden = true
            }
        }
    }

    // MARK: - User Interaction Methods

    @objc private func menuTapped() {
        userInteractionSubject.send()
    }
}
