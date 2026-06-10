import SpriteKit

// EN: Builds the square board grid — plaque, lines, checker cells, and mark labels.
// RU: Собирает квадратную доску — подложку, линии, клетки и метки символов.

struct BoardBuildResult {
    let grid: SKNode
    let cellNodes: [String: SKNode]
    let markNodes: [String: SKLabelNode]
    let halfBoard: CGFloat
    let cellSide: CGFloat
}

enum BoardRenderer {

    static func build(
        boardSize n: Int,
        boardSide: CGFloat,
        center: CGPoint,
        palette: BoardPalette
    ) -> BoardBuildResult {
        let cellSide = boardSide / CGFloat(n)
        let halfBoard = boardSide / 2

        let grid = SKNode()
        grid.position = center
        grid.zPosition = GameSceneLayer.grid

        let plaquePad: CGFloat = 18
        let shadow = SKShapeNode(rectOf: CGSize(width: boardSide + plaquePad + 8, height: boardSide + plaquePad + 8), cornerRadius: 18)
        shadow.fillColor = palette.boardShadow
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: -5, y: -7)
        shadow.zPosition = GameSceneLayer.boardShadow
        grid.addChild(shadow)

        let plaque = SKShapeNode(rectOf: CGSize(width: boardSide + plaquePad, height: boardSide + plaquePad), cornerRadius: 16)
        plaque.fillColor = palette.boardPlaqueFill
        plaque.strokeColor = palette.boardPlaqueStroke
        plaque.lineWidth = 2
        plaque.zPosition = GameSceneLayer.boardPlaque
        grid.addChild(plaque)

        let lineColor = palette.gridLine
        let lineWidth = max(1.5, boardSide * 0.004)

        for i in 1..<n {
            let offset = -halfBoard + CGFloat(i) * cellSide
            addLine(on: grid, from: CGPoint(x: offset, y: -halfBoard), to: CGPoint(x: offset, y: halfBoard), color: lineColor, width: lineWidth)
            addLine(on: grid, from: CGPoint(x: -halfBoard, y: offset), to: CGPoint(x: halfBoard, y: offset), color: lineColor, width: lineWidth)
        }

        let outer = SKShapeNode(rectOf: CGSize(width: boardSide, height: boardSide))
        outer.strokeColor = palette.gridOuter
        outer.lineWidth = max(lineWidth * 1.35, 2)
        outer.fillColor = .clear
        grid.addChild(outer)

        let inset = max(1, cellSide * 0.06)
        let markScale = min(0.62, 2.7 / CGFloat(n))
        var cellNodes: [String: SKNode] = [:]
        var markNodes: [String: SKLabelNode] = [:]

        for row in 0..<n {
            for col in 0..<n {
                let checker = (row + col) % 2 == 0
                let cellTint = checker ? palette.cellEven : palette.cellOdd
                let node = SKSpriteNode(color: cellTint, size: CGSize(width: cellSide - inset * 2, height: cellSide - inset * 2))
                let cx = -halfBoard + cellSide * (CGFloat(col) + 0.5)
                let cy = -halfBoard + cellSide * (CGFloat(row) + 0.5)
                node.position = CGPoint(x: cx, y: cy)
                let key = GameSceneLayout.cellKey(row: row, col: col)
                node.name = key
                node.zPosition = GameSceneLayer.cellHit
                grid.addChild(node)
                cellNodes[key] = node

                let mark = SKLabelNode(fontNamed: ".AppleSystemUIFontBold")
                mark.fontSize = cellSide * markScale
                mark.fontColor = palette.statusText
                mark.verticalAlignmentMode = .center
                mark.horizontalAlignmentMode = .center
                mark.position = CGPoint(x: cx, y: cy)
                mark.zPosition = GameSceneLayer.mark
                mark.text = ""
                grid.addChild(mark)
                markNodes[key] = mark
            }
        }

        return BoardBuildResult(
            grid: grid,
            cellNodes: cellNodes,
            markNodes: markNodes,
            halfBoard: halfBoard,
            cellSide: cellSide
        )
    }

    private static func addLine(on grid: SKNode, from: CGPoint, to: CGPoint, color: SKColor, width: CGFloat) {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        let shape = SKShapeNode(path: path)
        shape.strokeColor = color
        shape.lineWidth = width
        shape.lineCap = .round
        grid.addChild(shape)
    }
}
