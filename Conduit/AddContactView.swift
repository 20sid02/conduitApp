//
//  AddContactView.swift
//  Conduit
//

import SwiftUI
import SwiftData

struct AddContactView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let client: Client

    @State private var name = ""
    @State private var role = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var supportPortal = ""
    @State private var accountNotes = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ConduitBackground {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ConduitTheme.secondary)
                    Spacer()
                    Text("New Contact")
                        .font(.headline)
                        .foregroundStyle(ConduitTheme.primary)
                    Spacer()
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? ConduitTheme.accent : ConduitTheme.muted)
                        .disabled(!canSave)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        GlassCard {
                            VStack(spacing: 0) {
                                EditableRow(title: "Name") {
                                    styledField("Full Name", text: $name)
                                        .autocorrectionDisabled()
                                }
                                DividerLine()
                                EditableRow(title: "Role") {
                                    styledField("e.g. On-Call, Support", text: $role)
                                        .autocorrectionDisabled()
                                }
                            }
                        }

                        GlassCard {
                            VStack(spacing: 0) {
                                EditableRow(title: "Phone") {
                                    styledField("+1 555 000 0000", text: $phone)
                                        .keyboardType(.phonePad)
                                }
                                DividerLine()
                                EditableRow(title: "Email") {
                                    styledField("contact@example.com", text: $email)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                }
                                DividerLine()
                                EditableRow(title: "Support Portal") {
                                    styledField("https://support.example.com", text: $supportPortal)
                                        .keyboardType(.URL)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                }
                            }
                        }

                        GlassCard(padding: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Account Notes")
                                    .foregroundStyle(ConduitTheme.primary)
                                    .font(.body)
                                TextEditor(text: $accountNotes)
                                    .frame(minHeight: 80)
                                    .foregroundStyle(ConduitTheme.secondary)
                                    .scrollContentBackground(.hidden)
                                    .tint(ConduitTheme.accent)
                                    .font(.body.weight(.semibold))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
                .keyboardDismissControls()
            }
        }
    }

    private func styledField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(ConduitTheme.secondary)
            .fontWeight(.semibold)
            .tint(ConduitTheme.accent)
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let contact = ContactEntry(
            client: client,
            name: trimmedName,
            role: nilIfEmpty(role),
            phone: nilIfEmpty(phone),
            email: nilIfEmpty(email),
            supportPortal: nilIfEmpty(supportPortal),
            accountNotes: nilIfEmpty(accountNotes),
            sortOrder: client.contacts?.count ?? 0
        )
        modelContext.insert(contact)
        client.contacts.append(contact)
        dismiss()
    }

    private func nilIfEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
