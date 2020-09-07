//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class AlbumViewController: UIViewController, ClipsListViewController {
    typealias Factory = ViewControllerFactory
    typealias Presenter = AlbumPresenterProxy

    let factory: Factory
    let presenter: Presenter

    @IBOutlet var collectionView: ClipsCollectionView!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: AlbumPresenterProxy) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.presenter.set(view: self)
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

        self.presenter.setup()
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
        self.updateNavigationBar(for: self.presenter.isEditing)
    }

    private func updateNavigationBar(for isEditing: Bool) {
        self.navigationController?.navigationBar.prefersLargeTitles = !isEditing
    }

    @objc func didTapEdit() {
        self.setEditing(true, animated: true)
    }

    @objc func didTapCancel() {
        self.setEditing(false, animated: true)
    }

    @objc func didTapSave() {
        self.presenter.updateAlbumTitle()
        self.setEditing(false, animated: true)
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

    @objc func didTapAddToAlbum() {
        self.presenter.addAllToAlbum()
    }

    @objc func didTapRemove() {
        let alert = UIAlertController(title: "", message: "選択中の画像を削除しますか？", preferredStyle: .alert)

        alert.addAction(.init(title: "アルバムから削除", style: .destructive, handler: { [weak self] _ in
            self?.presenter.deleteFromAlbum()
        }))
        alert.addAction(.init(title: "完全に削除", style: .destructive, handler: { [weak self] _ in
            self?.presenter.deleteAll()
        }))
        alert.addAction(.init(title: "キャンセル", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }

    // MARK: UIViewController (Override)

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.presenter.setEditing(editing)
        self.updateCollectionView(for: editing)

        self.updateNavigationBar(for: editing)
        self.updateToolBar(for: editing)
    }
}

extension AlbumViewController: UITextFieldDelegate {
    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.tapGestureRecognizer.isEnabled = true
        self.navigationItem.hidesBackButton = true
        self.presenter.setTitleEditing(true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.tapGestureRecognizer.isEnabled = false
        self.navigationItem.hidesBackButton = false
        self.presenter.setTitleEditing(false)
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.presenter.edit(title: "")
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let nsString = textField.text as NSString?
        if let updatedText = nsString?.replacingCharacters(in: range, with: string) {
            self.presenter.edit(title: updatedText)
        }
        return true
    }
}

extension AlbumViewController: AlbumViewProtocol {
    // MARK: - AlbumViewProtocol

    func setNavigationItems(_ items: [AlbumViewNavigationItem]) {
        defer {
            self.navigationItem.titleView?.invalidateIntrinsicContentSize()
        }

        guard !items.isEmpty else {
            self.navigationItem.setRightBarButtonItems([], animated: false)
            return
        }

        let spacingItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.setRightBarButtonItems(items.map { $0.convertToBarButtonItem(for: self) } + [spacingItem], animated: false)
    }

    func setNavigationTitle(_ title: String, asEditable: Bool) {
        self.navigationItem.titleView = {
            guard asEditable else { return nil }

            let textField = AlbumTitleEditTextField()

            textField.translatesAutoresizingMaskIntoConstraints = false
            let desiredHeight = title.sizeOnLabel(for: textField.font).height + textField.padding.top + textField.padding.bottom
            textField.heightAnchor.constraint(equalToConstant: desiredHeight).isActive = true

            textField.placeholder = title
            textField.delegate = self

            return textField
        }()
        self.navigationItem.title = self.presenter.album.title
    }

    func reload() {
        self.collectionView.reloadData()
    }

    func deselectAll() {
        self.collectionView.indexPathsForSelectedItems?.forEach {
            self.collectionView.deselectItem(at: $0, animated: false)
        }
    }

    func endEditing() {
        self.setEditing(false, animated: true)
    }

    func presentPreviewView(for clip: Clip) {
        let nextViewController = self.factory.makeClipPreviewViewController(clip: clip)
        self.present(nextViewController, animated: true, completion: nil)
    }

    func presentAlbumSelectionView(for clips: [Clip]) {
        let viewController = self.factory.makeAddingClipsToAlbumViewController(clips: clips, delegate: self.presenter)
        self.present(viewController, animated: true, completion: nil)
    }

    func showErrorMassage(_ message: String) {
        let alert = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
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

private extension AlbumViewNavigationItem {
    func convertToBarButtonItem(for target: AlbumViewController) -> UIBarButtonItem {
        switch self {
        case .cancel:
            let button = RoundedButton()
            button.setTitle("キャンセル", for: .normal)
            button.addTarget(target, action: #selector(target.didTapCancel), for: .touchUpInside)
            return UIBarButtonItem(customView: button)
        case .edit:
            let button = RoundedButton()
            button.setTitle("編集", for: .normal)
            button.addTarget(target, action: #selector(target.didTapEdit), for: .touchUpInside)
            return UIBarButtonItem(customView: button)
        case .save:
            let button = RoundedButton()
            button.setTitle("保存", for: .normal)
            button.addTarget(target, action: #selector(target.didTapSave), for: .touchUpInside)
            return UIBarButtonItem(customView: button)
        }
    }
}

private class AlbumTitleEditTextField: PaddingTextField {
    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.backgroundColor = .systemBackground
        self.layer.cornerRadius = 8
        self.padding = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        self.clearButtonMode = .always
    }

    // MARK: - UIView (Overrides)

    override var intrinsicContentSize: CGSize {
        return .init(width: CGFloat.greatestFiniteMagnitude, height: UIView.noIntrinsicMetric)
    }
}

private extension String {
    func sizeOnLabel(for font: UIFont?) -> CGSize {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = font
        label.text = self
        return label.sizeThatFits(.init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
    }
}
