import AppKit
import SpriteKit

// EN: Main SpriteKit scene — themed HUD, responsive board layout, mouse input, async AI moves, win/draw FX.
// RU: Основная SpriteKit-сцена — темизированный HUD, адаптивное поле, мышь, асинхронный ход ИИ, эффекты победы/ничьей.

@MainActor
final class GameScene: SKScene {

    /// EN: Theme snapshot rebuilt whenever layout or system appearance-driven colours refresh.
    /// RU: Снимок темы пересобирается при смене раскладки или цветов из темы системы.
    var palette: BoardPalette!

    /// EN: Wins/losses vs AI, streaks, unlocks — persisted.
    /// RU: Победы/поражения против ИИ, серии, разблокировки — сохраняются.
    var progress = GameProgressStore.load()

    /// EN: VS AI stats card (rebuilt with layout; values refreshed in `updateStatsFooterText`).
    /// RU: Карточка статистики против ИИ (пересборка в раскладке; значения в `updateStatsFooterText`).
    var statsStripRoot: SKNode!

    /// EN: Ensures one persistence write per finished round vs AI.
    /// RU: Одно сохранение за завершённый раунд против ИИ.
    private var roundOutcomeRecorded = false

    // EN: Rule/UI settings kept alongside `game` so `rebuildLayout()` can reconstruct `GameModel` safely.
    // RU: Настройки правил/UI рядом с `game`, чтобы `rebuildLayout()` мог безопасно пересоздать `GameModel`.
    private var boardSize = 3
    private var winLength = 3
    var game = GameModel(boardSize: 3, winLength: 3)

    private var opponentMode: OpponentMode = .humanHuman
    private var humanPlayer: Player = .x

    private var cellNodes: [String: SKNode] = [:]
    private var markNodes: [String: SKLabelNode] = [:]

    /// EN: Root node for grid geometry (lines, plaque, cells); positioned at board centre.
    /// RU: Корневой узел геометрии сетки (линии, подложка, клетки); позиционируется в центре доски.
    var boardGrid: SKNode!
    /// EN: Cached half-side of square board and cell edge length — used by win-line overlay math.
    /// RU: Кэш половины стороны квадратного поля и размера ячейки — для линии победы и подсветки.
    var boardHalfBoard: CGFloat = 0
    var boardCellSide: CGFloat = 0

    private var winHighlightLine: SKShapeNode?

    var statusLabel: SKLabelNode!
    var newGameButton: SKShapeNode!

    /// EN: Ensures draw FX runs once per finished round.
    /// RU: Гарантирует однократное воспроизведение эффекта при ничьей за раунд.
    private var didPlayDrawFX = false

    /// EN: Monotonic counter so stale async AI tasks ignore outdated board/settings after user changes.
    /// RU: Монотонный счётчик: устаревшие асинхронные задачи ИИ игнорируют старое поле/настройки после действий пользователя.
    private var inputEpoch = 0
    private var aiThinkingTask: Task<Void, Never>?

    /// EN: Keyboard focus cell — arrow keys move, Return confirms move.
    /// RU: Фокус клавиатуры на клетке — стрелки двигают, Return ставит символ.
    var keyboardFocusRow = 1
    var keyboardFocusCol = 1
    var focusRingNode: SKShapeNode?

    /// EN: System appearance subscription — `SKView.window` is often nil on first `didMove`, so we also listen for global changes.
    /// RU: Подписка на тему — при первом `didMove` у `SKView` часто ещё нет `window`, плюс слушаем смену темы глобально.
    private var appearanceChangeObserver: NSObjectProtocol?

    /// EN: Resolves light/dark from the window when attached, otherwise from `NSApp` (correct at cold launch).
    /// RU: Светлая/тёмная тема из окна, если оно уже есть, иначе из `NSApp` (корректно при холодном старте).
    var isDarkInterfaceActive: Bool {
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
        applyPersistedSettings()
        view.window?.makeFirstResponder(view)
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
    private func applyPersistedSettings() {
        opponentMode = progress.opponentMode
        boardSize = progress.boardSize
        winLength = progress.winLength
        humanPlayer = progress.humanPlayer
        game = GameModel(boardSize: boardSize, winLength: winLength)
    }

    private func syncSettingsToProgress() {
        progress.opponentMode = opponentMode
        progress.setBoardSize(boardSize)
        progress.setWinLength(winLength)
        progress.setHumanPlayer(humanPlayer)
        GameProgressStore.save(progress)
    }

    private func applyBoardConfiguration() {
        bumpInputEpoch()
        roundOutcomeRecorded = false
        if winLength > boardSize {
            winLength = boardSize
        }
        syncSettingsToProgress()
        game = GameModel(boardSize: boardSize, winLength: winLength)
        rebuildLayout()
    }

    var isHumanTurn: Bool {
        opponentMode == .humanHuman || game.currentPlayer == humanPlayer
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
        statusLabel.zPosition = GameSceneLayer.hud
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
        newGameButton.zPosition = GameSceneLayer.hud
        addChild(newGameButton)

        let newGameLabel = SKLabelNode(fontNamed: ".AppleSystemUIFontSemibold")
        newGameLabel.fontSize = max(13, min(20, size.height * 0.021 * hudScale))
        newGameLabel.fontColor = palette.newGameLabel
        newGameLabel.verticalAlignmentMode = .center
        newGameLabel.text = L10n.newGame
        newGameLabel.position = CGPoint(x: panelCenterX, y: cy)
        newGameLabel.zPosition = GameSceneLayer.hud + 1
        addChild(newGameLabel)

        let statsCard = makeVsAiStatsCard(width: hudCardW, layoutScale: hudScale)
        let statsH = statsCard.height
        cy += newGameH * 0.5 + bandGap + statsH * 0.5
        statsStripRoot = statsCard.node
        statsStripRoot.position = CGPoint(x: panelCenterX, y: cy)
        statsStripRoot.zPosition = GameSceneLayer.hud
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
        panelBackdrop.zPosition = GameSceneLayer.panelBackdrop
        insertChild(panelBackdrop, at: 0)

        // EN: Place theme legend under the board / RU: Легенда тем — под доской.
        themeLegendRow.node.position = CGPoint(x: boardCenterX, y: sceneBottomY + legendH * 0.5)
        themeLegendRow.node.zPosition = GameSceneLayer.hud
        addChild(themeLegendRow.node)

        let board = BoardRenderer.build(
            boardSize: n,
            boardSide: boardSide,
            center: CGPoint(x: boardCenterX, y: boardCenterY),
            palette: palette
        )
        boardGrid = board.grid
        boardHalfBoard = board.halfBoard
        boardCellSide = board.cellSide
        cellNodes = board.cellNodes
        markNodes = board.markNodes
        addChild(board.grid)

        keyboardFocusRow = min(keyboardFocusRow, n - 1)
        keyboardFocusCol = min(keyboardFocusCol, n - 1)
        refreshFocusRing()

        didPlayDrawFX = false
        syncUI()
        applyAIMoveIfNeeded()

        playLayoutIntro()
        animateNewGameButtonPulse()
    }

    /// EN: Rounded VS AI stats card — triple metric row + streak footer / RU: Карточка статистики против ИИ.
    private static func cellKey(row: Int, col: Int) -> String {
        "cell_\(row)_\(col)"
    }

    /// EN: Push model → sprites (glyph colours, optional place animation), status text, win overlay.
    /// RU: Модель → спрайты (цвет символа, анимация хода), строка статуса, подсветка победы.
    private func syncUI(animateMarkAt placed: (row: Int, col: Int)? = nil) {
        let n = game.boardSize
        let animatedKey: String? = placed.map { GameSceneLayout.cellKey(row: $0.row, col: $0.col) }

        for row in 0..<n {
            for col in 0..<n {
                let key = GameSceneLayout.cellKey(row: row, col: col)
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
        updateAccessibilitySummary()
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
        line.zPosition = GameSceneLayer.winLine
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
    func restartRound() {
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

    func performMove(row: Int, col: Int) {
        guard game.outcome() == .inProgress, isHumanTurn else { return }
        do {
            try game.play(at: row, col: col)
            if game.outcome() == .inProgress {
                GameSoundFX.shared.playMoveTap()
            }
            syncUI(animateMarkAt: (row, col))
            applyAIMoveIfNeeded()
        } catch {
            GameSoundFX.shared.playInvalidMove()
        }
    }

    func handleInputAction(_ action: GameInputAction) {
        switch action {
        case .newGame:
            restartRound()
        case .setBoardSize(let s):
            guard s != boardSize else { return }
            boardSize = s
            if winLength > boardSize { winLength = boardSize }
            applyBoardConfiguration()
        case .setWinLength(let k):
            guard k != winLength, k <= boardSize else { return }
            winLength = k
            applyBoardConfiguration()
        case .setOpponentMode(let next):
            guard next != opponentMode else { return }
            opponentMode = next
            applyBoardConfiguration()
        case .toggleSound:
            progress.soundEnabled.toggle()
            GameSoundFX.shared.soundEffectsEnabled = progress.soundEnabled
            GameProgressStore.save(progress)
            if progress.soundEnabled { GameSoundFX.shared.playMoveTap() }
            rebuildLayout()
        case .setAIDifficulty(let d):
            guard progress.aiDifficulty != d else { return }
            progress.aiDifficulty = d
            GameProgressStore.save(progress)
            rebuildLayout()
        case .setHumanPlayer(let p):
            guard humanPlayer != p else { return }
            humanPlayer = p
            applyBoardConfiguration()
        case .setTheme(let style):
            guard progress.unlockedThemes.contains(style), progress.selectedTheme != style else { return }
            progress.selectedTheme = style
            GameProgressStore.save(progress)
            rebuildLayout()
        case .playCell(let row, let col):
            keyboardFocusRow = row
            keyboardFocusCol = col
            refreshFocusRing()
            performMove(row: row, col: col)
        }
    }

    /// EN: Hit-test stack resolves HUD pills first, then board cells; respects finished game + AI turn locks.
    /// RU: Стек попаданий: сначала HUD, затем клетки; учитывается конец партии и блокировка хода при очереди ИИ.
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let hits = nodes(at: location)
        guard let action = GameInputHandler.firstAction(
            from: hits,
            boardSize: boardSize,
            opponentMode: opponentMode,
            gameInProgress: game.outcome() == .inProgress,
            isHumanTurn: isHumanTurn
        ) else { return }
        handleInputAction(action)
    }
}
