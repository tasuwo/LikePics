//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

protocol ClipCollectionViewModelInputs {}

protocol ClipCollectionViewModelOutputs {
    var clips: CurrentValueSubject<[Clip], Never> { get }
    var selections: CurrentValueSubject<Set<Clip.Identity>, Never> { get }
    var operation: CurrentValueSubject<ClipCollection.Operation, Never> { get }
}

typealias ClipCollectionViewModelType = ClipCollectionViewModelInputs & ClipCollectionViewModelOutputs

extension TopClipCollectionViewModel: ClipCollectionViewModelInputs {}
extension TopClipCollectionViewModel: ClipCollectionViewModelOutputs {}

extension SearchResultViewModel: ClipCollectionViewModelInputs {}
extension SearchResultViewModel: ClipCollectionViewModelOutputs {}

extension AlbumViewModel: ClipCollectionViewModelInputs {}
extension AlbumViewModel: ClipCollectionViewModelOutputs {}
