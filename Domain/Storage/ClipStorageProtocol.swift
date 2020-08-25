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

    func readClip(ofUrl url: URL) -> Result<Clip, ClipStorageError>

    func readAllClips() -> Result<[Clip], ClipStorageError>

    func readAllAlbums() -> Result<[Album], ClipStorageError>

    func getImageData(ofUrl url: URL, forClipUrl clipUrl: URL) -> Result<Data, ClipStorageError>

    func searchClip(byKeywords: [String]) -> Result<[Clip], ClipStorageError>

    // MARK: Update

    func updateItems(inClipOfUrl url: URL, to items: [ClipItem]) -> Result<Clip, ClipStorageError>

    func add(clip clipUrl: URL, toAlbum albumId: String) -> Result<Void, ClipStorageError>

    func add(clips clipUrls: [URL], toAlbum albumId: String) -> Result<Void, ClipStorageError>

    func remove(clips clipUrls: [URL], fromAlbum albumId: String) -> Result<Void, ClipStorageError>

    // MARK: Delete

    func removeClip(ofUrl url: URL) -> Result<Clip, ClipStorageError>

    func removeClips(ofUrls urls: [URL]) -> Result<[Clip], ClipStorageError>

    func removeClipItem(_ item: ClipItem) -> Result<ClipItem, ClipStorageError>
}

extension ClipStorageProtocol {
    public func create(clip: Clip, withData data: [(URL, Data)]) -> Result<Void, ClipStorageError> {
        self.create(clip: clip, withData: data, forced: false)
    }
}
