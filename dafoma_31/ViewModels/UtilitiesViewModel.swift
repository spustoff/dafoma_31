//
//  UtilitiesViewModel.swift
//  PixelPlay Avi
//
//  Created by Вячеслав on 8/26/25.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

class UtilitiesViewModel: ObservableObject {
    @Published var currentFocusSession: FocusSession?
    @Published var isTimerRunning: Bool = false
    @Published var selectedFocusType: FocusType = .gameSession
    @Published var customDuration: TimeInterval = 600 // 10 minutes default
    @Published var remainingTime: TimeInterval = 0
    @Published var focusHistory: [FocusSession] = []
    @Published var showingFocusComplete: Bool = false
    @Published var showingBreakReminder: Bool = false
    @Published var totalFocusTimeToday: TimeInterval = 0
    @Published var focusStreak: Int = 0
    @Published var showingTimerSettings: Bool = false
    @Published var enableNotifications: Bool = true
    @Published var enableSoundAlerts: Bool = true
    @Published var selectedAlertSound: AlertSound = .gentle
    @Published var enableBreakReminders: Bool = true
    @Published var breakReminderInterval: TimeInterval = 1800 // 30 minutes
    
    // Statistics tracking
    @Published var weeklyFocusGoal: TimeInterval = 7200 // 2 hours per week
    @Published var dailyFocusGoal: TimeInterval = 1800 // 30 minutes per day
    @Published var weeklyProgress: Double = 0.0
    @Published var dailyProgress: Double = 0.0
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let dataService = DataService.shared
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    enum AlertSound: String, CaseIterable {
        case gentle = "Gentle"
        case chime = "Chime"
        case bell = "Bell"
        case nature = "Nature"
        case silent = "Silent"
        
        var fileName: String {
            switch self {
            case .gentle: return "gentle_alert"
            case .chime: return "chime_alert"
            case .bell: return "bell_alert"
            case .nature: return "nature_alert"
            case .silent: return ""
            }
        }
        
        var icon: String {
            switch self {
            case .gentle: return "speaker.wave.2"
            case .chime: return "bell"
            case .bell: return "bell.circle"
            case .nature: return "leaf"
            case .silent: return "speaker.slash"
            }
        }
    }
    
    init() {
        loadFocusHistory()
        calculateDailyProgress()
        calculateWeeklyProgress()
        requestNotificationPermission()
    }
    
    // MARK: - Focus Session Management
    func startFocusSession(type: FocusType, duration: TimeInterval? = nil) {
        let sessionDuration = duration ?? (type == .custom ? customDuration : type.defaultDuration)
        
        currentFocusSession = FocusSession(
            startTime: Date(),
            duration: sessionDuration,
            sessionType: type,
            isCompleted: false,
            endTime: Date().addingTimeInterval(sessionDuration)
        )
        
        remainingTime = sessionDuration
        isTimerRunning = true
        selectedFocusType = type
        
        startTimer()
        scheduleNotification()
        startBackgroundTask()
        
        triggerHapticFeedback(.start)
    }
    
    func pauseFocusSession() {
        isTimerRunning = false
        timer?.invalidate()
        endBackgroundTask()
        
        triggerHapticFeedback(.pause)
    }
    
    func resumeFocusSession() {
        guard currentFocusSession != nil else { return }
        
        isTimerRunning = true
        startTimer()
        startBackgroundTask()
        
        triggerHapticFeedback(.resume)
    }
    
    func stopFocusSession() {
        timer?.invalidate()
        isTimerRunning = false
        
        if let session = currentFocusSession {
            let completedSession = FocusSession(
                startTime: session.startTime,
                duration: Date().timeIntervalSince(session.startTime),
                sessionType: session.sessionType,
                isCompleted: false, // Stopped early
                endTime: Date()
            )
            
            focusHistory.append(completedSession)
            dataService.saveFocusSession(completedSession)
        }
        
        currentFocusSession = nil
        remainingTime = 0
        endBackgroundTask()
        cancelNotification()
        
        triggerHapticFeedback(.stop)
    }
    
    private func completeFocusSession() {
        guard let session = currentFocusSession else { return }
        
        let completedSession = FocusSession(
            startTime: session.startTime,
            duration: session.duration,
            sessionType: session.sessionType,
            isCompleted: true,
            endTime: Date()
        )
        
        focusHistory.append(completedSession)
        dataService.saveFocusSession(completedSession)
        
        currentFocusSession = nil
        isTimerRunning = false
        remainingTime = 0
        showingFocusComplete = true
        
        updateFocusStatistics(completedSession)
        checkFocusAchievements()
        
        endBackgroundTask()
        triggerHapticFeedback(.complete)
        
        // Show completion notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showingFocusComplete = false
        }
        
        // Schedule break reminder if enabled
        if enableBreakReminders {
            scheduleBreakReminder()
        }
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.remainingTime > 0 {
                    self.remainingTime -= 1
                } else {
                    self.completeFocusSession()
                }
            }
        }
    }
    
    // MARK: - Background Task Management
    private func startBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    // MARK: - Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.enableNotifications = granted
            }
        }
    }
    
    private func scheduleNotification() {
        guard enableNotifications, let session = currentFocusSession else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete!"
        content.body = "Great job! Your \(session.sessionType.rawValue.lowercased()) session is finished."
        content.sound = enableSoundAlerts ? UNNotificationSound.default : nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: session.duration, repeats: false)
        let request = UNNotificationRequest(identifier: "focus_complete", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["focus_complete"])
    }
    
    private func scheduleBreakReminder() {
        guard enableBreakReminders && enableNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Time for a Break!"
        content.body = "You've been focused for a while. Consider taking a short break."
        content.sound = enableSoundAlerts ? UNNotificationSound.default : nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: breakReminderInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "break_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Statistics and Progress
    private func updateFocusStatistics(_ session: FocusSession) {
        totalFocusTimeToday += session.duration
        calculateDailyProgress()
        calculateWeeklyProgress()
        updateFocusStreak()
    }
    
    private func calculateDailyProgress() {
        let calendar = Calendar.current
        let today = Date()
        
        let todaySessions = focusHistory.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: today) && session.isCompleted
        }
        
        totalFocusTimeToday = todaySessions.reduce(0) { total, session in
            total + session.duration
        }
        
        dailyProgress = min(1.0, totalFocusTimeToday / dailyFocusGoal)
    }
    
    private func calculateWeeklyProgress() {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        let weekSessions = focusHistory.filter { session in
            session.startTime >= weekAgo && session.isCompleted
        }
        
        let weeklyFocusTime = weekSessions.reduce(0) { total, session in
            total + session.duration
        }
        
        weeklyProgress = min(1.0, weeklyFocusTime / weeklyFocusGoal)
    }
    
    private func updateFocusStreak() {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        // Count consecutive days with focus sessions
        while true {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let dayHasSessions = focusHistory.contains { session in
                session.startTime >= dayStart && session.startTime < dayEnd && session.isCompleted
            }
            
            if dayHasSessions {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        focusStreak = streak
    }
    
    private func checkFocusAchievements() {
        // Check for Focus Guru achievement (1 hour total)
        let totalFocusTime = focusHistory.filter { $0.isCompleted }.reduce(0) { $0 + $1.duration }
        if totalFocusTime >= 3600 {
            // Trigger achievement unlock
        }
        
        // Check for daily focus achievement
        if dailyProgress >= 1.0 {
            // Trigger daily achievement
        }
    }
    
    // MARK: - Utility Functions
    func getFormattedTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    func getFormattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(remainingMinutes) min"
            }
        }
    }
    
    func getFocusSessionsToday() -> [FocusSession] {
        let calendar = Calendar.current
        let today = Date()
        
        return focusHistory.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: today)
        }
    }
    
    func getAverageFocusTime() -> TimeInterval {
        let completedSessions = focusHistory.filter { $0.isCompleted }
        guard !completedSessions.isEmpty else { return 0 }
        
        let totalTime = completedSessions.reduce(0) { $0 + $1.duration }
        return totalTime / Double(completedSessions.count)
    }
    
    func getLongestFocusSession() -> TimeInterval {
        return focusHistory.filter { $0.isCompleted }.map { $0.duration }.max() ?? 0
    }
    
    func getTotalFocusTime() -> TimeInterval {
        return focusHistory.filter { $0.isCompleted }.reduce(0) { $0 + $1.duration }
    }
    
    // MARK: - Settings Management
    func updateCustomDuration(_ duration: TimeInterval) {
        customDuration = max(60, min(7200, duration)) // 1 minute to 2 hours
    }
    
    func updateDailyGoal(_ goal: TimeInterval) {
        dailyFocusGoal = max(300, min(14400, goal)) // 5 minutes to 4 hours
        calculateDailyProgress()
    }
    
    func updateWeeklyGoal(_ goal: TimeInterval) {
        weeklyFocusGoal = max(1800, min(50400, goal)) // 30 minutes to 14 hours
        calculateWeeklyProgress()
    }
    
    // MARK: - Data Management
    private func loadFocusHistory() {
        focusHistory = dataService.loadFocusHistory()
    }
    
    func clearFocusHistory() {
        focusHistory.removeAll()
        totalFocusTimeToday = 0
        focusStreak = 0
        dailyProgress = 0
        weeklyProgress = 0
        
        // Clear from Core Data as well
        // This would require additional DataService methods
    }
    
    func exportFocusData() -> [String: Any] {
        return [
            "totalSessions": focusHistory.count,
            "completedSessions": focusHistory.filter { $0.isCompleted }.count,
            "totalFocusTime": getTotalFocusTime(),
            "averageFocusTime": getAverageFocusTime(),
            "longestSession": getLongestFocusSession(),
            "currentStreak": focusStreak,
            "dailyGoal": dailyFocusGoal,
            "weeklyGoal": weeklyFocusGoal
        ]
    }
    
    // MARK: - Haptic Feedback
    private func triggerHapticFeedback(_ type: HapticType) {
        switch type {
        case .start:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
        case .pause, .resume:
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.impactOccurred()
        case .stop:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.warning)
        case .complete:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
        }
    }
    
    private enum HapticType {
        case start, pause, resume, stop, complete
    }
    
    deinit {
        timer?.invalidate()
        endBackgroundTask()
        cancellables.removeAll()
    }
}
