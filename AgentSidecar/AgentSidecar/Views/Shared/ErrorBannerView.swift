import SwiftUI

struct ErrorBannerView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("Error")
                .font(DSFont.heading)

            Text(message)
                .font(DSFont.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)

            DSButton("Retry", action: onRetry)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
