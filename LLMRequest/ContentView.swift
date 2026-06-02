//
//  ContentView.swift
//  LLMRequest
//
//  Created by Igor Pogiba-Vishnevskiy on 01.06.2026.
//

import SwiftUI

struct ContentView: View {
    
    @State private var prompt = "Объясни простыми словами, что такое LLM"
    @State private var answer = ""
    @State private var isProxyLoading = false
    @State private var isDeepSeekLoading = false
    
    var body: some View {
        VStack(spacing: 16) {
            TextEditor(text: $prompt)
                .frame(height: 140)
                .padding(8)
                .background(.gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(spacing: 8) {
                Button {
                    Task {
                        await sendProxyRequest()
                    }
                } label: {
                    buttonTitle("Запрос в Proxy", isLoading: isProxyLoading)
                }
                .buttonStyle(.borderedProminent)
                .disabled(prompt.isEmpty || isProxyLoading)
                
                Button {
                    Task {
                        await sendDeepSeekRequest()
                    }
                } label: {
                    buttonTitle("Запрос в DeepSeek", isLoading: isDeepSeekLoading)
                }
                .buttonStyle(.bordered)
                .disabled(prompt.isEmpty || isDeepSeekLoading)
            }
            
            ScrollView {
                Text(answer)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
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
    
    @ViewBuilder
    private func buttonTitle(_ title: String, isLoading: Bool) -> some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else {
            Text(title)
                .frame(maxWidth: .infinity)
        }
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
