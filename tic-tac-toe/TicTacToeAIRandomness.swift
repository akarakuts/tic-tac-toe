// EN: Injectable randomness for AI difficulty — deterministic in unit tests, system RNG in play.
// RU: Подставляемая случайность для сложности ИИ — детерминированная в тестах, системная в игре.

struct TicTacToeAIRandomness: Sendable {
    var nextUnit: @Sendable () -> Double
    var pickIndex: @Sendable (Int) -> Int

    static let system = TicTacToeAIRandomness(
        nextUnit: { Double.random(in: 0...1) },
        pickIndex: { count in
            guard count > 0 else { return 0 }
            return Int.random(in: 0..<count)
        }
    )

    /// EN: Reproducible sequence for tests (`unit` values in [0,1), `index` picks modulo count).
    /// RU: Воспроизводимая последовательность для тестов.
    static func seeded(units: [Double], indices: [Int] = []) -> TicTacToeAIRandomness {
        final class Box: @unchecked Sendable {
            var u = 0
            var i = 0
            let units: [Double]
            let indices: [Int]
            init(units: [Double], indices: [Int]) {
                self.units = units.isEmpty ? [0.5] : units
                self.indices = indices.isEmpty ? [0] : indices
            }
        }
        let box = Box(units: units, indices: indices)
        return TicTacToeAIRandomness(
            nextUnit: {
                let v = box.units[box.u % box.units.count]
                box.u += 1
                return v
            },
            pickIndex: { count in
                guard count > 0 else { return 0 }
                let raw = box.indices[box.i % box.indices.count]
                box.i += 1
                return raw % count
            }
        )
    }

    func chance(_ probability: Double) -> Bool {
        nextUnit() < probability
    }

    func pick<T>(_ elements: [T]) -> T? {
        guard !elements.isEmpty else { return nil }
        return elements[pickIndex(elements.count)]
    }
}
