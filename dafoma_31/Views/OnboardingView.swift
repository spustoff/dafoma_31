//
//  OnboardingView.swift
//  PixelAvi Play
//
//  Created by Вячеслав on 8/26/25.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var showingPrivacyPolicy = false
    @State private var animateElements = false

    
    private let totalPages = 4
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(hex: "#0e0e0e")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    HStack {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index <= currentPage ? Color(hex: "#28a809") : Color(hex: "#666666"))
                                .frame(height: 4)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    
                    // Content
                    TabView(selection: $currentPage) {
                        // Page 1: Welcome
                        welcomePage
                            .tag(0)
                        
                        // Page 2: Game Mechanics
                        gameMechanicsPage
                            .tag(1)
                        
                        // Page 3: Focus Utility
                        focusUtilityPage
                            .tag(2)
                        
                        // Page 4: Privacy & Completion
                        privacyPage
                            .tag(3)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentPage)
                    
                    // Navigation buttons
                    HStack {
                        if currentPage > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }
                            .foregroundColor(Color(hex: "#666666"))
                        }
                        
                        Spacer()
                        
                        Button(currentPage == totalPages - 1 ? "Get Started" : "Next") {
                            if currentPage == totalPages - 1 {
                                completeOnboarding()
                            } else {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                        }
                        .foregroundColor(Color(hex: "#28a809"))
                        .font(.system(size: 17, weight: .semibold))
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateElements = true
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
    }
    
    // MARK: - Welcome Page
    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Icon Animation
            ZStack {
                Circle()
                    .fill(Color(hex: "#28a809"))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateElements ? 1.0 : 0.8)
                    .opacity(animateElements ? 1.0 : 0.0)
                
                Image(systemName: "grid.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(animateElements ? 1.0 : 0.5)
            }
            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateElements)
            
            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(Color(hex: "#666666"))
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateElements)
                
                Text("PixelAvi Play")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).delay(0.4), value: animateElements)
                
                Text("A unique puzzle game combined with focus utilities to enhance your productivity and entertainment.")
                    .font(.body)
                    .foregroundColor(Color(hex: "#666666"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).delay(0.6), value: animateElements)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Game Mechanics Page
    private var gameMechanicsPage: some View {
        VStack(spacing: 30) {
            Text("How to Play")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                // Demo Grid
                DemoGridView()
                    .frame(height: 200)
                
                VStack(spacing: 12) {
                    FeatureRow(
                        icon: "target",
                        title: "Match the Pattern",
                        description: "Recreate the target pattern by placing colored tiles on the grid",
                        color: "#28a809"
                    )
                    
                    FeatureRow(
                        icon: "timer",
                        title: "Beat the Clock",
                        description: "Complete puzzles within the time limit for maximum points",
                        color: "#e6053a"
                    )
                    
                    FeatureRow(
                        icon: "wand.and.rays",
                        title: "Use Power-Ups",
                        description: "Strategic power-ups help you solve challenging puzzles",
                        color: "#d17305"
                    )
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Focus Utility Page
    private var focusUtilityPage: some View {
        VStack(spacing: 30) {
            Text("Focus Time")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                // Focus Timer Demo
                ZStack {
                    Circle()
                        .stroke(Color(hex: "#666666"), lineWidth: 8)
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color(hex: "#28a809"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("14:32")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Game Session")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#666666"))
                    }
                }
                
                VStack(spacing: 12) {
                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "Enhanced Focus",
                        description: "Minimize distractions with customizable focus sessions",
                        color: "#28a809"
                    )
                    
                    FeatureRow(
                        icon: "bell",
                        title: "Smart Alerts",
                        description: "Gentle notifications to keep you on track without interruption",
                        color: "#e6053a"
                    )
                    
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Track Progress",
                        description: "Monitor your focus time and build productive habits",
                        color: "#d17305"
                    )
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Privacy Page
    private var privacyPage: some View {
        VStack(spacing: 30) {
            Text("Privacy & Data")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "#28a809"))
                    
                    Text("Your Privacy Matters")
                        .font(.title2)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("All your game data and focus sessions are stored locally on your device. We don't collect, share, or transmit any personal information.")
                        .font(.body)
                        .foregroundColor(Color(hex: "#666666"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                VStack(spacing: 12) {
                    PrivacyFeatureRow(
                        icon: "iphone",
                        title: "Local Storage Only",
                        description: "All data stays on your device"
                    )
                    
                    PrivacyFeatureRow(
                        icon: "wifi.slash",
                        title: "No Internet Required",
                        description: "Play and focus completely offline"
                    )
                    
                    PrivacyFeatureRow(
                        icon: "eye.slash",
                        title: "No Tracking",
                        description: "We don't monitor your usage patterns"
                    )
                }
                
                Button("View Privacy Policy") {
                    showingPrivacyPolicy = true
                }
                .foregroundColor(Color(hex: "#28a809"))
                .padding(.top, 10)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: color))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color(hex: "#666666"))
            }
            
            Spacer()
        }
    }
}

struct PrivacyFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: "#28a809"))
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color(hex: "#666666"))
            }
            
            Spacer()
        }
    }
}

struct DemoGridView: View {
    @StateObject private var gameState = DemoGameState()
    @State private var animationTimer: Timer?
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Target Pattern")
                .font(.caption)
                .foregroundColor(Color(hex: "#666666"))
            
            // Target grid (3x3 for demo)
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { col in
                            Rectangle()
                                .fill(Color(hex: gameState.targetPattern[row][col]))
                                .frame(width: 30, height: 30)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            Text("Your Progress")
                .font(.caption)
                .foregroundColor(Color(hex: "#666666"))
                .padding(.top, 8)
            
            // Current grid
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { col in
                            Rectangle()
                                .fill(Color(hex: gameState.currentPattern[row][col]))
                                .frame(width: 30, height: 30)
                                .cornerRadius(6)
                                .scaleEffect(gameState.animatingTiles.contains("\(row)-\(col)") ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: gameState.animatingTiles)
                        }
                    }
                }
            }
        }
        .onAppear {
            startDemoAnimation()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }
    
    private func startDemoAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            gameState.animateNextTile()
        }
    }
}

class DemoGameState: ObservableObject {
    let targetPattern = [
        ["#28a809", "#e6053a", "#28a809"],
        ["#e6053a", "#d17305", "#e6053a"],
        ["#28a809", "#e6053a", "#28a809"]
    ]
    
    @Published var currentPattern = [
        ["#0e0e0e", "#0e0e0e", "#0e0e0e"],
        ["#0e0e0e", "#0e0e0e", "#0e0e0e"],
        ["#0e0e0e", "#0e0e0e", "#0e0e0e"]
    ]
    
    @Published var animatingTiles: Set<String> = []
    private var currentTileIndex = 0
    
    func animateNextTile() {
        let positions = [(0,0), (0,1), (0,2), (1,0), (1,1), (1,2), (2,0), (2,1), (2,2)]
        
        if currentTileIndex < positions.count {
            let (row, col) = positions[currentTileIndex]
            currentPattern[row][col] = targetPattern[row][col]
            
            let tileKey = "\(row)-\(col)"
            animatingTiles.insert(tileKey)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.animatingTiles.remove(tileKey)
            }
            
            currentTileIndex += 1
        } else {
            // Reset demo
            currentTileIndex = 0
            currentPattern = [
                ["#0e0e0e", "#0e0e0e", "#0e0e0e"],
                ["#0e0e0e", "#0e0e0e", "#0e0e0e"],
                ["#0e0e0e", "#0e0e0e", "#0e0e0e"]
            ]
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Group {
                        privacySection(
                            title: "Data Collection",
                            content: "PixelAvi Play does not collect, store, or transmit any personal data to external servers. All game progress, statistics, and focus session data are stored locally on your device using Core Data."
                        )
                        
                        privacySection(
                            title: "Local Storage",
                            content: "Your game achievements, focus time statistics, and app preferences are saved locally on your device. This data is not accessible to us or any third parties."
                        )
                        
                        privacySection(
                            title: "Notifications",
                            content: "The app may request permission to send local notifications for focus session reminders and completions. These notifications are generated locally and do not involve any external services."
                        )
                        
                        privacySection(
                            title: "No Analytics",
                            content: "We do not use any analytics services, crash reporting tools, or tracking mechanisms. Your usage patterns and behavior within the app remain completely private."
                        )
                        
                        privacySection(
                            title: "Contact",
                            content: "If you have any questions about this privacy policy or the app's data handling, you can contact us through the App Store."
                        )
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    OnboardingView()
}
