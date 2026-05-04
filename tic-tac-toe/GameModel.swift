// EN: Pure game rules — board state, legal moves, win/draw detection for variable board size and win length.
// RU: Чистая игровая логика — состояние поля, ходы, победа/ничья для переменного размера и длины линии.

enum Player: Equatable, Sendable {
    case x
    case o

    var other: Player {
        self == .x ? .o : .x
    }
}

enum Cell: Equatable, Sendable {
    case empty
    case occupied(Player)
}

enum GameOutcome: Equatable, Sendable {
    case inProgress
    case win(Player)
    case draw
}

enum MoveError: Error, Equatable, Sendable {
    case outOfBounds
    case cellOccupied
    case gameAlreadyFinished
}

struct GameModel: Equatable, Sendable {
    let boardSize: Int
    let winLength: Int

    /// EN: Precomputed index segments (rows/cols/diagonals) of length `winLength` for fast win checks.
    /// RU: Заранее вычисленные отрезки индексов (ряды/столбцы/диагонали) длины `winLength` для быстрой проверки победы.
    private let winLines: [[Int]]

    private(set) var cells: [Cell]
    private(set) var currentPlayer: Player

    init(boardSize: Int = 3, winLength: Int = 3) {
        precondition((3...6).contains(boardSize))
        precondition((3...6).contains(winLength))
        precondition(winLength <= boardSize)

        self.boardSize = boardSize
        self.winLength = winLength
        self.winLines = Self.makeWinLines(boardSize: boardSize, winLength: winLength)
        self.cells = Array(repeating: .empty, count: boardSize * boardSize)
        self.currentPlayer = .x
    }

    /// EN: Builds every winning line as linear indices into `cells` (row-major: index = row * n + col).
    /// RU: Строит все выигрышные линии как линейные индексы в `cells` (порядок по строкам: row * n + col).
    static func makeWinLines(boardSize n: Int, winLength w: Int) -> [[Int]] {
        guard w <= n else { return [] }
        var lines: [[Int]] = []

        // EN: Horizontal segments / RU: Горизонтальные отрезки
        for row in 0..<n {
            for start in 0...(n - w) {
                lines.append((0..<w).map { row * n + start + $0 })
            }
        }
        // EN: Vertical segments / RU: Вертикальные отрезки
        for col in 0..<n {
            for start in 0...(n - w) {
                lines.append((0..<w).map { (start + $0) * n + col })
            }
        }
        // EN: Main diagonal (\) segments / RU: Главная диагональ (\)
        for row in 0...(n - w) {
            for col in 0...(n - w) {
                lines.append((0..<w).map { (row + $0) * n + (col + $0) })
            }
        }
        // EN: Anti-diagonal (/) segments / RU: Побочная диагональ (/)
        for row in 0...(n - w) {
            for col in (w - 1)..<n {
                lines.append((0..<w).map { (row + $0) * n + (col - $0) })
            }
        }
        return lines
    }

    mutating func reset() {
        cells = Array(repeating: .empty, count: boardSize * boardSize)
        currentPlayer = .x
    }

    func cell(at row: Int, col: Int) -> Cell {
        precondition((0..<boardSize).contains(row) && (0..<boardSize).contains(col))
        return cells[row * boardSize + col]
    }

    /// EN: First winning line found (for UI highlight); nil if no winner.
    /// RU: Первая найденная выигрышная линия (для подсветки в UI); nil если победителя нет.
    func winningLineIndices() -> [Int]? {
        for line in winLines {
            let a = cells[line[0]]
            guard case .occupied = a else { continue }
            var allMatch = true
            for idx in line.dropFirst() {
                if cells[idx] != a {
                    allMatch = false
                    break
                }
            }
            if allMatch {
                return line
            }
        }
        return nil
    }

    func outcome() -> GameOutcome {
        for line in winLines {
            let a = cells[line[0]]
            guard case let .occupied(p) = a else { continue }
            var win = true
            for idx in line.dropFirst() {
                if cells[idx] != a {
                    win = false
                    break
                }
            }
            if win {
                return .win(p)
            }
        }
        if cells.allSatisfy({
            if case .empty = $0 { return false }
            return true
        }) {
            return .draw
        }
        return .inProgress
    }

    /// EN: Places current player's mark; switches player only while the game stays in progress (after win, turn freezes).
    /// RU: Ставит символ текущего игрока; переключает ход только пока партия не закончена (после победы ход не меняется).
    mutating func play(at row: Int, col: Int) throws {
        guard outcome() == .inProgress else {
            throw MoveError.gameAlreadyFinished
        }
        guard (0..<boardSize).contains(row), (0..<boardSize).contains(col) else {
            throw MoveError.outOfBounds
        }
        let index = row * boardSize + col
        switch cells[index] {
        case .empty:
            cells[index] = .occupied(currentPlayer)
            if outcome() == .inProgress {
                currentPlayer = currentPlayer.other
            }
        case .occupied:
            throw MoveError.cellOccupied
        }
    }
}
