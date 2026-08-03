import SwiftData
import SwiftUI
import UIKit

@main
struct EgressApp: App {
    private let dependencies = AppDependencies.live()
    /// The audio + haptic + settings channels, created once and shared through the environment.
    @State private var feedback = FeedbackServices()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Self.configureChromeAppearance()
    }

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environment(\.dependencies, dependencies)
                .environment(feedback)
                .modelContainer(dependencies.modelContainer)
        }
        .onChange(of: scenePhase) { _, phase in feedback.handle(phase) }
    }

    /// Paints the UIKit chrome (nav bars, tab bar, List/Form grounds) in the cream shell so the whole
    /// app reads as one warm surface — the SwiftUI tokens handle everything inside. Serif nav titles
    /// (New York ≈ Zilla Slab) match `.egDisplay`. Called once at launch.
    private static func configureChromeAppearance() {
        let ground = UIColor(hexValue: 0xF4E8D0)
        let raised = UIColor(hexValue: 0xFBF4E4)
        let ink = UIColor(hexValue: 0x2B2622)
        let taupe = UIColor(hexValue: 0x9E8E73)
        let sage = UIColor(hexValue: 0x8DA85A)

        // List / Form grounds (belt; screens also set .scrollContentBackground(.hidden)).
        UITableView.appearance().backgroundColor = ground
        UICollectionView.appearance().backgroundColor = ground

        /// Serif titles to echo the display face.
        func serif(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
            return UIFont(descriptor: descriptor, size: size)
        }

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = ground
        nav.shadowColor = .clear
        nav.largeTitleTextAttributes = [.foregroundColor: ink, .font: serif(34, .bold)]
        nav.titleTextAttributes = [.foregroundColor: ink, .font: serif(17, .semibold)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = sage

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = raised
        tab.shadowColor = UIColor(hexValue: 0xCBB899)
        for item in [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance] {
            item.selected.iconColor = sage
            item.selected.titleTextAttributes = [.foregroundColor: sage]
            item.normal.iconColor = taupe
            item.normal.titleTextAttributes = [.foregroundColor: taupe]
        }
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = sage
    }
}
