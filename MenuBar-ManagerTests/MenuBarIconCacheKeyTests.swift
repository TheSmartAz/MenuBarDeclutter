import CoreGraphics
import Testing
@testable import MenuBarDeclutter

@Suite("MenuBar Icon Cache Key")
struct MenuBarIconCacheKeyTests {
    @Test func storageFilenameIsStableForEquivalentInputs() {
        let lhs = MenuBarIconCacheKey(
            identityFingerprint: "owner|item|visible",
            displayID: 42,
            backingScale: 2.0,
            menuBarHeight: 24,
            appearanceName: "NSAppearanceNameDarkAqua"
        )
        let rhs = MenuBarIconCacheKey(
            identityFingerprint: "owner|item|visible",
            displayID: 42,
            backingScale: 2.0,
            menuBarHeight: 24,
            appearanceName: "NSAppearanceNameDarkAqua"
        )

        #expect(lhs == rhs)
        #expect(lhs.storageFilename == rhs.storageFilename)
        #expect(lhs.storageFilename.hasPrefix("icon-"))
        #expect(lhs.storageFilename.hasSuffix(".png"))
    }

    @Test func storageFilenameChangesWhenAppearanceChanges() {
        let light = MenuBarIconCacheKey(
            identityFingerprint: "owner|item|visible",
            displayID: 42,
            backingScale: 2.0,
            menuBarHeight: 24,
            appearanceName: "NSAppearanceNameAqua"
        )
        let dark = MenuBarIconCacheKey(
            identityFingerprint: "owner|item|visible",
            displayID: 42,
            backingScale: 2.0,
            menuBarHeight: 24,
            appearanceName: "NSAppearanceNameDarkAqua"
        )

        #expect(light != dark)
        #expect(light.storageFilename != dark.storageFilename)
    }
}
