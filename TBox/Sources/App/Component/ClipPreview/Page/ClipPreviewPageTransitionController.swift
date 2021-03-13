//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import TBoxUIKit
import UIKit

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
    var presentInformation: PassthroughSubject<Void, Never> { get }
}

class ClipPreviewPageTransitionController: NSObject,
    ClipPreviewPageTransitionControllerType,
    ClipPreviewPageTransitionControllerInputs,
    ClipPreviewPageTransitionControllerOutputs
{
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
    let presentInformation: PassthroughSubject<Void, Never> = .init()

    // MARK: Privates

    private weak var baseViewController: UIViewController?

    private var panGestureRecognizer: UIPanGestureRecognizer!

    private let previewTransitioningController: ClipPreviewTransitionControllerProtocol
    private let informationTransitioningController: ClipInformationTransitioningControllerProtocol

    private var destination: TransitionDestination?
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    init(previewTransitioningController: ClipPreviewTransitionControllerProtocol,
         informationTransitionController: ClipInformationTransitioningControllerProtocol)
    {
        self.previewTransitioningController = previewTransitioningController
        self.informationTransitioningController = informationTransitionController

        super.init()
    }

    // MARK: - Methods

    func setup(baseViewController: UIViewController) {
        self.baseViewController = baseViewController

        self.setupGestureRecognizer()
        self.bind()
    }

    private func setupGestureRecognizer() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.didPan(_:)))
        panGestureRecognizer.delegate = self
        self.baseViewController?.view.addGestureRecognizer(panGestureRecognizer)
        self.panGestureRecognizer = panGestureRecognizer
    }

    private func bind() {
        self.beginDismissal
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.previewTransitioningController.beginTransition(.custom(interactive: false))
                self.baseViewController?.dismiss(animated: true, completion: nil)
            }
            .store(in: &self.subscriptions)

        self.beginPresentInformation
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.informationTransitioningController.beginTransition(.custom(interactive: false))
                self.presentInformation.send(())
            }
            .store(in: &self.subscriptions)
    }

    @objc
    func didPan(_ sender: UIPanGestureRecognizer) {
        switch (sender.state, self.destination) {
        case (.began, .back):
            self.isPreviewScrollEnabled.send(false)
            self.previewTransitioningController.beginTransition(.custom(interactive: true))
            self.baseViewController?.dismiss(animated: true, completion: nil)

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
            self.informationTransitioningController.beginTransition(.custom(interactive: true))
            self.presentInformation.send(())

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
            guard self.isMinimumPreviewZoomScale.value == true, let baseView = self.baseViewController?.view else { return false }
            if gestureRecognizer.velocity(in: baseView).y > 0 {
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
