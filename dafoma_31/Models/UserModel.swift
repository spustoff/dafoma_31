//
//  UserModel.swift
//  PixelAvi Play
//
//  Created by Вячеслав on 8/26/25.
//

import Foundation
import CoreData

// MARK: - User Preferences
enum AppTheme: String, CaseIterable {
    case dark = "Dark"
    case colorful = "Colorful"
    case minimal = "Minimal"
    
    var backgroundColor: String {
        switch self {
        case .dark: return "#0e0e0e"
        case .colorful: return "#1a1a1a"
        case .minimal: return "#000000"
        }
    }
    
    var primaryColor: String {
        switch self {
        case .dark, .colorful: return "#28a809"
        case .minimal: return "#ffffff"
        }
    }
    
    var secondaryColor: String {
        switch self {
        case .dark, .colorful: return "#e6053a"
        case .minimal: return "#666666"
        }
    }
    
    var accentColor: String {
        switch self {
        case .dark, .colorful: return "#d17305"
        case .minimal: return "#333333"
        }
    }
}

enum SoundSetting: String, CaseIterable {
    case off = "Off"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var volume: Float {
        switch self {
        case .off: return 0.0
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 1.0
        }
    }
}

enum NotificationSetting: String, CaseIterable {
    case off = "Off"
    case daily = "Daily"
    case weekly = "Weekly"
    
    var description: String {
        switch self {
        case .off: return "No notifications"
        case .daily: return "Daily game reminders"
        case .weekly: return "Weekly progress updates"
        }
    }
}

// MARK: - Achievement System
enum AchievementType: String, CaseIterable {
    case firstWin = "First Victory"
    case speedRunner = "Speed Runner"
    case perfectionist = "Perfectionist"
    case streakMaster = "Streak Master"
    case powerUpMaster = "Power-Up Master"
    case focusGuru = "Focus Guru"
    case dailyPlayer = "Daily Player"
    case weeklyChampion = "Weekly Champion"
    
    var description: String {
        switch self {
        case .firstWin: return "Complete your first game"
        case .speedRunner: return "Complete a game in under 30 seconds"
        case .perfectionist: return "Complete a game without using hints"
        case .streakMaster: return "Win 10 games in a row"
        case .powerUpMaster: return "Use all power-ups in a single game"
        case .focusGuru: return "Use Focus Time for 1 hour total"
        case .dailyPlayer: return "Play for 7 consecutive days"
        case .weeklyChampion: return "Complete 50 games in a week"
        }
    }
    
    var icon: String {
        switch self {
        case .firstWin: return "trophy"
        case .speedRunner: return "bolt"
        case .perfectionist: return "star"
        case .streakMaster: return "flame"
        case .powerUpMaster: return "wand.and.rays"
        case .focusGuru: return "brain.head.profile"
        case .dailyPlayer: return "calendar"
        case .weeklyChampion: return "crown"
        }
    }
    
    var points: Int {
        switch self {
        case .firstWin: return 100
        case .speedRunner: return 250
        case .perfectionist: return 300
        case .streakMaster: return 500
        case .powerUpMaster: return 200
        case .focusGuru: return 400
        case .dailyPlayer: return 350
        case .weeklyChampion: return 750
        }
    }
}

struct Achievement: Identifiable {
    let id = UUID()
    let type: AchievementType
    let unlockedDate: Date?
    let progress: Double // 0.0 to 1.0
    
    var isUnlocked: Bool {
        unlockedDate != nil
    }
}

// MARK: - User Statistics
struct GameStatistics {
    var totalGamesPlayed: Int = 0
    var totalGamesWon: Int = 0
    var totalTimePlayed: TimeInterval = 0
    var bestScore: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var averageCompletionTime: TimeInterval = 0
    var totalHintsUsed: Int = 0
    var totalPowerUpsUsed: Int = 0
    var favoriteGameMode: GameDifficulty = .easy
    var totalFocusTime: TimeInterval = 0
    var consecutiveDaysPlayed: Int = 0
    var lastPlayDate: Date?
    
    var winRate: Double {
        guard totalGamesPlayed > 0 else { return 0.0 }
        return Double(totalGamesWon) / Double(totalGamesPlayed)
    }
    
    var averageScore: Double {
        guard totalGamesWon > 0 else { return 0.0 }
        return Double(bestScore) / Double(totalGamesWon)
    }
}

// MARK: - Focus Time Utility
struct FocusSession: Identifiable {
    let id = UUID()
    let startTime: Date
    let duration: TimeInterval
    let sessionType: FocusType
    let isCompleted: Bool
    let endTime: Date?
    
    var remainingTime: TimeInterval {
        guard !isCompleted, let endTime = endTime else { return 0 }
        return max(0, endTime.timeIntervalSince(Date()))
    }
}

enum FocusType: String, CaseIterable {
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    case gameSession = "Game Session"
    case custom = "Custom"
    
    var defaultDuration: TimeInterval {
        switch self {
        case .shortBreak: return 300 // 5 minutes
        case .longBreak: return 900 // 15 minutes
        case .gameSession: return 1200 // 20 minutes
        case .custom: return 600 // 10 minutes
        }
    }
    
    var icon: String {
        switch self {
        case .shortBreak: return "pause.circle"
        case .longBreak: return "moon.circle"
        case .gameSession: return "gamecontroller"
        case .custom: return "timer"
        }
    }
    
    var color: String {
        switch self {
        case .shortBreak: return "#28a809"
        case .longBreak: return "#e6053a"
        case .gameSession: return "#d17305"
        case .custom: return "#666666"
        }
    }
}

// MARK: - User Profile
class UserProfile: ObservableObject {
    @Published var username: String = ""
    @Published var selectedTheme: AppTheme = .dark
    @Published var soundSettings: SoundSetting = .medium
    @Published var notificationSettings: NotificationSetting = .daily
    @Published var statistics: GameStatistics = GameStatistics()
    @Published var achievements: [Achievement] = []
    @Published var currentFocusSession: FocusSession?
    @Published var focusHistory: [FocusSession] = []
    @Published var hasCompletedOnboarding: Bool = false
    @Published var preferredDifficulty: GameDifficulty = .easy
    @Published var enableHapticFeedback: Bool = true
    @Published var enableAnimations: Bool = true
    @Published var autoSaveProgress: Bool = true
    
    init() {
        initializeAchievements()
        loadUserData()
    }
    
    private func initializeAchievements() {
        achievements = AchievementType.allCases.map { type in
            Achievement(type: type, unlockedDate: nil, progress: 0.0)
        }
    }
    
    func updateStatistics(gameResult: GameSession) {
        statistics.totalGamesPlayed += 1
        statistics.totalTimePlayed += gameResult.targetPattern.difficulty.timeLimit - gameResult.timeRemaining
        
        if gameResult.gameState == .completed {
            statistics.totalGamesWon += 1
            statistics.bestScore = max(statistics.bestScore, gameResult.score)
            statistics.currentStreak += 1
            statistics.longestStreak = max(statistics.longestStreak, statistics.currentStreak)
        } else {
            statistics.currentStreak = 0
        }
        
        statistics.totalHintsUsed += gameResult.hintsUsed
        statistics.totalPowerUpsUsed += gameResult.powerUpsAvailable.values.reduce(0) { total, count in
            total + (3 - count) // Assuming 3 is the max for each power-up
        }
        
        statistics.lastPlayDate = Date()
        updateConsecutiveDays()
        checkAchievements()
        saveUserData()
    }
    
    func startFocusSession(type: FocusType, duration: TimeInterval? = nil) {
        let sessionDuration = duration ?? type.defaultDuration
        let session = FocusSession(
            startTime: Date(),
            duration: sessionDuration,
            sessionType: type,
            isCompleted: false,
            endTime: Date().addingTimeInterval(sessionDuration)
        )
        
        currentFocusSession = session
    }
    
    func completeFocusSession() {
        guard let session = currentFocusSession else { return }
        
        let completedSession = FocusSession(
            startTime: session.startTime,
            duration: session.duration,
            sessionType: session.sessionType,
            isCompleted: true,
            endTime: Date()
        )
        
        focusHistory.append(completedSession)
        statistics.totalFocusTime += session.duration
        currentFocusSession = nil
        
        checkAchievements()
        saveUserData()
    }
    
    private func updateConsecutiveDays() {
        guard let lastPlayDate = statistics.lastPlayDate else {
            statistics.consecutiveDaysPlayed = 1
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        if calendar.isDate(lastPlayDate, inSameDayAs: today) {
            // Same day, no change
            return
        } else if calendar.isDate(lastPlayDate, equalTo: today, toGranularity: .day) {
            // Yesterday, increment
            statistics.consecutiveDaysPlayed += 1
        } else {
            // More than one day gap, reset
            statistics.consecutiveDaysPlayed = 1
        }
    }
    
    private func checkAchievements() {
        for i in 0..<achievements.count {
            let achievement = achievements[i]
            if achievement.isUnlocked { continue }
            
            var shouldUnlock = false
            var progress: Double = 0.0
            
            switch achievement.type {
            case .firstWin:
                shouldUnlock = statistics.totalGamesWon >= 1
                progress = min(1.0, Double(statistics.totalGamesWon))
                
            case .speedRunner:
                shouldUnlock = statistics.averageCompletionTime <= 30 && statistics.totalGamesWon > 0
                progress = statistics.averageCompletionTime > 0 ? min(1.0, 30.0 / statistics.averageCompletionTime) : 0.0
                
            case .perfectionist:
                // This would need to be tracked per game
                progress = 0.0
                
            case .streakMaster:
                shouldUnlock = statistics.longestStreak >= 10
                progress = min(1.0, Double(statistics.longestStreak) / 10.0)
                
            case .powerUpMaster:
                // This would need to be tracked per game
                progress = 0.0
                
            case .focusGuru:
                shouldUnlock = statistics.totalFocusTime >= 3600 // 1 hour
                progress = min(1.0, statistics.totalFocusTime / 3600.0)
                
            case .dailyPlayer:
                shouldUnlock = statistics.consecutiveDaysPlayed >= 7
                progress = min(1.0, Double(statistics.consecutiveDaysPlayed) / 7.0)
                
            case .weeklyChampion:
                // This would need weekly tracking
                progress = 0.0
            }
            
            achievements[i] = Achievement(
                type: achievement.type,
                unlockedDate: shouldUnlock ? Date() : nil,
                progress: progress
            )
        }
    }
    
    func getUnlockedAchievements() -> [Achievement] {
        return achievements.filter { $0.isUnlocked }
    }
    
    func getTotalAchievementPoints() -> Int {
        return getUnlockedAchievements().reduce(0) { total, achievement in
            total + achievement.type.points
        }
    }
    
    private func saveUserData() {
        // Implementation will be handled by DataService
    }
    
    private func loadUserData() {
        // Implementation will be handled by DataService
    }
}
