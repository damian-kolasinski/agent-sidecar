import Foundation

enum DeeplinkHandler {
    static func parse(url: URL) -> DeeplinkPayload? {
        guard url.scheme == "agentsidecar",
              url.host == "open" else {
            return nil
        }

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
