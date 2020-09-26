//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol AlbumListViewProtocol: AnyObject {
    func apply(_ albums: [Album])
    func showErrorMassage(_ message: String)
}

class AlbumListPresenter {
    private var cancellable: AnyCancellable?
    private var albumListQuery: AlbumListQuery? {
        didSet {
            self.cancellable = self.albumListQuery?.albums
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] albumQueries in
                    self?.view?.apply(albumQueries.map({ $0.album.value }))
                })
        }
    }

    private let storage: ClipStorageProtocol
    private let queryService: ClipQueryServiceProtocol
    private let logger: TBoxLoggable

    weak var view: AlbumListViewProtocol?

    // MARK: - Lifecycle

    init(storage: ClipStorageProtocol, queryService: ClipQueryServiceProtocol, logger: TBoxLoggable) {
        self.storage = storage
        self.queryService = queryService
        self.logger = logger
    }

    // MARK: - Methods

    func setup() {
        switch self.queryService.queryAllAlbums() {
        case let .success(query):
            self.albumListQuery = query

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read albums. (code: \(error.rawValue))"))
            self.view?.showErrorMassage("\(L10n.albumListViewErrorAtReadAlbums)\n(\(error.makeErrorCode())")
        }
    }

    func addAlbum(title: String) {
        if case let .failure(error) = self.storage.create(albumWithTitle: title) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add album. (code: \(error.rawValue))"))
            self.view?.showErrorMassage("\(L10n.albumListViewErrorAtAddAlbum)\n(\(error.makeErrorCode())")
        }
    }

    func deleteAlbum(_ album: Album) {
        if case let .failure(error) = self.storage.delete(album) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to delete album. (code: \(error.rawValue))"))
            self.view?.showErrorMassage("\(L10n.albumListViewErrorAtDeleteAlbum)\n(\(error.makeErrorCode())")
        }
    }

    func readThumbnailImageData(for album: Album) -> Data? {
        guard let clip = album.clips.first, let clipItem = clip.items.first else {
            return nil
        }

        switch self.storage.readThumbnailData(of: clipItem) {
        case let .success(data):
            return data

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read image. (code: \(error.rawValue))"))
            self.view?.showErrorMassage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
            return nil
        }
    }

    deinit {
        self.cancellable?.cancel()
    }
}
