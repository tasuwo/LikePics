//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipsListDelegate: AnyObject {
    func clipsListProviding(_ list: ClipsListProtocol, didUpdateClipsTo clips: [Clip])
    func clipsListProviding(_ list: ClipsListProtocol, didUpdateSelectedIndicesTo indices: [Int])
    func clipsListProviding(_ list: ClipsListProtocol, didUpdateEditingStateTo isEditing: Bool)
    func clipsListProviding(_ list: ClipsListProtocol, didTapClip clip: Clip, at index: Int)
    func clipsListProviding(_ list: ClipsListProtocol, failedToReadClipsWith error: ClipStorageError)
    func clipsListProviding(_ list: ClipsListProtocol, failedToDeleteClipsWith error: ClipStorageError)
    func clipsListProviding(_ list: ClipsListProtocol, failedToGetImageDataWith error: ClipStorageError)
}
