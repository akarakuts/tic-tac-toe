import Foundation

// EN: Typed accessors for String Catalog keys — UI follows the system locale (see Localizable.xcstrings).
// RU: Типизированный доступ к ключам String Catalog — интерфейс следует языку системы (см. Localizable.xcstrings).

enum L10n {
    static var newGame: String { String(localized: "game.button.new_game") }
    static var modeTwoPlayers: String { String(localized: "game.mode.two_players") }
    static var modeVsComputer: String { String(localized: "game.mode.vs_computer") }
    static var sideCrosses: String { String(localized: "game.side.crosses") }
    static var sideNoughts: String { String(localized: "game.side.noughts") }
    static var draw: String { String(localized: "game.draw") }

    static var turnCrosses: String { String(localized: "game.turn.crosses") }
    static var turnNoughts: String { String(localized: "game.turn.noughts") }
    static var yourTurnCrosses: String { String(localized: "game.turn.your.crosses") }
    static var yourTurnNoughts: String { String(localized: "game.turn.your.noughts") }
    static var computerTurnCrosses: String { String(localized: "game.turn.computer.crosses") }
    static var computerTurnNoughts: String { String(localized: "game.turn.computer.noughts") }
    static var turnOnlyCrosses: String { String(localized: "game.turn.only.crosses") }
    static var turnOnlyNoughts: String { String(localized: "game.turn.only.noughts") }

    static var winCrosses: String { String(localized: "game.win.crosses") }
    static var winNoughts: String { String(localized: "game.win.noughts") }
    static var winYou: String { String(localized: "game.win.you") }
    static var winComputer: String { String(localized: "game.win.computer") }

    static var settingsBoard: String { String(localized: "game.settings.board") }
    static var settingsWinLine: String { String(localized: "game.settings.win_line") }

    static var settingsAiDifficulty: String { String(localized: "game.settings.ai_difficulty") }
    static var aiEasy: String { String(localized: "game.ai.easy") }
    static var aiMedium: String { String(localized: "game.ai.medium") }
    static var aiHard: String { String(localized: "game.ai.hard") }

    static var settingsTheme: String { String(localized: "game.settings.theme") }
    static var themeClassic: String { String(localized: "game.theme.classic") }
    static var themeAurora: String { String(localized: "game.theme.aurora") }
    static var themeGrove: String { String(localized: "game.theme.grove") }
    static var themeEmber: String { String(localized: "game.theme.ember") }
    static var themeLockedBadge: String { String(localized: "game.theme.locked_badge") }

    static var statsVsAI: String { String(localized: "game.stats.vs_ai") }
    static var statsStreak: String { String(localized: "game.stats.streak") }
    static var statsBest: String { String(localized: "game.stats.best") }

    static func statsLine(wins: Int, losses: Int, draws: Int, streak: Int, best: Int) -> String {
        "\(statsVsAI) \(wins)-\(losses)-\(draws)  \(statsStreak) \(streak) (\(statsBest) \(best))"
    }

    static var soundOn: String { String(localized: "game.sound.on") }
    static var soundOff: String { String(localized: "game.sound.off") }

    static var themeUnlockIntro: String { String(localized: "game.theme.unlock.intro") }
    static var themeUnlockDetails: String { String(localized: "game.theme.unlock.details") }
}
