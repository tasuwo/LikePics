//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import LikePicsUIKit
import UIKit

public class ClipPreviewAnimationSelectionViewController: UIViewController {
    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!

    // MARK: Service

    private let storage: ClipPreviewPlayConfigurationStorageProtocol

    // MARK: - Initializers

    public init(storage: ClipPreviewPlayConfigurationStorageProtocol) {
        self.storage = storage
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.Root.MenuTitle.animation

        configureViewHierarchy()
        configureDataSource()
    }
}

// MARK: - Configuration

extension ClipPreviewAnimationSelectionViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))
    }

    private func configureDataSource() {
        dataSource = Layout.configureDataSource(collectionView: collectionView)

        var snapshot = Layout.Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems([.forward, .reverse, .off])
        dataSource.apply(snapshot) { [weak self] in
            guard let self = self else { return }
            guard let indexPath = self.dataSource.indexPath(for: self.storage.fetchAnimation()) else { return }
            self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell else { return }
            cell.accessories = [.checkmark()]
        }
    }
}

extension ClipPreviewAnimationSelectionViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell else { return }
        cell.accessories = [.checkmark()]

        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        storage.set(animation: item)

        navigationController?.popViewController(animated: true)
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell else { return }
        cell.accessories = []
    }
}

// MARK: - Layout

extension ClipPreviewAnimationSelectionViewController {
    @MainActor
    enum Layout {
        typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
        typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

        enum Section: Int {
            case main
        }

        typealias Item = ClipPreviewPlayConfiguration.Animation

        static func createLayout() -> UICollectionViewLayout {
            let layout = UICollectionViewCompositionalLayout { _, environment -> NSCollectionLayoutSection? in
                var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                configuration.backgroundColor = Asset.Color.background.color
                return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
            }
            return layout
        }

        static func configureDataSource(collectionView: UICollectionView) -> DataSource {
            let cellRegistration = configureCell()

            let dataSource: DataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
                collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }

            return dataSource
        }

        private static func configureCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
            return UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, _, item in
                var contentConfiguration = UIListContentConfiguration.valueCell()
                contentConfiguration.text = item.displayText
                cell.contentConfiguration = contentConfiguration

                var backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
                backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackground.color
                cell.backgroundConfiguration = backgroundConfiguration
            }
        }
    }
}
