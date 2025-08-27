//
//  DataService.swift
//  PixelPlay Avi
//
//  Created by Вячеслав on 8/26/25.
//

import Foundation
import CoreData

enum CoreDataError: Error {
    case entityNotFound(String)
    case saveFailed(Error)
    case fetchFailed(Error)
}

class DataService: ObservableObject {
    static let shared = DataService()
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PixelPlayModel")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    // MARK: - Core Data Operations
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    func saveContext() throws {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                throw CoreDataError.saveFailed(error)
            }
        }
    }
    
    func delete<T: NSManagedObject>(_ object: T) {
        context.delete(object)
        save()
    }
    
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> [T] {
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch: \(error)")
            return []
        }
    }
    
    // MARK: - User Profile Operations
    func saveUserProfile(_ profile: UserProfile) {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        let existingProfiles = fetch(request)
        
        let userEntity: UserProfileEntity
        if let existing = existingProfiles.first {
            userEntity = existing
        } else {
            userEntity = UserProfileEntity(context: context)
        }
        
        userEntity.username = profile.username
        userEntity.selectedTheme = profile.selectedTheme.rawValue
        userEntity.soundSettings = profile.soundSettings.rawValue
        userEntity.notificationSettings = profile.notificationSettings.rawValue
        userEntity.hasCompletedOnboarding = profile.hasCompletedOnboarding
        userEntity.preferredDifficulty = profile.preferredDifficulty.rawValue
        userEntity.enableHapticFeedback = profile.enableHapticFeedback
        userEntity.enableAnimations = profile.enableAnimations
        userEntity.autoSaveProgress = profile.autoSaveProgress
        
        // Save statistics
        userEntity.totalGamesPlayed = Int32(profile.statistics.totalGamesPlayed)
        userEntity.totalGamesWon = Int32(profile.statistics.totalGamesWon)
        userEntity.totalTimePlayed = profile.statistics.totalTimePlayed
        userEntity.bestScore = Int32(profile.statistics.bestScore)
        userEntity.currentStreak = Int32(profile.statistics.currentStreak)
        userEntity.longestStreak = Int32(profile.statistics.longestStreak)
        userEntity.averageCompletionTime = profile.statistics.averageCompletionTime
        userEntity.totalHintsUsed = Int32(profile.statistics.totalHintsUsed)
        userEntity.totalPowerUpsUsed = Int32(profile.statistics.totalPowerUpsUsed)
        userEntity.favoriteGameMode = profile.statistics.favoriteGameMode.rawValue
        userEntity.totalFocusTime = profile.statistics.totalFocusTime
        userEntity.consecutiveDaysPlayed = Int32(profile.statistics.consecutiveDaysPlayed)
        userEntity.lastPlayDate = profile.statistics.lastPlayDate
        
        save()
    }
    
    func loadUserProfile() -> UserProfile? {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        let profiles = fetch(request)
        
        guard let userEntity = profiles.first else { return nil }
        
        let profile = UserProfile()
        profile.username = userEntity.username ?? ""
        profile.selectedTheme = AppTheme(rawValue: userEntity.selectedTheme ?? "") ?? .dark
        profile.soundSettings = SoundSetting(rawValue: userEntity.soundSettings ?? "") ?? .medium
        profile.notificationSettings = NotificationSetting(rawValue: userEntity.notificationSettings ?? "") ?? .daily
        profile.hasCompletedOnboarding = userEntity.hasCompletedOnboarding
        profile.preferredDifficulty = GameDifficulty(rawValue: userEntity.preferredDifficulty ?? "") ?? .easy
        profile.enableHapticFeedback = userEntity.enableHapticFeedback
        profile.enableAnimations = userEntity.enableAnimations
        profile.autoSaveProgress = userEntity.autoSaveProgress
        
        // Load statistics
        profile.statistics.totalGamesPlayed = Int(userEntity.totalGamesPlayed)
        profile.statistics.totalGamesWon = Int(userEntity.totalGamesWon)
        profile.statistics.totalTimePlayed = userEntity.totalTimePlayed
        profile.statistics.bestScore = Int(userEntity.bestScore)
        profile.statistics.currentStreak = Int(userEntity.currentStreak)
        profile.statistics.longestStreak = Int(userEntity.longestStreak)
        profile.statistics.averageCompletionTime = userEntity.averageCompletionTime
        profile.statistics.totalHintsUsed = Int(userEntity.totalHintsUsed)
        profile.statistics.totalPowerUpsUsed = Int(userEntity.totalPowerUpsUsed)
        profile.statistics.favoriteGameMode = GameDifficulty(rawValue: userEntity.favoriteGameMode ?? "") ?? .easy
        profile.statistics.totalFocusTime = userEntity.totalFocusTime
        profile.statistics.consecutiveDaysPlayed = Int(userEntity.consecutiveDaysPlayed)
        profile.statistics.lastPlayDate = userEntity.lastPlayDate
        
        // Load achievements
        profile.achievements = loadAchievements()
        
        // Load focus history
        profile.focusHistory = loadFocusHistory()
        
        return profile
    }
    
    // MARK: - Achievement Operations
    func saveAchievement(_ achievement: Achievement) {
        let achievementEntity = AchievementEntity(context: context)
        achievementEntity.id = achievement.id
        achievementEntity.type = achievement.type.rawValue
        achievementEntity.unlockedDate = achievement.unlockedDate
        achievementEntity.progress = achievement.progress
        
        save()
    }
    
    func loadAchievements() -> [Achievement] {
        let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        let achievementEntities = fetch(request)
        
        return achievementEntities.compactMap { entity in
            guard let typeString = entity.type,
                  let type = AchievementType(rawValue: typeString) else { return nil }
            
            return Achievement(
                type: type,
                unlockedDate: entity.unlockedDate,
                progress: entity.progress
            )
        }
    }
    
    func updateAchievementProgress(_ achievementType: AchievementType, progress: Double, unlocked: Bool = false) {
        let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", achievementType.rawValue)
        
        let entities = fetch(request)
        let entity: AchievementEntity
        
        if let existing = entities.first {
            entity = existing
        } else {
            entity = AchievementEntity(context: context)
            entity.id = UUID()
            entity.type = achievementType.rawValue
        }
        
        entity.progress = progress
        if unlocked && entity.unlockedDate == nil {
            entity.unlockedDate = Date()
        }
        
        save()
    }
    
    // MARK: - Game Session Operations
    func saveGameSession(_ session: GameSession) throws {
        // Ensure the persistent container is loaded
        _ = persistentContainer
        
        // Validate context
        guard !context.isKind(of: NSNull.self) else {
            throw CoreDataError.saveFailed(NSError(domain: "DataService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Context is nil"]))
        }
        
        // Try to get entity description
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "GameSessionEntity", in: context) else {
            print("Available entities: \(persistentContainer.managedObjectModel.entities.map { $0.name ?? "Unknown" })")
            throw CoreDataError.entityNotFound("GameSessionEntity not found in model")
        }
        
        let sessionEntity = GameSessionEntity(entity: entityDescription, insertInto: context)
        sessionEntity.id = UUID()
        sessionEntity.difficulty = session.targetPattern.difficulty.rawValue
        sessionEntity.score = Int32(session.score)
        sessionEntity.timeRemaining = session.timeRemaining
        sessionEntity.movesUsed = Int32(session.movesUsed)
        sessionEntity.hintsUsed = Int32(session.hintsUsed)
        sessionEntity.gameState = session.gameState == .completed ? "completed" : "failed"
        sessionEntity.datePlayed = Date()
        sessionEntity.currentStreak = Int32(session.currentStreak)
        
        try saveContext()
    }
    
    func loadGameHistory(limit: Int = 50) -> [GameSessionEntity] {
        let request: NSFetchRequest<GameSessionEntity> = GameSessionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GameSessionEntity.datePlayed, ascending: false)]
        request.fetchLimit = limit
        
        return fetch(request)
    }
    
    // MARK: - Focus Session Operations
    func saveFocusSession(_ session: FocusSession) {
        let sessionEntity = FocusSessionEntity(context: context)
        sessionEntity.id = session.id
        sessionEntity.startTime = session.startTime
        sessionEntity.duration = session.duration
        sessionEntity.sessionType = session.sessionType.rawValue
        sessionEntity.isCompleted = session.isCompleted
        sessionEntity.endTime = session.endTime
        
        save()
    }
    
    func loadFocusHistory(limit: Int = 100) -> [FocusSession] {
        let request: NSFetchRequest<FocusSessionEntity> = FocusSessionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSessionEntity.startTime, ascending: false)]
        request.fetchLimit = limit
        
        let entities = fetch(request)
        
        return entities.compactMap { entity in
            guard let startTime = entity.startTime,
                  let sessionTypeString = entity.sessionType,
                  let sessionType = FocusType(rawValue: sessionTypeString) else { return nil }
            
            return FocusSession(
                startTime: startTime,
                duration: entity.duration,
                sessionType: sessionType,
                isCompleted: entity.isCompleted,
                endTime: entity.endTime
            )
        }
    }
    
    // MARK: - Data Management
    func clearAllData() {
        let entities = ["UserProfileEntity", "AchievementEntity", "GameSessionEntity", "FocusSessionEntity"]
        
        for entityName in entities {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Failed to delete \(entityName): \(error)")
            }
        }
        
        save()
    }
    
    func exportUserData() -> [String: Any] {
        guard let profile = loadUserProfile() else { return [:] }
        
        let gameHistory = loadGameHistory()
        let focusHistory = loadFocusHistory()
        
        return [
            "profile": [
                "username": profile.username,
                "theme": profile.selectedTheme.rawValue,
                "statistics": [
                    "totalGamesPlayed": profile.statistics.totalGamesPlayed,
                    "totalGamesWon": profile.statistics.totalGamesWon,
                    "bestScore": profile.statistics.bestScore,
                    "longestStreak": profile.statistics.longestStreak,
                    "totalFocusTime": profile.statistics.totalFocusTime
                ]
            ],
            "achievements": profile.getUnlockedAchievements().map { achievement in
                [
                    "type": achievement.type.rawValue,
                    "unlockedDate": achievement.unlockedDate?.timeIntervalSince1970 ?? 0
                ]
            },
            "gameHistoryCount": gameHistory.count,
            "focusHistoryCount": focusHistory.count
        ]
    }
}

// MARK: - Core Data Entities (These would typically be generated by Core Data)

@objc(UserProfileEntity)
class UserProfileEntity: NSManagedObject {
    @NSManaged var username: String?
    @NSManaged var selectedTheme: String?
    @NSManaged var soundSettings: String?
    @NSManaged var notificationSettings: String?
    @NSManaged var hasCompletedOnboarding: Bool
    @NSManaged var preferredDifficulty: String?
    @NSManaged var enableHapticFeedback: Bool
    @NSManaged var enableAnimations: Bool
    @NSManaged var autoSaveProgress: Bool
    
    // Statistics
    @NSManaged var totalGamesPlayed: Int32
    @NSManaged var totalGamesWon: Int32
    @NSManaged var totalTimePlayed: TimeInterval
    @NSManaged var bestScore: Int32
    @NSManaged var currentStreak: Int32
    @NSManaged var longestStreak: Int32
    @NSManaged var averageCompletionTime: TimeInterval
    @NSManaged var totalHintsUsed: Int32
    @NSManaged var totalPowerUpsUsed: Int32
    @NSManaged var favoriteGameMode: String?
    @NSManaged var totalFocusTime: TimeInterval
    @NSManaged var consecutiveDaysPlayed: Int32
    @NSManaged var lastPlayDate: Date?
}

@objc(AchievementEntity)
class AchievementEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var type: String?
    @NSManaged var unlockedDate: Date?
    @NSManaged var progress: Double
}

@objc(GameSessionEntity)
class GameSessionEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var difficulty: String?
    @NSManaged var score: Int32
    @NSManaged var timeRemaining: TimeInterval
    @NSManaged var movesUsed: Int32
    @NSManaged var hintsUsed: Int32
    @NSManaged var gameState: String?
    @NSManaged var datePlayed: Date?
    @NSManaged var currentStreak: Int32
}

@objc(FocusSessionEntity)
class FocusSessionEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var startTime: Date?
    @NSManaged var duration: TimeInterval
    @NSManaged var sessionType: String?
    @NSManaged var isCompleted: Bool
    @NSManaged var endTime: Date?
}

// MARK: - Fetch Request Extensions
extension UserProfileEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<UserProfileEntity> {
        return NSFetchRequest<UserProfileEntity>(entityName: "UserProfileEntity")
    }
}

extension AchievementEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<AchievementEntity> {
        return NSFetchRequest<AchievementEntity>(entityName: "AchievementEntity")
    }
}

extension GameSessionEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<GameSessionEntity> {
        return NSFetchRequest<GameSessionEntity>(entityName: "GameSessionEntity")
    }
}

extension FocusSessionEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FocusSessionEntity> {
        return NSFetchRequest<FocusSessionEntity>(entityName: "FocusSessionEntity")
    }
}
