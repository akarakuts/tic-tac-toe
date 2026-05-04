import XCTest

// EN: UI test bundle placeholder — launches app; extend with flows when UI is test-id friendly.
// RU: Заготовка UI-тестов — запуск приложения; дополнять сценариями при доступных test id.

final class TicTacToeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
