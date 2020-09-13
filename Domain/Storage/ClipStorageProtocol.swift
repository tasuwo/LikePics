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

    func create(tagWithName name: String) -> Result<Tag, ClipStorageError>

    func create(albumWithTitle: String) -> Result<Album, ClipStorageError>

    // MARK: Read

    func readClip(having url: URL) -> Result<Clip, ClipStorageError>

    func readImageData(having url: URL, forClipHaving clipUrl: URL) -> Result<Data, ClipStorageError>

    func readAllClips() -> Result<[Clip], ClipStorageError>

    func readAllTags() -> Result<[String], ClipStorageError>

    func readAllAlbums() -> Result<[Album], ClipStorageError>

    func searchClips(byKeywords keywords: [String]) -> Result<[Clip], ClipStorageError>

    func searchClips(byTags tags: [String]) -> Result<[Clip], ClipStorageError>

    // MARK: Update

    func update(_ clip: Clip, byAddingTag tag: String) -> Result<Clip, ClipStorageError>

    func update(_ clip: Clip, byDeletingTag tag: String) -> Result<Clip, ClipStorageError>

    func update(_ clips: [Clip], byAddingTags tags: [String]) -> Result<[Clip], ClipStorageError>

    func update(_ album: Album, byAddingClipsHaving clipUrls: [URL]) -> Result<Void, ClipStorageError>

    func update(_ album: Album, byDeletingClipsHaving clipUrls: [URL]) -> Result<Void, ClipStorageError>

    func update(_ album: Album, titleTo title: String) -> Result<Album, ClipStorageError>

    // MARK: Delete

    func delete(_ clip: Clip) -> Result<Clip, ClipStorageError>

    func delete(_ clips: [Clip]) -> Result<[Clip], ClipStorageError>

    func delete(_ clipItem: ClipItem) -> Result<ClipItem, ClipStorageError>

    func delete(_ album: Album) -> Result<Album, ClipStorageError>

    func deleteTag(_ tag: String) -> Result<String, ClipStorageError>
}

extension ClipStorageProtocol {
    public func create(clip: Clip, withData data: [(URL, Data)]) -> Result<Void, ClipStorageError> {
        self.create(clip: clip, withData: data, forced: false)
    }
}
