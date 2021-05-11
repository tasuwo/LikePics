//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias SettingsViewDependency = HasCloudAvailabilityService
    & HasUserSettingStorage

enum SettingsViewReducer: Reducer {
    typealias Dependency = SettingsViewDependency
    typealias State = SettingsViewState
    typealias Action = SettingsViewAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return prepare(state: state, dependency: dependency)

        // MARK: State Observation

        case let .itemsVisibilityUpdated(isHidden):
            nextState.isSomeItemsHidden = isHidden
            return (nextState, .none)

        case let .iCloudSyncAvailabilityUpdated(isEnabled):
            nextState.isICloudSyncEnabled = isEnabled
            return (nextState, .none)

        // MARK: Control

        case let .itemsVisibilityChanged(isHidden):
            dependency.userSettingStorage.set(showHiddenItems: !isHidden)
            nextState.isSomeItemsHidden = isHidden
            return (nextState, .none)

        case let .iCloudSyncAvailabilityChanged(isEnabled):
            guard let availability = dependency.cloudAvailabilityService.state.value else {
                nextState.isICloudSyncEnabled = !isEnabled
                return (nextState, .none)
            }

            // iCloudが利用不可な場合は、内部状態を書き換えるか確認する
            if isEnabled, availability == .unavailable {
                if dependency.userSettingStorage.readEnabledICloudSync() {
                    nextState.alert = .unavailableICloudTurnOffConfirmation
                } else {
                    nextState.alert = .unavailableICloudTurnOnConfirmation
                }
                nextState.isICloudSyncEnabled = !isEnabled
                return (nextState, .none)
            }

            if isEnabled {
                dependency.userSettingStorage.set(enabledICloudSync: true)
                nextState.isICloudSyncEnabled = true
            } else {
                nextState.alert = .iCloudTurnOffConfirmation
                nextState.isICloudSyncEnabled = false
            }

            return (nextState, .none)

        // MARK: Alert Completion

        case .unavailableICloudTurnOffConfirmed:
            nextState.alert = .iCloudTurnOffConfirmation
            return (nextState, .none)

        case .unavailableICloudTurnOnConfirmed:
            nextState.alert = nil
            dependency.userSettingStorage.set(enabledICloudSync: true)
            nextState.isICloudSyncEnabled = false // iCloudはUnabailableなので設定画面の見た目上はOff
            return (nextState, .none)

        case .iCloudTurnOffConfirmed:
            nextState.alert = nil
            dependency.userSettingStorage.set(enabledICloudSync: false)
            nextState.isICloudSyncEnabled = false
            return (nextState, .none)

        case .iCloudTurnOffCancelled:
            nextState.alert = nil
            nextState.isICloudSyncEnabled = true
            return (nextState, .none)

        case .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)
        }
    }
}

// MARK: - Preparation

extension SettingsViewReducer {
    private static func prepare(state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        let stream1 = dependency.userSettingStorage.showHiddenItems
            .map { Action.itemsVisibilityUpdated(isHidden: !$0) as Action? }

        let stream2 = dependency.userSettingStorage.enabledICloudSync
            .combineLatest(dependency.cloudAvailabilityService.state)
            .map { settingEnabled, availability in
                return settingEnabled && availability?.isAvailable == true
            }
            .map { Action.iCloudSyncAvailabilityUpdated(isEnabled: $0) as Action? }

        var nextState = state
        nextState.isSomeItemsHidden = !dependency.userSettingStorage.readShowHiddenItems()
        nextState.isICloudSyncEnabled = dependency.userSettingStorage.readEnabledICloudSync()
        // swiftlint:disable:next force_cast force_unwrapping
        nextState.version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

        return (nextState, [Effect(stream1), Effect(stream2)])
    }
}
