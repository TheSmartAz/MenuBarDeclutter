#!/usr/bin/env swift

import CoreGraphics
import Darwin
import Foundation

private struct Config {
    var ownerName = "MenuBarDeclutter"
    var ownerPID: Int?
    var titleContains: String?
    var minWidth: Double = 120
    var minHeight: Double = 80
    var waitSeconds: Double = 15
    var pollInterval: TimeInterval = 0.25
}

private struct WindowCandidate {
    let id: Int
    let title: String
    let ownerName: String
    let ownerPID: Int
    let layer: Int
    let alpha: Double
    let bounds: CGRect

    var area: Double {
        Double(bounds.width * bounds.height)
    }

    var tabSeparatedDescription: String {
        [
            String(id),
            String(Int(bounds.origin.x.rounded())),
            String(Int(bounds.origin.y.rounded())),
            String(Int(bounds.width.rounded())),
            String(Int(bounds.height.rounded())),
            String(layer),
            title.replacingOccurrences(of: "\t", with: " ")
        ].joined(separator: "\t")
    }
}

private func writeError(_ message: String) {
    FileHandle.standardError.write(Data(message.utf8))
}

private func usage() -> Never {
    writeError("""
    Usage: qa_window_id.swift [--owner NAME] [--pid PID] [--title-contains TEXT] [--min-width PX] [--min-height PX] [--wait SECONDS]

    Prints the best matching on-screen window as tab-separated fields:
    windowID x y width height layer title
    """)
    exit(2)
}

private func takeValue(from args: inout [String], for option: String) -> String {
    guard !args.isEmpty else {
        writeError("error: missing value for \(option)\n")
        usage()
    }

    return args.removeFirst()
}

private func parseConfig() -> Config {
    var config = Config()
    var args = Array(CommandLine.arguments.dropFirst())

    while !args.isEmpty {
        let option = args.removeFirst()

        switch option {
        case "--owner":
            config.ownerName = takeValue(from: &args, for: option)
        case "--pid":
            guard let value = Int(takeValue(from: &args, for: option)) else {
                writeError("error: --pid must be numeric\n")
                usage()
            }
            config.ownerPID = value
        case "--title-contains":
            config.titleContains = takeValue(from: &args, for: option)
        case "--min-width":
            guard let value = Double(takeValue(from: &args, for: option)) else {
                writeError("error: --min-width must be numeric\n")
                usage()
            }
            config.minWidth = value
        case "--min-height":
            guard let value = Double(takeValue(from: &args, for: option)) else {
                writeError("error: --min-height must be numeric\n")
                usage()
            }
            config.minHeight = value
        case "--wait":
            guard let value = Double(takeValue(from: &args, for: option)) else {
                writeError("error: --wait must be numeric\n")
                usage()
            }
            config.waitSeconds = value
        case "-h", "--help":
            usage()
        default:
            writeError("error: unknown option \(option)\n")
            usage()
        }
    }

    return config
}

private func number(_ value: Any?) -> Double? {
    switch value {
    case let number as NSNumber:
        return number.doubleValue
    case let double as Double:
        return double
    case let int as Int:
        return Double(int)
    default:
        return nil
    }
}

private func integer(_ value: Any?) -> Int? {
    switch value {
    case let number as NSNumber:
        return number.intValue
    case let int as Int:
        return int
    default:
        return nil
    }
}

private func bounds(from dictionary: [String: Any]) -> CGRect? {
    guard
        let x = number(dictionary["X"]),
        let y = number(dictionary["Y"]),
        let width = number(dictionary["Width"]),
        let height = number(dictionary["Height"])
    else {
        return nil
    }

    return CGRect(x: x, y: y, width: width, height: height)
}

private func collectWindows(ownerName: String? = nil, ownerPID: Int? = nil) -> [WindowCandidate] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    guard let rawWindows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
        return []
    }

    return rawWindows.compactMap { info in
        let owner = info[kCGWindowOwnerName as String] as? String ?? ""
        if let ownerName, owner != ownerName {
            return nil
        }

        guard
            let id = integer(info[kCGWindowNumber as String]),
            let pid = integer(info[kCGWindowOwnerPID as String]),
            let boundsDictionary = info[kCGWindowBounds as String] as? [String: Any],
            let bounds = bounds(from: boundsDictionary)
        else {
            return nil
        }

        if let ownerPID, pid != ownerPID {
            return nil
        }

        let title = info[kCGWindowName as String] as? String ?? ""
        let layer = integer(info[kCGWindowLayer as String]) ?? 0
        let alpha = number(info[kCGWindowAlpha as String]) ?? 1

        return WindowCandidate(
            id: id,
            title: title,
            ownerName: owner,
            ownerPID: pid,
            layer: layer,
            alpha: alpha,
            bounds: bounds
        )
    }
}

private func matchingWindows(config: Config) -> [WindowCandidate] {
    collectWindows(ownerName: config.ownerName, ownerPID: config.ownerPID).filter { window in
        guard window.alpha > 0 else {
            return false
        }

        guard
            Double(window.bounds.width) >= config.minWidth,
            Double(window.bounds.height) >= config.minHeight
        else {
            return false
        }

        if let titleContains = config.titleContains,
           window.title.range(of: titleContains, options: [.caseInsensitive, .diacriticInsensitive]) == nil {
            return false
        }

        return true
    }
}

private func bestWindow(from windows: [WindowCandidate]) -> WindowCandidate? {
    windows.sorted { lhs, rhs in
        if lhs.area != rhs.area {
            return lhs.area > rhs.area
        }

        if lhs.layer != rhs.layer {
            return lhs.layer < rhs.layer
        }

        return lhs.id < rhs.id
    }.first
}

private let config = parseConfig()
private let deadline = Date().addingTimeInterval(config.waitSeconds)

repeat {
    if let window = bestWindow(from: matchingWindows(config: config)) {
        print(window.tabSeparatedDescription)
        exit(0)
    }

    Thread.sleep(forTimeInterval: config.pollInterval)
} while Date() < deadline

let pidDescription = config.ownerPID.map { " pid '\($0)'" } ?? ""
writeError("error: no matching window for owner '\(config.ownerName)'\(pidDescription) within \(config.waitSeconds)s\n")
private let ownedWindows = collectWindows(ownerName: config.ownerName, ownerPID: config.ownerPID)
if ownedWindows.isEmpty {
    writeError("diagnostic: no on-screen windows owned by \(config.ownerName)\(pidDescription)\n")
} else {
    writeError("diagnostic: visible \(config.ownerName)\(pidDescription) windows:\n")
    for window in ownedWindows.sorted(by: { $0.area > $1.area }) {
        writeError(
            "  id=\(window.id) pid=\(window.ownerPID) layer=\(window.layer) alpha=\(window.alpha) " +
            "bounds=\(Int(window.bounds.width))x\(Int(window.bounds.height)) " +
            "title='\(window.title)'\n"
        )
    }
}
exit(1)
