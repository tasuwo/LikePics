//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit
import LikePicsUIKit
import UIKit

protocol ClipItemInformationViewCaching: AnyObject {
    func readCachingView() -> ClipItemInformationView
}

class ClipItemInformationViewCacheController {
    typealias Store = ForestKit.Store<ClipItemInformationViewCacheState, ClipItemInformationViewCacheAction, ClipItemInformationViewCacheDependency>
    typealias Layout = ClipItemInformationLayout

    // MARK: - Properties

    // MARK: View

    let baseView = UIView()
    let informationView = ClipItemInformationView()

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

        bind(to: store)
    }

    // MARK: - View Life-Cycle Methods

    func viewWillDisappear() {
        subscriptions.forEach { $0.cancel() }
    }

    func viewDidAppear(clipId: Clip.Identity?, itemId: ClipItem.Identity?) {
        insertCachingViewHierarchyIfNeeded()

        if let clipId = clipId, let itemId = itemId {
            store.execute(.pageChanged(clipId: clipId, itemId: itemId))
        }
    }

    func pageChanged(clipId: Clip.Identity, itemId: ClipItem.Identity) {
        store.execute(.pageChanged(clipId: clipId, itemId: itemId))
    }
}

// MARK: - Bind

extension ClipItemInformationViewCacheController {
    private func bind(to store: Store) {
        store.state
            .removeDuplicates(by: { $0.itemId == $1.itemId && $0.clipId == $0.clipId })
            .debounce(for: 0.3, scheduler: DispatchQueue.global())
            .sink { [weak self] state in
                guard let clipId = state.clipId, let itemId = state.itemId else { return }
                self?.store.execute(.load(clipId: clipId, itemId: itemId))
            }
            .store(in: &subscriptions)

        store.state
            .map(\.information)
            .compactMap { $0 }
            .removeDuplicates()
            .receive(on: DispatchQueue.global())
            .sink { [weak self] in self?.informationView.setInfo(Layout.Information($0), animated: false) }
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

// MARK: - Caching

extension ClipItemInformationViewCacheController {
    private func insertCachingViewHierarchyIfNeeded() {
        guard !baseView.subviews.contains(informationView) else { return }
        informationView.alpha = 0
        baseView.insertSubview(informationView, at: 0)
        NSLayoutConstraint.activate(informationView.constraints(fittingIn: baseView))
    }
}

extension ClipItemInformationViewCacheController: ClipItemInformationViewCaching {
    // MARK: - ClipItemInformationViewCaching

    func readCachingView() -> ClipItemInformationView {
        informationView.alpha = 1
        informationView.removeFromSuperview()
        return informationView
    }
}

extension ClipItemInformationLayout.Information {
    init(_ info: ClipItemInformationViewCacheState.Information) {
        self.init(clip: info.clip,
                  tags: info.tags.orderedFilteredEntities(),
                  albums: info.albums.orderedFilteredEntities(),
                  item: info.item)
    }
}
