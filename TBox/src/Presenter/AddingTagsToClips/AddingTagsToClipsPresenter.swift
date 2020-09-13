//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol AddingTagsToClipsPresenterDelegate: AnyObject {
    func addingTagsToClipsPresenter(_ presenter: AddingTagsToClipsPresenter, didSucceededToAddingTag: Bool)
}

protocol AddingTagsToClipsViewProtocol: AnyObject {
    func reload()
    func closeView(completion: @escaping () -> Void)
    func showErrorMessage(_ message: String)
}

class AddingTagsToClipsPresenter {
    private(set) var tags: [String] = []

    private let clips: [Clip]
    private let storage: ClipStorageProtocol

    weak var delegate: AddingTagsToClipsPresenterDelegate?
    weak var view: AddingTagsToClipsViewProtocol?

    // MARK: - Lifecycle

    init(clips: [Clip], storage: ClipStorageProtocol) {
        self.clips = clips
        self.storage = storage
    }

    // MARK: - Methods

    private static func resolveErrorMessage(_ error: ClipStorageError) -> String {
        // TODO:
        return "Error"
    }

    func reload() {
        guard let view = self.view else { return }

        switch self.storage.readAllTags() {
        case let .success(tags):
            self.tags = tags
            view.reload()

        case let .failure(error):
            view.showErrorMessage(Self.resolveErrorMessage(error))
        }
    }

    func addTag(_ name: String) {
        guard let view = self.view else { return }

        switch self.storage.create(tagWithName: name) {
        case .success:
            self.reload()

        case let .failure(error):
            view.showErrorMessage(Self.resolveErrorMessage(error))
        }
    }

    func updateClips(byAddingTagAt index: Int) {
        guard let view = self.view else { return }
        guard self.tags.indices.contains(index) else { return }

        let tag = self.tags[index]
        switch self.storage.update(self.clips, byAddingTags: [tag]) {
        case .success:
            view.closeView { [weak self] in
                guard let self = self else { return }
                self.delegate?.addingTagsToClipsPresenter(self, didSucceededToAddingTag: true)
            }

        case let .failure(error):
            self.delegate?.addingTagsToClipsPresenter(self, didSucceededToAddingTag: false)
            view.showErrorMessage(Self.resolveErrorMessage(error))
        }
    }
}
