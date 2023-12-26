//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

enum LazyImageLoadResult {
    case image(Image?)
}

final class LazyImageModel: ObservableObject {
    static var associatedKey = "ImageLoadTaskController.AssociatedKey"

    @Published var result: LazyImageLoadResult?
    private var cancellable: ImageLoadTaskCancellable?

    deinit {
        self.cancellable?.cancel()
    }

    func load(_ request: ImageRequest, with processingQueue: ImageProcessingQueue) {
        // TODO: サイズによってはキャッシュを破棄する
        cancellable = processingQueue.loadImage(request) { [weak self] response in
            DispatchQueue.main.async {
                if let response {
                    #if canImport(UIKit)
                    self?.result = .image(Image(uiImage: response.image))
                    #endif
                    #if canImport(AppKit)
                    self?.result = .image(Image(nsImage: response.image))
                    #endif
                } else {
                    // TODO: エラーハンドリング
                }
            }
        }
    }

    func cancel() {
        cancellable?.cancel()
        cancellable = nil
    }
}

public struct LazyImage<Content>: View where Content: View {
    @StateObject private var model = LazyImageModel()
    @ViewBuilder private let content: (LazyImageLoadResult?) -> Content
    @Environment(\.displayScale) var displayScale

    private let data: () async -> Data?
    private let processingQueue: ImageProcessingQueue

    public init<C, P>(data: @escaping () async -> Data?,
                      processingQueue: ImageProcessingQueue,
                      @ViewBuilder content: @escaping (Image?) -> C,
                      @ViewBuilder placeholder: @escaping () -> P) where C: View, P: View, Content == _ConditionalContent<C, P>
    {
        self.data = data
        self.processingQueue = processingQueue
        self.content = { result in
            switch result {
            case let .image(image):
                return ViewBuilder.buildEither(first: content(image))

            case .none:
                return ViewBuilder.buildEither(second: placeholder())
            }
        }
    }

    public var body: some View {
        GeometryReader { geometry in
            content(model.result)
                .onAppear {
                    model.load(.init(resize: .init(size: geometry.frame(in: .global).size, scale: displayScale), cacheKey: "", self.data), with: processingQueue)
                }
                .onDisappear {
                    model.cancel()
                }
                .position(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY)
        }
    }
}
