//
//  UtilitiesView.swift
//  PixelAvi Play
//
//  Created by Вячеслав on 8/26/25.
//

import SwiftUI

struct UtilitiesView: View {
    @StateObject private var utilitiesViewModel = UtilitiesViewModel()
    @StateObject private var userProfile = UserProfile()
    @State private var showingTimerSettings = false
    @State private var showingFocusHistory = false
    @State private var selectedFocusType: FocusType = .gameSession
    @State private var customMinutes: Double = 10
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Current Focus Session or Timer Setup
                    if utilitiesViewModel.isTimerRunning {
                        activeFocusSessionView
                    } else {
                        focusTimerSetupView
                    }
                    
                    // Quick Stats
                    focusStatsView
                    
                    // Focus History Preview
                    focusHistoryPreview
                    
                    // Settings
                    focusSettingsView
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("Focus Time")
            .navigationBarItems(
                trailing: Button(action: {
                    showingTimerSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(Color(hex: userProfile.selectedTheme.primaryColor))
                }
            )
        }
        .sheet(isPresented: $showingTimerSettings) {
            FocusSettingsView(utilitiesViewModel: utilitiesViewModel)
        }
        .sheet(isPresented: $showingFocusHistory) {
            FocusHistoryView(utilitiesViewModel: utilitiesViewModel)
        }
        .alert("Focus Session Complete!", isPresented: $utilitiesViewModel.showingFocusComplete) {
            Button("Great!") { }
        } message: {
            Text("Well done! You've completed your focus session.")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: userProfile.selectedTheme.primaryColor))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus Time")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Enhance your concentration")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Daily Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today's Progress")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(utilitiesViewModel.getFormattedDuration(utilitiesViewModel.totalFocusTimeToday)) / \(utilitiesViewModel.getFormattedDuration(utilitiesViewModel.dailyFocusGoal))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(Color(hex: userProfile.selectedTheme.primaryColor))
                            .frame(width: geometry.size.width * CGFloat(utilitiesViewModel.dailyProgress), height: 4)
                    }
                    .cornerRadius(2)
                }
                .frame(height: 4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.2))
            )
        }
    }
    
    // MARK: - Active Focus Session View
    private var activeFocusSessionView: some View {
        VStack(spacing: 20) {
            // Timer Display
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.3), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: utilitiesViewModel.remainingTime / (utilitiesViewModel.currentFocusSession?.duration ?? 1))
                    .stroke(
                        Color(hex: utilitiesViewModel.selectedFocusType.color),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: utilitiesViewModel.remainingTime)
                
                VStack(spacing: 8) {
                    Text(utilitiesViewModel.getFormattedTime(utilitiesViewModel.remainingTime))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(utilitiesViewModel.selectedFocusType.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Session Controls
            HStack(spacing: 20) {
                Button(action: {
                    if utilitiesViewModel.isTimerRunning {
                        utilitiesViewModel.pauseFocusSession()
                    } else {
                        utilitiesViewModel.resumeFocusSession()
                    }
                }) {
                    Image(systemName: utilitiesViewModel.isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: userProfile.selectedTheme.primaryColor))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    utilitiesViewModel.stopFocusSession()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: userProfile.selectedTheme.secondaryColor))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    // MARK: - Focus Timer Setup View
    private var focusTimerSetupView: some View {
        VStack(spacing: 20) {
            Text("Start Focus Session")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Focus Type Selection
            VStack(spacing: 12) {
                ForEach(FocusType.allCases, id: \.self) { focusType in
                    FocusTypeCard(
                        focusType: focusType,
                        isSelected: selectedFocusType == focusType,
                        customDuration: focusType == .custom ? customMinutes * 60 : nil
                    ) {
                        selectedFocusType = focusType
                    }
                }
            }
            
            // Custom Duration Slider (only for custom type)
            if selectedFocusType == .custom {
                VStack(spacing: 8) {
                    Text("Duration: \(Int(customMinutes)) minutes")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Slider(value: $customMinutes, in: 5...120, step: 5)
                        .accentColor(Color(hex: userProfile.selectedTheme.primaryColor))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.1))
                )
            }
            
            // Start Button
            Button(action: {
                let duration = selectedFocusType == .custom ? customMinutes * 60 : selectedFocusType.defaultDuration
                utilitiesViewModel.startFocusSession(type: selectedFocusType, duration: duration)
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Focus Session")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: userProfile.selectedTheme.primaryColor))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    // MARK: - Focus Stats View
    private var focusStatsView: some View {
        VStack(spacing: 16) {
            Text("Focus Statistics")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                FocusStatCard(
                    title: "Total Time",
                    value: utilitiesViewModel.getFormattedDuration(utilitiesViewModel.getTotalFocusTime()),
                    icon: "clock.fill",
                    color: userProfile.selectedTheme.primaryColor
                )
                
                FocusStatCard(
                    title: "Sessions Today",
                    value: "\(utilitiesViewModel.getFocusSessionsToday().count)",
                    icon: "calendar",
                    color: userProfile.selectedTheme.secondaryColor
                )
                
                FocusStatCard(
                    title: "Average Session",
                    value: utilitiesViewModel.getFormattedDuration(utilitiesViewModel.getAverageFocusTime()),
                    icon: "chart.bar.fill",
                    color: userProfile.selectedTheme.accentColor
                )
                
                FocusStatCard(
                    title: "Focus Streak",
                    value: "\(utilitiesViewModel.focusStreak) days",
                    icon: "flame.fill",
                    color: "#ff6b35"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    // MARK: - Focus History Preview
    private var focusHistoryPreview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Sessions")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    showingFocusHistory = true
                }
                .font(.caption)
                .foregroundColor(Color(hex: userProfile.selectedTheme.primaryColor))
            }
            
            if utilitiesViewModel.focusHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No focus sessions yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Start your first session to build focus habits!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(utilitiesViewModel.focusHistory.prefix(3)), id: \.id) { session in
                        FocusSessionRow(session: session)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    // MARK: - Focus Settings View
    private var focusSettingsView: some View {
        VStack(spacing: 16) {
            Text("Quick Settings")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                SettingToggle(
                    title: "Notifications",
                    subtitle: "Get alerts when sessions complete",
                    isOn: $utilitiesViewModel.enableNotifications,
                    icon: "bell.fill"
                )
                
                SettingToggle(
                    title: "Sound Alerts",
                    subtitle: "Play sound when timer finishes",
                    isOn: $utilitiesViewModel.enableSoundAlerts,
                    icon: "speaker.wave.2.fill"
                )
                
                SettingToggle(
                    title: "Break Reminders",
                    subtitle: "Remind you to take breaks",
                    isOn: $utilitiesViewModel.enableBreakReminders,
                    icon: "pause.circle.fill"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }
}

// MARK: - Supporting Views

struct FocusTypeCard: View {
    let focusType: FocusType
    let isSelected: Bool
    let customDuration: TimeInterval?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: focusType.icon)
                    .font(.title3)
                    .foregroundColor(Color(hex: focusType.color))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(focusType.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(customDuration != nil ? 
                         "\(Int(customDuration! / 60)) minutes" : 
                         "\(Int(focusType.defaultDuration / 60)) minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: focusType.color))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.black.opacity(0.3) : Color.black.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color(hex: focusType.color) : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct FocusStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: color))
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.1))
        )
    }
}

struct FocusSessionRow: View {
    let session: FocusSession
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.sessionType.icon)
                .font(.title3)
                .foregroundColor(Color(hex: session.sessionType.color))
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.sessionType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(formatSessionTime(session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(session.duration))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(session.isCompleted ? Color(hex: "#28a809") : Color(hex: "#e6053a"))
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatSessionTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

struct SettingToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: "#28a809"))
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#28a809")))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Additional Views

struct FocusSettingsView: View {
    let utilitiesViewModel: UtilitiesViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var dailyGoalHours: Double = 0.5
    @State private var weeklyGoalHours: Double = 2.0
    @State private var breakReminderMinutes: Double = 30
    
    var body: some View {
        NavigationView {
            Form {
                Section("Goals") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Goal: \(dailyGoalHours, specifier: "%.1f") hours")
                        Slider(value: $dailyGoalHours, in: 0.25...4.0, step: 0.25)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weekly Goal: \(weeklyGoalHours, specifier: "%.1f") hours")
                        Slider(value: $weeklyGoalHours, in: 1.0...14.0, step: 0.5)
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: .constant(utilitiesViewModel.enableNotifications))
                    Toggle("Sound Alerts", isOn: .constant(utilitiesViewModel.enableSoundAlerts))
                    Toggle("Break Reminders", isOn: .constant(utilitiesViewModel.enableBreakReminders))
                    
                    if utilitiesViewModel.enableBreakReminders {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Break Reminder: Every \(Int(breakReminderMinutes)) minutes")
                            Slider(value: $breakReminderMinutes, in: 15...120, step: 15)
                        }
                    }
                }
                
                Section("Data") {
                    Button("Export Focus Data") {
                        // Export functionality
                    }
                    
                    Button("Clear Focus History") {
                        utilitiesViewModel.clearFocusHistory()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Focus Settings")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            dailyGoalHours = utilitiesViewModel.dailyFocusGoal / 3600
            weeklyGoalHours = utilitiesViewModel.weeklyFocusGoal / 3600
            breakReminderMinutes = utilitiesViewModel.breakReminderInterval / 60
        }
        .onDisappear {
            utilitiesViewModel.updateDailyGoal(dailyGoalHours * 3600)
            utilitiesViewModel.updateWeeklyGoal(weeklyGoalHours * 3600)
        }
    }
}

struct FocusHistoryView: View {
    let utilitiesViewModel: UtilitiesViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(utilitiesViewModel.focusHistory, id: \.id) { session in
                    FocusSessionDetailRow(session: session)
                }
            }
            .navigationTitle("Focus History")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct FocusSessionDetailRow: View {
    let session: FocusSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: session.sessionType.icon)
                    .foregroundColor(Color(hex: session.sessionType.color))
                
                Text(session.sessionType.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Text(formatDate(session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Duration: \(formatDuration(session.duration))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label(
                    session.isCompleted ? "Completed" : "Stopped Early",
                    systemImage: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .font(.caption)
                .foregroundColor(session.isCompleted ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
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

#Preview {
    UtilitiesView()
}
