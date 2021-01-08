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

    func bind(view: ClipCollectionViewProtocol, propagator: ClipCollectionStatePropagable) {
        self.bind(dependency: self.viewModel, view: view, propagator: propagator)
    }

    // MARK: Privates

    private func bind(dependency: Dependency, view: ClipCollectionViewProtocol, propagator: ClipCollectionStatePropagable) {
        // MARK: Inputs

        propagator.clipsCount
            .sink { dependency.inputs.clipsCount.send($0) }
            .store(in: &self.cancellableBag)

        propagator.selectionsCount
            .sink { dependency.inputs.selectedClipsCount.send($0) }
            .store(in: &self.cancellableBag)

        propagator.currentOperation
            .sink { dependency.inputs.operation.send($0) }
            .store(in: &self.cancellableBag)

        // MARK: Outputs

        dependency.outputs.leftItems
            .compactMap { [weak self] items in
                guard let self = self else { return nil }
                return items
                    .compactMap { self.makeBarButtonItem(for: $0) }
                    .reversed()
            }
            .assign(to: \.leftBarButtonItems, on: view.navigationItem)
            .store(in: &self.cancellableBag)

        dependency.outputs.rightItems
            .compactMap { [weak self] items in
                guard let self = self else { return nil }
                return items
                    .compactMap { self.makeBarButtonItem(for: $0) }
                    .reversed()
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

    private func makeBarButtonItem(for navigationItem: ClipCollection.NavigationItem) -> UIBarButtonItem {
        let customView: UIView = {
            switch navigationItem {
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
        }()
        let item = UIBarButtonItem(customView: customView)
        item.isEnabled = navigationItem.isEnabled
        return item
    }
}
