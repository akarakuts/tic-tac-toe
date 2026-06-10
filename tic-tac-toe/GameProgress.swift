import Foundation

// EN: Persistent stats vs AI, streaks, unlocks, preferred difficulty — stored in UserDefaults.
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
    /// EN: Last chosen opponent mode — restored on launch.
    /// RU: Последний режим соперника — восстанавливается при запуске.
    var opponentMode: OpponentMode = .humanHuman
    var boardSize: Int = 3
    var winLength: Int = 3
    /// EN: Human side in vs-computer mode (`true` = crosses).
    /// RU: Сторона человека против ИИ (`true` = крестики).
    var humanPlaysAsX: Bool = true

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
        case opponentMode
        case boardSize
        case winLength
        case humanPlaysAsX
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
        soundEnabled: Bool = true,
        opponentMode: OpponentMode = .humanHuman,
        boardSize: Int = 3,
        winLength: Int = 3,
        humanPlaysAsX: Bool = true
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
        self.opponentMode = opponentMode
        self.boardSize = Self.clampBoardSize(boardSize)
        self.winLength = Self.clampWinLength(winLength, boardSize: self.boardSize)
        self.humanPlaysAsX = humanPlaysAsX
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
        opponentMode = try c.decodeIfPresent(OpponentMode.self, forKey: .opponentMode) ?? .humanHuman
        let rawBoard = try c.decodeIfPresent(Int.self, forKey: .boardSize) ?? 3
        boardSize = Self.clampBoardSize(rawBoard)
        let rawWin = try c.decodeIfPresent(Int.self, forKey: .winLength) ?? 3
        winLength = Self.clampWinLength(rawWin, boardSize: boardSize)
        humanPlaysAsX = try c.decodeIfPresent(Bool.self, forKey: .humanPlaysAsX) ?? true
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
        try c.encode(opponentMode, forKey: .opponentMode)
        try c.encode(boardSize, forKey: .boardSize)
        try c.encode(winLength, forKey: .winLength)
        try c.encode(humanPlaysAsX, forKey: .humanPlaysAsX)
    }

    var humanPlayer: Player {
        humanPlaysAsX ? .x : .o
    }

    mutating func setHumanPlayer(_ player: Player) {
        humanPlaysAsX = player == .x
    }

    mutating func setBoardSize(_ size: Int) {
        boardSize = Self.clampBoardSize(size)
        winLength = Self.clampWinLength(winLength, boardSize: boardSize)
    }

    mutating func setWinLength(_ length: Int) {
        winLength = Self.clampWinLength(length, boardSize: boardSize)
    }

    private static func clampBoardSize(_ size: Int) -> Int {
        min(6, max(3, size))
    }

    private static func clampWinLength(_ length: Int, boardSize: Int) -> Int {
        min(boardSize, max(3, min(6, length)))
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
            #if DEBUG
            print("GameProgressStore: decode failed — \(error.localizedDescription)")
            #endif
            return GameProgress()
        }
    }

    static func save(_ progress: GameProgress) {
        do {
            let data = try JSONEncoder().encode(progress)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            #if DEBUG
            print("GameProgressStore: encode failed — \(error.localizedDescription)")
            #endif
        }
    }
}
