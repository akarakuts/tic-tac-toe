import Testing
@testable import tic_tac_toe

// EN: Unit tests for `GameModel` rules and `TicTacToeAI` behaviour (Swift Testing).
// RU: Юнит-тесты правил `GameModel` и поведения `TicTacToeAI` (Swift Testing).

/// EN: Covers moves, wins (rows/cols/diagonals), draws, errors, reset, variable board sizes.
/// RU: Ходы, победы (ряды/столбцы/диагонали), ничья, ошибки, сброс, переменный размер поля.
struct GameModelTests {

    @Test func initialState_isEmptyBoard_xToMove() {
        let game = GameModel()
        for row in 0..<3 {
            for col in 0..<3 {
                #expect(game.cell(at: row, col: col) == .empty)
            }
        }
        #expect(game.currentPlayer == .x)
        #expect(game.outcome() == .inProgress)
    }

    @Test func play_alternatesPlayersUntilGameEnds() throws {
        var game = GameModel()
        try game.play(at: 1, col: 1)
        #expect(game.currentPlayer == .o)
        try game.play(at: 0, col: 0)
        #expect(game.currentPlayer == .x)
    }

    @Test func win_topRow_x() throws {
        var game = GameModel()
        try game.play(at: 0, col: 0)
        try game.play(at: 1, col: 0)
        try game.play(at: 0, col: 1)
        try game.play(at: 1, col: 1)
        try game.play(at: 0, col: 2)
        #expect(game.outcome() == .win(.x))
        #expect(game.currentPlayer == .x)
    }

    @Test func win_middleColumn_o() throws {
        var game = GameModel()
        try game.play(at: 0, col: 0)
        try game.play(at: 0, col: 1)
        try game.play(at: 1, col: 0)
        try game.play(at: 1, col: 1)
        try game.play(at: 2, col: 2)
        try game.play(at: 2, col: 1)
        #expect(game.outcome() == .win(.o))
    }

    @Test func win_diagonal_x() throws {
        var game = GameModel()
        try game.play(at: 0, col: 0)
        try game.play(at: 0, col: 1)
        try game.play(at: 1, col: 1)
        try game.play(at: 0, col: 2)
        try game.play(at: 2, col: 2)
        #expect(game.outcome() == .win(.x))
    }

    @Test func draw_fullBoard_noWinner() throws {
        var game = GameModel()
        try game.play(at: 0, col: 0)
        try game.play(at: 0, col: 1)
        try game.play(at: 0, col: 2)
        try game.play(at: 1, col: 1)
        try game.play(at: 1, col: 0)
        try game.play(at: 2, col: 0)
        try game.play(at: 1, col: 2)
        try game.play(at: 2, col: 2)
        try game.play(at: 2, col: 1)
        #expect(game.outcome() == .draw)
    }

    @Test func play_onOccupied_throwsCellOccupied() throws {
        var game = GameModel()
        try game.play(at: 1, col: 1)
        do {
            try game.play(at: 1, col: 1)
            Issue.record("Ожидался MoveError.cellOccupied")
        } catch let error as MoveError {
            #expect(error == .cellOccupied)
        } catch {
            Issue.record("Неожиданная ошибка: \(error)")
        }
    }

    @Test func play_afterGameFinished_throws() throws {
        var game = GameModel()
        try game.play(at: 0, col: 0)
        try game.play(at: 1, col: 0)
        try game.play(at: 0, col: 1)
        try game.play(at: 1, col: 1)
        try game.play(at: 0, col: 2)
        #expect(game.outcome() == .win(.x))
        do {
            try game.play(at: 2, col: 2)
            Issue.record("Ожидался MoveError.gameAlreadyFinished")
        } catch let error as MoveError {
            #expect(error == .gameAlreadyFinished)
        } catch {
            Issue.record("Неожиданная ошибка: \(error)")
        }
    }

    @Test func play_outOfBounds_throws() throws {
        var game = GameModel()
        do {
            try game.play(at: -1, col: 0)
            Issue.record("Ожидался MoveError.outOfBounds")
        } catch let error as MoveError {
            #expect(error == .outOfBounds)
        }

        do {
            try game.play(at: 0, col: 3)
            Issue.record("Ожидался MoveError.outOfBounds")
        } catch let error as MoveError {
            #expect(error == .outOfBounds)
        }
    }

    @Test func reset_clearsBoard_andStartsWithX() throws {
        var game = GameModel()
        try game.play(at: 1, col: 1)
        game.reset()
        #expect(game.outcome() == .inProgress)
        #expect(game.currentPlayer == .x)
        #expect(game.cell(at: 1, col: 1) == .empty)
    }

    @Test func winningLineIndices_topRow() throws {
        var game = GameModel()
        try game.play(at: 0, col: 0)
        try game.play(at: 1, col: 0)
        try game.play(at: 0, col: 1)
        try game.play(at: 1, col: 1)
        try game.play(at: 0, col: 2)
        #expect(game.winningLineIndices() == [0, 1, 2])
    }

    @Test func winningLineIndices_nilWhenNoWinner() {
        let game = GameModel()
        #expect(game.winningLineIndices() == nil)
    }

    @Test func win_four_board_four_in_row_top_row() throws {
        var game = GameModel(boardSize: 4, winLength: 4)
        for col in 0..<3 {
            try game.play(at: 0, col: col)
            try game.play(at: 1, col: col)
        }
        try game.play(at: 0, col: 3)
        #expect(game.outcome() == .win(.x))
    }

    @Test func win_five_by_five_win_length_three_row() throws {
        var game = GameModel(boardSize: 5, winLength: 3)
        try game.play(at: 2, col: 0)
        try game.play(at: 1, col: 0)
        try game.play(at: 2, col: 1)
        try game.play(at: 1, col: 1)
        try game.play(at: 2, col: 2)
        #expect(game.outcome() == .win(.x))
    }
}

/// EN: Smoke tests for minimax wrapper — legal moves, blocks, wins, empty when wrong turn or game over.
/// RU: Дымовые проверки обёртки минимакса — допустимые ходы, блок, победа, пусто при неверном ходе или конце игры.
struct TicTacToeAITests {

    @Test func bestMove_nilWhenNotAiTurn() {
        let game = GameModel()
        #expect(TicTacToeAI.bestMove(for: .o, in: game) == nil)
    }

    @Test func ai_blocksOpponentWinningRow() throws {
        var game = GameModel()
        try game.play(at: 0, col: 0)
        try game.play(at: 1, col: 1)
        try game.play(at: 0, col: 1)
        let move = TicTacToeAI.bestMove(for: .o, in: game)
        #expect(move?.row == 0 && move?.col == 2)
    }

    @Test func ai_takesImmediateWin() throws {
        var game = GameModel()
        try game.play(at: 0, col: 0)
        try game.play(at: 1, col: 0)
        try game.play(at: 0, col: 1)
        try game.play(at: 1, col: 1)
        let move = TicTacToeAI.bestMove(for: .x, in: game)
        #expect(move?.row == 0 && move?.col == 2)
    }

    @Test func ai_nilWhenGameOver() throws {
        var game = GameModel()
        try game.play(at: 0, col: 0)
        try game.play(at: 1, col: 0)
        try game.play(at: 0, col: 1)
        try game.play(at: 1, col: 1)
        try game.play(at: 0, col: 2)
        #expect(game.outcome() == .win(.x))
        #expect(TicTacToeAI.bestMove(for: .o, in: game) == nil)
    }

    @Test func ai_returnsLegalMove_onFourByFour() throws {
        var game = GameModel(boardSize: 4, winLength: 3)
        try game.play(at: 1, col: 1)
        let move = TicTacToeAI.bestMove(for: .o, in: game)
        #expect(move != nil)
        let m = try #require(move)
        var next = game
        try next.play(at: m.row, col: m.col)
        #expect(next.cell(at: m.row, col: m.col) == .occupied(.o))
    }
}
