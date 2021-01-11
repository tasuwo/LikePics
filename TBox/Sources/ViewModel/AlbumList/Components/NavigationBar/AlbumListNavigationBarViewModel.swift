//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

protocol AlbumListNavigationBarViewModelType {
    var inputs: AlbumListNavigationBarViewModelInputs { get }
    var outputs: AlbumListNavigationBarViewModelOutputs { get }
}

protocol AlbumListNavigationBarViewModelInputs {
    var albumsCount: CurrentValueSubject<Int, Never> { get }
    var operation: CurrentValueSubject<AlbumList.Operation, Never> { get }
}

protocol AlbumListNavigationBarViewModelOutputs {
    var leftItems: CurrentValueSubject<[AlbumList.NavigationItem], Never> { get }
    var rightItems: CurrentValueSubject<[AlbumList.NavigationItem], Never> { get }
}

class AlbumListNavigationBarViewModel: AlbumListNavigationBarViewModelType,
    AlbumListNavigationBarViewModelInputs,
    AlbumListNavigationBarViewModelOutputs
{
    // MARK: - Properties

    // MARK: AlbumListNavigationBarViewModelType

    var inputs: AlbumListNavigationBarViewModelInputs { self }
    var outputs: AlbumListNavigationBarViewModelOutputs { self }

    // MARK: AlbumListNavigationBarViewModelInputs

    let albumsCount: CurrentValueSubject<Int, Never> = .init(0)
    let operation: CurrentValueSubject<AlbumList.Operation, Never> = .init(.none)

    // MARK: AlbumListNavigationBarViewModelOutputs

    let leftItems: CurrentValueSubject<[AlbumList.NavigationItem], Never> = .init([])
    let rightItems: CurrentValueSubject<[AlbumList.NavigationItem], Never> = .init([])

    // MARK: Privates

    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    init() {
        // MARK: Bind

        self.operation
            .combineLatest(self.albumsCount)
            .sink { [weak self] mode, albumsCount in
                switch mode {
                case .none:
                    self?.rightItems.send([.edit(isEnabled: albumsCount > 0)])
                    self?.leftItems.send([.add(isEnabled: true)])

                case .editing:
                    self?.rightItems.send([.done])
                    self?.leftItems.send([.add(isEnabled: false)])
                }
            }
            .store(in: &self.subscriptions)
    }
}
