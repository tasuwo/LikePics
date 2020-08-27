//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class SearchResultEditViewController: UIViewController, ClipsListEditable, ClipsListSynchronizable {
    typealias Factory = ViewControllerFactory
    typealias Presenter = SearchResultEditPresenterProxy

    let factory: Factory
    let presenter: Presenter

    private let initialOffset: CGPoint
    private var isOffsetInitialized: Bool = false

    weak var delegate: ClipsListSynchronizableDelegate?

    @IBOutlet var collectionView: ClipsCollectionView!

    // MARK: - Lifecycle

    init(factory: Factory,
         presenter: SearchResultEditPresenterProxy,
         initialOffset: CGPoint,
         delegate: ClipsListSynchronizableDelegate)
    {
        self.factory = factory
        self.presenter = presenter
        self.initialOffset = initialOffset
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)

        self.presenter.set(view: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let layout = self.collectionView?.collectionViewLayout as? ClipCollectionLayout {
            layout.delegate = self
        }

        self.setupCollectionView()
        self.setupNavigationBar()
        self.setupToolBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !self.isOffsetInitialized {
            self.isOffsetInitialized = true
            self.collectionView.setContentOffset(self.initialOffset, animated: false)
        }
    }

    // MARK: - Methods

    private func setupCollectionView() {
        self.collectionView.allowsMultipleSelection = true
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()

        let button = RoundedButton()
        button.setTitle("キャンセル", for: .normal)
        button.addTarget(self, action: #selector(self.didTapEdit), for: .touchUpInside)

        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: button)
        ]
    }

    @objc func didTapEdit() {
        self.collectionView.setContentOffset(self.collectionView.contentOffset, animated: false)
        self.dismiss(animated: false, completion: nil)
    }

    // MARK: ToolBar

    private func setupToolBar() {
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let addToAlbumItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAddToAlbum))
        let removeItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(self.didTapRemove))

        self.setToolbarItems([addToAlbumItem, flexibleItem, removeItem], animated: false)
        self.navigationController?.setToolbarHidden(false, animated: false)
    }

    @objc func didTapAddToAlbum() {
        self.presenter.addAllToAlbum()
    }

    @objc func didTapRemove() {
        let alert = UIAlertController(title: "", message: "選択中の画像を全て削除しますか？", preferredStyle: .alert)

        alert.addAction(.init(title: "削除", style: .destructive, handler: { [weak self] _ in
            self?.presenter.deleteAll()
        }))
        alert.addAction(.init(title: "キャンセル", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
}

extension SearchResultEditViewController: SearchResultEditViewProtocol {
    // MARK: - SearchResultEditViewProtocol

    func showErrorMassage(_ message: String) {
        let alert = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
    }

    func reload() {
        self.collectionView.reloadData()
    }

    func deselectAll() {
        self.collectionView.indexPathsForSelectedItems?.forEach {
            self.collectionView.deselectItem(at: $0, animated: false)
        }
    }

    func presentAlbumSelectionView(for clips: [Clip]) {
        let viewController = self.factory.makeAddingClipsToAlbumViewController(clips: clips, delegate: self.presenter)
        self.present(viewController, animated: true, completion: nil)
    }

    func endEditing() {
        self.delegate?.clipsListSynchronizable(self, updatedClipsTo: self.presenter.clips)
        self.dismiss(animated: false, completion: nil)
    }
}

extension SearchResultEditViewController: UICollectionViewDelegate {
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

extension SearchResultEditViewController: UIScrollViewDelegate {
    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollViewDidScroll(self, scrollView)
    }
}

extension SearchResultEditViewController: UICollectionViewDataSource {
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

extension SearchResultEditViewController: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsCollectionLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        return self.collectionView(self, collectionView, photoHeightForWidth: width, atIndexPath: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat {
        return self.collectionView(self, collectionView, heightForHeaderAtIndexPath: indexPath)
    }
}
