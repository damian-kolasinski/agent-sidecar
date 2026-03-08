import SwiftUI

@MainActor
final class DiffListViewModel: ObservableObject {
    @Published var searchText = ""

    func filteredFiles(_ files: [FileDiff]) -> [FileDiff] {
        guard !searchText.isEmpty else { return files }
        let query = searchText.lowercased()
        return files.filter { $0.displayPath.lowercased().contains(query) }
    }
}
