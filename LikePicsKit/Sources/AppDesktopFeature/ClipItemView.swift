//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import SwiftUI

struct ClipItemView: View {
    let item: ClipItem
    @EnvironmentObject var router: Router
    @Environment(\.imageQueryService) var imageQueryService
    @Environment(\.clipThumbnailProcessingQueue) var processingQueue

    @State private var isRightHovered = false
    @State private var isLeftHovered = false

    var body: some View {
        ZStack {
            LazyImage(originalSize: item.imageSize.cgSize, cacheKey: "clip-item-\(item.imageId.uuidString)") {
                try? imageQueryService.read(having: item.imageId)
            } content: { image in
                if let image {
                    image
                        .resizable()
                } else {
                    Color(NSColor.secondarySystemFill)
                }
            } placeholder: {
                Color(NSColor.secondarySystemFill)
            }
            .aspectRatio(item.imageSize.aspectRatio, contentMode: .fit)

            HStack {
                Color.clear
                    .frame(maxWidth: 120)
                    .overlay {
                        if isLeftHovered {
                            Button {
                                // TODO: 実装する
                            } label: {
                                Image(systemName: "chevron.backward")
                                    .padding(8)
                                    .contentShape(.focusEffect, RoundedRectangle(cornerRadius: 4, style: .continuous))
                                    .contentShape(.interaction, RoundedRectangle(cornerRadius: 4, style: .continuous))
                                    .bold()
                            }
                            .buttonStyle(.plain)
                            .background {
                                Color(nsColor: .systemFill)
                                    .opacity(0.5)
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            }
                        }
                    }
                    .onHover { hovering in
                        isLeftHovered = hovering
                    }

                Spacer()

                Color.clear
                    .frame(maxWidth: 120)
                    .overlay {
                        if isRightHovered {
                            Button {
                                // TODO: 実装する
                            } label: {
                                Image(systemName: "chevron.forward")
                                    .padding(8)
                                    .contentShape(.focusEffect, RoundedRectangle(cornerRadius: 4, style: .continuous))
                                    .contentShape(.interaction, RoundedRectangle(cornerRadius: 4, style: .continuous))
                                    .bold()
                            }
                            .buttonStyle(.plain)
                            .background {
                                Color(nsColor: .systemFill)
                                    .opacity(0.5)
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            }
                        }
                    }
                    .onHover { hovering in
                        isRightHovered = hovering
                    }
            }
        }
        .environment(\.imageProcessingQueue, processingQueue)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigation) {
                BackButton {
                    // TODO: アニメーションさせる
                    router.path.removeLast()
                }
            }
        }
    }
}

#Preview {
    class _ImageQueryService: ImageQueryServiceProtocol {
        func read(having id: Domain.ImageContainer.Identity) throws -> Data? { nil }
    }

    return ClipItemView(item: .init(id: UUID(),
                                    url: nil,
                                    clipId: UUID(),
                                    clipIndex: 0,
                                    imageId: UUID(),
                                    imageFileName: "",
                                    imageUrl: nil,
                                    imageSize: .init(height: 150, width: 100),
                                    imageDataSize: 0,
                                    registeredDate: Date(),
                                    updatedDate: Date()))
        .environment(\.imageQueryService, _ImageQueryService())
}
