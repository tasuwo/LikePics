//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit
import UIKit

protocol ClipCollectionNavigationBarProviderDelegate: AnyObject {
    func didTapEditButton(_ provider: ClipCollectionNavigationBarProvider)
    func didTapCancelButton(_ provider: ClipCollectionNavigationBarProvider)
    func didTapSelectAllButton(_ provider: ClipCollectionNavigationBarProvider)
    func didTapDeselectAllButton(_ provider: ClipCollectionNavigationBarProvider)
    func didTapReorderButton(_ provider: ClipCollectionNavigationBarProvider)
    func didTapDoneButton(_ provider: ClipCollectionNavigationBarProvider)
}

class ClipCollectionNavigationBarProvider {
    typealias Dependency = ClipCollectionNavigationBarViewModelType

    private let cancelButton = RoundedButton()
    private let selectAllButton = RoundedButton()
    private let deselectAllButton = RoundedButton()
    private let selectButton = RoundedButton()
    private let reorderButton = RoundedButton()
    private let doneButton = RoundedButton()

    private let viewModel: Dependency

    private var cancellableBag: Set<AnyCancellable> = .init()

    weak var delegate: ClipCollectionNavigationBarProviderDelegate?

    // MARK: - Lifecycle

    init(viewModel: ClipCollectionNavigationBarViewModelType) {
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

        viewModel.clips
            .map { $0.count }
            .sink { dependency.inputs.clipsCount.send($0) }
            .store(in: &self.cancellableBag)

        viewModel.selections
            .map { $0.count }
            .sink { dependency.inputs.selectedClipsCount.send($0) }
            .store(in: &self.cancellableBag)

        viewModel.operation
            .sink { dependency.inputs.operation.send($0) }
            .store(in: &self.cancellableBag)

        // MARK: Outputs

        dependency.outputs.leftItems
            .receive(on: DispatchQueue.main)
            .map { [weak self] items in
                items.compactMap { leftItem -> UIBarButtonItem? in
                    guard let self = self else { return nil }
                    let item = UIBarButtonItem(customView: self.resolveCustomView(for: leftItem))
                    item.isEnabled = leftItem.isEnabled
                    return item
                }
            }
            .assign(to: \.leftBarButtonItems, on: view.navigationItem)
            .store(in: &self.cancellableBag)

        dependency.outputs.rightItems
            .receive(on: DispatchQueue.main)
            .map { [weak self] items in
                items.compactMap { rightItem -> UIBarButtonItem? in
                    guard let self = self else { return nil }
                    let item = UIBarButtonItem(customView: self.resolveCustomView(for: rightItem))
                    item.isEnabled = rightItem.isEnabled
                    return item
                }
            }
            .assign(to: \.rightBarButtonItems, on: view.navigationItem)
            .store(in: &self.cancellableBag)
    }

    @objc
    private func didTapEdit(_ sender: UIButton) {
        self.delegate?.didTapEditButton(self)
    }

    @objc
    private func didTapCancel(_ sender: UIButton) {
        self.delegate?.didTapCancelButton(self)
    }

    @objc
    private func didTapSelectAll(_ sender: UIButton) {
        self.delegate?.didTapSelectAllButton(self)
    }

    @objc
    private func didTapDeselectAll(_ sender: UIButton) {
        self.delegate?.didTapDeselectAllButton(self)
    }

    @objc
    private func didTapReorder(_ sender: UIButton) {
        self.delegate?.didTapReorderButton(self)
    }

    @objc
    private func didTapDone(_ sender: UIButton) {
        self.delegate?.didTapDoneButton(self)
    }

    private func setupButtons() {
        self.cancelButton.setTitle(L10n.confirmAlertCancel, for: .normal)
        self.cancelButton.addTarget(self, action: #selector(self.didTapCancel), for: .touchUpInside)

        self.selectAllButton.setTitle(L10n.clipsListRightBarItemForSelectAllTitle, for: .normal)
        self.selectAllButton.addTarget(self, action: #selector(self.didTapSelectAll), for: .touchUpInside)

        self.deselectAllButton.setTitle(L10n.clipsListRightBarItemForDeselectAllTitle, for: .normal)
        self.deselectAllButton.addTarget(self, action: #selector(self.didTapDeselectAll), for: .touchUpInside)

        self.selectButton.setTitle(L10n.clipsListRightBarItemForSelectTitle, for: .normal)
        self.selectButton.addTarget(self, action: #selector(self.didTapEdit), for: .touchUpInside)

        self.reorderButton.setTitle(L10n.clipsListRightBarItemForReorder, for: .normal)
        self.reorderButton.addTarget(self, action: #selector(self.didTapReorder), for: .touchUpInside)

        self.doneButton.setTitle(L10n.clipsListRightBarItemForDone, for: .normal)
        self.doneButton.addTarget(self, action: #selector(self.didTapDone(_:)), for: .touchUpInside)
    }

    private func resolveCustomView(for item: ClipCollection.NavigationItem) -> UIView {
        switch item {
        case .cancel:
            return self.cancelButton

        case .selectAll:
            return self.selectAllButton

        case .deselectAll:
            return self.deselectAllButton

        case .select:
            return self.selectButton

        case .reorder:
            return self.reorderButton

        case .done:
            return self.doneButton
        }
    }
}
