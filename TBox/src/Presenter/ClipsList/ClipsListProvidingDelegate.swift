//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipsListProvidingDelegate: AnyObject {
    func clipsListProviding(_ provider: ClipsListProviding, didUpdateClipsTo clips: [Clip])
    func clipsListProviding(_ provider: ClipsListProviding, didUpdateSelectedIndicesTo indices: [Int])
    func clipsListProviding(_ provider: ClipsListProviding, didUpdateEditingStateTo isEditing: Bool)
    func clipsListProviding(_ provider: ClipsListProviding, didTapClip clip: Clip, at index: Int)
    func clipsListProviding(_ provider: ClipsListProviding, failedToReadClipsWith error: ClipStorageError)
    func clipsListProviding(_ provider: ClipsListProviding, failedToDeleteClipsWith error: ClipStorageError)
    func clipsListProviding(_ provider: ClipsListProviding, failedToGetImageDataWith error: ClipStorageError)
}
