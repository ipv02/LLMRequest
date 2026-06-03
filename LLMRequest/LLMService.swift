//
//  LLMService.swift
//  LLMRequest
//
//  Created by Igor Pogiba-Vishnevskiy on 01.06.2026.
//

import Foundation

extension LLMService {
    
    enum LLMProvider {
        case proxyOpenAI
        case deepSeek
        
        var url: URL {
            switch self {
            case .proxyOpenAI:
                URL(string: "https://openai.api.proxyapi.ru/v1/chat/completions")!
            case .deepSeek:
                URL(string: "https://api.deepseek.com/chat/completions")!
            }
        }
        
        var model: String {
            switch self {
            case .proxyOpenAI:
                "openai/gpt-4o"
            case .deepSeek:
                "deepseek-v4-flash"
            }
        }
    }
}

final class LLMService {
    
    static let shared = LLMService()
    
    private let proxyAPIKey = "PROXY_API_KEY"
    private let deepSeekAPIKey = "DEEPSEEK_API_KEY"
    
    private let stopSequence = "###END###"
    private let defaultProvider: LLMProvider = .proxyOpenAI
    
    private init() {}
    
    func requestLLM(prompt: String) async throws -> String {
        try await request(prompt: prompt, provider: defaultProvider)
    }
    
    func requestControlledLLM(prompt: String) async throws -> String {
        try await requestControlled(prompt: prompt, provider: defaultProvider)
    }
    
    func request(prompt: String, provider: LLMProvider) async throws -> String {
        let messages = [
            message(role: "user", content: prompt)
        ]
        
        return try await performRequest(messages: messages, provider: provider)
    }
    
    func requestControlled(prompt: String, provider: LLMProvider) async throws -> String {
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
            provider: provider,
            maxTokens: 160,
            stop: [stopSequence]
        )
    }
    
    func requestReasoningExperiment(prompt: String) async throws -> String {
        async let directAnswer = requestDirectSolution(prompt: prompt)
        async let stepByStepAnswer = requestStepByStepSolution(prompt: prompt)
        async let expertGroupAnswer = requestExpertGroupSolution(prompt: prompt)
        
        let generatedPrompt = try await requestGeneratedPrompt(for: prompt)
        async let generatedPromptAnswer = request(prompt: generatedPrompt, provider: defaultProvider)
        
        let results = try await ReasoningExperimentResult(
            directAnswer: directAnswer,
            stepByStepAnswer: stepByStepAnswer,
            generatedPrompt: generatedPrompt,
            generatedPromptAnswer: generatedPromptAnswer,
            expertGroupAnswer: expertGroupAnswer
        )
        
        let comparison = try await requestExperimentComparison(prompt: prompt, result: results)
        
        return formatReasoningExperiment(result: results, comparison: comparison)
    }
}

private extension LLMService {
    
    struct ReasoningExperimentResult {
        let directAnswer: String
        let stepByStepAnswer: String
        let generatedPrompt: String
        let generatedPromptAnswer: String
        let expertGroupAnswer: String
    }
    
    func requestDirectSolution(prompt: String) async throws -> String {
        try await request(prompt: prompt, provider: defaultProvider)
    }
    
    func requestStepByStepSolution(prompt: String) async throws -> String {
        let stepPrompt = """
        \(prompt)
        
        Решай пошагово.
        """
        
        return try await request(prompt: stepPrompt, provider: defaultProvider)
    }
    
    func requestGeneratedPrompt(for prompt: String) async throws -> String {
        let promptGenerationTask = """
        Составь один точный промпт для решения задачи ниже.
        Промпт должен помогать получить максимально корректное решение.
        Верни только готовый промпт без пояснений.
        
        Задача:
        \(prompt)
        """
        
        return try await request(prompt: promptGenerationTask, provider: defaultProvider)
    }
    
    func requestExpertGroupSolution(prompt: String) async throws -> String {
        let expertPrompt = """
        Реши задачу через группу экспертов.
        
        Задача:
        \(prompt)
        
        Роли:
        1. Аналитик: выделяет условия и ограничения.
        2. Инженер: предлагает строгое решение.
        3. Критик: проверяет решение на ошибки.
        
        Дай ответ от каждого эксперта и общий финальный вывод.
        """
        
        return try await request(prompt: expertPrompt, provider: defaultProvider)
    }
    
    func requestExperimentComparison(
        prompt: String,
        result: ReasoningExperimentResult
    ) async throws -> String {
        let comparisonPrompt = """
        Сравни четыре решения одной задачи.
        
        Исходная задача:
        \(prompt)
        
        Способ 1. Прямой ответ:
        \(result.directAnswer)
        
        Способ 2. Инструкция «решай пошагово»:
        \(result.stepByStepAnswer)
        
        Способ 3. Сначала сгенерирован промпт, затем использован он:
        Сгенерированный промпт:
        \(result.generatedPrompt)
        
        Ответ:
        \(result.generatedPromptAnswer)
        
        Способ 4. Группа экспертов:
        \(result.expertGroupAnswer)
        
        Сравни:
        1. Отличаются ли ответы.
        2. Какой способ дал наиболее точный результат.
        3. Почему.
        Ответь кратко и структурировано.
        """
        
        return try await performRequest(
            messages: [message(role: "user", content: comparisonPrompt)],
            provider: defaultProvider,
            maxTokens: 700
        )
    }
    
    func formatReasoningExperiment(
        result: ReasoningExperimentResult,
        comparison: String
    ) -> String {
        """
        **Способ 1. Прямой ответ**
        \(result.directAnswer)
        
        **Способ 2. Решай пошагово**
        \(result.stepByStepAnswer)
        
        **Способ 3. Сначала промпт, потом решение**
        **Сгенерированный промпт:**
        \(result.generatedPrompt)
        
        **Ответ:**
        \(result.generatedPromptAnswer)
        
        **Способ 4. Группа экспертов**
        \(result.expertGroupAnswer)
        
        **Сравнение**
        \(comparison)
        """
    }
    
    func performRequest(
        messages: [[String: String]],
        provider: LLMProvider,
        maxTokens: Int? = nil,
        stop: [String]? = nil
    ) async throws -> String {
        
        var request = URLRequest(url: provider.url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey(for: provider))", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "model": provider.model,
            "messages": messages
        ]
        
        if let maxTokens {
            body["max_tokens"] = maxTokens
        }
        
        if let stop {
            body["stop"] = stop
        }
        
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
    
    func apiKey(for provider: LLMProvider) -> String {
        switch provider {
        case .proxyOpenAI: proxyAPIKey
        case .deepSeek: deepSeekAPIKey
        }
    }
    
    func message(role: String, content: String) -> [String: String] {
        [
            "role": role,
            "content": content
        ]
    }
}
