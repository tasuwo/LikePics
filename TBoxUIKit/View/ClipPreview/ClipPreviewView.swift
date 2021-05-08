//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import UIKit

public protocol ClipPreviewPageViewDelegate: AnyObject {
    func clipPreviewPageViewWillBeginZoom(_ view: ClipPreviewView)
}

public class ClipPreviewView: UIView {
    public enum Source: Equatable {
        public struct Image: Equatable {
            let uiImage: UIImage

            public init(uiImage: UIImage) {
                self.uiImage = uiImage
            }
        }

        public struct Thumbnail: Equatable {
            let uiImage: UIImage
            let originalSize: CGSize

            public init(uiImage: UIImage, originalSize: CGSize) {
                self.uiImage = uiImage
                self.originalSize = originalSize
            }
        }

        case image(Image)
        case thumbnail(Thumbnail)

        var uiImage: UIImage {
            switch self {
            case let .image(image):
                return image.uiImage

            case let .thumbnail(thumbnail):
                return thumbnail.uiImage
            }
        }

        var imageSize: CGSize {
            return uiImage.size
        }

        var originalSize: CGSize {
            switch self {
            case let .image(image):
                return image.uiImage.size

            case let .thumbnail(thumbnail):
                return thumbnail.originalSize
            }
        }
    }

    public var source: Source? {
        didSet {
            guard let source = source else { return }
            imageView.image = source.uiImage
        }
    }

    public var image: UIImage? {
        imageView.image
    }

    public var panGestureRecognizer: UIPanGestureRecognizer {
        scrollView.panGestureRecognizer
    }

    public var contentOffset: AnyPublisher<CGPoint, Never> {
        KeyValueObservingPublisher(object: scrollView, keyPath: \.contentOffset, options: .new)
            .eraseToAnyPublisher()
    }

    private let _isMinimumZoomScale: CurrentValueSubject<Bool, Never> = .init(true)
    public var isMinimumZoomScale: AnyPublisher<Bool, Never> {
        _isMinimumZoomScale.eraseToAnyPublisher()
    }

    public var isScrollEnabled: Bool {
        get {
            scrollView.isScrollEnabled
        }
        set {
            scrollView.isScrollEnabled = newValue
        }
    }

    public var initialImageFrame: CGRect {
        guard let source = source else { return .zero }
        let scale = min(1, Self.calcScaleScaleToFit(forSize: source.originalSize, fittingIn: bounds.size))
        let initialImageSize = CGSize(width: source.originalSize.width * scale,
                                      height: source.originalSize.height * scale)
        return CGRect(origin: CGPoint(x: (bounds.width - initialImageSize.width) / 2,
                                      y: (bounds.height - initialImageSize.height) / 2),
                      size: initialImageSize)
    }

    public var zoomGestureRecognizer: UITapGestureRecognizer {
        return doubleTapGestureRecognizer
    }

    public var isLoading: Bool {
        get {
            indicator.isAnimating
        }
        set {
            if newValue {
                imageView.alpha = 0.8
                indicator.startAnimating()
            } else {
                imageView.alpha = 1.0
                indicator.stopAnimating()
            }
        }
    }

    public weak var delegate: ClipPreviewPageViewDelegate?

    private var doubleTapGestureRecognizer: UITapGestureRecognizer!

    @IBOutlet var baseView: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var indicator: UIActivityIndicatorView!

    @IBOutlet var leftInsetConstraint: NSLayoutConstraint!
    @IBOutlet var bottomInsetConstraint: NSLayoutConstraint!
    @IBOutlet var rightInsetConstraint: NSLayoutConstraint!
    @IBOutlet var topInsetConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override public init(frame: CGRect) {
        super.init(frame: frame)

        configureViewHierarchy()
        configureGestureRecognizer()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        configureViewHierarchy()
        configureGestureRecognizer()
    }

    // MARK: - Methods

    static func calcScaleScaleToFit(forSize source: CGSize, fittingIn destination: CGSize) -> CGFloat {
        let widthScale = destination.width / source.width
        let heightScale = destination.height / source.height
        return min(widthScale, heightScale)
    }

    /**
     * SafeAreaのない端末にて、
     *
     * 1. 初期状態からダブルタップ
     * 2. NavigationBarが非表示になる
     * 3. `ClipPreviewViewController#viewDidLayoutSubviews` が実行される
     * 4. このメソッドが実行され、スケールが初期位置に戻される
     *
     * といった事象が発生した。そのため、レイアウト調整は初期状態に限る
     */
    public func shouldRecalculateInitialScale() {
        guard scrollView.zoomScale == scrollView.minimumZoomScale else { return }
        guard let source = source else { return }
        updateZoomScale(forImageSize: source.imageSize, on: bounds.size)
        updateInsetConstraints(forImageSize: source.imageSize, on: bounds)
    }

    @objc
    private func didDoubleTap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: imageView)
        guard imageView.bounds.contains(point), let image = imageView.image else { return }

        let nextScale: CGFloat = {
            if scrollView.zoomScale > scrollView.minimumZoomScale {
                return scrollView.minimumZoomScale
            } else {
                return scrollView.maximumZoomScale
            }
        }()

        let currentHorizontalInset = max((bounds.width - image.size.width * scrollView.zoomScale) / 2, 0)
        let currentVerticalInset = max((bounds.height - image.size.height * scrollView.zoomScale) / 2, 0)
        let width = scrollView.bounds.width / nextScale
        let height = scrollView.bounds.height / nextScale
        let nextPoint = CGPoint(x: point.x - (width / 2.0) - currentHorizontalInset,
                                y: point.y - (height / 2.0) - currentVerticalInset)
        let nextRect = CGRect(origin: nextPoint, size: .init(width: width, height: height))

        scrollView.zoom(to: nextRect, animated: true)
    }
}

// MARK: - Configuration

extension ClipPreviewView {
    private func configureViewHierarchy() {
        Bundle(for: type(of: self)).loadNibNamed("ClipPreviewView", owner: self, options: nil)
        baseView.frame = bounds
        addSubview(baseView)
        sendSubviewToBack(baseView)

        indicator.hidesWhenStopped = true
        indicator.stopAnimating()

        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.contentInsetAdjustmentBehavior = .never
    }

    private func configureGestureRecognizer() {
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap(_:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGestureRecognizer)
    }
}

// MARK: - Update

extension ClipPreviewView {
    private func updateZoomScale(forImageSize imageSize: CGSize, on size: CGSize) {
        let scaleToFit = Self.calcScaleScaleToFit(forSize: imageSize, fittingIn: size)

        scrollView.minimumZoomScale = min(1, scaleToFit)
        scrollView.maximumZoomScale = max(1, scaleToFit)

        scrollView.zoomScale = scrollView.minimumZoomScale
    }

    private func updateInsetConstraints(forImageSize imageSize: CGSize, on frame: CGRect) {
        let currentScale = scrollView.zoomScale

        let horizontalInset = max((frame.width - imageSize.width * currentScale) / 2, 0)
        let verticalInset = max((frame.height - imageSize.height * currentScale) / 2, 0)

        topInsetConstraint.constant = verticalInset
        bottomInsetConstraint.constant = verticalInset
        leftInsetConstraint.constant = horizontalInset
        rightInsetConstraint.constant = horizontalInset

        layoutIfNeeded()
        scrollView.contentSize = .init(width: imageView.frame.width + horizontalInset * 2,
                                       height: imageView.frame.height + verticalInset * 2)
    }
}

extension ClipPreviewView: UIScrollViewDelegate {
    // MARK: - UIScrollViewDelegate

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard let source = source else { return }
        updateInsetConstraints(forImageSize: source.imageSize, on: bounds)
        _isMinimumZoomScale.send(scrollView.zoomScale == scrollView.minimumZoomScale)
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        delegate?.clipPreviewPageViewWillBeginZoom(self)
    }
}
