//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol TopClipsListEditViewControllerDelegate: AnyObject {
    func topClipsListEditViewController(_ viewController: TopClipsListEditViewController, updatedContentOffset offset: CGPoint)
}

class TopClipsListEditViewController: UIViewController, ClipsListEditable {
    typealias Factory = ViewControllerFactory
    typealias Presenter = TopClipsListEditPresenterProxy

    let factory: Factory
    let presenter: Presenter

    private let initialOffset: CGPoint
    private var isOffsetInitialized: Bool = false
    private weak var delegate: TopClipsListEditViewControllerDelegate?

    @IBOutlet var collectionView: ClipsCollectionView!

    // MARK: - Lifecycle

    init(factory: Factory,
         presenter: TopClipsListEditPresenterProxy,
         initialOffset: CGPoint,
         delegate: TopClipsListEditViewControllerDelegate)
    {
        self.factory = factory
        self.presenter = presenter
        self.initialOffset = initialOffset
        self.delegate = delegate
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

        self.presenter.set(view: self)

        self.setupAppearance()
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

    // MARK: NavigationBar

    private func setupAppearance() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()

        let button = RoundedButton()
        button.setTitle("キャンセル", for: .normal)
        button.addTarget(self, action: #selector(self.didTapEdit), for: .touchUpInside)

        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: button)
        ]

        self.navigationController?.isToolbarHidden = false

        self.collectionView.allowsMultipleSelection = true
    }

    @objc func didTapEdit() {
        self.collectionView.setContentOffset(self.collectionView.contentOffset, animated: false)
        self.dismiss(animated: false, completion: nil)
    }
}

extension TopClipsListEditViewController: TopClipsListEditViewProtocol {
    // MARK: - TopClipsListEditViewProtocol

    func showErrorMassage(_ message: String) {
        let alert = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
    }
}

extension TopClipsListEditViewController: UICollectionViewDelegate {
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.topClipsListEditViewController(self, updatedContentOffset: self.collectionView.contentOffset)
    }
}

extension TopClipsListEditViewController: UICollectionViewDataSource {
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

extension TopClipsListEditViewController: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsCollectionLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        return self.collectionView(self, collectionView, photoHeightForWidth: width, atIndexPath: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat {
        return self.collectionView(self, collectionView, heightForHeaderAtIndexPath: indexPath)
    }
}
