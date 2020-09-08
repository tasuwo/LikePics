//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Nimble
import Quick
import RealmSwift

@testable import Persistence

class ClipStorageSpec: QuickSpec {
    func makeClip(url: String,
                  description: String,
                  items: [ClipItemObject],
                  tags: [TagObject],
                  registeredAt: Date,
                  updatedAt: Date) -> ClipObject
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

            context("同名のタグが存在する") {
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

            context("対象のClipが存在する") {
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

            context("対象のClipが存在しない") {
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

            context("Clipが1つも存在しない") {
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

            context("Clipが複数存在する") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 description: "hoge1",
                                                 items: [],
                                                 tags: [],
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/2",
                                                 description: "hoge2",
                                                 items: [],
                                                 tags: [],
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 description: "hoge3",
                                                 items: [],
                                                 tags: [],
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                    }
                    result = service.readAllClips()
                }
                it("successが返り、全てのClipが取得できる") {
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

        describe("readAllAlbums()") {
            var result: Result<[Album], ClipStorageError>!

            context("Albumが1つも存在しない") {
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

            context("Albumが複数存在する") {
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
                it("successが返り、全てのClipが取得できる") {
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

            context("条件にマッチするClipが1件も存在しない") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 description: "hoge1",
                                                 items: [],
                                                 tags: [],
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/2",
                                                 description: "hoge2",
                                                 items: [],
                                                 tags: [],
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 description: "hoge3",
                                                 items: [],
                                                 tags: [],
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

            context("1つのキーワードにマッチするClipが複数存在する") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/hogehoge",
                                                 description: "hoge1",
                                                 items: [],
                                                 tags: [],
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/poe",
                                                 description: "hoge2",
                                                 items: [],
                                                 tags: [],
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/hoge",
                                                 description: "hoge3",
                                                 items: [],
                                                 tags: [],
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                    }
                    result = service.searchClips(byKeywords: ["hoge"])
                }
                it("successが返り、マッチしたClipが返る") {
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
                                                 items: [],
                                                 tags: [],
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/piyo",
                                                 description: "hoge2",
                                                 items: [],
                                                 tags: [],
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/fuga",
                                                 description: "hoge3",
                                                 items: [],
                                                 tags: [],
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        let obj4 = self.makeClip(url: "https://localhost/poe",
                                                 description: "hoge4",
                                                 items: [],
                                                 tags: [],
                                                 registeredAt: Date(timeIntervalSince1970: 4000),
                                                 updatedAt: Date(timeIntervalSince1970: 5000))
                        let obj5 = self.makeClip(url: "https://localhost/hogefuga",
                                                 description: "hoge5",
                                                 items: [],
                                                 tags: [],
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
                it("successが返り、マッチしたClipが返る") {
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

            context("条件にマッチするClipが1件も存在しない") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 description: "hoge1",
                                                 items: [],
                                                 tags: [],
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/2",
                                                 description: "hoge2",
                                                 items: [],
                                                 tags: [],
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 description: "hoge3",
                                                 items: [],
                                                 tags: [],
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

            context("1つのタグにマッチするClipが複数存在する") {
                beforeEach {
                    try! realm.write {
                        let obj1 = self.makeClip(url: "https://localhost/1",
                                                 description: "hoge1",
                                                 items: [],
                                                 tags: [
                                                     self.makeTag(id: "111", name: "hoge")
                                                 ],
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/2",
                                                 description: "hoge2",
                                                 items: [],
                                                 tags: [
                                                     self.makeTag(id: "222", name: "fuga")
                                                 ],
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 description: "hoge3",
                                                 items: [],
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
                it("successが返り、マッチしたClipが返る") {
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
                                                 items: [],
                                                 tags: [
                                                     self.makeTag(id: "111", name: "hoge")
                                                 ],
                                                 registeredAt: Date(timeIntervalSince1970: 0),
                                                 updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = self.makeClip(url: "https://localhost/2",
                                                 description: "hoge2",
                                                 items: [],
                                                 tags: [
                                                     self.makeTag(id: "222", name: "piyo")
                                                 ],
                                                 registeredAt: Date(timeIntervalSince1970: 1000),
                                                 updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = self.makeClip(url: "https://localhost/3",
                                                 description: "hoge3",
                                                 items: [],
                                                 tags: [
                                                     self.makeTag(id: "333", name: "fuga")
                                                 ],
                                                 registeredAt: Date(timeIntervalSince1970: 2000),
                                                 updatedAt: Date(timeIntervalSince1970: 3000))
                        let obj4 = self.makeClip(url: "https://localhost/4",
                                                 description: "hoge4",
                                                 items: [],
                                                 tags: [
                                                     self.makeTag(id: "444", name: "poe")
                                                 ],
                                                 registeredAt: Date(timeIntervalSince1970: 4000),
                                                 updatedAt: Date(timeIntervalSince1970: 5000))
                        let obj5 = self.makeClip(url: "https://localhost/5",
                                                 description: "hoge5",
                                                 items: [],
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
                it("successが返り、マッチしたClipが返る") {
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

        // TODO:

        // MARK: Delete

        // TODO:
    }
}
