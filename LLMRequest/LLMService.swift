//
//  LLMService.swift
//  LLMRequest
//
//  Created by Igor Pogiba-Vishnevskiy on 01.06.2026.
//

import Foundation

final class LLMService {
    static let shared = LLMService()

    private let apiKey = "ТВОЙ_PROXY_API_KEY"

    private let url = URL(string: "https://openai.api.proxyapi.ru/v1/chat/completions")!
    private let model = "openai/gpt-4o"
    private let stopSequence = "###END###"

    private init() {}

    func requestLLM(prompt: String) async throws -> String {
        let messages = [
            message(role: "user", content: prompt)
        ]

        return try await performRequest(messages: messages)
    }

    func requestControlledLLM(prompt: String) async throws -> String {
        let systemPrompt = """
        Отвечай строго по правилам:
        1. Формат ответа: ровно 3 коротких пункта списком.
        2. Длина ответа: не больше 80 слов.
        3. После третьего пункта напиши \(stopSequence).
        """

        let messages = [
            message(role: "system", content: systemPrompt),
            message(role: "user", content: prompt)
        ]

        return try await performRequest(
            messages: messages,
            maxTokens: 160,
            stop: [stopSequence]
        )
    }

    private func performRequest(
        messages: [[String: String]],
        maxTokens: Int? = nil,
        stop: [String]? = nil
    ) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "model": model,
            "messages": messages
        ]

        if let maxTokens {
            body["max_tokens"] = maxTokens
        }

        if let stop {
            body["stop"] = stop
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = message?["content"] as? String

        return content ?? String(data: data, encoding: .utf8) ?? "Нет ответа"
    }

    private func message(role: String, content: String) -> [String: String] {
        [
            "role": role,
            "content": content
        ]
    }
}
