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
                    diffContent
                }
            }
        } header: {
            fileHeader
                .zIndex(1)
        }
    }

    // MARK: - Diff Content with Gaps

    @ViewBuilder
    private var diffContent: some View {
        let fileLines = appViewModel.fileLines(for: fileDiff.newPath)
        let totalFileLines = fileLines?.count ?? 0
        let hunks = fileDiff.hunks

        // Gap before first hunk
        if let firstHunk = hunks.first, firstHunk.newStart > 1, let fileLines {
            gapView(
                gapIndex: 0,
                newLineStart: 1,
                oldLineStart: 1,
                lineCount: firstHunk.newStart - 1,
                fileLines: fileLines,
                showExpandDown: true,
                showExpandUp: false
            )
        }

        ForEach(fileDiff.hunks) { hunk in
            if !shouldHideHunkHeader(hunk) {
                HunkHeaderView(header: hunk.header)
            }

            ForEach(hunk.lines) { line in
                lineWithComments(line)
            }

            afterHunkGap(hunk: hunk, fileLines: fileLines, totalFileLines: totalFileLines)
        }
    }

    // MARK: - Gap Helpers

    private func shouldHideHunkHeader(_ hunk: DiffHunk) -> Bool {
        let hunks = fileDiff.hunks
        guard let hunkIndex = hunks.firstIndex(where: { $0.id == hunk.id }) else { return false }

        let gapIndex: Int
        let lineCount: Int

        if hunkIndex == 0 {
            gapIndex = 0
            lineCount = hunks[0].newStart - 1
        } else {
            gapIndex = hunkIndex
            let prevHunk = hunks[hunkIndex - 1]
            lineCount = hunks[hunkIndex].newStart - (prevHunk.newStart + prevHunk.newCount)
        }

        guard lineCount > 0 else { return false }

        let gapID = "\(fileDiff.newPath):gap-\(gapIndex)"
        let expansion = detailViewModel.expansion(for: gapID)
        let remaining = max(0, lineCount - expansion.fromTop - expansion.fromBottom)
        // Hide when fully expanded or when bottom-expanded lines flow into this hunk
        return remaining == 0 || expansion.fromBottom > 0
    }

    // MARK: - Gap After Hunk

    @ViewBuilder
    private func afterHunkGap(hunk: DiffHunk, fileLines: [String]?, totalFileLines: Int) -> some View {
        if let fileLines, let gap = computeGapAfterHunk(hunk, totalFileLines: totalFileLines) {
            gapView(
                gapIndex: gap.gapIndex,
                newLineStart: gap.newLineStart,
                oldLineStart: gap.oldLineStart,
                lineCount: gap.lineCount,
                fileLines: fileLines,
                showExpandDown: gap.showExpandDown,
                showExpandUp: gap.showExpandUp
            )
        }
    }

    private struct GapParams {
        let gapIndex: Int
        let newLineStart: Int
        let oldLineStart: Int
        let lineCount: Int
        let showExpandDown: Bool
        let showExpandUp: Bool
    }

    private func computeGapAfterHunk(_ hunk: DiffHunk, totalFileLines: Int) -> GapParams? {
        let hunks = fileDiff.hunks
        guard let hunkIndex = hunks.firstIndex(where: { $0.id == hunk.id }) else {
            return nil
        }
        let newLineStart = hunk.newStart + hunk.newCount
        let oldLineStart = hunk.oldStart + hunk.oldCount
        let gapIndex = hunkIndex + 1

        if hunkIndex < hunks.count - 1 {
            let nextHunk = hunks[hunkIndex + 1]
            let lineCount = nextHunk.newStart - newLineStart
            guard lineCount > 0 else { return nil }
            return GapParams(
                gapIndex: gapIndex,
                newLineStart: newLineStart,
                oldLineStart: oldLineStart,
                lineCount: lineCount,
                showExpandDown: true,
                showExpandUp: true
            )
        } else if totalFileLines >= newLineStart {
            let lineCount = totalFileLines - newLineStart + 1
            guard lineCount > 0 else { return nil }
            return GapParams(
                gapIndex: gapIndex,
                newLineStart: newLineStart,
                oldLineStart: oldLineStart,
                lineCount: lineCount,
                showExpandDown: false,
                showExpandUp: true
            )
        }
        return nil
    }

    // MARK: - Gap Expansion View

    @ViewBuilder
    private func gapView(
        gapIndex: Int,
        newLineStart: Int,
        oldLineStart: Int,
        lineCount: Int,
        fileLines: [String],
        showExpandDown: Bool,
        showExpandUp: Bool
    ) -> some View {
        let gapID = "\(fileDiff.newPath):gap-\(gapIndex)"
        let expansion = detailViewModel.expansion(for: gapID)
        let remaining = max(0, lineCount - expansion.fromTop - expansion.fromBottom)

        // Lines expanded from top (continuing after previous hunk)
        ForEach(expandedLines(
            fileLines: fileLines,
            startNew: newLineStart,
            startOld: oldLineStart,
            count: expansion.fromTop,
            gapIndex: gapIndex,
            label: "t"
        )) { line in
            lineWithComments(line)
        }

        // Separator (if hidden lines remain)
        if remaining > 0 {
            GapSeparatorView(
                remainingLines: remaining,
                showExpandDown: showExpandDown,
                showExpandUp: showExpandUp,
                onExpandDown: { detailViewModel.expandGapDown(gapID, totalLines: lineCount) },
                onExpandUp: { detailViewModel.expandGapUp(gapID, totalLines: lineCount) }
            )
        }

        // Lines expanded from bottom (prepending before next hunk)
        ForEach(expandedLines(
            fileLines: fileLines,
            startNew: newLineStart + lineCount - expansion.fromBottom,
            startOld: oldLineStart + lineCount - expansion.fromBottom,
            count: expansion.fromBottom,
            gapIndex: gapIndex,
            label: "b"
        )) { line in
            lineWithComments(line)
        }
    }

    private func expandedLines(
        fileLines: [String],
        startNew: Int,
        startOld: Int,
        count: Int,
        gapIndex: Int,
        label: String
    ) -> [DiffLine] {
        guard count > 0 else { return [] }
        return (0..<count).compactMap { offset in
            let newLine = startNew + offset
            guard newLine >= 1 && newLine <= fileLines.count else { return nil }
            return DiffLine(
                id: "exp-\(fileDiff.id)-g\(gapIndex)-\(label)\(newLine)",
                type: .context,
                content: fileLines[newLine - 1],
                oldLineNumber: startOld + offset,
                newLineNumber: newLine,
                noNewlineAtEnd: false
            )
        }
    }

    // MARK: - Line with Comments

    @ViewBuilder
    private func lineWithComments(_ line: DiffLine) -> some View {
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

    // MARK: - File Header

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
