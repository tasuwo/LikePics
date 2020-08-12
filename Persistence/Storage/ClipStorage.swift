//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

public class ClipStorage {
    public enum StorageConfiguration {
        static let realmFileName = "clips.realm"

        public static func makeConfiguration() -> Realm.Configuration {
            var configuration = Realm.Configuration()

            if let appGroupIdentifier = Constants.appGroupIdentifier,
                let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
            {
                configuration.fileURL = directory.appendingPathComponent(self.realmFileName)
            } else {
                // TODO: Error handling
            }

            return configuration
        }
    }

    private let configuration: Realm.Configuration
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.queue")

    // MARK: - Lifecycle

    public init(realmConfiguration: Realm.Configuration) {
        self.configuration = realmConfiguration
    }

    public convenience init() {
        self.init(realmConfiguration: StorageConfiguration.makeConfiguration())
    }
}

extension ClipStorage: ClipStorageProtocol {
    // MARK: - ClipStorageProtocol

    public func create(clip: Clip) -> Result<Void, ClipStorageError> {
        self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            if let _ = realm.object(ofType: ClipObject.self, forPrimaryKey: clip.asManagedObject().url) {
                return .failure(.duplicated)
            }

            do {
                try realm.write {
                    realm.add(clip.asManagedObject())
                }
                return .success(())
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func readAllClips() -> Result<[Clip], ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }
            return .success(realm.objects(ClipObject.self).map { Clip.make(by: $0) })
        }
    }

    public func readClip(ofUrl url: URL) -> Result<Clip, ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: url.absoluteString) else {
                return .failure(.notFound)
            }

            return .success(.make(by: clip))
        }
    }

    public func updateItems(inClipOfUrl url: URL, to items: [ClipItem]) -> Result<Clip, ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: url.absoluteString) else {
                return .failure(.notFound)
            }

            do {
                try realm.write {
                    realm.delete(clip.webImages)
                    clip.webImages.append(objectsIn: items.map { $0.asManagedObject() })
                }
                return .success(.make(by: clip))
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func removeClip(ofUrl url: URL) -> Result<Clip, ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: url.absoluteString) else {
                return .failure(.notFound)
            }

            do {
                try realm.write {
                    realm.delete(clip)
                }
                return .success(.make(by: clip))
            } catch {
                return .failure(.internalError)
            }
        }
    }
}
