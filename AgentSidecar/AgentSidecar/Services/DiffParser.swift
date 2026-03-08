import Foundation

enum DiffParser {
    // Regex for hunk headers: @@ -oldStart[,oldCount] +newStart[,newCount] @@
    private nonisolated(unsafe) static let hunkHeaderPattern = /^@@\s+-(\d+)(?:,(\d+))?\s+\+(\d+)(?:,(\d+))?\s+@@(.*)$/

    static func parse(_ rawDiff: String) -> [FileDiff] {
        let lines = rawDiff.components(separatedBy: "\n")
        var fileDiffs: [FileDiff] = []

        var currentOldPath: String?
        var currentNewPath: String?
        var currentStatus: FileStatus = .modified
        var currentIsBinary = false
        var currentHunks: [DiffHunk] = []
        var currentHunkLines: [DiffLine] = []
        var currentHunkHeader: String?
        var hunkOldStart = 0
        var hunkOldCount = 0
        var hunkNewStart = 0
        var hunkNewCount = 0
        var currentOld = 0
        var currentNew = 0
        var lineIndex = 0
        var hunkIndex = 0
        var fileIndex = 0

        func finalizeHunk() {
            if let header = currentHunkHeader {
                let hunk = DiffHunk(
                    id: "hunk-\(fileIndex)-\(hunkIndex)",
                    header: header,
                    oldStart: hunkOldStart,
                    oldCount: hunkOldCount,
                    newStart: hunkNewStart,
                    newCount: hunkNewCount,
                    lines: currentHunkLines
                )
                currentHunks.append(hunk)
                hunkIndex += 1
                currentHunkLines = []
                currentHunkHeader = nil
            }
        }

        func finalizeFile() {
            finalizeHunk()
            if let oldPath = currentOldPath {
                let newPath = currentNewPath ?? oldPath
                let fileDiff = FileDiff(
                    id: "file-\(fileIndex)",
                    oldPath: oldPath,
                    newPath: newPath,
                    status: currentStatus,
                    isBinary: currentIsBinary,
                    hunks: currentHunks
                )
                fileDiffs.append(fileDiff)
                fileIndex += 1
            }
            currentOldPath = nil
            currentNewPath = nil
            currentStatus = .modified
            currentIsBinary = false
            currentHunks = []
            currentHunkLines = []
            currentHunkHeader = nil
            hunkIndex = 0
            lineIndex = 0
        }

        for line in lines {
            // New file diff
            if line.hasPrefix("diff --git ") {
                finalizeFile()
                let parts = line.components(separatedBy: " ")
                if parts.count >= 4 {
                    currentOldPath = String(parts[2].dropFirst(2)) // remove a/
                    currentNewPath = String(parts[3].dropFirst(2)) // remove b/
                }
                continue
            }

            // Extended headers
            if line.hasPrefix("new file mode") {
                currentStatus = .added
                continue
            }
            if line.hasPrefix("deleted file mode") {
                currentStatus = .deleted
                continue
            }
            if line.hasPrefix("rename from ") {
                currentStatus = .renamed
                currentOldPath = String(line.dropFirst("rename from ".count))
                continue
            }
            if line.hasPrefix("rename to ") {
                currentNewPath = String(line.dropFirst("rename to ".count))
                continue
            }
            if line.hasPrefix("similarity index") || line.hasPrefix("dissimilarity index") {
                continue
            }
            if line.hasPrefix("index ") || line.hasPrefix("old mode") || line.hasPrefix("new mode") {
                continue
            }
            if line.contains("Binary files") {
                currentIsBinary = true
                currentStatus = .binary
                continue
            }

            // --- / +++ headers
            if line.hasPrefix("--- ") {
                if line == "--- /dev/null" {
                    currentStatus = .added
                }
                continue
            }
            if line.hasPrefix("+++ ") {
                if line == "+++ /dev/null" {
                    currentStatus = .deleted
                }
                continue
            }

            // Hunk header
            if let match = line.wholeMatch(of: hunkHeaderPattern) {
                finalizeHunk()
                hunkOldStart = Int(match.1) ?? 0
                hunkOldCount = Int(match.2 ?? "1") ?? 1
                hunkNewStart = Int(match.3) ?? 0
                hunkNewCount = Int(match.4 ?? "1") ?? 1
                currentHunkHeader = line
                currentOld = hunkOldStart
                currentNew = hunkNewStart
                lineIndex = 0
                continue
            }

            // No newline marker
            if line == "\\ No newline at end of file" {
                if let lastIndex = currentHunkLines.indices.last {
                    let lastLine = currentHunkLines[lastIndex]
                    currentHunkLines[lastIndex] = DiffLine(
                        id: lastLine.id,
                        type: lastLine.type,
                        content: lastLine.content,
                        oldLineNumber: lastLine.oldLineNumber,
                        newLineNumber: lastLine.newLineNumber,
                        noNewlineAtEnd: true
                    )
                }
                continue
            }

            // Content lines (only if we're inside a hunk)
            guard currentHunkHeader != nil else { continue }

            if line.hasPrefix("+") {
                let content = String(line.dropFirst())
                let diffLine = DiffLine(
                    id: "line-\(fileIndex)-\(hunkIndex)-\(lineIndex)",
                    type: .addition,
                    content: content,
                    oldLineNumber: nil,
                    newLineNumber: currentNew,
                    noNewlineAtEnd: false
                )
                currentHunkLines.append(diffLine)
                currentNew += 1
                lineIndex += 1
            } else if line.hasPrefix("-") {
                let content = String(line.dropFirst())
                let diffLine = DiffLine(
                    id: "line-\(fileIndex)-\(hunkIndex)-\(lineIndex)",
                    type: .deletion,
                    content: content,
                    oldLineNumber: currentOld,
                    newLineNumber: nil,
                    noNewlineAtEnd: false
                )
                currentHunkLines.append(diffLine)
                currentOld += 1
                lineIndex += 1
            } else {
                // Context line (starts with space or is empty within a hunk)
                let content = line.hasPrefix(" ") ? String(line.dropFirst()) : line
                let diffLine = DiffLine(
                    id: "line-\(fileIndex)-\(hunkIndex)-\(lineIndex)",
                    type: .context,
                    content: content,
                    oldLineNumber: currentOld,
                    newLineNumber: currentNew,
                    noNewlineAtEnd: false
                )
                currentHunkLines.append(diffLine)
                currentOld += 1
                currentNew += 1
                lineIndex += 1
            }
        }

        // Finalize last file
        finalizeFile()

        return fileDiffs
    }
}
