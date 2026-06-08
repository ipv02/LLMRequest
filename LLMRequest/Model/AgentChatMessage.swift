//
//  AgentChatMessage.swift
//  LLMRequest
//
//  Created by Igor Pogiba-Vishnevskiy on 08.06.2026.
//

import Foundation

struct AgentChatMessage: Identifiable {
    
    enum Role {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
}
