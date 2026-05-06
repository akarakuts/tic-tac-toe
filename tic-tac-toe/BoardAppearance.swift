import AppKit
import SpriteKit

// EN: Unlockable board colour themes layered on top of light/dark system chrome + accent tint.
// RU: Разблокируемые цветовые темы доски поверх светлой/тёмной системной хромы и акцента.

enum BoardVisualStyle: String, CaseIterable, Codable, Hashable, Sendable {
    case classic
    case aurora
    case grove
    case ember
}

/// EN: All colours/fonts tones for dark vs light `effectiveAppearance`, blended with system `accent`.
/// RU: Все цвета/тон для тёмной и светлой темы системы, смешение с системным акцентом.
struct BoardPalette: Sendable {
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

    init(style: BoardVisualStyle, darkMode: Bool, accent: NSColor) {
        switch style {
        case .classic:
            self.init(classicDarkMode: darkMode, accent: accent)
        case .aurora:
            self.init(auroraDarkMode: darkMode, accent: accent)
        case .grove:
            self.init(groveDarkMode: darkMode, accent: accent)
        case .ember:
            self.init(emberDarkMode: darkMode, accent: accent)
        }
    }

    /// EN: Original cosmic boardroom / clean paper palette.
    /// RU: Исходная палитра «космический салон» / «чистая бумага».
    private init(classicDarkMode darkMode: Bool, accent: NSColor) {
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

    /// EN: Violet / teal northern-lights mood.
    /// RU: Фиолетово-бирюзовое настроение «северное сияние».
    private init(auroraDarkMode darkMode: Bool, accent: NSColor) {
        if darkMode {
            sceneBackground = NSColor(calibratedHue: 0.76, saturation: 0.35, brightness: 0.09, alpha: 1)
            panelFill = NSColor(calibratedHue: 0.72, saturation: 0.12, brightness: 1, alpha: 0.07)
            panelStroke = NSColor(calibratedWhite: 1, alpha: 0.12)
            boardShadow = NSColor(calibratedHue: 0.78, saturation: 0.6, brightness: 0.05, alpha: 0.55)
            boardPlaqueFill = NSColor(calibratedHue: 0.74, saturation: 0.22, brightness: 0.14, alpha: 1)
            boardPlaqueStroke = accent.withAlphaComponent(0.45)
            cellEven = NSColor(calibratedHue: 0.73, saturation: 0.28, brightness: 0.22, alpha: 1)
            cellOdd = NSColor(calibratedHue: 0.76, saturation: 0.22, brightness: 0.17, alpha: 1)
            gridLine = NSColor(calibratedHue: 0.72, saturation: 0.06, brightness: 1, alpha: 0.14)
            gridOuter = NSColor(calibratedHue: 0.68, saturation: 0.1, brightness: 1, alpha: 0.32)
            crossMark = NSColor(calibratedHue: 0.92, saturation: 0.55, brightness: 1, alpha: 1)
            noughtMark = NSColor(calibratedHue: 0.52, saturation: 0.45, brightness: 0.92, alpha: 1)
            statusText = NSColor(calibratedWhite: 0.96, alpha: 1)
            captionText = NSColor(calibratedHue: 0.72, saturation: 0.05, brightness: 0.72, alpha: 1)
            pillFill = NSColor(calibratedWhite: 1, alpha: 0.06)
            pillFillSelected = accent.withAlphaComponent(0.28)
            pillStroke = NSColor(calibratedWhite: 1, alpha: 0.15)
            pillStrokeSelected = accent
            pillText = NSColor(calibratedWhite: 0.93, alpha: 1)
            pillTextDisabled = NSColor(calibratedWhite: 0.38, alpha: 1)
            newGameFill = accent.withAlphaComponent(0.36)
            newGameStroke = accent.withAlphaComponent(0.74)
            newGameLabel = NSColor(calibratedWhite: 0.98, alpha: 1)
            winLine = NSColor(calibratedHue: 0.14, saturation: 0.85, brightness: 1, alpha: 1)
        } else {
            sceneBackground = NSColor(calibratedHue: 0.72, saturation: 0.06, brightness: 0.97, alpha: 1)
            panelFill = NSColor(calibratedWhite: 1, alpha: 0.82)
            panelStroke = NSColor(calibratedHue: 0.7, saturation: 0.12, brightness: 0.82, alpha: 0.38)
            boardShadow = NSColor(calibratedHue: 0.74, saturation: 0.2, brightness: 0.62, alpha: 0.2)
            boardPlaqueFill = NSColor(calibratedHue: 0.72, saturation: 0.03, brightness: 1, alpha: 1)
            boardPlaqueStroke = accent.withAlphaComponent(0.4)
            cellEven = NSColor(calibratedHue: 0.68, saturation: 0.07, brightness: 0.97, alpha: 1)
            cellOdd = NSColor(calibratedHue: 0.74, saturation: 0.06, brightness: 0.94, alpha: 1)
            gridLine = NSColor(calibratedHue: 0.66, saturation: 0.12, brightness: 0.72, alpha: 0.5)
            gridOuter = NSColor(calibratedHue: 0.68, saturation: 0.18, brightness: 0.58, alpha: 0.62)
            crossMark = NSColor(calibratedHue: 0.78, saturation: 0.62, brightness: 0.52, alpha: 1)
            noughtMark = NSColor(calibratedHue: 0.52, saturation: 0.42, brightness: 0.48, alpha: 1)
            statusText = NSColor(calibratedHue: 0.74, saturation: 0.38, brightness: 0.22, alpha: 1)
            captionText = NSColor(calibratedHue: 0.65, saturation: 0.08, brightness: 0.42, alpha: 1)
            pillFill = NSColor(calibratedWhite: 1, alpha: 0.92)
            pillFillSelected = accent.withAlphaComponent(0.22)
            pillStroke = NSColor(calibratedHue: 0.62, saturation: 0.08, brightness: 0.78, alpha: 0.68)
            pillStrokeSelected = accent
            pillText = NSColor(calibratedHue: 0.72, saturation: 0.32, brightness: 0.18, alpha: 1)
            pillTextDisabled = NSColor(calibratedHue: 0.58, saturation: 0.04, brightness: 0.62, alpha: 1)
            newGameFill = accent.withAlphaComponent(0.26)
            newGameStroke = accent.withAlphaComponent(0.56)
            newGameLabel = NSColor(calibratedHue: 0.74, saturation: 0.38, brightness: 0.14, alpha: 1)
            winLine = NSColor(calibratedHue: 0.86, saturation: 0.75, brightness: 0.55, alpha: 1)
        }
    }

    /// EN: Moss / pine forest calm greens.
    /// RU: Спокойные зелёные тона «мох и хвоя».
    private init(groveDarkMode darkMode: Bool, accent: NSColor) {
        if darkMode {
            sceneBackground = NSColor(calibratedHue: 0.38, saturation: 0.28, brightness: 0.08, alpha: 1)
            panelFill = NSColor(calibratedHue: 0.35, saturation: 0.08, brightness: 1, alpha: 0.055)
            panelStroke = NSColor(calibratedWhite: 1, alpha: 0.1)
            boardShadow = NSColor(calibratedHue: 0.32, saturation: 0.45, brightness: 0.05, alpha: 0.52)
            boardPlaqueFill = NSColor(calibratedHue: 0.36, saturation: 0.18, brightness: 0.13, alpha: 1)
            boardPlaqueStroke = accent.withAlphaComponent(0.42)
            cellEven = NSColor(calibratedHue: 0.37, saturation: 0.22, brightness: 0.2, alpha: 1)
            cellOdd = NSColor(calibratedHue: 0.33, saturation: 0.18, brightness: 0.15, alpha: 1)
            gridLine = NSColor(calibratedHue: 0.38, saturation: 0.06, brightness: 1, alpha: 0.12)
            gridOuter = NSColor(calibratedHue: 0.36, saturation: 0.08, brightness: 1, alpha: 0.28)
            crossMark = NSColor(calibratedHue: 0.12, saturation: 0.65, brightness: 0.95, alpha: 1)
            noughtMark = NSColor(calibratedHue: 0.44, saturation: 0.35, brightness: 0.88, alpha: 1)
            statusText = NSColor(calibratedHue: 0.28, saturation: 0.05, brightness: 0.96, alpha: 1)
            captionText = NSColor(calibratedHue: 0.33, saturation: 0.06, brightness: 0.62, alpha: 1)
            pillFill = NSColor(calibratedWhite: 1, alpha: 0.055)
            pillFillSelected = accent.withAlphaComponent(0.26)
            pillStroke = NSColor(calibratedWhite: 1, alpha: 0.14)
            pillStrokeSelected = accent
            pillText = NSColor(calibratedWhite: 0.93, alpha: 1)
            pillTextDisabled = NSColor(calibratedWhite: 0.36, alpha: 1)
            newGameFill = accent.withAlphaComponent(0.34)
            newGameStroke = accent.withAlphaComponent(0.72)
            newGameLabel = NSColor(calibratedWhite: 0.98, alpha: 1)
            winLine = NSColor(calibratedHue: 0.14, saturation: 0.9, brightness: 1, alpha: 1)
        } else {
            sceneBackground = NSColor(calibratedHue: 0.31, saturation: 0.07, brightness: 0.96, alpha: 1)
            panelFill = NSColor(calibratedWhite: 1, alpha: 0.78)
            panelStroke = NSColor(calibratedHue: 0.33, saturation: 0.12, brightness: 0.78, alpha: 0.36)
            boardShadow = NSColor(calibratedHue: 0.35, saturation: 0.18, brightness: 0.58, alpha: 0.2)
            boardPlaqueFill = NSColor(calibratedHue: 0.29, saturation: 0.04, brightness: 0.995, alpha: 1)
            boardPlaqueStroke = accent.withAlphaComponent(0.38)
            cellEven = NSColor(calibratedHue: 0.32, saturation: 0.09, brightness: 0.96, alpha: 1)
            cellOdd = NSColor(calibratedHue: 0.28, saturation: 0.07, brightness: 0.93, alpha: 1)
            gridLine = NSColor(calibratedHue: 0.34, saturation: 0.12, brightness: 0.68, alpha: 0.48)
            gridOuter = NSColor(calibratedHue: 0.36, saturation: 0.18, brightness: 0.54, alpha: 0.58)
            crossMark = NSColor(calibratedHue: 0.03, saturation: 0.68, brightness: 0.52, alpha: 1)
            noughtMark = NSColor(calibratedHue: 0.42, saturation: 0.48, brightness: 0.42, alpha: 1)
            statusText = NSColor(calibratedHue: 0.33, saturation: 0.38, brightness: 0.22, alpha: 1)
            captionText = NSColor(calibratedHue: 0.32, saturation: 0.08, brightness: 0.42, alpha: 1)
            pillFill = NSColor(calibratedWhite: 1, alpha: 0.92)
            pillFillSelected = accent.withAlphaComponent(0.2)
            pillStroke = NSColor(calibratedHue: 0.34, saturation: 0.08, brightness: 0.76, alpha: 0.66)
            pillStrokeSelected = accent
            pillText = NSColor(calibratedHue: 0.34, saturation: 0.3, brightness: 0.17, alpha: 1)
            pillTextDisabled = NSColor(calibratedHue: 0.32, saturation: 0.04, brightness: 0.6, alpha: 1)
            newGameFill = accent.withAlphaComponent(0.26)
            newGameStroke = accent.withAlphaComponent(0.54)
            newGameLabel = NSColor(calibratedHue: 0.34, saturation: 0.36, brightness: 0.14, alpha: 1)
            winLine = NSColor(calibratedHue: 0.08, saturation: 0.82, brightness: 0.92, alpha: 1)
        }
    }

    /// EN: Ember / sunset warmth.
    /// RU: Тёплые тона «закат и угли».
    private init(emberDarkMode darkMode: Bool, accent: NSColor) {
        if darkMode {
            sceneBackground = NSColor(calibratedHue: 0.06, saturation: 0.35, brightness: 0.09, alpha: 1)
            panelFill = NSColor(calibratedHue: 0.08, saturation: 0.12, brightness: 1, alpha: 0.055)
            panelStroke = NSColor(calibratedWhite: 1, alpha: 0.11)
            boardShadow = NSColor(calibratedHue: 0.03, saturation: 0.55, brightness: 0.05, alpha: 0.55)
            boardPlaqueFill = NSColor(calibratedHue: 0.07, saturation: 0.22, brightness: 0.14, alpha: 1)
            boardPlaqueStroke = accent.withAlphaComponent(0.44)
            cellEven = NSColor(calibratedHue: 0.06, saturation: 0.28, brightness: 0.22, alpha: 1)
            cellOdd = NSColor(calibratedHue: 0.04, saturation: 0.22, brightness: 0.17, alpha: 1)
            gridLine = NSColor(calibratedHue: 0.1, saturation: 0.08, brightness: 1, alpha: 0.13)
            gridOuter = NSColor(calibratedHue: 0.08, saturation: 0.1, brightness: 1, alpha: 0.3)
            crossMark = NSColor(calibratedHue: 0.02, saturation: 0.75, brightness: 1, alpha: 1)
            noughtMark = NSColor(calibratedHue: 0.12, saturation: 0.55, brightness: 0.98, alpha: 1)
            statusText = NSColor(calibratedHue: 0.09, saturation: 0.08, brightness: 0.98, alpha: 1)
            captionText = NSColor(calibratedHue: 0.08, saturation: 0.06, brightness: 0.63, alpha: 1)
            pillFill = NSColor(calibratedWhite: 1, alpha: 0.055)
            pillFillSelected = accent.withAlphaComponent(0.27)
            pillStroke = NSColor(calibratedWhite: 1, alpha: 0.15)
            pillStrokeSelected = accent
            pillText = NSColor(calibratedWhite: 0.93, alpha: 1)
            pillTextDisabled = NSColor(calibratedWhite: 0.36, alpha: 1)
            newGameFill = accent.withAlphaComponent(0.35)
            newGameStroke = accent.withAlphaComponent(0.73)
            newGameLabel = NSColor(calibratedWhite: 0.98, alpha: 1)
            winLine = NSColor(calibratedHue: 0.15, saturation: 0.95, brightness: 1, alpha: 1)
        } else {
            sceneBackground = NSColor(calibratedHue: 0.09, saturation: 0.09, brightness: 0.97, alpha: 1)
            panelFill = NSColor(calibratedWhite: 1, alpha: 0.78)
            panelStroke = NSColor(calibratedHue: 0.08, saturation: 0.14, brightness: 0.82, alpha: 0.38)
            boardShadow = NSColor(calibratedHue: 0.06, saturation: 0.22, brightness: 0.62, alpha: 0.22)
            boardPlaqueFill = NSColor(calibratedHue: 0.1, saturation: 0.03, brightness: 1, alpha: 1)
            boardPlaqueStroke = accent.withAlphaComponent(0.39)
            cellEven = NSColor(calibratedHue: 0.09, saturation: 0.09, brightness: 0.97, alpha: 1)
            cellOdd = NSColor(calibratedHue: 0.07, saturation: 0.06, brightness: 0.935, alpha: 1)
            gridLine = NSColor(calibratedHue: 0.06, saturation: 0.12, brightness: 0.72, alpha: 0.52)
            gridOuter = NSColor(calibratedHue: 0.05, saturation: 0.16, brightness: 0.56, alpha: 0.62)
            crossMark = NSColor(calibratedHue: 0.98, saturation: 0.72, brightness: 0.52, alpha: 1)
            noughtMark = NSColor(calibratedHue: 0.09, saturation: 0.62, brightness: 0.48, alpha: 1)
            statusText = NSColor(calibratedHue: 0.06, saturation: 0.42, brightness: 0.22, alpha: 1)
            captionText = NSColor(calibratedHue: 0.08, saturation: 0.08, brightness: 0.42, alpha: 1)
            pillFill = NSColor(calibratedWhite: 1, alpha: 0.92)
            pillFillSelected = accent.withAlphaComponent(0.21)
            pillStroke = NSColor(calibratedHue: 0.08, saturation: 0.08, brightness: 0.77, alpha: 0.68)
            pillStrokeSelected = accent
            pillText = NSColor(calibratedHue: 0.06, saturation: 0.34, brightness: 0.17, alpha: 1)
            pillTextDisabled = NSColor(calibratedHue: 0.06, saturation: 0.04, brightness: 0.61, alpha: 1)
            newGameFill = accent.withAlphaComponent(0.27)
            newGameStroke = accent.withAlphaComponent(0.56)
            newGameLabel = NSColor(calibratedHue: 0.05, saturation: 0.4, brightness: 0.14, alpha: 1)
            winLine = NSColor(calibratedHue: 0.08, saturation: 0.85, brightness: 0.55, alpha: 1)
        }
    }
}
