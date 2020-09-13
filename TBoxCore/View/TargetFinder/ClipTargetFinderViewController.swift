//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import TBoxUIKit
import UIKit

public protocol ClipTargetFinderDelegate: AnyObject {
    func didCancel(_ viewController: ClipTargetFinderViewController)

    func didFinish(_ viewController: ClipTargetFinderViewController)
}

public class ClipTargetFinderViewController: UIViewController {
    private let presenter: ClipTargetFinderPresenter

    private weak var delegate: ClipTargetFinderDelegate?

    @IBOutlet var collectionView: ClipSelectionCollectionView!
    @IBOutlet var indicator: UIActivityIndicatorView!

    // MARK: - Lifecycle

    public init(presenter: ClipTargetFinderPresenter, delegate: ClipTargetFinderDelegate) {
        self.presenter = presenter
        self.delegate = delegate
        super.init(nibName: "ClipTargetFinderViewController", bundle: Bundle(for: Self.self))

        self.presenter.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.presenter.attachWebView(to: self.view)

        if let layout = self.collectionView?.collectionViewLayout as? ClipCollectionLayout {
            layout.delegate = self
        }

        self.setupNavigationBar()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presenter.findImages()
    }

    // MARK: - Methods

    private func setupNavigationBar() {
        self.navigationItem.title = L10n.clipTargetFinderViewTitle

        let itemCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
        self.navigationItem.setLeftBarButton(itemCancel, animated: false)

        let itemDone = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveAction))
        self.navigationItem.setRightBarButton(itemDone, animated: false)

        self.navigationItem.rightBarButtonItem?.isEnabled = false
    }

    @objc private func cancelAction() {
        self.delegate?.didCancel(self)
    }

    @objc private func saveAction() {
        self.presenter.saveSelectedImages()
    }
}

extension ClipTargetFinderViewController: ClipTargetFinderViewProtocol {
    // MARK: - ClipTargetFinderViewProtocol

    func startLoading() {
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }

    func endLoading() {
        self.indicator.isHidden = true
        self.indicator.stopAnimating()
    }

    func reloadList() {
        self.collectionView.reloadData()
    }

    func showConfirmationForOverwrite() {
        let alert = UIAlertController(title: "",
                                      message: L10n.clipTargetFinderViewOverwriteAlertBody,
                                      preferredStyle: .alert)

        alert.addAction(
            .init(title: L10n.clipTargetFinderViewOverwriteAlertCancel,
                  style: .cancel,
                  handler: { [weak self] _ in
                      guard let self = self else { return }
                      self.delegate?.didCancel(self)
                  })
        )

        alert.addAction(
            .init(title: L10n.clipTargetFinderViewOverwriteAlertOk,
                  style: .default,
                  handler: { [weak self] _ in
                      self?.presenter.enableOverwrite()
                      self?.presenter.findImages()
                  })
        )

        self.present(alert, animated: true, completion: nil)
    }

    func show(errorMessage: String) {
        let alert = UIAlertController(title: L10n.clipTargetFinderViewErrorAlertTitle,
                                      message: errorMessage,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: L10n.clipTargetFinderViewErrorAlertOk,
                              style: .default,
                              handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func updateSelectionOrder(at index: Int, to order: Int) {
        guard let cell = self.collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? ClipSelectionCollectionViewCell else { return }
        cell.selectionOrder = order
    }

    func updateDoneButton(isEnabled: Bool) {
        self.navigationItem.rightBarButtonItem?.isEnabled = isEnabled
    }

    func resetSelection() {
        self.collectionView.indexPathsForSelectedItems?
            .forEach { self.collectionView.deselectItem(at: $0, animated: false) }
        self.collectionView.visibleCells
            .compactMap { $0 as? ClipSelectionCollectionViewCell }
            .forEach { $0.selectionOrder = nil }
    }

    func notifySavedImagesSuccessfully() {
        self.delegate?.didFinish(self)
    }
}

extension ClipTargetFinderViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return self.presenter.webImages.indices.contains(indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return self.presenter.webImages.indices.contains(indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return self.presenter.webImages.indices.contains(indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.presenter.selectItem(at: indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.presenter.deselectItem(at: indexPath.row)
    }
}

extension ClipTargetFinderViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.presenter.webImages.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: type(of: self.collectionView).cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? ClipSelectionCollectionViewCell else { return dequeuedCell }
        guard self.presenter.webImages.indices.contains(indexPath.row) else { return cell }

        cell.imageUrl = self.presenter.webImages[indexPath.row].lowQualityImageUrl
        if let indexInSelection = self.presenter.selectedIndices.firstIndex(of: indexPath.row) {
            cell.selectionOrder = indexInSelection + 1
        }

        return cell
    }
}

extension ClipTargetFinderViewController: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsCollectionLayoutDelegate

    public func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        guard self.presenter.webImages.indices.contains(indexPath.row) else { return .zero }
        let imageSize = self.presenter.webImages[indexPath.row].lowQualityImageSize
        return width * (imageSize.height / imageSize.width)
    }

    public func collectionView(_ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat {
        return .zero
    }
}
