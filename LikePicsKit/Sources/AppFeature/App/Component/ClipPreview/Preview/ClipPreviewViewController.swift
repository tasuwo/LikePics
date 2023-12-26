//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import LikePicsUIKit
import Smoothie
import UIKit

public class ClipPreviewViewController: UIViewController {
    // MARK: - Properties

    // MARK: View

    let previewView = ClipPreviewView()

    // MARK: Service

    private let imageQueryService: ImageQueryServiceProtocol
    private let thumbnailMemoryCache: MemoryCaching
    private let thumbnailDiskCache: DiskCaching
    private let processingQueue: ImageProcessingQueue

    // MARK: Store

    private let state: ClipPreviewViewState
    var itemId: ClipItem.Identity { state.itemId }
    private var alreadyPreviewLoaded = false

    // MARK: - Initializers

    public init(state: ClipPreviewViewState,
                imageQueryService: ImageQueryServiceProtocol,
                thumbnailMemoryCache: MemoryCaching,
                thumbnailDiskCache: DiskCaching,
                processingQueue: ImageProcessingQueue)
    {
        self.imageQueryService = imageQueryService
        self.thumbnailMemoryCache = thumbnailMemoryCache
        self.thumbnailDiskCache = thumbnailDiskCache
        self.processingQueue = processingQueue

        self.state = state

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override public func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()

        loadPreview()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 遷移アニメーションががくつかないよう、このタイミングでPreviewを読み込む
        if !alreadyPreviewLoaded {
            alreadyPreviewLoaded = true
            var request = ImageRequest(cacheKey: "preview-\(itemId.uuidString)") { [imageQueryService, state] in
                try? imageQueryService.read(having: state.imageId)
            }
            request.ignoreDiskCaching = true
            loadImage(request, with: processingQueue, on: previewView)
        }
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
            alreadyPreviewLoaded = true

            // サムネイルが存在しない場合は、アニメーションのがくつきよりもPreviewを早く表示することを優先する
            var request = ImageRequest(cacheKey: "preview-\(itemId.uuidString)") { [imageQueryService, state] in
                try? imageQueryService.read(having: state.imageId)
            }
            request.ignoreDiskCaching = true
            loadImage(request, with: processingQueue, on: previewView)
        }
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
