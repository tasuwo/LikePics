//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class SearchResultViewController: UIViewController, ClipsListViewController {
    typealias Factory = ViewControllerFactory
    typealias Presenter = SearchResultPresenter

    let factory: Factory
    let presenter: Presenter
    let navigationItemManager = ClipsListNavigationItemManager()

    @IBOutlet var collectionView: ClipsCollectionView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: SearchResultPresenter) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.presenter.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupAppearance()
        self.setupCollectionView()
        self.setupNavigationBar()
        self.setupToolBar()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.title = self.presenter.context.title
    }

    // MARK: CollectionView

    private func setupCollectionView() {
        if let layout = self.collectionView?.collectionViewLayout as? ClipCollectionLayout {
            layout.delegate = self
        }
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationItemManager.delegate = self
        self.navigationItemManager.dataSource = self.presenter
        self.navigationItemManager.navigationItem = self.navigationItem
    }

    // MARK: ToolBar

    private func setupToolBar() {
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let addToAlbumItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAddToAlbum))
        let removeItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(self.didTapRemove))
        let hideItem = UIBarButtonItem(image: UIImage(systemName: "eye.slash"), style: .plain, target: self, action: #selector(self.didTapHide))
        let unhideItem = UIBarButtonItem(image: UIImage(systemName: "eye"), style: .plain, target: self, action: #selector(self.didTapUnhide))

        self.setToolbarItems([addToAlbumItem, flexibleItem, hideItem, flexibleItem, unhideItem, flexibleItem, removeItem], animated: false)
        self.updateToolBar(for: self.presenter.isEditing)
    }

    private func updateToolBar(for editing: Bool) {
        self.navigationController?.setToolbarHidden(!editing, animated: false)
    }

    @objc
    func didTapAddToAlbum() {
        let viewController = self.factory.makeAddingClipsToAlbumViewController(clips: clips, delegate: self)
        self.present(viewController, animated: true, completion: nil)
    }

    @objc
    func didTapRemove() {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipsListAlertForDeleteMessage,
                                      preferredStyle: .actionSheet)

        let title = L10n.clipsListAlertForDeleteAction(self.presenter.selectedClips.count)
        alert.addAction(.init(title: title, style: .destructive, handler: { [weak self] _ in
            self?.presenter.deleteAll()
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }

    @objc
    func didTapHide() {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipsListAlertForHideMessage,
                                      preferredStyle: .actionSheet)

        let title = L10n.clipsListAlertForHideAction(self.presenter.selectedClips.count)
        alert.addAction(.init(title: title, style: .destructive, handler: { [weak self] _ in
            self?.presenter.hidesAll()
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }

    @objc
    func didTapUnhide() {
        self.presenter.unhidesAll()
    }

    // MARK: UIViewController (Override)

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.updateCollectionView(for: editing)

        self.navigationItemManager.setEditing(editing, animated: animated)
        self.updateToolBar(for: editing)
    }
}

extension SearchResultViewController: SearchResultViewProtocol {
    // MARK: - SearchResultViewProtocol

    func reloadList() {
        self.collectionView.reloadData()
    }

    func applySelection(at indices: [Int]) {
        self.collectionView.applySelection(at: indices.map { IndexPath(row: $0, section: 0) })
        self.navigationItemManager.onUpdateSelection()
    }

    func applyEditing(_ editing: Bool) {
        self.setEditing(editing, animated: true)
    }

    func presentPreviewView(for clip: Clip) {
        let nextViewController = self.factory.makeClipPreviewViewController(clip: clip)
        self.present(nextViewController, animated: true, completion: nil)
    }

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
    }
}

extension SearchResultViewController: ClipPreviewPresentingViewController {
    // MARK: - ClipPreviewPresentingViewController

    var selectedIndexPath: IndexPath? {
        guard let index = self.presenter.selectedIndices.first else { return nil }
        return IndexPath(row: index, section: 0)
    }

    var clips: [Clip] {
        self.presenter.clips
    }
}

extension SearchResultViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return self.collectionView(self, collectionView, shouldSelectItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return self.collectionView(self, collectionView, shouldSelectItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.collectionView(self, collectionView, didSelectItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.collectionView(self, collectionView, didDeselectItemAt: indexPath)
    }
}

extension SearchResultViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.numberOfSections(self, in: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.collectionView(self, collectionView, numberOfItemsInSection: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return self.collectionView(self, collectionView, cellForItemAt: indexPath)
    }
}

extension SearchResultViewController: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        return self.collectionView(self, collectionView, photoHeightForWidth: width, atIndexPath: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat {
        return self.collectionView(self, collectionView, heightForHeaderAtIndexPath: indexPath)
    }
}

extension SearchResultViewController: ClipsListNavigationItemManagerDelegate {
    // MARK: - ClipsListNavigationItemManagerDelegate

    func didTapEditButton(_ manager: ClipsListNavigationItemManager) {
        self.presenter.setEditing(true)
    }

    func didTapCancelButton(_ manager: ClipsListNavigationItemManager) {
        self.presenter.setEditing(false)
    }

    func didTapSelectAllButton(_ manager: ClipsListNavigationItemManager) {
        self.presenter.selectAll()
    }

    func didTapDeselectAllButton(_ manager: ClipsListNavigationItemManager) {
        self.presenter.deselectAll()
    }
}

extension SearchResultViewController: AddingClipsToAlbumPresenterDelegate {
    // MARK: - AddingClipsToAlbumPresenterDelegate

    func addingClipsToAlbumPresenter(_ presenter: AddingClipsToAlbumPresenter, didSucceededToAdding isSucceeded: Bool) {
        guard isSucceeded else { return }
        self.presenter.setEditing(false)
    }
}

extension SearchResultPresenter: ClipsListNavigationItemManagerDataSource {
    // MARK: - ClipsListNavigationItemManagerDataSource

    func clipsCount(_ manager: ClipsListNavigationItemManager) -> Int {
        return self.clips.count
    }

    func selectedClipsCount(_ manager: ClipsListNavigationItemManager) -> Int {
        return self.selectedClips.count
    }
}
