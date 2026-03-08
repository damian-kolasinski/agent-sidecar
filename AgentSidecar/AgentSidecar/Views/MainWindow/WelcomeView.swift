import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            Spacer()

            header

            if !appViewModel.recentRepositories.isEmpty {
                recentsList
            }

            DSButton("Open Repository") {
                appViewModel.openDirectoryPicker()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        VStack(spacing: DSSpacing.sm) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text("Agent Sidecar")
                .font(DSFont.heading)

            Text("Open a Git repository to view diffs.")
                .font(DSFont.body)
                .foregroundStyle(.secondary)
        }
    }

    private var recentsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent Repositories")
                .font(DSFont.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, DSSpacing.md)
                .padding(.bottom, DSSpacing.xs)

            VStack(spacing: 0) {
                ForEach(appViewModel.recentRepositories) { repo in
                    recentRow(repo)

                    if repo.id != appViewModel.recentRepositories.last?.id {
                        DSDivider(.horizontal)
                    }
                }
            }
            .background(DSColor.sidebarBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DSColor.separator, lineWidth: 1)
            )
        }
        .frame(maxWidth: 400)
    }

    private func recentRow(_ repo: RecentRepository) -> some View {
        Button {
            appViewModel.selectRecentRepo(repo)
        } label: {
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text(repo.displayName)
                        .font(DSFont.body)
                        .lineLimit(1)
                    Text(repo.abbreviatedPath)
                        .font(DSFont.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Remove from Recents", role: .destructive) {
                appViewModel.removeRecentRepo(repo)
            }
        }
    }
}
