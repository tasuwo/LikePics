//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Persistence
import SwiftUI

struct AlbumListView: View {
    @FetchRequest private var albums: FetchedResults<Persistence.Album>
    @State var layout: AlbumListLayout = .default
    @State private var isPresentingUpdateAlbumFailureAlert = false
    @State private var isPresentingDeleteAlbumFailureAlert = false
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var router: Router

    init(showHiddenItems: Bool) {
        _albums = .init(sortDescriptors: [.init(keyPath: \Persistence.Album.index, ascending: true)],
                        predicate: showHiddenItems ? nil : NSPredicate(format: "isHidden == false"),
                        animation: .default)
    }

    var body: some View {
        ScrollView {
            ZStack {
                Color.clear
                    .frame(maxWidth: .infinity)

                LazyVGrid(columns: layout.columns, spacing: AlbumListLayout.spacing) {
                    ForEach(albums.compactMap({ $0.map(to: Domain.Album.self) })) { album in
                        AlbumView(album: album)
                            .contextMenu {
                                Button {
                                    do {
                                        try context.updateAlbum(having: album.id, isHidden: !album.isHidden)
                                    } catch {
                                        isPresentingUpdateAlbumFailureAlert = true
                                    }
                                } label: {
                                    if album.isHidden {
                                        Text("Show Album", bundle: .module, comment: "Context Menu")
                                    } else {
                                        Text("Hide Album", bundle: .module, comment: "Context Menu")
                                    }
                                }

                                Button {
                                    do {
                                        try context.deleteAlbum(having: album.id)
                                    } catch {
                                        isPresentingDeleteAlbumFailureAlert = true
                                    }
                                } label: {
                                    Text("Delete Album", bundle: .module, comment: "Context Menu")
                                }
                            }
                            .onTapGesture {
                                router.path.append(Route.AlbumClipList(albumId: album.id))
                            }
                    }
                }
                .padding(.all, type(of: layout).padding)
            }
        }
        .alert(Text("Failed to Update Album", bundle: .module, comment: "Alert title."), isPresented: $isPresentingUpdateAlbumFailureAlert) {
            Button {
                isPresentingUpdateAlbumFailureAlert = false
            } label: {
                Text("OK", bundle: .module)
            }
        } message: {
            Text("Album could not be updated because an error occurred.", bundle: .module, comment: "Alert message.")
        }
        .alert(Text("Failed to Delete Album", bundle: .module, comment: "Alert title."), isPresented: $isPresentingDeleteAlbumFailureAlert) {
            Button {
                isPresentingDeleteAlbumFailureAlert = false
            } label: {
                Text("OK", bundle: .module)
            }
        } message: {
            Text("Album could not be deleted because an error occurred.", bundle: .module, comment: "Alert message.")
        }
        .onChangeFrame { size in
            layout = AlbumListLayout.layout(forWidth: size.width)
        }
    }
}

#Preview {
    let persistentContainer: NSPersistentContainer = {
        let model = NSManagedObjectModel(contentsOf: ManagedObjectModelUrl)!
        let container = NSPersistentContainer(name: "Model", managedObjectModel: model)

        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [persistentStoreDescription]

        container.loadPersistentStores { _, _ in }

        (0 ... 6).forEach { index in
            let album = Persistence.Album(context: container.viewContext)
            album.id = UUID()
            album.title = randomAlbumName()
            album.index = Int64(index)
            album.updatedDate = Date()
            album.createdDate = Date()
        }

        try! container.viewContext.save()

        return container
    }()

    func randomAlbumName() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< Int.random(in: 8 ... 15)).map { _ in letters.randomElement()! })
    }

    return AlbumListView(showHiddenItems: true)
        .environment(\.managedObjectContext, persistentContainer.viewContext)
}
