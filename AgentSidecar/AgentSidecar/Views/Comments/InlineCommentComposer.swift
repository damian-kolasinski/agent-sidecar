import SwiftUI

struct InlineCommentComposer: View {
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            TextEditor(text: $text)
                .font(DSFont.body)
                .frame(minHeight: DSSpacing.composerMinHeight, maxHeight: 120)
                .padding(DSSpacing.xs)
                .background(DSColor.composerBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                )
                .focused($isFocused)

            HStack {
                Spacer()
                DSButton("Cancel", variant: .secondary) {
                    onCancel()
                }
                DSButton("Comment") {
                    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    onSubmit(text.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
        .padding(DSSpacing.commentPadding)
        .padding(.leading, DSSpacing.gutterWidth * 2)
        .background(DSColor.commentBackground)
        .onAppear {
            isFocused = true
        }
    }
}
