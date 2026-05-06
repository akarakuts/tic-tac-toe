import AppKit
import SpriteKit

// EN: Main SpriteKit scene — themed HUD, responsive board layout, mouse input, async AI moves, win/draw FX.
// RU: Основная SpriteKit-сцена — темизированный HUD, адаптивное поле, мышь, асинхронный ход ИИ, эффекты победы/ничьей.

/// EN: Node stacking order (higher z draws on top).
/// RU: Порядок слоёв узлов (больший z рисуется поверх).
private enum Layer {
    static let backdropDecor: CGFloat = -40
    static let boardShadow: CGFloat = -15
    static let boardPlaque: CGFloat = -8
    static let grid: CGFloat = 0
    static let cellHit: CGFloat = 10
    static let mark: CGFloat = 20
    static let winLine: CGFloat = 35
    static let panelBackdrop: CGFloat = 40
    static let hud: CGFloat = 100
}

@MainActor
final class GameScene: SKScene {

    /// EN: Theme snapshot rebuilt whenever layout or system appearance-driven colours refresh.
    /// RU: Снимок темы пересобирается при смене раскладки или цветов из темы системы.
    private var palette: BoardPalette!

    /// EN: Wins/losses vs AI, streaks, unlocks — persisted.
    /// RU: Победы/поражения против ИИ, серии, разблокировки — сохраняются.
    private var progress = GameProgressStore.load()

    /// EN: VS AI stats card (rebuilt with layout; values refreshed in `updateStatsFooterText`).
    /// RU: Карточка статистики против ИИ (пересборка в раскладке; значения в `updateStatsFooterText`).
    private var statsStripRoot: SKNode!

    /// EN: Ensures one persistence write per finished round vs AI.
    /// RU: Одно сохранение за завершённый раунд против ИИ.
    private var roundOutcomeRecorded = false

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
        roundOutcomeRecorded = false
        if winLength > boardSize {
            winLength = boardSize
        }
        game = GameModel(boardSize: boardSize, winLength: winLength)
        rebuildLayout()
    }

    /// EN: Uniform scale for left HUD vs ~760pt window short side / RU: Масштаб левой панели и контролов от короткой стороны окна.
    private func hudLayoutScale() -> CGFloat {
        let m = min(size.width, size.height)
        let raw = m / 760
        return max(0.62, min(1.42, raw))
    }

    /// EN: Full UI reconstruction — theme, left panel, board footprint, grid cells, then sync state + AI kick-off.
    /// RU: Полная пересборка UI — тема, левая панель, область доски, сетка, затем синхронизация и запуск ИИ при необходимости.
    private func rebuildLayout() {
        removeAllActions()
        removeAllChildren()
        cellNodes.removeAll()
        markNodes.removeAll()

        let darkMode = isDarkInterfaceActive
        palette = BoardPalette(style: progress.selectedTheme, darkMode: darkMode, accent: NSColor.controlAccentColor)
        GameSoundFX.shared.soundEffectsEnabled = progress.soundEnabled
        backgroundColor = palette.sceneBackground

        addBackdropAuras()

        let n = game.boardSize
        let hudScale = hudLayoutScale()
        // EN: Minimum inset from scene edges / RU: Минимальный отступ от краёв сцены
        let margin = max(12 * hudScale, min(size.width, size.height) * 0.02)
        let panelHalfWidth = max(76, min(148, 102 * hudScale))
        let panelGap = max(10, min(26, 16 * hudScale))
        let panelCenterX = -size.width * 0.5 + margin + panelHalfWidth

        let panelRightEdge = panelCenterX + panelHalfWidth
        // EN: Horizontal strip reserved for the square board (right of panel + gap).
        // RU: Горизонтальная полоса под квадратную доску (справа от панели и зазора).
        let boardAreaLeft = panelRightEdge + panelGap
        let boardAreaRight = size.width * 0.5 - margin
        let availWidth = max(0, boardAreaRight - boardAreaLeft)

        let sceneTopY = size.height * 0.5 - margin
        let sceneBottomY = -size.height * 0.5 + margin
        let statusFontSize = max(12, min(28, size.height * 0.019 * hudScale))
        let statusLabelY = sceneTopY - statusFontSize * 0.45 - 6 * hudScale
        let statusBottomGap: CGFloat = max(9, min(18, 12 * hudScale))
        // EN: Board top must stay below status headline band / RU: Верх доски не заходит в полосу статуса
        let maxBoardTop = statusLabelY - statusFontSize * 0.55 - statusBottomGap

        // EN: Theme legend is moved under the board, so reserve a small band at the bottom.
        // RU: Легенду про темы переносим под доску, поэтому резервируем снизу небольшую полосу.
        let panelBackdropW = panelHalfWidth * 2 + max(44, min(72, 56 * hudScale))
        let hintMaxW = panelReadableWidth(panelHalfWidth: panelHalfWidth, edgeMargin: margin, layoutScale: hudScale)
        let hudCardW = min(hintMaxW, panelBackdropW - max(26, 32 * hudScale))
        let legendW = min(max(260, 420 * hudScale), max(220, availWidth))
        let themeLegendRow = makeThemeUnlockLegendRow(width: legendW, layoutScale: hudScale)
        let legendH = themeLegendRow.height
        let legendGapToBoard = max(10, min(18, 12 * hudScale))
        let boardBottomLimit = sceneBottomY + legendH + legendGapToBoard

        let verticalSpan = max(0, maxBoardTop - boardBottomLimit)

        // EN: Largest axis-aligned square fitting width × vertical span / RU: Максимальный вписанный квадрат в ширину × высоту
        let boardSide = max(1, min(availWidth, verticalSpan))
        let cellSide = boardSide / CGFloat(n)
        let halfBoard = boardSide / 2
        let boardCenterX = boardAreaLeft + availWidth * 0.5
        let boardCenterY = boardBottomLimit + verticalSpan * 0.5

        statusLabel = SKLabelNode(fontNamed: ".AppleSystemUIFontBold")
        statusLabel.fontSize = statusFontSize
        statusLabel.fontColor = palette.statusText
        statusLabel.position = CGPoint(x: boardCenterX, y: statusLabelY)
        statusLabel.zPosition = Layer.hud
        addChild(statusLabel)

        // EN: --- Left HUD: single bottom→top stack so hints/sound/stats never collide with pills ---
        // RU: --- Левый HUD: один столбец снизу вверх — подсказки/звук/статистика не наезжают на кнопки ---
        let colDX = max(34, min(54, 43 * hudScale))
        let pillW = max(56, min(92, 74 * hudScale))
        let pillH = max(23, min(38, 27 * hudScale))
        let pillRowGap = max(5, min(11, 7 * hudScale))
        /// EN: Tighter gaps on short windows so the panel stack fits / RU: На низких окнах уменьшаем зазоры.
        let bandGapBase = max(7, min(16, 11 * hudScale))
        let bandGap = size.height < 520 ? bandGapBase * 0.92 : (size.height < 640 ? bandGapBase * 0.96 : bandGapBase)
        let captionAboveRow = max(13, min(23, (size.height < 520 ? 15 : 17) * hudScale))
        let modePillW = min(max(128, 162 * hudScale), panelHalfWidth * 2 + max(5, 6 * hudScale))
        let themePillW = max(58, min(96, 72 * hudScale))
        let newGameH = max(36, min(56, 44 * hudScale))
        let newGameW = min(max(168, 196 * hudScale), modePillW + max(28, 36 * hudScale))
        let boardSides = [3, 4, 5, 6]
        let themeStyles: [BoardVisualStyle] = [.classic, .aurora, .grove, .ember]
        // NOTE: hintMaxW / hudCardW computed above (used by stats + legend).

        func boardTitle(_ side: Int) -> String {
            "\(side)×\(side)"
        }

        /// EN: Bottom inset for left stack — consistent floor for backdrop math / RU: Нижняя граница левого столбца.
        let hudFloorY = sceneBottomY + max(12 * hudScale, size.height * 0.022)

        /// EN: Vertical center `cy` walks upward (each step: top(previous)+gap+half(next)) / RU: Центр следующего виджета выше по Y.
        var cy = hudFloorY + newGameH * 0.5

        let newGameCorner = max(9, min(18, 13 * hudScale))
        newGameButton = SKShapeNode(rectOf: CGSize(width: newGameW, height: newGameH), cornerRadius: newGameCorner)
        newGameButton.fillColor = palette.newGameFill
        newGameButton.strokeColor = palette.newGameStroke
        newGameButton.lineWidth = max(1.15, min(2.2, 1.5 * hudScale))
        newGameButton.position = CGPoint(x: panelCenterX, y: cy)
        newGameButton.name = "newGame"
        newGameButton.zPosition = Layer.hud
        addChild(newGameButton)

        let newGameLabel = SKLabelNode(fontNamed: ".AppleSystemUIFontSemibold")
        newGameLabel.fontSize = max(13, min(20, size.height * 0.021 * hudScale))
        newGameLabel.fontColor = palette.newGameLabel
        newGameLabel.verticalAlignmentMode = .center
        newGameLabel.text = L10n.newGame
        newGameLabel.position = CGPoint(x: panelCenterX, y: cy)
        newGameLabel.zPosition = Layer.hud + 1
        addChild(newGameLabel)

        let statsCard = makeVsAiStatsCard(width: hudCardW, layoutScale: hudScale)
        let statsH = statsCard.height
        cy += newGameH * 0.5 + bandGap + statsH * 0.5
        statsStripRoot = statsCard.node
        statsStripRoot.position = CGPoint(x: panelCenterX, y: cy)
        statsStripRoot.zPosition = Layer.hud
        addChild(statsStripRoot)
        updateStatsFooterText()

        cy += statsH * 0.5 + bandGap + pillH * 0.5

        makePill(
            name: "sound_toggle",
            title: progress.soundEnabled ? L10n.soundOn : L10n.soundOff,
            x: panelCenterX,
            y: cy,
            width: min(max(118, 136 * hudScale), modePillW + max(22, 28 * hudScale)),
            height: pillH,
            fontPoints: 11,
            layoutScale: hudScale,
            selected: progress.soundEnabled,
            enabled: true
        )
        // EN/RU: Theme legend moved under the board — free vertical space in left panel.
        cy += pillH + bandGap

        let themeBottomRowCenter = cy
        for col in 0..<2 {
            let i = 2 + col
            let style = themeStyles[i]
            let unlocked = progress.unlockedThemes.contains(style)
            let x = panelCenterX + (col == 0 ? -colDX : colDX)
            makePill(
                name: "theme_\(style.rawValue)",
                title: themePillTitle(style),
                x: x,
                y: themeBottomRowCenter,
                width: themePillW,
                height: pillH,
                fontPoints: 11,
                layoutScale: hudScale,
                selected: progress.selectedTheme == style,
                enabled: unlocked
            )
        }

        let themeTopRowCenter = themeBottomRowCenter + pillH + pillRowGap
        for col in 0..<2 {
            let i = col
            let style = themeStyles[i]
            let unlocked = progress.unlockedThemes.contains(style)
            let x = panelCenterX + (col == 0 ? -colDX : colDX)
            makePill(
                name: "theme_\(style.rawValue)",
                title: themePillTitle(style),
                x: x,
                y: themeTopRowCenter,
                width: themePillW,
                height: pillH,
                fontPoints: 11,
                layoutScale: hudScale,
                selected: progress.selectedTheme == style,
                enabled: unlocked
            )
        }

        let themeCaptionY = themeTopRowCenter + pillH * 0.5 + captionAboveRow
        addSectionCaption(x: panelCenterX, y: themeCaptionY, text: L10n.settingsTheme, layoutScale: hudScale)

        let modeStackLead = max(14, min(22, 16 * hudScale))
        let modePairGap = max(8, min(14, 10 * hudScale))
        var rowCY = themeCaptionY + modeStackLead + pillH * 0.5 + max(6, 8 * hudScale)
        makePill(
            name: "mode_ai",
            title: L10n.modeVsComputer,
            x: panelCenterX,
            y: rowCY,
            width: modePillW,
            height: pillH,
            fontPoints: 12,
            layoutScale: hudScale,
            selected: opponentMode == .humanComputer,
            enabled: true
        )
        rowCY += pillH + modePairGap
        makePill(
            name: "mode_human",
            title: L10n.modeTwoPlayers,
            x: panelCenterX,
            y: rowCY,
            width: modePillW,
            height: pillH,
            fontPoints: 12,
            layoutScale: hudScale,
            selected: opponentMode == .humanHuman,
            enabled: true
        )

        // EN: Always show AI difficulty + side picker on the panel; gray them out when in 2-players mode.
        // RU: Всегда показываем «Сложность ИИ» и «Вы — X/О» на панели; в режиме «Два игрока» делаем их неактивными.
        do {
            let aiActive = (opponentMode == .humanComputer)
            let diffHGap = max(4, min(10, 6 * hudScale))
            let panelInnerW = panelHalfWidth * 2 - max(8, 12 * hudScale)
            let diffMaxPillW = max(36, (panelInnerW - 2 * diffHGap) / 3)
            let diffPillW = min(max(40, min(64, 50 * hudScale)), diffMaxPillW)
            let diffSpacing = diffPillW + diffHGap
            let gapBetweenRows = max(pillRowGap, max(7, 10 * hudScale))
            let gapBetweenSections = max(bandGap, max(12, 16 * hudScale))
            let captionFontH = max(8.5, min(13.5, 10 * hudScale))

            let diffRowY = rowCY + pillH + gapBetweenSections
            let diffCaptionY = diffRowY + pillH * 0.5 + captionAboveRow
            addSectionCaption(x: panelCenterX, y: diffCaptionY, text: L10n.settingsAiDifficulty, layoutScale: hudScale)
            makePill(
                name: "ai_easy",
                title: L10n.aiEasy,
                x: panelCenterX - diffSpacing,
                y: diffRowY,
                width: diffPillW,
                height: pillH,
                fontPoints: 11,
                layoutScale: hudScale,
                selected: aiActive && progress.aiDifficulty == .easy,
                enabled: aiActive
            )
            makePill(
                name: "ai_medium",
                title: L10n.aiMedium,
                x: panelCenterX,
                y: diffRowY,
                width: diffPillW,
                height: pillH,
                fontPoints: 11,
                layoutScale: hudScale,
                selected: aiActive && progress.aiDifficulty == .medium,
                enabled: aiActive
            )
            makePill(
                name: "ai_hard",
                title: L10n.aiHard,
                x: panelCenterX + diffSpacing,
                y: diffRowY,
                width: diffPillW,
                height: pillH,
                fontPoints: 11,
                layoutScale: hudScale,
                selected: aiActive && progress.aiDifficulty == .hard,
                enabled: aiActive
            )

            let captionTopY = diffCaptionY + captionFontH
            let pickXCenter = captionTopY + gapBetweenSections + pillH * 0.5
            rowCY = pickXCenter
            makePill(
                name: "pick_x",
                title: L10n.sideCrosses,
                x: panelCenterX,
                y: rowCY,
                width: modePillW,
                height: pillH,
                fontPoints: 12,
                layoutScale: hudScale,
                selected: aiActive && humanPlayer == .x,
                enabled: aiActive
            )
            rowCY = pickXCenter + pillH + gapBetweenRows
            makePill(
                name: "pick_o",
                title: L10n.sideNoughts,
                x: panelCenterX,
                y: rowCY,
                width: modePillW,
                height: pillH,
                fontPoints: 12,
                layoutScale: hudScale,
                selected: aiActive && humanPlayer == .o,
                enabled: aiActive
            )
        }

        rowCY += pillH * 0.5 + bandGap + max(5, min(10, 6 * hudScale))

        let winBottomRowCenter = rowCY + pillH * 0.5 + max(1, min(5, 2 * hudScale))
        let winTopRowCenter = winBottomRowCenter + pillH + pillRowGap
        for row in 0..<2 {
            for col in 0..<2 {
                let i = row * 2 + col
                let k = boardSides[i]
                let enabled = k <= boardSize
                let x = panelCenterX + (col == 0 ? -colDX : colDX)
                let y = winBottomRowCenter + CGFloat(row) * (pillH + pillRowGap)
                makePill(
                    name: "winlen_\(k)",
                    title: "\(k)",
                    x: x,
                    y: y,
                    width: pillW,
                    height: pillH,
                    fontPoints: 13,
                    layoutScale: hudScale,
                    selected: winLength == k && enabled,
                    enabled: enabled
                )
            }
        }
        let winCaptionY = winTopRowCenter + pillH * 0.5 + captionAboveRow
        addSectionCaption(x: panelCenterX, y: winCaptionY, text: L10n.settingsWinLine, layoutScale: hudScale)

        let boardBottomRowCenter = winCaptionY + max(12, min(22, 16 * hudScale)) + bandGap + pillH * 0.5 + max(3, min(8, 4 * hudScale))
        let boardTopRowCenter = boardBottomRowCenter + pillH + pillRowGap
        for row in 0..<2 {
            for col in 0..<2 {
                let i = row * 2 + col
                let side = boardSides[i]
                let x = panelCenterX + (col == 0 ? -colDX : colDX)
                let y = boardBottomRowCenter + CGFloat(row) * (pillH + pillRowGap)
                makePill(
                    name: "board_\(side)",
                    title: boardTitle(side),
                    x: x,
                    y: y,
                    width: pillW,
                    height: pillH,
                    fontPoints: 12,
                    layoutScale: hudScale,
                    selected: boardSize == side,
                    enabled: true
                )
            }
        }
        let boardCaptionY = boardTopRowCenter + pillH * 0.5 + captionAboveRow
        addSectionCaption(x: panelCenterX, y: boardCaptionY, text: L10n.settingsBoard, layoutScale: hudScale)

        let panelHudTop = boardCaptionY + max(11, min(20, 14 * hudScale))
        let panelHudBottom = hudFloorY
        let panelBackdropH = min(size.height - margin * 2, max(size.height * 0.86, panelHudTop - panelHudBottom + max(36, 48 * hudScale)))
        let panelBackdropCY = (panelHudTop + panelHudBottom) * 0.5
        let backdropCorner = max(18, min(32, 24 * hudScale))
        let panelBackdrop = SKShapeNode(rectOf: CGSize(width: panelBackdropW, height: panelBackdropH), cornerRadius: backdropCorner)
        panelBackdrop.fillColor = palette.panelFill
        panelBackdrop.strokeColor = palette.panelStroke.withAlphaComponent(min(1, palette.panelStroke.alphaComponent * 1.12))
        panelBackdrop.lineWidth = max(0.85, min(1.6, hudScale))
        panelBackdrop.position = CGPoint(x: panelCenterX, y: panelBackdropCY)
        panelBackdrop.zPosition = Layer.panelBackdrop
        insertChild(panelBackdrop, at: 0)

        // EN: Place theme legend under the board / RU: Легенда тем — под доской.
        themeLegendRow.node.position = CGPoint(x: boardCenterX, y: sceneBottomY + legendH * 0.5)
        themeLegendRow.node.zPosition = Layer.hud
        addChild(themeLegendRow.node)

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

        playLayoutIntro()
        animateNewGameButtonPulse()
    }

    /// EN: Rounded VS AI stats card — triple metric row + streak footer / RU: Карточка статистики против ИИ.
    private func makeVsAiStatsCard(width: CGFloat, layoutScale s: CGFloat) -> (node: SKNode, height: CGFloat) {
        let root = SKNode()
        root.name = "vs_ai_stats_root"

        let h: CGFloat = max(66 * s, min(102 * s, size.height * 0.095 * max(s, 0.85)))
        let cr = max(10, min(18, 14 * s))
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: h), cornerRadius: cr)
        bg.fillColor = palette.pillFill.withAlphaComponent(min(1, palette.pillFill.alphaComponent * 1.45))
        bg.strokeColor = palette.panelStroke.withAlphaComponent(min(1, palette.panelStroke.alphaComponent * 1.05))
        bg.lineWidth = max(0.75, min(1.5, s))
        bg.position = .zero
        root.addChild(bg)

        let glossH = max(14 * s, h * 0.22)
        let gloss = SKShapeNode(rectOf: CGSize(width: width - 2 * s, height: glossH), cornerRadius: max(8, min(14, 12 * s)))
        gloss.fillColor = NSColor(calibratedWhite: 1, alpha: isDarkInterfaceActive ? 0.04 : 0.07)
        gloss.strokeColor = .clear
        gloss.position = CGPoint(x: 0, y: h * 0.5 - glossH * 0.5 - 2 * s)
        gloss.zPosition = 0.5
        root.addChild(gloss)

        let cap = SKLabelNode(fontNamed: ".AppleSystemUIFontSemibold")
        cap.fontSize = max(8, min(13.5, size.height * 0.011 * s))
        cap.fontColor = palette.captionText.withAlphaComponent(0.82)
        cap.text = L10n.statsVsAI
        cap.horizontalAlignmentMode = .center
        cap.verticalAlignmentMode = .center
        cap.position = CGPoint(x: 0, y: h * 0.5 - 15 * s)
        cap.zPosition = 1
        root.addChild(cap)

        let colX: [CGFloat] = [-width * 0.26, 0, width * 0.26]
        let yNums = h * 0.5 - 36 * s
        let ySyms = h * 0.5 - 52 * s

        func addColumn(index: Int, symbol: String, valueKey: String, value: Int, valueColor: SKColor) {
            let sym = SKLabelNode(fontNamed: ".AppleSystemUIFontMedium")
            sym.fontSize = max(8.5, min(13.5, size.height * 0.012 * s))
            sym.fontColor = palette.captionText.withAlphaComponent(0.72)
            sym.text = symbol
            sym.horizontalAlignmentMode = .center
            sym.verticalAlignmentMode = .center
            sym.position = CGPoint(x: colX[index], y: ySyms)
            sym.zPosition = 1
            root.addChild(sym)

            let num = SKLabelNode(fontNamed: ".AppleSystemUIFontBold")
            num.name = valueKey
            num.fontSize = max(12, min(22, size.height * 0.02 * s))
            num.fontColor = valueColor
            num.text = "\(value)"
            num.horizontalAlignmentMode = .center
            num.verticalAlignmentMode = .center
            num.position = CGPoint(x: colX[index], y: yNums)
            num.zPosition = 1
            root.addChild(num)
        }

        addColumn(index: 0, symbol: "✓", valueKey: "stats_win_val", value: progress.winsVsAI, valueColor: palette.noughtMark.withAlphaComponent(0.96))
        addColumn(index: 1, symbol: "✗", valueKey: "stats_loss_val", value: progress.lossesVsAI, valueColor: palette.crossMark.withAlphaComponent(0.95))
        addColumn(index: 2, symbol: "=", valueKey: "stats_draw_val", value: progress.drawsVsAI, valueColor: palette.statusText.withAlphaComponent(0.82))

        let sepH = 26 * s
        let sepLeft = SKShapeNode(rectOf: CGSize(width: max(0.75, s * 0.85), height: sepH), cornerRadius: 0)
        sepLeft.fillColor = palette.panelStroke.withAlphaComponent(0.35)
        sepLeft.strokeColor = .clear
        sepLeft.position = CGPoint(x: (colX[0] + colX[1]) * 0.5, y: yNums + 7 * s)
        sepLeft.zPosition = 0.8
        root.addChild(sepLeft)

        let sepRight = SKShapeNode(rectOf: CGSize(width: max(0.75, s * 0.85), height: sepH), cornerRadius: 0)
        sepRight.fillColor = palette.panelStroke.withAlphaComponent(0.35)
        sepRight.strokeColor = .clear
        sepRight.position = CGPoint(x: (colX[1] + colX[2]) * 0.5, y: yNums + 7 * s)
        sepRight.zPosition = 0.8
        root.addChild(sepRight)

        let div = SKShapeNode(rectOf: CGSize(width: width - 22 * s, height: max(0.75, s * 0.85)), cornerRadius: 0)
        div.fillColor = palette.panelStroke.withAlphaComponent(0.28)
        div.strokeColor = .clear
        div.position = CGPoint(x: 0, y: h * 0.5 - 58 * s)
        div.zPosition = 0.8
        root.addChild(div)

        let streak = SKLabelNode(fontNamed: ".AppleSystemUIFontMedium")
        streak.name = "stats_streak_line"
        streak.fontSize = max(8, min(13, size.height * 0.0115 * s))
        streak.fontColor = palette.captionText.withAlphaComponent(0.9)
        streak.horizontalAlignmentMode = .center
        streak.verticalAlignmentMode = .center
        streak.position = CGPoint(x: 0, y: h * 0.5 - 69 * s)
        streak.zPosition = 1
        root.addChild(streak)

        return (root, h)
    }

    /// EN: Theme unlock explainer — accent rail + headline + dotted rows / RU: Карточка разблокировки тем.
    private func makeThemeUnlockCard(width: CGFloat, layoutScale s: CGFloat) -> (node: SKNode, height: CGFloat) {
        let root = SKNode()
        root.name = "theme_unlock_card_root"

        let inset: CGFloat = max(9, min(17, 12 * s))
        let rawDetails = L10n.themeUnlockDetails
        let segments = rawDetails.split(whereSeparator: { $0 == "·" }).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let useRows = segments.count >= 3

        let titleFont = max(9, min(14.5, size.height * 0.012 * s))
        let titleLineHeight = titleFont * 1.22
        let intro = L10n.themeUnlockIntro
        let approxCharsPerLine = max(12, Int((width - inset * 2 - 10) / max(4, titleFont * 0.52)))
        let titleLines = max(1, (intro.count + approxCharsPerLine - 1) / approxCharsPerLine)
        let titleBlockH = CGFloat(titleLines) * titleLineHeight

        let rowFont = max(8.5, min(13.5, size.height * 0.0113 * s))
        let rowSpacing: CGFloat = max(13, min(21, 16 * s))

        let bodyH: CGFloat
        if useRows {
            bodyH = 3 * rowSpacing + 14 * s
        } else {
            let detailLines = max(2, (rawDetails.count + approxCharsPerLine - 1) / approxCharsPerLine)
            bodyH = max(CGFloat(detailLines) * rowFont * 1.42 + 16 * s, 52 * s)
        }

        let totalH = max(88 * s, inset + titleBlockH + 14 * s + bodyH + inset + 6 * s)

        let dotPalette: [SKColor] = [
            NSColor(calibratedHue: 0.54, saturation: 0.42, brightness: isDarkInterfaceActive ? 0.93 : 0.72, alpha: 1),
            NSColor(calibratedHue: 0.31, saturation: 0.48, brightness: isDarkInterfaceActive ? 0.88 : 0.68, alpha: 1),
            NSColor(calibratedHue: 0.03, saturation: 0.62, brightness: isDarkInterfaceActive ? 0.94 : 0.78, alpha: 1),
        ]

        let bgCr = max(10, min(18, 14 * s))
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: totalH), cornerRadius: bgCr)
        bg.fillColor = palette.pillFill.withAlphaComponent(min(1, palette.pillFill.alphaComponent * 1.28))
        bg.strokeColor = palette.panelStroke.withAlphaComponent(min(1, palette.panelStroke.alphaComponent * 1.08))
        bg.lineWidth = max(0.75, min(1.5, s))
        bg.position = .zero
        root.addChild(bg)

        let accentBar = SKShapeNode(rectOf: CGSize(width: max(2.25, 3 * s), height: max(26 * s, totalH - inset * 2)), cornerRadius: 1.5 * s)
        accentBar.fillColor = palette.pillStrokeSelected.withAlphaComponent(0.5)
        accentBar.strokeColor = .clear
        accentBar.position = CGPoint(x: -width * 0.5 + inset + 1.5 * s, y: 0)
        accentBar.zPosition = 0.5
        root.addChild(accentBar)

        let hairline = SKShapeNode(rectOf: CGSize(width: width - 26 * s, height: max(0.75, s * 0.85)), cornerRadius: 0)
        hairline.fillColor = palette.panelStroke.withAlphaComponent(0.22)
        hairline.strokeColor = .clear
        hairline.position = CGPoint(x: 8 * s, y: totalH * 0.5 - inset - titleBlockH - 4 * s)
        hairline.zPosition = 0.6
        root.addChild(hairline)

        let title = SKLabelNode(fontNamed: ".AppleSystemUIFontSemibold")
        title.fontSize = titleFont
        title.fontColor = palette.statusText
        title.text = intro
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .top
        title.preferredMaxLayoutWidth = width - inset * 2 - 12 * s
        title.numberOfLines = 0
        title.position = CGPoint(x: -width * 0.5 + inset + 10 * s, y: totalH * 0.5 - inset)
        title.zPosition = 1
        root.addChild(title)

        var cursorY = title.position.y - titleBlockH - 14 * s

        if useRows {
            for i in 0..<3 {
                let dot = SKShapeNode(circleOfRadius: max(2.8, min(5.2, 3.5 * s)))
                dot.fillColor = dotPalette[i]
                dot.strokeColor = NSColor(calibratedWhite: 1, alpha: isDarkInterfaceActive ? 0.14 : 0.42)
                dot.lineWidth = 0.5
                dot.position = CGPoint(x: -width * 0.5 + inset + 9 * s, y: cursorY)
                dot.zPosition = 1
                root.addChild(dot)

                let line = SKLabelNode(fontNamed: ".AppleSystemUIFont")
                line.fontSize = rowFont
                line.fontColor = palette.captionText.withAlphaComponent(0.94)
                line.text = segments[i]
                line.horizontalAlignmentMode = .left
                line.verticalAlignmentMode = .center
                line.position = CGPoint(x: -width * 0.5 + inset + 19 * s, y: cursorY)
                line.preferredMaxLayoutWidth = width - inset * 2 - 26 * s
                line.numberOfLines = 2
                line.zPosition = 1
                root.addChild(line)

                cursorY -= rowSpacing
            }
        } else {
            let body = SKLabelNode(fontNamed: ".AppleSystemUIFont")
            body.fontSize = rowFont
            body.fontColor = palette.captionText.withAlphaComponent(0.92)
            body.text = rawDetails
            body.horizontalAlignmentMode = .left
            body.verticalAlignmentMode = .top
            body.preferredMaxLayoutWidth = width - inset * 2 - 12 * s
            body.numberOfLines = 0
            body.position = CGPoint(x: -width * 0.5 + inset + 10 * s, y: cursorY)
            body.zPosition = 1
            root.addChild(body)
        }

        return (root, totalH)
    }

    /// EN: Two-line readable theme legend placed under the board.
    /// RU: Двухстрочная читаемая легенда тем под игровым полем.
    private func makeThemeUnlockLegendRow(width: CGFloat, layoutScale s: CGFloat) -> (node: SKNode, height: CGFloat) {
        let root = SKNode()
        root.name = "theme_unlock_legend_row_root"

        let titleFont = max(10, min(13.5, 11.5 * s))
        let detailsFont = max(9, min(12.5, 10.5 * s))
        let vPad = max(6, min(11, 8 * s))
        let lineGap = max(2, min(6, 3 * s))
        let h = vPad * 2 + titleFont + lineGap + detailsFont

        let cr = max(10, min(16, 12 * s))
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: h), cornerRadius: cr)
        bg.fillColor = palette.pillFill.withAlphaComponent(min(1, palette.pillFill.alphaComponent * 1.18))
        bg.strokeColor = palette.panelStroke.withAlphaComponent(min(1, palette.panelStroke.alphaComponent * 0.95))
        bg.lineWidth = max(0.75, min(1.3, s))
        bg.position = .zero
        root.addChild(bg)

        let title = SKLabelNode(fontNamed: ".AppleSystemUIFontSemibold")
        title.fontSize = titleFont
        title.fontColor = palette.captionText
        title.text = L10n.themeUnlockIntro
        title.horizontalAlignmentMode = .center
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: (lineGap + detailsFont) * 0.5)
        title.zPosition = 1
        root.addChild(title)

        let rawDetails = L10n.themeUnlockDetails
        let segments = rawDetails
            .split(whereSeparator: { $0 == "·" })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let detailsText = segments.isEmpty ? rawDetails : segments.joined(separator: "   •   ")

        let details = SKLabelNode(fontNamed: ".AppleSystemUIFontMedium")
        details.fontSize = detailsFont
        details.fontColor = palette.captionText.withAlphaComponent(0.9)
        details.text = detailsText
        details.horizontalAlignmentMode = .center
        details.verticalAlignmentMode = .center
        details.position = CGPoint(x: 0, y: -(lineGap + titleFont) * 0.5)
        details.zPosition = 1
        root.addChild(details)

        return (root, h)
    }

    /// EN: Soft decorative auras behind the whole scene to add depth and warmth.
    /// RU: Мягкие декоративные «ауры» в фоне сцены — добавляют глубину и теплоту.
    private func addBackdropAuras() {
        let darkMode = isDarkInterfaceActive
        let topRadius = max(size.width, size.height) * 0.55
        let bottomRadius = max(size.width, size.height) * 0.42

        let topGlow = SKShapeNode(circleOfRadius: topRadius)
        topGlow.fillColor = palette.pillStrokeSelected.withAlphaComponent(darkMode ? 0.16 : 0.12)
        topGlow.strokeColor = .clear
        topGlow.glowWidth = max(40, topRadius * 0.35)
        topGlow.position = CGPoint(x: size.width * 0.32, y: size.height * 0.36)
        topGlow.zPosition = Layer.backdropDecor
        topGlow.alpha = 0.85
        topGlow.blendMode = .add
        addChild(topGlow)

        let bottomGlow = SKShapeNode(circleOfRadius: bottomRadius)
        bottomGlow.fillColor = palette.crossMark.withAlphaComponent(darkMode ? 0.10 : 0.07)
        bottomGlow.strokeColor = .clear
        bottomGlow.glowWidth = max(40, bottomRadius * 0.35)
        bottomGlow.position = CGPoint(x: -size.width * 0.32, y: -size.height * 0.30)
        bottomGlow.zPosition = Layer.backdropDecor
        bottomGlow.alpha = 0.8
        bottomGlow.blendMode = .add
        addChild(bottomGlow)

        let driftDuration: TimeInterval = 9.0
        topGlow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 14, y: -10, duration: driftDuration),
            SKAction.moveBy(x: -14, y: 10, duration: driftDuration),
        ])))
        bottomGlow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: -10, y: 14, duration: driftDuration + 1.4),
            SKAction.moveBy(x: 10, y: -14, duration: driftDuration + 1.4),
        ])))
    }

    /// EN: Subtle fade-in for whole scene contents on rebuild.
    /// RU: Мягкое появление содержимого сцены при перестроении.
    private func playLayoutIntro() {
        for child in children {
            let base = child.alpha
            child.alpha = 0
            child.run(SKAction.fadeAlpha(to: base, duration: 0.22))
        }
    }

    /// EN: Friendly heartbeat-style pulse on the New game button stroke.
    /// RU: Дружелюбный «пульс» обводки кнопки «Новая игра».
    private func animateNewGameButtonPulse() {
        guard let btn = newGameButton else { return }
        btn.removeAction(forKey: "newGamePulse")
        let baseLW = btn.lineWidth
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.customAction(withDuration: 1.05) { node, t in
                guard let s = node as? SKShapeNode else { return }
                let phase = sin(Double(t / 1.05) * .pi * 2)
                s.lineWidth = baseLW * (1.0 + 0.18 * CGFloat(phase))
            },
            SKAction.customAction(withDuration: 1.05) { node, t in
                guard let s = node as? SKShapeNode else { return }
                let phase = sin(.pi + Double(t / 1.05) * .pi * 2)
                s.lineWidth = baseLW * (1.0 + 0.18 * CGFloat(phase))
            },
        ]))
        btn.run(pulse, withKey: "newGamePulse")
    }

    /// EN: Max label width inside frosted panel / RU: Макс. ширина текста внутри панели.
    private func panelReadableWidth(panelHalfWidth: CGFloat, edgeMargin: CGFloat, layoutScale s: CGFloat) -> CGFloat {
        let innerMargin = max(10, min(22, 14 * s))
        return min(size.width - 2 * edgeMargin - innerMargin, panelHalfWidth * 2 + max(44, min(72, 56 * s)))
    }

    /// EN: Small muted label above pill groups / RU: Приглушённая подпись над группами кнопок
    private func addSectionCaption(x: CGFloat, y: CGFloat, text: String, layoutScale s: CGFloat) {
        let cap = SKLabelNode(fontNamed: ".AppleSystemUIFontMedium")
        cap.fontSize = max(8.5, min(13.5, 10 * s))
        cap.fontColor = palette.captionText.withAlphaComponent(0.94)
        cap.text = text
        cap.horizontalAlignmentMode = .center
        // EN: Captions are positioned relative to the pills below; bottom alignment prevents descenders
        // from visually overlapping the controls on large scales.
        // RU: Подписи позиционируются относительно «пилюль» ниже; bottom-выравнивание убирает
        // «хвосты» букв вниз и предотвращает визуальное налезание при большом масштабе.
        cap.verticalAlignmentMode = .bottom
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
        fontPoints: CGFloat,
        layoutScale s: CGFloat,
        selected: Bool,
        enabled: Bool
    ) {
        // EN: Clamp font to pill height so labels never visually overlap adjacent pills on small heights.
        // RU: Ограничиваем шрифт по высоте «пилюли», чтобы текст не вылезал и не наезжал на соседние кнопки.
        let rawFontSize = max(8, min(17.5, fontPoints * s))
        let heightBound = max(8, height * 0.62)
        let fontSize = min(rawFontSize, heightBound)
        let corner = max(6, min(13, 8 * s))
        let shape = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: corner)
        shape.position = CGPoint(x: x, y: y)
        shape.name = enabled ? name : "\(name)_disabled"
        let lwBase = selected ? 2.25 : 1.15
        shape.lineWidth = max(1, min(3.2, lwBase * s))
        shape.strokeColor = enabled ? (selected ? palette.pillStrokeSelected : palette.pillStroke) : palette.pillTextDisabled
        shape.fillColor = enabled ? (selected ? palette.pillFillSelected : palette.pillFill) : palette.pillFill.withAlphaComponent(0.22)
        shape.zPosition = Layer.hud
        shape.alpha = enabled ? 1 : 0.45

        // EN: Soft glossy highlight on top half — adds tactility without contrast cost.
        // RU: Лёгкий «блик» в верхней половине — делает кнопку «живой» без потери контраста.
        if enabled {
            let glossH = height * 0.46
            let gloss = SKShapeNode(rectOf: CGSize(width: width - 4 * s, height: glossH), cornerRadius: max(4, corner - 2))
            gloss.fillColor = NSColor(calibratedWhite: 1, alpha: isDarkInterfaceActive ? 0.05 : 0.18)
            gloss.strokeColor = .clear
            gloss.position = CGPoint(x: 0, y: height * 0.5 - glossH * 0.5 - 1.5 * s)
            gloss.zPosition = 0.5
            shape.addChild(gloss)
        }

        let label = SKLabelNode(fontNamed: ".AppleSystemUIFont")
        label.name = enabled ? name : "\(name)_disabled"
        label.fontSize = fontSize
        label.fontColor = enabled ? palette.pillText : palette.pillTextDisabled
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.text = title
        shape.addChild(label)

        // EN: Pop-in animation when newly drawn — gives the panel a friendlier feel.
        // RU: Лёгкая «пружинка» при отрисовке — делает панель приятнее на старте.
        if enabled {
            shape.setScale(0.96)
            shape.run(SKAction.sequence([
                SKAction.scale(to: 1.03, duration: 0.10),
                SKAction.scale(to: 1.00, duration: 0.08),
            ]))
        }

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
                GameSoundFX.shared.playWinFanfare()
                animateOutcomeBanner(wasWin: true)
            }
        case .draw:
            statusLabel.text = L10n.draw
            if placed != nil {
                playDrawBoardFXIfNeeded()
                animateOutcomeBanner(wasWin: false)
            }
        }

        maybeRecordVsAIOutcome()
        updateStatsFooterText()
    }

    /// EN: Persist win/loss/draw and streak once when a vs-AI round leaves `inProgress`.
    /// RU: Один раз сохранить победу/поражение/ничью и серию, когда партия против ИИ завершилась.
    private func maybeRecordVsAIOutcome() {
        guard opponentMode == .humanComputer else { return }
        guard !roundOutcomeRecorded else { return }
        switch game.outcome() {
        case .inProgress:
            return
        case .win(let winner):
            roundOutcomeRecorded = true
            progress.applyVsAIOutcome(humanWon: winner == humanPlayer)
            GameProgressStore.save(progress)
        case .draw:
            roundOutcomeRecorded = true
            progress.applyVsAIOutcome(humanWon: nil)
            GameProgressStore.save(progress)
        }
    }

    private func updateStatsFooterText() {
        guard let root = statsStripRoot else { return }
        root.enumerateChildNodes(withName: "//stats_win_val") { n, _ in
            (n as? SKLabelNode)?.text = "\(self.progress.winsVsAI)"
        }
        root.enumerateChildNodes(withName: "//stats_loss_val") { n, _ in
            (n as? SKLabelNode)?.text = "\(self.progress.lossesVsAI)"
        }
        root.enumerateChildNodes(withName: "//stats_draw_val") { n, _ in
            (n as? SKLabelNode)?.text = "\(self.progress.drawsVsAI)"
        }
        let streakText = "\(L10n.statsStreak) \(progress.currentWinStreak)  ·  \(L10n.statsBest) \(progress.bestWinStreak)"
        root.enumerateChildNodes(withName: "//stats_streak_line") { n, _ in
            (n as? SKLabelNode)?.text = streakText
        }
    }

    private func themePillTitle(_ style: BoardVisualStyle) -> String {
        let name: String = switch style {
        case .classic:
            L10n.themeClassic
        case .aurora:
            L10n.themeAurora
        case .grove:
            L10n.themeGrove
        case .ember:
            L10n.themeEmber
        }
        if progress.unlockedThemes.contains(style) {
            return name
        }
        return name + L10n.themeLockedBadge
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
        let difficulty = progress.aiDifficulty

        aiThinkingTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 220_000_000)
            guard !Task.isCancelled else { return }
            let move = await Task.detached {
                TicTacToeAI.bestMove(for: ai, in: snapshot, difficulty: difficulty)
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
                    if self.game.outcome() == .inProgress {
                        GameSoundFX.shared.playMoveTap()
                    }
                    self.syncUI(animateMarkAt: (m.row, m.col))
                }
            }
        }
    }

    /// EN: Clears board model + visuals, preserves rule toggles, restarts AI opening if needed.
    /// RU: Очищает модель и визуал, сохраняет переключатели правил, при необходимости снова запускает открытие ИИ.
    private func restartRound() {
        bumpInputEpoch()
        roundOutcomeRecorded = false
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
            if name == "sound_toggle" {
                progress.soundEnabled.toggle()
                GameSoundFX.shared.soundEffectsEnabled = progress.soundEnabled
                GameProgressStore.save(progress)
                if progress.soundEnabled {
                    GameSoundFX.shared.playMoveTap()
                }
                rebuildLayout()
                return
            }
            if opponentMode == .humanComputer {
                if name == "ai_easy", progress.aiDifficulty != .easy {
                    progress.aiDifficulty = .easy
                    GameProgressStore.save(progress)
                    rebuildLayout()
                    return
                }
                if name == "ai_medium", progress.aiDifficulty != .medium {
                    progress.aiDifficulty = .medium
                    GameProgressStore.save(progress)
                    rebuildLayout()
                    return
                }
                if name == "ai_hard", progress.aiDifficulty != .hard {
                    progress.aiDifficulty = .hard
                    GameProgressStore.save(progress)
                    rebuildLayout()
                    return
                }
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
            if name.hasPrefix("theme_"),
               let style = BoardVisualStyle(rawValue: String(name.dropFirst(6))),
               progress.unlockedThemes.contains(style),
               progress.selectedTheme != style {
                progress.selectedTheme = style
                GameProgressStore.save(progress)
                rebuildLayout()
                return
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
                if game.outcome() == .inProgress {
                    GameSoundFX.shared.playMoveTap()
                }
                syncUI(animateMarkAt: (row, col))
                applyAIMoveIfNeeded()
            } catch {
                GameSoundFX.shared.playInvalidMove()
                break
            }
            return
        }
    }
}
