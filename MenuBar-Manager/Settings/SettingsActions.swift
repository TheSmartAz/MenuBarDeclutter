import Foundation

struct SettingsActions {
    var behaviorChanged: (() -> Void)?
    var searchChanged: (() -> Void)?
    var secondBarChanged: (() -> Void)?
    var privacyChanged: (() -> Void)?
    var profile: SettingsProfileActions
    var triggersChanged: (() -> Void)?
    var resetLayout: (() -> Void)?
    var resetAllSettings: (() -> Void)?
    var resetMovingWarnings: (() -> Void)?
    var showOnboarding: (() -> Void)?
    var runHealthCheck: (() -> Void)?
    var fixHealthIssues: (() -> Void)?
    var resetBasicMode: (() -> Void)?
    var disableProMode: (() -> Void)?
    var enterSafeModeNextLaunch: (() -> Void)?

    init(
        behaviorChanged: (() -> Void)? = nil,
        searchChanged: (() -> Void)? = nil,
        secondBarChanged: (() -> Void)? = nil,
        privacyChanged: (() -> Void)? = nil,
        profile: SettingsProfileActions = .empty,
        triggersChanged: (() -> Void)? = nil,
        resetLayout: (() -> Void)? = nil,
        resetAllSettings: (() -> Void)? = nil,
        resetMovingWarnings: (() -> Void)? = nil,
        showOnboarding: (() -> Void)? = nil,
        runHealthCheck: (() -> Void)? = nil,
        fixHealthIssues: (() -> Void)? = nil,
        resetBasicMode: (() -> Void)? = nil,
        disableProMode: (() -> Void)? = nil,
        enterSafeModeNextLaunch: (() -> Void)? = nil
    ) {
        self.behaviorChanged = behaviorChanged
        self.searchChanged = searchChanged
        self.secondBarChanged = secondBarChanged
        self.privacyChanged = privacyChanged
        self.profile = profile
        self.triggersChanged = triggersChanged
        self.resetLayout = resetLayout
        self.resetAllSettings = resetAllSettings
        self.resetMovingWarnings = resetMovingWarnings
        self.showOnboarding = showOnboarding
        self.runHealthCheck = runHealthCheck
        self.fixHealthIssues = fixHealthIssues
        self.resetBasicMode = resetBasicMode
        self.disableProMode = disableProMode
        self.enterSafeModeNextLaunch = enterSafeModeNextLaunch
    }

    static let empty = SettingsActions()
}

struct SettingsProfileActions {
    var dryRun: ((ProfileModel) -> ProfileApplicationDryRun)?
    var apply: ((ProfileModel) -> ProfileApplicationDryRun)?

    init(
        dryRun: ((ProfileModel) -> ProfileApplicationDryRun)? = nil,
        apply: ((ProfileModel) -> ProfileApplicationDryRun)? = nil
    ) {
        self.dryRun = dryRun
        self.apply = apply
    }

    static let empty = SettingsProfileActions()
}
