//
//  MyAgentView.swift
//  LLMRequest
//
//  Created by Igor Pogiba-Vishnevskiy on 08.06.2026.
//

import SwiftUI

struct MyAgentView: View {
    @State private var input = "Объясни, чем отличается struct от class в Swift, и приведи короткий пример"
    @State private var messages: [AgentChatMessage] = [
        AgentChatMessage(
            role: .assistant,
            text: "Я code assistant. Могу объяснять код, помогать с архитектурой, искать ошибки и предлагать исправления."
        )
    ]
    @State private var isLoading = false

    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                appBackground
                    .onTapGesture {
                        hideKeyboard()
                    }

                VStack(spacing: 12) {
                    chatHeader
                    messagesList
                    inputBar
                }
                .padding(16)
            }
            .navigationTitle("My Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        resetChat()
                    }
                    .disabled(isLoading)
                }
            }
        }
    }

    private var appBackground: some View {
        LinearGradient(
            colors: [
                Color(.systemGroupedBackground),
                Color(.secondarySystemGroupedBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var chatHeader: some View {
        Label("Code Assistant", systemImage: "chevron.left.forwardslash.chevron.right")
            .font(.title2.bold())
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            }
    }

    private var messagesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(messages) { message in
                    AgentMessageBubble(message: message)
                }

                if isLoading {
                    HStack {
                        ProgressView()
                        Text("Агент думает")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(14)
                    .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 1)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var inputBar: some View {
        VStack(spacing: 10) {
            TextEditor(text: $input)
                .focused($isInputFocused)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 76, maxHeight: 120)
                .padding(10)
                .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                }

            Button {
                hideKeyboard()
                Task {
                    await sendAgentMessage()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }

                    Text("Отправить агенту")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(.indigo.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            .opacity(isLoading ? 0.82 : 1)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 1)
        }
    }

    private func hideKeyboard() {
        isInputFocused = false
    }

    private func sendAgentMessage() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        input = ""
        isLoading = true
        messages.append(AgentChatMessage(role: .user, text: text))

        do {
            let answer = try await MyAgentService.shared.sendMessage(text)
            messages.append(AgentChatMessage(role: .assistant, text: answer))
        } catch {
            messages.append(AgentChatMessage(role: .assistant, text: "Ошибка: \(error.localizedDescription)"))
        }

        isLoading = false
    }

    private func resetChat() {
        MyAgentService.shared.resetHistory()
        messages = [
            AgentChatMessage(
                role: .assistant,
                text: "История очищена. Я снова готов помогать с кодом."
            )
        ]
    }
}
