//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

protocol SceneRootSideBarControllerDelegate: AnyObject {
    func appRootSideBarController(_ controller: SceneRootSideBarController, didSelect item: SceneRootSideBarController.Item)
}

class SceneRootSideBarController: UIViewController {
    typealias Factory = ViewControllerFactory

    enum Section: Int {
        case main
    }

    typealias Item = SceneRoot.SideBarItem

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    // MARK: Store

    private let sideBarItem: AnyPublisher<Item, Never>
    private var subscription: Set<AnyCancellable> = .init()

    // MARK: Delegate

    weak var delegate: SceneRootSideBarControllerDelegate?

    // MARK: - Lifecycle

    init(sideBarItem: AnyPublisher<Item, Never>) {
        self.sideBarItem = sideBarItem
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "LikePics"
        navigationController?.navigationBar.prefersLargeTitles = true

        configureHierarchy()
        configureDataSource()

        bind(to: sideBarItem)
    }
}

// MARK: - Bind

extension SceneRootSideBarController {
    private func bind(to sideBarItem: AnyPublisher<Item, Never>) {
        sideBarItem
            .sink { [weak self] item in
                self?.collectionView.selectItem(at: IndexPath(row: item.rawValue, section: 0),
                                                animated: false,
                                                scrollPosition: [])
            }
            .store(in: &subscription)
    }
}

// MARK: - Layout

extension SceneRootSideBarController {
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { _, environment -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
            configuration.backgroundColor = Asset.Color.backgroundClient.color
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        }
    }
}

extension SceneRootSideBarController {
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: createLayout())
        collectionView.backgroundColor = Asset.Color.backgroundClient.color
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        collectionView.delegate = self
    }

    private func configureDataSource() {
        let registration: UICollectionView.CellRegistration<UICollectionViewListCell, Item> = .init { cell, _, item in
            var contentConfiguration = UIListContentConfiguration.sidebarCell()
            contentConfiguration.image = item.image
            contentConfiguration.text = item.title
            cell.contentConfiguration = contentConfiguration
        }

        dataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: item)
        }
        collectionView.dataSource = dataSource

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(Item.allCases)
        dataSource.apply(snapshot)
    }
}

extension SceneRootSideBarController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        self.delegate?.appRootSideBarController(self, didSelect: item)
    }
}
