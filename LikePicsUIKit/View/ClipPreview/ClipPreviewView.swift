//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Smoothie
import UIKit

public protocol ClipPreviewPageViewDelegate: AnyObject {
    func clipPreviewPageViewWillBeginZoom(_ view: ClipPreviewView)
}

public class ClipPreviewView: UIView {
    public var source: ClipPreviewSource? {
        didSet {
            guard let source = source else { return }

            imageView.originalSize = source.originalSize
            imageView.image = source.uiImage
            imageView.invalidateIntrinsicContentSize()
            imageView.backgroundColor = source.uiImage == nil
                ? Asset.Color.secondaryBackground.color
                : .clear

            // HACK: 参照タイミングによってはbounds.sizeがゼロになる
            //       サイズがゼロだと `resetToInitialZoomScaleFlag()` 等、スケール計算に
            //       bounds.sizeを計算に利用している箇所がおかしくなってしまうので、再描画する
            layoutIfNeeded()

            updateZoomScaleLimits()

            // サムネ > 元画像 の順で source が設定されるケースが多い
            // 元画像設定時にスケールがリセットされることを防ぐため、リセットは初回に限定する
            // 初回にリセットしないと、初期スケールが画面に収まらない不正なスケールになる
            if oldValue == nil {
                resetToInitialZoomScale()
            }

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

    public weak var delegate: ClipPreviewPageViewDelegate?

    private var doubleTapGestureRecognizer: UITapGestureRecognizer!

    @IBOutlet var baseView: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: PreviewImageView!

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

    override public func layoutSubviews() {
        super.layoutSubviews()

        let currentMinimumZoomScale = scrollView.minimumZoomScale
        let currentMaximumZoomScale = scrollView.maximumZoomScale

        updateZoomScaleLimits()
        adjustZoomScale(previousMinimumZoomScale: currentMinimumZoomScale,
                        previousMaximumZoomScale: currentMaximumZoomScale)
        updateInitialZoomScaleFlag()

        updateInsetsForCurrentScale()
    }

    // MARK: - IBActions

    @objc
    private func didDoubleTap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: imageView)

        guard imageView.bounds.contains(point),
              let image = imageView.image
        else {
            return
        }

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
    func viewWillStartTransition(frame: CGRect, thumbnail: UIImage, originalImageSize: CGSize) {
        self.frame = frame

        if source == nil {
            source = .thumbnail(thumbnail, originalSize: originalImageSize)
        } else {
            updateZoomScaleLimits()
            resetToInitialZoomScale()
            updateInitialZoomScaleFlag()

            updateInsetsForCurrentScale()
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
    /**
     * 現在のboundsにプレビュー画像がぴったり収まるzoomScaleを設定する
     */
    private func resetToInitialZoomScale() {
        guard let source = source else { return }
        scrollView.zoomScale = source.size.scale(fittingIn: bounds.size)
    }

    /**
     * 現在のboundsに合わせて、zoomScaleの最大/最小値を再設定する
     */
    private func updateZoomScaleLimits() {
        guard let source = source else { return }

        let scaleToFit = source.size.scale(fittingIn: bounds.size)

        scrollView.minimumZoomScale = min(1, scaleToFit)
        scrollView.maximumZoomScale = max(1, scaleToFit)
    }

    /**
     * 現在のzoomScaleが、最大値/最小値に対して不正であった場合に調整する
     *
     * zoomScaleの最大値/最小値の更新直後の利用を想定している
     *
     * - parameters:
     *   - previousMinimumZoomScale: 元々のzoomScaleの最小値
     *   - previousMaximumZoomScale: 元々のzoomScaleの最大値
     */
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

    /**
     * 現在のzoomScaleに対して、適切な上下左右のInsetを計算,適用する
     *
     * zoomScaleの更新直後に呼び出されることを想定している
     */
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

    /**
     * 現在のzoomScaleが初期zoomScaleかどうかチェックし、外部に通知する
     *
     * zoomScaleの更新直後に呼び出されることを想定している
     */
    private func updateInitialZoomScaleFlag() {
        guard let source = source else {
            _isInitialZoomScale.send(false)
            return
        }
        _isInitialZoomScale.send(scrollView.zoomScale == source.size.scale(fittingIn: bounds.size))
    }
}

extension ClipPreviewView: UIScrollViewDelegate {
    // MARK: - UIScrollViewDelegate

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateInsetsForCurrentScale()
        updateInitialZoomScaleFlag()
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        delegate?.clipPreviewPageViewWillBeginZoom(self)
    }
}

extension ClipPreviewView: ImageDisplayable {
    @objc
    public func smt_display(_ image: UIImage?) {
        guard let image = image else { return }
        source = .image(image)
    }
}
