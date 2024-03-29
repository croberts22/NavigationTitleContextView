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
        get { navigationTitleButton.title }
        set { navigationTitleButton.title = newValue }
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

    public var titleFont: UIFont {
        get { navigationTitleButton.font }
        set { navigationTitleButton.font = newValue }
    }

    public var subtitleFont: UIFont {
        get { subtitleLabel.font }
        set { subtitleLabel.font = newValue }
    }

    public var titleColor: UIColor {
        get { navigationTitleButton.color }
        set { navigationTitleButton.color = newValue }
    }

    public var subtitleColor: UIColor {
        get { subtitleLabel.textColor }
        set { subtitleLabel.textColor = newValue }
    }

    /// Determines if the subtitle should be animated. Defaults to `true`.
    public var animateSubtitleUpdates: Bool = true

    /// The length at which the subtitle should remain visible before it disappears. Defaults to `3.0` seconds.
    public var subtitleDisplayDuration: TimeInterval = 3.0

    /// The animation duration for animating the subtitle. Defaults to `0.25` seconds.
    public var animationDuration: TimeInterval = 0.25

    /// The animation curve for animating the subtitle. Defaults to `.easeInOut`.
    public var animationCurve: UIView.AnimationCurve = .easeInOut

    /// An image that is displayed to the trailing edge of the navigation title in order to denote a tappable action.
    /// Defaults to using the `chevron.down` system image.
    public var contextMenuImage: UIImage? = UIImage(systemName: "chevron.down")?.withRenderingMode(.alwaysTemplate)

    override public var alpha: CGFloat {
        didSet {
            print("** did set \(alpha)")
        }
    }

    /// A menu interaction that can be attached to the context menu.
    public var contextMenuInteraction: UIContextMenuInteraction? {
        didSet {
            guard let contextMenuInteraction = contextMenuInteraction else { return }
            navigationTitleButton.addInteraction(contextMenuInteraction)
        }
    }

    /// A context menu that can be attached to this view.
    public var contextMenu: UIMenu? {
        didSet {
            if !navigationTitleButton.interactions.isEmpty {
                navigationTitleButton.interactions.forEach {
                    navigationTitleButton.removeInteraction($0)
                }
            }

            let contextMenuInteraction = UIContextMenuInteraction(delegate: navigationTitleButton)

            let configuration = UIContextMenuConfiguration(actionProvider: { [weak self] _ in
                self?.contextMenu
            })

            navigationTitleButton.showsMenuAsPrimaryAction = true
            navigationTitleButton.isUserInteractionEnabled = true
            navigationTitleButton.addInteraction(contextMenuInteraction)
            navigationTitleButton.contextMenuConfiguration = configuration
            navigationTitleButton.isContextMenuInteractionEnabled = true
        }
    }

    /// Determines if the context menu image should be visible. Defaults to `false`.
    public lazy var shouldShowContextMenu: Bool = false {
        didSet {
            let image = shouldShowContextMenu ? contextMenuImage : nil
            navigationTitleButton.configure(icon: image)
            navigationTitleButton.isUserInteractionEnabled = shouldShowContextMenu
        }
    }

    /// A publisher that emits user interaction updates, particularly when the user taps on the context menu.
    /// This publisher emits no events if `shouldShowContextMenu` is `false`.
    public lazy var userInteractionPublisher: AnyPublisher<Void, Never> = userInteractionSubject
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()

    /// A subject that sends user interaction trigger updates.
    private var userInteractionSubject = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()

    private var isCurrentlyDisplayingMessage = false
    private var messageQueue = [Message]()

    private let lock = NSRecursiveLock()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0.0
        stackView.distribution = .fill
        stackView.alignment = .center
        return stackView
    }()

    private lazy var navigationTitleButton: DropdownButton = {
        let button = DropdownButton()
        button.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
        return button
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.alpha = 0.0
        label.isHidden = true
        label.numberOfLines = 1
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.allowsDefaultTighteningForTruncation = true
        label.adjustsFontSizeToFitWidth = true
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

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        addSubview(stackView)

        navigationTitleButton.translatesAutoresizingMaskIntoConstraints = false
        navigationTitleButton.setContentHuggingPriority(.required, for: .horizontal)
        navigationTitleButton.configure(icon: nil)
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

    override public func tintColorDidChange() {
        super.tintColorDidChange()
        stackView.tintColor = tintColor
        navigationTitleButton.tintColor = tintColor
        subtitleLabel.textColor = tintColor
    }

    // MARK: - Public Methods

    /// Sets a subtitle to display and hide after a given duration.
    /// - Parameters:
    ///   - payload: The message payload.
    ///   - generateFeedback: A boolean that determines whether haptic feedback should be generated. Defaults to `true`.
    ///   - duration: The length at which the subtitle should be displayed. Defaults to `5.0`.
    ///   - clearQueueOnSet: Determines if this message should clear the queue and immediately show this message. Defaults to `false`.
    public func setSubtitle(_ payload: MessagePayload?, generateFeedback: Bool = true, hideAfter duration: TimeInterval = 5.0, clearQueueOnSet: Bool = false) {
        lock.lock()

        guard let payload = payload else {
            subtitle = nil
            return
        }

        let message = Message(payload: payload,
                              shouldGenerateFeedback: generateFeedback,
                              duration: duration)

        // Reset everything.
        if clearQueueOnSet {
            messageQueue.removeAll()
            isCurrentlyDisplayingMessage = false
        }

        messageQueue.append(message)

        if !isCurrentlyDisplayingMessage {
            displayNextMessage()
        }

        lock.unlock()
    }

    // MARK: - Private Methods

    private func displayNextMessage() {
        lock.lock()

        guard !messageQueue.isEmpty else { return }

        isCurrentlyDisplayingMessage = true
        let message = messageQueue.removeFirst()
        os_log(.debug, "Displaying message: \(message.payload.message)")

        animateSubtitleUpdates = false
        subtitle = message.payload.message
        animateSubtitleUpdates = true
        performAnimation(hideAfter: message.duration)

        if message.shouldGenerateFeedback, let feedbackType = message.payload.feedbackType {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.notificationOccurred(feedbackType)
        }

        lock.unlock()
    }

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

                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                    self.isCurrentlyDisplayingMessage = false
                    self.displayNextMessage()
                }
            }
        }
    }

    // MARK: - User Interaction Methods

    @objc private func menuTapped() {
        userInteractionSubject.send()
    }
}
