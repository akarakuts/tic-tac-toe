import AppKit
import SpriteKit

// EN: Keyboard focus navigation and VoiceOver integration for the SpriteKit board.
// RU: Клавиатурная навигация и VoiceOver для SpriteKit-доски.

extension GameScene {

    func refreshFocusRing() {
        focusRingNode?.removeFromParent()
        focusRingNode = nil
        guard boardGrid != nil, boardCellSide > 0 else { return }

        let n = game.boardSize
        keyboardFocusRow = min(max(0, keyboardFocusRow), n - 1)
        keyboardFocusCol = min(max(0, keyboardFocusCol), n - 1)

        let cx = -boardHalfBoard + boardCellSide * (CGFloat(keyboardFocusCol) + 0.5)
        let cy = -boardHalfBoard + boardCellSide * (CGFloat(keyboardFocusRow) + 0.5)
        let pad = max(2, boardCellSide * 0.08)
        let ring = SKShapeNode(rectOf: CGSize(width: boardCellSide - pad, height: boardCellSide - pad), cornerRadius: max(4, boardCellSide * 0.12))
        ring.strokeColor = palette.pillStrokeSelected
        ring.lineWidth = max(2, boardCellSide * 0.04)
        ring.fillColor = .clear
        ring.position = CGPoint(x: cx, y: cy)
        ring.zPosition = GameSceneLayer.focusRing
        ring.alpha = 0.92
        boardGrid.addChild(ring)
        focusRingNode = ring
    }

    func updateAccessibilitySummary() {
        let status = statusLabel.text ?? ""
        view?.setAccessibilityElement(true)
        view?.setAccessibilityLabel(
            GameAccessibility.boardSummary(
                statusText: status,
                boardSize: game.boardSize,
                focusedRow: keyboardFocusRow,
                focusedCol: keyboardFocusCol
            )
        )
        view?.setAccessibilityHelp(L10n.accessibilityKeyboardHelp)
    }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers?.lowercased() == "n" {
            restartRound()
            GameAccessibility.announce(L10n.newGame)
            return
        }

        guard game.outcome() == .inProgress else { return }

        switch event.keyCode {
        case 123: moveFocus(dRow: 0, dCol: -1)
        case 124: moveFocus(dRow: 0, dCol: 1)
        case 125: moveFocus(dRow: -1, dCol: 0)
        case 126: moveFocus(dRow: 1, dCol: 0)
        case 36, 49: playFocusedCell()
        default:
            super.keyDown(with: event)
        }
    }

    private func moveFocus(dRow: Int, dCol: Int) {
        keyboardFocusRow += dRow
        keyboardFocusCol += dCol
        refreshFocusRing()
        let cell = game.cell(at: keyboardFocusRow, col: keyboardFocusCol)
        GameAccessibility.announce(
            GameAccessibility.cellLabel(row: keyboardFocusRow, col: keyboardFocusCol, cell: cell, boardSize: game.boardSize)
        )
        updateAccessibilitySummary()
    }

    private func playFocusedCell() {
        performMove(row: keyboardFocusRow, col: keyboardFocusCol)
    }
}
