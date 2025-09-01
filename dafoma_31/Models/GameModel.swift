//
//  GameModel.swift
//  PixelAvi Play
//
//  Created by Вячеслав on 8/26/25.
//

import Foundation
import CoreData

// MARK: - Game State Enums
enum GameDifficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"
    
    var gridSize: Int {
        switch self {
        case .easy: return 4
        case .medium: return 5
        case .hard: return 6
        case .expert: return 7
        }
    }
    
    var timeLimit: TimeInterval {
        switch self {
        case .easy: return 120
        case .medium: return 90
        case .hard: return 60
        case .expert: return 45
        }
    }
}

enum GameState {
    case notStarted
    case playing
    case paused
    case completed
    case failed
}

enum PowerUpType: String, CaseIterable {
    case timeBoost = "Time Boost"
    case hintReveal = "Hint Reveal"
    case colorMatch = "Color Match"
    case gridClear = "Grid Clear"
    
    var icon: String {
        switch self {
        case .timeBoost: return "clock.arrow.circlepath"
        case .hintReveal: return "lightbulb"
        case .colorMatch: return "paintbrush"
        case .gridClear: return "trash"
        }
    }
    
    var description: String {
        switch self {
        case .timeBoost: return "Adds 15 seconds to timer"
        case .hintReveal: return "Reveals next correct move"
        case .colorMatch: return "Highlights matching colors"
        case .gridClear: return "Clears incorrect tiles"
        }
    }
}

// MARK: - Game Models
struct GridTile: Identifiable, Equatable {
    let id = UUID()
    var position: GridPosition
    var color: TileColor
    var isSelected: Bool = false
    var isCorrect: Bool = false
    var isHinted: Bool = false
    var animationOffset: CGSize = .zero
    
    static func == (lhs: GridTile, rhs: GridTile) -> Bool {
        lhs.id == rhs.id
    }
}

struct GridPosition: Equatable {
    let row: Int
    let column: Int
}

enum TileColor: String, CaseIterable {
    case primary = "#28a809"
    case secondary = "#e6053a"
    case accent = "#d17305"
    case background = "#0e0e0e"
    case neutral = "#666666"
    
    var displayName: String {
        switch self {
        case .primary: return "Green"
        case .secondary: return "Red"
        case .accent: return "Orange"
        case .background: return "Dark"
        case .neutral: return "Gray"
        }
    }
}

struct GamePattern {
    let id = UUID()
    let targetGrid: [[TileColor]]
    let difficulty: GameDifficulty
    let moves: Int
    let description: String
}

class GameSession: ObservableObject {
    @Published var currentGrid: [[GridTile]]
    @Published var targetPattern: GamePattern
    @Published var gameState: GameState = .notStarted
    @Published var score: Int = 0
    @Published var timeRemaining: TimeInterval
    @Published var movesUsed: Int = 0
    @Published var powerUpsAvailable: [PowerUpType: Int] = [:]
    @Published var hintsUsed: Int = 0
    @Published var currentStreak: Int = 0
    
    private var timer: Timer?
    private let difficulty: GameDifficulty
    
    init(difficulty: GameDifficulty) {
        self.difficulty = difficulty
        self.timeRemaining = difficulty.timeLimit
        
        // Initialize power-ups based on difficulty
        switch difficulty {
        case .easy:
            powerUpsAvailable = [.timeBoost: 3, .hintReveal: 5, .colorMatch: 2, .gridClear: 1]
        case .medium:
            powerUpsAvailable = [.timeBoost: 2, .hintReveal: 3, .colorMatch: 2, .gridClear: 1]
        case .hard:
            powerUpsAvailable = [.timeBoost: 1, .hintReveal: 2, .colorMatch: 1, .gridClear: 0]
        case .expert:
            powerUpsAvailable = [.timeBoost: 1, .hintReveal: 1, .colorMatch: 0, .gridClear: 0]
        }
        
        // Generate random pattern
        self.targetPattern = GameSession.generateRandomPattern(for: difficulty)
        
        // Initialize grid
        self.currentGrid = GameSession.createEmptyGrid(size: difficulty.gridSize)
    }
    
    static func generateRandomPattern(for difficulty: GameDifficulty) -> GamePattern {
        let size = difficulty.gridSize
        var pattern: [[TileColor]] = []
        
        for _ in 0..<size {
            var row: [TileColor] = []
            for _ in 0..<size {
                // Create interesting patterns with higher probability for primary colors
                let random = Double.random(in: 0...1)
                if random < 0.4 {
                    row.append(.primary)
                } else if random < 0.7 {
                    row.append(.secondary)
                } else if random < 0.85 {
                    row.append(.accent)
                } else {
                    row.append(.neutral)
                }
            }
            pattern.append(row)
        }
        
        let maxMoves = Int(Double(size * size) * 1.5)
        let description = "Create the target pattern using color transformations"
        
        return GamePattern(targetGrid: pattern, difficulty: difficulty, moves: maxMoves, description: description)
    }
    
    static func createEmptyGrid(size: Int) -> [[GridTile]] {
        var grid: [[GridTile]] = []
        
        for row in 0..<size {
            var gridRow: [GridTile] = []
            for col in 0..<size {
                let tile = GridTile(
                    position: GridPosition(row: row, column: col),
                    color: .background
                )
                gridRow.append(tile)
            }
            grid.append(gridRow)
        }
        
        return grid
    }
    
    func startGame() {
        gameState = .playing
        startTimer()
    }
    
    func pauseGame() {
        gameState = .paused
        timer?.invalidate()
    }
    
    func resumeGame() {
        gameState = .playing
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.endGame(success: false)
                }
            }
        }
    }
    
    func makeMove(at position: GridPosition, newColor: TileColor) {
        guard gameState == .playing else { return }
        
        currentGrid[position.row][position.column].color = newColor
        movesUsed += 1
        
        // Check if pattern is complete
        if isPatternComplete() {
            endGame(success: true)
        }
    }
    
    func usePowerUp(_ powerUp: PowerUpType) {
        guard let count = powerUpsAvailable[powerUp], count > 0 else { return }
        
        powerUpsAvailable[powerUp] = count - 1
        
        switch powerUp {
        case .timeBoost:
            timeRemaining += 15
        case .hintReveal:
            revealHint()
        case .colorMatch:
            highlightMatchingColors()
        case .gridClear:
            clearIncorrectTiles()
        }
    }
    
    private func revealHint() {
        hintsUsed += 1
        // Find first incorrect tile and mark it for hint
        for row in 0..<currentGrid.count {
            for col in 0..<currentGrid[row].count {
                let currentColor = currentGrid[row][col].color
                let targetColor = targetPattern.targetGrid[row][col]
                
                if currentColor != targetColor {
                    currentGrid[row][col].isHinted = true
                    return
                }
            }
        }
    }
    
    private func highlightMatchingColors() {
        // Implementation for color matching highlight
    }
    
    private func clearIncorrectTiles() {
        for row in 0..<currentGrid.count {
            for col in 0..<currentGrid[row].count {
                let currentColor = currentGrid[row][col].color
                let targetColor = targetPattern.targetGrid[row][col]
                
                if currentColor != targetColor && currentColor != .background {
                    currentGrid[row][col].color = .background
                }
            }
        }
    }
    
    private func isPatternComplete() -> Bool {
        for row in 0..<currentGrid.count {
            for col in 0..<currentGrid[row].count {
                let currentColor = currentGrid[row][col].color
                let targetColor = targetPattern.targetGrid[row][col]
                
                if currentColor != targetColor {
                    return false
                }
            }
        }
        return true
    }
    
    private func endGame(success: Bool) {
        timer?.invalidate()
        gameState = success ? .completed : .failed
        
        if success {
            calculateScore()
            currentStreak += 1
        } else {
            currentStreak = 0
        }
    }
    
    private func calculateScore() {
        let baseScore = difficulty.gridSize * difficulty.gridSize * 10
        let timeBonus = Int(timeRemaining) * 2
        let moveBonus = max(0, (targetPattern.moves - movesUsed) * 5)
        let hintPenalty = hintsUsed * 10
        let streakBonus = currentStreak * 50
        
        score = baseScore + timeBonus + moveBonus - hintPenalty + streakBonus
    }
    
    deinit {
        timer?.invalidate()
    }
}

