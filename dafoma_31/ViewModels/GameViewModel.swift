//
//  GameViewModel.swift
//  PixelAvi Play
//
//  Created by Вячеслав on 8/26/25.
//

import Foundation
import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var currentSession: GameSession?
    @Published var isGameActive: Bool = false
    @Published var selectedDifficulty: GameDifficulty = .easy
    @Published var showingGameOver: Bool = false
    @Published var showingPauseMenu: Bool = false
    @Published var selectedTilePosition: GridPosition?
    @Published var availableColors: [TileColor] = [.primary, .secondary, .accent, .neutral]
    @Published var showingPowerUpMenu: Bool = false
    @Published var animatingTiles: Set<UUID> = []
    @Published var showingHint: Bool = false
    @Published var gameOverMessage: String = ""
    @Published var showingAchievementUnlock: Bool = false
    @Published var unlockedAchievement: Achievement?
    
    private var cancellables = Set<AnyCancellable>()
    private let dataService = DataService.shared
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    // Game Statistics
    @Published var sessionStats: SessionStats = SessionStats()
    
    struct SessionStats {
        var perfectMoves: Int = 0
        var powerUpsUsed: [PowerUpType: Int] = [:]
        var fastestSolve: TimeInterval = 0
        var hintsUsedThisSession: Int = 0
    }
    
    init() {
        setupHapticFeedback()
    }
    
    private func setupHapticFeedback() {
        hapticFeedback.prepare()
    }
    
    // MARK: - Game Management
    func startNewGame(difficulty: GameDifficulty) {
        selectedDifficulty = difficulty
        currentSession = GameSession(difficulty: difficulty)
        isGameActive = true
        showingGameOver = false
        sessionStats = SessionStats()
        
        currentSession?.startGame()
        
        // Subscribe to game session updates
        currentSession?.objectWillChange
            .sink { [weak self] in
                self?.handleGameStateChange()
            }
            .store(in: &cancellables)
    }
    
    func pauseGame() {
        currentSession?.pauseGame()
        showingPauseMenu = true
        isGameActive = false
    }
    
    func resumeGame() {
        currentSession?.resumeGame()
        showingPauseMenu = false
        isGameActive = true
    }
    
    func endGame() {
        currentSession?.pauseGame()
        isGameActive = false
        
        // Clean up game state immediately
        currentSession = nil
        selectedTilePosition = nil
        animatingTiles.removeAll()
        showingGameOver = false
        showingPauseMenu = false
        showingPowerUpMenu = false
        showingAchievementUnlock = false
        unlockedAchievement = nil
        
        print("Game ended successfully")
    }
    
    private func handleGameStateChange() {
        guard let session = currentSession else { return }
        
        switch session.gameState {
        case .completed:
            handleGameCompletion(success: true)
        case .failed:
            handleGameCompletion(success: false)
        case .paused:
            showingPauseMenu = true
        default:
            break
        }
    }
    
    private func handleGameCompletion(success: Bool) {
        isGameActive = false
        showingGameOver = true
        
        if success {
            gameOverMessage = "Congratulations! Pattern Complete!"
            sessionStats.fastestSolve = currentSession?.targetPattern.difficulty.timeLimit ?? 0 - (currentSession?.timeRemaining ?? 0)
            triggerSuccessHaptic()
            checkForAchievements()
        } else {
            gameOverMessage = "Time's Up! Try Again?"
            triggerFailureHaptic()
        }
        
        // Update statistics without saving to CoreData for now
        if let session = currentSession {
            updateUserStatistics(session)
        }
    }
    
    // MARK: - Game Actions
    func selectTile(at position: GridPosition) {
        guard isGameActive, let session = currentSession else { return }
        
        selectedTilePosition = position
        triggerSelectionHaptic()
        
        // Add tile animation
        let tileId = session.currentGrid[position.row][position.column].id
        animatingTiles.insert(tileId)
        
        // Remove animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.animatingTiles.remove(tileId)
        }
    }
    
    func applyColor(_ color: TileColor, to position: GridPosition) {
        guard isGameActive, let session = currentSession else { return }
        
        session.makeMove(at: position, newColor: color)
        selectedTilePosition = nil
        
        // Check for perfect move
        let targetColor = session.targetPattern.targetGrid[position.row][position.column]
        if color == targetColor {
            sessionStats.perfectMoves += 1
            triggerSuccessHaptic()
        } else {
            triggerErrorHaptic()
        }
    }
    
    func usePowerUp(_ powerUp: PowerUpType) {
        guard isGameActive, let session = currentSession else { return }
        
        session.usePowerUp(powerUp)
        sessionStats.powerUpsUsed[powerUp, default: 0] += 1
        showingPowerUpMenu = false
        
        triggerPowerUpHaptic()
        
        // Handle specific power-up effects
        switch powerUp {
        case .hintReveal:
            showHintAnimation()
        case .colorMatch:
            highlightMatchingColors()
        case .gridClear:
            animateGridClear()
        case .timeBoost:
            animateTimeBoost()
        }
    }
    
    func useHint() {
        guard isGameActive, let session = currentSession else { return }
        
        session.usePowerUp(.hintReveal)
        sessionStats.hintsUsedThisSession += 1
        showHintAnimation()
    }
    
    // MARK: - Visual Effects
    private func showHintAnimation() {
        showingHint = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showingHint = false
        }
    }
    
    private func highlightMatchingColors() {
        // Implementation for highlighting matching colors
        guard let session = currentSession else { return }
        
        for row in 0..<session.currentGrid.count {
            for col in 0..<session.currentGrid[row].count {
                let tileId = session.currentGrid[row][col].id
                animatingTiles.insert(tileId)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.animatingTiles.removeAll()
        }
    }
    
    private func animateGridClear() {
        guard let session = currentSession else { return }
        
        // Animate tiles being cleared
        for row in 0..<session.currentGrid.count {
            for col in 0..<session.currentGrid[row].count {
                let currentColor = session.currentGrid[row][col].color
                let targetColor = session.targetPattern.targetGrid[row][col]
                
                if currentColor != targetColor && currentColor != .background {
                    let tileId = session.currentGrid[row][col].id
                    animatingTiles.insert(tileId)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.animatingTiles.removeAll()
        }
    }
    
    private func animateTimeBoost() {
        // Visual feedback for time boost
        withAnimation(.easeInOut(duration: 0.5)) {
            // This would trigger a visual effect in the UI
        }
    }
    
    // MARK: - Haptic Feedback
    private func triggerSelectionHaptic() {
        let feedback = UISelectionFeedbackGenerator()
        feedback.selectionChanged()
    }
    
    private func triggerSuccessHaptic() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }
    
    private func triggerErrorHaptic() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.error)
    }
    
    private func triggerFailureHaptic() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.error)
    }
    
    private func triggerPowerUpHaptic() {
        hapticFeedback.impactOccurred()
    }
    
    // MARK: - Statistics and Achievements
    private func updateUserStatistics(_ session: GameSession) {
        // This would typically update the user profile through a shared service
        // For now, we'll just save the session data
    }
    
    private func checkForAchievements() {
        guard let session = currentSession else { return }
        
        // Check for speed runner achievement
        let completionTime = session.targetPattern.difficulty.timeLimit - session.timeRemaining
        if completionTime <= 30 {
            unlockAchievement(.speedRunner)
        }
        
        // Check for perfectionist achievement
        if session.hintsUsed == 0 {
            unlockAchievement(.perfectionist)
        }
        
        // Check for power-up master achievement
        let totalPowerUpsUsed = sessionStats.powerUpsUsed.values.reduce(0, +)
        if totalPowerUpsUsed >= 4 {
            unlockAchievement(.powerUpMaster)
        }
    }
    
    private func unlockAchievement(_ type: AchievementType) {
        let achievement = Achievement(type: type, unlockedDate: Date(), progress: 1.0)
        unlockedAchievement = achievement
        showingAchievementUnlock = true
        
        dataService.updateAchievementProgress(type, progress: 1.0, unlocked: true)
        
        // Hide achievement notification after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showingAchievementUnlock = false
            self.unlockedAchievement = nil
        }
    }
    
    // MARK: - Game Helpers
    func getTileColor(at position: GridPosition) -> TileColor {
        guard let session = currentSession,
              position.row < session.currentGrid.count,
              position.column < session.currentGrid[position.row].count else {
            return .background
        }
        
        return session.currentGrid[position.row][position.column].color
    }
    
    func getTargetColor(at position: GridPosition) -> TileColor {
        guard let session = currentSession,
              position.row < session.targetPattern.targetGrid.count,
              position.column < session.targetPattern.targetGrid[position.row].count else {
            return .background
        }
        
        return session.targetPattern.targetGrid[position.row][position.column]
    }
    
    func isTileCorrect(at position: GridPosition) -> Bool {
        return getTileColor(at: position) == getTargetColor(at: position)
    }
    
    func isTileHinted(at position: GridPosition) -> Bool {
        guard let session = currentSession,
              position.row < session.currentGrid.count,
              position.column < session.currentGrid[position.row].count else {
            return false
        }
        
        return session.currentGrid[position.row][position.column].isHinted
    }
    
    func getCompletionPercentage() -> Double {
        guard let session = currentSession else { return 0.0 }
        
        let totalTiles = session.currentGrid.count * session.currentGrid.count
        var correctTiles = 0
        
        for row in 0..<session.currentGrid.count {
            for col in 0..<session.currentGrid[row].count {
                if isTileCorrect(at: GridPosition(row: row, column: col)) {
                    correctTiles += 1
                }
            }
        }
        
        return Double(correctTiles) / Double(totalTiles)
    }
    
    func getFormattedTime() -> String {
        guard let session = currentSession else { return "0:00" }
        
        let minutes = Int(session.timeRemaining) / 60
        let seconds = Int(session.timeRemaining) % 60
        
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func getScoreMultiplier() -> Double {
        let completion = getCompletionPercentage()
        let perfectMoveRatio = sessionStats.perfectMoves > 0 ? Double(sessionStats.perfectMoves) / Double(currentSession?.movesUsed ?? 1) : 0.0
        
        return 1.0 + completion + perfectMoveRatio
    }
    
    deinit {
        cancellables.removeAll()
    }
}
