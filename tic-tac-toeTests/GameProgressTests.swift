import Foundation
import Testing
@testable import tic_tac_toe

// EN: Persistence rules for stats, streaks, theme unlocks, and saved game settings.
// RU: Правила сохранения статистики, серий, разблокировок тем и настроек игры.

struct GameProgressTests {

    @Test func applyVsAIOutcome_winUnlocksAurora() {
        var p = GameProgress()
        p.applyVsAIOutcome(humanWon: true)
        #expect(p.winsVsAI == 1)
        #expect(p.currentWinStreak == 1)
        #expect(p.unlockedThemes.contains(.aurora))
    }

    @Test func applyVsAIOutcome_fiveWinsUnlocksGrove() {
        var p = GameProgress()
        for _ in 0..<5 { p.applyVsAIOutcome(humanWon: true) }
        #expect(p.unlockedThemes.contains(.grove))
    }

    @Test func applyVsAIOutcome_streakThreeUnlocksEmber() {
        var p = GameProgress()
        for _ in 0..<3 { p.applyVsAIOutcome(humanWon: true) }
        #expect(p.bestWinStreak == 3)
        #expect(p.unlockedThemes.contains(.ember))
    }

    @Test func applyVsAIOutcome_lossResetsStreak() {
        var p = GameProgress(winsVsAI: 2, currentWinStreak: 2, bestWinStreak: 2)
        p.applyVsAIOutcome(humanWon: false)
        #expect(p.lossesVsAI == 1)
        #expect(p.currentWinStreak == 0)
    }

    @Test func applyVsAIOutcome_drawResetsStreak() {
        var p = GameProgress(currentWinStreak: 2)
        p.applyVsAIOutcome(humanWon: nil)
        #expect(p.drawsVsAI == 1)
        #expect(p.currentWinStreak == 0)
    }

    @Test func setBoardSize_clampsWinLength() {
        var p = GameProgress(boardSize: 6, winLength: 6)
        p.setBoardSize(4)
        #expect(p.boardSize == 4)
        #expect(p.winLength == 4)
    }

    @Test func roundTripCodable_preservesSettings() throws {
        var original = GameProgress()
        original.opponentMode = .humanComputer
        original.boardSize = 5
        original.winLength = 4
        original.setHumanPlayer(.o)
        original.aiDifficulty = .hard
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GameProgress.self, from: data)
        #expect(decoded == original)
    }
}
