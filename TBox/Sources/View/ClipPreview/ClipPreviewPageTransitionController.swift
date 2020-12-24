//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import TBoxUIKit
import UIKit

protocol ClipInformationViewControllerFactory {
    func make(transitioningController: ClipInformationTransitioningControllerProtocol) -> UIViewController?
}

protocol ClipPreviewPageTransitionControllerType {
    var inputs: ClipPreviewPageTransitionControllerInputs { get }
    var outputs: ClipPreviewPageTransitionControllerOutputs { get }
}

protocol ClipPreviewPageTransitionControllerInputs {
    var isMinimumPreviewZoomScale: CurrentValueSubject<Bool?, Never> { get }
    var previewContentOffset: CurrentValueSubject<CGPoint?, Never> { get }
    var previewPanGestureRecognizer: CurrentValueSubject<UIPanGestureRecognizer?, Never> { get }

    var beginPresentInformation: PassthroughSubject<Void, Never> { get }
    var beginDismissal: PassthroughSubject<Void, Never> { get }
}

protocol ClipPreviewPageTransitionControllerOutputs {
    var isPreviewScrollEnabled: CurrentValueSubject<Bool, Never> { get }
}

class ClipPreviewPageTransitionController: NSObject,
    ClipPreviewPageTransitionControllerType,
    ClipPreviewPageTransitionControllerInputs,
    ClipPreviewPageTransitionControllerOutputs
{
    typealias Factory = ClipInformationViewControllerFactory

    enum TransitionDestination {
        case back
        case information
    }

    // MARK: - Properties

    // MARK: ClipPreviewPageTransitionControllerType

    var inputs: ClipPreviewPageTransitionControllerInputs { self }
    var outputs: ClipPreviewPageTransitionControllerOutputs { self }

    // MARK: ClipPreviewPageTransitionControllerInputs

    let isMinimumPreviewZoomScale: CurrentValueSubject<Bool?, Never> = .init(nil)
    let previewContentOffset: CurrentValueSubject<CGPoint?, Never> = .init(nil)
    let previewPanGestureRecognizer: CurrentValueSubject<UIPanGestureRecognizer?, Never> = .init(nil)

    let beginPresentInformation: PassthroughSubject<Void, Never> = .init()
    let beginDismissal: PassthroughSubject<Void, Never> = .init()

    // MARK: ClipPreviewPageTransitionControllerOutputs

    let isPreviewScrollEnabled: CurrentValueSubject<Bool, Never> = .init(true)

    // MARK: Privates

    private let factory: Factory
    private let baseViewController: UIViewController

    private var panGestureRecognizer: UIPanGestureRecognizer!

    private let previewTransitioningController: ClipPreviewTransitionControllerProtocol
    private let informationTransitioningController: ClipInformationTransitioningControllerProtocol

    private var destination: TransitionDestination?
    private var cancellableBag: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    init(factory: Factory,
         baseViewController: UIViewController,
         previewTransitioningController: ClipPreviewTransitionControllerProtocol,
         informationTransitionController: ClipInformationTransitioningControllerProtocol)
    {
        self.factory = factory
        self.baseViewController = baseViewController
        self.previewTransitioningController = previewTransitioningController
        self.informationTransitioningController = informationTransitionController

        super.init()

        self.setupGestureRecognizer()
        self.bind()
    }

    // MARK: - Methods

    private func setupGestureRecognizer() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.didPan(_:)))
        panGestureRecognizer.delegate = self
        self.baseViewController.view.addGestureRecognizer(panGestureRecognizer)
        self.panGestureRecognizer = panGestureRecognizer
    }

    private func bind() {
        self.beginDismissal
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.previewTransitioningController.beginTransition(.custom(interactive: false))
                self.baseViewController.dismiss(animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        self.beginPresentInformation
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard let viewController = self.factory.make(transitioningController: self.informationTransitioningController) else { return }
                self.informationTransitioningController.beginTransition(.custom(interactive: false))
                self.baseViewController.present(viewController, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)
    }

    @objc
    func didPan(_ sender: UIPanGestureRecognizer) {
        switch (sender.state, self.destination) {
        case (.began, .back):
            self.isPreviewScrollEnabled.send(false)
            self.previewTransitioningController.beginTransition(.custom(interactive: true))
            self.baseViewController.dismiss(animated: true, completion: nil)

        case (.ended, .back):
            if self.previewTransitioningController.isInteractive {
                self.isPreviewScrollEnabled.send(true)
                self.previewTransitioningController.didPanForDismissal(sender: sender)
            }
            self.destination = nil

        case (_, .back):
            if self.previewTransitioningController.isInteractive {
                self.previewTransitioningController.didPanForDismissal(sender: sender)
            }

        case (.began, .information):
            guard let viewController = self.factory.make(transitioningController: self.informationTransitioningController) else { return }
            self.informationTransitioningController.beginTransition(.custom(interactive: true))
            self.baseViewController.present(viewController, animated: true, completion: nil)

        case (.ended, .information):
            if self.informationTransitioningController.isInteractive {
                self.informationTransitioningController.didPanForPresentation(sender: sender)
            }
            self.destination = nil

        case (_, .information):
            if self.informationTransitioningController.isInteractive {
                self.informationTransitioningController.didPanForPresentation(sender: sender)
            }

        case (_, .none):
            break
        }
    }
}

extension ClipPreviewPageTransitionController: UIGestureRecognizerDelegate {
    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer, gestureRecognizer === self.panGestureRecognizer {
            guard self.isMinimumPreviewZoomScale.value == true else { return false }
            if gestureRecognizer.velocity(in: self.baseViewController.view).y > 0 {
                self.destination = .back
            } else {
                self.destination = .information
            }
            return true
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer == self.previewPanGestureRecognizer.value {
            if self.previewContentOffset.value?.y == 0 {
                return true
            }
        }
        return false
    }
}
