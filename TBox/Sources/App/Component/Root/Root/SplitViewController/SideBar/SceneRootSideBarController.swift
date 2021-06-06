//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import TBoxUIKit
import UIKit

protocol SceneRootSideBarControllerDelegate: AnyObject {
    func appRootSideBarController(_ controller: SceneRootSideBarController, didSelect item: SceneRoot.SideBarItem)
}

class SceneRootSideBarController: UIViewController {
    typealias Layout = SceneRootSideBarLayout
    typealias Factory = ViewControllerFactory

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!

    // MARK: Store

    private let sideBarItem: AnyPublisher<Layout.Item, Never>
    private var subscription: Set<AnyCancellable> = .init()

    // MARK: Delegate

    weak var delegate: SceneRootSideBarControllerDelegate?

    // MARK: - Lifecycle

    init(sideBarItem: AnyPublisher<Layout.Item, Never>) {
        self.sideBarItem = sideBarItem
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureDataSource()

        bind(to: sideBarItem)
    }
}

// MARK: - Bind

extension SceneRootSideBarController {
    private func bind(to sideBarItem: AnyPublisher<Layout.Item, Never>) {
        sideBarItem
            .sink { [weak self] item in
                self?.collectionView.selectItem(at: IndexPath(row: item.rawValue, section: 0),
                                                animated: false,
                                                scrollPosition: [])
            }
            .store(in: &subscription)
    }
}

// MARK: - Configuration

extension SceneRootSideBarController {
    private func configureViewHierarchy() {
        navigationItem.title = "LikePics"
        navigationController?.navigationBar.prefersLargeTitles = true

        view.backgroundColor = Asset.Color.background.color

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: Layout.createLayout())
        collectionView.accessibilityIdentifier = "SceneRootSideBarController.collectionView"
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))
    }

    private func configureDataSource() {
        collectionView.delegate = self
        dataSource = Layout.configureDataSource(collectionView: collectionView)

        var snapshot = Layout.Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(SceneRoot.SideBarItem.allCases)
        dataSource.apply(snapshot)
    }
}

extension SceneRootSideBarController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        self.delegate?.appRootSideBarController(self, didSelect: item)
    }
}
