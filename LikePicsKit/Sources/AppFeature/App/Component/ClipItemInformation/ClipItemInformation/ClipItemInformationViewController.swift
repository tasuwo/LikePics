//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import Environment
import LikePicsUIKit
import MobileTransition
import TagSelectionModalFeature
import UIKit

class ClipItemInformationViewController: UIViewController {
    typealias Store = CompositeKit.Store<ClipItemInformationViewState, ClipItemInformationViewAction, ClipItemInformationViewDependency>
    typealias Layout = ClipItemInformationLayout
    typealias ModalRouter = AlbumSelectionModalRouter & TagSelectionModalRouter

    // MARK: - Properties

    // MARK: View

    override var prefersStatusBarHidden: Bool { store.stateValue.isHiddenStatusBar }

    private let informationView = ClipItemInformationView()
    private let transitioningController: ClipItemInformationTransitioningControllable
    private var panGestureRecognizer: UIPanGestureRecognizer!

    // MARK: Component

    private let siteUrlEditAlert: TextEditAlertController

    // MARK: Service

    private let modalRouter: ModalRouter

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()
    private var modalSubscriptions: Set<AnyCancellable> = .init()

    // MARK: - Temporary

    private var transitionId: UUID?
    private let snapshotQueue = DispatchQueue(label: "net.tasuwo.TBox.ClipItemInformationView.Snapshot")

    // MARK: - Initializers

    init(state: ClipItemInformationViewState,
         siteUrlEditAlertState: TextEditAlertState,
         dependency: ClipItemInformationViewDependency,
         transitioningController: ClipItemInformationTransitioningControllable,
         modalRouter: ModalRouter)
    {
        self.store = Store(initialState: state, dependency: dependency, reducer: ClipItemInformationViewReducer())
        self.siteUrlEditAlert = .init(state: siteUrlEditAlertState)
        self.transitioningController = transitioningController
        self.modalRouter = modalRouter

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

extension ClipItemInformationViewController {
    private func bind(to store: Store) {
        store.state
            // インタラクティブな画面遷移中に更新が入ると操作が引っかかるので、必要に応じて更新を一時停止する
            .filter { $0.isSuspendedCollectionViewUpdate == false }
            .removeDuplicates(by: {
                $0.clip == $1.clip
                    && $0.tags.filteredOrderedEntities() == $1.tags.filteredOrderedEntities()
                    && $0.albums.filteredOrderedEntities() == $1.albums.filteredOrderedEntities()
                    && $0.item == $1.item
            })
            // セルの描画が崩れることがあるため、バックグラウンドスレッドから更新する
            .receive(on: snapshotQueue)
            .sink { [weak self] state in
                let information = Layout.Information(clip: state.clip,
                                                     tags: state.tags.orderedFilteredEntities(),
                                                     albums: state.albums.orderedFilteredEntities(),
                                                     item: state.item)
                self?.informationView.setInfo(information, animated: true)
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
                self?.dismissAll(completion: nil)
            }
            .store(in: &subscriptions)
    }

    // MARK: Alert

    private func presentAlertIfNeeded(for alert: ClipItemInformationViewState.Alert?) {
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

    // MARK: Modal

    private func presentModalIfNeeded(for modal: ClipItemInformationViewState.Modal?) {
        switch modal {
        case let .tagSelection(id: id, tagIds: tagIds):
            presentTagSelectionModal(id: id, selections: tagIds)

        case let .albumSelection(id: id):
            presentAlbumSelectionModal(id: id)

        case .none:
            break
        }
    }

    private func presentTagSelectionModal(id: UUID, selections: Set<Tag.Identity>) {
        ModalNotificationCenter.default
            .publisher(for: id, name: .tagSelectionModalDidSelect)
            .sink { [weak self] notification in
                if let tags = notification.userInfo?[ModalNotification.UserInfoKey.selectedTags] as? [Tag] {
                    self?.store.execute(.tagsSelected(Set(tags.map({ $0.id }))))
                } else {
                    self?.store.execute(.tagsSelected(nil))
                }
                self?.modalSubscriptions.removeAll()
            }
            .store(in: &modalSubscriptions)

        ModalNotificationCenter.default
            .publisher(for: id, name: .tagSelectionModalDidDismiss)
            .sink { [weak self] _ in
                self?.modalSubscriptions.removeAll()
                self?.store.execute(.modalCompleted(false))
            }
            .store(in: &modalSubscriptions)

        if modalRouter.showTagSelectionModal(id: id, selections: selections) == false {
            modalSubscriptions.removeAll()
            store.execute(.modalCompleted(false))
        }
    }

    private func presentAlbumSelectionModal(id: UUID) {
        ModalNotificationCenter.default
            .publisher(for: id, name: .albumSelectionModal)
            .sink { [weak self] notification in
                let albumId = notification.userInfo?[ModalNotification.UserInfoKey.selectedAlbumId] as? Album.Identity
                self?.store.execute(.albumSelected(albumId))
                self?.modalSubscriptions.removeAll()
            }
            .store(in: &modalSubscriptions)

        ModalNotificationCenter.default
            .publisher(for: id, name: .albumSelectionModalDidDismiss)
            .sink { [weak self] _ in
                self?.store.execute(.modalCompleted(false))
                self?.modalSubscriptions.removeAll()
            }
            .store(in: &modalSubscriptions)

        if modalRouter.showAlbumSelectionModal(id: id) == false {
            modalSubscriptions.removeAll()
            store.execute(.modalCompleted(false))
        }
    }
}

// MARK: - Configuration

extension ClipItemInformationViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

        informationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(informationView)
        NSLayoutConstraint.activate(informationView.constraints(fittingIn: view))
        informationView.delegate = self

        modalTransitionStyle = .crossDissolve
    }

    private func configureGestureRecognizer() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        panGestureRecognizer.allowedScrollTypesMask = .all
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(self.panGestureRecognizer)
    }
}

extension ClipItemInformationViewController: ClipItemInformationViewDelegate {
    // MARK: - ClipItemInformationViewDelegate

    func didTapAddTagButton(_ view: ClipItemInformationView) {
        store.execute(.tagAdditionButtonTapped)
    }

    func didTapAddToAlbumButton(_ view: ClipItemInformationView) {
        store.execute(.albumAdditionButtonTapped)
    }

    func clipItemInformationView(_ view: ClipItemInformationView, didTapDeleteButtonForTag tag: Tag, at placement: UIView) {
        store.execute(.tagRemoveButtonTapped(tag.identity))
    }

    func clipItemInformationView(_ view: ClipItemInformationView, shouldOpen url: URL) {
        store.execute(.urlOpenMenuSelected(url))
    }

    func clipItemInformationView(_ view: ClipItemInformationView, shouldCopy url: URL) {
        store.execute(.urlCopyMenuSelected(url))
    }

    func clipItemInformationView(_ view: ClipItemInformationView, shouldHide isHidden: Bool) {
        if isHidden {
            store.execute(.hidedClip)
        } else {
            store.execute(.revealedClip)
        }
    }

    func clipItemInformationView(_ view: ClipItemInformationView, startEditingSiteUrl url: URL?) {
        store.execute(.siteUrlEditButtonTapped)
    }

    func clipItemInformationView(_ view: ClipItemInformationView, didSelectTag tag: Tag) {
        store.execute(.tagTapped(tag))
    }

    func clipItemInformationView(_ view: ClipItemInformationView, didSelectAlbum album: ListingAlbumTitle) {
        store.execute(.albumTapped(album))
    }

    func clipItemInformationView(_ view: ClipItemInformationView, didRequestDeleteAlbum album: ListingAlbumTitle, completion: @escaping (Bool) -> Void) {
        store.execute(.albumDeleted(album))
    }
}

extension ClipItemInformationViewController: TextEditAlertDelegate {
    // MARK: - TextEditAlertDelegate

    func textEditAlert(_ id: UUID, didTapSaveWithText text: String) {
        store.execute(.siteUrlEditConfirmed(text: text))
    }

    func textEditAlertDidCancel(_ id: UUID) {
        store.execute(.alertDismissed)
    }
}

extension ClipItemInformationViewController: UIGestureRecognizerDelegate {
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

extension ClipItemInformationViewController: ClipItemInformationPresenting {
    // MARK: - ClipItemInformationPresenting

    func clipItem(_ animator: ClipItemInformationAnimator) -> InfoViewingClipItem? {
        return .init(clipId: store.stateValue.clipId,
                     itemId: store.stateValue.itemId)
    }

    func clipInformationView(_ animator: ClipItemInformationAnimator) -> ClipItemInformationView? {
        return informationView
    }

    func clipInformationAnimator(_ animator: ClipItemInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect {
        // HACK: Update safeAreaInsets immediately.
        containerView.layoutIfNeeded()
        return informationView.convert(informationView.calcInitialFrame(), to: containerView)
    }
}
