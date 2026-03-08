import Foundation

actor GitService {
    let repoPath: String

    init(repoPath: String) {
        self.repoPath = repoPath
    }

    func diff(scope: DiffScope, baseBranch: String = "main") async throws -> String {
        let args = ["git"] + scope.gitArguments(baseBranch: baseBranch)
        let output = try await ProcessRunner.run(arguments: args, workingDirectory: repoPath)
        if output.exitCode != 0 {
            throw ProcessRunnerError.nonZeroExit(exitCode: output.exitCode, stderr: output.stderr)
        }
        return output.stdout
    }

    func changedFiles(scope: DiffScope, baseBranch: String = "main") async throws -> [String] {
        let args = ["git"] + scope.gitFileArguments(baseBranch: baseBranch)
        let output = try await ProcessRunner.run(arguments: args, workingDirectory: repoPath)
        if output.exitCode != 0 {
            throw ProcessRunnerError.nonZeroExit(exitCode: output.exitCode, stderr: output.stderr)
        }
        return output.stdout
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    func validateRepository() async throws -> Bool {
        let output = try await ProcessRunner.run(
            arguments: ["git", "rev-parse", "--is-inside-work-tree"],
            workingDirectory: repoPath
        )
        return output.exitCode == 0 && output.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
    }

    func fetchRemoteBranch(_ branch: String) async -> String? {
        let output = try? await ProcessRunner.run(
            arguments: ["git", "fetch", "origin", branch],
            workingDirectory: repoPath
        )
        if let output, output.exitCode != 0 {
            return "Failed to fetch origin/\(branch): \(output.stderr)"
        }
        return nil
    }

    func currentBranch() async throws -> String {
        let output = try await ProcessRunner.run(
            arguments: ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            workingDirectory: repoPath
        )
        if output.exitCode != 0 {
            throw ProcessRunnerError.nonZeroExit(exitCode: output.exitCode, stderr: output.stderr)
        }
        return output.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
