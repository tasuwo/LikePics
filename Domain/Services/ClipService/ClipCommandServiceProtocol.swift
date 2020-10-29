//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

public protocol ClipCommandServiceProtocol {
    // MARK: Create

    func create(clip: Clip, withData data: [(fileName: String, image: Data)], forced: Bool) -> Result<Void, ClipStorageError>
    func create(tagWithName name: String) -> Result<Void, ClipStorageError>
    func create(albumWithTitle: String) -> Result<Void, ClipStorageError>

    // MARK: Update

    func updateClips(having ids: [Clip.Identity], byHiding: Bool) -> Result<Void, ClipStorageError>
    func updateClips(having clipIds: [Clip.Identity], byAddingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError>
    func updateClips(having clipIds: [Clip.Identity], byDeletingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError>
    func updateClips(having clipIds: [Clip.Identity], byReplacingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, byAddingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, byDeletingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, titleTo title: String) -> Result<Void, ClipStorageError>
    func updateTag(having id: Tag.Identity, nameTo name: String) -> Result<Void, ClipStorageError>

    // MARK: Delete

    func deleteClips(having ids: [Clip.Identity]) -> Result<Void, ClipStorageError>
    func deleteClipItem(having id: ClipItem.Identity) -> Result<Void, ClipStorageError>
    func deleteAlbum(having id: Album.Identity) -> Result<Void, ClipStorageError>
    func deleteTags(having ids: [Tag.Identity]) -> Result<Void, ClipStorageError>
}

extension ClipCommandServiceProtocol {
    public func create(clip: Clip, withData data: [(fileName: String, image: Data)], forced: Bool) -> Result<Void, ClipStorageError> {
        self.create(clip: clip, withData: data, forced: false)
    }
}
