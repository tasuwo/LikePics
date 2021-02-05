//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol SearchEntryViewModelType {
    var inputs: SearchEntryViewModelInputs { get }
    var outputs: SearchEntryViewModelOutputs { get }
}

protocol SearchEntryViewModelInputs {
    var queryInputted: PassthroughSubject<String, Never> { get }
    var queryEntered: PassthroughSubject<Void, Never> { get }
}

protocol SearchEntryViewModelOutputs {
    var displayErrorMessage: PassthroughSubject<String, Never> { get }
    var performSearch: PassthroughSubject<ClipCollection.SearchContext, Never> { get }
}

class SearchEntryViewModel: SearchEntryViewModelType,
    SearchEntryViewModelInputs,
    SearchEntryViewModelOutputs
{
    // MARK: - SearchEntryViewModelType

    var inputs: SearchEntryViewModelInputs { self }
    var outputs: SearchEntryViewModelOutputs { self }

    // MARK: - SearchEntryViewModelInputs

    let queryInputted: PassthroughSubject<String, Never> = .init()
    let queryEntered: PassthroughSubject<Void, Never> = .init()

    // MARK: - SearchEntryViewModelOutputs

    let displayErrorMessage: PassthroughSubject<String, Never> = .init()
    let performSearch: PassthroughSubject<ClipCollection.SearchContext, Never> = .init()

    // MARK: Privates

    private let query: CurrentValueSubject<String?, Never> = .init(nil)
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    init() {
        bind()
    }
}

extension SearchEntryViewModel {
    func bind() {
        queryInputted
            .sink { [weak self] query in
                self?.query.send(query)
            }
            .store(in: &subscriptions)

        queryEntered
            .sink { [weak self] in
                guard let query = self?.query.value else { return }
                let keywords = query
                    .trimmingCharacters(in: .whitespaces)
                    .split(separator: " ")
                    .map { String($0) }
                self?.performSearch.send(.keywords(keywords))
            }
            .store(in: &subscriptions)
    }
}
