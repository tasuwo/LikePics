//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit
import UIKit

class ClipInformationViewController: UIViewController {
    typealias Store = LikePics.Store<ClipInformationViewState, ClipInformationViewAction, ClipInformationViewDependency>
    typealias Layout = ClipInformationLayout

    // MARK: - Properties

    // MARK: View

    override var prefersStatusBarHidden: Bool { store.stateValue.isHiddenStatusBar }

    private let informationView: ClipInformationView
    private let transitioningController: ClipInformationTransitioningControllerProtocol
    private var panGestureRecognizer: UIPanGestureRecognizer!

    // MARK: Component

    private let siteUrlEditAlert: TextEditAlertController

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Temporary

    private var previousState: ClipInformationViewState?
    private var snapshotPreviousState: ClipInformationViewState?
    private let snapshotQueue = DispatchQueue(label: "net.tasuwo.TBox.ClipInformationView.Snapshot")

    // MARK: - Initializers

    init(state: ClipInformationViewState,
         siteUrlEditAlertState: TextEditAlertState,
         dependency: ClipInformationViewDependency,
         clipInformationViewCache: ClipInformationViewCaching,
         transitioningController: ClipInformationTransitioningControllerProtocol)
    {
        self.store = Store(initialState: state, dependency: dependency, reducer: ClipInformationViewReducer.self)
        self.siteUrlEditAlert = .init(state: siteUrlEditAlertState)
        self.transitioningController = transitioningController
        self.informationView = clipInformationViewCache.readCachingView()

        super.init(nibName: nil, bundle: nil)

        siteUrlEditAlert.textEditAlertDelegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        store.execute(.viewWillAppear)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        store.execute(.viewDidAppear)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        store.execute(.viewWillDisappear)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { _ in
            self.informationView.updateImageViewFrame(for: size)
        } completion: { _ in
            // NOP
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureGestureRecognizer()

        bind(to: store)

        store.execute(.viewDidLoad)
    }

    // MARK: - IBActions

    @objc
    func didPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            informationView.isScrollEnabled = false
            transitioningController.beginTransition(.custom(interactive: true))
            dismiss(animated: true, completion: nil)

        case .ended:
            informationView.isScrollEnabled = true
            if transitioningController.isInteractive {
                transitioningController.didPanForDismissal(sender: sender)
            }

        default:
            if transitioningController.isInteractive {
                transitioningController.didPanForDismissal(sender: sender)
            }
        }
    }
}

// MARK: - Bind

extension ClipInformationViewController {
    private func bind(to store: Store) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }
            defer { self.previousState = state }

            // セルの描画が崩れることがあるため、バックグラウンドスレッドから更新する
            self.snapshotQueue.async {
                defer { self.snapshotPreviousState = state }

                // インタラクティブな画面遷移中に更新が入ると操作が引っかかるので、必要に応じて更新を一時停止する
                guard state.isSuspendedCollectionViewUpdate == false else { return }

                // iPadにてセルが過剰にアニメーションされてしまうケースがあったため、差分がある場合のみ更新をかける
                guard state.hasDifferentValue(at: \.clip, from: self.snapshotPreviousState)
                    || state.hasDifferentValue(at: \.tags, from: self.snapshotPreviousState)
                    || state.hasDifferentValue(at: \.item, from: self.snapshotPreviousState)
                else {
                    return
                }
                self.informationView.setInfo(Layout.Information(state), animated: state.shouldCollectionViewUpdateWithAnimation)
            }

            if state.hasDifferentValue(at: \.isHiddenStatusBar, from: self.previousState) {
                self.setNeedsStatusBarAppearanceUpdate()
            }

            if state.hasDifferentValue(at: \.alert, from: self.previousState) {
                self.presentAlertIfNeeded(for: state.alert)
            }

            if state.isDismissed {
                self.dismiss(animated: true, completion: nil)
            }
        }
        .store(in: &subscriptions)
    }

    private func presentAlertIfNeeded(for alert: ClipInformationViewState.Alert?) {
        switch alert {
        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case let .siteUrlEdit(title: title):
            siteUrlEditAlert.present(with: title ?? "", validator: { $0?.isEmpty == false && $0 != title && $0?.isUrlConvertible == true }, on: self)

        case .none:
            break
        }
    }

    private func presentErrorMessageAlertIfNeeded(message: String?) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        })
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Configuration

extension ClipInformationViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color

        informationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(informationView)
        NSLayoutConstraint.activate(informationView.constraints(fittingIn: view))
        informationView.delegate = self

        modalTransitionStyle = .crossDissolve
    }

    private func configureGestureRecognizer() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(self.panGestureRecognizer)
    }
}

extension ClipInformationViewController: ClipInformationViewDelegate {
    // MARK: - ClipInformationViewDelegate

    func didTapAddTagButton(_ view: ClipInformationView) {
        store.execute(.tagAdditionButtonTapped)
    }

    func clipInformationView(_ view: ClipInformationView, didSelectTag tag: Tag, at placement: UIView) {
        store.execute(.tagRemoveButtonTapped(tag.identity))
    }

    func clipInformationView(_ view: ClipInformationView, shouldOpen url: URL) {
        store.execute(.urlOpenMenuSelected(url))
    }

    func clipInformationView(_ view: ClipInformationView, shouldCopy url: URL) {
        store.execute(.urlCopyMenuSelected(url))
    }

    func clipInformationView(_ view: ClipInformationView, shouldHide isHidden: Bool) {
        if isHidden {
            store.execute(.hidedClip)
        } else {
            store.execute(.revealedClip)
        }
    }

    func clipInformationView(_ view: ClipInformationView, startEditingSiteUrl url: URL?) {
        store.execute(.siteUrlEditButtonTapped)
    }
}

extension ClipInformationViewController: TextEditAlertDelegate {
    // MARK: - TextEditAlertDelegate

    func textEditAlert(_ id: UUID, didTapSaveWithText text: String) {
        store.execute(.siteUrlEditConfirmed(text: text))
    }

    func textEditAlertDidCancel(_ id: UUID) {
        store.execute(.alertDismissed)
    }
}

extension ClipInformationViewController: UIGestureRecognizerDelegate {
    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer, gestureRecognizer === panGestureRecognizer {
            guard gestureRecognizer.velocity(in: self.view).y > 0 else { return false }
            return true
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer == informationView.panGestureRecognizer {
            return informationView.contentOffSet.y <= 0
        }
        return false
    }
}

extension ClipInformationViewController: ClipInformationPresentedAnimatorDataSource {
    // MARK: - ClipInformationPresentedAnimatorDataSource

    func animatingInformationView(_ animator: ClipInformationAnimator) -> ClipInformationView? {
        return informationView
    }

    func clipInformationAnimator(_ animator: ClipInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect {
        // HACK: Update safeAreaInsets immediately.
        containerView.layoutIfNeeded()
        return informationView.convert(informationView.calcInitialFrame(), to: containerView)
    }
}

extension ClipInformationLayout.Information {
    init(_ state: ClipInformationViewState) {
        self.init(clip: state.clip, tags: state.tags.displayableValues, item: state.item)
    }
}
