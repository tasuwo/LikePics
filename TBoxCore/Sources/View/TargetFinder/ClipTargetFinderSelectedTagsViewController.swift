//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit
import UIKit

class ClipTargetFinderSelectedTagsViewController: UIViewController {
    typealias Dependency = ClipTargetFinderSelectedTagsViewModelType

    enum Section {
        case main
    }

    private let viewModel: ClipTargetFinderSelectedTagsViewModelType

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var collectionView: UICollectionView!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var dataSource: UICollectionViewDiffableDataSource<Section, Tag>!
    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(viewModel: ClipTargetFinderSelectedTagsViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupCollectionView()

        self.bind(to: viewModel)
    }

    // MARK: - Methods

    private func bind(to dependency: Dependency) {
        dependency.outputs.tags
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tags in
                var snapshot = NSDiffableDataSourceSnapshot<Section, Tag>()
                snapshot.appendSections([.main])
                snapshot.appendItems(tags)
                self?.dataSource.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &self.cancellableBag)
    }

    private func setupCollectionView() {
        self.collectionView = TagCollectionView(frame: self.view.bounds,
                                                collectionViewLayout: self.createLayout())
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.collectionView)
        NSLayoutConstraint.activate(self.collectionView.constraints(fittingIn: self.view))

        self.collectionView.delegate = self
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = true
        self.dataSource = .init(collectionView: self.collectionView,
                                cellProvider: TagCollectionView.cellProvider(dataSource: self))
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ -> NSCollectionLayoutSection? in
            let groupEdgeSpacing = NSCollectionLayoutEdgeSpacing(leading: nil, top: nil, trailing: nil, bottom: .fixed(4))
            let section = TagCollectionView.createLayoutSection(groupEdgeSpacing: groupEdgeSpacing)
            section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 4, trailing: 12)
            return section
        }
        return layout
    }
}

extension ClipTargetFinderSelectedTagsViewController: TagCollectionViewDataSource {
    // MARK: - TagCollectionViewDataSource

    public func displayMode(_ collectionView: UICollectionView) -> TagCollectionViewCell.DisplayMode {
        return .normal
    }

    func visibleDeleteButton(_ collectionView: UICollectionView) -> Bool {
        return true
    }

    func delegate(_ collectionView: UICollectionView) -> TagCollectionViewCellDelegate? {
        return self
    }
}

extension ClipTargetFinderSelectedTagsViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension ClipTargetFinderSelectedTagsViewController: TagCollectionViewCellDelegate {
    // MARK: - TagCollectionViewCellDelegate

    func didTapDeleteButton(_ cell: TagCollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell),
            let item = self.dataSource.itemIdentifier(for: indexPath)
        else {
            return
        }
        self.viewModel.inputs.delete.send(item)
    }
}
