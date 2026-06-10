import AppKit

// EN: VoiceOver announcements and SKView accessibility summary for the SpriteKit scene.
// RU: Озвучивание VoiceOver и accessibility-описание SKView для SpriteKit-сцены.

enum GameAccessibility {

    static func announce(_ text: String) {
        guard !text.isEmpty else { return }
        NSAccessibility.post(
            element: NSApp.mainWindow as Any?,
            notification: .announcementRequested,
            userInfo: [.announcement: text, .priority: NSAccessibilityPriorityLevel.high.rawValue]
        )
    }

    static func cellLabel(row: Int, col: Int, cell: Cell, boardSize: Int) -> String {
        let pos = String(format: L10n.accessibilityCellPosition, row + 1, col + 1, boardSize)
        let state: String = switch cell {
        case .empty: L10n.accessibilityCellEmpty
        case .occupied(.x): L10n.accessibilityCellCross
        case .occupied(.o): L10n.accessibilityCellNought
        }
        return "\(pos), \(state)"
    }

    static func boardSummary(
        statusText: String,
        boardSize: Int,
        focusedRow: Int,
        focusedCol: Int
    ) -> String {
        let focus = String(format: L10n.accessibilityFocus, focusedRow + 1, focusedCol + 1)
        return "\(statusText). \(focus)"
    }
}
