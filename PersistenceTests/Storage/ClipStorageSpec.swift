//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Nimble
import Quick
import RealmSwift

@testable import Persistence
@testable import TestHelper

class ClipStorageSpec: QuickSpec {
    func makeClip(url: String,
                  description: String = "hoge",
                  items: [ClipItemObject] = [],
                  tags: [TagObject] = [],
                  isHidden: Bool = false,
                  registeredAt: Date = Date(timeIntervalSince1970: 0),
                  updatedAt: Date = Date(timeIntervalSince1970: 1000)) -> ClipObject
    {
        let obj = ClipObject()
        obj.url = url
        obj.descriptionText = description
        items.forEach {
            obj.items.append($0)
        }
        tags.forEach {
            obj.tags.append($0)
        }
        obj.isHidden = isHidden
        obj.registeredAt = registeredAt
        obj.updatedAt = updatedAt
        return obj
    }

    func makeClipItem(clipUrl: String,
                      clipIndex: Int,
                      thumbnailImageUrl: String,
                      thumbnailHeight: Double,
                      thumbnailWidth: Double,
                      largeImageUrl: String,
                      largeImageHeight: Double,
                      largeImageWidth: Double,
                      registeredAt: Date,
                      updatedAt: Date) -> ClipItemObject
    {
        let obj = ClipItemObject()
        obj.clipUrl = clipUrl
        obj.clipIndex = clipIndex
        obj.thumbnailImageUrl = thumbnailImageUrl
        obj.thumbnailHeight = thumbnailHeight
        obj.thumbnailWidth = thumbnailWidth
        obj.largeImageUrl = largeImageUrl
        obj.largeImageHeight = largeImageHeight
        obj.largeImageWidth = largeImageWidth
        obj.registeredAt = registeredAt
        obj.updatedAt = updatedAt
        obj.key = obj.makeKey()
        return obj
    }

    func makeTag(id: String, name: String) -> TagObject {
        let obj = TagObject()
        obj.id = id
        obj.name = name
        return obj
    }

    func makeClippedImage(clipUrl: String,
                          imageUrl: String,
                          image: Data,
                          registeredAt: Date,
                          updatedAt: Date) -> ClippedImageObject
    {
        let obj = ClippedImageObject()
        obj.clipUrl = clipUrl
        obj.imageUrl = imageUrl
        obj.image = image
        obj.registeredAt = registeredAt
        obj.updatedAt = updatedAt
        obj.key = obj.makeKey()
        return obj
    }

    override func spec() {
        let configuration = Realm.Configuration(inMemoryIdentifier: self.name, schemaVersion: 3)
        let realm = try! Realm(configuration: configuration)

        var service: ClipStorage!

        beforeSuite {
            service = ClipStorage(realmConfiguration: configuration)
        }

        beforeEach {
            try! realm.write {
                realm.deleteAll()
            }
        }

        // MARK: Create

        describe("create(clip:withData:forced:)") {
            // TODO:
        }

        describe("create(tagWithName:)") {
            var result: Result<Tag, ClipStorageError>!

            context("同名のタグが存在しない") {
                beforeEach {
                    result = service.create(tagWithName: "hoge")
                }
                it("successが返る") {
                    switch result! {
                    case .success:
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("Realmに保存されている") {
                    guard case let .success(tag) = result else {
                        fail("Unexpected failure")
                        return
                    }
                    let saved = realm.object(ofType: TagObject.self, forPrimaryKey: tag.id)
                    expect(saved?.id).to(equal(tag.id))
                    expect(saved?.name).to(equal(tag.name))
                }
            }

            context("同名のタグが存在する") {
                beforeEach {
                    try! realm.write {
                        let obj = TagObject()
                        obj.id = "999"
                        obj.name = "hoge"
                        realm.add(obj)
                    }
                    result = service.create(tagWithName: "hoge")
                }
                it("duplicatedが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.duplicated):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("Realmに保存されていない") {
                    let savedTags = realm.objects(TagObject.self)
                    expect(savedTags).to(haveCount(1))
                    expect(savedTags[0].id).to(equal("999"))
                    expect(savedTags[0].name).to(equal("hoge"))
                }
            }
        }

        describe("create(albumWithTitle:)") {
            var result: Result<Album, ClipStorageError>!

            context("同名のアルバムが存在しない") {
                beforeEach {
                    result = service.create(albumWithTitle: "hoge")
                }
                it("successが返る") {
                    switch result! {
                    case .success:
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("Realmに保存されている") {
                    guard case let .success(album) = result else {
                        fail("Unexpected failure")
                        return
                    }
                    let saved = realm.object(ofType: AlbumObject.self, forPrimaryKey: album.id)
                    expect(saved?.id).to(equal(album.id))
                    expect(saved?.title).to(equal(album.title))
                }
            }

            context("同名のアルバムが存在する") {
                beforeEach {
                    try! realm.write {
                        let obj = AlbumObject()
                        obj.id = "999"
                        obj.title = "hoge"
                        realm.add(obj)
                    }
                    result = service.create(albumWithTitle: "hoge")
                }
                it("duplicatedが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.duplicated):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("Realmに保存されていない") {
                    let savedAlbums = realm.objects(AlbumObject.self)
                    expect(savedAlbums).to(haveCount(1))
                    expect(savedAlbums[0].id).to(equal("999"))
                    expect(savedAlbums[0].title).to(equal("hoge"))
                }
            }
        }

        // MARK: Read

        describe("readClip(having:)") {
            var result: Result<Clip, ClipStorageError>!

            context("対象のクリップが存在する") {
                beforeEach {
                    try! realm.write {
                        let obj = self.makeClip(url: "https://localhost",
                                                description: "hogehoge",
                                                items: [
                                                    self.makeClipItem(clipUrl: "https://localhost/1",
                                                                      clipIndex: 1,
                                                                      thumbnailImageUrl: "https://localhost/image/thumb/1",
                                                                      thumbnailHeight: 100,
                                                                      thumbnailWidth: 200,
                                                                      largeImageUrl: "https://localhost/image/large/1",
                                                                      largeImageHeight: 300,
                                                                      largeImageWidth: 400,
                                                                      registeredAt: Date(timeIntervalSince1970: 0),
                                                                      updatedAt: Date(timeIntervalSince1970: 1000)),
                                                    self.makeClipItem(clipUrl: "https://localhost/2",
                                                                      clipIndex: 2,
                                                                      thumbnailImageUrl: "https://localhost/image/thumb/2",
                                                                      thumbnailHeight: 500,
                                                                      thumbnailWidth: 600,
                                                                      largeImageUrl: "https://localhost/image/large/2",
                                                                      largeImageHeight: 700,
                                                                      largeImageWidth: 800,
                                                                      registeredAt: Date(timeIntervalSince1970: 0),
                                                                      updatedAt: Date(timeIntervalSince1970: 1000))
                                                ],
                                                tags: [
                                                    self.makeTag(id: "111", name: "hoge"),
                                                    self.makeTag(id: "222", name: "fuga"),
                                                ],
                                                registeredAt: Date(timeIntervalSince1970: 0),
                                                updatedAt: Date(timeIntervalSince1970: 1000))
                        realm.add(obj)
                    }
                    result = service.readClip(having: URL(string: "https://localhost")!)
                }
                it("successが返る") {
                    switch result! {
                    case let .success(clip):
                        expect(clip.url).to(equal(URL(string: "https://localhost")!))
                        expect(clip.description).to(equal("hogehoge"))
                        expect(clip.items).to(haveCount(2))
                        expect(clip.items[0].clipUrl).to(equal(URL(string: "https://localhost/1")!))
                        expect(clip.items[0].clipIndex).to(equal(1))
                        expect(clip.items[0].thumbnail.url).to(equal(URL(string: "https://localhost/image/thumb/1")!))
                        expect(clip.items[0].thumbnail.size).to(equal(.init(height: 100, width: 200)))
                        expect(clip.items[0].image.url).to(equal(URL(string: "https://localhost/image/large/1")!))
                        expect(clip.items[0].image.size).to(equal(.init(height: 300, width: 400)))
                        expect(clip.items[0].registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                        expect(clip.items[0].updatedDate).to(equal(Date(timeIntervalSince1970: 1000)))
                        expect(clip.items[1].clipUrl).to(equal(URL(string: "https://localhost/2")!))
                        expect(clip.items[1].clipIndex).to(equal(2))
                        expect(clip.items[1].thumbnail.url).to(equal(URL(string: "https://localhost/image/thumb/2")!))
                        expect(clip.items[1].thumbnail.size).to(equal(.init(height: 500, width: 600)))
                        expect(clip.items[1].image.url).to(equal(URL(string: "https://localhost/image/large/2")!))
                        expect(clip.items[1].image.size).to(equal(.init(height: 700, width: 800)))
                        expect(clip.items[1].registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                        expect(clip.items[1].updatedDate).to(equal(Date(timeIntervalSince1970: 1000)))
                        expect(clip.tags).to(haveCount(2))
                        expect(clip.tags[0]).to(equal("hoge"))
                        expect(clip.tags[1]).to(equal("fuga"))
                        expect(clip.registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                        expect(clip.updatedDate).to(equal(Date(timeIntervalSince1970: 1000)))
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }

            context("対象のクリップが存在しない") {
                beforeEach {
                    result = service.readClip(having: URL(string: "https://localhost")!)
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }
        }

        describe("readImageData(having:forClipHaving:)") {
            var result: Result<Data, ClipStorageError>!

            context("対象の画像データが存在する") {
                beforeEach {
                    try! realm.write {
                        let obj = self.makeClippedImage(clipUrl: "https://localhost/2",
                                                        imageUrl: "https://localhost/1",
                                                        image: Data(base64Encoded: "hogehoge")!,
                                                        registeredAt: Date(timeIntervalSince1970: 0),
                                                        updatedAt: Date(timeIntervalSince1970: 1000))
                        realm.add(obj)
                    }
                    result = service.readImageData(having: URL(string: "https://localhost/1")!,
                                                   forClipHaving: URL(string: "https://localhost/2")!)
                }
                it("successが返る") {
                    switch result! {
                    case let .success(data):
                        expect(data).to(equal(Data(base64Encoded: "hogehoge")!))
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }

            context("対象の画像データが存在しない") {
                beforeEach {
                    result = service.readImageData(having: URL(string: "https://localhost/1")!,
                                                   forClipHaving: URL(string: "https://localhost/2")!)
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }
        }

        describe("readAllClips()") {
            var result: Result<[Clip], ClipStorageError>!

            context("クリップが1つも存在しない") {
                beforeEach {
                    result = service.readAllClips()
                }
                it("successが返り、結果は空配列となる") {
                    switch result! {
                    case let .success(clips):
                        expect(clips).to(beEmpty())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }

            context("クリップが複数存在する") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 description: "hoge1",
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/2",
                                                 description: "hoge2",
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 description: "hoge3",
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                    }
                    result = service.readAllClips()
                }
                it("successが返り、全てのクリップが取得できる") {
                    switch result! {
                    case let .success(v):
                        let clips = v.sorted(by: { $0.registeredDate < $1.registeredDate })
                        expect(clips).to(haveCount(3))
                        expect(clips[0].url).to(equal(URL(string: "https://localhost/1")!))
                        expect(clips[0].description).to(equal("hoge1"))
                        expect(clips[0].items).to(beEmpty())
                        expect(clips[0].tags).to(beEmpty())
                        expect(clips[0].registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                        expect(clips[0].updatedDate).to(equal(Date(timeIntervalSince1970: 1000)))
                        expect(clips[1].url).to(equal(URL(string: "https://localhost/2")!))
                        expect(clips[1].description).to(equal("hoge2"))
                        expect(clips[1].items).to(beEmpty())
                        expect(clips[1].tags).to(beEmpty())
                        expect(clips[1].registeredDate).to(equal(Date(timeIntervalSince1970: 1000)))
                        expect(clips[1].updatedDate).to(equal(Date(timeIntervalSince1970: 2000)))
                        expect(clips[2].url).to(equal(URL(string: "https://localhost/3")!))
                        expect(clips[2].description).to(equal("hoge3"))
                        expect(clips[2].items).to(beEmpty())
                        expect(clips[2].tags).to(beEmpty())
                        expect(clips[2].registeredDate).to(equal(Date(timeIntervalSince1970: 2000)))
                        expect(clips[2].updatedDate).to(equal(Date(timeIntervalSince1970: 3000)))
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }
        }

        describe("readAllTags()") {
            var result: Result<[String], ClipStorageError>!

            context("タグが1つも存在しない") {
                beforeEach {
                    result = service.readAllTags()
                }
                it("successが返り、結果は空配列となる") {
                    switch result! {
                    case let .success(tags):
                        expect(tags).to(beEmpty())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }

            context("タグが複数存在する") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeTag(id: "111", name: "hoge")
                        let obj2 = self.makeTag(id: "222", name: "fuga")
                        let obj3 = self.makeTag(id: "333", name: "piyo")

                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                    }
                    result = service.readAllTags()
                }
                it("successが返り、全てのタグが取得できる") {
                    switch result! {
                    case let .success(v):
                        let tags = v.sorted(by: { $0 < $1 })
                        expect(tags).to(haveCount(3))
                        expect(tags[0]).to(equal("fuga"))
                        expect(tags[1]).to(equal("hoge"))
                        expect(tags[2]).to(equal("piyo"))
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }
        }

        describe("readAllAlbums()") {
            var result: Result<[Album], ClipStorageError>!

            context("アルバムが1つも存在しない") {
                beforeEach {
                    result = service.readAllAlbums()
                }
                it("successが返り、結果は空配列となる") {
                    switch result! {
                    case let .success(albums):
                        expect(albums).to(beEmpty())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }

            context("アルバムが複数存在する") {
                beforeEach {
                    try! realm.write {
                        let obj1 = AlbumObject()
                        obj1.id = "111"
                        obj1.title = "hoge"
                        obj1.registeredAt = Date(timeIntervalSince1970: 0)
                        obj1.updatedAt = Date(timeIntervalSince1970: 1000)

                        let obj2 = AlbumObject()
                        obj2.id = "222"
                        obj2.title = "fuga"
                        obj2.registeredAt = Date(timeIntervalSince1970: 1000)
                        obj2.updatedAt = Date(timeIntervalSince1970: 2000)

                        let obj3 = AlbumObject()
                        obj3.id = "333"
                        obj3.title = "piyo"
                        obj3.registeredAt = Date(timeIntervalSince1970: 2000)
                        obj3.updatedAt = Date(timeIntervalSince1970: 3000)

                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                    }
                    result = service.readAllAlbums()
                }
                it("successが返り、全てのクリップが取得できる") {
                    switch result! {
                    case let .success(v):
                        let albums = v.sorted(by: { $0.registeredDate < $1.registeredDate })
                        expect(albums).to(haveCount(3))
                        expect(albums[0].id).to(equal("111"))
                        expect(albums[0].title).to(equal("hoge"))
                        expect(albums[0].registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                        expect(albums[0].updatedDate).to(equal(Date(timeIntervalSince1970: 1000)))
                        expect(albums[1].id).to(equal("222"))
                        expect(albums[1].title).to(equal("fuga"))
                        expect(albums[1].registeredDate).to(equal(Date(timeIntervalSince1970: 1000)))
                        expect(albums[1].updatedDate).to(equal(Date(timeIntervalSince1970: 2000)))
                        expect(albums[2].id).to(equal("333"))
                        expect(albums[2].title).to(equal("piyo"))
                        expect(albums[2].registeredDate).to(equal(Date(timeIntervalSince1970: 2000)))
                        expect(albums[2].updatedDate).to(equal(Date(timeIntervalSince1970: 3000)))
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }
        }

        describe("searchClips(byKeywords:)") {
            var result: Result<[Clip], ClipStorageError>!

            context("条件にマッチするクリップが1件も存在しない") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 description: "hoge1",
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/2",
                                                 description: "hoge2",
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 description: "hoge3",
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                    }
                    result = service.searchClips(byKeywords: ["hoge", "fuga", "piyo"])
                }
                it("successが返り、結果は空配列となる") {
                    switch result! {
                    case let .success(clips):
                        expect(clips).to(beEmpty())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }

            context("1つのキーワードにマッチするクリップが複数存在する") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/hogehoge",
                                                 description: "hoge1",
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/poe",
                                                 description: "hoge2",
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/hoge",
                                                 description: "hoge3",
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                    }
                    result = service.searchClips(byKeywords: ["hoge"])
                }
                it("successが返り、マッチしたクリップが返る") {
                    switch result! {
                    case let .success(v):
                        let clips = v.sorted(by: { $0.registeredDate < $1.registeredDate })
                        expect(clips).to(haveCount(2))
                        expect(clips[0].url).to(equal(URL(string: "https://localhost/hogehoge")!))
                        expect(clips[0].description).to(equal("hoge1"))
                        expect(clips[0].items).to(beEmpty())
                        expect(clips[0].tags).to(beEmpty())
                        expect(clips[0].registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                        expect(clips[0].updatedDate).to(equal(Date(timeIntervalSince1970: 1000)))
                        expect(clips[1].url).to(equal(URL(string: "https://localhost/hoge")!))
                        expect(clips[1].description).to(equal("hoge3"))
                        expect(clips[1].items).to(beEmpty())
                        expect(clips[1].tags).to(beEmpty())
                        expect(clips[1].registeredDate).to(equal(Date(timeIntervalSince1970: 2000)))
                        expect(clips[1].updatedDate).to(equal(Date(timeIntervalSince1970: 3000)))
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }

            context("複数のキーワードでOR検索できる") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/hoge",
                                                 description: "hoge1",
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/piyo",
                                                 description: "hoge2",
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/fuga",
                                                 description: "hoge3",
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        let obj4 = self.makeClip(url: "https://localhost/poe",
                                                 description: "hoge4",
                                                 registeredAt: Date(timeIntervalSince1970: 4000),
                                                 updatedAt: Date(timeIntervalSince1970: 5000))
                        let obj5 = self.makeClip(url: "https://localhost/hogefuga",
                                                 description: "hoge5",
                                                 registeredAt: Date(timeIntervalSince1970: 6000),
                                                 updatedAt: Date(timeIntervalSince1970: 7000))
                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                        realm.add(obj4)
                        realm.add(obj5)
                    }
                    result = service.searchClips(byKeywords: ["hoge", "fuga"])
                }
                it("successが返り、マッチしたクリップが返る") {
                    switch result! {
                    case let .success(v):
                        let clips = v.sorted(by: { $0.registeredDate < $1.registeredDate })
                        expect(clips).to(haveCount(3))
                        expect(clips[0].url).to(equal(URL(string: "https://localhost/hoge")!))
                        expect(clips[0].description).to(equal("hoge1"))
                        expect(clips[0].items).to(beEmpty())
                        expect(clips[0].tags).to(beEmpty())
                        expect(clips[0].registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                        expect(clips[0].updatedDate).to(equal(Date(timeIntervalSince1970: 1000)))
                        expect(clips[1].url).to(equal(URL(string: "https://localhost/fuga")!))
                        expect(clips[1].description).to(equal("hoge3"))
                        expect(clips[1].items).to(beEmpty())
                        expect(clips[1].tags).to(beEmpty())
                        expect(clips[1].registeredDate).to(equal(Date(timeIntervalSince1970: 2000)))
                        expect(clips[1].updatedDate).to(equal(Date(timeIntervalSince1970: 3000)))
                        expect(clips[2].url).to(equal(URL(string: "https://localhost/hogefuga")!))
                        expect(clips[2].description).to(equal("hoge5"))
                        expect(clips[2].items).to(beEmpty())
                        expect(clips[2].tags).to(beEmpty())
                        expect(clips[2].registeredDate).to(equal(Date(timeIntervalSince1970: 6000)))
                        expect(clips[2].updatedDate).to(equal(Date(timeIntervalSince1970: 7000)))
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }
        }

        describe("searchClips(byTags:)") {
            var result: Result<[Clip], ClipStorageError>!

            context("条件にマッチするクリップが1件も存在しない") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 description: "hoge1",
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/2",
                                                 description: "hoge2",
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 description: "hoge3",
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                    }
                    result = service.searchClips(byTags: ["hoge", "fuga", "piyo"])
                }
                it("successが返り、結果は空配列となる") {
                    switch result! {
                    case let .success(clips):
                        expect(clips).to(beEmpty())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }

            context("1つのタグにマッチするクリップが複数存在する") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 description: "hoge1",
                                                 tags: [
                                                     self.makeTag(id: "111", name: "hoge")
                                                 ],
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/2",
                                                 description: "hoge2",
                                                 tags: [
                                                     self.makeTag(id: "222", name: "fuga")
                                                 ],
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 description: "hoge3",
                                                 tags: [
                                                     self.makeTag(id: "111", name: "hoge"),
                                                     self.makeTag(id: "222", name: "fuga")
                                                 ],
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        realm.add(obj1, update: .modified)
                        realm.add(obj2, update: .modified)
                        realm.add(obj3, update: .modified)
                    }
                    result = service.searchClips(byTags: ["hoge"])
                }
                it("successが返り、マッチしたクリップが返る") {
                    switch result! {
                    case let .success(v):
                        let clips = v.sorted(by: { $0.registeredDate < $1.registeredDate })
                        expect(clips).to(haveCount(2))
                        expect(clips[0].url).to(equal(URL(string: "https://localhost/1")!))
                        expect(clips[0].description).to(equal("hoge1"))
                        expect(clips[0].items).to(beEmpty())
                        expect(clips[0].tags).to(haveCount(1))
                        expect(clips[0].registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                        expect(clips[0].updatedDate).to(equal(Date(timeIntervalSince1970: 1000)))
                        expect(clips[1].url).to(equal(URL(string: "https://localhost/3")!))
                        expect(clips[1].description).to(equal("hoge3"))
                        expect(clips[1].items).to(beEmpty())
                        expect(clips[1].tags).to(haveCount(2))
                        expect(clips[1].registeredDate).to(equal(Date(timeIntervalSince1970: 2000)))
                        expect(clips[1].updatedDate).to(equal(Date(timeIntervalSince1970: 3000)))
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }

            context("複数のタグでOR検索できる") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 description: "hoge1",
                                                 tags: [
                                                     self.makeTag(id: "111", name: "hoge")
                                                 ],
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/2",
                                                 description: "hoge2",
                                                 tags: [
                                                     self.makeTag(id: "222", name: "piyo")
                                                 ],
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 description: "hoge3",
                                                 tags: [
                                                     self.makeTag(id: "333", name: "fuga")
                                                 ],
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        let obj4 = self.makeClip(url: "https://localhost/4",
                                                 description: "hoge4",
                                                 tags: [
                                                     self.makeTag(id: "444", name: "poe")
                                                 ],
                                                 registeredAt: Date(timeIntervalSince1970: 4000),
                                                 updatedAt: Date(timeIntervalSince1970: 5000))
                        let obj5 = self.makeClip(url: "https://localhost/5",
                                                 description: "hoge5",
                                                 tags: [
                                                     self.makeTag(id: "111", name: "hoge"),
                                                     self.makeTag(id: "333", name: "fuga"),
                                                 ],
                                                 registeredAt: Date(timeIntervalSince1970: 6000),
                                                 updatedAt: Date(timeIntervalSince1970: 7000))
                        realm.add(obj1, update: .modified)
                        realm.add(obj2, update: .modified)
                        realm.add(obj3, update: .modified)
                        realm.add(obj4, update: .modified)
                        realm.add(obj5, update: .modified)
                    }
                    result = service.searchClips(byTags: ["hoge", "fuga"])
                }
                it("successが返り、マッチしたクリップが返る") {
                    switch result! {
                    case let .success(v):
                        let clips = v.sorted(by: { $0.registeredDate < $1.registeredDate })
                        expect(clips).to(haveCount(3))
                        expect(clips[0].url).to(equal(URL(string: "https://localhost/1")!))
                        expect(clips[0].description).to(equal("hoge1"))
                        expect(clips[0].items).to(beEmpty())
                        expect(clips[0].tags).to(haveCount(1))
                        expect(clips[0].registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                        expect(clips[0].updatedDate).to(equal(Date(timeIntervalSince1970: 1000)))
                        expect(clips[1].url).to(equal(URL(string: "https://localhost/3")!))
                        expect(clips[1].description).to(equal("hoge3"))
                        expect(clips[1].items).to(beEmpty())
                        expect(clips[1].tags).to(haveCount(1))
                        expect(clips[1].registeredDate).to(equal(Date(timeIntervalSince1970: 2000)))
                        expect(clips[1].updatedDate).to(equal(Date(timeIntervalSince1970: 3000)))
                        expect(clips[2].url).to(equal(URL(string: "https://localhost/5")!))
                        expect(clips[2].description).to(equal("hoge5"))
                        expect(clips[2].items).to(beEmpty())
                        expect(clips[2].tags).to(haveCount(2))
                        expect(clips[2].registeredDate).to(equal(Date(timeIntervalSince1970: 6000)))
                        expect(clips[2].updatedDate).to(equal(Date(timeIntervalSince1970: 7000)))
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }
        }

        // MARK: Update

        describe("update(_:byAddingTag:)") {
            var result: Result<Clip, ClipStorageError>!

            context("追加対象のタグとクリップが存在する") {
                beforeEach {
                    try! realm.write {
                        let obj = self.makeClip(url: "https://localhost")
                        let tagObj = self.makeTag(id: "111", name: "hoge")
                        realm.add(obj)
                        realm.add(tagObj)
                    }
                    result = service.update(Clip(url: URL(string: "https://localhost")!,
                                                 description: nil,
                                                 items: [],
                                                 tags: [], isHidden: false,
                                                 registeredDate: Date(timeIntervalSince1970: 0),
                                                 updatedDate: Date(timeIntervalSince1970: 1000)),
                                            byAddingTag: "hoge")
                }
                it("successが返る") {
                    switch result! {
                    case .success:
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("返ってきたクリップが更新されている") {
                    guard case let .success(clip) = result else {
                        fail("Unexpected failure")
                        return
                    }
                    expect(clip.url).to(equal(URL(string: "https://localhost")))
                    expect(clip.description).to(equal("hoge"))
                    expect(clip.items).to(beEmpty())
                    expect(clip.tags).to(haveCount(1))
                    expect(clip.tags.first!).to(equal("hoge"))
                    expect(clip.registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                    // 更新時刻が更新されている
                    expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 1000)))
                }
                it("Realm内のクリップが更新されている") {
                    let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: "https://localhost")
                    expect(clip?.url).to(equal("https://localhost"))
                    expect(clip?.descriptionText).to(equal("hoge"))
                    expect(clip?.items).to(beEmpty())
                    expect(clip?.tags).to(haveCount(1))
                    expect(clip?.tags.first!.id).to(equal("111"))
                    expect(clip?.tags.first!.name).to(equal("hoge"))
                    expect(clip?.registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                    // 更新時刻が更新されている
                    expect(clip?.updatedAt).notTo(equal(Date(timeIntervalSince1970: 1000)))
                }
                it("タグは新しく増えない") {
                    let tags = realm.objects(TagObject.self)
                    expect(tags).to(haveCount(1))
                    expect(tags.first?.id).to(equal("111"))
                    expect(tags.first?.name).to(equal("hoge"))
                }
            }

            context("追加対象のタグが存在しない") {
                beforeEach {
                    try! realm.write {
                        let obj = self.makeClip(url: "https://localhost")
                        realm.add(obj)
                    }
                    result = service.update(Clip.makeDefault(url: URL(string: "https://localhost")!),
                                            byAddingTag: "hoge")
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("タグは新しく増えない") {
                    let tags = realm.objects(TagObject.self)
                    expect(tags).to(haveCount(0))
                }
            }

            context("追加対象のクリップが存在しない") {
                beforeEach {
                    try! realm.write {
                        let obj = self.makeTag(id: "111", name: "hoge")
                        realm.add(obj)
                    }
                    result = service.update(Clip.makeDefault(), byAddingTag: "hoge")
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }
        }

        describe("update(_:byDeletingTag:)") {
            var result: Result<Clip, ClipStorageError>!

            context("クリップが削除対象のタグを保持している") {
                beforeEach {
                    try! realm.write {
                        let obj = self.makeClip(url: "https://localhost",
                                                tags: [
                                                    self.makeTag(id: "111", name: "hoge"),
                                                    self.makeTag(id: "222", name: "fuga"),
                                                    self.makeTag(id: "333", name: "piyo"),

                                                ])
                        realm.add(obj)
                    }
                    result = service.update(Clip.makeDefault(url: URL(string: "https://localhost")!,
                                                             registeredDate: Date(timeIntervalSince1970: 0),
                                                             updatedDate: Date(timeIntervalSince1970: 1000)),
                                            byDeletingTag: "fuga")
                }
                it("successが返る") {
                    switch result! {
                    case .success:
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("返ってきたクリップが更新されている") {
                    guard case let .success(clip) = result else {
                        fail("Unexpected failure")
                        return
                    }
                    expect(clip.url).to(equal(URL(string: "https://localhost")))
                    expect(clip.description).to(equal("hoge"))
                    expect(clip.items).to(beEmpty())
                    expect(clip.tags).to(haveCount(2))
                    expect(clip.tags).to(equal(["hoge", "piyo"]))
                    expect(clip.registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                    // 更新時刻が更新されている
                    expect(clip.updatedDate).notTo(equal(Date(timeIntervalSince1970: 1000)))
                }
                it("Realm内のクリップが更新されている") {
                    let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: "https://localhost")
                    expect(clip?.url).to(equal("https://localhost"))
                    expect(clip?.descriptionText).to(equal("hoge"))
                    expect(clip?.items).to(beEmpty())
                    expect(clip?.tags).to(haveCount(2))
                    expect(clip?.tags[0].id).to(equal("111"))
                    expect(clip?.tags[0].name).to(equal("hoge"))
                    expect(clip?.tags[1].id).to(equal("333"))
                    expect(clip?.tags[1].name).to(equal("piyo"))
                    expect(clip?.registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                    // 更新時刻が更新されている
                    expect(clip?.updatedAt).notTo(equal(Date(timeIntervalSince1970: 1000)))
                }
                it("タグ自体は残っている") {
                    let tags = realm.objects(TagObject.self).sorted(by: { $0.id < $1.id })
                    expect(tags).to(haveCount(3))
                    expect(tags[0].id).to(equal("111"))
                    expect(tags[0].name).to(equal("hoge"))
                    expect(tags[1].id).to(equal("222"))
                    expect(tags[1].name).to(equal("fuga"))
                    expect(tags[2].id).to(equal("333"))
                    expect(tags[2].name).to(equal("piyo"))
                }
            }

            context("更新対象のクリップが削除対象のタグを持っていない") {
                beforeEach {
                    try! realm.write {
                        let obj = self.makeClip(url: "https://localhost",
                                                tags: [
                                                    self.makeTag(id: "111", name: "fuga"),
                                                    self.makeTag(id: "222", name: "piyo"),
                                                ])
                        realm.add(obj)
                    }
                    result = service.update(Clip.makeDefault(url: URL(string: "https://localhost")!,
                                                             registeredDate: Date(timeIntervalSince1970: 0),
                                                             updatedDate: Date(timeIntervalSince1970: 1000)),
                                            byDeletingTag: "hoge")
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }

            context("更新対象のクリップが存在しない") {
                beforeEach {
                    try! realm.write {
                        let obj = self.makeTag(id: "111", name: "hoge")
                        realm.add(obj)
                    }
                    result = service.update(Clip.makeDefault(),
                                            byDeletingTag: "hoge")
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }
        }

        describe("update(_:byHiding:)") {
            var result: Result<[Clip], ClipStorageError>!

            context("追加対象のクリップが存在する") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/2",
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                    }
                    result = service.update([
                        Clip.makeDefault(url: URL(string: "https://localhost/1")!,
                                         registeredDate: Date(timeIntervalSince1970: 0),
                                         updatedDate: Date(timeIntervalSince1970: 1000)),
                        Clip.makeDefault(url: URL(string: "https://localhost/3")!,
                                         registeredDate: Date(timeIntervalSince1970: 2000),
                                         updatedDate: Date(timeIntervalSince1970: 3000)),
                    ],
                    byHiding: true)
                }

                it("successが返る") {
                    switch result! {
                    case .success:
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("返ってきたクリップが更新されている") {
                    guard case let .success(v) = result else {
                        fail("Unexpected failure")
                        return
                    }
                    let clips = v.sorted(by: { $0.registeredDate < $1.registeredDate })
                    expect(clips).to(haveCount(2))
                    expect(clips[0].url).to(equal(URL(string: "https://localhost/1")))
                    expect(clips[0].isHidden).to(beTrue())
                    expect(clips[0].registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                    // 更新時刻が更新されている
                    expect(clips[0].updatedDate).notTo(equal(Date(timeIntervalSince1970: 1000)))

                    expect(clips[1].url).to(equal(URL(string: "https://localhost/3")))
                    expect(clips[1].isHidden).to(beTrue())
                    expect(clips[1].registeredDate).to(equal(Date(timeIntervalSince1970: 2000)))
                    // 更新時刻が更新されている
                    expect(clips[1].updatedDate).notTo(equal(Date(timeIntervalSince1970: 3000)))
                }
                it("Realm内のクリップが更新されている") {
                    let clips = realm.objects(ClipObject.self).sorted(by: { $0.registeredAt < $1.registeredAt })
                    expect(clips).to(haveCount(3))
                    expect(clips[0].url).to(equal("https://localhost/1"))
                    expect(clips[0].isHidden).to(beTrue())
                    expect(clips[0].registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                    // 更新時刻が更新されている
                    expect(clips[0].updatedAt).notTo(equal(Date(timeIntervalSince1970: 1000)))

                    expect(clips[1].url).to(equal("https://localhost/2"))
                    expect(clips[1].isHidden).to(beFalse())
                    expect(clips[1].registeredAt).to(equal(Date(timeIntervalSince1970: 1000)))
                    expect(clips[1].updatedAt).to(equal(Date(timeIntervalSince1970: 2000)))

                    expect(clips[2].url).to(equal("https://localhost/3"))
                    expect(clips[2].isHidden).to(beTrue())
                    expect(clips[2].registeredAt).to(equal(Date(timeIntervalSince1970: 2000)))
                    // 更新時刻が更新されている
                    expect(clips[2].updatedAt).notTo(equal(Date(timeIntervalSince1970: 3000)))
                }
            }

            context("追加対象のクリップが1つも存在しない") {
                beforeEach {
                    result = service.update([
                        Clip.makeDefault(url: URL(string: "https://localhost/1")!),
                        Clip.makeDefault(url: URL(string: "https://localhost/2")!),
                        Clip.makeDefault(url: URL(string: "https://localhost/3")!),
                    ],
                    byHiding: true)
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("Realm内にクリップが追加されない") {
                    let clips = realm.objects(ClipObject.self)
                    expect(clips).to(beEmpty())
                }
            }

            context("追加対象のクリップが一部存在しない") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        realm.add(obj1)
                        realm.add(obj3)
                    }
                    result = service.update([
                        Clip.makeDefault(url: URL(string: "https://localhost/1")!,
                                         registeredDate: Date(timeIntervalSince1970: 0),
                                         updatedDate: Date(timeIntervalSince1970: 1000)),
                        Clip.makeDefault(url: URL(string: "https://localhost/2")!,
                                         registeredDate: Date(timeIntervalSince1970: 1000),
                                         updatedDate: Date(timeIntervalSince1970: 2000)),
                        Clip.makeDefault(url: URL(string: "https://localhost/3")!,
                                         registeredDate: Date(timeIntervalSince1970: 2000),
                                         updatedDate: Date(timeIntervalSince1970: 3000)),
                    ],
                    byHiding: true)
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("Realm内のクリップが更新されない") {
                    let clips = realm.objects(ClipObject.self).sorted(by: { $0.registeredAt < $1.registeredAt })
                    expect(clips).to(haveCount(2))
                    expect(clips[0].url).to(equal("https://localhost/1"))
                    expect(clips[0].isHidden).to(beFalse())
                    expect(clips[0].registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                    expect(clips[0].updatedAt).to(equal(Date(timeIntervalSince1970: 1000)))
                    expect(clips[1].url).to(equal("https://localhost/3"))
                    expect(clips[1].isHidden).to(beFalse())
                    expect(clips[1].registeredAt).to(equal(Date(timeIntervalSince1970: 2000)))
                    expect(clips[1].updatedAt).to(equal(Date(timeIntervalSince1970: 3000)))
                }
            }
        }

        describe("update(_:byAddingTags:)") {
            var result: Result<[Clip], ClipStorageError>!

            context("追加対象のタグとクリップが存在する") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/2",
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        let tag1 = self.makeTag(id: "111", name: "hoge")
                        let tag2 = self.makeTag(id: "222", name: "fuga")
                        let tag3 = self.makeTag(id: "333", name: "piyo")

                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                        realm.add(tag1)
                        realm.add(tag2)
                        realm.add(tag3)
                    }
                    result = service.update([
                        Clip.makeDefault(url: URL(string: "https://localhost/1")!,
                                         registeredDate: Date(timeIntervalSince1970: 0),
                                         updatedDate: Date(timeIntervalSince1970: 1000)),
                        Clip.makeDefault(url: URL(string: "https://localhost/2")!,
                                         registeredDate: Date(timeIntervalSince1970: 1000),
                                         updatedDate: Date(timeIntervalSince1970: 2000)),
                        Clip.makeDefault(url: URL(string: "https://localhost/3")!,
                                         registeredDate: Date(timeIntervalSince1970: 2000),
                                         updatedDate: Date(timeIntervalSince1970: 3000)),
                    ],
                    byAddingTags: ["hoge", "fuga", "piyo"])
                }

                it("successが返る") {
                    switch result! {
                    case .success:
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("返ってきたクリップが更新されている") {
                    guard case let .success(v) = result else {
                        fail("Unexpected failure")
                        return
                    }
                    let clips = v.sorted(by: { $0.registeredDate < $1.registeredDate })
                    expect(clips).to(haveCount(3))
                    expect(clips[0].url).to(equal(URL(string: "https://localhost/1")))
                    expect(clips[0].tags).to(haveCount(3))
                    expect(clips[0].tags.sorted(by: { $0 < $1 })[0]).to(equal("fuga"))
                    expect(clips[0].tags.sorted(by: { $0 < $1 })[1]).to(equal("hoge"))
                    expect(clips[0].tags.sorted(by: { $0 < $1 })[2]).to(equal("piyo"))
                    expect(clips[0].registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                    // 更新時刻が更新されている
                    expect(clips[0].updatedDate).notTo(equal(Date(timeIntervalSince1970: 1000)))

                    expect(clips[1].url).to(equal(URL(string: "https://localhost/2")))
                    expect(clips[1].tags).to(haveCount(3))
                    expect(clips[1].tags.sorted(by: { $0 < $1 })[0]).to(equal("fuga"))
                    expect(clips[1].tags.sorted(by: { $0 < $1 })[1]).to(equal("hoge"))
                    expect(clips[1].tags.sorted(by: { $0 < $1 })[2]).to(equal("piyo"))
                    expect(clips[1].registeredDate).to(equal(Date(timeIntervalSince1970: 1000)))
                    // 更新時刻が更新されている
                    expect(clips[1].updatedDate).notTo(equal(Date(timeIntervalSince1970: 2000)))

                    expect(clips[2].url).to(equal(URL(string: "https://localhost/3")))
                    expect(clips[2].tags).to(haveCount(3))
                    expect(clips[2].tags.sorted(by: { $0 < $1 })[0]).to(equal("fuga"))
                    expect(clips[2].tags.sorted(by: { $0 < $1 })[1]).to(equal("hoge"))
                    expect(clips[2].tags.sorted(by: { $0 < $1 })[2]).to(equal("piyo"))
                    expect(clips[2].registeredDate).to(equal(Date(timeIntervalSince1970: 2000)))
                    // 更新時刻が更新されている
                    expect(clips[2].updatedDate).notTo(equal(Date(timeIntervalSince1970: 3000)))
                }
                it("Realm内のクリップが更新されている") {
                    let clips = realm.objects(ClipObject.self).sorted(by: { $0.registeredAt < $1.registeredAt })
                    expect(clips).to(haveCount(3))
                    expect(clips[0].url).to(equal("https://localhost/1"))
                    expect(clips[0].tags).to(haveCount(3))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[0].id).to(equal("111"))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[0].name).to(equal("hoge"))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[1].id).to(equal("222"))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[1].name).to(equal("fuga"))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[2].id).to(equal("333"))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[2].name).to(equal("piyo"))
                    expect(clips[0].registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                    // 更新時刻が更新されている
                    expect(clips[0].updatedAt).notTo(equal(Date(timeIntervalSince1970: 1000)))

                    expect(clips[1].url).to(equal("https://localhost/2"))
                    expect(clips[1].tags).to(haveCount(3))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[0].id).to(equal("111"))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[0].name).to(equal("hoge"))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[1].id).to(equal("222"))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[1].name).to(equal("fuga"))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[2].id).to(equal("333"))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[2].name).to(equal("piyo"))
                    expect(clips[1].registeredAt).to(equal(Date(timeIntervalSince1970: 1000)))
                    // 更新時刻が更新されている
                    expect(clips[1].updatedAt).notTo(equal(Date(timeIntervalSince1970: 2000)))

                    expect(clips[2].url).to(equal("https://localhost/3"))
                    expect(clips[2].tags).to(haveCount(3))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[0].id).to(equal("111"))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[0].name).to(equal("hoge"))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[1].id).to(equal("222"))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[1].name).to(equal("fuga"))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[2].id).to(equal("333"))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[2].name).to(equal("piyo"))
                    expect(clips[2].registeredAt).to(equal(Date(timeIntervalSince1970: 2000)))
                    // 更新時刻が更新されている
                    expect(clips[2].updatedAt).notTo(equal(Date(timeIntervalSince1970: 3000)))
                }
                it("タグは新しく増えない") {
                    let tags = realm.objects(TagObject.self)
                    expect(tags).to(haveCount(3))
                    expect(tags.sorted(by: { $0.id < $1.id })[0].id).to(equal("111"))
                    expect(tags.sorted(by: { $0.id < $1.id })[0].name).to(equal("hoge"))
                    expect(tags.sorted(by: { $0.id < $1.id })[1].id).to(equal("222"))
                    expect(tags.sorted(by: { $0.id < $1.id })[1].name).to(equal("fuga"))
                    expect(tags.sorted(by: { $0.id < $1.id })[2].id).to(equal("333"))
                    expect(tags.sorted(by: { $0.id < $1.id })[2].name).to(equal("piyo"))
                }
            }

            context("追加対象のタグが1つも存在しない") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/2",
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                    }
                    result = service.update([
                        Clip.makeDefault(url: URL(string: "https://localhost/1")!,
                                         registeredDate: Date(timeIntervalSince1970: 0),
                                         updatedDate: Date(timeIntervalSince1970: 1000)),
                        Clip.makeDefault(url: URL(string: "https://localhost/2")!,
                                         registeredDate: Date(timeIntervalSince1970: 1000),
                                         updatedDate: Date(timeIntervalSince1970: 2000)),
                        Clip.makeDefault(url: URL(string: "https://localhost/3")!,
                                         registeredDate: Date(timeIntervalSince1970: 2000),
                                         updatedDate: Date(timeIntervalSince1970: 3000)),
                    ],
                    byAddingTags: ["hoge", "fuga", "piyo"])
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("Realm内のクリップが更新されない") {
                    let clips = realm.objects(ClipObject.self).sorted(by: { $0.registeredAt < $1.registeredAt })
                    expect(clips).to(haveCount(3))
                    expect(clips[0].url).to(equal("https://localhost/1"))
                    expect(clips[0].tags).to(haveCount(0))
                    expect(clips[0].registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                    expect(clips[0].updatedAt).to(equal(Date(timeIntervalSince1970: 1000)))
                    expect(clips[1].url).to(equal("https://localhost/2"))
                    expect(clips[1].tags).to(haveCount(0))
                    expect(clips[1].registeredAt).to(equal(Date(timeIntervalSince1970: 1000)))
                    expect(clips[1].updatedAt).to(equal(Date(timeIntervalSince1970: 2000)))
                    expect(clips[2].url).to(equal("https://localhost/3"))
                    expect(clips[2].tags).to(haveCount(0))
                    expect(clips[2].registeredAt).to(equal(Date(timeIntervalSince1970: 2000)))
                    expect(clips[2].updatedAt).to(equal(Date(timeIntervalSince1970: 3000)))
                }
                it("タグは新しく増えない") {
                    let tags = realm.objects(TagObject.self)
                    expect(tags).to(haveCount(0))
                }
            }

            context("追加対象のタグが一部存在しない") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/2",
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        let tag1 = self.makeTag(id: "111", name: "hoge")
                        let tag3 = self.makeTag(id: "333", name: "piyo")

                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                        realm.add(tag1)
                        realm.add(tag3)
                    }
                    result = service.update([
                        Clip.makeDefault(url: URL(string: "https://localhost/1")!,
                                         registeredDate: Date(timeIntervalSince1970: 0),
                                         updatedDate: Date(timeIntervalSince1970: 1000)),
                        Clip.makeDefault(url: URL(string: "https://localhost/2")!,
                                         registeredDate: Date(timeIntervalSince1970: 1000),
                                         updatedDate: Date(timeIntervalSince1970: 2000)),
                        Clip.makeDefault(url: URL(string: "https://localhost/3")!,
                                         registeredDate: Date(timeIntervalSince1970: 2000),
                                         updatedDate: Date(timeIntervalSince1970: 3000)),
                    ],
                    byAddingTags: ["hoge", "fuga", "piyo"])
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("Realm内のクリップが更新されない") {
                    let clips = realm.objects(ClipObject.self).sorted(by: { $0.registeredAt < $1.registeredAt })
                    expect(clips).to(haveCount(3))
                    expect(clips[0].url).to(equal("https://localhost/1"))
                    expect(clips[0].tags).to(haveCount(0))
                    expect(clips[0].registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                    expect(clips[0].updatedAt).to(equal(Date(timeIntervalSince1970: 1000)))
                    expect(clips[1].url).to(equal("https://localhost/2"))
                    expect(clips[1].tags).to(haveCount(0))
                    expect(clips[1].registeredAt).to(equal(Date(timeIntervalSince1970: 1000)))
                    expect(clips[1].updatedAt).to(equal(Date(timeIntervalSince1970: 2000)))
                    expect(clips[2].url).to(equal("https://localhost/3"))
                    expect(clips[2].tags).to(haveCount(0))
                    expect(clips[2].registeredAt).to(equal(Date(timeIntervalSince1970: 2000)))
                    expect(clips[2].updatedAt).to(equal(Date(timeIntervalSince1970: 3000)))
                }
                it("タグは新しく増えない") {
                    let tags = realm.objects(TagObject.self)
                    expect(tags).to(haveCount(2))
                    expect(tags.sorted(by: { $0.id < $1.id })[0].id).to(equal("111"))
                    expect(tags.sorted(by: { $0.id < $1.id })[0].name).to(equal("hoge"))
                    expect(tags.sorted(by: { $0.id < $1.id })[1].id).to(equal("333"))
                    expect(tags.sorted(by: { $0.id < $1.id })[1].name).to(equal("piyo"))
                }
            }

            context("追加対象のクリップが1つも存在しない") {
                beforeEach {
                    try! realm.write {
                        let tag1 = self.makeTag(id: "111", name: "hoge")
                        let tag2 = self.makeTag(id: "222", name: "fuga")
                        let tag3 = self.makeTag(id: "333", name: "piyo")
                        realm.add(tag1)
                        realm.add(tag2)
                        realm.add(tag3)
                    }
                    result = service.update([
                        Clip.makeDefault(url: URL(string: "https://localhost/1")!,
                                         registeredDate: Date(timeIntervalSince1970: 0),
                                         updatedDate: Date(timeIntervalSince1970: 1000)),
                        Clip.makeDefault(url: URL(string: "https://localhost/2")!,
                                         registeredDate: Date(timeIntervalSince1970: 1000),
                                         updatedDate: Date(timeIntervalSince1970: 2000)),
                        Clip.makeDefault(url: URL(string: "https://localhost/3")!,
                                         registeredDate: Date(timeIntervalSince1970: 2000),
                                         updatedDate: Date(timeIntervalSince1970: 3000)),
                    ],
                    byAddingTags: ["hoge", "fuga", "piyo"])
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("Realm内にクリップが追加されない") {
                    let clips = realm.objects(ClipObject.self)
                    expect(clips).to(beEmpty())
                }
                it("タグは新しく増えない") {
                    let tags = realm.objects(TagObject.self)
                    expect(tags).to(haveCount(3))
                    expect(tags.sorted(by: { $0.id < $1.id })[0].id).to(equal("111"))
                    expect(tags.sorted(by: { $0.id < $1.id })[0].name).to(equal("hoge"))
                    expect(tags.sorted(by: { $0.id < $1.id })[1].id).to(equal("222"))
                    expect(tags.sorted(by: { $0.id < $1.id })[1].name).to(equal("fuga"))
                    expect(tags.sorted(by: { $0.id < $1.id })[2].id).to(equal("333"))
                    expect(tags.sorted(by: { $0.id < $1.id })[2].name).to(equal("piyo"))
                }
            }

            context("追加対象のクリップが一部存在しない") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        let tag1 = self.makeTag(id: "111", name: "hoge")
                        let tag2 = self.makeTag(id: "222", name: "fuga")
                        let tag3 = self.makeTag(id: "333", name: "piyo")
                        realm.add(obj1)
                        realm.add(obj3)
                        realm.add(tag1)
                        realm.add(tag2)
                        realm.add(tag3)
                    }
                    result = service.update([
                        Clip.makeDefault(url: URL(string: "https://localhost/1")!,
                                         registeredDate: Date(timeIntervalSince1970: 0),
                                         updatedDate: Date(timeIntervalSince1970: 1000)),
                        Clip.makeDefault(url: URL(string: "https://localhost/2")!,
                                         registeredDate: Date(timeIntervalSince1970: 1000),
                                         updatedDate: Date(timeIntervalSince1970: 2000)),
                        Clip.makeDefault(url: URL(string: "https://localhost/3")!,
                                         registeredDate: Date(timeIntervalSince1970: 2000),
                                         updatedDate: Date(timeIntervalSince1970: 3000)),
                    ],
                    byAddingTags: ["hoge", "fuga", "piyo"])
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("Realm内のクリップが更新されない") {
                    let clips = realm.objects(ClipObject.self).sorted(by: { $0.registeredAt < $1.registeredAt })
                    expect(clips).to(haveCount(2))
                    expect(clips[0].url).to(equal("https://localhost/1"))
                    expect(clips[0].descriptionText).to(equal("hoge"))
                    expect(clips[0].items).to(beEmpty())
                    expect(clips[0].tags).to(haveCount(0))
                    expect(clips[0].registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                    expect(clips[0].updatedAt).to(equal(Date(timeIntervalSince1970: 1000)))
                    expect(clips[1].url).to(equal("https://localhost/3"))
                    expect(clips[1].descriptionText).to(equal("hoge"))
                    expect(clips[1].items).to(beEmpty())
                    expect(clips[1].tags).to(haveCount(0))
                    expect(clips[1].registeredAt).to(equal(Date(timeIntervalSince1970: 2000)))
                    expect(clips[1].updatedAt).to(equal(Date(timeIntervalSince1970: 3000)))
                }
                it("タグは新しく増えない") {
                    let tags = realm.objects(TagObject.self)
                    expect(tags).to(haveCount(3))
                    expect(tags.sorted(by: { $0.id < $1.id })[0].id).to(equal("111"))
                    expect(tags.sorted(by: { $0.id < $1.id })[0].name).to(equal("hoge"))
                    expect(tags.sorted(by: { $0.id < $1.id })[1].id).to(equal("222"))
                    expect(tags.sorted(by: { $0.id < $1.id })[1].name).to(equal("fuga"))
                    expect(tags.sorted(by: { $0.id < $1.id })[2].id).to(equal("333"))
                    expect(tags.sorted(by: { $0.id < $1.id })[2].name).to(equal("piyo"))
                }
            }
        }

        describe("update(_:byAddingClipsHaving:)") {
            var result: Result<Void, ClipStorageError>!

            context("更新対象のアルバムが存在し追加対象のクリップを保持していない") {
                // TODO:
            }

            context("更新対象のアルバムが既に追加対象のクリップを保持している") {
                // TODO:
            }

            context("更新対象のアルバムが存在しない") {
                beforeEach {
                    result = service.update(Album.makeDefault(id: "111",
                                                              title: "hogehoge",
                                                              registeredDate: Date(timeIntervalSince1970: 0),
                                                              updatedDate: Date(timeIntervalSince1970: 1000)),
                                            byAddingClipsHaving: [
                                                URL(string: "https://localhost/1")!,
                                                URL(string: "https://localhost/2")!
                                            ])
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }
        }

        describe("update(_:byDeletingClipsHaving:)") {
            var result: Result<Void, ClipStorageError>!

            context("更新対象のアルバムが存在し削除対象のクリップを保持している") {
                // TODO:
            }

            context("更新対象のアルバムが削除対象のクリップを保持していない") {
                // TODO:
            }

            context("更新対象のアルバムが存在しない") {
                beforeEach {
                    result = service.update(Album.makeDefault(id: "111",
                                                              title: "hogehoge",
                                                              registeredDate: Date(timeIntervalSince1970: 0),
                                                              updatedDate: Date(timeIntervalSince1970: 1000)),
                                            byDeletingClipsHaving: [
                                                URL(string: "https://localhost/1")!,
                                                URL(string: "https://localhost/2")!
                                            ])
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }
        }

        describe("update(_:titleTo:)") {
            var result: Result<Album, ClipStorageError>!

            context("更新対象のアルバムが存在する") {
                beforeEach {
                    try! realm.write {
                        let obj = AlbumObject()
                        obj.id = "111"
                        obj.title = "hogehoge"
                        obj.registeredAt = Date(timeIntervalSince1970: 0)
                        obj.updatedAt = Date(timeIntervalSince1970: 1000)
                        realm.add(obj)
                    }
                    result = service.update(Album.makeDefault(id: "111",
                                                              title: "hogehoge",
                                                              registeredDate: Date(timeIntervalSince1970: 0),
                                                              updatedDate: Date(timeIntervalSince1970: 1000)),
                                            titleTo: "fugafuga")
                }
                it("successが返る") {
                    switch result! {
                    case .success:
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("返ってきたアルバムのタイトルが更新されている") {
                    guard case let .success(album) = result else {
                        fail("Unexpected failure")
                        return
                    }
                    expect(album.id).to(equal("111"))
                    expect(album.title).to(equal("fugafuga"))
                    expect(album.registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                    // 更新日時が更新されている
                    expect(album.updatedDate).notTo(equal(Date(timeIntervalSince1970: 1000)))
                }
                it("Realm上のアルバムのタイトルも更新されている") {
                    let obj = realm.object(ofType: AlbumObject.self, forPrimaryKey: "111")
                    expect(obj?.id).to(equal("111"))
                    expect(obj?.title).to(equal("fugafuga"))
                    expect(obj?.registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                    // 更新日時が更新されている
                    expect(obj?.updatedAt).notTo(equal(Date(timeIntervalSince1970: 1000)))
                }
            }

            context("更新対象のタイトルと同名のアルバムが既に存在する") {
                beforeEach {
                    try! realm.write {
                        let obj1 = AlbumObject()
                        obj1.id = "111"
                        obj1.title = "hogehoge"
                        obj1.registeredAt = Date(timeIntervalSince1970: 0)
                        obj1.updatedAt = Date(timeIntervalSince1970: 1000)
                        let obj2 = AlbumObject()
                        obj2.id = "222"
                        obj2.title = "fugafuga"
                        obj2.registeredAt = Date(timeIntervalSince1970: 0)
                        obj2.updatedAt = Date(timeIntervalSince1970: 1000)
                        realm.add(obj1)
                        realm.add(obj2)
                    }
                    result = service.update(Album.makeDefault(id: "111",
                                                              title: "hogehoge",
                                                              registeredDate: Date(timeIntervalSince1970: 0),
                                                              updatedDate: Date(timeIntervalSince1970: 1000)),
                                            titleTo: "fugafuga")
                }
                it("duplicatedが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected faliure")
                    case .failure(.duplicated):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("Realm上のアルバムは更新されない") {
                    let albums = realm.objects(AlbumObject.self).sorted(by: { $0.id < $1.id })
                    expect(albums[0].id).to(equal("111"))
                    expect(albums[0].title).to(equal("hogehoge"))
                    expect(albums[0].registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                    expect(albums[0].updatedAt).to(equal(Date(timeIntervalSince1970: 1000)))
                    expect(albums[1].id).to(equal("222"))
                    expect(albums[1].title).to(equal("fugafuga"))
                    expect(albums[1].registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                    expect(albums[1].updatedAt).to(equal(Date(timeIntervalSince1970: 1000)))
                }
            }

            context("更新対象のアルバムが存在しない") {
                beforeEach {
                    result = service.update(Album.makeDefault(id: "111",
                                                              title: "hogehoge",
                                                              registeredDate: Date(timeIntervalSince1970: 0),
                                                              updatedDate: Date(timeIntervalSince1970: 1000)),
                                            titleTo: "fugafuga")
                }
                it("notFoundが返る") {
                    switch result! {
                    case .success:
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }
        }

        // MARK: Delete

        // TODO:

        describe("delegeTag(_:)") {
            var result: Result<String, ClipStorageError>!

            context("削除対象のタグが存在しない") {
                beforeEach {
                    result = service.deleteTag("hoge")
                }
                it("notFoundが返る") {
                    switch result! {
                    case let .success(tag):
                        fail("Unexpected success")
                    case .failure(.notFound):
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
            }
            context("削除対象のタグが存在する") {
                context("削除対象のタグにひもづくクリップが存在しない") {
                    beforeEach {
                        try! realm.write {
                            let tag1 = self.makeTag(id: "111", name: "hoge")
                            let tag2 = self.makeTag(id: "222", name: "fuga")
                            let tag3 = self.makeTag(id: "333", name: "piyo")
                            realm.add(tag1)
                            realm.add(tag2)
                            realm.add(tag3)
                        }
                        result = service.deleteTag("fuga")
                    }
                    it("successが返り、削除対象のタグ名が返ってくる") {
                        switch result! {
                        case let .success(tag):
                            expect(tag).to(equal("fuga"))
                        case let .failure(error):
                            fail("Unexpected failure: \(error)")
                        }
                    }
                    it("Realmからタグが削除されている") {
                        let tags = realm.objects(TagObject.self).sorted(by: { $0.id < $1.id })
                        expect(tags).to(haveCount(2))
                        expect(tags[0].id).to(equal("111"))
                        expect(tags[0].name).to(equal("hoge"))
                        expect(tags[1].id).to(equal("333"))
                        expect(tags[1].name).to(equal("piyo"))
                    }
                }
                context("削除対象のタグにひもづくクリップが存在する") {
                    beforeEach {
                        try! realm.write {
                            let obj1 = self.makeClip(url: "https://localhost/1",
                                                     tags: [
                                                         self.makeTag(id: "222", name: "fuga"),
                                                     ],
                                                     registeredAt: Date(timeIntervalSince1970: 0),
                                                     updatedAt: Date(timeIntervalSince1970: 1000))
                            let obj2 = self.makeClip(url: "https://localhost/2",
                                                     tags: [
                                                         self.makeTag(id: "111", name: "hoge"),
                                                         self.makeTag(id: "222", name: "fuga"),
                                                     ],
                                                     registeredAt: Date(timeIntervalSince1970: 2000),
                                                     updatedAt: Date(timeIntervalSince1970: 3000))
                            realm.add(obj1, update: .modified)
                            realm.add(obj2, update: .modified)
                        }
                        result = service.deleteTag("fuga")
                    }
                    it("successが返り、削除対象のタグ名が返ってくる") {
                        switch result! {
                        case let .success(tag):
                            expect(tag).to(equal("fuga"))
                        case let .failure(error):
                            fail("Unexpected failure: \(error)")
                        }
                    }
                    it("Realmからタグが削除されている") {
                        let tags = realm.objects(TagObject.self)
                        expect(tags).to(haveCount(1))
                        expect(tags.first?.id).to(equal("111"))
                        expect(tags.first?.name).to(equal("hoge"))
                    }
                    it("紐づいていたClipからタグが削除される") {
                        let clips = realm.objects(ClipObject.self).sorted(by: { $0.registeredAt < $1.registeredAt })
                        expect(clips).to(haveCount(2))
                        expect(clips[0].url).to(equal("https://localhost/1"))
                        expect(clips[0].tags).to(haveCount(0))
                        expect(clips[1].url).to(equal("https://localhost/2"))
                        expect(clips[1].tags).to(haveCount(1))
                        expect(clips[1].tags.first?.id).to(equal("111"))
                        expect(clips[1].tags.first?.name).to(equal("hoge"))
                    }
                }
            }
        }
    }
}
