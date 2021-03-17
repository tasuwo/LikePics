//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit
import UIKit

protocol ClipInformationViewCaching: AnyObject {
    func startUpdating(clipId: Clip.Identity, itemId: ClipItem.Identity)
    func stopUpdating()
    func readCachingView() -> ClipInformationView
    func insertCachingViewHierarchyIfNeeded()
}

protocol ClipInformationViewCachingDelegate: AnyObject {
    func didInvalidateCache(_ caching: ClipInformationViewCaching)
}

class ClipInformationViewCacheController {
    typealias Store = LikePics.Store<ClipInformationViewCacheState, ClipInformationViewCacheAction, ClipInformationViewCacheDependency>
    typealias Layout = ClipInformationLayout

    // MARK: - Properties

    // MARK: View

    let baseView = UIView()
    let informationView = ClipInformationView()
    weak var delegate: ClipInformationViewCachingDelegate?

    // MARK: Store

    private let dependency: ClipInformationViewCacheDependency
    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(state: ClipInformationViewCacheState,
         dependency: ClipInformationViewCacheDependency)
    {
        self.dependency = dependency
        self.store = Store(initialState: state, dependency: dependency, reducer: ClipInformationViewCacheReducer.self)

        configureViewHierarchy()
    }
}

// MARK: - Bind

extension ClipInformationViewCacheController {
    private func bind(to store: Store) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }

            guard state.isInvalidated == false else {
                self.delegate?.didInvalidateCache(self)
                return
            }

            DispatchQueue.global().async {
                self.informationView.setInfo(Layout.Information(state), animated: false)
            }
        }
        .store(in: &subscriptions)
    }
}

// MARK: - Configuration

extension ClipInformationViewCacheController {
    private func configureViewHierarchy() {
        baseView.translatesAutoresizingMaskIntoConstraints = false
        baseView.backgroundColor = .clear

        informationView.alpha = 0
        informationView.translatesAutoresizingMaskIntoConstraints = false
        baseView.insertSubview(informationView, at: 0)
        NSLayoutConstraint.activate(informationView.constraints(fittingIn: baseView))
    }
}

extension ClipInformationViewCacheController: ClipInformationViewCaching {
    // MARK: - ClipInformationViewCaching

    func startUpdating(clipId: Clip.Identity, itemId: ClipItem.Identity) {
        stopUpdating()
        store = Store(initialState: .init(clip: nil,
                                          tags: .init(_values: [:],
                                                      _selectedIds: .init(),
                                                      _displayableIds: .init()),
                                          item: nil,
                                          isSomeItemsHidden: true,
                                          isInvalidated: false),
                      dependency: dependency,
                      reducer: ClipInformationViewCacheReducer.self)
        bind(to: store)
        store.execute(.loaded(clipId, itemId))
    }

    func stopUpdating() {
        subscriptions.forEach { $0.cancel() }
    }

    func readCachingView() -> ClipInformationView {
        informationView.alpha = 1
        informationView.loadImageView()
        informationView.removeFromSuperview()
        return informationView
    }

    func insertCachingViewHierarchyIfNeeded() {
        guard !baseView.subviews.contains(informationView) else { return }
        informationView.alpha = 0
        baseView.insertSubview(informationView, at: 0)
        NSLayoutConstraint.activate(informationView.constraints(fittingIn: baseView))
    }
}

extension ClipInformationLayout.Information {
    init(_ state: ClipInformationViewCacheState) {
        self.init(clip: state.clip, tags: state.tags.displayableValues, item: state.item)
    }
}
