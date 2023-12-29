//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

// TODO: 無限スクロールに対応させる
// TODO: ウインドウを小さくした時の問題を修正する
struct PageView<Data: Identifiable & Hashable, Content: View>: View {
    enum Direction {
        case forward
        case backward
    }

    @ViewBuilder
    let content: (Data) -> Content

    @State private var data: [Data]
    @State private var displayData: [Data]

    @State private var currentIndex: Int
    @State private var direction: Direction?
    @State private var isLeftHovered = false
    @State private var isRightHovered = false
    // TODO: 自動切り替えできる
    @State private var animated = true

    init(_ data: [Data], from index: Int = 0, @ViewBuilder content: @escaping (Data) -> Content) {
        self.content = content
        self.data = data
        currentIndex = index
        displayData = Self.resolvePages(from: data, at: index)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 18) {
                        ForEach(displayData, id: \.self) { data in
                            content(data)
                                .id(data)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                }
                .onAppear(perform: {
                    proxy.scrollTo(data[currentIndex])
                })
                .onChange(of: direction) { _, direction in
                    guard let direction else { return }

                    switch direction {
                    case .forward:
                        guard data.indices.contains(currentIndex + 1) else { return }
                        currentIndex += 1

                    case .backward:
                        guard data.indices.contains(currentIndex - 1) else { return }
                        currentIndex -= 1
                    }

                    if animated {
                        withAnimation(.linear(duration: 0.5)) {
                            proxy.scrollTo(data[currentIndex])
                        }

                        Task {
                            try? await Task.sleep(for: .seconds(0.5))
                            self.direction = nil
                            displayData = Self.resolvePages(from: data, at: currentIndex)
                        }
                    } else {
                        proxy.scrollTo(data[currentIndex])
                        self.direction = nil
                        displayData = Self.resolvePages(from: data, at: currentIndex)
                    }
                }
                .onChange(of: displayData) { oldValue, newValue in
                    proxy.scrollTo(data[currentIndex])
                }
                .onChangeFrame { _ in
                    proxy.scrollTo(data[currentIndex])
                }
                .scrollDisabled(true)
            }
            .position(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY)
        }
        .overlay {
            HStack {
                Color.black
                    .opacity(isLeftHovered ? 0.4 : 0)
                    .frame(maxWidth: 120)
                    .overlay {
                        if isLeftHovered {
                            Button {
                                direction = .backward
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

                Color.black
                    .opacity(isRightHovered ? 0.4 : 0)
                    .frame(maxWidth: 120)
                    .overlay {
                        if isRightHovered {
                            Button {
                                direction = .forward
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
    }

    static func resolvePages(from data: [Data], at index: Int) -> [Data] {
        var pages: [Data] = []

        if data.indices.contains(index - 1) {
            pages.append(data[index - 1])
        }

        pages.append(data[index])

        if data.indices.contains(index + 1) {
            pages.append(data[index + 1])
        }

        return pages
    }
}

#Preview {
    struct Item: Identifiable, Hashable {
        let id = UUID()
        let number: Int
    }

    return PageView((0 ... 10).map({ Item(number: $0) })) {
        Text("\($0.number)")
    }
}
