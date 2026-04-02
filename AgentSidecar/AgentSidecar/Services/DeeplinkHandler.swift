import Foundation

enum DeeplinkAction {
    case openDiff(DeeplinkPayload)
    case openPlan(filePath: String)
    case openFileReview(FileReviewPayload)
}

enum DeeplinkHandler {
    static func parse(url: URL) -> DeeplinkAction? {
        guard url.scheme == "agentsidecar" else { return nil }

        switch url.host {
        case "open":
            return parseDiffDeeplink(url: url).map { .openDiff($0) }
        case "plan":
            return parsePlanDeeplink(url: url).map { .openPlan(filePath: $0) }
        case "file":
            return parseFileReviewDeeplink(url: url).map { .openFileReview($0) }
        default:
            return nil
        }
    }

    private static func parseDiffDeeplink(url: URL) -> DeeplinkPayload? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }

        guard let repoPath = queryItems.first(where: { $0.name == "repo" })?.value,
              !repoPath.isEmpty else {
            return nil
        }

        let scopeString = queryItems.first(where: { $0.name == "scope" })?.value
        let scope = scopeString.flatMap { DiffScope(rawValue: $0) }
        let baseBranch = queryItems.first(where: { $0.name == "base" })?.value
        let bundlePath = queryItems.first(where: { $0.name == "bundle" })?.value

        return DeeplinkPayload(
            repoPath: repoPath,
            scope: scope,
            baseBranch: baseBranch,
            bundlePath: bundlePath
        )
    }

    private static func parsePlanDeeplink(url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let filePath = queryItems.first(where: { $0.name == "file" })?.value,
              !filePath.isEmpty else {
            return nil
        }
        return filePath
    }

    private static func parseFileReviewDeeplink(url: URL) -> FileReviewPayload? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let filePath = queryItems.first(where: { $0.name == "file" })?.value,
              !filePath.isEmpty else {
            return nil
        }

        let reviewPath = queryItems.first(where: { $0.name == "review" })?.value
        let title = queryItems.first(where: { $0.name == "title" })?.value

        return FileReviewPayload(
            filePath: filePath,
            reviewPath: reviewPath,
            title: title
        )
    }

    static func buildURL(
        repoPath: String,
        scope: DiffScope = .workingTree,
        baseBranch: String? = nil,
        bundlePath: String? = nil
    ) -> URL? {
        var components = URLComponents()
        components.scheme = "agentsidecar"
        components.host = "open"
        var queryItems = [
            URLQueryItem(name: "repo", value: repoPath),
            URLQueryItem(name: "scope", value: scope.rawValue),
        ]
        if let baseBranch {
            queryItems.append(URLQueryItem(name: "base", value: baseBranch))
        }
        if let bundlePath {
            queryItems.append(URLQueryItem(name: "bundle", value: bundlePath))
        }
        components.queryItems = queryItems
        return components.url
    }

    static func buildFileReviewURL(
        filePath: String,
        reviewPath: String? = nil,
        title: String? = nil
    ) -> URL? {
        var components = URLComponents()
        components.scheme = "agentsidecar"
        components.host = "file"
        var queryItems = [
            URLQueryItem(name: "file", value: filePath),
        ]
        if let reviewPath {
            queryItems.append(URLQueryItem(name: "review", value: reviewPath))
        }
        if let title {
            queryItems.append(URLQueryItem(name: "title", value: title))
        }
        components.queryItems = queryItems
        return components.url
    }
}
