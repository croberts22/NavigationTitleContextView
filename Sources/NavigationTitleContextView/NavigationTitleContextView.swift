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
        get { navigationTitleButton.title(for: .normal) }
        set { navigationTitleButton.setTitle(newValue, for: .normal) }
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

    /// Determines if the context menu image should be visible. Defaults to `false`.
    public lazy var shouldShowContextMenu: Bool = false {
        didSet {
            let image = shouldShowContextMenu ? contextMenuImage : nil
            navigationTitleButton.setImage(image, for: .normal)
            navigationTitleButton.isUserInteractionEnabled = shouldShowContextMenu
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
    
    private var cancellables = Set<AnyCancellable>()

    private let lock = NSRecursiveLock()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0.0
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        return stackView
    }()

    private let navigationTitleButton: UIButton = {
        let button = UIButton(type: .system)
        button.semanticContentAttribute = .forceRightToLeft
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        button.titleLabel?.font = .boldSystemFont(ofSize: button.titleLabel?.font.pointSize ?? 14.0)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
        button.imageEdgeInsets = .init(top: 6.0, left: 4.0, bottom: 6.0, right: 6.0)
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
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
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

        addSubview(stackView)

        stackView.addArrangedSubview(navigationTitleButton)
        stackView.addArrangedSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        setupObservers()
        updateOrientation(using: UIDevice.current)
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { $0.object as? UIDevice }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] device in
                self?.updateOrientation(using: device)
            }
            .store(in: &cancellables)
    }
    
    private func updateOrientation(using device: UIDevice) {
        
        var spacing: CGFloat = 0.0
        var axis: NSLayoutConstraint.Axis = .vertical
        
        // If we're dealing with regular sized devices, keep the spacing/axis the same.
        guard traitCollection.horizontalSizeClass == .compact else {
            return
        }
        
        switch device.orientation {
        case .landscapeLeft, .landscapeRight:
            axis = .horizontal
            spacing = 12.0
        case .portrait, .portraitUpsideDown:
            break
        case .faceUp, .faceDown:
            break
        case .unknown:
            break
        @unknown default:
            break
        }
        
        stackView.axis = axis
        stackView.spacing = spacing
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
        
        // Sometimes, setting up the spacing for this stack view prior to the
        // context view getting added to the view hierarchy can nullify updates
        // and simply set the spacing to 0.
        if stackView.spacing.isZero {
            updateOrientation(using: UIDevice.current)
        }

        let displayDuration = duration ?? subtitleDisplayDuration

        if #available(iOS 14.0, *) {
            os_log(.debug, "Displaying subtitle for \(displayDuration) seconds...")
        }

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
        if #available(iOS 14.0, *) {
            os_log(.debug, "\(animator.description) is running currently, forcing it to end!")
        }
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
