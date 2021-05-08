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
        case image(UIImage)
        case thumbnail(UIImage, originalSize: CGSize)

        var uiImage: UIImage {
            switch self {
            case let .image(image):
                return image

            case let .thumbnail(image, _):
                return image
            }
        }

        var size: CGSize {
            return uiImage.size
        }

        var originalSizeInPixel: CGSize {
            switch self {
            case let .image(image):
                return .init(width: image.size.width * image.scale,
                             height: image.size.height * image.scale)

            case let .thumbnail(_, size):
                return size
            }
        }
    }

    public var source: Source? {
        didSet {
            guard let source = source else { return }
            imageView.image = source.uiImage

            updateZoomScaleLimits()
            resetToInitialZoomScale()
            updateInitialZoomScaleFlag()

            updateInsetsForCurrentScale()
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

    private let _isInitialZoomScale: CurrentValueSubject<Bool, Never> = .init(true)
    public var isInitialZoomScale: AnyPublisher<Bool, Never> {
        _isInitialZoomScale.eraseToAnyPublisher()
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
        let scale = source.originalSizeInPixel.scale(fittingIn: bounds.size)
        let initialImageSize = CGSize(width: source.originalSizeInPixel.width * scale,
                                      height: source.originalSizeInPixel.height * scale)
        return CGRect(origin: CGPoint(x: (bounds.width - initialImageSize.width) / 2,
                                      y: (bounds.height - initialImageSize.height) / 2),
                      size: initialImageSize)
    }

    public var zoomGestureRecognizer: UITapGestureRecognizer {
        return doubleTapGestureRecognizer
    }

    public var isDisplayingLoadingIndicator: Bool = false {
        didSet { updateLoadingState() }
    }

    public var isLoadingIndicatorHidden: Bool = false {
        didSet { updateLoadingState() }
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

    // MARK: - Initializers

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

    // MARK: - IBActions

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

// MARK: - View Life-Cycle Methods

public extension ClipPreviewView {
    func viewWillStartTransition(frame: CGRect, thumbnail: UIImage) {
        self.frame = frame

        if source == nil {
            source = .thumbnail(thumbnail, originalSize: thumbnail.size)
        } else {
            updateZoomScaleLimits()
            resetToInitialZoomScale()
            updateInitialZoomScaleFlag()

            updateInsetsForCurrentScale()
        }
    }

    func viewDidLayoutSubviews() {
        let currentMinimumZoomScale = scrollView.minimumZoomScale
        let currentMaximumZoomScale = scrollView.maximumZoomScale

        updateZoomScaleLimits()
        // `viewDidLayoutSubviews` は画面回転時以外にも呼ばれる可能性がある
        // そのため、呼出の度にスケールをリセットすると不自然な動作となってしまう
        // したがって、不正なスケールであった場合のみ調整を行う
        adjustZoomScale(previousMinimumZoomScale: currentMinimumZoomScale,
                        previousMaximumZoomScale: currentMaximumZoomScale)
        updateInitialZoomScaleFlag()

        updateInsetsForCurrentScale()
    }

    func viewDidAppear() {
        updateZoomScaleLimits()
        // 遷移アニメーションのことを考慮して、初期スケールにリセットする
        resetToInitialZoomScale()
        updateInitialZoomScaleFlag()

        updateInsetsForCurrentScale()
    }

    private func resetToInitialZoomScale() {
        guard let source = source else { return }
        scrollView.zoomScale = source.size.scale(fittingIn: bounds.size)
    }

    private func adjustZoomScale(previousMinimumZoomScale: CGFloat,
                                 previousMaximumZoomScale: CGFloat)
    {
        if scrollView.zoomScale == previousMinimumZoomScale {
            scrollView.zoomScale = scrollView.minimumZoomScale
            return
        }

        if scrollView.zoomScale > scrollView.maximumZoomScale {
            scrollView.zoomScale = scrollView.maximumZoomScale
        } else if scrollView.zoomScale < scrollView.minimumZoomScale {
            scrollView.zoomScale = scrollView.minimumZoomScale
        }
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
    private func updateZoomScaleLimits() {
        guard let source = source else { return }

        let scaleToFit = source.size.scale(fittingIn: bounds.size)

        scrollView.minimumZoomScale = min(1, scaleToFit)
        scrollView.maximumZoomScale = max(1, scaleToFit)
    }

    private func updateInsetsForCurrentScale() {
        guard let source = source else { return }

        let currentScale = scrollView.zoomScale

        let horizontalInset = max((bounds.size.width - source.size.width * currentScale) / 2, 0)
        let verticalInset = max((bounds.size.height - source.size.height * currentScale) / 2, 0)

        topInsetConstraint.constant = verticalInset
        bottomInsetConstraint.constant = verticalInset
        leftInsetConstraint.constant = horizontalInset
        rightInsetConstraint.constant = horizontalInset

        layoutIfNeeded()
        scrollView.contentSize = .init(width: imageView.frame.width + horizontalInset * 2,
                                       height: imageView.frame.height + verticalInset * 2)
    }

    private func updateInitialZoomScaleFlag() {
        guard let source = source else {
            _isInitialZoomScale.send(false)
            return
        }
        _isInitialZoomScale.send(scrollView.zoomScale == source.size.scale(fittingIn: bounds.size))
    }

    private func updateLoadingState() {
        guard !isLoadingIndicatorHidden else {
            imageView.alpha = 1.0
            indicator.stopAnimating()
            return
        }

        if isDisplayingLoadingIndicator {
            imageView.alpha = 0.8
            indicator.startAnimating()
        } else {
            imageView.alpha = 1.0
            indicator.stopAnimating()
        }
    }
}

extension ClipPreviewView: UIScrollViewDelegate {
    // MARK: - UIScrollViewDelegate

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateInitialZoomScaleFlag()
        updateInsetsForCurrentScale()
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        delegate?.clipPreviewPageViewWillBeginZoom(self)
    }
}
