//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Persistence
import UIKit

class UserInterfaceStyleSelectionViewController: UIViewController {
    typealias Layout = UserInterfaceStyleSelectionViewLayout

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!

    // MARK: Service

    private let userSettingsStorage: UserSettingsStorageProtocol = UserSettingsStorage.shared

    // MARK: Subscription

    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureDataSource()

        bind()
    }
}

// MARK: - Bind

extension UserInterfaceStyleSelectionViewController {
    private func bind() {
        userSettingsStorage
            .userInterfaceStyle
            .sink { [weak self] style in self?.apply(style: style) }
            .store(in: &subscriptions)
    }

    private func apply(style: UserInterfaceStyle) {
        Layout.Item.allCases.forEach { item in
            guard let indexPath = dataSource.indexPath(for: item),
                  let cell = collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell else { return }
            if item.style == style {
                cell.accessories = [.checkmark()]
            } else {
                cell.accessories = []
            }
        }
    }
}

// MARK: - Configuration

extension UserInterfaceStyleSelectionViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.delegate = self
        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))
    }

    private func configureDataSource() {
        dataSource = Layout.configureDataSource(collectionView: collectionView)

        var snapshot = Layout.Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(Layout.Item.allCases)
        dataSource.apply(snapshot)
    }
}

extension UserInterfaceStyleSelectionViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell else { return }
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        userSettingsStorage.set(userInterfaceStyle: item.style)
        cell.accessories = [.checkmark()]
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell else { return }
        cell.accessories = []
    }
}
