//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class AlbumViewController: UIViewController, ClipsListViewController {
    typealias Factory = ViewControllerFactory
    typealias Presenter = AlbumPresenter

    let factory: Factory
    let presenter: Presenter

    @IBOutlet var collectionView: ClipsCollectionView!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: AlbumPresenter) {
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

        self.setupCollectionView()
        self.setupNavigationBar()
        self.setupToolBar()
    }

    @IBAction func didTapAlbumView(_ sender: UITapGestureRecognizer) {
        self.navigationItem.titleView?.endEditing(true)
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
        self.updateNavigationBar(for: self.presenter.isEditing)
    }

    private func updateNavigationBar(for isEditing: Bool) {
        if isEditing {
            let button = RoundedButton()
            button.setTitle(L10n.confirmAlertCancel, for: .normal)
            button.addTarget(self, action: #selector(self.didTapCancel), for: .touchUpInside)

            self.navigationItem.rightBarButtonItems = [
                UIBarButtonItem(customView: button)
            ]
        } else {
            let button = RoundedButton()
            button.setTitle(L10n.clipsListRightBarItemForSelectTitle, for: .normal)
            button.addTarget(self, action: #selector(self.didTapEdit), for: .touchUpInside)

            self.navigationItem.rightBarButtonItems = [
                UIBarButtonItem(customView: button)
            ]
        }
    }

    @objc
    func didTapEdit() {
        self.presenter.setEditing(true)
    }

    @objc
    func didTapCancel() {
        self.presenter.setEditing(false)
    }

    // MARK: ToolBar

    private func setupToolBar() {
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let addToAlbumItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAddToAlbum))
        let removeItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(self.didTapRemove))

        self.setToolbarItems([addToAlbumItem, flexibleItem, removeItem], animated: false)
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
        let alert = UIAlertController(title: "", message: "選択中の画像を削除しますか？", preferredStyle: .alert)

        alert.addAction(.init(title: "アルバムから削除", style: .destructive, handler: { [weak self] _ in
            self?.presenter.removeFromAlbum()
        }))
        alert.addAction(.init(title: "完全に削除", style: .destructive, handler: { [weak self] _ in
            self?.presenter.deleteAll()
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }

    // MARK: UIViewController (Override)

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.updateCollectionView(for: editing)

        self.updateNavigationBar(for: editing)
        self.updateToolBar(for: editing)
    }
}

extension AlbumViewController: AlbumViewProtocol {
    // MARK: - AlbumViewProtocol

    func reloadList() {
        self.collectionView.reloadData()
    }

    func applySelection(at indices: [Int]) {
        self.collectionView.applySelection(at: indices.map { IndexPath(row: $0, section: 0) })
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

extension AlbumViewController: ClipPreviewPresentingViewController {
    // MARK: - ClipPreviewPresentingViewController

    var selectedIndexPath: IndexPath? {
        guard let index = self.presenter.selectedIndices.first else { return nil }
        return IndexPath(row: index, section: 0)
    }

    var clips: [Clip] {
        self.presenter.clips
    }
}

extension AlbumViewController: UICollectionViewDelegate {
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

extension AlbumViewController: UICollectionViewDataSource {
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

extension AlbumViewController: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        return self.collectionView(self, collectionView, photoHeightForWidth: width, atIndexPath: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat {
        return self.collectionView(self, collectionView, heightForHeaderAtIndexPath: indexPath)
    }
}

extension AlbumViewController: AddingClipsToAlbumPresenterDelegate {
    // MARK: - AddingClipsToAlbumPresenterDelegate

    func addingClipsToAlbumPresenter(_ presenter: AddingClipsToAlbumPresenter, didSucceededToAdding isSucceeded: Bool) {
        guard isSucceeded else { return }
        self.presenter.setEditing(false)
    }
}
