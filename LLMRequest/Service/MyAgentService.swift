//
//  MyAgentService.swift
//  LLMRequest
//
//  Created by Igor Pogiba-Vishnevskiy on 01.06.2026.
//

import Foundation

@MainActor
final class MyAgentService {
    static let shared = MyAgentService()

    private let apiKey = "DEEPSEEK_API_KEY"
    private let url = URL(string: "https://api.deepseek.com/chat/completions")!
    private let model = "deepseek-v4-flash"
    private let maxHistoryMessages = 20

    private let systemPrompt = """
    Ты code assistant. Помогай пользователю писать, объяснять, улучшать и отлаживать код.
    Отвечай практично, кратко и структурированно.
    Если пользователь просит исправить код, объясни проблему и дай исправленный вариант.
    Если данных недостаточно, задай уточняющий вопрос.
    """

    private var messages: [[String: String]]

    private init() {
        messages = [
            [
                "role": "system",
                "content": systemPrompt
            ]
        ]
    }

    // MARK: - Agent Request

    func sendMessage(_ text: String) async throws -> String {
        let userMessage = message(role: "user", content: text)
        messages.append(userMessage)
        trimHistoryIfNeeded()

        do {
            let answer = try await performRequest(messages: messages)
            messages.append(message(role: "assistant", content: answer))
            trimHistoryIfNeeded()
            return answer
        } catch {
            messages.removeAll { $0 == userMessage }
            throw error
        }
    }

    func resetHistory() {
        messages = [
            [
                "role": "system",
                "content": systemPrompt
            ]
        ]
    }
}

private extension MyAgentService {
    // MARK: - Network Request

    func performRequest(messages: [[String: String]]) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.2
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            return String(data: data, encoding: .utf8) ?? "Ошибка API"
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = message?["content"] as? String

        return content ?? String(data: data, encoding: .utf8) ?? "Нет ответа"
    }

    // MARK: - History

    func trimHistoryIfNeeded() {
        guard messages.count > maxHistoryMessages + 1 else { return }

        let systemMessage = messages[0]
        let recentMessages = messages.suffix(maxHistoryMessages)
        messages = [systemMessage] + recentMessages
    }

    func message(role: String, content: String) -> [String: String] {
        [
            "role": role,
            "content": content
        ]
    }
}
