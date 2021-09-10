//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit
import LikePicsUIKit
import UIKit

protocol ClipItemInformationViewCaching: AnyObject {
    func startUpdating(clipId: Clip.Identity, itemId: ClipItem.Identity)
    func stopUpdating()
    func readCachingView() -> ClipItemInformationView
    func insertCachingViewHierarchyIfNeeded()
}

protocol ClipItemInformationViewCachingDelegate: AnyObject {
    func didInvalidateCache(_ caching: ClipItemInformationViewCaching)
}

class ClipItemInformationViewCacheController {
    typealias Store = ForestKit.Store<ClipItemInformationViewCacheState, ClipItemInformationViewCacheAction, ClipItemInformationViewCacheDependency>
    typealias Layout = ClipItemInformationLayout

    // MARK: - Properties

    // MARK: View

    let baseView = UIView()
    let informationView = ClipItemInformationView()
    weak var delegate: ClipItemInformationViewCachingDelegate?

    // MARK: Store

    private let dependency: ClipItemInformationViewCacheDependency
    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(state: ClipItemInformationViewCacheState,
         dependency: ClipItemInformationViewCacheDependency)
    {
        self.dependency = dependency
        self.store = Store(initialState: state, dependency: dependency, reducer: ClipItemInformationViewCacheReducer())

        configureViewHierarchy()
    }
}

// MARK: - Bind

extension ClipItemInformationViewCacheController {
    private func bind(to store: Store) {
        store.state
            .bind(\.isInvalidated) { [weak self] isInvalidated in
                guard isInvalidated == true, let self = self else { return }
                self.delegate?.didInvalidateCache(self)
            }
            .store(in: &subscriptions)

        store.state
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.global())
            .sink { [weak self] state in
                self?.informationView.setInfo(Layout.Information(state), animated: false)
            }
            .store(in: &subscriptions)
    }
}

// MARK: - Configuration

extension ClipItemInformationViewCacheController {
    private func configureViewHierarchy() {
        baseView.translatesAutoresizingMaskIntoConstraints = false
        baseView.backgroundColor = .clear

        informationView.alpha = 0
        informationView.translatesAutoresizingMaskIntoConstraints = false
        baseView.insertSubview(informationView, at: 0)
        NSLayoutConstraint.activate(informationView.constraints(fittingIn: baseView))
    }
}

extension ClipItemInformationViewCacheController: ClipItemInformationViewCaching {
    // MARK: - ClipItemInformationViewCaching

    func startUpdating(clipId: Clip.Identity, itemId: ClipItem.Identity) {
        stopUpdating()
        store = Store(initialState: .init(isSomeItemsHidden: true),
                      dependency: dependency,
                      reducer: ClipItemInformationViewCacheReducer())
        bind(to: store)
        store.execute(.loaded(clipId, itemId))
    }

    func stopUpdating() {
        subscriptions.forEach { $0.cancel() }
    }

    func readCachingView() -> ClipItemInformationView {
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

extension ClipItemInformationLayout.Information {
    init(_ state: ClipItemInformationViewCacheState) {
        self.init(clip: state.clip,
                  tags: state.tags.orderedFilteredEntities(),
                  albums: state.albums.orderedFilteredEntities(),
                  item: state.item)
    }
}
