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
    func create(clip: Clip, withData data: [(URL, Data)], forced: Bool) -> Result<Void, ClipStorageError>

    func readAllClips() -> Result<[Clip], ClipStorageError>

    func readClip(ofUrl url: URL) -> Result<Clip, ClipStorageError>

    func updateItems(inClipOfUrl url: URL, to items: [ClipItem]) -> Result<Clip, ClipStorageError>

    func removeClip(ofUrl url: URL) -> Result<Clip, ClipStorageError>

    func removeClips(ofUrls urls: [URL]) -> Result<[Clip], ClipStorageError>

    func removeClipItem(_ item: ClipItem) -> Result<ClipItem, ClipStorageError>

    func getImageData(ofUrl url: URL, forClipUrl clipUrl: URL) -> Result<Data, ClipStorageError>

    func searchClip(byKeywords: [String]) -> Result<[Clip], ClipStorageError>

    func create(albumWithTitle: String) -> Result<Album, ClipStorageError>

    func readAllAlbums() -> Result<[Album], ClipStorageError>

    func add(clip clipUrl: URL, toAlbum albumId: String) -> Result<Void, ClipStorageError>

    func add(clips clipUrls: [URL], toAlbum albumId: String) -> Result<Void, ClipStorageError>
}

extension ClipStorageProtocol {
    public func create(clip: Clip, withData data: [(URL, Data)]) -> Result<Void, ClipStorageError> {
        self.create(clip: clip, withData: data, forced: false)
    }
}
