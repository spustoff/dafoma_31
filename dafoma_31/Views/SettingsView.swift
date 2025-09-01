//
//  SettingsView.swift
//  PixelAvi Play
//
//  Created by Вячеслав on 8/26/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var userProfile = UserProfile()
    @State private var showingAchievements = false
    @State private var showingStatistics = false
    @State private var showingAbout = false
    @State private var showingDataExport = false
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                profileSection
                
                // Game Settings
                gameSettingsSection
                
                // Appearance
                appearanceSection
                
                // Notifications & Sounds
                notificationsSection
                
                // Progress & Achievements
                progressSection
                
                // Data & Privacy
                dataSection
                
                // About
                aboutSection
            }
            .navigationTitle("Settings")
            .listStyle(InsetGroupedListStyle())
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView(userProfile: userProfile)
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsView(userProfile: userProfile)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView(userProfile: userProfile)
        }
        .alert("Reset All Data", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will permanently delete all your game progress, achievements, and focus session data. This action cannot be undone.")
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        Section {
            HStack(spacing: 16) {
                // Profile Avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: userProfile.selectedTheme.primaryColor))
                        .frame(width: 60, height: 60)
                    
                    Text(userProfile.username.isEmpty ? "?" : String(userProfile.username.prefix(1).uppercased()))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Username", text: $userProfile.username)
                        .font(.headline)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    Text("\(userProfile.getTotalAchievementPoints()) Achievement Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Game Settings Section
    private var gameSettingsSection: some View {
        Section("Game Settings") {
            Picker("Preferred Difficulty", selection: $userProfile.preferredDifficulty) {
                ForEach(GameDifficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.rawValue).tag(difficulty)
                }
            }
            
            Toggle("Haptic Feedback", isOn: $userProfile.enableHapticFeedback)
            
            Toggle("Animations", isOn: $userProfile.enableAnimations)
            
            Toggle("Auto-Save Progress", isOn: $userProfile.autoSaveProgress)
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        Section("Appearance") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: userProfile.selectedTheme == theme
                        ) {
                            userProfile.selectedTheme = theme
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        Section("Notifications & Sounds") {
            Picker("Notifications", selection: $userProfile.notificationSettings) {
                ForEach(NotificationSetting.allCases, id: \.self) { setting in
                    Text(setting.rawValue).tag(setting)
                }
            }
            
            Picker("Sound Volume", selection: $userProfile.soundSettings) {
                ForEach(SoundSetting.allCases, id: \.self) { setting in
                    Text(setting.rawValue).tag(setting)
                }
            }
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        Section("Progress & Achievements") {
            NavigationLink(destination: EmptyView()) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(Color(hex: "#d17305"))
                        .frame(width: 25)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Achievements")
                        Text("\(userProfile.getUnlockedAchievements().count) of \(userProfile.achievements.count) unlocked")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onTapGesture {
                showingAchievements = true
            }
            
            NavigationLink(destination: EmptyView()) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(Color(hex: "#28a809"))
                        .frame(width: 25)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Statistics")
                        Text("Games played: \(userProfile.statistics.totalGamesPlayed)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onTapGesture {
                showingStatistics = true
            }
        }
    }
    
    // MARK: - Data Section
    private var dataSection: some View {
        Section("Data & Privacy") {
            Button(action: {
                showingDataExport = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                        .frame(width: 25)
                    
                    Text("Export Data")
                        .foregroundColor(.primary)
                }
            }
            
            Button(action: {
                showingResetConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 25)
                    
                    Text("Reset All Data")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        Section("About") {
            NavigationLink(destination: EmptyView()) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .frame(width: 25)
                    
                    Text("About PixelAvi Play")
                }
            }
            .onTapGesture {
                showingAbout = true
            }
            
            HStack {
                Image(systemName: "number")
                    .foregroundColor(.secondary)
                    .frame(width: 25)
                
                Text("Version")
                
                Spacer()
                
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func resetAllData() {
        // Reset user profile
        userProfile.statistics = GameStatistics()
        userProfile.achievements = []
        userProfile.focusHistory = []
        userProfile.username = ""
        
        // Clear Core Data
        DataService.shared.clearAllData()
    }
}

// MARK: - Supporting Views

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Theme Preview
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color(hex: theme.backgroundColor))
                        .frame(width: 12, height: 20)
                    
                    VStack(spacing: 1) {
                        Rectangle()
                            .fill(Color(hex: theme.primaryColor))
                            .frame(width: 12, height: 6)
                        
                        Rectangle()
                            .fill(Color(hex: theme.secondaryColor))
                            .frame(width: 12, height: 6)
                        
                        Rectangle()
                            .fill(Color(hex: theme.accentColor))
                            .frame(width: 12, height: 6)
                    }
                }
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
                
                Text(theme.rawValue)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct AchievementsView: View {
    let userProfile: UserProfile
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(userProfile.achievements, id: \.id) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding()
            }
            .navigationTitle("Achievements")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color(hex: "#d17305") : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.type.icon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(achievement.type.rawValue)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                
                Text(achievement.type.description)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if achievement.isUnlocked {
                    Text("\(achievement.type.points) pts")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#d17305"))
                } else {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 2)
                            
                            Rectangle()
                                .fill(Color(hex: "#28a809"))
                                .frame(width: geometry.size.width * CGFloat(achievement.progress), height: 2)
                        }
                        .cornerRadius(1)
                    }
                    .frame(height: 2)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.05))
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}

struct StatisticsView: View {
    let userProfile: UserProfile
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section("Game Statistics") {
                    StatRow(title: "Games Played", value: "\(userProfile.statistics.totalGamesPlayed)")
                    StatRow(title: "Games Won", value: "\(userProfile.statistics.totalGamesWon)")
                    StatRow(title: "Win Rate", value: String(format: "%.1f%%", userProfile.statistics.winRate * 100))
                    StatRow(title: "Best Score", value: "\(userProfile.statistics.bestScore)")
                    StatRow(title: "Current Streak", value: "\(userProfile.statistics.currentStreak)")
                    StatRow(title: "Longest Streak", value: "\(userProfile.statistics.longestStreak)")
                }
                
                Section("Focus Statistics") {
                    StatRow(title: "Total Focus Time", value: formatDuration(userProfile.statistics.totalFocusTime))
                    StatRow(title: "Focus Sessions", value: "\(userProfile.focusHistory.count)")
                    StatRow(title: "Consecutive Days", value: "\(userProfile.statistics.consecutiveDaysPlayed)")
                }
                
                Section("Usage") {
                    StatRow(title: "Total Play Time", value: formatDuration(userProfile.statistics.totalTimePlayed))
                    StatRow(title: "Hints Used", value: "\(userProfile.statistics.totalHintsUsed)")
                    StatRow(title: "Power-Ups Used", value: "\(userProfile.statistics.totalPowerUpsUsed)")
                }
            }
            .navigationTitle("Statistics")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Title
                    VStack(spacing: 16) {
                        Image(systemName: "grid.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color(hex: "#28a809"))
                        
                        Text("PixelAvi Play")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.headline)
                        
                        Text("PixelAvi Play is a unique puzzle game that combines engaging grid-based challenges with powerful focus utilities. Match colorful patterns while building productive habits through integrated focus sessions.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureItem(icon: "gamecontroller", text: "Innovative grid-based puzzle gameplay")
                            FeatureItem(icon: "timer", text: "Timed challenges with power-ups")
                            FeatureItem(icon: "brain.head.profile", text: "Focus Time utility for productivity")
                            FeatureItem(icon: "trophy", text: "Achievement system and progress tracking")
                            FeatureItem(icon: "paintbrush", text: "Dynamic themes and customization")
                            FeatureItem(icon: "lock.shield", text: "Complete privacy with local data storage")
                        }
                    }
                    
                    // Privacy
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Privacy")
                            .font(.headline)
                        
                        Text("Your privacy is important to us. All game data, achievements, and focus sessions are stored locally on your device. We don't collect, share, or transmit any personal information.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Credits
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Credits")
                            .font(.headline)
                        
                        Text("Developed with SwiftUI and Core Data, following Apple's Human Interface Guidelines for the best user experience.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "#28a809"))
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct DataExportView: View {
    let userProfile: UserProfile
    @Environment(\.presentationMode) var presentationMode
    @State private var exportData: [String: Any] = [:]
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Export Options") {
                    Button("Export Game Statistics") {
                        exportGameData()
                    }
                    
                    Button("Export Focus Data") {
                        exportFocusData()
                    }
                    
                    Button("Export All Data") {
                        exportAllData()
                    }
                }
                
                if !exportData.isEmpty {
                    Section("Export Preview") {
                        ForEach(Array(exportData.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key)
                                Spacer()
                                Text("\(exportData[key] ?? "")")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button("Share Data") {
                            showingShareSheet = true
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [createExportString()])
        }
    }
    
    private func exportGameData() {
        exportData = [
            "Total Games": userProfile.statistics.totalGamesPlayed,
            "Games Won": userProfile.statistics.totalGamesWon,
            "Best Score": userProfile.statistics.bestScore,
            "Longest Streak": userProfile.statistics.longestStreak,
            "Win Rate": String(format: "%.1f%%", userProfile.statistics.winRate * 100)
        ]
    }
    
    private func exportFocusData() {
        exportData = [
            "Total Focus Time": formatDuration(userProfile.statistics.totalFocusTime),
            "Focus Sessions": userProfile.focusHistory.count,
            "Consecutive Days": userProfile.statistics.consecutiveDaysPlayed
        ]
    }
    
    private func exportAllData() {
        exportData = DataService.shared.exportUserData()
    }
    
    private func createExportString() -> String {
        var result = "PixelAvi Play - Data Export\n\n"
        
        for (key, value) in exportData.sorted(by: { $0.key < $1.key }) {
            result += "\(key): \(value)\n"
        }
        
        result += "\nExported on: \(Date())"
        return result
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
}
