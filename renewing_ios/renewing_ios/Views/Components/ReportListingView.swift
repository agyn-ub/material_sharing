import SwiftUI

struct ReportListingView: View {
    let listingId: String
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason = .prohibitedContent
    @State private var comment = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Причина жалобы") {
                    Picker("Причина", selection: $selectedReason) {
                        ForEach(ReportReason.allCases, id: \.self) { reason in
                            Text(reason.label).tag(reason)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Комментарий (необязательно)") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Пожаловаться")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Отправить") { submitReport() }
                        .disabled(isSubmitting)
                }
            }
            .alert("Жалоба отправлена", isPresented: $showConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("Спасибо за обращение. Мы рассмотрим вашу жалобу.")
            }
        }
    }

    private func submitReport() {
        isSubmitting = true
        Task {
            do {
                try await APIService.shared.reportListing(
                    listingId: listingId,
                    reason: selectedReason.rawValue,
                    comment: comment.isEmpty ? nil : comment
                )
                showConfirmation = true
            } catch {
                isSubmitting = false
            }
        }
    }
}

enum ReportReason: String, CaseIterable {
    case prohibitedContent = "prohibited_content"
    case fraud = "fraud"
    case offensive = "offensive"
    case spam = "spam"
    case other = "other"

    var label: String {
        switch self {
        case .prohibitedContent: return "Запрещённый контент"
        case .fraud: return "Мошенничество"
        case .offensive: return "Оскорбительное содержание"
        case .spam: return "Спам"
        case .other: return "Другое"
        }
    }
}
