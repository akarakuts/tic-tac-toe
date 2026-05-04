import Foundation

// EN: Typed accessors for String Catalog keys — UI follows the system locale (EN/RU in Localizable.xcstrings).
// RU: Типизированный доступ к ключам String Catalog — интерфейс следует языку системы (EN/RU в Localizable.xcstrings).

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
}
