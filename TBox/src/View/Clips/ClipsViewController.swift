//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class ClipsViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: ClipsPresenter
    private let transitionController: ClipPreviewTransitionControllerProtocol

    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var collectionView: ClipsCollectionView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: ClipsPresenter, transitionController: ClipPreviewTransitionControllerProtocol) {
        self.factory = factory
        self.presenter = presenter
        self.transitionController = transitionController
        super.init(nibName: nil, bundle: nil)

        self.addBecomeActiveNotification()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.removeBecomeActiveNotification()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let layout = self.collectionView?.collectionViewLayout as? ClipCollectionLayout {
            layout.delegate = self
        }

        self.presenter.view = self
        self.presenter.reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateNavigationBarAppearance()
    }

    // MARK: - Methods

    private func updateNavigationBarAppearance() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
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

    @objc func didBecomeActive() {
        self.presenter.reload()
    }
}

extension ClipsViewController: ClipsViewProtocol {
    // MARK: - ClipsViewProtocol

    func startLoading() {
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }

    func endLoading() {
        self.indicator.isHidden = true
        self.indicator.stopAnimating()
    }

    func showErrorMassage(_ message: String) {
        let alert = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
    }

    func reload() {
        self.collectionView.reloadData()
    }
}

extension ClipsViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard self.presenter.clips.indices.contains(indexPath.row) else { return }
        let clip = self.presenter.clips[indexPath.row]

        let nextViewController = self.factory.makeClipDetailViewController(clip: clip)

        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
}

extension ClipsViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.presenter.clips.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: ClipsCollectionView.cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? ClipsCollectionViewCell else { return dequeuedCell }
        guard self.presenter.clips.indices.contains(indexPath.row) else { return cell }

        let clip = self.presenter.clips[indexPath.row]
        cell.primaryImage = {
            guard let item = clip.items.first(where: { $0.clipIndex == 0 }) else { return nil }
            guard let data = self.presenter.getImageData(forUrl: item.thumbnail.url, in: clip) else { return nil }
            return UIImage(data: data)!
        }()
        cell.secondaryImage = {
            guard let item = clip.items.first(where: { $0.clipIndex == 1 }) else { return nil }
            guard let data = self.presenter.getImageData(forUrl: item.thumbnail.url, in: clip) else { return nil }
            return UIImage(data: data)!
        }()
        cell.tertiaryImage = {
            guard let item = clip.items.first(where: { $0.clipIndex == 2 }) else { return nil }
            guard let data = self.presenter.getImageData(forUrl: item.thumbnail.url, in: clip) else { return nil }
            return UIImage(data: data)!
        }()

        return cell
    }
}

extension ClipsViewController: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        guard self.presenter.clips.indices.contains(indexPath.row) else { return .zero }
        let clip = self.presenter.clips[indexPath.row]

        guard let item = clip.items.first(where: { $0.clipIndex == 0 }) else { return .zero }
        let baseHeight = width * (CGFloat(item.thumbnail.size.height) / CGFloat(item.thumbnail.size.width))

        if clip.items.count > 1 {
            if clip.items.count > 2 {
                return baseHeight + ClipsCollectionViewCell.secondaryStickingOutMargin + ClipsCollectionViewCell.tertiaryStickingOutMargin
            } else {
                return baseHeight + ClipsCollectionViewCell.secondaryStickingOutMargin
            }
        } else {
            return baseHeight
        }
    }

    func collectionView(_ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat {
        return .zero
    }
}

extension ClipsViewController: ClipPreviewPresentingAnimatorDataSource {
    // MARK: - ClipPreviewAnimatorDataSource

    func animatingCell(_ animator: ClipPreviewAnimator) -> ClipsCollectionViewCell? {
        guard let selectedIndexPath = self.collectionView.indexPathsForSelectedItems?.first else {
            return nil
        }

        if !self.collectionView.indexPathsForVisibleItems.contains(selectedIndexPath) {
            self.collectionView.scrollToItem(at: selectedIndexPath, at: .centeredVertically, animated: false)
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
            self.collectionView.layoutIfNeeded()
        }

        guard let selectedCell = self.collectionView.cellForItem(at: selectedIndexPath) as? ClipsCollectionViewCell else {
            return nil
        }
        return selectedCell
    }
}
