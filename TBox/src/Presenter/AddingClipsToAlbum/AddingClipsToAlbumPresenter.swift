//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain

protocol AddingClipsToAlbumPresenterDelegate: AnyObject {
    func addingClipsToAlbumPresenter(_ presenter: AddingClipsToAlbumPresenter, didSucceededToAdding isSucceeded: Bool)
}

protocol AddingClipsToAlbumViewProtocol: AnyObject {
    func showErrorMassage(_ message: String)
    func reload()
    func closeView(completion: @escaping () -> Void)
}

class AddingClipsToAlbumPresenter {
    enum FailureContext {
        case readAlbums
        case updateAlbum
    }

    weak var view: AddingClipsToAlbumViewProtocol?
    weak var delegate: AddingClipsToAlbumPresenterDelegate?

    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    private let sourceClips: [Clip]
    private(set) var albums: [Album] = []

    // MARK: - Lifecycle

    init(sourceClips: [Clip], storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.sourceClips = sourceClips
        self.storage = storage
        self.logger = logger
    }

    // MARK: - Methods

    private static func resolveErrorMessage(for error: ClipStorageError, at context: FailureContext) -> String {
        let message: String = {
            switch context {
            case .readAlbums:
                return L10n.addingClipsToAlbumViewErrorAtReadAlbums

            case .updateAlbum:
                return L10n.addingClipsToAlbumViewErrorAtUpdateAlbum
            }
        }()
        return message + "\n(\(error.makeErrorCode()))"
    }

    func reload() {
        guard let view = self.view else { return }

        switch self.storage.readAllAlbums() {
        case let .success(albums):
            self.albums = albums
            view.reload()

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read albums. (code: \(error.rawValue))"))
            view.showErrorMassage(Self.resolveErrorMessage(for: error, at: .readAlbums))
        }
    }

    func clipTo(albumAt index: Int) {
        guard self.albums.indices.contains(index) else { return }
        guard let view = self.view else { return }

        let album = self.albums[index]

        switch self.storage.update(album, byAddingClipsHaving: self.sourceClips.map { $0.url }) {
        case .success:
            view.closeView { [weak self] in
                guard let self = self else { return }
                self.delegate?.addingClipsToAlbumPresenter(self, didSucceededToAdding: true)
            }

        case let .failure(error):
            self.delegate?.addingClipsToAlbumPresenter(self, didSucceededToAdding: false)
            self.logger.write(ConsoleLog(level: .error, message: "Failed to update album. (code: \(error.rawValue))"))
            view.showErrorMassage(Self.resolveErrorMessage(for: error, at: .updateAlbum))
        }
    }
}
