//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class TagListViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: TagListPresenter
    private lazy var alertContainer = AddingAlert(configuration: .init(title: "新規タグ",
                                                                       message: "追加するタグの名前を入力してください",
                                                                       placeholder: "タグ名"),
                                                  baseView: self)

    @IBOutlet var collectionView: TagCollectionView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: TagListPresenter) {
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

        self.setupAppearance()
        self.updateNavigationBar(for: self.isEditing)

        self.presenter.reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.presenter.reload()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = false
        self.title = "タグ"
    }

    // MARK: NavigationBar

    private func updateNavigationBar(for isEditing: Bool) {
        if isEditing {
            let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.didTapCancel))
            let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.didTapDone))
            self.navigationItem.leftBarButtonItem = cancelItem
            self.navigationItem.rightBarButtonItem = doneItem
        } else {
            let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAdd))
            let deleteItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(self.didTapDelete))
            self.navigationItem.leftBarButtonItem = addItem
            self.navigationItem.rightBarButtonItem = deleteItem
        }
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
    func didTapDone() {
        let alert = UIAlertController(title: "タグを削除する",
                                      message: "選択中のタグを全て削除しますか？クリップに紐づいたタグの場合は、クリップからタグが削除されます",
                                      preferredStyle: .actionSheet)

        alert.addAction(.init(title: "削除", style: .destructive, handler: { [weak self] _ in
            guard let indices = self?.collectionView.indexPathsForSelectedItems?.map({ $0.row }) else { return }
            self?.presenter.delete(at: indices)
        }))
        alert.addAction(.init(title: "キャンセル", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }

    @objc
    func didTapCancel() {
        self.setEditing(false, animated: true)
    }

    @objc
    func didTapDelete() {
        self.setEditing(true, animated: true)
    }

    // MARK: UIViewController (Override)

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.updateNavigationBar(for: editing)

        self.collectionView
            .visibleCells
            .map { $0 as? TagCollectionViewCell }
            .forEach { $0?.displayMode = editing ? .deletion : .normal }
        self.collectionView
            .indexPathsForSelectedItems?
            .forEach { self.collectionView.deselectItem(at: $0, animated: false) }
        self.collectionView.allowsMultipleSelection = editing
    }
}

extension TagListViewController: TagListViewProtocol {
    // MARK: - TagListViewProtocol

    func reload() {
        self.collectionView.reloadData()
    }

    func showSearchReult(for clips: [Clip], withContext context: SearchContext) {
        self.show(self.factory.makeSearchResultViewController(context: context, clips: clips), sender: nil)
    }

    func showErrorMessage(_ message: String) {
        // TODO:
        print(message)
    }

    func endEditing() {
        self.setEditing(false, animated: true)
    }
}

extension TagListViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !self.isEditing else { return }
        self.presenter.select(at: indexPath.row)
    }
}

extension TagListViewController: UICollectionViewDataSource {
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
        cell.displayMode = self.isEditing ? .deletion : .normal

        return cell
    }
}

extension TagListViewController: UICollectionViewDelegateFlowLayout {
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
