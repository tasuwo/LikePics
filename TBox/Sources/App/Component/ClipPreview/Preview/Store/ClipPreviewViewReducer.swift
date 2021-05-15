//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import UIKit

typealias ClipPreviewViewDependency = HasPreviewLoader
    & HasClipQueryService

struct ClipPreviewViewReducer: Reducer {
    typealias Dependency = ClipPreviewViewDependency
    typealias State = ClipPreviewViewState
    typealias Action = ClipPreviewViewAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return Self.readPreview(state: nextState, dependency: dependency)

        // MARK: Load Completion

        case let .imageLoaded(image):
            nextState.isDisplayingLoadingIndicator = false
            nextState.isUserInteractionEnabled = true
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
            nextState.isDisplayingLoadingIndicator = true
            nextState.isUserInteractionEnabled = false
            let stream = Deferred {
                Future<Action?, Never> { promise in
                    dependency.previewLoader.loadPreview(forImageId: state.imageId) { image in
                        promise(.success(.imageLoaded(image)))
                    }
                }
            }
            return (nextState, [Effect(stream)])
        }

        nextState.isDisplayingLoadingIndicator = true
        nextState.isUserInteractionEnabled = false
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
