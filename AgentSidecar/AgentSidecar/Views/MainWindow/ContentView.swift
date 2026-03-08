import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
        }
        .navigationSplitViewColumnWidth(min: DSSpacing.sidebarWidth, ideal: DSSpacing.sidebarWidth + 40)
        .toolbar {
            ToolbarActions()
        }
    }
}
