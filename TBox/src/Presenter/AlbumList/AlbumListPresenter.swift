//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain

protocol AlbumListViewProtocol: AnyObject {
    func showErrorMassage(_ message: String)
    func reload()
}

class AlbumListPresenter {
    enum FailureContext {
        case readAlbums
        case addAlbum
        case deleteAlbum
        case readImage
    }

    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    private(set) var albums: [Album] = []

    weak var view: AlbumListViewProtocol?

    // MARK: - Lifecycle

    init(storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.storage = storage
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

    func reload() {
        guard let view = self.view else { return }

        switch self.storage.readAllAlbums() {
        case let .success(albums):
            self.albums = albums.sorted(by: { $0.registeredDate > $1.registeredDate })
            view.reload()

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read albums. (code: \(error.rawValue))"))
            view.showErrorMassage(Self.resolveErrorMessage(for: error, at: .readImage))
        }
    }

    func addAlbum(title: String) {
        guard let view = self.view else { return }

        switch self.storage.create(albumWithTitle: title) {
        case let .success(album):
            self.albums = (albums + [album]).sorted(by: { $0.registeredDate > $1.registeredDate })
            view.reload()

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add album. (code: \(error.rawValue))"))
            view.showErrorMassage(Self.resolveErrorMessage(for: error, at: .addAlbum))
        }
    }

    func deleteAlbum(at index: Int) {
        guard let view = self.view, self.albums.indices.contains(index) else { return }
        let album = self.albums[index]

        switch self.storage.delete(album) {
        case .success:
            self.albums.remove(at: index)
            view.reload()

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to delete album. (code: \(error.rawValue))"))
            view.showErrorMassage(Self.resolveErrorMessage(for: error, at: .deleteAlbum))
        }
    }

    func getThumbnailImageData(at index: Int) -> Data? {
        guard self.albums.indices.contains(index),
            let clip = self.albums[index].clips.first,
            let clipItem = clip.items.first
        else {
            return nil
        }

        switch self.storage.readImageData(having: clipItem.thumbnail.url, forClipHaving: clip.url) {
        case let .success(data):
            return data

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read image. (code: \(error.rawValue))"))
            self.view?.showErrorMassage(Self.resolveErrorMessage(for: error, at: .readImage))
            return nil
        }
    }
}
