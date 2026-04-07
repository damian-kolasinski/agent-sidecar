import SwiftUI

/// Renders a single file diff as a `Section` so the parent `LazyVStack`
/// can pin the file header while its lines scroll underneath.
struct FileDiffSectionView: View {
    let fileDiff: FileDiff
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var detailViewModel: DiffDetailViewModel

    private var isCollapsed: Bool {
        detailViewModel.isFileCollapsed(fileDiff.displayPath)
    }

    private var isReviewed: Bool {
        detailViewModel.isFileReviewed(fileDiff.displayPath)
    }

    private var isSwiftFile: Bool {
        fileDiff.newPath.hasSuffix(".swift") || fileDiff.oldPath.hasSuffix(".swift")
    }

    var body: some View {
        Section {
            if !isCollapsed {
                if fileDiff.isBinary {
                    binaryFileNotice
                } else {
                    ForEach(fileDiff.hunks) { hunk in
                        HunkHeaderView(header: hunk.header)

                        ForEach(hunk.lines) { line in
                            DiffLineView(line: line, syntaxHighlight: isSwiftFile) {
                                detailViewModel.openComposer(
                                    filePath: fileDiff.displayPath,
                                    anchor: line.anchor
                                )
                            }

                            let comments = appViewModel.commentsForAnchor(
                                fileDiff.displayPath,
                                anchor: line.anchor
                            )
                            if !comments.isEmpty {
                                CommentThreadView(
                                    comments: comments,
                                    anchor: line.anchor
                                )
                            }

                            if detailViewModel.composerAnchor == line.anchor
                                && detailViewModel.composerFilePath == fileDiff.displayPath {
                                InlineCommentComposer(
                                    onSubmit: { body in
                                        appViewModel.addComment(
                                            filePath: fileDiff.displayPath,
                                            lineAnchor: line.anchor,
                                            body: body
                                        )
                                        detailViewModel.closeComposer()
                                    },
                                    onCancel: {
                                        detailViewModel.closeComposer()
                                    }
                                )
                            }
                        }
                    }
                }
            }
        } header: {
            fileHeader
                .zIndex(1)
        }
    }

    private var fileHeader: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 12)

            DSBadge(status: fileDiff.status)

            Text(fileDiff.displayPath)
                .font(DSFont.heading)
                .lineLimit(1)
                .truncationMode(.middle)

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

            viewedToggle
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background {
            ZStack {
                DSColor.sidebarBackground
                if isReviewed {
                    DSColor.statusAdded.opacity(0.06)
                } else {
                    DSColor.hunkHeaderBackground.opacity(0.5)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                detailViewModel.toggleFileCollapsed(fileDiff.displayPath)
            }
        }
    }

    private var viewedToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                detailViewModel.toggleFileReviewed(fileDiff.displayPath)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isReviewed ? "checkmark.square.fill" : "square")
                    .font(.system(size: 12))
                    .foregroundStyle(isReviewed ? DSColor.statusAdded : .secondary)
                Text("Viewed")
                    .font(DSFont.caption)
                    .foregroundStyle(isReviewed ? DSColor.statusAdded : .secondary)
            }
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xxs)
        }
        .buttonStyle(.plain)
    }

    private var binaryFileNotice: some View {
        HStack {
            Spacer()
            Text("Binary file — cannot display diff")
                .font(DSFont.body)
                .foregroundStyle(.secondary)
                .padding(DSSpacing.xl)
            Spacer()
        }
    }
}
