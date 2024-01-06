//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeatureCore
import struct Smoothie.LazyImage
import SwiftUI

struct ImageEntryView: View {
    let image: ImageSource
    let selectedOrder: Int?
    let displayOrder: Bool

    var isSelected: Bool {
        selectedOrder != nil
    }

    var body: some View {
        LazyImage {
            await ImageLoader().data(for: image)
        } content: { image in
            if let image {
                image
                    .resizable()
            } else {
                Color(NSColor.secondarySystemFill)
            }
        } placeholder: {
            Color(NSColor.secondarySystemFill)
                .aspectRatio(1, contentMode: .fit)
        }
        .environment(\.lazyImageCacheInfo, .init(key: image.id.uuidString))
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            GeometryReader { geometry in
                VStack {
                    Spacer()

                    Group {
                        if let selectedOrder, displayOrder {
                            number(selectedOrder)
                        } else {
                            checkmark
                        }
                    }
                    .offset(x: -10, y: -10)
                }
                .frame(width: geometry.size.width, alignment: .trailing)
            }
            .opacity(isSelected ? 1 : 0)
        }
    }

    @ViewBuilder
    private var checkmark: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 14, weight: .heavy))
            .foregroundStyle(.white)
            .padding(6)
            .frame(minWidth: 30, minHeight: 30)
            .background {
                ZStack {
                    Color.white
                        .clipShape(Circle())

                    Color.accentColor
                        .clipShape(Circle())
                        .padding(2)
                }
            }
    }

    @ViewBuilder
    private func number(_ number: Int) -> some View {
        Text("\(number)", bundle: .module, comment: "Image entry order")
            .font(.system(size: 16, weight: .heavy))
            .foregroundStyle(.white)
            .padding(6)
            .frame(minWidth: 30, minHeight: 30)
            .background {
                ZStack {
                    Color.white
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Color.accentColor
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .padding(2)
                }
            }
    }
}

#Preview {
    VStack {
        ImageEntryView(image: .init(fileURL: URL(string: "https://localhost")!), selectedOrder: nil, displayOrder: false)
        ImageEntryView(image: .init(fileURL: URL(string: "https://localhost")!), selectedOrder: 1, displayOrder: false)
        ImageEntryView(image: .init(fileURL: URL(string: "https://localhost")!), selectedOrder: 1, displayOrder: true)
        ImageEntryView(image: .init(fileURL: URL(string: "https://localhost")!), selectedOrder: 100, displayOrder: true)
    }
    .frame(width: 150, height: 800)
    .padding()
}
