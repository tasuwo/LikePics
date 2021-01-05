//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

class AlbumListNavigationBarProvider {
    typealias Dependency = AlbumListNavigationBarViewModelType

    // MARK: - Properties

    // MARK: Dependency

    private let viewModel: Dependency

    // MARK: Buttons

    private let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    private let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: nil, action: nil)
    private let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)

    // MARK: Outputs

    let didTapAdd: PassthroughSubject<Void, Never> = .init()
    let didTapEdit: PassthroughSubject<Void, Never> = .init()
    let didTapDone: PassthroughSubject<Void, Never> = .init()

    // MARK: Privates

    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(viewModel: AlbumListNavigationBarViewModelType) {
        self.viewModel = viewModel
        self.setupButtons()
    }

    // MARK: - Methods

    // MARK: Bind

    func bind(view: UIViewController, propagator: AlbumListViewModelOutputs) {
        // Inputs

        propagator.operation
            .sink { [weak self] operation in self?.viewModel.inputs.operation.send(operation) }
            .store(in: &self.cancellableBag)

        propagator.albums
            .map { $0.count }
            .sink { [weak self] count in self?.viewModel.inputs.albumsCount.send(count) }
            .store(in: &self.cancellableBag)

        // Outputs

        self.viewModel.outputs.leftItems
            .compactMap { [weak self] items in
                guard let self = self else { return nil }
                return items
                    .compactMap { self.resolveBarButtonItem(for: $0) }
                    .reversed()
            }
            .assign(to: \.leftBarButtonItems, on: view.navigationItem)
            .store(in: &self.cancellableBag)

        self.viewModel.outputs.rightItems
            .compactMap { [weak self] items in
                guard let self = self else { return nil }
                return items
                    .compactMap { self.resolveBarButtonItem(for: $0) }
                    .reversed()
            }
            .assign(to: \.rightBarButtonItems, on: view.navigationItem)
            .store(in: &self.cancellableBag)
    }

    // MARK: Configurations

    private func setupButtons() {
        self.addButton.primaryAction = UIAction { [weak self] _ in self?.didTapAdd.send(()) }
        self.editButton.primaryAction = UIAction { [weak self] _ in self?.didTapEdit.send(()) }
        self.doneButton.primaryAction = UIAction { [weak self] _ in self?.didTapDone.send(()) }
    }

    // MARK: Resolver

    private func resolveBarButtonItem(for item: AlbumList.NavigationItem) -> UIBarButtonItem {
        switch item {
        case .done:
            return self.doneButton

        case let .add(isEnabled: isEnabled):
            self.addButton.isEnabled = isEnabled
            return addButton

        case let .edit(isEnabled: isEnabled):
            self.editButton.isEnabled = isEnabled
            return self.editButton
        }
    }
}
