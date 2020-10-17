//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class ClipInformationViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: ClipInformationPresenter
    private let transitioningController: ClipInformationTransitioningControllerProtocol
    private lazy var alertContainer = TextEditAlert(
        configuration: .init(title: L10n.tagListViewAlertForAddTitle,
                             message: L10n.tagListViewAlertForAddMessage,
                             placeholder: L10n.tagListViewAlertForAddPlaceholder)
    )

    private weak var dataSource: ClipInformationViewDataSource?
    private var shouldHideStatusBar: Bool = false

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var panGestureRecognizer: UIPanGestureRecognizer!

    override var prefersStatusBarHidden: Bool {
        return self.shouldHideStatusBar
    }

    @IBOutlet var informationView: ClipInformationView!

    // MARK: - Lifecycle

    init(factory: Factory,
         dataSource: ClipInformationViewDataSource,
         presenter: ClipInformationPresenter,
         transitioningController: ClipInformationTransitioningControllerProtocol)
    {
        self.factory = factory
        self.presenter = presenter
        self.transitioningController = transitioningController
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)

        self.presenter.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupAppearance()
        self.setupGestureRecognizer()

        self.informationView.delegate = self
        self.informationView.dataSource = self.dataSource

        self.presenter.setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.shouldHideStatusBar = true
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.shouldHideStatusBar = false
        self.setNeedsStatusBarAppearanceUpdate()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.modalTransitionStyle = .crossDissolve
    }

    // MARK: Gesture Recognizer

    private func setupGestureRecognizer() {
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.didPan(_:)))
        self.panGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(self.panGestureRecognizer)
    }

    @objc
    func didPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            self.informationView.isScrollEnabled = false
            self.transitioningController.beginTransition(.custom(interactive: true))
            self.dismiss(animated: true, completion: nil)

        case .ended:
            self.informationView.isScrollEnabled = true
            if self.transitioningController.isInteractive {
                self.transitioningController.didPanForDismissal(sender: sender)
            }

        default:
            if self.transitioningController.isInteractive {
                self.transitioningController.didPanForDismissal(sender: sender)
            }
        }
    }
}

extension ClipInformationViewController: ClipInformationViewProtocol {
    // MARK: - ClipInformationViewProtocol

    func reload() {
        guard let item = self.presenter.clip.items.first(where: { $0.identity == self.presenter.itemId }) else {
            return
        }
        self.informationView.info = .init(clip: self.presenter.clip, item: item)
    }

    func close() {
        self.dismiss(animated: true, completion: nil)
    }

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension ClipInformationViewController: ClipInformationViewDelegate {
    // MARK: - ClipInformationViewDelegate

    func didTapAddTagButton(_ view: ClipInformationView) {
        let tags = self.presenter.clip.tags.map { $0.identity }
        let nullableViewController = self.factory.makeTagSelectionViewController(selectedTags: tags, context: nil, delegate: self)
        guard let viewController = nullableViewController else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func clipInformationView(_ view: ClipInformationView, didSelectTag tag: Tag) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipInformationViewAlertForDeleteTagMessage,
                                      preferredStyle: .actionSheet)

        let title = L10n.clipInformationViewAlertForDeleteTagAction
        alert.addAction(.init(title: title, style: .destructive, handler: { [weak self] _ in
            self?.presenter.removeTagFromClip(tag)
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }

    func clipInformationView(_ view: ClipInformationView, shouldOpen url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func clipInformationView(_ view: ClipInformationView, shouldCopy url: URL) {
        UIPasteboard.general.string = url.absoluteString
    }
}

extension ClipInformationViewController: TagSelectionPresenterDelegate {
    // MARK: - TagSelectionPresenterDelegate

    func tagSelectionPresenter(_ presenter: TagSelectionPresenter, didSelectTagsHaving tagIds: Set<Tag.Identity>, withContext context: Any?) {
        self.presenter.replaceTagsOfClip(tagIds)
    }
}

extension ClipInformationViewController: UIGestureRecognizerDelegate {
    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer, gestureRecognizer === self.panGestureRecognizer {
            guard gestureRecognizer.velocity(in: self.view).y > 0 else { return false }
            return true
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer == self.informationView.panGestureRecognizer {
            return self.informationView.contentOffSet.y <= 0
        }
        return false
    }
}

extension ClipInformationViewController: ClipInformationPresentedAnimatorDataSource {
    // MARK: - ClipInformationPresentedAnimatorDataSource

    func animatingInformationView(_ animator: ClipInformationAnimator) -> ClipInformationView? {
        return self.informationView
    }

    func clipInformationAnimator(_ animator: ClipInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect {
        // HACK: Update safeAreaInsets immediately.
        containerView.layoutIfNeeded()
        return self.informationView.convert(self.informationView.calcInitialFrame(), to: containerView)
    }
}
