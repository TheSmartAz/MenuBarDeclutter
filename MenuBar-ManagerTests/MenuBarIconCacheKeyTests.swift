import AppKit
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

@Suite("MenuBar Rendered Icon Cache")
@MainActor
struct MenuBarRenderedIconCacheTests {
    @Test func removeAllClearsRenderedAndStaleIconLookups() throws {
        let cache = MenuBarRenderedIconCache()
        let snapshot = Self.snapshot(id: "cache-test", frame: Self.menuBarFrame(height: 22))
        let cacheKey = try #require(MenuBarIconAppearanceResolver().cacheKey(for: snapshot))
        let image = try #require(Self.makeImage())

        cache.cache(MenuBarIconSnapshot(
            identity: MenuBarIconIdentity(snapshot: snapshot),
            image: image,
            frameInScreenPoints: try #require(snapshot.frame),
            scale: 1,
            cacheKey: cacheKey,
            source: .renderedCapture,
            capturedAt: Date(timeIntervalSince1970: 1_782_700_000)
        ))

        let rendered = try #require(cache.resolvedImage(for: snapshot))
        #expect(rendered.source == .renderedCapture)

        let resizedSnapshot = Self.snapshot(id: snapshot.id, frame: Self.menuBarFrame(height: 24))
        let stale = try #require(cache.resolvedImage(for: resizedSnapshot))
        #expect(stale.source == .staleRenderedCapture)

        #expect(cache.removeAll())
        #expect(cache.resolvedImage(for: snapshot) == nil)
        #expect(cache.resolvedImage(for: resizedSnapshot) == nil)
    }

    private static func snapshot(id: String, frame: CGRect) -> MenuBarItemSnapshot {
        MenuBarItemSnapshot(
            id: id,
            title: "Cache Test",
            role: "AXMenuBarItem",
            subrole: nil,
            frame: frame,
            owningProcessIdentifier: nil,
            owningApplicationName: "Cache Test",
            bundleIdentifier: "com.example.cache-test",
            zone: .hidden,
            isLikelySystemItem: false,
            scanTimestamp: Date(timeIntervalSince1970: 1_782_700_000)
        )
    }

    private static func menuBarFrame(height: CGFloat) -> CGRect {
        let screenFrame = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        return CGRect(
            x: screenFrame.maxX - 120,
            y: screenFrame.maxY - height,
            width: 24,
            height: height
        )
    }

    private static func makeImage() -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: 2,
            height: 2,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.setFillColor(CGColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        return context.makeImage()
    }
}
