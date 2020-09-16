//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain

protocol ClipsListProvidingDelegate: AnyObject {
    func clipsListProviding(_ provider: ClipsListProviding, didUpdateClipsTo clips: [Clip])
    func clipsListProviding(_ provider: ClipsListProviding, didUpdateEditingStateTo isEditing: Bool)
    func clipsListProviding(_ provider: ClipsListProviding, didUpdateSelectedIndices indices: [Int])
    func clipsListProviding(_ provider: ClipsListProviding, didTapClip clip: Clip, at index: Int)
    func clipsListProviding(_ provider: ClipsListProviding, failedToReadClipsWith error: ClipStorageError)
    func clipsListProviding(_ provider: ClipsListProviding, failedToDeleteClipsWith error: ClipStorageError)
    func clipsListProviding(_ provider: ClipsListProviding, failedToGetImageDataWith error: ClipStorageError)
}

protocol ClipsListProviding {
    var clips: [Clip] { get set }
    var selectedClips: [Clip] { get }
    var selectedIndices: [Int] { get }
    var isEditing: Bool { get }

    func set(delegate: ClipsListProvidingDelegate)

    // TODO:
    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data?

    func reload()

    func setEditing(_ isEditing: Bool)
    func select(at index: Int)
    func deselect(at index: Int)

    func deleteSelectedClips()
}

class ClipsList: ClipsListProviding {
    var clips: [Clip] = [] {
        didSet {
            self.delegate?.clipsListProviding(self, didUpdateClipsTo: self.clips)
        }
    }

    private(set) var selectedClips: [Clip] = [] {
        didSet {
            self.delegate?.clipsListProviding(self, didUpdateSelectedIndices: self.selectedIndices)
        }
    }

    private(set) var isEditing: Bool = false {
        didSet {
            self.delegate?.clipsListProviding(self, didUpdateEditingStateTo: self.isEditing)
        }
    }

    var selectedIndices: [Int] {
        return self.selectedClips.compactMap { selectedClip in
            self.clips.firstIndex(where: { $0.url == selectedClip.url })
        }
    }

    weak var delegate: ClipsListProvidingDelegate?

    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    // MARK: - Lifecycle

    init(storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.storage = storage
        self.logger = logger
    }

    // MARK: - ClipsListProviding

    func set(delegate: ClipsListProvidingDelegate) {
        self.delegate = delegate
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

        switch self.storage.readImageData(having: clipItem.thumbnail.url, forClipHaving: clip.url) {
        case let .success(data):
            return data

        case let .failure(error):
            self.delegate?.clipsListProviding(self, failedToGetImageDataWith: error)
            return nil
        }
    }

    func reload() {
        switch self.storage.readAllClips() {
        case let .success(clips):
            self.clips = clips.sorted(by: { $0.registeredDate > $1.registeredDate })

        case let .failure(error):
            self.delegate?.clipsListProviding(self, failedToReadClipsWith: error)
        }
    }

    func setEditing(_ editing: Bool) {
        if self.isEditing != editing {
            self.selectedClips = []
        }
        self.isEditing = editing
    }

    func select(at index: Int) {
        guard self.clips.indices.contains(index) else { return }
        let clip = self.clips[index]

        if self.isEditing {
            guard !self.selectedClips.contains(where: { $0.url == clip.url }) else {
                return
            }
            self.selectedClips.append(clip)
        } else {
            self.selectedClips = [clip]
            self.delegate?.clipsListProviding(self, didTapClip: clip, at: index)
        }
    }

    func deselect(at index: Int) {
        guard self.clips.indices.contains(index) else { return }
        let clip = self.clips[index]

        if self.isEditing {
            guard let index = self.selectedClips.firstIndex(where: { $0.url == clip.url }) else {
                return
            }
            self.selectedClips.remove(at: index)
        } else {
            self.selectedClips = []
        }
    }

    func deleteSelectedClips() {
        if case let .failure(error) = self.storage.delete(self.selectedClips) {
            self.delegate?.clipsListProviding(self, failedToDeleteClipsWith: error)
            return
        }

        let newClips: [Clip] = self.clips.compactMap { clip in
            if self.selectedClips.contains(where: { clip.url == $0.url }) { return nil }
            return clip
        }
        self.clips = newClips

        self.selectedClips = []

        self.isEditing = false
    }
}
