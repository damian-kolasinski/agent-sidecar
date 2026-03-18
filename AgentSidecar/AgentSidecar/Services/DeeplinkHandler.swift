import Foundation

enum DeeplinkAction {
    case openDiff(DeeplinkPayload)
    case openPlan(filePath: String)
}

enum DeeplinkHandler {
    static func parse(url: URL) -> DeeplinkAction? {
        guard url.scheme == "agentsidecar" else { return nil }

        switch url.host {
        case "open":
            return parseDiffDeeplink(url: url).map { .openDiff($0) }
        case "plan":
            return parsePlanDeeplink(url: url).map { .openPlan(filePath: $0) }
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
}
