//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

protocol ClipPreviewPageBarViewModelType {
    var inputs: ClipPreviewPageBarViewModelInputs { get }
    var outputs: ClipPreviewPageBarViewModelOutputs { get }
}

protocol ClipPreviewPageBarViewModelInputs {
    var isHorizontalCompact: CurrentValueSubject<Bool, Never> { get }
    var currentClipItem: CurrentValueSubject<ClipItem?, Never> { get }
    var clipItemCount: CurrentValueSubject<Int, Never> { get }
}

protocol ClipPreviewPageBarViewModelOutputs {
    var displayToolBar: CurrentValueSubject<Bool, Never> { get }
    var leftItems: CurrentValueSubject<[ClipPreview.BarItem], Never> { get }
    var rightItems: CurrentValueSubject<[ClipPreview.BarItem], Never> { get }
    var toolBarItems: CurrentValueSubject<[ClipPreview.BarItem], Never> { get }
}

class ClipPreviewPageBarViewModel: ClipPreviewPageBarViewModelType,
    ClipPreviewPageBarViewModelInputs,
    ClipPreviewPageBarViewModelOutputs
{
    // MARK: - Properties

    // MARK: ClipPreviewPageBarViewModelType

    var inputs: ClipPreviewPageBarViewModelInputs { self }
    var outputs: ClipPreviewPageBarViewModelOutputs { self }

    // MARK: ClipPreviewPageBarViewModelInputs

    let isHorizontalCompact: CurrentValueSubject<Bool, Never> = .init(true)
    let currentClipItem: CurrentValueSubject<ClipItem?, Never> = .init(nil)
    let clipItemCount: CurrentValueSubject<Int, Never> = .init(0)

    // MARK: ClipPreviewPageBarViewModelOutputs

    let displayToolBar: CurrentValueSubject<Bool, Never> = .init(true)
    let leftItems: CurrentValueSubject<[ClipPreview.BarItem], Never> = .init([])
    let rightItems: CurrentValueSubject<[ClipPreview.BarItem], Never> = .init([])
    let toolBarItems: CurrentValueSubject<[ClipPreview.BarItem], Never> = .init([])

    // MARK: Privates

    private var cancellableBag: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    init() {
        self.isHorizontalCompact
            .combineLatest(clipItemCount, currentClipItem)
            .sink { [weak self] isHorizontalCompact, clipItemCount, currentClipItem in
                guard let self = self else { return }

                let displayToolBar = isHorizontalCompact
                self.displayToolBar.send(displayToolBar)

                if !displayToolBar {
                    self.toolBarItems.send([])
                    self.leftItems.send([.init(kind: .back, isEnabled: true)])
                    self.rightItems.send([
                        clipItemCount == 1
                            ? .init(kind: .deleteClip, isEnabled: true)
                            : .init(kind: .deleteOnlyImageOrClip, isEnabled: true)
                    ])
                } else {
                    self.toolBarItems.send([
                        .init(kind: .openWeb, isEnabled: currentClipItem?.url != nil),
                        .init(kind: .add, isEnabled: true),
                        clipItemCount == 1
                            ? .init(kind: .deleteClip, isEnabled: true)
                            : .init(kind: .deleteOnlyImageOrClip, isEnabled: true)
                    ])
                    self.leftItems.send([.init(kind: .back, isEnabled: true)])
                    self.rightItems.send([.init(kind: .info, isEnabled: true)])
                }
            }
            .store(in: &self.cancellableBag)
    }
}
