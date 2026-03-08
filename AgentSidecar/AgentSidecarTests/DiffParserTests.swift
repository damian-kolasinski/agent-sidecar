import Testing
@testable import AgentSidecar

@Suite("DiffParser Tests")
struct DiffParserTests {

    @Test("Parse simple modification diff")
    func parseSimpleModification() {
        let rawDiff = """
        diff --git a/Sources/main.swift b/Sources/main.swift
        index abc1234..def5678 100644
        --- a/Sources/main.swift
        +++ b/Sources/main.swift
        @@ -1,5 +1,5 @@
         import Foundation

        -let greeting = "Hello"
        +let greeting = "Hello, World!"

         print(greeting)
        """

        let files = DiffParser.parse(rawDiff)
        #expect(files.count == 1)

        let file = files[0]
        #expect(file.oldPath == "Sources/main.swift")
        #expect(file.newPath == "Sources/main.swift")
        #expect(file.status == .modified)
        #expect(file.isBinary == false)
        #expect(file.hunks.count == 1)

        let hunk = file.hunks[0]
        #expect(hunk.oldStart == 1)
        #expect(hunk.oldCount == 5)
        #expect(hunk.newStart == 1)
        #expect(hunk.newCount == 5)
        #expect(hunk.lines.count == 6)

        // Check line types
        #expect(hunk.lines[0].type == .context)  // import Foundation
        #expect(hunk.lines[1].type == .context)  // empty line
        #expect(hunk.lines[2].type == .deletion) // -let greeting = "Hello"
        #expect(hunk.lines[3].type == .addition) // +let greeting = "Hello, World!"
        #expect(hunk.lines[4].type == .context)  // empty line
        #expect(hunk.lines[5].type == .context)  // print(greeting)
    }

    @Test("Parse new file diff")
    func parseNewFile() {
        let rawDiff = """
        diff --git a/new_file.swift b/new_file.swift
        new file mode 100644
        index 0000000..abc1234
        --- /dev/null
        +++ b/new_file.swift
        @@ -0,0 +1,3 @@
        +import Foundation
        +
        +print("New file")
        """

        let files = DiffParser.parse(rawDiff)
        #expect(files.count == 1)
        #expect(files[0].status == .added)
        #expect(files[0].hunks[0].lines.count == 3)
        #expect(files[0].hunks[0].lines.allSatisfy { $0.type == .addition })
    }

    @Test("Parse deleted file diff")
    func parseDeletedFile() {
        let rawDiff = """
        diff --git a/old_file.swift b/old_file.swift
        deleted file mode 100644
        index abc1234..0000000
        --- a/old_file.swift
        +++ /dev/null
        @@ -1,2 +0,0 @@
        -import Foundation
        -print("Gone")
        """

        let files = DiffParser.parse(rawDiff)
        #expect(files.count == 1)
        #expect(files[0].status == .deleted)
        #expect(files[0].hunks[0].lines.count == 2)
        #expect(files[0].hunks[0].lines.allSatisfy { $0.type == .deletion })
    }

    @Test("Parse multiple files")
    func parseMultipleFiles() {
        let rawDiff = """
        diff --git a/file1.swift b/file1.swift
        index abc1234..def5678 100644
        --- a/file1.swift
        +++ b/file1.swift
        @@ -1,3 +1,3 @@
         line1
        -line2
        +line2_modified
         line3
        diff --git a/file2.swift b/file2.swift
        new file mode 100644
        index 0000000..abc1234
        --- /dev/null
        +++ b/file2.swift
        @@ -0,0 +1 @@
        +new content
        """

        let files = DiffParser.parse(rawDiff)
        #expect(files.count == 2)
        #expect(files[0].newPath == "file1.swift")
        #expect(files[1].newPath == "file2.swift")
        #expect(files[1].status == .added)
    }

    @Test("Parse rename diff")
    func parseRename() {
        let rawDiff = """
        diff --git a/old_name.swift b/new_name.swift
        similarity index 100%
        rename from old_name.swift
        rename to new_name.swift
        """

        let files = DiffParser.parse(rawDiff)
        #expect(files.count == 1)
        #expect(files[0].status == .renamed)
        #expect(files[0].oldPath == "old_name.swift")
        #expect(files[0].newPath == "new_name.swift")
    }

    @Test("Parse binary file")
    func parseBinaryFile() {
        let rawDiff = """
        diff --git a/image.png b/image.png
        index abc1234..def5678 100644
        Binary files a/image.png and b/image.png differ
        """

        let files = DiffParser.parse(rawDiff)
        #expect(files.count == 1)
        #expect(files[0].isBinary == true)
    }

    @Test("Line numbers are correct")
    func lineNumberTracking() {
        let rawDiff = """
        diff --git a/test.swift b/test.swift
        index abc1234..def5678 100644
        --- a/test.swift
        +++ b/test.swift
        @@ -10,4 +10,5 @@
         context
        -old line
        +new line 1
        +new line 2
         context end
        """

        let files = DiffParser.parse(rawDiff)
        let lines = files[0].hunks[0].lines

        // Context: old=10, new=10
        #expect(lines[0].oldLineNumber == 10)
        #expect(lines[0].newLineNumber == 10)

        // Deletion: old=11, new=nil
        #expect(lines[1].oldLineNumber == 11)
        #expect(lines[1].newLineNumber == nil)

        // Addition: old=nil, new=11
        #expect(lines[2].oldLineNumber == nil)
        #expect(lines[2].newLineNumber == 11)

        // Addition: old=nil, new=12
        #expect(lines[3].oldLineNumber == nil)
        #expect(lines[3].newLineNumber == 12)

        // Context: old=12, new=13
        #expect(lines[4].oldLineNumber == 12)
        #expect(lines[4].newLineNumber == 13)
    }

    @Test("Line anchors are stable")
    func lineAnchors() {
        let rawDiff = """
        diff --git a/test.swift b/test.swift
        index abc1234..def5678 100644
        --- a/test.swift
        +++ b/test.swift
        @@ -1,3 +1,3 @@
         context
        -removed
        +added
         end
        """

        let lines = DiffParser.parse(rawDiff)[0].hunks[0].lines
        #expect(lines[0].anchor == "1:1")
        #expect(lines[1].anchor == "2:_")
        #expect(lines[2].anchor == "_:2")
        #expect(lines[3].anchor == "3:3")
    }

    @Test("No newline at end of file marker")
    func noNewlineAtEnd() {
        let rawDiff = """
        diff --git a/test.swift b/test.swift
        index abc1234..def5678 100644
        --- a/test.swift
        +++ b/test.swift
        @@ -1 +1 @@
        -old content
        \\ No newline at end of file
        +new content
        \\ No newline at end of file
        """

        let files = DiffParser.parse(rawDiff)
        let lines = files[0].hunks[0].lines
        #expect(lines[0].noNewlineAtEnd == true)
        #expect(lines[1].noNewlineAtEnd == true)
    }

    @Test("Empty diff returns empty array")
    func emptyDiff() {
        let files = DiffParser.parse("")
        #expect(files.isEmpty)
    }

    @Test("Multiple hunks in one file")
    func multipleHunks() {
        let rawDiff = """
        diff --git a/test.swift b/test.swift
        index abc1234..def5678 100644
        --- a/test.swift
        +++ b/test.swift
        @@ -1,3 +1,3 @@
         line 1
        -line 2
        +line 2 modified
         line 3
        @@ -10,3 +10,3 @@
         line 10
        -line 11
        +line 11 modified
         line 12
        """

        let files = DiffParser.parse(rawDiff)
        #expect(files.count == 1)
        #expect(files[0].hunks.count == 2)
        #expect(files[0].hunks[0].oldStart == 1)
        #expect(files[0].hunks[1].oldStart == 10)
    }
}
