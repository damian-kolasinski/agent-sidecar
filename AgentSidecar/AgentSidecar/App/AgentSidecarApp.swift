import SwiftUI

@main
struct AgentSidecarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .onOpenURL { url in
                    appViewModel.handleDeeplink(url: url)
                }
                .task {
                    await appViewModel.loadRecents()
                }
                .frame(minWidth: 800, minHeight: 500)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(after: .newItem) {
                Menu("Open Recent") {
                    ForEach(appViewModel.recentRepositories) { repo in
                        Button(repo.displayName) {
                            appViewModel.selectRecentRepo(repo)
                        }
                    }
                    if !appViewModel.recentRepositories.isEmpty {
                        Divider()
                        Button("Clear Recents") {
                            appViewModel.clearRecents()
                        }
                    }
                }
                .disabled(appViewModel.recentRepositories.isEmpty)
            }
        }
    }
}
