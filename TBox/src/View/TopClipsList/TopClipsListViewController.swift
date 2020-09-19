//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class TopClipsListViewController: UIViewController, ClipsListViewController {
    typealias Factory = ViewControllerFactory
    typealias Presenter = TopClipsListPresenter

    let factory: Factory
    let presenter: Presenter
    let navigationItemsProvider: ClipsListNavigationItemsProvider

    @IBOutlet var collectionView: ClipsCollectionView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: TopClipsListPresenter, navigationItemsProvider: ClipsListNavigationItemsProvider) {
        self.factory = factory
        self.presenter = presenter
        self.navigationItemsProvider = navigationItemsProvider
        super.init(nibName: nil, bundle: nil)

        self.presenter.view = self
        self.addBecomeActiveNotification()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupCollectionView()
        self.setupNavigationBar()
        self.setupToolBar()

        self.presenter.reload()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.presenter.reload()
    }

    // MARK: - Methods

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
        self.navigationItemsProvider.delegate = self
        self.navigationItemsProvider.navigationItem = self.navigationItem
    }

    // MARK: Notification

    private func addBecomeActiveNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    private func removeBecomeActiveNotification() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
    }

    @objc
    func didBecomeActive() {
        self.presenter.reload()
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
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipsListAlertForAddToAlbum, style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let viewController = self.factory.makeAddingClipsToAlbumViewController(clips: self.presenter.selectedClips, delegate: self)
            self.present(viewController, animated: true, completion: nil)
        }))

        alert.addAction(.init(title: L10n.clipsListAlertForAddTag, style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let viewController = self.factory.makeAddingTagToClipViewController(clips: self.presenter.selectedClips, delegate: self)
            self.present(viewController, animated: true, completion: nil)
        }))

        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
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

        self.navigationItemsProvider.setEditing(editing, animated: animated)
        self.updateToolBar(for: editing)
    }

    deinit {
        self.removeBecomeActiveNotification()
    }
}

extension TopClipsListViewController: TopClipsListViewProtocol {
    // MARK: - TopClipsListViewProtocol

    func reloadList() {
        self.collectionView.reloadData()
    }

    func applySelection(at indices: [Int]) {
        self.collectionView.applySelection(at: indices.map { IndexPath(row: $0, section: 0) })
        self.navigationItemsProvider.onUpdateSelection()
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

extension TopClipsListViewController: ClipPreviewPresentingViewController {
    // MARK: - ClipPreviewPresentingViewController

    var selectedIndexPath: IndexPath? {
        guard let index = self.presenter.selectedIndices.first else { return nil }
        return IndexPath(row: index, section: 0)
    }

    var clips: [Clip] {
        self.presenter.clips
    }
}

extension TopClipsListViewController: UICollectionViewDelegate {
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

extension TopClipsListViewController: UICollectionViewDataSource {
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

extension TopClipsListViewController: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsCollectionLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        return self.collectionView(self, collectionView, photoHeightForWidth: width, atIndexPath: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat {
        return self.collectionView(self, collectionView, heightForHeaderAtIndexPath: indexPath)
    }
}

extension TopClipsListViewController: ClipsListNavigationItemsProviderDelegate {
    // MARK: - ClipsListNavigationItemsProviderDelegate

    func didTapEditButton(_ provider: ClipsListNavigationItemsProvider) {
        self.presenter.setEditing(true)
    }

    func didTapCancelButton(_ provider: ClipsListNavigationItemsProvider) {
        self.presenter.setEditing(false)
    }

    func didTapSelectAllButton(_ provider: ClipsListNavigationItemsProvider) {
        self.presenter.selectAll()
    }

    func didTapDeselectAllButton(_ provider: ClipsListNavigationItemsProvider) {
        self.presenter.deselectAll()
    }
}

extension TopClipsListViewController: AddingClipsToAlbumPresenterDelegate {
    // MARK: - AddingClipsToAlbumPresenterDelegate

    func addingClipsToAlbumPresenter(_ presenter: AddingClipsToAlbumPresenter, didSucceededToAdding isSucceeded: Bool) {
        guard isSucceeded else { return }
        self.presenter.setEditing(false)
    }
}

extension TopClipsListViewController: AddingTagsToClipsPresenterDelegate {
    // MARK: - AddingTagsToClipsPresenterDelegate

    func addingTagsToClipsPresenter(_ presenter: AddingTagsToClipsPresenter, didSucceededToAddingTag isSucceeded: Bool) {
        guard isSucceeded else { return }
        self.presenter.setEditing(false)
    }
}
