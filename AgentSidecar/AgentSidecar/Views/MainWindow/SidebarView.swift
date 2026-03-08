import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var listViewModel = DiffListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ScopePickerView()
                .padding(DSSpacing.sm)

            DSDivider(.horizontal)

            if appViewModel.fileDiffs.isEmpty && !appViewModel.isLoading {
                emptyState
            } else {
                fileList
            }
        }
        .searchable(text: $listViewModel.searchText, prompt: "Filter files…")
    }

    private var sidebarSelection: Binding<String?> {
        Binding(
            get: { appViewModel.selectedFilePath },
            set: { newValue in
                appViewModel.selectedFilePath = newValue
                appViewModel.scrollToFilePath = newValue
            }
        )
    }

    private var fileList: some View {
        List(
            listViewModel.filteredFiles(appViewModel.fileDiffs),
            selection: sidebarSelection
        ) { fileDiff in
            fileRow(fileDiff)
                .tag(fileDiff.displayPath)
        }
        .listStyle(.sidebar)
    }

    private func fileRow(_ fileDiff: FileDiff) -> some View {
        HStack(spacing: DSSpacing.sm) {
            DSBadge(status: fileDiff.status)

            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(fileName(from: fileDiff.displayPath))
                    .font(DSFont.body)
                    .lineLimit(1)
                Text(directoryPath(from: fileDiff.displayPath))
                    .font(DSFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: DSSpacing.xs) {
                if fileDiff.additionCount > 0 {
                    Text("+\(fileDiff.additionCount)")
                        .font(DSFont.caption)
                        .foregroundStyle(DSColor.statusAdded)
                }
                if fileDiff.deletionCount > 0 {
                    Text("-\(fileDiff.deletionCount)")
                        .font(DSFont.caption)
                        .foregroundStyle(DSColor.statusDeleted)
                }
            }
        }
        .padding(.vertical, DSSpacing.xxs)
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("No changes found")
                .font(DSFont.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func fileName(from path: String) -> String {
        (path as NSString).lastPathComponent
    }

    private func directoryPath(from path: String) -> String {
        let dir = (path as NSString).deletingLastPathComponent
        return dir.isEmpty ? "" : dir
    }
}
