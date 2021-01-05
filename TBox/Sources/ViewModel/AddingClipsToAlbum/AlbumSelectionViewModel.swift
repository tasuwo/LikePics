//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import UIKit

protocol AlbumSelectionViewModelType {
    var inputs: AlbumSelectionViewModelInputs { get }
    var outputs: AlbumSelectionViewModelOutputs { get }
}

protocol AlbumSelectionViewModelInputs {
    var addedAlbum: PassthroughSubject<String, Never> { get }
    var selectedAlbum: PassthroughSubject<Album.Identity, Never> { get }
}

protocol AlbumSelectionViewModelOutputs {
    var albums: CurrentValueSubject<[Album], Never> { get }
    var errorMessage: PassthroughSubject<String, Never> { get }
    var displayEmptyMessage: CurrentValueSubject<Bool, Never> { get }
    var close: PassthroughSubject<Void, Never> { get }
}

protocol AlbumSelectionPresenterDelegate: AnyObject {
    func albumSelectionPresenter(_ presenter: AlbumSelectionViewModel, didSelectAlbumHaving albumId: Album.Identity, withContext context: Any?)
}

class AlbumSelectionViewModel: AlbumSelectionViewModelType,
    AlbumSelectionViewModelInputs,
    AlbumSelectionViewModelOutputs
{
    // MARK: - Properties

    // MARK: AlbumSelectionViewModelType

    var inputs: AlbumSelectionViewModelInputs { self }
    var outputs: AlbumSelectionViewModelOutputs { self }

    // MARK: AlbumSelectionViewModelInputs

    let addedAlbum: PassthroughSubject<String, Never> = .init()
    let selectedAlbum: PassthroughSubject<Album.Identity, Never> = .init()

    // MARK: AlbumSelectionViewModelOutputs

    let albums: CurrentValueSubject<[Album], Never>
    let errorMessage: PassthroughSubject<String, Never> = .init()
    let displayEmptyMessage: CurrentValueSubject<Bool, Never> = .init(false)
    let close: PassthroughSubject<Void, Never> = .init()

    // MARK: Privates

    private let query: AlbumListQuery
    private let context: Any?
    private let clipCommandService: ClipCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var cancellableBag = Set<AnyCancellable>()

    weak var delegate: AlbumSelectionPresenterDelegate?

    // MARK: - Lifecycle

    init(query: AlbumListQuery,
         context: Any?,
         clipCommandService: ClipCommandServiceProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.context = context
        self.clipCommandService = clipCommandService
        self.settingStorage = settingStorage
        self.logger = logger

        self.albums = .init(query.albums.value)

        self.bind()
    }
}

extension AlbumSelectionViewModel {
    // MARK: - Bind

    private func bind() {
        self.query.albums
            .catch { _ -> AnyPublisher<[Album], Never> in
                return Just([Album]()).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
            .combineLatest(self.settingStorage.showHiddenItems)
            .sink { [weak self] albums, showHiddenItems in
                guard let self = self else { return }

                let newAlbums: [Album]
                if showHiddenItems {
                    newAlbums = albums
                } else {
                    newAlbums = albums
                        .filter { !$0.isHidden }
                        .map { $0.removingHiddenClips() }
                }

                self.albums.send(newAlbums)
                self.displayEmptyMessage.send(albums.isEmpty)
            }
            .store(in: &self.cancellableBag)

        self.addedAlbum
            .sink { [weak self] title in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.create(albumWithTitle: title) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to add album. (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.albumListViewErrorAtAddAlbum)
                }
            }
            .store(in: &self.cancellableBag)

        self.selectedAlbum
            .sink { [weak self] albumId in
                guard let self = self else { return }
                self.delegate?.albumSelectionPresenter(self, didSelectAlbumHaving: albumId, withContext: self.context)
                self.close.send(())
            }
            .store(in: &self.cancellableBag)
    }
}
