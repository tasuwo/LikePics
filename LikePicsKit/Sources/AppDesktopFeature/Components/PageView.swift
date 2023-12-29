//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

// TODO: 無限スクロールに対応させる
struct PageView<Data: Identifiable & Hashable, Content: View>: View {
    enum Direction {
        case forward
        case backward

        var imageName: String {
            switch self {
            case .forward: "chevron.forward"
            case .backward: "chevron.backward"
            }
        }
    }

    class AnimationCoordinator: ObservableObject {
        @Published private(set) var direction: Direction?
        @Published var animated = true

        private var lastTransitionRequestedDate: Date?

        @MainActor
        func onRequestTranstition(to direction: Direction) {
            let requestedDate = Date()

            if let lastTransitionRequestedDate {
                if requestedDate.timeIntervalSince(lastTransitionRequestedDate) < 0.5 {
                    animated = false
                } else if requestedDate.timeIntervalSince(lastTransitionRequestedDate) > 1 {
                    animated = true
                }
            }

            lastTransitionRequestedDate = requestedDate
            self.direction = direction
        }

        @MainActor
        func onTransitioned() {
            direction = nil
        }
    }

    @ViewBuilder
    let content: (Data) -> Content

    @State private var data: [Data]
    @State private var displayData: [Data]

    @State private var currentIndex: Int
    @State private var isLeftHovered = false
    @State private var isRightHovered = false
    @StateObject private var coordinator = AnimationCoordinator()

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
                .onChange(of: coordinator.direction) { _, direction in
                    guard let direction else { return }

                    switch direction {
                    case .forward:
                        guard data.indices.contains(currentIndex + 1) else { return }
                        currentIndex += 1

                    case .backward:
                        guard data.indices.contains(currentIndex - 1) else { return }
                        currentIndex -= 1
                    }

                    if coordinator.animated {
                        withAnimation(.linear(duration: 0.5)) {
                            proxy.scrollTo(data[currentIndex])
                        }

                        Task {
                            try? await Task.sleep(for: .seconds(0.5))
                            coordinator.onTransitioned()
                            displayData = Self.resolvePages(from: data, at: currentIndex)
                        }
                    } else {
                        proxy.scrollTo(data[currentIndex])
                        coordinator.onTransitioned()
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
                Color.clear
                    .frame(width: 120)
                    .overlay {
                        if isLeftHovered {
                            Button {
                                coordinator.onRequestTranstition(to: .backward)
                            } label: {
                                pagingButton(for: .backward)
                            }
                            .buttonStyle(.plain)
                            .background {
                                Color(nsColor: .systemFill)
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            }
                        }
                    }
                    .onHover { hovering in
                        withAnimation(.linear(duration: 0.1)) {
                            isLeftHovered = hovering
                        }
                    }

                Spacer()

                Color.clear
                    .frame(width: 120)
                    .overlay {
                        if isRightHovered {
                            Button {
                                coordinator.onRequestTranstition(to: .forward)
                            } label: {
                                pagingButton(for: .forward)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onHover { hovering in
                        withAnimation(.linear(duration: 0.1)) {
                            isRightHovered = hovering
                        }
                    }
            }
        }
    }

    @ViewBuilder
    func pagingButton(for direction: Direction) -> some View {
        ZStack {
            Color.white
                .frame(width: 44)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            Image(systemName: direction.imageName)
                .foregroundColor(.black)
                .font(.title)
                .bold()
        }
        .opacity(0.5)
        .contentShape(.focusEffect, RoundedRectangle(cornerRadius: 4, style: .continuous))
        .contentShape(.interaction, RoundedRectangle(cornerRadius: 4, style: .continuous))
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
