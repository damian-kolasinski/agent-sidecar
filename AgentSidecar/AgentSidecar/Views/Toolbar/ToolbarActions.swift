import SwiftUI

struct ToolbarActions: ToolbarContent {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                appViewModel.openDirectoryPicker()
            } label: {
                Label("Open", systemImage: "folder")
            }
            .help("Open repository")

            Button {
                Task { await appViewModel.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .help("Refresh diffs")
            .keyboardShortcut("r", modifiers: .command)

            Button {
                appViewModel.saveReview()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .help("Save review comments")
            .keyboardShortcut("s", modifiers: .command)
        }
    }
}
