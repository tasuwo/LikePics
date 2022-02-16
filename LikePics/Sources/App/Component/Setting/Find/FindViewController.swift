//
//  Copyright © 2022 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import Foundation
import LikePicsCore
import LikePicsUIKit
import UIKit
import WebKit

class FindViewController: UIViewController {
    typealias Store = CompositeKit.Store<FindViewState, FindViewAction, FindViewDependency>

    // MARK: - Properties

    // MARK: View

    private let webView: WKWebView
    private let barTitleView = FindViewTitleBar()
    private let progressBar = UIProgressView(progressViewStyle: .bar)

    // MARK: BarButtons

    private var goForwardButton: UIBarButtonItem!
    private var goBackButton: UIBarButtonItem!
    private var reloadButton: UIBarButtonItem!
    private var cancelButton: UIBarButtonItem!
    private var clipButton: UIBarButtonItem!
    private var flexibleItem: UIBarButtonItem!

    // MARK: Store

    private var store: Store
    private var previousOffset: CGPoint?
    private var subscriptions: Set<AnyCancellable> = .init()
    private var observations: [NSKeyValueObservation] = []
    private var modalSubscription: Cancellable?

    // MARK: Services

    private let router: Router

    init(webView: WKWebView,
         state: FindViewState,
         dependency: FindViewDependency,
         router: Router)
    {
        self.webView = webView
        self.store = Store(initialState: state, dependency: dependency, reducer: FindViewReducer())
        self.router = router

        super.init(nibName: nil, bundle: nil)
    }

    convenience init(state: FindViewState,
                     dependency: FindViewDependency,
                     router: Router)
    {
        let webView = WKWebView()

        // swiftlint:disable:next force_unwrapping
        let request = URLRequest(url: URL(string: "https://google.com")!)
        webView.load(request)

        self.init(webView: webView, state: state, dependency: dependency, router: router)
    }

    deinit {
        self.observations.forEach { $0.invalidate() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureBarButtons()
        configureNavigationBar()

        bind(to: store)
    }
}

// MARK: - Bind

extension FindViewController {
    private func bind(to store: Store) {
        webView.publisher(for: \.estimatedProgress, options: .new)
            .sink { [weak self] in self?.store.execute(.updatedEstimatedProgress($0)) }
            .store(in: &subscriptions)
        webView.publisher(for: \.isLoading, options: .new)
            .sink { [weak self] in self?.store.execute(.updatedLoading($0)) }
            .store(in: &subscriptions)
        webView.publisher(for: \.canGoBack, options: .new)
            .sink { [weak self] in self?.store.execute(.updatedCanGoBack($0)) }
            .store(in: &subscriptions)
        webView.publisher(for: \.canGoForward, options: .new)
            .sink { [weak self] in self?.store.execute(.updatedCanGoForward($0)) }
            .store(in: &subscriptions)
        webView.publisher(for: \.title, options: [.initial, .new])
            .sink { [weak self] in self?.store.execute(.updatedTitle($0)) }
            .store(in: &subscriptions)
        webView.publisher(for: \.url, options: [.initial, .new])
            .sink { [weak self] in self?.store.execute(.updatedUrl($0)) }
            .store(in: &subscriptions)

        store.state
            .bind(\.canGoBack, to: \.isEnabled, on: goBackButton)
            .store(in: &subscriptions)
        store.state
            .bind(\.canGoForward, to: \.isEnabled, on: goForwardButton)
            .store(in: &subscriptions)
        store.state
            .bind(\.isClipEnabled, to: \.isEnabled, on: clipButton)
            .store(in: &subscriptions)
        store.state
            .bind(\.estimatedProgress) { [weak self] in
                guard let self = self else { return }
                if self.progressBar.progress >= 1, $0 < 1 {
                    // 進捗度100%から戻る際にアニメーションさせると不自然なので、局所的にアニメーションを切る
                    self.progressBar.setProgress(Float($0), animated: false)
                    self.progressBar.isHidden = self.store.stateValue.isProgressBarHidden
                } else {
                    self.progressBar.setProgress(Float($0), animated: true)
                    UIView.animate(withDuration: 0.2) {
                        self.progressBar.layoutIfNeeded()
                    } completion: { _ in
                        self.progressBar.isHidden = self.store.stateValue.isProgressBarHidden
                    }
                }
            }
            .store(in: &subscriptions)
        store.state
            .bind(\.isLoading) { [weak self] in
                guard let self = self else { return }
                let item: UIBarButtonItem = $0 ? self.cancelButton : self.reloadButton
                self.navigationItem.setRightBarButtonItems([item], animated: false)
            }
            .store(in: &subscriptions)
        store.state
            .bind(\.title, to: \.title, on: barTitleView)
            .store(in: &subscriptions)
        store.state
            .bind(\.currentUrl) { [weak self] in
                self?.barTitleView.text = $0?.absoluteString
            }
            .store(in: &subscriptions)
        store.state
            .bind(\.modal) { [weak self] modal in self?.presentModalIfNeeded(for: modal) }
            .store(in: &subscriptions)
    }

    private func presentModalIfNeeded(for modal: FindViewState.Modal?) {
        switch modal {
        case let .clipCreation(id: id):
            presentClipCreationModal(id: id)

        case .none:
            break
        }
    }

    private func presentClipCreationModal(id: UUID) {
        ModalNotificationCenter.default
            .publisher(for: id, name: .clipCreationModalDidFinish)
            .sink { [weak self] _ in
                self?.modalSubscription?.cancel()
                self?.modalSubscription = nil
                self?.store.execute(.modalDismissed)
            }
            .store(in: &subscriptions)

        if router.showClipCreationModal(id: id, webView: webView) == false {
            modalSubscription?.cancel()
            modalSubscription = nil
            store.execute(.modalDismissed)
        }
    }
}

// MARK: - Configuration

extension FindViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.allowsBackForwardNavigationGestures = true

        progressBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressBar)
        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressBar.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor)
        ])
    }

    private func configureNavigationBar() {
        navigationItem.titleView = barTitleView
        barTitleView.delegate = self
        barTitleView.textFieldDelegate = self
    }

    private func configureBarButtons() {
        reloadButton = UIBarButtonItem(title: nil,
                                       image: UIImage(systemName: "arrow.clockwise"),
                                       primaryAction: .init(handler: { [weak self] _ in
                                           self?.webView.reload()
                                       }), menu: nil)

        cancelButton = UIBarButtonItem(title: nil,
                                       image: UIImage(systemName: "xmark"),
                                       primaryAction: .init(handler: { [weak self] _ in
                                           self?.webView.stopLoading()
                                       }), menu: nil)

        goForwardButton = UIBarButtonItem(title: nil,
                                          image: UIImage(systemName: "chevron.right"),
                                          primaryAction: .init(handler: { [weak self] _ in
                                              self?.webView.goForward()
                                          }), menu: nil)

        goBackButton = UIBarButtonItem(title: nil,
                                       image: UIImage(systemName: "chevron.left"),
                                       primaryAction: .init(handler: { [weak self] _ in
                                           self?.webView.goBack()
                                       }), menu: nil)

        clipButton = UIBarButtonItem(title: nil,
                                     image: UIImage(systemName: "paperclip"),
                                     primaryAction: .init(handler: { [weak self] _ in self?.store.execute(.tapClip) }),
                                     menu: nil)

        flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        navigationItem.setRightBarButtonItems([reloadButton], animated: true)
        setToolbarItems([
            goBackButton,
            flexibleItem,
            clipButton,
            flexibleItem,
            goForwardButton
        ], animated: false)

        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.setToolbarHidden(false, animated: false)
    }
}

extension FindViewController: WKUIDelegate {
    // MARK: - WKUIDelegate

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let targetFrame = navigationAction.targetFrame,
              targetFrame.isMainFrame
        else {
            webView.load(navigationAction.request)
            return nil
        }
        return nil
    }
}

extension FindViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // TODO:
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // TODO:
    }
}

extension FindViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        previousOffset = nil
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        defer {
            previousOffset = scrollView.contentOffset
        }

        guard let previousContentOffset = previousOffset else {
            return
        }

        if scrollView.contentOffset.y < -scrollView.contentInset.top {
            // 上方向にバウンスする
            showBars()
            return
        } else if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.size.height {
            // 下方向にバウンスする
            return
        }

        let delta = scrollView.contentOffset.y - previousContentOffset.y
        guard abs(delta) > 8 else { return }
        guard scrollView.isDragging else { return }

        if delta > 0 {
            hideBars()
        } else {
            showBars()
        }
    }

    private func showBars() {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.setToolbarHidden(false, animated: true)
    }

    private func hideBars() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
}

extension FindViewController: FindViewTitleBarDelegate {
    func didTapTitleButton(_ view: FindViewTitleBar) {
        barTitleView.isSearching = true
    }
}

extension FindViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        barTitleView.isSearching = false
        barTitleView.text = store.stateValue.currentUrl?.absoluteString
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text, let url = URL(string: text) else { return false }
        webView.load(URLRequest(url: url))
        barTitleView.isSearching = false
        return true
    }
}

extension FindViewController: Restorable {
    // MARK: - Restorable

    func restore() -> RestorableViewController {
        return FindViewController(webView: webView,
                                  state: store.stateValue,
                                  dependency: store.dependency,
                                  router: router)
    }
}
