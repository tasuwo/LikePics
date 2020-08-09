//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Kingfisher
import UIKit

class ClipTargetCollectionViewController: UIViewController {
    private let presenter: ClipTargetCollecitonViewPresenter

    @IBOutlet var collectionView: ClipTargetCollectionView!
    @IBOutlet var indicator: UIActivityIndicatorView!

    // MARK: - Lifecycle

    public init() {
        self.presenter = ClipTargetCollecitonViewPresenter()
        super.init(nibName: "ClipTargetCollectionViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.presenter.view = self
        self.presenter.attachWebView(to: self.view)

        if let layout = self.collectionView?.collectionViewLayout as? ClipCollectionLayout {
            layout.delegate = self
        }

        self.setupNavBar()

        guard let item = self.extensionContext?.inputItems.first as? NSExtensionItem else {
            // TODO: Error handling
            print("Error!!")
            return
        }
        self.presenter.findImages(fromItem: item)
    }

    // MARK: - Methods

    private func setupNavBar() {
        self.navigationItem.title = "Select Image!"

        let itemCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
        self.navigationItem.setLeftBarButton(itemCancel, animated: false)

        let itemDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        self.navigationItem.setRightBarButton(itemDone, animated: false)
    }

    @objc private func cancelAction() {
        let error = NSError(domain: "net.tasuwo.TBox", code: 0, userInfo: [NSLocalizedDescriptionKey: "An error description"])
        extensionContext?.cancelRequest(withError: error)
    }

    @objc private func doneAction() {
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
}

extension ClipTargetCollectionViewController: ClipTargetCollectionViewProtocol {
    // MARK: - ClipTargetCollectionViewProtocol

    func startLoading() {
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }

    func endLoading() {
        self.indicator.isHidden = true
        self.indicator.stopAnimating()
    }

    func show(errorMessage: String) {
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
        alert.present(self, animated: true, completion: nil)
    }

    func reload() {
        self.collectionView.reloadData()
    }
}

extension ClipTargetCollectionViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return self.presenter.imageUrls.indices.contains(indexPath.row)
    }

    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return self.presenter.imageUrls.indices.contains(indexPath.row)
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return self.presenter.imageUrls.indices.contains(indexPath.row)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let header = self.collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader).compactMap({ $0 as? ClipTargetCollectionViewHeader }).first else {
            return
        }
        header.selectionCount = self.collectionView.indexPathsForSelectedItems?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let header = self.collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader).compactMap({ $0 as? ClipTargetCollectionViewHeader }).first else {
            return
        }
        header.selectionCount = self.collectionView.indexPathsForSelectedItems?.count ?? 0
    }
}

extension ClipTargetCollectionViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.presenter.imageUrls.count
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let dequeuedHeader = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                             withReuseIdentifier: type(of: self.collectionView).headerIdentifier,
                                                                             for: indexPath)
        guard let header = dequeuedHeader as? ClipTargetCollectionViewHeader else { return dequeuedHeader }

        header.selectionCount = self.collectionView.indexPathsForSelectedItems?.count ?? 0

        return header
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: type(of: self.collectionView).cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? ClipTargetCollectionViewCell else { return dequeuedCell }
        guard self.presenter.imageUrls.indices.contains(indexPath.row) else { return cell }

        cell.imageUrl = self.presenter.imageUrls[indexPath.row]

        return cell
    }
}

extension ClipTargetCollectionViewController: ClipCollectionLayoutDelegate {
    // MARK: - ClipCollectionLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        self.presenter.resolveImageHeight(for: width, at: indexPath.row)
    }

    func collectionView(_ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat {
        return ClipTargetCollectionViewHeader.preferredHeight
    }
}
