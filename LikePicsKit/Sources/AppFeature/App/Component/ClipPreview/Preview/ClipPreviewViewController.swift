//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import LikePicsUIKit
import Smoothie
import UIKit

class ClipPreviewViewController: UIViewController {
    // MARK: - Properties

    // MARK: View

    let previewView = ClipPreviewView()

    // MARK: Service

    private let imageQueryService: ImageQueryServiceProtocol
    private let thumbnailMemoryCache: MemoryCaching
    private let thumbnailDiskCache: DiskCaching
    private let pipeline: Pipeline

    // MARK: Store

    private let state: ClipPreviewViewState
    var itemId: ClipItem.Identity { state.itemId }

    // MARK: - Initializers

    init(state: ClipPreviewViewState,
         imageQueryService: ImageQueryServiceProtocol,
         thumbnailMemoryCache: MemoryCaching,
         thumbnailDiskCache: DiskCaching,
         pipeline: Pipeline)
    {
        self.imageQueryService = imageQueryService
        self.thumbnailMemoryCache = thumbnailMemoryCache
        self.thumbnailDiskCache = thumbnailDiskCache
        self.pipeline = pipeline

        self.state = state

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()

        loadPreview()
    }
}

// MARK: - Configuration

extension ClipPreviewViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = .clear

        previewView.backgroundColor = .clear
        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)
        NSLayoutConstraint.activate(previewView.constraints(fittingIn: view))
    }
}

// MARK: - Load Image

extension ClipPreviewViewController {
    private func loadPreview() {
        if let image = readThumbnail(forItemId: itemId) {
            previewView.source = .thumbnail(image, originalSize: state.imageSize)
        } else {
            previewView.source = .thumbnail(nil, originalSize: state.imageSize)
        }

        let provider = ImageDataProvider(imageId: state.imageId,
                                         cacheKey: "preview-\(itemId.uuidString)",
                                         imageQueryService: imageQueryService)
        let request = ImageRequest(source: .provider(provider))
        loadImage(request, with: pipeline, on: previewView)
    }

    private func readThumbnail(forItemId itemId: ClipItem.Identity) -> UIImage? {
        // - SeeAlso: ClipCollectionViewLayout
        if let image = thumbnailMemoryCache["clip-collection-\(itemId.uuidString)"] {
            return image
        }

        // Note: 一時的な表示に利用するものなので、表示速度を優先し decompress はしない
        if let data = thumbnailDiskCache["clip-collection-\(itemId.uuidString)"] {
            return UIImage(data: data)
        }

        return nil
    }
}
