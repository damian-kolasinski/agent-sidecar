import SwiftUI

/// Renders a single file's diff content as flat rows suitable for embedding
/// directly inside a parent `LazyVStack`. No internal `VStack` wrapper, so
/// the parent container drives lazy loading at the line level.
struct FileDiffSectionView: View {
    let fileDiff: FileDiff
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var detailViewModel: DiffDetailViewModel

    var body: some View {
        fileHeader

        if fileDiff.isBinary {
            binaryFileNotice
        } else {
            ForEach(fileDiff.hunks) { hunk in
                HunkHeaderView(header: hunk.header)

                ForEach(hunk.lines) { line in
                    DiffLineView(line: line) {
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

    private var fileHeader: some View {
        HStack(spacing: DSSpacing.sm) {
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
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(DSColor.hunkHeaderBackground.opacity(0.5))
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
