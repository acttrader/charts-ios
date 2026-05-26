import XCTest
@testable import ActtraderCharts

final class BridgeCommandTests: XCTestCase {

    // ── BridgeCommand JSON encoding ───────────────────────────────────────────

    func testInitCommandJSON() throws {
        let cmd = BridgeCommand.initialize(
            theme: "dark",
            symbol: "EURUSD",
            series: "candlestick",
            timeframe: nil,
            duration: nil,
            enableTrading: false,
            showVolume: nil,
            showUI: nil,
            showDrawingTools: nil,
            showBidAskLines: nil,
            showActLogo: nil,
            showCandleCountdown: nil,
            candleCountdownTimeframes: nil,
            disableCountdownOnMobile: nil,
            maxSubPanes: nil,
            mobileBarDivisor: nil,
            minInitialBars: nil,
            maxLookbackMs: nil,
            momentumScrollEnabled: nil,
            momentumDecay: nil,
            momentumThreshold: nil,
            momentumMaxVelocity: nil,
            targetCandleWidth: nil,
            tickClosePriceSource: nil,
            tradesThresholdForHorizontalLine: nil,
            tradeDisplayFilter: nil,
            positionRenderStyle: nil,
            hideLevelConfirmCancel: nil,
            deselectActiveOnOutsideClick: nil,
            showTradeLevelsAlways: nil,
            showPriceAxisCountdown: nil,
            tradeLevelButtonScale: nil,
            levelClusteringEnabled: nil,
            clusterThresholdDistance: nil,
            tfcEnabled: nil,
            showSettings: nil,
            showFullscreenButton: false,
            hideSymbolAndTick: nil,
            hideOHLCV: nil,
            showBottomBar: nil,
            aggregateFrom: nil,
            canvasColorsJson: nil,
            themeOverridesJson: nil,
            labelsJson: nil,
            uiConfigJson: nil,
            durationTimeframeMap: nil,
            onSymbolClick: nil,
            timezone: nil,
            headerLayout: nil,
            enableMultipleLayouts: nil,
            enableSnapshot: nil,
            hideHeader: nil,
            initialCompares: nil,
            maxCompares: nil
        )
        let obj = try parseJSON(cmd.jsonString)
        XCTAssertEqual(obj["type"] as? String, "init")
        let payload = try XCTUnwrap(obj["payload"] as? [String: Any])
        XCTAssertEqual(payload["theme"] as? String, "dark")
        XCTAssertEqual(payload["symbol"] as? String, "EURUSD")
        XCTAssertEqual(payload["series"] as? String, "candlestick")
    }

    func testInitWithComparesIncludesInitialCompares() throws {
        let cmd = BridgeCommand.initialize(
            theme: "dark",
            symbol: "AAPL",
            series: nil, timeframe: nil, duration: nil, enableTrading: false,
            showVolume: nil, showUI: nil, showDrawingTools: nil,
            showBidAskLines: nil, showActLogo: nil, showCandleCountdown: nil,
            candleCountdownTimeframes: nil, disableCountdownOnMobile: nil,
            maxSubPanes: nil, mobileBarDivisor: nil, minInitialBars: nil,
            maxLookbackMs: nil, momentumScrollEnabled: nil, momentumDecay: nil,
            momentumThreshold: nil, momentumMaxVelocity: nil,
            targetCandleWidth: nil, tickClosePriceSource: nil,
            tradesThresholdForHorizontalLine: nil, tradeDisplayFilter: nil,
            positionRenderStyle: nil, hideLevelConfirmCancel: nil,
            deselectActiveOnOutsideClick: nil, showTradeLevelsAlways: nil,
            showPriceAxisCountdown: nil, tradeLevelButtonScale: nil,
            levelClusteringEnabled: nil, clusterThresholdDistance: nil,
            tfcEnabled: nil, showSettings: nil, showFullscreenButton: false,
            hideSymbolAndTick: nil, hideOHLCV: nil, showBottomBar: nil,
            aggregateFrom: nil, canvasColorsJson: nil, themeOverridesJson: nil,
            labelsJson: nil, uiConfigJson: nil, durationTimeframeMap: nil,
            onSymbolClick: nil, timezone: nil, headerLayout: nil,
            enableMultipleLayouts: nil, enableSnapshot: nil, hideHeader: nil,
            initialCompares: ["MSFT", "GOOG"],
            maxCompares: 4
        )
        let obj = try parseJSON(cmd.jsonString)
        let payload = try XCTUnwrap(obj["payload"] as? [String: Any])
        XCTAssertEqual(payload["initialCompares"] as? [String], ["MSFT", "GOOG"])
        XCTAssertEqual(payload["maxCompares"] as? Int, 4)
    }

    // ── Compare commands ──────────────────────────────────────────────────────

    func testAddCompareCommandJSON() throws {
        let obj = try parseJSON(BridgeCommand.addCompare("MSFT").jsonString)
        XCTAssertEqual(obj["type"] as? String, "addCompare")
        let payload = try XCTUnwrap(obj["payload"] as? [String: Any])
        XCTAssertEqual(payload["symbol"] as? String, "MSFT")
    }

    func testRemoveCompareCommandJSON() throws {
        let obj = try parseJSON(BridgeCommand.removeCompare("MSFT").jsonString)
        XCTAssertEqual(obj["type"] as? String, "removeCompare")
        let payload = try XCTUnwrap(obj["payload"] as? [String: Any])
        XCTAssertEqual(payload["symbol"] as? String, "MSFT")
    }

    func testClearComparesCommandJSON() throws {
        let obj = try parseJSON(BridgeCommand.clearCompares.jsonString)
        XCTAssertEqual(obj["type"] as? String, "clearCompares")
    }

    func testResolveCompareDataRequestCommandJSON() throws {
        let bars = [OHLCVBar(time: 1_700_000_000_000, open: 100, high: 110,
                             low: 90, close: 105, volume: 1000)]
        let obj = try parseJSON(BridgeCommand.resolveCompareDataRequest(
            requestId: "cr_1", bars: bars).jsonString)
        XCTAssertEqual(obj["type"] as? String, "resolveCompareDataRequest")
        let payload = try XCTUnwrap(obj["payload"] as? [String: Any])
        XCTAssertEqual(payload["requestId"] as? String, "cr_1")
        let barsArr = try XCTUnwrap(payload["bars"] as? [[String: Any]])
        XCTAssertEqual(barsArr.count, 1)
        XCTAssertEqual(barsArr[0]["close"] as? Double, 105)
    }

    func testLoadDataCommandJSON() throws {
        let bars = [
            OHLCVBar(time: 1_700_000_000_000, open: 1.1, high: 1.2, low: 1.0, close: 1.15, volume: 1000),
            OHLCVBar(time: 1_700_000_060_000, open: 1.15, high: 1.25, low: 1.1, close: 1.2, volume: 2000),
        ]
        let cmd = BridgeCommand.loadData(bars: bars, fitAll: true)
        let obj = try parseJSON(cmd.jsonString)
        XCTAssertEqual(obj["type"] as? String, "loadData")
        let payload = try XCTUnwrap(obj["payload"] as? [String: Any])
        XCTAssertEqual(payload["fitAll"] as? Bool, true)
        let barsArr = try XCTUnwrap(payload["bars"] as? [[String: Any]])
        XCTAssertEqual(barsArr.count, 2)
        XCTAssertEqual(barsArr[0]["open"] as? Double, 1.1)
        XCTAssertEqual(barsArr[0]["close"] as? Double, 1.15)
    }

    func testPushTickCommandJSON() throws {
        let cmd = BridgeCommand.pushTick(bid: 1.0500, ask: 1.0502, timestamp: 1_700_000_000_000)
        let obj = try parseJSON(cmd.jsonString)
        XCTAssertEqual(obj["type"] as? String, "pushTick")
        let payload = try XCTUnwrap(obj["payload"] as? [String: Any])
        XCTAssertEqual(payload["B"] as? Double, 1.0500)
        XCTAssertEqual(payload["A"] as? Double, 1.0502)
        XCTAssertEqual(payload["T"] as? Int64, 1_700_000_000_000)
    }

    func testSetThemeCommandJSON() throws {
        let cmd = BridgeCommand.setTheme("light")
        let obj = try parseJSON(cmd.jsonString)
        XCTAssertEqual(obj["type"] as? String, "setTheme")
        let payload = try XCTUnwrap(obj["payload"] as? [String: Any])
        XCTAssertEqual(payload["theme"] as? String, "light")
    }

    func testAddIndicatorWithParamsJSON() throws {
        let cmd = BridgeCommand.addIndicator(name: "SMA", params: ["period": 20])
        let obj = try parseJSON(cmd.jsonString)
        XCTAssertEqual(obj["type"] as? String, "addIndicator")
        let payload = try XCTUnwrap(obj["payload"] as? [String: Any])
        XCTAssertEqual(payload["shortName"] as? String, "SMA")
        let params = try XCTUnwrap(payload["params"] as? [String: Any])
        XCTAssertEqual(params["period"] as? Int, 20)
    }

    func testSetDrawingToolNilJSON() throws {
        let cmd = BridgeCommand.setDrawingTool(nil)
        let obj = try parseJSON(cmd.jsonString)
        XCTAssertEqual(obj["type"] as? String, "setDrawingTool")
        let payload = try XCTUnwrap(obj["payload"] as? [String: Any])
        XCTAssertTrue(payload["tool"] is NSNull)
    }

    func testClearAllDrawingsJSON() throws {
        let cmd = BridgeCommand.clearAllDrawings
        let obj = try parseJSON(cmd.jsonString)
        XCTAssertEqual(obj["type"] as? String, "clearAllDrawings")
    }

    func testDestroyCommandJSON() throws {
        let cmd = BridgeCommand.destroy
        let obj = try parseJSON(cmd.jsonString)
        XCTAssertEqual(obj["type"] as? String, "destroy")
    }

    // ── BridgeEvent parsing ───────────────────────────────────────────────────

    func testParseReadyEvent() {
        let event = BridgeEvent.parse(#"{"type":"ready"}"#)
        guard case .ready = event else {
            XCTFail("Expected .ready, got \(String(describing: event))")
            return
        }
    }

    func testParseCrosshairEvent() {
        let json = """
        {
          "type": "crosshair",
          "bar": {"time": 1700000000000, "open": 1.1, "high": 1.2, "low": 1.0, "close": 1.15, "volume": 1000},
          "position": {"x": 100.5, "y": 200.0}
        }
        """
        let event = BridgeEvent.parse(json)
        guard case let .crosshair(time, open, high, low, close, volume, x, y) = event else {
            XCTFail("Expected .crosshair, got \(String(describing: event))")
            return
        }
        XCTAssertEqual(time, 1_700_000_000_000)
        XCTAssertEqual(open, 1.1)
        XCTAssertEqual(high, 1.2)
        XCTAssertEqual(low, 1.0)
        XCTAssertEqual(close, 1.15)
        XCTAssertEqual(volume, 1000)
        XCTAssertEqual(x, 100.5)
        XCTAssertEqual(y, 200.0)
    }

    func testParseViewportChangeEvent() {
        let json = """
        {"type":"viewportChange","viewport":{"startIndex":0,"endIndex":99,"barWidth":8.5}}
        """
        let event = BridgeEvent.parse(json)
        guard case let .viewportChange(start, end, barWidth) = event else {
            XCTFail("Expected .viewportChange, got \(String(describing: event))")
            return
        }
        XCTAssertEqual(start, 0)
        XCTAssertEqual(end, 99)
        XCTAssertEqual(barWidth, 8.5)
    }

    func testParseDataLoadedEvent() {
        let json = #"{"type":"dataLoaded","barCount":250}"#
        let event = BridgeEvent.parse(json)
        guard case let .dataLoaded(count) = event else {
            XCTFail("Expected .dataLoaded, got \(String(describing: event))")
            return
        }
        XCTAssertEqual(count, 250)
    }

    func testParseErrorEvent() {
        let json = #"{"type":"error","message":"Engine crash","code":"E001"}"#
        let event = BridgeEvent.parse(json)
        guard case let .error(message, code) = event else {
            XCTFail("Expected .error, got \(String(describing: event))")
            return
        }
        XCTAssertEqual(message, "Engine crash")
        XCTAssertEqual(code, "E001")
    }

    func testParseCompareDataRequestEvent() {
        let json = """
        {"type":"compareDataRequest","payload":{"requestId":"cr_1","symbol":"MSFT","timeframe":"1D","interval":"1day","start":1700000000000,"end":1700100000000}}
        """
        guard case let .compareDataRequest(rid, sym, tf, intv, start, end) = BridgeEvent.parse(json) else {
            XCTFail("Expected .compareDataRequest")
            return
        }
        XCTAssertEqual(rid, "cr_1")
        XCTAssertEqual(sym, "MSFT")
        XCTAssertEqual(tf, "1D")
        XCTAssertEqual(intv, "1day")
        XCTAssertEqual(start, 1_700_000_000_000)
        XCTAssertEqual(end, 1_700_100_000_000)
    }

    func testParseCompareAddedEvent() {
        let json = ##"{"type":"compareAdded","payload":{"symbol":"MSFT","color":"#2962FF"}}"##
        guard case let .compareAdded(symbol, color) = BridgeEvent.parse(json) else {
            XCTFail("Expected .compareAdded")
            return
        }
        XCTAssertEqual(symbol, "MSFT")
        XCTAssertEqual(color, "#2962FF")
    }

    func testParseCompareRemovedEvent() {
        let json = #"{"type":"compareRemoved","payload":{"symbol":"MSFT"}}"#
        guard case let .compareRemoved(symbol) = BridgeEvent.parse(json) else {
            XCTFail("Expected .compareRemoved")
            return
        }
        XCTAssertEqual(symbol, "MSFT")
    }

    func testParseCompareErrorEvent() {
        let json = #"{"type":"compareError","payload":{"symbol":"BADTICKER","message":"loader rejected"}}"#
        guard case let .compareError(symbol, message) = BridgeEvent.parse(json) else {
            XCTFail("Expected .compareError")
            return
        }
        XCTAssertEqual(symbol, "BADTICKER")
        XCTAssertEqual(message, "loader rejected")
    }

    func testParseInvalidJSONReturnsNil() {
        XCTAssertNil(BridgeEvent.parse("not json at all"))
    }

    func testParseUnknownTypeReturnsNil() {
        XCTAssertNil(BridgeEvent.parse(#"{"type":"unknownFutureEvent","payload":{}}"#))
    }

    func testParseMissingTypeReturnsNil() {
        XCTAssertNil(BridgeEvent.parse(#"{"foo":"bar"}"#))
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private func parseJSON(_ jsonString: String) throws -> [String: Any] {
        let data = try XCTUnwrap(jsonString.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
