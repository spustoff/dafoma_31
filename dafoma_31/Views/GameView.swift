//
//  GameView.swift
//  PixelAvi Play
//
//  Created by Вячеслав on 8/26/25.
//

import SwiftUI

struct GameView: View {
    @ObservedObject var gameViewModel: GameViewModel
    @EnvironmentObject var userProfile: UserProfile
    @State private var showingDifficultySelection = false
    @State private var showingGameMenu = false
    @State private var selectedColor: TileColor = .primary
    @State private var showingColorPicker = false
    
    init(gameViewModel: GameViewModel) {
        self.gameViewModel = gameViewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(hex: userProfile.selectedTheme.backgroundColor)
                    .ignoresSafeArea()
                
                if gameViewModel.isGameActive {
                    gameplayView
                } else {
                    gameMenuView
                }
                
                // Overlays
                if gameViewModel.showingPauseMenu {
                    pauseMenuOverlay
                }
                
                if gameViewModel.showingGameOver {
                    gameOverOverlay
                }
                
                if gameViewModel.showingPowerUpMenu {
                    powerUpMenuOverlay
                }
                
                if gameViewModel.showingAchievementUnlock {
                    achievementUnlockOverlay
                }
            }
        }
        .navigationBarHidden(gameViewModel.isGameActive)
        .sheet(isPresented: $showingDifficultySelection) {
            DifficultySelectionView(gameViewModel: gameViewModel)
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerView(selectedColor: $selectedColor, gameViewModel: gameViewModel)
        }
    }
    
    // MARK: - Game Menu View
    private var gameMenuView: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "grid.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: userProfile.selectedTheme.primaryColor))
                
                Text("PixelAvi Play")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Match patterns, beat the clock!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Quick Stats
            HStack(spacing: 30) {
                StatCard(
                    title: "Best Score",
                    value: "\(userProfile.statistics.bestScore)",
                    icon: "trophy.fill",
                    color: userProfile.selectedTheme.primaryColor
                )
                
                StatCard(
                    title: "Win Streak",
                    value: "\(userProfile.statistics.currentStreak)",
                    icon: "flame.fill",
                    color: userProfile.selectedTheme.secondaryColor
                )
                
                StatCard(
                    title: "Games Won",
                    value: "\(userProfile.statistics.totalGamesWon)",
                    icon: "checkmark.circle.fill",
                    color: userProfile.selectedTheme.accentColor
                )
            }
            
            // Main Menu Buttons
            VStack(spacing: 16) {
                MenuButton(
                    title: "Quick Play",
                    subtitle: "Start with your preferred difficulty",
                    icon: "play.fill",
                    color: userProfile.selectedTheme.primaryColor
                ) {
                    gameViewModel.startNewGame(difficulty: userProfile.preferredDifficulty)
                }
                
                MenuButton(
                    title: "Select Difficulty",
                    subtitle: "Choose your challenge level",
                    icon: "slider.horizontal.3",
                    color: userProfile.selectedTheme.secondaryColor
                ) {
                    showingDifficultySelection = true
                }
                
                MenuButton(
                    title: "View Progress",
                    subtitle: "Check achievements and stats",
                    icon: "chart.bar.fill",
                    color: userProfile.selectedTheme.accentColor
                ) {
                    // Navigate to progress view
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.top, 50)
    }
    
    // MARK: - Gameplay View
    private var gameplayView: some View {
        VStack(spacing: 16) {
            // Top HUD
            gameHUD
            
            // Target Pattern
            targetPatternView
            
            // Game Grid
            gameGridView
            
            // Color Palette
            colorPaletteView
            
            // Bottom Controls
            gameControlsView
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 5)
    }
    

    
    // MARK: - Game HUD
    private var gameHUD: some View {
        HStack {
            // Timer
            VStack(alignment: .leading, spacing: 6) {
                Text("TIME")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(gameViewModel.getFormattedTime())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(gameViewModel.currentSession?.timeRemaining ?? 0 < 30 ? Color(hex: "#e6053a") : .white)
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .center, spacing: 6) {
                Text("SCORE")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("\(gameViewModel.currentSession?.score ?? 0)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Moves
            VStack(alignment: .trailing, spacing: 6) {
                Text("MOVES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("\(gameViewModel.currentSession?.movesUsed ?? 0)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Target Pattern View
    private var targetPatternView: some View {
        VStack(spacing: 12) {
            Text("TARGET PATTERN")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let session = gameViewModel.currentSession {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: session.targetPattern.targetGrid.count), spacing: 3) {
                    ForEach(0..<session.targetPattern.targetGrid.count, id: \.self) { row in
                        ForEach(0..<session.targetPattern.targetGrid[row].count, id: \.self) { col in
                            Rectangle()
                                .fill(Color(hex: session.targetPattern.targetGrid[row][col].rawValue))
                                .aspectRatio(1, contentMode: .fit)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
                .frame(maxWidth: 160, maxHeight: 160)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Game Grid View
    private var gameGridView: some View {
        VStack(spacing: 12) {
            Text("YOUR GRID")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let session = gameViewModel.currentSession {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: session.currentGrid.count), spacing: 6) {
                    ForEach(0..<session.currentGrid.count, id: \.self) { row in
                        ForEach(0..<session.currentGrid[row].count, id: \.self) { col in
                            GameTileView(
                                position: GridPosition(row: row, column: col),
                                gameViewModel: gameViewModel,
                                selectedColor: selectedColor,
                                isSelected: gameViewModel.selectedTilePosition == GridPosition(row: row, column: col),
                                showingColorPicker: $showingColorPicker
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Color Palette View
    private var colorPaletteView: some View {
        VStack(spacing: 12) {
            Text("COLORS")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                ForEach(gameViewModel.availableColors, id: \.self) { color in
                    Button(action: {
                        selectedColor = color
                        if let position = gameViewModel.selectedTilePosition {
                            gameViewModel.applyColor(color, to: position)
                        }
                    }) {
                        Circle()
                            .fill(Color(hex: color.rawValue))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.white : Color.white.opacity(0.3), lineWidth: selectedColor == color ? 4 : 2)
                            )
                            .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                            .shadow(color: selectedColor == color ? Color.white.opacity(0.3) : Color.clear, radius: 8)
                            .animation(.easeInOut(duration: 0.2), value: selectedColor)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Game Controls View
    private var gameControlsView: some View {
        HStack(spacing: 20) {
            // Pause Button
            Button(action: {
                gameViewModel.pauseGame()
            }) {
                Image(systemName: "pause.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Hint Button
            Button(action: {
                gameViewModel.useHint()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.title3)
                    Text("Hint")
                        .font(.caption)
                }
                .foregroundColor(Color(hex: "#d17305"))
                .frame(width: 60, height: 50)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
            }
            .disabled((gameViewModel.currentSession?.powerUpsAvailable[.hintReveal] ?? 0) <= 0)
            
            // Power-ups Button
            Button(action: {
                gameViewModel.showingPowerUpMenu = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "wand.and.rays")
                        .font(.title3)
                    Text("Power")
                        .font(.caption)
                }
                .foregroundColor(Color(hex: "#28a809"))
                .frame(width: 60, height: 50)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Progress Indicator
            CircularProgressView(progress: gameViewModel.getCompletionPercentage())
                .frame(width: 50, height: 50)
        }
        .padding(.horizontal, 10)
    }
    
    // MARK: - Overlays
    private var pauseMenuOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    gameViewModel.resumeGame()
                }
            
            VStack(spacing: 20) {
                Text("Game Paused")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    Button("Resume") {
                        gameViewModel.resumeGame()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("New Game") {
                        gameViewModel.endGame()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Main Menu") {
                        gameViewModel.endGame()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.9))
            )
        }
    }
    
    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text(gameViewModel.gameOverMessage)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if let session = gameViewModel.currentSession {
                    VStack(spacing: 8) {
                        Text("Final Score: \(session.score)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Time: \(gameViewModel.getFormattedTime())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Moves: \(session.movesUsed)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(spacing: 12) {
                    Button("Play Again") {
                        gameViewModel.startNewGame(difficulty: gameViewModel.selectedDifficulty)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Main Menu") {
                        gameViewModel.endGame()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.9))
            )
        }
    }
    
    private var powerUpMenuOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    gameViewModel.showingPowerUpMenu = false
                }
            
            VStack(spacing: 16) {
                Text("Power-Ups")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                ForEach(PowerUpType.allCases, id: \.self) { powerUp in
                    PowerUpRow(
                        powerUp: powerUp,
                        available: gameViewModel.currentSession?.powerUpsAvailable[powerUp] ?? 0,
                        onUse: {
                            gameViewModel.usePowerUp(powerUp)
                        }
                    )
                }
                
                Button("Close") {
                    gameViewModel.showingPowerUpMenu = false
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.9))
            )
        }
    }
    
    private var achievementUnlockOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "#d17305"))
            
            Text("Achievement Unlocked!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let achievement = gameViewModel.unlockedAchievement {
                VStack(spacing: 8) {
                    Text(achievement.type.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(achievement.type.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.9))
        )
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Supporting Views

struct GameTileView: View {
    let position: GridPosition
    let gameViewModel: GameViewModel
    let selectedColor: TileColor
    let isSelected: Bool
    @Binding var showingColorPicker: Bool
    
    var body: some View {
        let currentColor = gameViewModel.getTileColor(at: position)
        let targetColor = gameViewModel.getTargetColor(at: position)
        let isCorrect = gameViewModel.isTileCorrect(at: position)
        let isHinted = gameViewModel.isTileHinted(at: position)
        
        Button(action: {
            if isSelected {
                gameViewModel.applyColor(selectedColor, to: position)
            } else {
                gameViewModel.selectTile(at: position)
            }
        }) {
            Rectangle()
                .fill(Color(hex: currentColor.rawValue))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelected ? Color.white :
                            isCorrect ? Color(hex: "#28a809") :
                            isHinted ? Color(hex: "#d17305") : Color.white.opacity(0.2),
                            lineWidth: isSelected ? 4 : (isCorrect || isHinted) ? 3 : 1
                        )
                )
                .cornerRadius(10)
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .shadow(color: isSelected ? Color.white.opacity(0.3) : Color.clear, radius: 8)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

struct StatCard: View {
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
                .fill(Color.black.opacity(0.2))
        )
    }
}

struct MenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: color))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.2))
            )
        }
    }
}

struct PowerUpRow: View {
    let powerUp: PowerUpType
    let available: Int
    let onUse: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: powerUp.icon)
                .font(.title3)
                .foregroundColor(Color(hex: "#28a809"))
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(powerUp.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(powerUp.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(available)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Use") {
                onUse()
            }
            .buttonStyle(CompactButtonStyle())
            .disabled(available <= 0)
        }
        .padding(.vertical, 8)
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color(hex: "#28a809"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(hex: "#28a809"))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct CompactButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: "#28a809"))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Additional Views

struct DifficultySelectionView: View {
    let gameViewModel: GameViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Difficulty")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                ForEach(GameDifficulty.allCases, id: \.self) { difficulty in
                    DifficultyCard(difficulty: difficulty) {
                        gameViewModel.startNewGame(difficulty: difficulty)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct DifficultyCard: View {
    let difficulty: GameDifficulty
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(difficulty.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(difficulty.gridSize)×\(difficulty.gridSize)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("\(Int(difficulty.timeLimit))s", systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.2))
            )
        }
    }
}

struct ColorPickerView: View {
    @Binding var selectedColor: TileColor
    let gameViewModel: GameViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Color")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                    ForEach(gameViewModel.availableColors, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: color.rawValue))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 4)
                                    )
                                
                                Text(color.displayName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.2))
                            )
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    GameView(gameViewModel: GameViewModel())
        .environmentObject(UserProfile())
}
