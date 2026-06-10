import CoreGraphics

// EN: Shared z-ordering and cell naming for SpriteKit board nodes.
// RU: Общий порядок слоёв и имена узлов клеток для SpriteKit-доски.

enum GameSceneLayer {
    static let backdropDecor: CGFloat = -40
    static let boardShadow: CGFloat = -15
    static let boardPlaque: CGFloat = -8
    static let grid: CGFloat = 0
    static let cellHit: CGFloat = 10
    static let mark: CGFloat = 20
    static let focusRing: CGFloat = 25
    static let winLine: CGFloat = 35
    static let panelBackdrop: CGFloat = 40
    static let hud: CGFloat = 100
}

enum GameSceneLayout {
    static func cellKey(row: Int, col: Int) -> String {
        "cell_\(row)_\(col)"
    }

    static func parseCellName(_ name: String) -> (row: Int, col: Int)? {
        guard name.hasPrefix("cell_") else { return nil }
        let parts = name.dropFirst(5).split(separator: "_")
        guard parts.count == 2,
              let row = Int(parts[0]),
              let col = Int(parts[1]) else { return nil }
        return (row, col)
    }
}
