// EN: Opponent AI — minimax with alpha-beta, depth limits on large boards, and tactical win/block moves.
// RU: ИИ соперника — минимакс с альфа-бета отсечением, лимит глубины на больших полях и тактика выигрыша/блока.

enum OpponentMode: Equatable, Sendable {
    case humanHuman
    case humanComputer
}

enum TicTacToeAI: Sendable {

    /// EN: Best reply for `aiPlayer` from `state`, or nil if not AI turn or game over.
    /// RU: Лучший ответ для `aiPlayer` из позиции `state`, или nil если не ход ИИ или партия окончена.
    static func bestMove(for aiPlayer: Player, in state: GameModel) -> (row: Int, col: Int)? {
        guard state.outcome() == .inProgress else { return nil }
        guard state.currentPlayer == aiPlayer else { return nil }

        // EN: One-ply tactics before expensive search / RU: Одноходовые тактики перед тяжёлым перебором
        if let win = immediateWinningMove(ai: aiPlayer, in: state) {
            return win
        }
        if let block = immediateBlockMove(ai: aiPlayer, in: state) {
            return block
        }

        let plyBudget = searchPliesRemaining(for: state)

        var best: (row: Int, col: Int)?
        var bestScore = Int.min

        for (row, col) in orderedEmptyCells(state: state) {
            var next = state
            guard (try? next.play(at: row, col: col)) != nil else { continue }
            let aiMovesNext = next.currentPlayer == aiPlayer
            let score = minimax(
                state: next,
                ai: aiPlayer,
                maximizingAI: aiMovesNext,
                alpha: Int.min,
                beta: Int.max,
                depth: 1,
                plyRemaining: plyBudget - 1
            )
            if score > bestScore {
                bestScore = score
                best = (row, col)
            }
        }
        return best
    }

    /// EN: Full-depth search only on 3×3; larger boards need a ply cap or minimax never finishes.
    /// RU: Полный перебор только на 3×3; на больших полях нужен лимит полуходов, иначе минимакс не завершится.
    private static func searchPliesRemaining(for state: GameModel) -> Int {
        switch state.boardSize {
        case 3:
            return 64
        case 4:
            return 6
        case 5:
            return 5
        default:
            return 4
        }
    }

    /// EN: Empty cell where AI moving now yields immediate win.
    /// RU: Пустая клетка: если ИИ ходит сюда сейчас — мгновенная победа.
    private static func immediateWinningMove(ai: Player, in state: GameModel) -> (Int, Int)? {
        let n = state.boardSize
        for row in 0..<n {
            for col in 0..<n {
                guard state.cell(at: row, col: col) == .empty else { continue }
                var next = state
                guard (try? next.play(at: row, col: col)) != nil else { continue }
                if next.outcome() == .win(ai) {
                    return (row, col)
                }
            }
        }
        return nil
    }

    /// EN: Empty cell the opponent would use to complete `winLength` in one move — must block.
    /// RU: Пустая клетка, где соперник замкнёт линию из `winLength` одним ходом — нужно блокировать.
    private static func immediateBlockMove(ai: Player, in state: GameModel) -> (Int, Int)? {
        let opp = ai.other
        let n = state.boardSize
        for row in 0..<n {
            for col in 0..<n {
                guard state.cell(at: row, col: col) == .empty else { continue }
                if completesWinLine(for: opp, row: row, col: col, in: state) {
                    return (row, col)
                }
            }
        }
        return nil
    }

    /// EN: True if placing `player` at (row,col) completes a full winning segment on some line through that cell.
    /// RU: Истина, если постановка `player` в (row,col) завершает выигрышный отрезок по какой-то линии через эту клетку.
    private static func completesWinLine(for player: Player, row: Int, col: Int, in state: GameModel) -> Bool {
        let n = state.boardSize
        let w = state.winLength
        let idx = row * n + col
        let lines = GameModel.makeWinLines(boardSize: n, winLength: w)
        lineLoop: for line in lines {
            guard line.contains(idx) else { continue }
            var pCount = 0
            var emptyCount = 0
            for i in line {
                let r = i / n
                let c = i % n
                switch state.cell(at: r, col: c) {
                case .empty:
                    emptyCount += 1
                case let .occupied(p):
                    if p == player {
                        pCount += 1
                    } else {
                        continue lineLoop
                    }
                }
            }
            if emptyCount == 1, pCount == w - 1 {
                return true
            }
        }
        return false
    }

    /// EN: Heuristic at search cutoff — rewards AI threats, penalizes opponent threats on open lines.
    /// RU: Эвристика на обрезке по глубине — поощряет угрозы ИИ, штрафует угрозы соперника на открытых линиях.
    private static func evaluateStatic(state: GameModel, ai: Player) -> Int {
        let opp = ai.other
        let lines = GameModel.makeWinLines(boardSize: state.boardSize, winLength: state.winLength)
        var score = 0
        let n = state.boardSize
        for line in lines {
            var aiCount = 0
            var oppCount = 0
            var emptyCount = 0
            for idx in line {
                let row = idx / n
                let col = idx % n
                switch state.cell(at: row, col: col) {
                case .empty:
                    emptyCount += 1
                case let .occupied(p):
                    if p == ai { aiCount += 1 }
                    else if p == opp { oppCount += 1 }
                }
            }
            if oppCount == 0, aiCount > 0 {
                score += aiCount * aiCount * 8 + emptyCount * 2
            }
            if aiCount == 0, oppCount > 0 {
                score -= oppCount * oppCount * 8 + emptyCount * 2
            }
        }
        return score
    }

    /// EN: Empty cells sorted by local density — explores promising moves first for alpha-beta pruning.
    /// RU: Пустые клетки, отсортированные по плотности соседей — сначала перспективные ходы для альфа-бета отсечения.
    private static func orderedEmptyCells(state: GameModel) -> [(Int, Int)] {
        let n = state.boardSize
        var cells: [(Int, Int)] = []
        for row in 0..<n {
            for col in 0..<n {
                if state.cell(at: row, col: col) == .empty {
                    cells.append((row, col))
                }
            }
        }

        func neighborsOccupied(_ row: Int, _ col: Int) -> Int {
            var count = 0
            for dr in -1...1 {
                for dc in -1...1 {
                    if dr == 0 && dc == 0 { continue }
                    let nr = row + dr
                    let nc = col + dc
                    guard (0..<n).contains(nr), (0..<n).contains(nc) else { continue }
                    if case .occupied = state.cell(at: nr, col: nc) {
                        count += 1
                    }
                }
            }
            return count
        }

        return cells.sorted { neighborsOccupied($0.0, $0.1) > neighborsOccupied($1.0, $1.1) }
    }

    /// EN: Minimax with alpha-beta; terminal scores favour wins earlier via `1000 - depth`.
    /// RU: Минимакс с альфа-бета; терминальные оценки учитывают «раннюю» победу через `1000 - depth`.
    private static func minimax(
        state: GameModel,
        ai: Player,
        maximizingAI: Bool,
        alpha: Int,
        beta: Int,
        depth: Int,
        plyRemaining: Int
    ) -> Int {
        switch state.outcome() {
        case .win(let winner):
            let magnitude = 1000 - depth
            return winner == ai ? magnitude : -magnitude
        case .draw:
            return 0
        case .inProgress:
            break
        }

        if plyRemaining <= 0 {
            return evaluateStatic(state: state, ai: ai)
        }

        let moves = movesForMinimax(state: state, plyRemaining: plyRemaining)

        if maximizingAI {
            var value = Int.min
            var a = alpha
            for (row, col) in moves {
                var next = state
                guard (try? next.play(at: row, col: col)) != nil else { continue }
                let aiNext = next.currentPlayer == ai
                value = max(
                    value,
                    minimax(
                        state: next,
                        ai: ai,
                        maximizingAI: aiNext,
                        alpha: a,
                        beta: beta,
                        depth: depth + 1,
                        plyRemaining: plyRemaining - 1
                    )
                )
                if value >= beta {
                    return value
                }
                a = max(a, value)
            }
            return value
        } else {
            var value = Int.max
            var b = beta
            for (row, col) in moves {
                var next = state
                guard (try? next.play(at: row, col: col)) != nil else { continue }
                let aiNext = next.currentPlayer == ai
                value = min(
                    value,
                    minimax(
                        state: next,
                        ai: ai,
                        maximizingAI: aiNext,
                        alpha: alpha,
                        beta: b,
                        depth: depth + 1,
                        plyRemaining: plyRemaining - 1
                    )
                )
                if value <= alpha {
                    return value
                }
                b = min(b, value)
            }
            return value
        }
    }

    /// EN: On large boards with low remaining ply, cap branching to keep runtime bounded.
    /// RU: На больших полях при малом оставшемся числе полуходов ограничиваем ветвление для разумного времени работы.
    private static func movesForMinimax(state: GameModel, plyRemaining: Int) -> [(Int, Int)] {
        let ordered = orderedEmptyCells(state: state)
        guard state.boardSize > 3 else { return ordered }

        let empty = ordered.count
        if plyRemaining >= 5 || empty <= 16 {
            return ordered
        }

        let cap = min(empty, max(10, plyRemaining * 3))
        return Array(ordered.prefix(cap))
    }
}
