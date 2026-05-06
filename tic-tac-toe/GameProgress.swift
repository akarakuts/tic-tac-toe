import Foundation

// EN: Persistent stats vs AI, streaks, unlocked themes, preferred difficulty — stored in UserDefaults.
// RU: Постоянная статистика против ИИ, серии, разблокированные темы и сложность — UserDefaults.

enum AIDifficulty: Int, Codable, CaseIterable, Sendable {
    case easy
    case medium
    case hard
}

struct GameProgress: Codable, Equatable, Sendable {
    var winsVsAI: Int = 0
    var lossesVsAI: Int = 0
    var drawsVsAI: Int = 0
    /// EN: Consecutive human wins vs AI (draw or loss resets).
    /// RU: Серия побед человека над ИИ (ничья или поражение обнуляет).
    var currentWinStreak: Int = 0
    var bestWinStreak: Int = 0
    var unlockedThemes: Set<BoardVisualStyle> = [.classic]
    var selectedTheme: BoardVisualStyle = .classic
    var aiDifficulty: AIDifficulty = .medium
    /// EN: Master switch for move/win/error UI sounds.
    /// RU: Общий переключатель звуков хода/победы/ошибки.
    var soundEnabled: Bool = true

    private enum CodingKeys: String, CodingKey {
        case winsVsAI
        case lossesVsAI
        case drawsVsAI
        case currentWinStreak
        case bestWinStreak
        case unlockedThemes
        case selectedTheme
        case aiDifficulty
        case soundEnabled
    }

    init(
        winsVsAI: Int = 0,
        lossesVsAI: Int = 0,
        drawsVsAI: Int = 0,
        currentWinStreak: Int = 0,
        bestWinStreak: Int = 0,
        unlockedThemes: Set<BoardVisualStyle> = [.classic],
        selectedTheme: BoardVisualStyle = .classic,
        aiDifficulty: AIDifficulty = .medium,
        soundEnabled: Bool = true
    ) {
        self.winsVsAI = winsVsAI
        self.lossesVsAI = lossesVsAI
        self.drawsVsAI = drawsVsAI
        self.currentWinStreak = currentWinStreak
        self.bestWinStreak = bestWinStreak
        self.unlockedThemes = unlockedThemes
        self.selectedTheme = selectedTheme
        self.aiDifficulty = aiDifficulty
        self.soundEnabled = soundEnabled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        winsVsAI = try c.decodeIfPresent(Int.self, forKey: .winsVsAI) ?? 0
        lossesVsAI = try c.decodeIfPresent(Int.self, forKey: .lossesVsAI) ?? 0
        drawsVsAI = try c.decodeIfPresent(Int.self, forKey: .drawsVsAI) ?? 0
        currentWinStreak = try c.decodeIfPresent(Int.self, forKey: .currentWinStreak) ?? 0
        bestWinStreak = try c.decodeIfPresent(Int.self, forKey: .bestWinStreak) ?? 0
        unlockedThemes = try c.decodeIfPresent(Set<BoardVisualStyle>.self, forKey: .unlockedThemes) ?? [.classic]
        selectedTheme = try c.decodeIfPresent(BoardVisualStyle.self, forKey: .selectedTheme) ?? .classic
        aiDifficulty = try c.decodeIfPresent(AIDifficulty.self, forKey: .aiDifficulty) ?? .medium
        soundEnabled = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(winsVsAI, forKey: .winsVsAI)
        try c.encode(lossesVsAI, forKey: .lossesVsAI)
        try c.encode(drawsVsAI, forKey: .drawsVsAI)
        try c.encode(currentWinStreak, forKey: .currentWinStreak)
        try c.encode(bestWinStreak, forKey: .bestWinStreak)
        try c.encode(unlockedThemes, forKey: .unlockedThemes)
        try c.encode(selectedTheme, forKey: .selectedTheme)
        try c.encode(aiDifficulty, forKey: .aiDifficulty)
        try c.encode(soundEnabled, forKey: .soundEnabled)
    }

    mutating func applyVsAIOutcome(humanWon: Bool?) {
        switch humanWon {
        case .some(true):
            winsVsAI += 1
            currentWinStreak += 1
            bestWinStreak = max(bestWinStreak, currentWinStreak)
            if winsVsAI >= 1 {
                unlockedThemes.insert(.aurora)
            }
            if winsVsAI >= 5 {
                unlockedThemes.insert(.grove)
            }
            if bestWinStreak >= 3 {
                unlockedThemes.insert(.ember)
            }
        case .some(false):
            lossesVsAI += 1
            currentWinStreak = 0
        case .none:
            drawsVsAI += 1
            currentWinStreak = 0
        }
        if !unlockedThemes.contains(selectedTheme) {
            selectedTheme = .classic
        }
    }
}

enum GameProgressStore {
    private static let key = "tic_tac_toe_progress_v1"

    static func load() -> GameProgress {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return GameProgress()
        }
        do {
            return try JSONDecoder().decode(GameProgress.self, from: data)
        } catch {
            return GameProgress()
        }
    }

    static func save(_ progress: GameProgress) {
        do {
            let data = try JSONEncoder().encode(progress)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            // EN: Ignore persistence failures — gameplay stays usable.
            // RU: Игнорируем ошибки сохранения — игра остаётся рабочей.
        }
    }
}
