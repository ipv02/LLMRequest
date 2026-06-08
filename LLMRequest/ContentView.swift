//
//  ContentView.swift
//  LLMRequest
//
//  Created by Igor Pogiba-Vishnevskiy on 01.06.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ModelRequestsView()
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }

            MyAgentView()
                .tabItem {
                    Label("My Agent", systemImage: "person.crop.circle.badge.checkmark")
                }
        }
    }
}
