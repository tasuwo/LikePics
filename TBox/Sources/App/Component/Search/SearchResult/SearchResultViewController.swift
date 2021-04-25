//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Persistence
import Smoothie
import UIKit

class SearchResultViewController: UIViewController {
    typealias Layout = SearchResultViewLayout

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!

    // MARK: Dependencies

    private let thumbnailLoader: ThumbnailLoaderProtocol
    private let queryService: ClipQueryService

    // MARK: - Initializers

    init(queryService: ClipQueryService,
         thumbnailLoader: ThumbnailLoaderProtocol)
    {
        self.queryService = queryService
        self.thumbnailLoader = thumbnailLoader

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .red

        configureViewHierarchy()
        configureDataSource()

        // =====Dummy=====
        var snapshot = Layout.Snapshot()
        snapshot.appendSections([.tokenCandidates])
        snapshot.appendItems([
            .tokenCandidate(.init(kind: .tag, title: "hoge")),
            .tokenCandidate(.init(kind: .tag, title: "fuga")),
            .tokenCandidate(.init(kind: .album, title: "piyo"))
        ])

        guard case let .success(query) = queryService.queryAllClips() else { return }
        snapshot.appendSections([.results])
        snapshot.appendItems(query.clips.value.prefix(12).map({ Layout.Item.result($0) }))

        dataSource.apply(snapshot)
        // ===============
    }
}

// MARK: - Configuration

extension SearchResultViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))
    }

    private func configureDataSource() {
        // swiftlint:disable identifier_name
        let _dataSource = Layout.createDataSource(collectionView: collectionView,
                                                  thumbnailLoader: thumbnailLoader,
                                                  seeAllButtonHandler: { print("See All Tapped") })
        dataSource = _dataSource
        collectionView.delegate = self
    }
}

extension SearchResultViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("selected at \(indexPath)")
    }
}
