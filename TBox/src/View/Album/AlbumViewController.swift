//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class AlbumViewController: UIViewController, ClipsListPreviewable {
    typealias Factory = ViewControllerFactory
    typealias Presenter = AlbumPresenterProxy

    let factory: Factory
    let presenter: Presenter

    @IBOutlet var collectionView: ClipsCollectionView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: AlbumPresenterProxy) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let layout = self.collectionView?.collectionViewLayout as? ClipCollectionLayout {
            layout.delegate = self
        }

        self.setupNavigationBar()

        self.presenter.set(view: self)
    }

    // MARK: - Methods

    private func setupNavigationBar() {
        self.navigationItem.title = self.presenter.album.title
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.view.backgroundColor = UIColor(named: "background_client")

        let button = RoundedButton()
        button.setTitle("編集", for: .normal)
        button.addTarget(self, action: #selector(self.didTapEdit), for: .touchUpInside)

        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: button)
        ]
    }

    @objc func didTapEdit() {
        self.collectionView.setContentOffset(self.collectionView.contentOffset, animated: false)
        let viewController = self.factory.makeAlbumEditViewController(album: self.presenter.album,
                                                                      initialOffset: self.collectionView.contentOffset,
                                                                      delegate: self)
        self.present(viewController, animated: false, completion: nil)
    }
}

extension AlbumViewController: AlbumViewProtocol {
    // MARK: - AlbumViewProtocol

    func reload() {
        self.collectionView.reloadData()
    }

    func showErrorMassage(_ message: String) {
        print(message)
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

extension AlbumViewController: ClipPreviewPresentingViewController {}

extension AlbumViewController: ClipsListSynchronizableDelegate {
    // MARK: - ClipsListSynchronizableDelegate

    func clipsListSynchronizable(_ synchronizable: ClipsListSynchronizable, updatedClipsTo clips: [Clip]) {
        self.presenter.replaceAlbum(by: self.presenter.album.updatingClips(to: clips))
    }

    func clipsListSynchronizable(_ synchronizable: ClipsListSynchronizable, updatedContentOffset offset: CGPoint) {
        self.collectionView.contentOffset = offset
    }
}
