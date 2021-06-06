//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit
import TBoxUIKit
import UIKit

class ClipInformationViewController: UIViewController {
    typealias Store = ForestKit.Store<ClipInformationViewState, ClipInformationViewAction, ClipInformationViewDependency>
    typealias Layout = ClipInformationLayout

    // MARK: - Properties

    // MARK: View

    override var prefersStatusBarHidden: Bool { store.stateValue.isHiddenStatusBar }

    private let informationView: ClipInformationView
    private let transitioningController: ClipInformationTransitioningControllerProtocol
    private var panGestureRecognizer: UIPanGestureRecognizer!

    // MARK: Component

    private let siteUrlEditAlert: TextEditAlertController

    // MARK: Service

    private let router: Router

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()
    private var modalSubscription: Cancellable?

    // MARK: - Temporary

    private var transitionId: UUID?
    private let snapshotQueue = DispatchQueue(label: "net.tasuwo.TBox.ClipInformationView.Snapshot")

    // MARK: - Initializers

    init(state: ClipInformationViewState,
         siteUrlEditAlertState: TextEditAlertState,
         dependency: ClipInformationViewDependency,
         clipInformationViewCache: ClipInformationViewCaching,
         transitioningController: ClipInformationTransitioningControllerProtocol)
    {
        self.store = Store(initialState: state, dependency: dependency, reducer: ClipInformationViewReducer())
        self.siteUrlEditAlert = .init(state: siteUrlEditAlertState)
        self.transitioningController = transitioningController
        self.informationView = clipInformationViewCache.readCachingView()
        self.router = dependency.router

        super.init(nibName: nil, bundle: nil)

        siteUrlEditAlert.textEditAlertDelegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        modalSubscription?.cancel()
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
            guard transitionId == nil else { return }
            let id = UUID()
            guard transitioningController.beginTransition(id: id, mode: .custom(interactive: true)) else { return }
            informationView.isScrollEnabled = false
            dismiss(animated: true, completion: nil)
            transitionId = id

        case .ended, .cancelled, .failed, .recognized:
            guard let id = transitionId, transitioningController.isLocked(by: id) else { return }
            if transitioningController.isInteractive {
                transitioningController.didPanForDismissal(id: id, sender: sender)
            }
            informationView.isScrollEnabled = true
            transitionId = nil

        case .changed:
            guard let id = transitionId, transitioningController.isLocked(by: id) else { return }
            if transitioningController.isInteractive {
                transitioningController.didPanForDismissal(id: id, sender: sender)
            }

        case .possible:
            // NOP
            break

        @unknown default:
            // NOP
            break
        }
    }
}

// MARK: - Bind

extension ClipInformationViewController {
    private func bind(to store: Store) {
        store.state
            .removeDuplicates(by: {
                $0.clip == $1.clip
                    && $0.tags.filteredOrderedEntities() == $1.tags.filteredOrderedEntities()
                    && $0.item == $1.item
            })
            // セルの描画が崩れることがあるため、バックグラウンドスレッドから更新する
            .receive(on: snapshotQueue)
            .sink { [weak self] state in
                // インタラクティブな画面遷移中に更新が入ると操作が引っかかるので、必要に応じて更新を一時停止する
                guard state.isSuspendedCollectionViewUpdate == false else { return }
                let information = Layout.Information(clip: state.clip,
                                                     tags: state.tags.orderedFilteredEntities(),
                                                     albums: state.albums.orderedFilteredEntities(),
                                                     item: state.item)
                self?.informationView.setInfo(information, animated: state.shouldCollectionViewUpdateWithAnimation)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.isHiddenStatusBar) { [weak self] _ in
                self?.setNeedsStatusBarAppearanceUpdate()
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.alert) { [weak self] alert in self?.presentAlertIfNeeded(for: alert) }
            .store(in: &subscriptions)

        store.state
            .bind(\.modal) { [weak self] modal in self?.presentModalIfNeeded(for: modal) }
            .store(in: &subscriptions)

        store.state
            .bind(\.isDismissed) { [weak self] isDismissed in
                guard isDismissed else { return }
                self?.dismiss(animated: true, completion: nil)
            }
            .store(in: &subscriptions)
    }

    // MARK: Alert

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

    private func presentModalIfNeeded(for modal: ClipInformationViewState.Modal?) {
        switch modal {
        case let .tagSelection(id: id, tagIds: tagIds):
            presentTagSelectionModal(id: id, selections: tagIds)

        case .none:
            break
        }
    }

    private func presentTagSelectionModal(id: UUID, selections: Set<Tag.Identity>) {
        modalSubscription = ModalNotificationCenter.default
            .publisher(for: id, name: .tagSelectionModal)
            .sink { [weak self] notification in
                if let tags = notification.userInfo?[ModalNotification.UserInfoKey.selectedTags] as? Set<Tag> {
                    self?.store.execute(.tagsSelected(Set(tags.map({ $0.id }))))
                } else {
                    self?.store.execute(.tagsSelected(nil))
                }
                self?.modalSubscription?.cancel()
                self?.modalSubscription = nil
            }

        if router.showTagSelectionModal(id: id, selections: selections) == false {
            modalSubscription?.cancel()
            modalSubscription = nil
            store.execute(.modalCompleted(false))
        }
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

    func clipInformationView(_ view: ClipInformationView, didTapDeleteButtonForTag tag: Tag, at placement: UIView) {
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

    func clipInformationView(_ view: ClipInformationView, didSelectTag tag: Tag) {
        store.execute(.tagTapped(tag))
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
