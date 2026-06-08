//
//  AgentMessageBubbleView.swift
//  LLMRequest
//
//  Created by Igor Pogiba-Vishnevskiy on 08.06.2026.
//

import SwiftUI

struct AgentMessageBubble: View {
    let message: AgentChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 36)
            }

            Text(.init(message.text))
                .font(.body)
                .foregroundStyle(message.role == .user ? .white : .primary)
                .textSelection(.enabled)
                .padding(14)
                .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if message.role == .assistant {
                Spacer(minLength: 36)
            }
        }
    }

    private var backgroundStyle: some ShapeStyle {
        message.role == .user ? AnyShapeStyle(Color.indigo.gradient) : AnyShapeStyle(Color(.secondarySystemGroupedBackground))
    }
}
