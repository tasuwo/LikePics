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
    override func spec() {
        let configuration = Realm.Configuration(inMemoryIdentifier: self.name, schemaVersion: 8)
        let realm = try! Realm(configuration: configuration)
        let sampleImage = UIImage(named: "TestImage", in: Bundle(for: Self.self), with: nil)!

        var service: ClipStorage!
        var imageStorage: ImageStorageProtocolMock!

        beforeEach {
            imageStorage = ImageStorageProtocolMock()
            service = try! ClipStorage(realmConfiguration: configuration, imageStorage: imageStorage)

            try! realm.write {
                realm.deleteAll()
            }
        }

        // MARK: Create

        describe("create(clip:withData:forced:)") {
            var result: Result<Void, ClipStorageError>!
            var savedData: [(Data, String, Clip.Identity)] = []

            beforeEach {
                imageStorage.saveHandler = { data, fileName, clipId in
                    savedData.append((data, fileName, clipId))
                }
            }

            afterEach {
                savedData = []
            }

            context("引数が不正ではない") {
                context("URLが同一のClipが存在しない") {
                    beforeEach {
                        result = service.create(
                            clip: Clip.makeDefault(
                                id: "1",
                                url: URL(string: "https://localhost/1")!,
                                description: "my description",
                                items: [
                                    ClipItem.makeDefault(id: "111", imageFileName: "hoge1"),
                                    ClipItem.makeDefault(id: "222", imageFileName: "hoge2"),
                                    ClipItem.makeDefault(id: "333", imageFileName: "hoge3"),
                                ],
                                tags: [],
                                isHidden: false,
                                registeredDate: Date(timeIntervalSince1970: 0),
                                updatedDate: Date(timeIntervalSince1970: 1000)
                            ),
                            withData: [
                                ("hoge1", sampleImage.pngData()!),
                                ("hoge2", sampleImage.pngData()!),
                                ("hoge3", sampleImage.pngData()!),
                                ("fuga1", sampleImage.pngData()!),
                                ("fuga2", sampleImage.pngData()!),
                                ("fuga3", sampleImage.pngData()!),
                            ],
                            forced: true
                        )
                    }

                    it("ClipとClipItemがRealmに書き込まれている") {
                        let clips = realm.objects(ClipObject.self)
                        expect(clips).to(haveCount(1))
                        expect(clips.first?.id).to(equal("1"))
                        expect(clips.first?.url).to(equal("https://localhost/1"))
                        expect(clips.first?.descriptionText).to(equal("my description"))
                        expect(clips.first?.isHidden).to(beFalse())
                        expect(clips.first?.items).to(haveCount(3))
                        expect(clips.first?.tags).to(haveCount(0))
                        expect(clips.first?.registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                        expect(clips.first?.updatedAt).to(equal(Date(timeIntervalSince1970: 1000)))
                    }
                    it("画像データが保存される") {
                        expect(imageStorage.saveCallCount).to(equal(6))
                        expect(savedData).toEventually(haveCount(6))
                    }
                }
                context("URLが同一のClipが存在する") {
                    beforeEach {
                        try! realm.write {
                            let clip = ClipObject.makeDefault(
                                id: "1",
                                url: "https://localhost/1",
                                description: "my description",
                                items: [
                                    ClipItemObject.makeDefault(id: "111",
                                                               clipId: "1",
                                                               clipIndex: 1),
                                    ClipItemObject.makeDefault(id: "222",
                                                               clipId: "1",
                                                               clipIndex: 2),
                                ],
                                tags: [
                                    TagObject.makeDefault(id: "111", name: "tag1"),
                                    TagObject.makeDefault(id: "222", name: "tag2"),
                                ],
                                registeredAt: Date(timeIntervalSince1970: 0),
                                updatedAt: Date(timeIntervalSince1970: 1000)
                            )
                            realm.add(clip)
                        }
                    }

                    context("強制上書きフラグがオン") {
                        beforeEach {
                            result = service.create(
                                clip: Clip.makeDefault(
                                    id: "9999",
                                    url: URL(string: "https://localhost/1")!,
                                    description: "my new description",
                                    items: [
                                        ClipItem.makeDefault(id: "11", imageFileName: "hoge1"),
                                        ClipItem.makeDefault(id: "22", imageFileName: "hoge2"),
                                        ClipItem.makeDefault(id: "33", imageFileName: "hoge3"),
                                    ],
                                    tags: [],
                                    isHidden: true,
                                    registeredDate: Date(timeIntervalSince1970: 8888),
                                    updatedDate: Date(timeIntervalSince1970: 9999)
                                ),
                                withData: [
                                    ("hoge1", sampleImage.pngData()!),
                                    ("hoge2", sampleImage.pngData()!),
                                    ("hoge3", sampleImage.pngData()!),
                                    ("fuga1", sampleImage.pngData()!),
                                    ("fuga2", sampleImage.pngData()!),
                                    ("fuga3", sampleImage.pngData()!),
                                ],
                                forced: true
                            )
                        }
                        it("successが返る") {
                            guard case let .failure(error) = result else {
                                expect(true).to(beTrue())
                                return
                            }
                            fail("Unexpected failed with \(error)")
                        }
                        it("Clipが上書きされる") {
                            let clips = realm.objects(ClipObject.self)
                            expect(clips).to(haveCount(1))
                            // idは引き継がれる
                            expect(clips.first?.id).to(equal("1"))
                            expect(clips.first?.url).to(equal("https://localhost/1"))
                            expect(clips.first?.descriptionText).to(equal("my new description"))
                            expect(clips.first?.items).to(haveCount(3))
                            // FIXME: 現状、tagは引き継がれる
                            expect(clips.first?.tags).to(haveCount(2))
                            expect(clips.first?.isHidden).to(beTrue())
                            // 登録日は引き継がれる
                            expect(clips.first?.registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                            expect(clips.first?.updatedAt).to(equal(Date(timeIntervalSince1970: 9999)))
                        }
                        it("既存の画像データは全て削除される") {
                            expect(imageStorage.deleteAllCallCount).to(equal(1))
                        }
                        it("新しい画像データが保存される") {
                            expect(imageStorage.saveCallCount).to(equal(6))
                            expect(savedData).toEventually(haveCount(6))
                        }
                        it("古いClipItemは全て削除される") {
                            let items = realm.objects(ClipItemObject.self).sorted(by: { $0.id < $1.id })
                            expect(items).to(haveCount(3))
                            if items.count == 3 {
                                expect(items[0].id).to(equal("11"))
                                expect(items[1].id).to(equal("22"))
                                expect(items[2].id).to(equal("33"))
                            }
                        }
                        it("除去されたタグはRealmから削除されない") {
                            let tags = realm.objects(TagObject.self).sorted(by: { $0.id < $1.id })
                            expect(tags).to(haveCount(2))
                            if tags.count == 2 {
                                expect(tags[0].id).to(equal("111"))
                                expect(tags[1].id).to(equal("222"))
                            }
                        }
                    }
                    context("強制上書きフラグがオフ") {
                        beforeEach {
                            result = service.create(
                                clip: Clip.makeDefault(
                                    id: "9999",
                                    url: URL(string: "https://localhost/1")!,
                                    description: "my description",
                                    items: [
                                        ClipItem.makeDefault(id: "11", imageFileName: "hoge1"),
                                        ClipItem.makeDefault(id: "22", imageFileName: "hoge2"),
                                        ClipItem.makeDefault(id: "33", imageFileName: "hoge3"),
                                    ],
                                    tags: [],
                                    isHidden: false,
                                    registeredDate: Date(timeIntervalSince1970: 0),
                                    updatedDate: Date(timeIntervalSince1970: 1000)
                                ),
                                withData: [
                                    ("hoge1", sampleImage.pngData()!),
                                    ("hoge2", sampleImage.pngData()!),
                                    ("hoge3", sampleImage.pngData()!),
                                    ("fuga1", sampleImage.pngData()!),
                                    ("fuga2", sampleImage.pngData()!),
                                    ("fuga3", sampleImage.pngData()!),
                                ],
                                forced: false
                            )
                        }
                        it("duplicatedエラーが返る") {
                            guard case let .failure(error) = result else {
                                fail("Unexpected success")
                                return
                            }
                            expect(error).to(equal(.duplicated))
                        }
                        it("Clipが保存されない") {
                            expect(realm.object(ofType: ClipObject.self, forPrimaryKey: "9999")).to(beNil())
                            expect(realm.object(ofType: ClipObject.self, forPrimaryKey: "1")).notTo(beNil())
                        }
                        it("画像データが保存されない") {
                            expect(imageStorage.saveCallCount).to(equal(0))
                        }
                        it("ClipItem,Tagが変わらない") {
                            expect(realm.objects(TagObject.self)).to(haveCount(2))
                            expect(realm.objects(ClipItemObject.self)).to(haveCount(2))
                        }
                    }
                }
            }
            context("引数が不正") {
                context("同一のファイル名のデータが含まれている") {
                    beforeEach {
                        result = service.create(
                            clip: .makeDefault(items: [
                                ClipItem.makeDefault(id: "11", imageFileName: "hoge1"),
                                ClipItem.makeDefault(id: "22", imageFileName: "hoge2"),
                                ClipItem.makeDefault(id: "33", imageFileName: "hoge1"),
                            ]),
                            withData: [
                                ("hoge1", sampleImage.pngData()!),
                                ("hoge2", sampleImage.pngData()!),
                                ("hoge1", sampleImage.pngData()!),
                                ("fuga1", sampleImage.pngData()!),
                                ("fuga2", sampleImage.pngData()!),
                                ("fuga3", sampleImage.pngData()!),
                            ],
                            forced: true
                        )
                    }
                    it("invalidParameterエラーが返る") {
                        guard case let .failure(error) = result else {
                            fail("Unexpected success")
                            return
                        }
                        expect(error).to(equal(.invalidParameter))
                    }
                }

                context("ClipItemに対応するファイル名のデータが欠損している") {
                    beforeEach {
                        result = service.create(
                            clip: .makeDefault(items: [
                                ClipItem.makeDefault(id: "11", imageFileName: "hoge1"),
                                ClipItem.makeDefault(id: "22", imageFileName: "hoge2"),
                                ClipItem.makeDefault(id: "33", imageFileName: "hoge3"),
                            ]),
                            withData: [
                                ("hoge1", sampleImage.pngData()!),
                                ("hoge2", sampleImage.pngData()!),
                                ("fuga1", sampleImage.pngData()!),
                                ("fuga2", sampleImage.pngData()!),
                                ("fuga3", sampleImage.pngData()!),
                            ],
                            forced: true
                        )
                    }
                    it("invalidParameterエラーが返る") {
                        guard case let .failure(error) = result else {
                            fail("Unexpected success")
                            return
                        }
                        expect(error).to(equal(.invalidParameter))
                    }
                }

                context("存在しないタグを指定した") {
                    // TODO:
                }
            }
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

        describe("readImageData(of:)") {
            var result: Result<Data, ClipStorageError>!

            context("対象の画像データが存在する") {
                beforeEach {
                    imageStorage.readImageHandler = { name, clipId in
                        expect(name).to(equal("hoge.png"))
                        expect(clipId).to(equal("111"))
                        return Data(base64Encoded: "hogehoge")!
                    }
                    result = service.readImageData(of: .makeDefault(clipId: "111",
                                                                    imageFileName: "hoge.png"))
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
                    imageStorage.readImageHandler = { name, clipId in
                        expect(name).to(equal("hoge.png"))
                        expect(clipId).to(equal("111"))
                        throw ImageStorageError.notFound
                    }
                    result = service.readImageData(of: .makeDefault(clipId: "111",
                                                                    imageFileName: "hoge.png"))
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

        // MARK: Update

        describe("updateClips(having:byHiding:)") {
            var result: Result<[Clip], ClipStorageError>!

            context("更新対象のクリップが存在する") {
                beforeEach {
                    try! realm.write {
                        let obj1 = ClipObject.makeDefault(id: "1",
                                                          url: "https://localhost/1",
                                                          registeredAt: Date(timeIntervalSince1970: 0),
                                                          updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = ClipObject.makeDefault(id: "2",
                                                          url: "https://localhost/2",
                                                          registeredAt: Date(timeIntervalSince1970: 1000),
                                                          updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = ClipObject.makeDefault(id: "3",
                                                          url: "https://localhost/3",
                                                          registeredAt: Date(timeIntervalSince1970: 2000),
                                                          updatedAt: Date(timeIntervalSince1970: 3000))
                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                    }
                    result = service.updateClips(having: ["1", "3"], byHiding: true)
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
                    result = service.updateClips(having: ["1", "2", "3"], byHiding: true)
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
                        let obj1 = ClipObject.makeDefault(id: "1",
                                                          url: "https://localhost/1",
                                                          registeredAt: Date(timeIntervalSince1970: 0),
                                                          updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj3 = ClipObject.makeDefault(id: "3",
                                                          url: "https://localhost/3",
                                                          registeredAt: Date(timeIntervalSince1970: 2000),
                                                          updatedAt: Date(timeIntervalSince1970: 3000))
                        realm.add(obj1)
                        realm.add(obj3)
                    }
                    result = service.updateClips(having: ["1", "2", "3"], byHiding: true)
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

        describe("updateClips(having:byAddingTagsHaving:)") {
            var result: Result<[Clip], ClipStorageError>!

            context("追加対象のタグとクリップが存在する") {
                beforeEach {
                    try! realm.write {
                        let obj1 = ClipObject.makeDefault(id: "1",
                                                          url: "https://localhost/1",
                                                          tags: [TagObject.makeDefault(id: "444", name: "poyo")],
                                                          registeredAt: Date(timeIntervalSince1970: 0),
                                                          updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = ClipObject.makeDefault(id: "2",
                                                          url: "https://localhost/2",
                                                          tags: [TagObject.makeDefault(id: "555", name: "huwa")],
                                                          registeredAt: Date(timeIntervalSince1970: 1000),
                                                          updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = ClipObject.makeDefault(id: "3",
                                                          url: "https://localhost/3",
                                                          tags: [TagObject.makeDefault(id: "666", name: "pien")],
                                                          registeredAt: Date(timeIntervalSince1970: 2000),
                                                          updatedAt: Date(timeIntervalSince1970: 3000))
                        let tag1 = TagObject.makeDefault(id: "111", name: "hoge")
                        let tag2 = TagObject.makeDefault(id: "222", name: "fuga")
                        let tag3 = TagObject.makeDefault(id: "333", name: "piyo")

                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                        realm.add(tag1)
                        realm.add(tag2)
                        realm.add(tag3)
                    }
                    result = service.updateClips(having: ["1", "2", "3"], byAddingTagsHaving: ["111", "222", "333"])
                }

                it("successが返る") {
                    switch result! {
                    case .success:
                        expect(true).to(beTrue())
                    case let .failure(error):
                        fail("Unexpected failure: \(error)")
                    }
                }
                it("返ってきたクリップにタグが追加されている") {
                    guard case let .success(v) = result else {
                        fail("Unexpected failure")
                        return
                    }
                    let clips = v.sorted(by: { $0.registeredDate < $1.registeredDate })
                    expect(clips).to(haveCount(3))
                    guard clips.count == 3 else { return }
                    expect(clips[0].url).to(equal(URL(string: "https://localhost/1")))
                    expect(clips[0].tags).to(haveCount(4))
                    guard clips[0].tags.count == 4 else { return }
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[0]).to(equal(.makeDefault(id: "111", name: "hoge")))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[1]).to(equal(.makeDefault(id: "222", name: "fuga")))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[2]).to(equal(.makeDefault(id: "333", name: "piyo")))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[3]).to(equal(.makeDefault(id: "444", name: "poyo")))
                    expect(clips[0].registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                    // 更新時刻が更新されている
                    expect(clips[0].updatedDate).notTo(equal(Date(timeIntervalSince1970: 1000)))

                    expect(clips[1].url).to(equal(URL(string: "https://localhost/2")))
                    expect(clips[1].tags).to(haveCount(4))
                    guard clips[1].tags.count == 3 else { return }
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[0]).to(equal(.makeDefault(id: "111", name: "hoge")))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[1]).to(equal(.makeDefault(id: "222", name: "fuga")))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[2]).to(equal(.makeDefault(id: "333", name: "piyo")))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[3]).to(equal(.makeDefault(id: "555", name: "fuwa")))
                    expect(clips[1].registeredDate).to(equal(Date(timeIntervalSince1970: 1000)))
                    // 更新時刻が更新されている
                    expect(clips[1].updatedDate).notTo(equal(Date(timeIntervalSince1970: 2000)))

                    expect(clips[2].url).to(equal(URL(string: "https://localhost/3")))
                    expect(clips[2].tags).to(haveCount(4))
                    guard clips[2].tags.count == 3 else { return }
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[0]).to(equal(.makeDefault(id: "111", name: "hoge")))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[1]).to(equal(.makeDefault(id: "222", name: "fuga")))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[2]).to(equal(.makeDefault(id: "333", name: "piyo")))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[3]).to(equal(.makeDefault(id: "666", name: "pien")))
                    expect(clips[2].registeredDate).to(equal(Date(timeIntervalSince1970: 2000)))
                    // 更新時刻が更新されている
                    expect(clips[2].updatedDate).notTo(equal(Date(timeIntervalSince1970: 3000)))
                }
                it("Realm内のクリップが更新されている") {
                    let clips = realm.objects(ClipObject.self).sorted(by: { $0.registeredAt < $1.registeredAt })
                    expect(clips).to(haveCount(3))
                    guard clips.count == 3 else { return }
                    expect(clips[0].url).to(equal("https://localhost/1"))
                    expect(clips[0].tags).to(haveCount(4))
                    guard clips[0].tags.count == 4 else { return }
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[0].id).to(equal("111"))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[0].name).to(equal("hoge"))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[1].id).to(equal("222"))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[1].name).to(equal("fuga"))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[2].id).to(equal("333"))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[2].name).to(equal("piyo"))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[3].id).to(equal("444"))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[3].name).to(equal("poyo"))
                    expect(clips[0].registeredAt).to(equal(Date(timeIntervalSince1970: 0)))
                    // 更新時刻が更新されている
                    expect(clips[0].updatedAt).notTo(equal(Date(timeIntervalSince1970: 1000)))

                    expect(clips[1].url).to(equal("https://localhost/2"))
                    expect(clips[1].tags).to(haveCount(4))
                    guard clips[1].tags.count == 4 else { return }
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[0].id).to(equal("111"))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[0].name).to(equal("hoge"))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[1].id).to(equal("222"))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[1].name).to(equal("fuga"))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[2].id).to(equal("333"))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[2].name).to(equal("piyo"))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[3].id).to(equal("555"))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[3].name).to(equal("huwa"))
                    expect(clips[1].registeredAt).to(equal(Date(timeIntervalSince1970: 1000)))
                    // 更新時刻が更新されている
                    expect(clips[1].updatedAt).notTo(equal(Date(timeIntervalSince1970: 2000)))

                    expect(clips[2].url).to(equal("https://localhost/3"))
                    expect(clips[2].tags).to(haveCount(4))
                    guard clips[2].tags.count == 4 else { return }
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[0].id).to(equal("111"))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[0].name).to(equal("hoge"))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[1].id).to(equal("222"))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[1].name).to(equal("fuga"))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[2].id).to(equal("333"))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[2].name).to(equal("piyo"))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[3].id).to(equal("666"))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[3].name).to(equal("pien"))
                    expect(clips[2].registeredAt).to(equal(Date(timeIntervalSince1970: 2000)))
                    // 更新時刻が更新されている
                    expect(clips[2].updatedAt).notTo(equal(Date(timeIntervalSince1970: 3000)))
                }
                it("タグは新しく増えない") {
                    let tags = realm.objects(TagObject.self)
                    expect(tags).to(haveCount(6))
                    guard tags.count == 6 else { return }
                    expect(tags.sorted(by: { $0.id < $1.id })[0].id).to(equal("111"))
                    expect(tags.sorted(by: { $0.id < $1.id })[0].name).to(equal("hoge"))
                    expect(tags.sorted(by: { $0.id < $1.id })[1].id).to(equal("222"))
                    expect(tags.sorted(by: { $0.id < $1.id })[1].name).to(equal("fuga"))
                    expect(tags.sorted(by: { $0.id < $1.id })[2].id).to(equal("333"))
                    expect(tags.sorted(by: { $0.id < $1.id })[2].name).to(equal("piyo"))
                    expect(tags.sorted(by: { $0.id < $1.id })[3].id).to(equal("444"))
                    expect(tags.sorted(by: { $0.id < $1.id })[3].name).to(equal("poyo"))
                    expect(tags.sorted(by: { $0.id < $1.id })[4].id).to(equal("555"))
                    expect(tags.sorted(by: { $0.id < $1.id })[4].name).to(equal("huwa"))
                    expect(tags.sorted(by: { $0.id < $1.id })[5].id).to(equal("666"))
                    expect(tags.sorted(by: { $0.id < $1.id })[5].name).to(equal("pien"))
                }
            }

            context("追加対象のタグが1つも存在しない") {
                beforeEach {
                    try! realm.write {
                        let obj1 = ClipObject.makeDefault(id: "1",
                                                          url: "https://localhost/1",
                                                          registeredAt: Date(timeIntervalSince1970: 0),
                                                          updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = ClipObject.makeDefault(id: "2",
                                                          url: "https://localhost/2",
                                                          registeredAt: Date(timeIntervalSince1970: 1000),
                                                          updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = ClipObject.makeDefault(id: "3",
                                                          url: "https://localhost/3",
                                                          registeredAt: Date(timeIntervalSince1970: 2000),
                                                          updatedAt: Date(timeIntervalSince1970: 3000))
                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                    }
                    result = service.updateClips(having: ["1", "2", "3"], byAddingTagsHaving: ["111", "222", "333"])
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
                        let obj1 = ClipObject.makeDefault(id: "1",
                                                          url: "https://localhost/1",
                                                          registeredAt: Date(timeIntervalSince1970: 0),
                                                          updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = ClipObject.makeDefault(id: "2",
                                                          url: "https://localhost/2",
                                                          registeredAt: Date(timeIntervalSince1970: 1000),
                                                          updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = ClipObject.makeDefault(id: "3",
                                                          url: "https://localhost/3",
                                                          registeredAt: Date(timeIntervalSince1970: 2000),
                                                          updatedAt: Date(timeIntervalSince1970: 3000))
                        let tag1 = TagObject.makeDefault(id: "111", name: "hoge")
                        let tag3 = TagObject.makeDefault(id: "333", name: "piyo")

                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                        realm.add(tag1)
                        realm.add(tag3)
                    }
                    result = service.updateClips(having: ["1", "2", "3"], byAddingTagsHaving: ["111", "222", "333"])
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
                        let tag1 = TagObject.makeDefault(id: "111", name: "hoge")
                        let tag2 = TagObject.makeDefault(id: "222", name: "fuga")
                        let tag3 = TagObject.makeDefault(id: "333", name: "piyo")
                        realm.add(tag1)
                        realm.add(tag2)
                        realm.add(tag3)
                    }
                    result = service.updateClips(having: ["1", "2", "3"], byAddingTagsHaving: ["111", "222", "333"])
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
                        let obj1 = ClipObject.makeDefault(id: "1",
                                                          url: "https://localhost/1",
                                                          registeredAt: Date(timeIntervalSince1970: 0),
                                                          updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj3 = ClipObject.makeDefault(id: "2",
                                                          url: "https://localhost/3",
                                                          registeredAt: Date(timeIntervalSince1970: 2000),
                                                          updatedAt: Date(timeIntervalSince1970: 3000))
                        let tag1 = TagObject.makeDefault(id: "111", name: "hoge")
                        let tag2 = TagObject.makeDefault(id: "222", name: "fuga")
                        let tag3 = TagObject.makeDefault(id: "333", name: "piyo")
                        realm.add(obj1)
                        realm.add(obj3)
                        realm.add(tag1)
                        realm.add(tag2)
                        realm.add(tag3)
                    }
                    result = service.updateClips(having: ["1", "2", "3"], byAddingTagsHaving: ["111", "222", "333"])
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

        describe("updateClips(having:byReplacingTagsHaving:)") {
            var result: Result<[Clip], ClipStorageError>!

            context("追加対象のタグとクリップが存在する") {
                beforeEach {
                    try! realm.write {
                        let obj1 = ClipObject.makeDefault(id: "1",
                                                          url: "https://localhost/1",
                                                          tags: [TagObject.makeDefault(id: "444", name: "poyo")],
                                                          registeredAt: Date(timeIntervalSince1970: 0),
                                                          updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = ClipObject.makeDefault(id: "2",
                                                          url: "https://localhost/2",
                                                          tags: [TagObject.makeDefault(id: "555", name: "huwa")],
                                                          registeredAt: Date(timeIntervalSince1970: 1000),
                                                          updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = ClipObject.makeDefault(id: "3",
                                                          url: "https://localhost/3",
                                                          tags: [TagObject.makeDefault(id: "666", name: "pien")],
                                                          registeredAt: Date(timeIntervalSince1970: 2000),
                                                          updatedAt: Date(timeIntervalSince1970: 3000))
                        let tag1 = TagObject.makeDefault(id: "111", name: "hoge")
                        let tag2 = TagObject.makeDefault(id: "222", name: "fuga")
                        let tag3 = TagObject.makeDefault(id: "333", name: "piyo")

                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                        realm.add(tag1)
                        realm.add(tag2)
                        realm.add(tag3)
                    }
                    result = service.updateClips(having: ["1", "2", "3"], byReplacingTagsHaving: ["111", "222", "333"])
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
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[0]).to(equal(.makeDefault(id: "111", name: "hoge")))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[1]).to(equal(.makeDefault(id: "222", name: "fuga")))
                    expect(clips[0].tags.sorted(by: { $0.id < $1.id })[2]).to(equal(.makeDefault(id: "333", name: "piyo")))
                    expect(clips[0].registeredDate).to(equal(Date(timeIntervalSince1970: 0)))
                    // 更新時刻が更新されている
                    expect(clips[0].updatedDate).notTo(equal(Date(timeIntervalSince1970: 1000)))

                    expect(clips[1].url).to(equal(URL(string: "https://localhost/2")))
                    expect(clips[1].tags).to(haveCount(3))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[0]).to(equal(.makeDefault(id: "111", name: "hoge")))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[1]).to(equal(.makeDefault(id: "222", name: "fuga")))
                    expect(clips[1].tags.sorted(by: { $0.id < $1.id })[2]).to(equal(.makeDefault(id: "333", name: "piyo")))
                    expect(clips[1].registeredDate).to(equal(Date(timeIntervalSince1970: 1000)))
                    // 更新時刻が更新されている
                    expect(clips[1].updatedDate).notTo(equal(Date(timeIntervalSince1970: 2000)))

                    expect(clips[2].url).to(equal(URL(string: "https://localhost/3")))
                    expect(clips[2].tags).to(haveCount(3))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[0]).to(equal(.makeDefault(id: "111", name: "hoge")))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[1]).to(equal(.makeDefault(id: "222", name: "fuga")))
                    expect(clips[2].tags.sorted(by: { $0.id < $1.id })[2]).to(equal(.makeDefault(id: "333", name: "piyo")))
                    expect(clips[2].registeredDate).to(equal(Date(timeIntervalSince1970: 2000)))
                    // 更新時刻が更新されている
                    expect(clips[2].updatedDate).notTo(equal(Date(timeIntervalSince1970: 3000)))
                }
                it("Realm内のクリップのタグが置き換えられている") {
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
                it("置き換えられたタグは削除されない") {
                    let tags = realm.objects(TagObject.self)
                    expect(tags).to(haveCount(6))
                    guard tags.count == 6 else { return }
                    expect(tags.sorted(by: { $0.id < $1.id })[0].id).to(equal("111"))
                    expect(tags.sorted(by: { $0.id < $1.id })[0].name).to(equal("hoge"))
                    expect(tags.sorted(by: { $0.id < $1.id })[1].id).to(equal("222"))
                    expect(tags.sorted(by: { $0.id < $1.id })[1].name).to(equal("fuga"))
                    expect(tags.sorted(by: { $0.id < $1.id })[2].id).to(equal("333"))
                    expect(tags.sorted(by: { $0.id < $1.id })[2].name).to(equal("piyo"))
                    expect(tags.sorted(by: { $0.id < $1.id })[3].id).to(equal("444"))
                    expect(tags.sorted(by: { $0.id < $1.id })[3].name).to(equal("poyo"))
                    expect(tags.sorted(by: { $0.id < $1.id })[4].id).to(equal("555"))
                    expect(tags.sorted(by: { $0.id < $1.id })[4].name).to(equal("huwa"))
                    expect(tags.sorted(by: { $0.id < $1.id })[5].id).to(equal("666"))
                    expect(tags.sorted(by: { $0.id < $1.id })[5].name).to(equal("pien"))
                }
            }

            context("追加対象のタグが1つも存在しない") {
                beforeEach {
                    try! realm.write {
                        let obj1 = ClipObject.makeDefault(id: "1",
                                                          url: "https://localhost/1",
                                                          registeredAt: Date(timeIntervalSince1970: 0),
                                                          updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = ClipObject.makeDefault(id: "2",
                                                          url: "https://localhost/2",
                                                          registeredAt: Date(timeIntervalSince1970: 1000),
                                                          updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = ClipObject.makeDefault(id: "3",
                                                          url: "https://localhost/3",
                                                          registeredAt: Date(timeIntervalSince1970: 2000),
                                                          updatedAt: Date(timeIntervalSince1970: 3000))
                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                    }
                    result = service.updateClips(having: ["1", "2", "3"], byReplacingTagsHaving: ["111", "222", "333"])
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
                        let obj1 = ClipObject.makeDefault(id: "1",
                                                          url: "https://localhost/1",
                                                          registeredAt: Date(timeIntervalSince1970: 0),
                                                          updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj2 = ClipObject.makeDefault(id: "2",
                                                          url: "https://localhost/2",
                                                          registeredAt: Date(timeIntervalSince1970: 1000),
                                                          updatedAt: Date(timeIntervalSince1970: 2000))
                        let obj3 = ClipObject.makeDefault(id: "3",
                                                          url: "https://localhost/3",
                                                          registeredAt: Date(timeIntervalSince1970: 2000),
                                                          updatedAt: Date(timeIntervalSince1970: 3000))
                        let tag1 = TagObject.makeDefault(id: "111", name: "hoge")
                        let tag3 = TagObject.makeDefault(id: "333", name: "piyo")

                        realm.add(obj1)
                        realm.add(obj2)
                        realm.add(obj3)
                        realm.add(tag1)
                        realm.add(tag3)
                    }
                    result = service.updateClips(having: ["1", "2", "3"], byReplacingTagsHaving: ["111", "222", "333"])
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
                        let tag1 = TagObject.makeDefault(id: "111", name: "hoge")
                        let tag2 = TagObject.makeDefault(id: "222", name: "fuga")
                        let tag3 = TagObject.makeDefault(id: "333", name: "piyo")
                        realm.add(tag1)
                        realm.add(tag2)
                        realm.add(tag3)
                    }
                    result = service.updateClips(having: ["1", "2", "3"], byReplacingTagsHaving: ["111", "222", "333"])
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
                        let obj1 = ClipObject.makeDefault(id: "1",
                                                          url: "https://localhost/1",
                                                          registeredAt: Date(timeIntervalSince1970: 0),
                                                          updatedAt: Date(timeIntervalSince1970: 1000))
                        let obj3 = ClipObject.makeDefault(id: "2",
                                                          url: "https://localhost/3",
                                                          registeredAt: Date(timeIntervalSince1970: 2000),
                                                          updatedAt: Date(timeIntervalSince1970: 3000))
                        let tag1 = TagObject.makeDefault(id: "111", name: "hoge")
                        let tag2 = TagObject.makeDefault(id: "222", name: "fuga")
                        let tag3 = TagObject.makeDefault(id: "333", name: "piyo")
                        realm.add(obj1)
                        realm.add(obj3)
                        realm.add(tag1)
                        realm.add(tag2)
                        realm.add(tag3)
                    }
                    result = service.updateClips(having: ["1", "2", "3"], byReplacingTagsHaving: ["111", "222", "333"])
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

        describe("updateAlbum(having:byAddingClipsHaving:)") {
            var result: Result<Void, ClipStorageError>!

            context("更新対象のアルバムが存在し追加対象のクリップを保持していない") {
                // TODO:
            }

            context("更新対象のアルバムが既に追加対象のクリップを保持している") {
                // TODO:
            }

            context("更新対象のアルバムが存在しない") {
                beforeEach {
                    result = service.updateAlbum(having: "111", byAddingClipsHaving: ["1", "2"])
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

        describe("updateAlbum(having:byDeletingClipsHaving:)") {
            var result: Result<Void, ClipStorageError>!

            context("更新対象のアルバムが存在し削除対象のクリップを保持している") {
                // TODO:
            }

            context("更新対象のアルバムが削除対象のクリップを保持していない") {
                // TODO:
            }

            context("更新対象のアルバムが存在しない") {
                beforeEach {
                    result = service.updateAlbum(having: "111", byDeletingClipsHaving: ["1", "2"])
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

        describe("updateAlbum(having:titleTo:)") {
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
                    result = service.updateAlbum(having: "111", titleTo: "fugafuga")
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
                    result = service.updateAlbum(having: "111", titleTo: "fugafuga")
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
                    result = service.updateAlbum(having: "111", titleTo: "fugafuga")
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

        describe("updateTag(having:nameTo:)") {
            // TODO:
        }

        // MARK: Delete

        // TODO:

        describe("delete(") {
        }

        describe("delegeTags(having:)") {
            var result: Result<[Tag], ClipStorageError>!

            context("削除対象のタグが存在しない") {
                beforeEach {
                    result = service.deleteTags(having: ["111"])
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
            context("削除対象のタグが存在する") {
                context("削除対象のタグにひもづくクリップが存在しない") {
                    beforeEach {
                        try! realm.write {
                            let tag1 = TagObject.makeDefault(id: "111", name: "hoge")
                            let tag2 = TagObject.makeDefault(id: "222", name: "fuga")
                            let tag3 = TagObject.makeDefault(id: "333", name: "piyo")
                            realm.add(tag1)
                            realm.add(tag2)
                            realm.add(tag3)
                        }
                        result = service.deleteTags(having: ["222"])
                    }
                    it("successが返り、削除対象のタグ名が返ってくる") {
                        switch result! {
                        case let .success(tags):
                            expect(tags).to(equal([.makeDefault(id: "222", name: "fuga")]))
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
                            let obj1 = ClipObject.makeDefault(id: "1",
                                                              url: "https://localhost/1",
                                                              tags: [
                                                                  TagObject.makeDefault(id: "222", name: "fuga"),
                                                              ],
                                                              registeredAt: Date(timeIntervalSince1970: 0),
                                                              updatedAt: Date(timeIntervalSince1970: 1000))
                            let obj2 = ClipObject.makeDefault(id: "2",
                                                              url: "https://localhost/2",
                                                              tags: [
                                                                  TagObject.makeDefault(id: "111", name: "hoge"),
                                                                  TagObject.makeDefault(id: "222", name: "fuga"),
                                                              ],
                                                              registeredAt: Date(timeIntervalSince1970: 2000),
                                                              updatedAt: Date(timeIntervalSince1970: 3000))
                            realm.add(obj1, update: .modified)
                            realm.add(obj2, update: .modified)
                        }
                        result = service.deleteTags(having: ["222"])
                    }
                    it("successが返り、削除対象のタグ名が返ってくる") {
                        switch result! {
                        case let .success(tags):
                            expect(tags).to(equal([.makeDefault(id: "222", name: "fuga")]))
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
