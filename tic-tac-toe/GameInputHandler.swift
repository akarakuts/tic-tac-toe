import SpriteKit

// EN: Maps hit-tested node names to high-level game actions — keeps input routing out of GameScene.
// RU: Преобразует имена узлов в игровые действия — маршрутизация ввода вне GameScene.

enum GameInputAction: Equatable {
    case newGame
    case setBoardSize(Int)
    case setWinLength(Int)
    case setOpponentMode(OpponentMode)
    case toggleSound
    case setAIDifficulty(AIDifficulty)
    case setHumanPlayer(Player)
    case setTheme(BoardVisualStyle)
    case playCell(row: Int, col: Int)
}

enum GameInputHandler {

    /// EN: First actionable hit from top-most nodes; nil if click is a no-op on HUD chrome.
    /// RU: Первое значимое попадание сверху вниз; nil если клик не по активному элементу.
    static func firstAction(
        from hits: [SKNode],
        boardSize: Int,
        opponentMode: OpponentMode,
        gameInProgress: Bool,
        isHumanTurn: Bool
    ) -> GameInputAction? {
        for hit in hits {
            guard let raw = hit.name else { continue }
            let name = raw.replacingOccurrences(of: "_disabled", with: "")

            if name == "newGame" { return .newGame }

            if name.hasPrefix("board_"), let s = Int(name.dropFirst(6)) {
                return .setBoardSize(s)
            }
            if name.hasPrefix("winlen_"), let k = Int(name.dropFirst(7)), k <= boardSize {
                return .setWinLength(k)
            }
            if name == "mode_human" { return .setOpponentMode(.humanHuman) }
            if name == "mode_ai" { return .setOpponentMode(.humanComputer) }
            if name == "sound_toggle" { return .toggleSound }

            if opponentMode == .humanComputer {
                if name == "ai_easy" { return .setAIDifficulty(.easy) }
                if name == "ai_medium" { return .setAIDifficulty(.medium) }
                if name == "ai_hard" { return .setAIDifficulty(.hard) }
                if name == "pick_x" { return .setHumanPlayer(.x) }
                if name == "pick_o" { return .setHumanPlayer(.o) }
            }

            if name.hasPrefix("theme_"),
               let style = BoardVisualStyle(rawValue: String(name.dropFirst(6))) {
                return .setTheme(style)
            }
        }

        guard gameInProgress, isHumanTurn else { return nil }

        for node in hits {
            guard let name = node.name,
                  let cell = GameSceneLayout.parseCellName(name) else { continue }
            return .playCell(row: cell.row, col: cell.col)
        }
        return nil
    }
}
