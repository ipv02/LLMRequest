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
            let result = try await LLMService.shared.requestLLM(prompt: prompt)
            answer = result
        } catch {
            answer = "Ошибка: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
