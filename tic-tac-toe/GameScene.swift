import AppKit
import SpriteKit

// EN: Main SpriteKit scene — themed HUD, responsive board layout, mouse input, async AI moves, win/draw FX.
// RU: Основная SpriteKit-сцена — темизированный HUD, адаптивное поле, мышь, асинхронный ход ИИ, эффекты победы/ничьей.

/// EN: Node stacking order (higher z draws on top).
/// RU: Порядок слоёв узлов (больший z рисуется поверх).
private enum Layer {
    static let boardShadow: CGFloat = -15
    static let boardPlaque: CGFloat = -8
    static let grid: CGFloat = 0
    static let cellHit: CGFloat = 10
    static let mark: CGFloat = 20
    static let winLine: CGFloat = 35
    static let panelBackdrop: CGFloat = 40
    static let hud: CGFloat = 100
}

/// EN: All colours/fonts tones for dark vs light `effectiveAppearance`, blended with system `accent`.
/// RU: Все цвета/тон для тёмной и светлой `effectiveAppearance`, смешение с системным акцентом.
private struct BoardPalette {
    let sceneBackground: SKColor
    let panelFill: SKColor
    let panelStroke: SKColor
    let boardShadow: SKColor
    let boardPlaqueFill: SKColor
    let boardPlaqueStroke: SKColor
    let cellEven: SKColor
    let cellOdd: SKColor
    let gridLine: SKColor
    let gridOuter: SKColor
    let crossMark: SKColor
    let noughtMark: SKColor
    let statusText: SKColor
    let captionText: SKColor
    let pillFill: SKColor
    let pillFillSelected: SKColor
    let pillStroke: SKColor
    let pillStrokeSelected: SKColor
    let pillText: SKColor
    let pillTextDisabled: SKColor
    let newGameFill: SKColor
    let newGameStroke: SKColor
    let newGameLabel: SKColor
    let winLine: SKColor

    init(darkMode: Bool, accent: NSColor) {
        // EN: Dark “cosmic boardroom” vs bright “clean paper” moods / RU: Тёмный «космический салон» vs светлый «чистая бумага»
        if darkMode {
            sceneBackground = NSColor(calibratedRed: 0.055, green: 0.065, blue: 0.12, alpha: 1)
            panelFill = NSColor(calibratedWhite: 1, alpha: 0.055)
            panelStroke = NSColor(calibratedWhite: 1, alpha: 0.11)
            boardShadow = NSColor(calibratedHue: 0.62, saturation: 0.55, brightness: 0.06, alpha: 0.55)
            boardPlaqueFill = NSColor(calibratedRed: 0.085, green: 0.095, blue: 0.16, alpha: 1)
            boardPlaqueStroke = accent.withAlphaComponent(0.42)
            cellEven = NSColor(calibratedRed: 0.13, green: 0.15, blue: 0.26, alpha: 1)
            cellOdd = NSColor(calibratedRed: 0.1, green: 0.115, blue: 0.2, alpha: 1)
            gridLine = NSColor(calibratedWhite: 1, alpha: 0.13)
            gridOuter = NSColor(calibratedWhite: 1, alpha: 0.32)
            crossMark = NSColor(calibratedRed: 1, green: 0.38, blue: 0.45, alpha: 1)
            noughtMark = NSColor(calibratedRed: 0.38, green: 0.88, blue: 0.82, alpha: 1)
            statusText = NSColor(calibratedWhite: 0.94, alpha: 1)
            captionText = NSColor(calibratedWhite: 0.52, alpha: 1)
            pillFill = NSColor(calibratedWhite: 1, alpha: 0.065)
            pillFillSelected = accent.withAlphaComponent(0.26)
            pillStroke = NSColor(calibratedWhite: 1, alpha: 0.16)
            pillStrokeSelected = accent
            pillText = NSColor(calibratedWhite: 0.93, alpha: 1)
            pillTextDisabled = NSColor(calibratedWhite: 0.36, alpha: 1)
            newGameFill = accent.withAlphaComponent(0.34)
            newGameStroke = accent.withAlphaComponent(0.72)
            newGameLabel = NSColor(calibratedWhite: 0.98, alpha: 1)
            winLine = NSColor(calibratedRed: 1, green: 0.82, blue: 0.28, alpha: 1)
        } else {
            sceneBackground = NSColor(calibratedRed: 0.92, green: 0.935, blue: 0.975, alpha: 1)
            panelFill = NSColor(calibratedWhite: 1, alpha: 0.78)
            panelStroke = NSColor(calibratedHue: 0.58, saturation: 0.08, brightness: 0.72, alpha: 0.35)
            boardShadow = NSColor(calibratedHue: 0.58, saturation: 0.18, brightness: 0.55, alpha: 0.22)
            boardPlaqueFill = NSColor(calibratedRed: 0.985, green: 0.99, blue: 1, alpha: 1)
            boardPlaqueStroke = accent.withAlphaComponent(0.38)
            cellEven = NSColor(calibratedHue: 0.58, saturation: 0.06, brightness: 0.97, alpha: 1)
            cellOdd = NSColor(calibratedHue: 0.56, saturation: 0.05, brightness: 0.935, alpha: 1)
            gridLine = NSColor(calibratedHue: 0.55, saturation: 0.08, brightness: 0.72, alpha: 0.55)
            gridOuter = NSColor(calibratedHue: 0.55, saturation: 0.12, brightness: 0.58, alpha: 0.65)
            crossMark = NSColor(calibratedRed: 0.82, green: 0.18, blue: 0.26, alpha: 1)
            noughtMark = NSColor(calibratedRed: 0.08, green: 0.48, blue: 0.52, alpha: 1)
            statusText = NSColor(calibratedHue: 0.62, saturation: 0.35, brightness: 0.22, alpha: 1)
            captionText = NSColor(calibratedHue: 0.58, saturation: 0.06, brightness: 0.42, alpha: 1)
            pillFill = NSColor(calibratedWhite: 1, alpha: 0.92)
            pillFillSelected = accent.withAlphaComponent(0.2)
            pillStroke = NSColor(calibratedHue: 0.55, saturation: 0.06, brightness: 0.78, alpha: 0.7)
            pillStrokeSelected = accent
            pillText = NSColor(calibratedHue: 0.58, saturation: 0.28, brightness: 0.18, alpha: 1)
            pillTextDisabled = NSColor(calibratedHue: 0.55, saturation: 0.04, brightness: 0.62, alpha: 1)
            newGameFill = accent.withAlphaComponent(0.26)
            newGameStroke = accent.withAlphaComponent(0.55)
            newGameLabel = NSColor(calibratedHue: 0.58, saturation: 0.35, brightness: 0.15, alpha: 1)
            winLine = NSColor(calibratedRed: 0.95, green: 0.62, blue: 0.08, alpha: 1)
        }
    }
}

@MainActor
final class GameScene: SKScene {

    /// EN: Theme snapshot rebuilt whenever layout or system appearance-driven colours refresh.
    /// RU: Снимок темы пересобирается при смене раскладки или цветов из темы системы.
    private var palette: BoardPalette!

    // EN: Rule/UI settings kept alongside `game` so `rebuildLayout()` can reconstruct `GameModel` safely.
    // RU: Настройки правил/UI рядом с `game`, чтобы `rebuildLayout()` мог безопасно пересоздать `GameModel`.
    private var boardSize = 3
    private var winLength = 3
    private var game = GameModel(boardSize: 3, winLength: 3)

    private var opponentMode: OpponentMode = .humanHuman
    private var humanPlayer: Player = .x

    private var cellNodes: [String: SKNode] = [:]
    private var markNodes: [String: SKLabelNode] = [:]

    /// EN: Root node for grid geometry (lines, plaque, cells); positioned at board centre.
    /// RU: Корневой узел геометрии сетки (линии, подложка, клетки); позиционируется в центре доски.
    private var boardGrid: SKNode!
    /// EN: Cached half-side of square board and cell edge length — used by win-line overlay math.
    /// RU: Кэш половины стороны квадратного поля и размера ячейки — для линии победы и подсветки.
    private var boardHalfBoard: CGFloat = 0
    private var boardCellSide: CGFloat = 0

    private var winHighlightLine: SKShapeNode?

    private var statusLabel: SKLabelNode!
    private var newGameButton: SKShapeNode!

    /// EN: Ensures draw FX runs once per finished round.
    /// RU: Гарантирует однократное воспроизведение эффекта при ничьей за раунд.
    private var didPlayDrawFX = false

    /// EN: Monotonic counter so stale async AI tasks ignore outdated board/settings after user changes.
    /// RU: Монотонный счётчик: устаревшие асинхронные задачи ИИ игнорируют старое поле/настройки после действий пользователя.
    private var inputEpoch = 0
    private var aiThinkingTask: Task<Void, Never>?

    /// EN: System appearance subscription — `SKView.window` is often nil on first `didMove`, so we also listen for global changes.
    /// RU: Подписка на тему — при первом `didMove` у `SKView` часто ещё нет `window`, плюс слушаем смену темы глобально.
    private var appearanceChangeObserver: NSObjectProtocol?

    /// EN: Resolves light/dark from the window when attached, otherwise from `NSApp` (correct at cold launch).
    /// RU: Светлая/тёмная тема из окна, если оно уже есть, иначе из `NSApp` (корректно при холодном старте).
    private var isDarkInterfaceActive: Bool {
        let appearance = view?.window?.effectiveAppearance ?? NSApp.effectiveAppearance
        return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    private func installAppearanceChangeObserverIfNeeded() {
        removeAppearanceChangeObserver()
        // EN: System light/dark toggle (no public NSApplication notification; this name is stable on macOS).
        // RU: Переключение светлой/тёмной темы в настройках (стабильное имя уведомления в macOS).
        appearanceChangeObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.rebuildLayout()
            }
        }
    }

    private func removeAppearanceChangeObserver() {
        if let token = appearanceChangeObserver {
            DistributedNotificationCenter.default().removeObserver(token)
            appearanceChangeObserver = nil
        }
    }

    /// EN: Cancels in-flight AI work and invalidates pending completions tied to old epochs.
    /// RU: Отменяет текущий расчёт ИИ и делает недействительными отложенные завершения со старыми эпохами.
    private func bumpInputEpoch() {
        aiThinkingTask?.cancel()
        aiThinkingTask = nil
        inputEpoch &+= 1
    }

    override func didMove(to view: SKView) {
        // EN: Scene coordinates centred in the view — maths assume origin at middle.
        // RU: Координаты сцены по центру вида — расчёты отталкиваются от середины.
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        installAppearanceChangeObserverIfNeeded()
        rebuildLayout()
    }

    override func willMove(from view: SKView?) {
        removeAppearanceChangeObserver()
        if let view {
            super.willMove(from: view)
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if size != oldSize, size.width > 1, size.height > 1 {
            rebuildLayout()
        }
    }

    /// EN: User changed board rules — rebuild model + entire node tree from scratch.
    /// RU: Пользователь сменил правила поля — пересоздаём модель и всё дерево узлов.
    private func applyBoardConfiguration() {
        bumpInputEpoch()
        if winLength > boardSize {
            winLength = boardSize
        }
        game = GameModel(boardSize: boardSize, winLength: winLength)
        rebuildLayout()
    }

    /// EN: Full UI reconstruction — theme, left panel, board footprint, grid cells, then sync state + AI kick-off.
    /// RU: Полная пересборка UI — тема, левая панель, область доски, сетка, затем синхронизация и запуск ИИ при необходимости.
    private func rebuildLayout() {
        removeAllActions()
        removeAllChildren()
        cellNodes.removeAll()
        markNodes.removeAll()

        let darkMode = isDarkInterfaceActive
        palette = BoardPalette(darkMode: darkMode, accent: NSColor.controlAccentColor)
        backgroundColor = palette.sceneBackground

        let n = game.boardSize
        // EN: Minimum inset from scene edges / RU: Минимальный отступ от краёв сцены
        let margin = max(12, min(size.width, size.height) * 0.02)
        let panelHalfWidth: CGFloat = 86
        let panelGap: CGFloat = 16
        let panelCenterX = -size.width * 0.5 + margin + panelHalfWidth

        let panelRightEdge = panelCenterX + panelHalfWidth
        // EN: Horizontal strip reserved for the square board (right of panel + gap).
        // RU: Горизонтальная полоса под квадратную доску (справа от панели и зазора).
        let boardAreaLeft = panelRightEdge + panelGap
        let boardAreaRight = size.width * 0.5 - margin
        let availWidth = max(0, boardAreaRight - boardAreaLeft)

        let sceneTopY = size.height * 0.5 - margin
        let sceneBottomY = -size.height * 0.5 + margin
        let statusFontSize = max(14, size.height * 0.019)
        let statusLabelY = sceneTopY - statusFontSize * 0.45 - 6
        let statusBottomGap: CGFloat = 12
        // EN: Board top must stay below status headline band / RU: Верх доски не заходит в полосу статуса
        let maxBoardTop = statusLabelY - statusFontSize * 0.55 - statusBottomGap
        let verticalSpan = max(0, maxBoardTop - sceneBottomY)

        // EN: Largest axis-aligned square fitting width × vertical span / RU: Максимальный вписанный квадрат в ширину × высоту
        let boardSide = max(1, min(availWidth, verticalSpan))
        let cellSide = boardSide / CGFloat(n)
        let halfBoard = boardSide / 2
        let boardCenterX = boardAreaLeft + availWidth * 0.5
        let boardCenterY = sceneBottomY + verticalSpan * 0.5

        // EN: Frosted/wash backdrop behind left settings stack / RU: Фон под левой колонкой настроек
        let panelBackdropW = panelHalfWidth * 2 + 52
        let panelBackdropH = size.height * 0.86
        let panelBackdrop = SKShapeNode(rectOf: CGSize(width: panelBackdropW, height: panelBackdropH), cornerRadius: 22)
        panelBackdrop.fillColor = palette.panelFill
        panelBackdrop.strokeColor = palette.panelStroke
        panelBackdrop.lineWidth = 1
        panelBackdrop.position = CGPoint(x: panelCenterX, y: -size.height * 0.015)
        panelBackdrop.zPosition = Layer.panelBackdrop
        addChild(panelBackdrop)

        statusLabel = SKLabelNode(fontNamed: ".AppleSystemUIFontBold")
        statusLabel.fontSize = statusFontSize
        statusLabel.fontColor = palette.statusText
        statusLabel.position = CGPoint(x: boardCenterX, y: statusLabelY)
        statusLabel.zPosition = Layer.hud
        addChild(statusLabel)

        // EN: --- Left HUD: board size, win length, opponent mode, side vs AI, New Game ---
        // RU: --- Левый HUD: размер поля, длина линии победы, режим соперника, сторона против ИИ, Новая игра ---
        var settingsY = size.height * 0.36
        let colDX: CGFloat = 44
        let pillW: CGFloat = 76
        let pillH: CGFloat = 28
        let modePillW: CGFloat = min(168, panelHalfWidth * 2 + 8)

        func boardTitle(_ side: Int) -> String {
            "\(side)×\(side)"
        }

        addSectionCaption(x: panelCenterX, y: settingsY + 22, text: L10n.settingsBoard)
        let boardSides = [3, 4, 5, 6]
        for row in 0..<2 {
            for col in 0..<2 {
                let i = row * 2 + col
                let side = boardSides[i]
                let x = panelCenterX + (col == 0 ? -colDX : colDX)
                let y = settingsY - CGFloat(row) * (pillH + 8)
                makePill(
                    name: "board_\(side)",
                    title: boardTitle(side),
                    x: x,
                    y: y,
                    width: pillW,
                    height: pillH,
                    fontSize: 12,
                    selected: boardSize == side,
                    enabled: true
                )
            }
        }

        settingsY -= 2 * (pillH + 8) + 28
        addSectionCaption(x: panelCenterX, y: settingsY + 22, text: L10n.settingsWinLine)
        for row in 0..<2 {
            for col in 0..<2 {
                let i = row * 2 + col
                let k = boardSides[i]
                let enabled = k <= boardSize
                let x = panelCenterX + (col == 0 ? -colDX : colDX)
                let y = settingsY - CGFloat(row) * (pillH + 8)
                makePill(
                    name: "winlen_\(k)",
                    title: "\(k)",
                    x: x,
                    y: y,
                    width: pillW,
                    height: pillH,
                    fontSize: 13,
                    selected: winLength == k && enabled,
                    enabled: enabled
                )
            }
        }

        settingsY -= 2 * (pillH + 8) + 28
        makePill(
            name: "mode_human",
            title: L10n.modeTwoPlayers,
            x: panelCenterX,
            y: settingsY,
            width: modePillW,
            height: pillH,
            fontSize: 12,
            selected: opponentMode == .humanHuman,
            enabled: true
        )
        settingsY -= pillH + 10
        makePill(
            name: "mode_ai",
            title: L10n.modeVsComputer,
            x: panelCenterX,
            y: settingsY,
            width: modePillW,
            height: pillH,
            fontSize: 12,
            selected: opponentMode == .humanComputer,
            enabled: true
        )

        if opponentMode == .humanComputer {
            settingsY -= pillH + 14
            makePill(
                name: "pick_x",
                title: L10n.sideCrosses,
                x: panelCenterX,
                y: settingsY,
                width: modePillW,
                height: pillH,
                fontSize: 12,
                selected: humanPlayer == .x,
                enabled: true
            )
            settingsY -= pillH + 10
            makePill(
                name: "pick_o",
                title: L10n.sideNoughts,
                x: panelCenterX,
                y: settingsY,
                width: modePillW,
                height: pillH,
                fontSize: 12,
                selected: humanPlayer == .o,
                enabled: true
            )
        }

        let bottomY = -size.height * 0.46
        let newGameW = min(200, modePillW + 32)
        newGameButton = SKShapeNode(rectOf: CGSize(width: newGameW, height: 46), cornerRadius: 12)
        newGameButton.fillColor = palette.newGameFill
        newGameButton.strokeColor = palette.newGameStroke
        newGameButton.lineWidth = 1.5
        newGameButton.position = CGPoint(x: panelCenterX, y: bottomY)
        newGameButton.name = "newGame"
        newGameButton.zPosition = Layer.hud
        addChild(newGameButton)

        let newGameLabel = SKLabelNode(fontNamed: ".AppleSystemUIFontSemibold")
        newGameLabel.fontSize = 16
        newGameLabel.fontColor = palette.newGameLabel
        newGameLabel.verticalAlignmentMode = .center
        newGameLabel.text = L10n.newGame
        newGameLabel.position = CGPoint(x: panelCenterX, y: bottomY)
        newGameLabel.zPosition = Layer.hud + 1
        addChild(newGameLabel)

        // EN: --- Board chrome (shadow, plaque, grid, checker cells, marks) ---
        // RU: --- Оформление доски (тень, подложка, сетка, шахматные клетки, символы) ---
        let grid = SKNode()
        boardGrid = grid
        boardHalfBoard = halfBoard
        boardCellSide = cellSide
        grid.position = CGPoint(x: boardCenterX, y: boardCenterY)
        grid.zPosition = Layer.grid
        addChild(grid)

        let plaquePad: CGFloat = 18
        let shadow = SKShapeNode(rectOf: CGSize(width: boardSide + plaquePad + 8, height: boardSide + plaquePad + 8), cornerRadius: 18)
        shadow.fillColor = palette.boardShadow
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: -5, y: -7)
        shadow.zPosition = Layer.boardShadow
        grid.addChild(shadow)

        let plaque = SKShapeNode(rectOf: CGSize(width: boardSide + plaquePad, height: boardSide + plaquePad), cornerRadius: 16)
        plaque.fillColor = palette.boardPlaqueFill
        plaque.strokeColor = palette.boardPlaqueStroke
        plaque.lineWidth = 2
        plaque.zPosition = Layer.boardPlaque
        grid.addChild(plaque)

        let lineColor = palette.gridLine
        let lineWidth = max(1.5, boardSide * 0.004)

        func addLine(from: CGPoint, to: CGPoint) {
            let path = CGMutablePath()
            path.move(to: from)
            path.addLine(to: to)
            let shape = SKShapeNode(path: path)
            shape.strokeColor = lineColor
            shape.lineWidth = lineWidth
            shape.lineCap = .round
            grid.addChild(shape)
        }

        for i in 1..<n {
            let offset = -halfBoard + CGFloat(i) * cellSide
            addLine(from: CGPoint(x: offset, y: -halfBoard), to: CGPoint(x: offset, y: halfBoard))
            addLine(from: CGPoint(x: -halfBoard, y: offset), to: CGPoint(x: halfBoard, y: offset))
        }

        let outer = SKShapeNode(rectOf: CGSize(width: boardSide, height: boardSide))
        outer.strokeColor = palette.gridOuter
        outer.lineWidth = max(lineWidth * 1.35, 2)
        outer.fillColor = .clear
        grid.addChild(outer)

        let inset = max(1, cellSide * 0.06)
        let markScale = min(0.62, 2.7 / CGFloat(n))

        for row in 0..<n {
            for col in 0..<n {
                let checker = (row + col) % 2 == 0
                let cellTint = checker ? palette.cellEven : palette.cellOdd
                let node = SKSpriteNode(color: cellTint, size: CGSize(width: cellSide - inset * 2, height: cellSide - inset * 2))
                let cx = -halfBoard + cellSide * (CGFloat(col) + 0.5)
                let cy = -halfBoard + cellSide * (CGFloat(row) + 0.5)
                node.position = CGPoint(x: cx, y: cy)
                let key = Self.cellKey(row: row, col: col)
                node.name = key
                node.zPosition = Layer.cellHit
                grid.addChild(node)
                cellNodes[key] = node

                let mark = SKLabelNode(fontNamed: ".AppleSystemUIFontBold")
                mark.fontSize = cellSide * markScale
                mark.fontColor = palette.statusText
                mark.verticalAlignmentMode = .center
                mark.horizontalAlignmentMode = .center
                mark.position = CGPoint(x: cx, y: cy)
                mark.zPosition = Layer.mark
                mark.text = ""
                grid.addChild(mark)
                markNodes[key] = mark
            }
        }

        didPlayDrawFX = false
        syncUI()
        applyAIMoveIfNeeded()
    }

    /// EN: Small muted label above pill groups / RU: Приглушённая подпись над группами кнопок
    private func addSectionCaption(x: CGFloat, y: CGFloat, text: String) {
        let cap = SKLabelNode(fontNamed: ".AppleSystemUIFontMedium")
        cap.fontSize = 11
        cap.fontColor = palette.captionText
        cap.text = text
        cap.horizontalAlignmentMode = .center
        cap.position = CGPoint(x: x, y: y)
        cap.zPosition = Layer.hud
        addChild(cap)
    }

    /// EN: Hit-testable rounded HUD button; `_disabled` suffix when inactive so clicks ignore logically disabled picks.
    /// RU: Кликабельная «пилюля» HUD; суффикс `_disabled` при неактивном варианте, чтобы клики не проходили.
    private func makePill(
        name: String,
        title: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        fontSize: CGFloat,
        selected: Bool,
        enabled: Bool
    ) {
        let shape = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 7)
        shape.position = CGPoint(x: x, y: y)
        shape.name = enabled ? name : "\(name)_disabled"
        shape.lineWidth = selected ? 2.5 : 1
        shape.strokeColor = enabled ? (selected ? palette.pillStrokeSelected : palette.pillStroke) : palette.pillTextDisabled
        shape.fillColor = enabled ? (selected ? palette.pillFillSelected : palette.pillFill) : palette.pillFill.withAlphaComponent(0.22)
        shape.zPosition = Layer.hud
        shape.alpha = enabled ? 1 : 0.45

        let label = SKLabelNode(fontNamed: ".AppleSystemUIFont")
        label.name = enabled ? name : "\(name)_disabled"
        label.fontSize = fontSize
        label.fontColor = enabled ? palette.pillText : palette.pillTextDisabled
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.text = title
        shape.addChild(label)

        addChild(shape)
    }

    /// EN: Stable dictionary key for sprite lookup matching `SKNode.name` on cells / RU: Стабильный ключ словаря для спрайтов = `name` клетки
    private static func cellKey(row: Int, col: Int) -> String {
        "cell_\(row)_\(col)"
    }

    /// EN: Push model → sprites (glyph colours, optional place animation), status text, win overlay.
    /// RU: Модель → спрайты (цвет символа, анимация хода), строка статуса, подсветка победы.
    private func syncUI(animateMarkAt placed: (row: Int, col: Int)? = nil) {
        let n = game.boardSize
        let animatedKey: String? = placed.map { Self.cellKey(row: $0.row, col: $0.col) }

        for row in 0..<n {
            for col in 0..<n {
                let key = Self.cellKey(row: row, col: col)
                let cell = game.cell(at: row, col: col)
                let text = symbol(for: cell)
                guard let mark = markNodes[key] else { continue }

                mark.text = text
                mark.fontColor = markTint(for: cell)

                if let animatedKey, key == animatedKey, !text.isEmpty {
                    mark.removeAllActions()
                    mark.setScale(0.28)
                    mark.alpha = 0
                    let grow = SKAction.group([
                        SKAction.scale(to: 1.12, duration: 0.14),
                        SKAction.fadeIn(withDuration: 0.1),
                    ])
                    grow.timingMode = .easeOut
                    let settle = SKAction.scale(to: 1.0, duration: 0.1)
                    settle.timingMode = .easeOut
                    mark.run(SKAction.sequence([grow, settle]))
                } else {
                    mark.removeAllActions()
                    mark.alpha = 1
                    mark.setScale(1)
                }
            }
        }

        refreshWinHighlight()

        switch game.outcome() {
        case .inProgress:
            statusLabel.text = statusInProgressText()
        case .win(let winner):
            statusLabel.text = statusWinText(winner)
            if placed != nil {
                animateOutcomeBanner(wasWin: true)
            }
        case .draw:
            statusLabel.text = L10n.draw
            if placed != nil {
                playDrawBoardFXIfNeeded()
                animateOutcomeBanner(wasWin: false)
            }
        }
    }

    /// EN: Animated stroke across winning segment endpoints (first & last indices along rule order).
    /// RU: Анимированная линия по концам выигрышного отрезка (первый и последний индекс в порядке правил).
    private func refreshWinHighlight() {
        winHighlightLine?.removeFromParent()
        winHighlightLine = nil

        guard case .win = game.outcome(),
              let indices = game.winningLineIndices(),
              indices.count >= 2 else { return }

        let n = game.boardSize

        func center(forIndex index: Int) -> CGPoint {
            let row = index / n
            let col = index % n
            let cx = -boardHalfBoard + boardCellSide * (CGFloat(col) + 0.5)
            let cy = -boardHalfBoard + boardCellSide * (CGFloat(row) + 0.5)
            return CGPoint(x: cx, y: cy)
        }

        let start = center(forIndex: indices.first!)
        let end = center(forIndex: indices.last!)

        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)

        let line = SKShapeNode(path: path)
        line.strokeColor = palette.winLine
        line.glowWidth = max(2, boardCellSide * 0.04)
        line.lineWidth = max(4, boardCellSide * 0.1)
        line.lineCap = .round
        line.zPosition = Layer.winLine
        line.alpha = 0
        boardGrid.addChild(line)
        winHighlightLine = line

        let baseWidth = max(4, boardCellSide * 0.1)
        let strokeTarget = line.lineWidth * 1.15
        line.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeAlpha(to: 1, duration: 0.2),
                SKAction.customAction(withDuration: 0.22) { node, elapsed in
                    guard let shape = node as? SKShapeNode else { return }
                    let t = CGFloat(elapsed / 0.22)
                    shape.lineWidth = baseWidth + (strokeTarget - baseWidth) * t
                },
            ]),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.72, duration: 0.45),
                SKAction.fadeAlpha(to: 1.0, duration: 0.45),
            ])),
        ]))
    }

    /// EN: Gentle pulse on all occupied marks once when draw triggers / RU: Лёгкий пульс по всем занятым клеткам при ничьей
    private func playDrawBoardFXIfNeeded() {
        guard !didPlayDrawFX else { return }
        didPlayDrawFX = true

        for (_, mark) in markNodes {
            guard !(mark.text ?? "").isEmpty else { continue }
            let base = CGFloat(1)
            mark.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.08),
                SKAction.group([
                    SKAction.sequence([
                        SKAction.scale(to: base * 1.07, duration: 0.12),
                        SKAction.scale(to: base * 0.98, duration: 0.1),
                        SKAction.scale(to: base, duration: 0.08),
                    ]),
                    SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.75, duration: 0.14),
                        SKAction.fadeAlpha(to: 1.0, duration: 0.16),
                    ]),
                ]),
            ]))
        }
    }

    /// EN: Short scale/alpha pop on status headline after decisive move / RU: Короткий «поп» статуса после решающего хода
    private func animateOutcomeBanner(wasWin: Bool) {
        statusLabel.removeAllActions()
        statusLabel.setScale(1)
        let pop = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: wasWin ? 1.08 : 1.05, duration: 0.14),
                SKAction.fadeAlpha(to: 0.85, duration: 0.06),
            ]),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.12),
                SKAction.fadeAlpha(to: 1.0, duration: 0.1),
            ]),
        ])
        pop.timingMode = .easeOut
        statusLabel.run(pop)
    }

    /// EN: Turn banner varies by human/human vs human/AI and chosen human side / RU: Текст хода зависит от режима и стороны человека
    private func statusInProgressText() -> String {
        switch opponentMode {
        case .humanHuman:
            return game.currentPlayer == .x ? L10n.turnCrosses : L10n.turnNoughts
        case .humanComputer:
            let ai = humanPlayer.other
            if game.currentPlayer == humanPlayer {
                return humanPlayer == .x ? L10n.yourTurnCrosses : L10n.yourTurnNoughts
            }
            if game.currentPlayer == ai {
                return ai == .x ? L10n.computerTurnCrosses : L10n.computerTurnNoughts
            }
            return game.currentPlayer == .x ? L10n.turnOnlyCrosses : L10n.turnOnlyNoughts
        }
    }

    /// EN: Win headline — names sides or differentiates player vs computer / RU: Заголовок победы — стороны или человек против ИИ
    private func statusWinText(_ winner: Player) -> String {
        switch opponentMode {
        case .humanHuman:
            return winner == .x ? L10n.winCrosses : L10n.winNoughts
        case .humanComputer:
            return winner == humanPlayer ? L10n.winYou : L10n.winComputer
        }
    }

    /// EN: Unicode glyphs for marks / RU: Символы Unicode для крестика и нолика
    private func symbol(for cell: Cell) -> String {
        switch cell {
        case .empty:
            ""
        case .occupied(.x):
            "✕"
        case .occupied(.o):
            "○"
        }
    }

    /// EN: Per-player accent tint on labels / RU: Акцентный цвет подписи для ✕ и ○
    private func markTint(for cell: Cell) -> SKColor {
        switch cell {
        case .empty:
            palette.statusText
        case .occupied(.x):
            palette.crossMark
        case .occupied(.o):
            palette.noughtMark
        }
    }

    /// EN: Non-human side when playing vs computer / RU: Сторона противника (ИИ) в режиме «против компьютера»
    private var aiPlayer: Player {
        humanPlayer.other
    }

    /// EN: Offloads minimax to detached task, applies move on main actor if epoch still matches (settings unchanged).
    /// RU: Выносит минимакс в detached-задачу; применяет ход на main actor, если эпоха совпала (настройки не менялись).
    private func applyAIMoveIfNeeded() {
        guard opponentMode == .humanComputer else { return }
        guard game.outcome() == .inProgress else { return }
        guard game.currentPlayer == aiPlayer else { return }

        aiThinkingTask?.cancel()
        let epoch = inputEpoch
        let snapshot = game
        let ai = aiPlayer

        aiThinkingTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 220_000_000)
            guard !Task.isCancelled else { return }
            let move = await Task.detached {
                TicTacToeAI.bestMove(for: ai, in: snapshot)
            }.value
            await MainActor.run { [weak self] in
                guard let self else { return }
                guard !Task.isCancelled else { return }
                guard epoch == self.inputEpoch else { return }
                guard self.opponentMode == .humanComputer else { return }
                guard self.game.outcome() == .inProgress else { return }
                guard self.game.currentPlayer == ai else { return }
                if let m = move {
                    try? self.game.play(at: m.row, col: m.col)
                    self.syncUI(animateMarkAt: (m.row, m.col))
                }
            }
        }
    }

    /// EN: Clears board model + visuals, preserves rule toggles, restarts AI opening if needed.
    /// RU: Очищает модель и визуал, сохраняет переключатели правил, при необходимости снова запускает открытие ИИ.
    private func restartRound() {
        bumpInputEpoch()
        game.reset()
        didPlayDrawFX = false
        winHighlightLine?.removeFromParent()
        winHighlightLine = nil
        statusLabel.removeAllActions()
        statusLabel.alpha = 1
        statusLabel.setScale(1)
        syncUI()
        applyAIMoveIfNeeded()
    }

    /// EN: Hit-test stack resolves HUD pills first, then board cells; respects finished game + AI turn locks.
    /// RU: Стек попаданий: сначала HUD, затем клетки; учитывается конец партии и блокировка хода при очереди ИИ.
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let hits = nodes(at: location)

        if hits.contains(where: { $0.name == "newGame" }) {
            restartRound()
            return
        }

        for hit in hits {
            guard let raw = hit.name else { continue }
            let name = raw.replacingOccurrences(of: "_disabled", with: "")
            if name.hasPrefix("board_"), let s = Int(name.dropFirst(6)), s != boardSize {
                boardSize = s
                if winLength > boardSize {
                    winLength = boardSize
                }
                applyBoardConfiguration()
                return
            }
            if name.hasPrefix("winlen_"), let k = Int(name.dropFirst(7)), k <= boardSize, k != winLength {
                winLength = k
                applyBoardConfiguration()
                return
            }
            if name == "mode_human" || name == "mode_ai" {
                let next: OpponentMode = name == "mode_human" ? .humanHuman : .humanComputer
                if next != opponentMode {
                    opponentMode = next
                    applyBoardConfiguration()
                }
                return
            }
            if opponentMode == .humanComputer {
                if name == "pick_x", humanPlayer != .x {
                    humanPlayer = .x
                    applyBoardConfiguration()
                    return
                }
                if name == "pick_o", humanPlayer != .o {
                    humanPlayer = .o
                    applyBoardConfiguration()
                    return
                }
            }
        }

        guard game.outcome() == .inProgress else { return }

        if opponentMode == .humanComputer, game.currentPlayer != humanPlayer {
            return
        }

        for node in hits {
            guard let name = node.name, name.hasPrefix("cell_") else { continue }
            let parts = name.dropFirst(5).split(separator: "_")
            guard parts.count == 2,
                  let row = Int(parts[0]),
                  let col = Int(parts[1]) else { continue }

            do {
                try game.play(at: row, col: col)
                syncUI(animateMarkAt: (row, col))
                applyAIMoveIfNeeded()
            } catch {
                break
            }
            return
        }
    }
}
