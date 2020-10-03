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
    private let transitionController: ClipInformationTransitioningController

    private weak var dataSource: ClipInformationViewDataSource?

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var panGestureRecognizer: UIPanGestureRecognizer!

    @IBOutlet var informationView: ClipInformationView!

    // MARK: - Lifecycle

    init(factory: Factory, dataSource: ClipInformationViewDataSource, presenter: ClipInformationPresenter, transitionController: ClipInformationTransitioningController) {
        self.factory = factory
        self.presenter = presenter
        self.transitionController = transitionController
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupGestureRecognizer()

        self.informationView.delegate = self
        self.informationView.dataSource = self.dataSource
        self.informationView.info = .init(clip: self.presenter.clip, item: self.presenter.item)
    }

    // MARK: - Methods

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
            self.transitionController.beginInteractiveTransition(.dismiss)
            self.dismiss(animated: true, completion: nil)

        case .ended:
            self.informationView.isScrollEnabled = true
            if self.transitionController.isInteractiveTransitioning {
                self.transitionController.endInteractiveTransition()
                self.transitionController.didPan(sender: sender)
            }

        default:
            if self.transitionController.isInteractiveTransitioning {
                self.transitionController.didPan(sender: sender)
            }
        }
    }
}

extension ClipInformationViewController: ClipInformationViewProtocol {
    // MARK: - ClipInformationViewProtocol
}

extension ClipInformationViewController: ClipInformationViewDelegate {
    // MARK: - ClipInformationViewDelegate

    func clipInformationView(_ view: ClipInformationView, didSelectTag name: String) {
        // TODO:
        print(name)
    }

    func clipInformationView(_ view: ClipInformationView, shouldOpen url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func clipInformationView(_ view: ClipInformationView, shouldCopy url: URL) {
        UIPasteboard.general.string = url.absoluteString
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
