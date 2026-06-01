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
    @State private var isLoading = false
    
    private let apiKey = "ТВОЙ_PROXY_API_KEY"
    
    var body: some View {
        VStack(spacing: 16) {
            TextEditor(text: $prompt)
                .frame(height: 140)
                .padding(8)
                .background(.gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button {
                Task {
                    await sendRequest()
                }
            } label: {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Отправить")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(prompt.isEmpty || isLoading)
            
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
    
    private func sendRequest() async {
        isLoading = true
        answer = ""
        
        do {
            let result = try await requestLLM(prompt: prompt)
            answer = result
        } catch {
            answer = "Ошибка: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func requestLLM(prompt: String) async throws -> String {
        let url = URL(string: "https://openai.api.proxyapi.ru/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "openai/gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = message?["content"] as? String
        
        return content ?? String(data: data, encoding: .utf8) ?? "Нет ответа"
    }
}
