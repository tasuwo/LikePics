//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

protocol ClipCollectionToolBarProviderDelegate: AnyObject {
    func shouldAddToAlbum(_ provider: ClipCollectionToolBarProvider)
    func shouldAddTags(_ provider: ClipCollectionToolBarProvider)
    func shouldDelete(_ provider: ClipCollectionToolBarProvider)
    func shouldRemoveFromAlbum(_ provider: ClipCollectionToolBarProvider)
    func shouldHide(_ provider: ClipCollectionToolBarProvider)
    func shouldUnhide(_ provider: ClipCollectionToolBarProvider)
}

class ClipCollectionToolBarProvider {
    typealias Dependency = ClipCollectionToolBarViewModelType

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var flexibleItem: UIBarButtonItem!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var addItem: UIBarButtonItem!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var removeItem: UIBarButtonItem!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var removeFromAlbum: UIBarButtonItem!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var hideItem: UIBarButtonItem!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var unhideItem: UIBarButtonItem!

    weak var alertPresentable: ClipCollectionAlertPresentable?
    weak var delegate: ClipCollectionToolBarProviderDelegate?

    private let viewModel: ClipCollectionToolBarViewModel
    private var cancellableBag: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    init(viewModel: ClipCollectionToolBarViewModel) {
        self.viewModel = viewModel
        self.setupButtons()
    }

    // MARK: - Methods

    func bind(view: ClipCollectionViewProtocol, viewModel: ClipCollectionViewModelType) {
        self.bind(dependency: self.viewModel, view: view, viewModel: viewModel)
    }

    // MARK: Privates

    private func bind(dependency: Dependency, view: ClipCollectionViewProtocol, viewModel: ClipCollectionViewModelType) {
        // MARK: Inputs

        viewModel.selections
            .map { $0.count }
            .sink { dependency.inputs.selectedClipsCount.send($0) }
            .store(in: &self.cancellableBag)

        viewModel.operation
            .sink { dependency.inputs.operation.send($0) }
            .store(in: &self.cancellableBag)

        // MARK: Outputs

        dependency.outputs.isHidden
            .sink { view.navigationController?.setToolbarHidden($0, animated: true) }
            .store(in: &self.cancellableBag)

        dependency.outputs.items
            .map { [weak self] items in
                items.compactMap { self?.resolveBarButtonItem(for: $0) }
            }
            .sink { view.setToolbarItems($0, animated: true) }
            .store(in: &self.cancellableBag)
    }

    @objc
    private func didTapAddToAlbum(item: UIBarButtonItem) {
        self.alertPresentable?.presentAddAlert(
            at: item,
            addToAlbumAction: { [weak self] in
                guard let self = self else { return }
                self.delegate?.shouldAddToAlbum(self)
            },
            addTagsAction: { [weak self] in
                guard let self = self else { return }
                self.delegate?.shouldAddTags(self)
            }
        )
    }

    @objc
    private func didTapRemove(item: UIBarButtonItem) {
        self.alertPresentable?.presentRemoveAlert(at: item, targetCount: self.viewModel.outputs.selectionCount.value) { [weak self] in
            guard let self = self else { return }
            self.delegate?.shouldDelete(self)
        }
    }

    @objc
    private func didTapRemoveFromAlbum(item: UIBarButtonItem) {
        self.alertPresentable?.presentRemoveFromAlbumAlert(
            at: item,
            targetCount: self.viewModel.outputs.selectionCount.value,
            deleteAction: { [weak self] in
                guard let self = self else { return }
                self.delegate?.shouldDelete(self)
            },
            removeFromAlbumAction: { [weak self] in
                guard let self = self else { return }
                self.delegate?.shouldRemoveFromAlbum(self)
            }
        )
    }

    @objc
    private func didTapHide(item: UIBarButtonItem) {
        self.alertPresentable?.presentHideAlert(at: item, targetCount: self.viewModel.outputs.selectionCount.value) { [weak self] in
            guard let self = self else { return }
            self.delegate?.shouldHide(self)
        }
    }

    @objc
    private func didTapUnhide() {
        self.delegate?.shouldUnhide(self)
    }

    private func setupButtons() {
        self.flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil,
                                            action: nil)
        self.addItem = UIBarButtonItem(barButtonSystemItem: .add,
                                       target: self,
                                       action: #selector(self.didTapAddToAlbum))
        self.removeItem = UIBarButtonItem(barButtonSystemItem: .trash,
                                          target: self,
                                          action: #selector(self.didTapRemove))
        self.removeFromAlbum = UIBarButtonItem(barButtonSystemItem: .trash,
                                               target: self,
                                               action: #selector(self.didTapRemoveFromAlbum))
        self.hideItem = UIBarButtonItem(image: UIImage(systemName: "eye.slash"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(self.didTapHide))
        self.unhideItem = UIBarButtonItem(image: UIImage(systemName: "eye"),
                                          style: .plain,
                                          target: self,
                                          action: #selector(self.didTapUnhide))
    }

    private func resolveBarButtonItem(for item: ClipCollection.ToolBarItem) -> UIBarButtonItem {
        switch item {
        case .spacer:
            return self.flexibleItem

        case .add:
            return self.addItem

        case .delete:
            return self.removeItem

        case .removeFromAlbum:
            return self.removeFromAlbum

        case .hide:
            return self.hideItem

        case .unhide:
            return self.unhideItem
        }
    }
}
