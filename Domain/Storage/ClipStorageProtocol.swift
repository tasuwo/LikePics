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
    // MARK: Create

    func create(clip: Clip, withData data: [(URL, Data)], forced: Bool) -> Result<Void, ClipStorageError>

    func create(albumWithTitle: String) -> Result<Album, ClipStorageError>

    // MARK: Read

    func read(clipOfUrl url: URL) -> Result<Clip, ClipStorageError>

    func read(imageDataOfUrl url: URL, forClipOfUrl clipUrl: URL) -> Result<Data, ClipStorageError>

    func readAllClips() -> Result<[Clip], ClipStorageError>

    func readAllAlbums() -> Result<[Album], ClipStorageError>

    func search(clipsByKeywords: [String]) -> Result<[Clip], ClipStorageError>

    // MARK: Update

    func update(clipItemsInClip clip: Clip, to items: [ClipItem]) -> Result<Clip, ClipStorageError>

    func update(byAddingClip clipUrl: URL, toAlbum album: Album) -> Result<Void, ClipStorageError>

    func update(byAddingClips clipUrls: [URL], toAlbum album: Album) -> Result<Void, ClipStorageError>

    func update(byDeletingClips clipUrls: [URL], fromAlbum album: Album) -> Result<Void, ClipStorageError>

    // MARK: Delete

    func delete(clip: Clip) -> Result<Clip, ClipStorageError>

    func delete(clips: [Clip]) -> Result<[Clip], ClipStorageError>

    func delete(clipItem: ClipItem) -> Result<ClipItem, ClipStorageError>
}

extension ClipStorageProtocol {
    public func create(clip: Clip, withData data: [(URL, Data)]) -> Result<Void, ClipStorageError> {
        self.create(clip: clip, withData: data, forced: false)
    }
}
