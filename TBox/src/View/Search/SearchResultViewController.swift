//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class SearchResultViewController: UIViewController, ClipsListPreviewable {
    typealias Factory = ViewControllerFactory
    typealias Presenter = SearchResultPresenterProxy

    let factory: Factory
    let presenter: Presenter

    @IBOutlet var collectionView: ClipsCollectionView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: SearchResultPresenterProxy) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.presenter.set(view: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupCollectionView()
        self.setupNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateAppearance()
    }

    // MARK: - Methods

    private func updateAppearance() {
        self.navigationController?.navigationBar.prefersLargeTitles = false
    }

    // MARK: CollectionView

    private func setupCollectionView() {
        if let layout = self.collectionView?.collectionViewLayout as? ClipCollectionLayout {
            layout.delegate = self
        }
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
        let button = RoundedButton()
        button.setTitle("編集", for: .normal)
        button.addTarget(self, action: #selector(self.didTapEdit), for: .touchUpInside)

        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: button)
        ]
    }

    @objc func didTapEdit() {
        // self.collectionView.setContentOffset(self.collectionView.contentOffset, animated: false)
        // let viewController = self.factory.makeTopClipsListEditViewController(clips: self.presenter.clips,
        //                                                                      initialOffset: self.collectionView.contentOffset,
        //                                                                      delegate: self)
        // self.present(viewController, animated: false, completion: nil)
    }
}

extension SearchResultViewController: SearchResultViewProtocol {
    // MARK: - SearchResultViewProtocol

    func reload() {
        self.collectionView.reloadData()
    }

    func showErrorMassage(_ message: String) {
        print(message)
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

extension SearchResultViewController: ClipPreviewPresentingViewController {}

extension SearchResultViewController: ClipsListSynchronizableDelegate {
    // MARK: - ClipsListSynchronizableDelegate

    func clipsListSynchronizable(_ synchronizable: ClipsListSynchronizable, updatedClipsTo clips: [Clip]) {
        self.presenter.replaceClips(by: clips)
    }

    func clipsListSynchronizable(_ synchronizable: ClipsListSynchronizable, updatedContentOffset offset: CGPoint) {
        self.collectionView.contentOffset = offset
    }
}
