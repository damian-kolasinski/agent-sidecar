import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        Group {
            switch appViewModel.currentMode {
            case .diffReview:
                NavigationSplitView {
                    SidebarView()
                } detail: {
                    DetailView()
                }
                .navigationSplitViewColumnWidth(min: DSSpacing.sidebarWidth, ideal: DSSpacing.sidebarWidth + 40)
                .toolbar {
                    ToolbarActions()
                }
            case .planReview(let filePath):
                NavigationStack {
                    PlanReviewView(filePath: filePath)
                }
            case .fileReview(let payload):
                NavigationStack {
                    FileReviewView(payload: payload)
                }
            }
        }
    }
}
