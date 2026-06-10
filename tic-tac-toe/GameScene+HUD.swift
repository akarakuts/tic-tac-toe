import AppKit
import SpriteKit

// EN: Left HUD panel builders — extracted from GameScene.
// RU: Сборка левой панели HUD — вынесена из GameScene.

extension GameScene {
    /// EN: Rounded VS AI stats card — triple metric row + streak footer / RU: Карточка статистики против ИИ.
    func makeVsAiStatsCard(width: CGFloat, layoutScale s: CGFloat) -> (node: SKNode, height: CGFloat) {
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


    /// EN: Two-line readable theme legend placed under the board.
    /// RU: Двухстрочная читаемая легенда тем под игровым полем.
    func makeThemeUnlockLegendRow(width: CGFloat, layoutScale s: CGFloat) -> (node: SKNode, height: CGFloat) {
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

        let details = SKLabelNode(fontNamed: ".AppleSystemUIFontMedium")
        details.fontSize = detailsFont
        details.fontColor = palette.captionText.withAlphaComponent(0.9)
        details.text = L10n.themeUnlockLegendDetails
        details.horizontalAlignmentMode = .center
        details.verticalAlignmentMode = .center
        details.position = CGPoint(x: 0, y: -(lineGap + titleFont) * 0.5)
        details.zPosition = 1
        root.addChild(details)

        return (root, h)
    }

    /// EN: Soft decorative auras behind the whole scene to add depth and warmth.
    /// RU: Мягкие декоративные «ауры» в фоне сцены — добавляют глубину и теплоту.
    func addBackdropAuras() {
        let darkMode = isDarkInterfaceActive
        let topRadius = max(size.width, size.height) * 0.55
        let bottomRadius = max(size.width, size.height) * 0.42

        let topGlow = SKShapeNode(circleOfRadius: topRadius)
        topGlow.fillColor = palette.pillStrokeSelected.withAlphaComponent(darkMode ? 0.16 : 0.12)
        topGlow.strokeColor = .clear
        topGlow.glowWidth = max(40, topRadius * 0.35)
        topGlow.position = CGPoint(x: size.width * 0.32, y: size.height * 0.36)
        topGlow.zPosition = GameSceneLayer.backdropDecor
        topGlow.alpha = 0.85
        topGlow.blendMode = .add
        addChild(topGlow)

        let bottomGlow = SKShapeNode(circleOfRadius: bottomRadius)
        bottomGlow.fillColor = palette.crossMark.withAlphaComponent(darkMode ? 0.10 : 0.07)
        bottomGlow.strokeColor = .clear
        bottomGlow.glowWidth = max(40, bottomRadius * 0.35)
        bottomGlow.position = CGPoint(x: -size.width * 0.32, y: -size.height * 0.30)
        bottomGlow.zPosition = GameSceneLayer.backdropDecor
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
    func playLayoutIntro() {
        for child in children {
            let base = child.alpha
            child.alpha = 0
            child.run(SKAction.fadeAlpha(to: base, duration: 0.22))
        }
    }

    /// EN: Friendly heartbeat-style pulse on the New game button stroke.
    /// RU: Дружелюбный «пульс» обводки кнопки «Новая игра».
    func animateNewGameButtonPulse() {
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
    func panelReadableWidth(panelHalfWidth: CGFloat, edgeMargin: CGFloat, layoutScale s: CGFloat) -> CGFloat {
        let innerMargin = max(10, min(22, 14 * s))
        return min(size.width - 2 * edgeMargin - innerMargin, panelHalfWidth * 2 + max(44, min(72, 56 * s)))
    }

    /// EN: Small muted label above pill groups / RU: Приглушённая подпись над группами кнопок
    func addSectionCaption(x: CGFloat, y: CGFloat, text: String, layoutScale s: CGFloat) {
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
        cap.zPosition = GameSceneLayer.hud
        addChild(cap)
    }

    /// EN: Hit-testable rounded HUD button; `_disabled` suffix when inactive so clicks ignore logically disabled picks.
    /// RU: Кликабельная «пилюля» HUD; суффикс `_disabled` при неактивном варианте, чтобы клики не проходили.
    func makePill(
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
        shape.zPosition = GameSceneLayer.hud
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
}
