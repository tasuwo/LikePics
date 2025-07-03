//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import CompositeKit
import Domain
import LikePicsUIKit
import UIKit

public class TagSelectionModalController: UIViewController {
    typealias Layout = TagSelectionModalLayout
    typealias Store = CompositeKit.Store<TagSelectionModalState, TagSelectionModalAction, TagSelectionModalDependency>

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var searchBar: UISearchBar!
    private let emptyMessageView = EmptyMessageView()
    private var quickAddButton = UIButton()
    private var dataSource: Layout.DataSource!
    private var selectionApplier: UICollectionViewSelectionLazyApplier<Layout.Section, Layout.Item, Tag>!

    // MARK: Component

    private let tagAdditionAlert: TextEditAlertController

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()
    private let collectionUpdateQueue = DispatchQueue(label: "net.tasuwo.TBox.TagSelectionModalController")

    // MARK: - Initializers

    public init(
        state: TagSelectionModalState,
        tagAdditionAlertState: TextEditAlertState,
        dependency: TagSelectionModalDependency
    ) {
        self.store = .init(initialState: state, dependency: dependency, reducer: TagSelectionModalReducer())
        self.tagAdditionAlert = .init(state: tagAdditionAlertState)
        super.init(nibName: nil, bundle: nil)

        tagAdditionAlert.textEditAlertDelegate = self
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Life-Cycle Methods

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // HACK: 画面回転時にStackViewの状態がおかしくなるケースがあるため、強制的に表示を更新する
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.collectionView.allCells
                .compactMap { $0 as? TagCollectionViewCell }
                .forEach { $0.updateAppearance() }
        })
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureDataSource()
        configureSearchBar()
        configureNavigationBar()
        configureEmptyMessageView()
        configureKeybinding()

        bind(to: store)

        store.execute(.viewDidLoad)
    }

    override public func viewDidAppear(_ animated: Bool) {
        searchBar.becomeFirstResponder()
    }
}

// MARK: - Bind

extension TagSelectionModalController {
    private func bind(to store: Store) {
        store.state
            .receive(on: collectionUpdateQueue)
            .sink { [weak self] state in
                guard let self = self else { return }
                var snapshot = Layout.Snapshot()
                snapshot.appendSections([.main])
                snapshot.appendItems(state.tags.orderedFilteredEntities().map({ Layout.Item(tag: $0, displayCount: !state.isSomeItemsHidden) }))
                self.dataSource.apply(snapshot, animatingDifferences: true)
                Task {
                    await self.selectionApplier.didApplyDataSource(snapshot: state.tags)
                }
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.isCollectionViewHidden, to: \.isHidden, on: searchBar)
            .store(in: &subscriptions)
        store.state
            .bind(\.isCollectionViewHidden, to: \.isHidden, on: collectionView)
            .store(in: &subscriptions)

        store.state
            .bind(\.emptyMessageViewAlpha, to: \.alpha, on: emptyMessageView)
            .store(in: &subscriptions)

        store.state
            .removeDuplicates(by: \.tags.selectedIds)
            .sink { [weak self] state in
                Task {
                    await self?.selectionApplier.applySelection(snapshot: state.tags)
                }
            }
            .store(in: &subscriptions)
        store.state
            .bind(\.alert) { [weak self] alert in self?.presentAlertIfNeeded(for: alert) }
            .store(in: &subscriptions)

        store.state
            .bind(\.isDismissed) { [weak self] isDismissed in
                guard isDismissed else { return }
                self?.dismissAll(completion: nil)
            }
            .store(in: &subscriptions)

        store.state
            .sink { [weak self] state in
                guard let title = state.quickAddButtonTitle, !state.isQuickAddButtonHidden else {
                    self?.quickAddButton.configuration?.title = ""
                    self?.quickAddButton.alpha = 0
                    return
                }
                self?.quickAddButton.configuration?.title = title
                self?.quickAddButton.alpha = 1
            }
            .store(in: &subscriptions)
    }

    private func presentAlertIfNeeded(for alert: TagSelectionModalState.Alert?) {
        switch alert {
        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case .addition:
            tagAdditionAlert.present(with: "", validator: { $0?.isEmpty == false }, on: self)

        case .none:
            break
        }
    }

    private func presentErrorMessageAlertIfNeeded(message: String?) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(
            .init(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
                self?.store.execute(.alertDismissed)
            }
        )
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Configuration

extension TagSelectionModalController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

        searchBar = UISearchBar()
        searchBar.backgroundColor = .clear
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyMessageView)
        NSLayoutConstraint.activate(emptyMessageView.constraints(fittingIn: view.safeAreaLayoutGuide))

        let quickAddButton = UIButton(
            primaryAction: .init { [weak self] _ in
                self?.store.execute(.quickAddButtonTapped)
            }
        )
        var configuration = UIButton.Configuration.plain()
        configuration.title = ""
        quickAddButton.configuration = configuration
        quickAddButton.isPointerInteractionEnabled = true
        quickAddButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(quickAddButton)
        NSLayoutConstraint.activate([
            quickAddButton.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            quickAddButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
        ])
        self.quickAddButton = quickAddButton
    }

    private func configureDataSource() {
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        dataSource = Layout.configureDataSource(collectionView)
        selectionApplier = UICollectionViewSelectionLazyApplier(collectionView: collectionView, dataSource: dataSource) { [weak store] model in
            return Layout.Item(tag: model, displayCount: !(store?.stateValue.isSomeItemsHidden ?? false))
        }
    }

    private func configureSearchBar() {
        searchBar.barStyle = .default
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.showsCancelButton = false
        searchBar.placeholder = L10n.placeholderSearchTag
        searchBar.backgroundColor = Asset.Color.background.color
    }

    private func configureNavigationBar() {
        navigationItem.title = L10n.tagSelectionViewTitle

        let addItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.addButtonTapped)
            }),
            menu: nil
        )
        let saveItem = UIBarButtonItem(
            systemItem: .save,
            primaryAction: .init(handler: { [weak self] _ in
                self?.store.execute(.saveButtonTapped)
            }),
            menu: nil
        )
        [addItem, saveItem].forEach {
            // HACK: ShareExtentionだと、tintColorがテキスト色にうまく反映されないケースがあるので、ここで反映する
            $0.setTitleTextAttributes([.foregroundColor: Asset.Color.likePicsRed.color], for: .normal)
            $0.setTitleTextAttributes([.foregroundColor: Asset.Color.likePicsRed.color.withAlphaComponent(0.4)], for: .disabled)
        }

        navigationItem.leftBarButtonItem = addItem
        navigationItem.rightBarButtonItem = saveItem
    }

    private func configureEmptyMessageView() {
        emptyMessageView.alpha = 0
        emptyMessageView.title = L10n.tagListViewEmptyTitle
        emptyMessageView.message = L10n.tagListViewEmptyMessage
        emptyMessageView.actionButtonTitle = L10n.tagListViewEmptyActionTitle
        emptyMessageView.delegate = self
    }

    private func configureKeybinding() {
        addKeyCommand(UIKeyCommand(title: L10n.keyCommandSave, action: #selector(handle(key:)), input: "\r", modifierFlags: .command))
        addKeyCommand(UIKeyCommand(title: L10n.keyCommandAdd, action: #selector(handle(key:)), input: "n", modifierFlags: .command))
    }

    @objc func handle(key: UIKeyCommand?) {
        switch key?.input {
        case "\r": store.execute(.saveButtonTapped)
        case "n": store.execute(.addButtonTapped)
        default: break
        }
    }
}

extension TagSelectionModalController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let tagId = dataSource.itemIdentifier(for: indexPath)?.tag.identity else { return }
        store.execute(.selected(tagId))
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let tagId = dataSource.itemIdentifier(for: indexPath)?.tag.identity else { return }
        store.execute(.deselected(tagId))
    }
}

extension TagSelectionModalController: UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDelegateFlowLayout

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return .zero }
        return TagCollectionViewCell.preferredSize(
            title: item.tag.name,
            clipCount: item.tag.clipCount,
            isHidden: item.tag.isHidden,
            visibleCountIfPossible: !store.stateValue.isSomeItemsHidden,
            visibleDeleteButton: false
        )
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12.0
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
}

extension TagSelectionModalController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        RunLoop.main.perform {
            self.store.execute(.searchQueryChanged(searchBar.text ?? ""))
        }
    }

    public func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // HACK: marked text 入力を待つために遅延を設ける
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            RunLoop.main.perform {
                self.store.execute(.searchQueryChanged(searchBar.text ?? ""))
            }
        }
        return true
    }

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension TagSelectionModalController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    public func didTapActionButton(_ view: EmptyMessageView) {
        store.execute(.emptyMessageViewActionButtonTapped)
    }
}

extension TagSelectionModalController: TextEditAlertDelegate {
    // MARK: - TextEditAlertDelegate

    public func textEditAlert(_ id: UUID, didTapSaveWithText text: String) {
        store.execute(.alertSaveButtonTapped(text: text))
    }

    public func textEditAlertDidCancel(_ id: UUID) {
        store.execute(.alertDismissed)
    }
}

extension TagSelectionModalController: UIAdaptivePresentationControllerDelegate {
    // MARK: - UIAdaptivePresentationControllerDelegate

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        store.execute(.didDismissedManually)
    }
}

extension TagSelectionModalController: ModalController {
    // MARK: - ModalController

    public var id: UUID { store.stateValue.id }
}
