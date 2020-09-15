//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class AddingTagsToClipsViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: AddingTagsToClipsPresenter
    private lazy var alertContainer = AddingAlert(configuration: .init(title: "新規タグ",
                                                                       message: "追加するタグの名前を入力してください",
                                                                       placeholder: "タグ名"),
                                                  baseView: self)

    @IBOutlet var collectionView: TagCollectionView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: AddingTagsToClipsPresenter) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.presenter.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupNavigationBar()

        self.presenter.reload()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        self.collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Methods

    private func setupNavigationBar() {
        self.navigationItem.title = "タグを選択"

        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAdd))
        let saveItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.didTapSave))

        self.navigationItem.leftBarButtonItem = addItem
        self.navigationItem.rightBarButtonItem = saveItem
    }

    @objc
    func didTapAdd() {
        self.alertContainer.present { [weak self] action in
            switch action {
            case let .saved(text: tag):
                self?.presenter.addTag(tag)

            default:
                // NOP
                break
            }
        }
    }

    @objc
    func didTapSave() {
        self.presenter.updateClipsByAddingTags()
    }
}

extension AddingTagsToClipsViewController: AddingTagsToClipsViewProtocol {
    // MARK: - AddingTagsToClipsViewProtocol

    func reload() {
        self.collectionView.reloadData()
    }

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func closeView(completion: @escaping () -> Void) {
        self.dismiss(animated: true, completion: completion)
    }
}

extension AddingTagsToClipsViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.presenter.selectTag(at: indexPath.row)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.presenter.deselectTag(at: indexPath.row)
    }
}

extension AddingTagsToClipsViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.presenter.tags.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionView.cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? TagCollectionViewCell else { return dequeuedCell }
        guard self.presenter.tags.indices.contains(indexPath.row) else { return dequeuedCell }

        let target = self.presenter.tags[indexPath.row]
        cell.title = target

        let shouldSelect = self.presenter.selectedTags.contains(where: { $0 == target })
        if shouldSelect {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
        cell.isSelected = shouldSelect

        return cell
    }
}

extension AddingTagsToClipsViewController: UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard self.presenter.tags.indices.contains(indexPath.row) else { return .zero }
        let preferredSize = TagCollectionViewCell.preferredSize(for: self.presenter.tags[indexPath.row])
        return CGSize(width: fmin(preferredSize.width, collectionView.frame.width - 16 * 2), height: preferredSize.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 16, bottom: 16, right: 16)
    }
}