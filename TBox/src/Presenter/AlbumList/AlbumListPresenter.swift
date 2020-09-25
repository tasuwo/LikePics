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
    enum FailureContext {
        case readAlbums
        case addAlbum
        case deleteAlbum
        case readImage
    }

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

    private static func resolveErrorMessage(for error: ClipStorageError, at context: FailureContext) -> String {
        let message: String = {
            switch context {
            case .readAlbums:
                return L10n.albumListViewErrorAtReadAlbums

            case .addAlbum:
                return L10n.albumListViewErrorAtAddAlbum

            case .deleteAlbum:
                return L10n.albumListViewErrorAtDeleteAlbum

            case .readImage:
                return L10n.albumListViewErrorAtReadImageData
            }
        }()
        return message + "\n(\(error.makeErrorCode()))"
    }

    func setup() {
        switch self.queryService.queryAllAlbums() {
        case let .success(query):
            self.albumListQuery = query

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read albums. (code: \(error.rawValue))"))
            self.view?.showErrorMassage(Self.resolveErrorMessage(for: error, at: .readImage))
        }
    }

    func addAlbum(title: String) {
        if case let .failure(error) = self.storage.create(albumWithTitle: title) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add album. (code: \(error.rawValue))"))
            self.view?.showErrorMassage(Self.resolveErrorMessage(for: error, at: .addAlbum))
        }
    }

    func deleteAlbum(_ album: Album) {
        if case let .failure(error) = self.storage.delete(album) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to delete album. (code: \(error.rawValue))"))
            self.view?.showErrorMassage(Self.resolveErrorMessage(for: error, at: .deleteAlbum))
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
            self.view?.showErrorMassage(Self.resolveErrorMessage(for: error, at: .readImage))
            return nil
        }
    }
}
