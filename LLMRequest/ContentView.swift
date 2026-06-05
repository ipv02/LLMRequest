//
//  ContentView.swift
//  LLMRequest
//
//  Created by Igor Pogiba-Vishnevskiy on 01.06.2026.
//

import SwiftUI

struct ContentView: View {
    
    @State private var prompt = "Объясни что такое LLM"
    @State private var answer = ""
    @State private var isProxyLoading = false
    @State private var isDeepSeekLoading = false
    @State private var isReasoningExperimentLoading = false
    @State private var isTemperatureExperimentLoading = false
    @State private var isModelComparisonLoading = false
    
    @FocusState private var isPromptFocused: Bool
    
    private var isRequestRunning: Bool {
        isProxyLoading || isDeepSeekLoading || isReasoningExperimentLoading || isTemperatureExperimentLoading || isModelComparisonLoading
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemGroupedBackground),
                        Color(.secondarySystemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerView
                        promptCard
                        actionButtons
                        answerCard
                    }
                    .padding(20)
                    .background {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                hideKeyboard()
                            }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("LLM Request")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Запрос в LLM")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
            
//            Text("Сравните обычный запрос, controlled-ответ, DeepSeek или четыре стратегии решения одной задачи.")
//                .font(.callout)
//                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Prompt", systemImage: "text.bubble")
                .font(.headline)
                .foregroundStyle(.primary)
            
            TextEditor(text: $prompt)
                .focused($isPromptFocused)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 132)
                .padding(12)
                .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 1)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            requestButton(
                title: "Запрос в Proxy",
                subtitle: "Обычный + controlled",
                systemImage: "bolt.fill",
                color: .blue,
                isLoading: isProxyLoading
            ) {
                hideKeyboard()
                Task {
                    await sendProxyRequest()
                }
            }
            
            requestButton(
                title: "Запрос в DeepSeek",
                subtitle: "Один обычный ответ",
                systemImage: "sparkles",
                color: .purple,
                isLoading: isDeepSeekLoading
            ) {
                hideKeyboard()
                Task {
                    await sendDeepSeekRequest()
                }
            }
            
            requestButton(
                title: "4 способа решения",
                subtitle: "Прямой, пошаговый, meta-prompt, эксперты",
                systemImage: "person.3.sequence.fill",
                color: .green,
                isLoading: isReasoningExperimentLoading
            ) {
                hideKeyboard()
                Task {
                    await sendReasoningExperimentRequest()
                }
            }
            
            requestButton(
                title: "Температура",
                subtitle: "DeepSeek: 0, 0.7, 1.2",
                systemImage: "thermometer.variable",
                color: .orange,
                isLoading: isTemperatureExperimentLoading
            ) {
                hideKeyboard()
                Task {
                    await sendTemperatureExperimentRequest()
                }
            }
            
            requestButton(
                title: "Модели HF",
                subtitle: "Qwen 4B, 7B, 72B",
                systemImage: "chart.bar.xaxis",
                color: .teal,
                isLoading: isModelComparisonLoading
            ) {
                hideKeyboard()
                Task {
                    await sendModelComparisonRequest()
                }
            }
        }
    }
    
    private var answerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Label("Ответ", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if isRequestRunning {
                    Text("Выполняется")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.blue.opacity(0.12), in: Capsule())
                        .foregroundStyle(.blue)
                }
            }
            
            Text(.init(answer.isEmpty ? "Здесь появится ответ модели." : answer))
                .font(.body)
                .foregroundStyle(answer.isEmpty ? .secondary : .primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func requestButton(
        title: String,
        subtitle: String,
        systemImage: String,
        color: Color,
        isLoading: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 38, height: 38)
                    
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: systemImage)
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .opacity(0.82)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .opacity(isLoading ? 0 : 0.9)
            }
            .foregroundStyle(.white)
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 68)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: color.opacity(0.25), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        .opacity(isLoading ? 0.82 : 1)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
    
    private func hideKeyboard() {
        isPromptFocused = false
    }
    
    private func sendProxyRequest() async {
        isProxyLoading = true
        answer = ""
        
        do {
            async let unrestrictedAnswer = LLMService.shared.requestLLM(prompt: prompt)
            async let controlledAnswer = LLMService.shared.requestControlledLLM(prompt: prompt)
            
            let result = try await formatComparison(
                title: "Proxy",
                unrestricted: unrestrictedAnswer,
                controlled: controlledAnswer
            )
            answer = result
        } catch {
            answer = "Ошибка: \(error.localizedDescription)"
        }
        
        isProxyLoading = false
    }
    
    private func sendDeepSeekRequest() async {
        isDeepSeekLoading = true
        answer = ""
        
        do {
            let result = try await LLMService.shared.request(
                prompt: prompt,
                provider: .deepSeek
            )
            answer = """
            DeepSeek:
            \(result)
            """
        } catch {
            answer = "Ошибка: \(error.localizedDescription)"
        }
        
        isDeepSeekLoading = false
    }
    
    private func sendReasoningExperimentRequest() async {
        isReasoningExperimentLoading = true
        answer = ""
        
        do {
            answer = try await LLMService.shared.requestReasoningExperiment(prompt: prompt)
        } catch {
            answer = "Ошибка: \(error.localizedDescription)"
        }
        
        isReasoningExperimentLoading = false
    }
    
    private func sendTemperatureExperimentRequest() async {
        isTemperatureExperimentLoading = true
        answer = ""
        
        do {
            answer = try await LLMService.shared.requestTemperatureExperiment(prompt: prompt)
        } catch {
            answer = "Ошибка: \(error.localizedDescription)"
        }
        
        isTemperatureExperimentLoading = false
    }
    
    private func sendModelComparisonRequest() async {
        isModelComparisonLoading = true
        answer = ""
        
        do {
            answer = try await LLMService.shared.requestHuggingFaceModelComparisonExperiment(prompt: prompt)
        } catch {
            answer = "Ошибка: \(error.localizedDescription)"
        }
        
        isModelComparisonLoading = false
    }
    
    private func formatComparison(
        title: String,
        unrestricted: String,
        controlled: String
    ) -> String {
        """
        \(title)
        
        Без ограничений:
        \(unrestricted)
        
        С ограничениями:
        \(controlled)
        """
    }
}
