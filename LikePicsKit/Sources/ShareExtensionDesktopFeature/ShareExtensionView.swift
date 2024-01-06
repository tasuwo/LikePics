//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import ClipCreationDesktopFeature
import ClipCreationFeatureCore
import ShareExtensionFeatureCore
import SwiftUI

public struct ShareExtensionView: View {
    public let context: NSExtensionContext
    public let container: Container

    @State private var images: [ImageSource] = []

    public init(context: NSExtensionContext, container: Container) {
        self.context = context
        self.container = container
    }

    public var body: some View {
        Group {
            if images.isEmpty {
                ProgressView()
            } else {
                ClipCreateView(images: images) {
                    context.completeRequest(returningItems: nil)
                } onCancel: {
                    let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
                    context.cancelRequest(withError: cancelError)
                }
                .environment(\.managedObjectContext, container.viewContext)
            }
        }
        .task {
            do {
                switch try await ClipCreationInputResolver.inputs(for: context) {
                case .webPageURL, .none:
                    let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
                    context.cancelRequest(withError: cancelError)

                case let .imageSources(sources):
                    images = sources
                }
            } catch {
                context.cancelRequest(withError: error)
            }
        }
    }
}
