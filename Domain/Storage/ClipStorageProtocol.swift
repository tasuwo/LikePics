//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum ClipStorageError: Error {
    case duplicated
    case notFound
    case invalidParameter
    case internalError
}

public protocol ClipStorageProtocol {
    func create(clip: Clip) -> Result<Void, ClipStorageError>

    func readAllClips() -> Result<[Clip], ClipStorageError>

    func readClip(ofUrl url: URL) -> Result<Clip, ClipStorageError>

    func updateWebImages(inClipOfUrl url: URL, to webImages: [WebImage]) -> Result<Clip, ClipStorageError>

    func removeClip(ofUrl url: URL) -> Result<Clip, ClipStorageError>
}
