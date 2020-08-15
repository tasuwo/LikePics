//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

public protocol ClipTargetCollectionViewControllerDelegate: AnyObject {
    func didFinish(_ viewController: ClipTargetCollectionViewController)
}

public class ClipTargetCollectionViewController: UIViewController {
    private let presenter: ClipTargetCollectionViewPresenter

    private weak var delegate: ClipTargetCollectionViewControllerDelegate?

    @IBOutlet var collectionView: ClipSelectionCollectionView!
    @IBOutlet var indicator: UIActivityIndicatorView!

    // MARK: - Lifecycle

    public init(presenter: ClipTargetCollectionViewPresenter, delegate: ClipTargetCollectionViewControllerDelegate) {
        self.presenter = presenter
        self.delegate = delegate
        super.init(nibName: "ClipTargetCollectionViewController", bundle: Bundle(for: Self.self))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.presenter.view = self
        self.presenter.attachWebView(to: self.view)

        if let layout = self.collectionView?.collectionViewLayout as? ClipCollectionLayout {
            layout.delegate = self
        }

        self.setupNavBar()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presenter.findImages()
    }

    // MARK: - Methods

    private func setupNavBar() {
        self.navigationItem.title = "画像を選択"

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
        guard let collectionView = self.collectionView,
            let selectedIndices = collectionView.indexPathsForSelectedItems,
            !selectedIndices.isEmpty
        else {
            self.show(errorMessage: "No images selected.")
            return
        }

        let alert = UIAlertController(title: "保存", message: "\(selectedIndices.count)件のアイテムが選択されています。保存しますか？", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] action in
            guard let self = self else { return }

            self.startLoading()
            self.presenter.saveImages { isSucceeded in
                self.endLoading()

                guard isSucceeded else {
                    self.show(errorMessage: "Failed to save images.")
                    return
                }

                self.delegate?.didFinish(self)
            }
        }))

        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
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

    func showConfirmationForOverwrite() {
        let alert = UIAlertController(title: "", message: "既にクリップ済みのURLです。上書きしますか？", preferredStyle: .alert)

        alert.addAction(.init(title: "キャンセル", style: .cancel, handler: { [weak self] _ in
            // TODO: FIXME
            self?.dismiss(animated: true, completion: nil)
        }))

        alert.addAction(.init(title: "OK", style: .default, handler: { [weak self] _ in
            self?.presenter.enableOverwrite()
            self?.presenter.findImages()
        }))

        self.present(alert, animated: true, completion: nil)
    }

    func show(errorMessage: String) {
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func reload() {
        self.collectionView.reloadData()
    }

    func updateSelectionOrder(at index: Int, to order: Int) {
        guard let cell = self.collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? ClipSelectionCollectionViewCell else { return }
        cell.selectionOrder = order
    }

    func resetSelection() {
        self.collectionView.indexPathsForSelectedItems?
            .forEach { self.collectionView.deselectItem(at: $0, animated: false) }
        self.collectionView.visibleCells
            .compactMap { $0 as? ClipSelectionCollectionViewCell }
            .forEach { $0.selectionOrder = nil }
    }
}

extension ClipTargetCollectionViewController: UICollectionViewDelegate {
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

        if let header = self.collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader).compactMap({ $0 as? ClipSelectionCollectionViewHeader }).first {
            header.selectionCount = self.presenter.selectedIndices.count
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.presenter.deselectItem(at: indexPath.row)

        if let header = self.collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader).compactMap({ $0 as? ClipSelectionCollectionViewHeader }).first {
            header.selectionCount = self.presenter.selectedIndices.count
        }
    }
}

extension ClipTargetCollectionViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.presenter.webImages.count
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let dequeuedHeader = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                             withReuseIdentifier: type(of: self.collectionView).headerIdentifier,
                                                                             for: indexPath)
        guard let header = dequeuedHeader as? ClipSelectionCollectionViewHeader else { return dequeuedHeader }

        header.selectionCount = self.presenter.selectedIndices.count

        return header
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

extension ClipTargetCollectionViewController: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsCollectionLayoutDelegate

    public func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        guard self.presenter.webImages.indices.contains(indexPath.row) else { return .zero }
        let imageSize = self.presenter.webImages[indexPath.row].lowQualityImageSize
        return width * (imageSize.height / imageSize.width)
    }

    public func collectionView(_ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat {
        return ClipSelectionCollectionViewHeader.preferredHeight
    }
}
