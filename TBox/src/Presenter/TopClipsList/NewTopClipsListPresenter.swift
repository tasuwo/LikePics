//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol NewTopClipsListViewProtocol: AnyObject {
    func apply(_ clips: [Clip])
    func apply(selection: Set<Clip>)
    func presentPreview(for clip: Clip)
    func setEditing(_ editing: Bool)
    func showErrorMessage(_ message: String)
}

protocol NewTopClipsListPresenterProtocol {
    var clips: [Clip] { get }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data?

    func setup(with view: NewTopClipsListViewProtocol)
    func setEditing(_ editing: Bool)
    func select(clipId: Clip.Identity)
    func deselect(clipId: Clip.Identity)
    func selectAll()
    func deselectAll()
    func deleteSelectedClips()
    func hideSelectedClips()
    func unhideSelectedClips()
}

class NewTopClipsListPresenter {
    private let storage: ClipStorageProtocol
    private let queryService: ClipQueryServiceProtocol
    private let logger: TBoxLoggable

    private var cancellable: AnyCancellable?
    private var clipsQuery: ClipListQuery?

    private(set) var clips: [Clip] = [] {
        didSet {
            self.view?.apply(clips)
        }
    }

    private var selectedClips: [Clip] {
        return self.selections
            .compactMap { selection in
                return self.clips.first(where: { selection == $0.identity })
            }
    }

    private var selections: Set<Clip.Identity> = .init() {
        didSet {
            self.view?.apply(selection: Set(self.selectedClips))
        }
    }

    private var isEditing: Bool = false {
        didSet {
            self.selections = []
            self.view?.setEditing(self.isEditing)
        }
    }

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
            self.cancellable = query.clips
                .sink(receiveCompletion: { _ in }, receiveValue: { clips in
                    self.clips = clips

                    let newClips = Set(clips.map { $0.identity })
                    if !self.selections.isSubset(of: newClips) {
                        self.selections = self.selections.subtracting(self.selections.subtracting(newClips))
                    }
                })

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read albums. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtReadClips)\n(\(error.makeErrorCode())")
        }
    }

    func setEditing(_ editing: Bool) {
        self.isEditing = editing
    }

    func select(clipId: Clip.Identity) {
        if self.isEditing {
            self.selections.insert(clipId)
        } else {
            self.selections = Set([clipId])
            // TODO:
            self.view?.presentPreview(for: self.selectedClips.first(where: { $0.identity == clipId })!)
        }
    }

    func selectAll() {
        guard self.isEditing else { return }
        self.selections = Set(self.clips.map { $0.identity })
    }

    func deselect(clipId: Clip.Identity) {
        guard self.selections.contains(clipId) else { return }
        self.selections.remove(clipId)
    }

    func deselectAll() {
        self.selections = []
    }

    func deleteSelectedClips() {
        if case let .failure(error) = self.storage.delete(self.selectedClips) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read image. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.isEditing = false
    }

    func hideSelectedClips() {
        if case let .failure(error) = self.storage.update(self.selectedClips, byHiding: true) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read image. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.isEditing = false
    }

    func unhideSelectedClips() {
        if case let .failure(error) = self.storage.update(self.selectedClips, byHiding: false) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read image. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.isEditing = false
    }
}

extension NewTopClipsListPresenter: ClipsListNavigationPresenterDataSource {
    // MARK: - ClipsListNavigationPresenterDataSource

    func clipsCount(_ presenter: ClipsListNavigationItemsPresenter) -> Int {
        return self.clips.count
    }

    func selectedClipsCount(_ presenter: ClipsListNavigationItemsPresenter) -> Int {
        return self.selections.count
    }
}

extension NewTopClipsListPresenter: ClipsListToolBarItemsPresenterDataSouce {
    // MARK: - ClipsListToolBarItemsPresenterDataSouce

    func selectedClipsCount(_ presenter: ClipsListToolBarItemsPresenter) -> Int {
        return self.selections.count
    }
}
