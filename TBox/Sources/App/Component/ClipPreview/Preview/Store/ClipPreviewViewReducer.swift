//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import UIKit

typealias ClipPreviewViewDependency = HasPreviewLoader
    & HasClipQueryService

enum ClipPreviewViewReducer: Reducer {
    typealias Dependency = ClipPreviewViewDependency
    typealias State = ClipPreviewViewState
    typealias Action = ClipPreviewViewAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return readPreview(state: nextState, dependency: dependency)

        // MARK: Load Completion

        case let .imageLoaded(image):
            nextState.isLoading = false
            guard let image = image else { return (nextState, .none) }
            nextState.source = .image(image)
            return (nextState, .none)
        }
    }
}

// MARK: - Load Preview

extension ClipPreviewViewReducer {
    private static func readPreview(state: State, dependency: Dependency) -> (State, [Effect<Action>]) {
        var nextState = state

        if let preview = dependency.previewLoader.readCache(forImageId: state.imageId) {
            nextState.source = .image(preview)
            return (nextState, [])
        }

        if let preview = dependency.previewLoader.readThumbnail(forItemId: state.itemId) {
            nextState.source = .thumbnail(preview, originalSize: state.imageSize)
            nextState.isLoading = true
            let stream = Deferred {
                Future<Action?, Never> { promise in
                    dependency.previewLoader.loadPreview(forImageId: state.imageId) { image in
                        promise(.success(.imageLoaded(image)))
                    }
                }
            }
            return (nextState, [Effect(stream)])
        }

        if state.shouldLoadImageSynchronously {
            // クリップ一覧からプレビュー画面への遷移時に、サムネイルのキャッシュが既に揮発している
            // 可能性もある。そのような場合には遷移アニメーションが若干崩れてしまう
            // これを防ぐため、若干の操作のスムーズさを犠牲にして同期的に downsampling する
            let semaphore = DispatchSemaphore(value: 0)

            var result: UIImage?
            dependency.previewLoader.loadPreview(forImageId: state.imageId) { image in
                result = image
                semaphore.signal()
            }
            semaphore.wait()

            if let image = result {
                nextState.source = .image(image)
            }

            return (nextState, [])
        } else {
            nextState.isLoading = true
            let stream = Deferred {
                Future<Action?, Never> { promise in
                    dependency.previewLoader.loadPreview(forImageId: state.imageId) { image in
                        promise(.success(.imageLoaded(image)))
                    }
                }
            }
            return (nextState, [Effect(stream)])
        }
    }
}
