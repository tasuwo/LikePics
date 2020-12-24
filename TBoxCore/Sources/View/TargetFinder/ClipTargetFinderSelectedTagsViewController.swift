//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import TBoxUIKit
import UIKit

class ClipTargetFinderSelectedTagsViewController: UIViewController {
    typealias Factory = ViewControllerFactory
    typealias Dependency = ClipTargetFinderSelectedTagsViewModelType

    enum Section {
        case main
    }

    enum Cell: Hashable, Equatable {
        case addition
        case tag(Tag)
    }

    var contentViewHeight: CurrentValueSubject<CGFloat, Never> = .init(0)

    private let factory: Factory
    let viewModel: ClipTargetFinderSelectedTagsViewModelType

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Cell>!
    private var cancellableBag = Set<AnyCancellable>()
    private var observation: NSKeyValueObservation?

    // MARK: - Lifecycle

    init(factory: Factory,
         viewModel: ClipTargetFinderSelectedTagsViewModelType)
    {
        self.factory = factory
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
                var snapshot = NSDiffableDataSourceSnapshot<Section, Cell>()
                snapshot.appendSections([.main])
                snapshot.appendItems([.addition] + tags.map({ .tag($0) }))
                // NOTE: contentViewHeightがタイミングによって正確に取得できない問題を解消するためにアニメーションはOFF
                self?.dataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &self.cancellableBag)

        self.observation = self.collectionView
            .observe(\.contentSize, options: [.new]) { [weak self] _, change in
                guard let newHeight = change.newValue?.height else { return }
                self?.contentViewHeight.send(newHeight)
            }
    }

    private func setupCollectionView() {
        self.collectionView = TagCollectionView(frame: self.view.bounds, collectionViewLayout: Self.createLayout())
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.collectionView)
        NSLayoutConstraint.activate(self.collectionView.constraints(fittingIn: self.view))

        self.collectionView.backgroundColor = Asset.Color.background.color
        self.collectionView.delegate = self
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = true
        self.dataSource = .init(collectionView: self.collectionView, cellProvider: self.cellProvider())
    }

    private func cellProvider() -> (UICollectionView, IndexPath, Cell) -> UICollectionViewCell? {
        return { [weak self] collectionView, indexPath, item -> UICollectionViewCell? in
            switch item {
            case .addition:
                let configuration = TagCollectionView.CellConfiguration.Addition(title: L10n.clipTargetFinderViewAdditionTitle,
                                                                                 delegate: self)
                return TagCollectionView.provideCell(collectionView: collectionView,
                                                     indexPath: indexPath,
                                                     configuration: .addition(configuration))

            case let .tag(value):
                let configuration = TagCollectionView.CellConfiguration.Tag(tag: value,
                                                                            displayMode: .normal,
                                                                            visibleDeleteButton: true,
                                                                            delegate: self)
                return TagCollectionView.provideCell(collectionView: collectionView,
                                                     indexPath: indexPath,
                                                     configuration: .tag(configuration))
            }
        }
    }

    private static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ -> NSCollectionLayoutSection? in
            let groupEdgeSpacing = NSCollectionLayoutEdgeSpacing(leading: nil, top: nil, trailing: nil, bottom: .fixed(4))
            let section = TagCollectionView.createLayoutSection(groupEdgeSpacing: groupEdgeSpacing)
            section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 4, trailing: 12)
            return section
        }
        return layout
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
            let item = self.dataSource.itemIdentifier(for: indexPath),
            case let .tag(tag) = item
        else {
            return
        }
        self.viewModel.inputs.delete.send(tag)
    }
}

extension ClipTargetFinderSelectedTagsViewController: TagCollectionAdditionCellDelegate {
    // MARK: - TagCollectionAdditionCellDelegate

    func didTap(_ cell: TagCollectionAdditionCell) {
        guard let parent = self.parent else {
            RootLogger.shared.write(ConsoleLog(level: .error, message: "Failed to resolve parent view controller for opening tag selection view"))
            return
        }
        let selectedTags = Set(self.viewModel.outputs.tags.value.map({ $0.identity }))
        guard let nextVC = self.factory.makeTagSelectionViewController(selectedTags: selectedTags, delegate: self) else {
            RootLogger.shared.write(ConsoleLog(level: .error, message: "Failed to open tag selection view"))
            return
        }
        parent.present(nextVC, animated: true, completion: nil)
    }
}

extension ClipTargetFinderSelectedTagsViewController: TagSelectionViewControllerDelegate {
    // MARK: - TagSelectionViewControllerDelegate

    func didSelectTags(tags: [Tag]) {
        self.viewModel.inputs.replace.send(tags)
    }
}
