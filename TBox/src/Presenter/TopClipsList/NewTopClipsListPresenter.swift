//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol NewTopClipsListViewProtocol: AnyObject {
    func apply(_ clips: [Clip])
    func showErrorMessage(_ message: String)
}

protocol NewTopClipsListPresenterProtocol {
    var clips: [Clip] { get }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data?

    func setup(with view: NewTopClipsListViewProtocol)
    func delete(_ clips: [Clip])
    func hide(_ clips: [Clip])
    func unhide(_ clips: [Clip])
}

class NewTopClipsListPresenter {
    private let storage: ClipStorageProtocol
    private let queryService: ClipQueryServiceProtocol
    private let logger: TBoxLoggable

    private var cancellable: AnyCancellable?
    private var clipsQuery: ClipListQuery?

    private weak var view: NewTopClipsListViewProtocol?

    // MARK: - Lifecycle

    init(storage: ClipStorageProtocol, queryService: ClipQueryServiceProtocol, logger: TBoxLoggable) {
        self.storage = storage
        self.queryService = queryService
        self.logger = logger
    }
}

extension NewTopClipsListPresenter: NewTopClipsListPresenterProtocol {
    // MARK: - NewTopClipsListPresenterProtocol

    var clips: [Clip] {
        return self.clipsQuery?.clips.value.map { $0.clip.value } ?? []
    }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data? {
        let nullableClipItem: ClipItem? = {
            switch layer {
            case .primary:
                return clip.primaryItem

            case .secondary:
                return clip.secondaryItem

            case .tertiary:
                return clip.tertiaryItem
            }
        }()
        guard let clipItem = nullableClipItem else { return nil }

        switch self.storage.readThumbnailData(of: clipItem) {
        case let .success(data):
            return data

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read albums. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtGetImageData)\n(\(error.makeErrorCode())")
            return nil
        }
    }

    func setup(with view: NewTopClipsListViewProtocol) {
        self.view = view

        switch self.queryService.queryAllClips() {
        case let .success(query):
            self.clipsQuery = query
            self.cancellable = query.clips
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] clipsQueries in
                    self?.view?.apply(clipsQueries.map({ $0.clip.value }))
                })

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read albums. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtReadClips)\n(\(error.makeErrorCode())")
        }
    }

    func delete(_ clips: [Clip]) {
        if case let .failure(error) = self.storage.delete(clips) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read image. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
        }
    }

    func hide(_ clips: [Clip]) {
        if case let .failure(error) = self.storage.update(clips, byHiding: true) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read image. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
        }
    }

    func unhide(_ clips: [Clip]) {
        if case let .failure(error) = self.storage.update(clips, byHiding: false) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read image. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
        }
    }
}
