# Apple HIG Inventory For MenuBarDeclutter

Generated: 2026-06-30

This inventory was built from Apple's live Human Interface Guidelines route index:

- HIG root: https://developer.apple.com/design/human-interface-guidelines/
- HIG route index used by the rendered docs app: https://developer.apple.com/tutorials/data/index/design--human-interface-guidelines
- macOS design entry: https://developer.apple.com/design/human-interface-guidelines/designing-for-macos
- Apple 2026 design resources announcement: https://developer.apple.com/news/?id=e2lxw9l1
- Liquid Glass technology overview: https://developer.apple.com/documentation/technologyoverviews/liquid-glass

The HIG route index returned 171 visible routes. The classification below is not
a claim that every paragraph on every page is applicable to this app. It is a
coverage map: every route is accounted for, then applied, used as supporting
guidance, or deliberately deferred as platform or feature irrelevant.

## Classification Key

| Mark | Meaning |
| --- | --- |
| Core | Must directly shape the redesign. |
| Supporting | Use as secondary guidance when the feature exists. |
| Defer / NA | Not relevant to this macOS menu bar utility right now. |

## Design Consequences

- The app should feel like a native macOS utility, not a web dashboard.
- The main Settings window should use a standard macOS split-view shell: sidebar,
  titlebar toolbar, search, content area, and optional inspector.
- Repeated Settings pages should use grouped forms, native controls, and standard
  section spacing.
- Dense data pages should use native tables, outline/list detail layouts, or a
  table plus inspector. Avoid card grids for operational information.
- Status menus should be true `NSMenu` command groups, not custom-drawn panels.
- Short-lived tools should use native popovers, utility panels, sheets, and
  alerts according to task scope.
- Liquid Glass should come from system materials and controls. Do not fake glass
  with decorative translucent cards.
- Privacy is part of the visual system: Basic Mode must visibly avoid sensitive
  permissions, and Pro Mode must be clearly opt-in.
- macOS 27 design resources should be treated as future-facing design kit input,
  but implementation should remain standard macOS 26+ AppKit/SwiftUI APIs unless
  Apple ships newer APIs in the project target.

## Route Inventory

### Getting Started

| HIG route | Relevance | MenuBarDeclutter decision |
| --- | --- | --- |
| Getting started | Supporting | Parent collection only. |
| Design principles | Core | Make the app direct, deferential, consistent, and focused on user control. |
| Designing for iOS | Defer / NA | iOS-specific. |
| Designing for iPadOS | Defer / NA | iPadOS-specific. |
| Designing for macOS | Core | Primary platform page for windowing, menus, keyboard, pointer, and app structure. |
| Designing for tvOS | Defer / NA | tvOS-specific. |
| Designing for visionOS | Defer / NA | visionOS-specific. |
| Designing for watchOS | Defer / NA | watchOS-specific. |
| Designing for games | Defer / NA | Not a game. |

### Foundations

| HIG route | Relevance | MenuBarDeclutter decision |
| --- | --- | --- |
| Foundations | Supporting | Parent collection only. |
| Accessibility | Core | Required for keyboard navigation, VoiceOver labels, contrast, reduce motion, and permission language. |
| App icons | Supporting | Use for final app icon and status item identity, not core page layout. |
| Branding | Supporting | Keep the product identity quiet and utility-like. |
| Color | Core | Use semantic system colors and a restrained status palette. |
| Dark Mode | Core | Every surface must work in Light, Dark, and increased contrast appearances. |
| Icons | Core | Use system metaphor and SF Symbols-style iconography. |
| Images | Supporting | Use only where they clarify setup or preview behavior. |
| Immersive experiences | Defer / NA | Spatial/immersive guidance is out of scope. |
| Inclusion | Core | Use plain, nonjudgmental language and flexible interaction paths. |
| Layout | Core | Drives spacing, hierarchy, alignment, and responsive window behavior. |
| Materials | Core | Use native window, sidebar, titlebar, popover, and panel materials only. |
| Motion | Supporting | Keep transitions subtle and respect Reduce Motion. |
| Privacy | Core | Central to Basic Mode, Pro Mode, permission gating, diagnostics, and onboarding. |
| Right to left | Supporting | Preserve mirroring-ready layouts where SwiftUI makes it practical. |
| SF Symbols | Core | Use SF Symbols through SwiftUI/AppKit instead of custom icon drawings. |
| Spatial layout | Defer / NA | visionOS-oriented. |
| Typography | Core | Use SF system text styles and native control sizing. |
| Writing | Core | Use concise, system-like labels and helpful permission copy. |

### Patterns

| HIG route | Relevance | MenuBarDeclutter decision |
| --- | --- | --- |
| Patterns | Supporting | Parent collection only. |
| Charting data | Supporting | Only useful for future diagnostics trends. |
| Collaboration and sharing | Defer / NA | No collaborative workflow planned. |
| Drag and drop | Core | Relevant for menu bar item grouping, import, and future layout editing. |
| Entering data | Core | Hotkeys, names, profile triggers, and import settings need native validation. |
| Feedback | Core | Status, warnings, permission denial, and repair outcomes need clear feedback. |
| File management | Core | Import/export, backups, and diagnostics export need predictable file flows. |
| Going full screen | Supporting | Settings should behave correctly, but fullscreen is not primary. |
| Launching | Core | Launch at login, menu bar accessory behavior, and onboarding state. |
| Live-viewing apps | Defer / NA | Not a live-viewing app. |
| Loading | Core | Discovery, diagnostics, import preview, and export should show native progress. |
| Managing accounts | Defer / NA | No account system planned. |
| Managing notifications | Supporting | Only if future automation uses user notifications. |
| Modality | Core | Use sheets/alerts only for focused decisions and destructive confirmation. |
| Multitasking | Supporting | The app should stay lightweight beside other apps. |
| Offering help | Core | Local help, diagnostics explanations, and setup guidance. |
| Onboarding | Core | First launch assistant for Basic Mode, control placement, and privacy promise. |
| Playing audio | Defer / NA | Not relevant. |
| Playing haptics | Defer / NA | Not relevant on macOS utility surfaces. |
| Playing video | Defer / NA | Not relevant. |
| Printing | Defer / NA | No printing workflow. |
| Ratings and reviews | Defer / NA | Not part of current native utility UI. |
| Searching | Core | Search settings, Find Icon, Second Bar filtering, and diagnostics filtering. |
| Settings | Core | Main redesign center. |
| Undo and redo | Core | Important for layout, groups, profiles, imports, and hotkey edits. |
| Workouts | Defer / NA | Not relevant. |

### Components - Content

| HIG route | Relevance | MenuBarDeclutter decision |
| --- | --- | --- |
| Components | Supporting | Parent collection only. |
| Content | Supporting | Parent collection only. |
| Charts | Supporting | Possible diagnostics only. |
| Image views | Supporting | Use for setup/preview images only if needed. |
| Text views | Supporting | Diagnostics log detail and exported text previews. |
| Web views | Defer / NA | Avoid web content in the app unless a future help system requires it. |

### Components - Layout And Organization

| HIG route | Relevance | MenuBarDeclutter decision |
| --- | --- | --- |
| Layout and organization | Core | Parent collection for the Settings shell and repeated structures. |
| Boxes | Supporting | Use sparingly for real grouped settings, not decorative cards. |
| Collections | Supporting | Useful for icon lists or group item picking. |
| Column views | Supporting | Useful for import/package browsing if needed. |
| Disclosure controls | Core | Advanced groups and optional Pro details should use standard disclosure. |
| Labels | Core | Critical for native control labeling and accessibility. |
| Lists and tables | Core | Primary structure for items, hotkeys, diagnostics, and profiles. |
| Lockups | Supporting | About/support rows and app identity blocks. |
| Outline views | Core | Groups, profiles, and import package hierarchy. |
| Split views | Core | Main Settings layout and table/inspector workflows. |
| Tab views | Supporting | Use only for dense submodes where sidebar would be too heavy. |

### Components - Menus And Actions

| HIG route | Relevance | MenuBarDeclutter decision |
| --- | --- | --- |
| Menus and actions | Core | Parent collection for command design. |
| Activity views | Defer / NA | Mostly share-sheet oriented. |
| Buttons | Core | Standard push, destructive, bordered, and toolbar buttons. |
| Context menus | Core | Item rows, groups, diagnostics, and table actions. |
| Dock menus | Supporting | App may be accessory-only, but menu commands should remain coherent. |
| Edit menus | Core | Undo/redo, copy diagnostics, paste/import text where relevant. |
| Home Screen quick actions | Defer / NA | iOS-specific. |
| Menus | Core | App menu, status menu, pull-downs, and context actions. |
| Ornaments | Defer / NA | visionOS-specific. |
| Pop-up buttons | Core | Native option selection inside grouped forms. |
| Pull-down buttons | Core | Toolbar/action menus for grouped commands. |
| The menu bar | Core | Central product surface. |
| Toolbars | Core | Settings window toolbar, search, add/remove, refresh, import/export. |

### Components - Navigation And Search

| HIG route | Relevance | MenuBarDeclutter decision |
| --- | --- | --- |
| Navigation and search | Core | Parent collection for sidebar/search architecture. |
| Path controls | Supporting | Useful only for file package browsing. |
| Search fields | Core | Main settings search, Find Icon, Second Bar filtering, diagnostics search. |
| Sidebars | Core | Primary navigation for Settings. |
| Tab bars | Defer / NA | Not a primary macOS Settings pattern here. |
| Token fields | Supporting | Useful for future app/include/exclude rules. |

### Components - Presentation

| HIG route | Relevance | MenuBarDeclutter decision |
| --- | --- | --- |
| Presentation | Core | Parent collection for windows, panels, popovers, sheets, and alerts. |
| Action sheets | Defer / NA | Not a typical macOS pattern for this app. |
| Alerts | Core | Permission failures, destructive actions, and unrecoverable errors. |
| Page controls | Defer / NA | Not needed. |
| Panels | Core | Find Icon, Second Bar, and compact transient utilities. |
| Popovers | Core | Status item affordances and small contextual tools. |
| Scroll views | Core | Settings pages and tables must scroll natively. |
| Sheets | Core | Import preview, onboarding substeps, and confirmation flows. |
| Windows | Core | Settings, onboarding, diagnostics, and utility window behavior. |

### Components - Selection And Input

| HIG route | Relevance | MenuBarDeclutter decision |
| --- | --- | --- |
| Selection and input | Core | Parent collection for form controls. |
| Color wells | Defer / NA | Avoid custom theming unless future user color labels exist. |
| Combo boxes | Supporting | Useful for searchable rule selection if added. |
| Digit entry views | Defer / NA | Not needed. |
| Image wells | Defer / NA | Not needed. |
| Pickers | Core | Profiles, layout presets, triggers, and modes. |
| Segmented controls | Core | Table filtering and mode switching where compact. |
| Sliders | Core | Delays, highlight duration, spacing preview. |
| Steppers | Supporting | Possible numeric delay/spacing adjustment. |
| Text fields | Core | Search, names, hotkey labels, import descriptions. |
| Toggles | Core | Basic settings, opt-in Pro features, and feature flags. |
| Virtual keyboards | Defer / NA | Not applicable to native macOS. |

### Components - Status

| HIG route | Relevance | MenuBarDeclutter decision |
| --- | --- | --- |
| Status | Supporting | Parent collection for health/status display. |
| Activity rings | Defer / NA | Not relevant. |
| Gauges | Supporting | Possible future capacity/coverage status only. |
| Progress indicators | Core | Discovery, import/export, diagnostics, and repair tasks. |
| Rating indicators | Defer / NA | Not relevant. |

### Components - System Experiences

| HIG route | Relevance | MenuBarDeclutter decision |
| --- | --- | --- |
| System experiences | Supporting | Parent collection for OS-level integrations. |
| App Shortcuts | Core | Pro-safe Shortcuts/App Intents automation UI. |
| Complications | Defer / NA | watchOS-specific. |
| Controls | Supporting | Use only if a future Control Center-style affordance is appropriate. |
| Live Activities | Defer / NA | Not relevant. |
| Notifications | Supporting | Only if future automation needs user notifications. |
| Snippets | Defer / NA | Not relevant now. |
| Status bars | Defer / NA | iOS-specific meaning; macOS menu bar handled separately. |
| Top Shelf | Defer / NA | tvOS-specific. |
| Watch faces | Defer / NA | watchOS-specific. |
| Widgets | Defer / NA | No widget planned. |

### Inputs

| HIG route | Relevance | MenuBarDeclutter decision |
| --- | --- | --- |
| Inputs | Supporting | Parent collection only. |
| Action button | Defer / NA | Hardware-specific. |
| Apple Pencil and Scribble | Defer / NA | iPadOS-specific. |
| Camera Control | Defer / NA | Hardware-specific. |
| Digital Crown | Defer / NA | watchOS/visionOS-specific. |
| Eyes | Defer / NA | visionOS-specific. |
| Focus and selection | Core | Keyboard focus, table selection, VoiceOver, and full keyboard access. |
| Game controls | Defer / NA | Not relevant. |
| Gestures | Supporting | Pointer and trackpad gestures only where native. |
| Gyroscope and accelerometer | Defer / NA | Not relevant. |
| Keyboards | Core | Hotkeys, shortcuts, menu commands, focus movement. |
| Nearby interactions | Defer / NA | Not relevant. |
| Pointing devices | Core | Hover, click, drag, row selection, and menu bar interactions. |
| Remotes | Defer / NA | Not relevant. |

### Technologies

| HIG route | Relevance | MenuBarDeclutter decision |
| --- | --- | --- |
| Technologies | Supporting | Parent collection only. |
| AirPlay | Defer / NA | Not relevant. |
| Always On | Defer / NA | Not relevant. |
| App Clips | Defer / NA | iOS-specific. |
| Apple Pay | Defer / NA | Not relevant. |
| Augmented reality | Defer / NA | Not relevant. |
| CareKit | Defer / NA | Not relevant. |
| CarPlay | Defer / NA | Not relevant. |
| Game Center | Defer / NA | Not relevant. |
| Generative AI | Defer / NA | No AI feature in the current product. |
| HealthKit | Defer / NA | Not relevant. |
| HomeKit | Defer / NA | Not relevant. |
| iCloud | Supporting | Only if future settings sync is added with explicit user control. |
| ID Verifier | Defer / NA | Not relevant. |
| iMessage apps and stickers | Defer / NA | Not relevant. |
| In-app purchase | Defer / NA | Only relevant if a future Pro purchase flow ships. |
| Live Photos | Defer / NA | Not relevant. |
| Mac Catalyst | Defer / NA | App is native macOS AppKit/SwiftUI, not Catalyst. |
| Machine learning | Defer / NA | Not relevant. |
| Maps | Defer / NA | Not relevant. |
| NFC | Defer / NA | Not relevant. |
| Photo editing | Defer / NA | Not relevant. |
| ResearchKit | Defer / NA | Not relevant. |
| SharePlay | Defer / NA | Not relevant. |
| ShazamKit | Defer / NA | Not relevant. |
| Sign in with Apple | Defer / NA | No account flow planned. |
| Siri | Supporting | Possible App Shortcuts/Siri integration only after safe automation exists. |
| Tap to Pay on iPhone | Defer / NA | Not relevant. |
| VoiceOver | Core | Required accessibility support. |
| Wallet | Defer / NA | Not relevant. |

## Page Set For The App

These are the app surfaces required by the product after applying the inventory:

| App surface | Reused template |
| --- | --- |
| Overview | Grouped settings form |
| Menu Bar Items | Table plus inspector |
| Behavior | Grouped settings form |
| Layout | Grouped settings form plus preview band |
| Search | Grouped settings form |
| Second Bar | Grouped settings form plus compact utility panel |
| Groups | Outline/list plus detail editor |
| Hotkeys | Table plus inspector |
| Profiles | Outline/list plus detail editor |
| Automation | Grouped settings form |
| Import / Export | Outline/list plus assistant sheet |
| Privacy | Grouped settings form |
| Diagnostics | Table plus inspector |
| Advanced | Grouped settings form with disclosures |
| About | Grouped settings form |
| First launch onboarding | Assistant window/sheet |
| Find Icon panel | Compact utility panel |
| Second Bar panel | Compact utility panel |
| Status item menu | Native `NSMenu` |

## Reusable Native Templates

| Template | HIG roots | App use |
| --- | --- | --- |
| Settings shell | Designing for macOS, Settings, Windows, Split views, Sidebars, Toolbars, Search fields | All Settings pages. |
| Grouped form | Layout, Labels, Toggles, Pickers, Sliders, Pop-up buttons, Disclosure controls | Most preference pages. |
| Table plus inspector | Lists and tables, Split views, Selection, Toolbars, Context menus | Items, hotkeys, diagnostics. |
| Outline/list plus detail | Outline views, Lists and tables, Disclosure controls, Undo and redo | Groups, profiles, import packages. |
| Assistant/sheet | Onboarding, Sheets, Modality, Buttons, Feedback | First launch, import preview, confirmations. |
| Compact panel/popover | Panels, Popovers, Search fields, Focus and selection | Find Icon, Second Bar, contextual panels. |
| Status menu | The menu bar, Menus, Context menus, Keyboard, App Shortcuts | Menu bar control and command surface. |
