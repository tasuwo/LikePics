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
    func shouldCancel(_ provider: ClipCollectionToolBarProvider)
    func shouldMerge(_ provider: ClipCollectionToolBarProvider)
    func shouldShare(_ provider: ClipCollectionToolBarProvider)
}

class ClipCollectionToolBarProvider {
    typealias Dependency = ClipCollectionToolBarViewModelType

    private var flexibleItem: UIBarButtonItem!
    private var addItem: UIBarButtonItem!
    private var deleteItem: UIBarButtonItem!
    private var removeFromAlbum: UIBarButtonItem!
    private var changeVisibilityItem: UIBarButtonItem!
    private var shareItem: UIBarButtonItem!
    private var mergeItem: UIBarButtonItem!

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

    func bind(view: ClipCollectionViewProtocol, propagator: ClipCollectionStatePropagable) {
        self.bind(dependency: self.viewModel, view: view, propagator: propagator)
    }

    // MARK: Privates

    private func bind(dependency: Dependency, view: ClipCollectionViewProtocol, propagator: ClipCollectionStatePropagable) {
        // MARK: Inputs

        propagator.selections
            .map { $0.count }
            .sink { dependency.inputs.selectedClipsCount.send($0) }
            .store(in: &self.cancellableBag)

        propagator.operation
            .sink { dependency.inputs.operation.send($0) }
            .store(in: &self.cancellableBag)

        propagator.startShareForToolBar
            .sink { [weak self, weak view] data in
                guard let self = self else { return }
                let controller = UIActivityViewController(activityItems: data, applicationActivities: nil)
                controller.popoverPresentationController?.barButtonItem = self.shareItem
                controller.completionWithItemsHandler = { _, _, _, _ in
                    self.delegate?.shouldCancel(self)
                }
                view?.present(controller, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        // MARK: Outputs

        dependency.outputs.isHidden
            .sink { [weak view] isHidden in view?.navigationController?.setToolbarHidden(isHidden, animated: true) }
            .store(in: &self.cancellableBag)

        dependency.outputs.items
            .map { [weak self] items in
                self?.resolveBarButtonItems(for: items)
            }
            .sink { [weak view] items in view?.setToolbarItems(items, animated: true) }
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
    private func didTapDelete(item: UIBarButtonItem) {
        self.alertPresentable?.presentDeleteAlert(at: item, targetCount: self.viewModel.outputs.selectionCount.value) { [weak self] in
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
    private func didTapChangeVisibility(item: UIBarButtonItem) {
        self.alertPresentable?.presentUpdateVisibilityAlert(at: item, targetCount: self.viewModel.outputs.selectionCount.value) { [weak self] in
            guard let self = self else { return }
            self.delegate?.shouldHide(self)
        } unhideAction: { [weak self] in
            guard let self = self else { return }
            self.delegate?.shouldUnhide(self)
        }
    }

    @objc
    private func didTapShare() {
        self.delegate?.shouldShare(self)
    }

    @objc
    private func didTapMerge() {
        self.delegate?.shouldMerge(self)
    }

    private func setupButtons() {
        self.flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil,
                                            action: nil)
        self.addItem = UIBarButtonItem(barButtonSystemItem: .add,
                                       target: self,
                                       action: #selector(self.didTapAddToAlbum))
        self.deleteItem = UIBarButtonItem(barButtonSystemItem: .trash,
                                          target: self,
                                          action: #selector(self.didTapDelete))
        self.removeFromAlbum = UIBarButtonItem(barButtonSystemItem: .trash,
                                               target: self,
                                               action: #selector(self.didTapRemoveFromAlbum))
        self.changeVisibilityItem = UIBarButtonItem(image: UIImage(systemName: "eye"),
                                                    style: .plain,
                                                    target: self,
                                                    action: #selector(self.didTapChangeVisibility(item:)))
        self.shareItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(self.didTapShare))
        self.mergeItem = UIBarButtonItem(image: UIImage(systemName: "rectangle.and.paperclip"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(self.didTapMerge))
    }

    private func resolveBarButtonItems(for items: [ClipCollection.ToolBarItem]) -> [UIBarButtonItem] {
        return items.reduce(into: [UIBarButtonItem]()) { array, item in
            if !array.isEmpty { array.append(self.flexibleItem) }
            array.append(self.resolveBarButtonItem(for: item))
        }
    }

    private func resolveBarButtonItem(for item: ClipCollection.ToolBarItem) -> UIBarButtonItem {
        let buttonItem: UIBarButtonItem = {
            switch item.kind {
            case .add:
                return self.addItem

            case .delete:
                return self.deleteItem

            case .removeFromAlbum:
                return self.removeFromAlbum

            case .changeVisibility:
                return self.changeVisibilityItem

            case .share:
                return self.shareItem

            case .merge:
                return self.mergeItem
            }
        }()
        buttonItem.isEnabled = item.isEnabled
        return buttonItem
    }
}
