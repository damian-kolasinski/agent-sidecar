import SwiftUI

struct ScopePickerView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        Picker("Scope", selection: Binding(
            get: { appViewModel.scope },
            set: { appViewModel.changeScope($0) }
        )) {
            ForEach(DiffScope.allCases) { scope in
                Text(scope.displayName).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}
