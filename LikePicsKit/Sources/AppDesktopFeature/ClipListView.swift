//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import MasonryGrid
import Persistence
import SwiftUI

struct ClipListView: View {
    let clips: [Domain.Clip]

    @State private var layout: ClipListLayout = .default
    @State private var clipEditableViewModel = ClipEditableViewModel()
    @Namespace private var animation
    @EnvironmentObject private var router: Router
    @Environment(\.managedObjectContext) private var context

    var body: some View {
        if clips.isEmpty {
            EmptyView()
        } else {
            ScrollView {
                VMasonryGrid(clips,
                             numberOfColumns: layout.numberOfColumns,
                             columnSpacing: layout.spacing,
                             contentSpacing: layout.spacing)
                { clip in
                    ClipView(clip: clip)
                        .matchedGeometryEffect(id: clip.id, in: animation)
                        .onTapGesture {
                            if let primaryItem = clip.primaryItem {
                                router.path.append(Route.ClipItemPage(clips: clips, clipItem: primaryItem))
                            }
                        }
                        .contextMenu {
                            Button {
                                clipEditableViewModel.updateClip(having: clip.id, isHidden: !clip.isHidden, in: context)
                            } label: {
                                if clip.isHidden {
                                    Text("Show Clip", bundle: .module, comment: "Clip context menu.")
                                } else {
                                    Text("Hide Clip", bundle: .module, comment: "Clip context menu.")
                                }
                            }

                            // TODO: アルバム/タグに追加できる

                            Button(role: .destructive) {
                                clipEditableViewModel.requestToDeleteClip(id: clip.id, in: context)
                            } label: {
                                Text("Delete Clip", bundle: .module, comment: "Clip context menu.")
                            }
                        }
                } height: { clip in
                    // 配置計算に利用されるだけなので、相対的なサイズで良い
                    let columnWidth: CGFloat = 100

                    guard let primaryItem = clip.primaryItem else { return columnWidth }

                    var columnHeight = columnWidth / primaryItem.imageSize.cgSize.width * primaryItem.imageSize.cgSize.height

                    if clip.secondaryItem != nil {
                        columnHeight += 16
                    }

                    if clip.tertiaryItem != nil {
                        columnHeight += 16
                    }

                    return columnHeight
                }
                .padding(.all, type(of: layout).padding)
            }
            .alertForClipEditableView(viewModel: clipEditableViewModel)
            .onChangeFrame { size in
                layout = ClipListLayout.layout(forWidth: size.width)
            }
        }
    }
}

#Preview {
    class _ImageQueryService: ImageQueryServiceProtocol {
        func read(having id: Domain.ImageContainer.Identity) throws -> Data? { nil }
    }

    func makeClip(size: ImageSize) -> Domain.Clip {
        return .init(id: UUID(),
                     description: "",
                     items: [
                         .init(id: UUID(),
                               url: nil,
                               clipId: UUID(),
                               clipIndex: 0,
                               imageId: UUID(),
                               imageFileName: "",
                               imageUrl: nil,
                               imageSize: size,
                               imageDataSize: 0,
                               registeredDate: Date(),
                               updatedDate: Date())
                     ],
                     isHidden: false,
                     dataSize: 0,
                     registeredDate: Date(),
                     updatedDate: Date())
    }

    return ClipListView(clips: (0 ... 100).map { _ in
        makeClip(size: .init(height: CGFloat((100 ... 150).randomElement()!), width: 100))
    })
    .environment(\.imageQueryService, _ImageQueryService())
}
