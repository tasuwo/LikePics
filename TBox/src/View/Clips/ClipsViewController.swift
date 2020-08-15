//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class ClipsViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: ClipsPresenter
    private let transitionController: ClipPreviewTransitionControllerProtocol

    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var collectionView: ClipsCollectionView!

    private(set) var selectedIndexPath: IndexPath?

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // TODO: FIXME
        self.presenter.reload()
    }

    // MARK: - Methods

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

        self.selectedIndexPath = indexPath

        let clip = self.presenter.clips[indexPath.row]

        let nextViewController = self.factory.makeClipPreviewViewController(clip: clip)

        self.present(nextViewController, animated: true, completion: nil)
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
            guard let data = self.presenter.getImageData(for: .primary, in: clip) else { return nil }
            return UIImage(data: data)!
        }()
        cell.secondaryImage = {
            guard let data = self.presenter.getImageData(for: .secondary, in: clip) else { return nil }
            return UIImage(data: data)!
        }()
        cell.tertiaryImage = {
            guard let data = self.presenter.getImageData(for: .tertiary, in: clip) else { return nil }
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

        switch (clip.primaryItem, clip.secondaryItem, clip.tertiaryItem) {
        case let (.some(item), .none, .none):
            return width * (CGFloat(item.thumbnail.size.height) / CGFloat(item.thumbnail.size.width))
        case let (.some(item), .some(_), .none):
            return width * (CGFloat(item.thumbnail.size.height) / CGFloat(item.thumbnail.size.width))
                + ClipsCollectionViewCell.secondaryStickingOutMargin
        case let (.some(item), .some(_), .some(_)):
            return width * (CGFloat(item.thumbnail.size.height) / CGFloat(item.thumbnail.size.width))
                + ClipsCollectionViewCell.secondaryStickingOutMargin
                + ClipsCollectionViewCell.tertiaryStickingOutMargin
        case let (.some(item), _, _):
            return width * (CGFloat(item.thumbnail.size.height) / CGFloat(item.thumbnail.size.width))
        default:
            return width
        }
    }

    func collectionView(_ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat {
        return .zero
    }
}
