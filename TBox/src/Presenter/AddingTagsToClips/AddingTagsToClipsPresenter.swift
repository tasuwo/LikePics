//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol AddingTagsToClipsPresenterDelegate: AnyObject {
    func addingTagsToClipsPresenter(_ presenter: AddingTagsToClipsPresenter, didSucceededToAddingTagsTo clip: Clip?)
}

protocol AddingTagsToClipsViewProtocol: AnyObject {
    func reload()
    func closeView(completion: @escaping () -> Void)
    func showErrorMessage(_ message: String)
}

class AddingTagsToClipsPresenter {
    enum FailureContext {
        case reload
        case addTag
        case addTagsToClip
    }

    private(set) var tags: [String] = []
    private(set) var selectedTags: [String] = []

    private let clips: [Clip]
    private let storage: ClipStorageProtocol

    weak var delegate: AddingTagsToClipsPresenterDelegate?
    weak var view: AddingTagsToClipsViewProtocol?

    // MARK: - Lifecycle

    init(clips: [Clip], storage: ClipStorageProtocol) {
        self.clips = clips
        self.storage = storage

        // TODO: 選択済みのタグは選択済みにすべきかどうか
    }

    // MARK: - Methods

    private static func resolveErrorMessage(error: ClipStorageError, context: FailureContext) -> String {
        let message: String = {
            switch context {
            case .reload:
                return L10n.tagListViewErrorAtReadTags

            case .addTag:
                return L10n.tagListViewErrorAtAddTag

            case .addTagsToClip:
                return L10n.tagListViewErrorAtAddTagsToClip
            }
        }()
        return message + "\n(\(error.makeErrorCode()))"
    }

    func reload() {
        guard let view = self.view else { return }

        switch self.storage.readAllTags() {
        case let .success(tags):
            self.tags = tags
            view.reload()

        case let .failure(error):
            view.showErrorMessage(Self.resolveErrorMessage(error: error, context: .reload))
        }
    }

    func addTag(_ name: String) {
        guard let view = self.view else { return }

        switch self.storage.create(tagWithName: name) {
        case .success:
            self.reload()

        case let .failure(error):
            view.showErrorMessage(Self.resolveErrorMessage(error: error, context: .addTag))
        }
    }

    func selectTag(at index: Int) {
        self.selectedTags.append(self.tags[index])
    }

    func deselectTag(at index: Int) {
        let target = self.tags[index]
        self.selectedTags.removeAll(where: { $0 == target })
    }

    func updateClipsByAddingTags() {
        guard let view = self.view else { return }

        switch self.storage.update(self.clips, byAddingTags: self.selectedTags) {
        case let .success(clips):
            view.closeView { [weak self] in
                guard let self = self else { return }
                self.delegate?.addingTagsToClipsPresenter(self, didSucceededToAddingTagsTo: clips.first)
            }

        case let .failure(error):
            self.delegate?.addingTagsToClipsPresenter(self, didSucceededToAddingTagsTo: nil)
            view.showErrorMessage(Self.resolveErrorMessage(error: error, context: .addTagsToClip))
        }
    }
}
