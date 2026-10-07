import Foundation

/// A single change within a `tradeLevelEdit` event.
public struct TradeLevelChange {
    /// Which field changed: `"MAIN"`, `"SL"`, `"TP"`, `"ADD_SL"`, `"ADD_TP"`, `"REMOVE_SL"`, `"REMOVE_TP"`.
    public let field: String
    public let newPrice: Double
    /// Opaque level data serialised as a raw JSON string. On the `MAIN` change, the embedded
    /// `lots` field is overridden with the newly-edited qty when the user changed it this session.
    public let data: String
    /// Present on the `MAIN` change when the user edited the lot size this session.
    public let newLots: Double?
    public let bracketOrderLabel: String?
}

/// Events emitted from the chart WebView back to native iOS code.
public enum BridgeEvent {

    /// Chart engine is initialised and ready to receive commands.
    case ready

    /// Crosshair moved; contains the bar data at the cursor position.
    case crosshair(time: Int64, open: Double, high: Double, low: Double, close: Double, volume: Double, x: Double, y: Double)

    /// User tapped/clicked a bar.
    case barClick(time: Int64, open: Double, high: Double, low: Double, close: Double, volume: Double)

    /// Viewport scroll or zoom changed.
    case viewportChange(startIndex: Int, endIndex: Int, barWidth: Double)

    /// Active chart series type changed.
    case seriesChange(String)

    /// User picked a price source (`"bid"`, `"ask"` or `"ltp"`) from the header
    /// dropdown (`priceSourceSelector`) — persist it host-side if desired.
    case priceSourceChange(String)

    /// Active timeframe changed.
    case timeframeChange(String)

    /// Active duration changed.
    case durationChange(String)

    /// Any aspect of chart state changed (generic).
    case stateChange(String)

    /// Response to a `getState` command; contains the full serialised state JSON.
    case stateSnapshot(String)

    /// The native-UI catalog: everything the app needs to build its own header, chart-type
    /// list, drawing-tools sheet, indicators list and chart-settings screen — ids, labels,
    /// defaults, indicator settings fields, and `available` per entry (true = works in this
    /// chart version). Sent once after every init and on ``BridgeCommand/getCatalog``.
    /// - catalogVersion: chart library version — cache the JSON and rebuild your UI only when it changes.
    /// - catalogJson: the whole catalog as a raw JSON string (store as-is, decode with `Codable`).
    case catalog(catalogVersion: String, catalogJson: String)

    /// `loadData` command completed successfully.
    case dataLoaded(barCount: Int)

    /// A new bar was appended at the live edge.
    case newBar(time: Int64, open: Double, high: Double, low: Double, close: Double, volume: Double)

    /// Stream connection status changed.
    case streamStatus(String)

    /// User submitted an order via the floating trade button.
    case placeOrder(price: Double, side: String, orderType: String)

    /// User tapped × to close or cancel a trade level or remove a bracket.
    case tradeLevelClose(label: String, type: String, action: String, data: String, bracketType: String?, isFullscreen: Bool)

    /// Live drag position — fires on every pointer move while a level or bracket is being dragged.
    case tradeLevelDrag(label: String, newPrice: Double, data: String, bracketType: String?, isFullscreen: Bool)

    /// User confirmed edits to a trade level (main price, SL, TP, or bracket changes batched together).
    /// `data` has its embedded `lots` field overridden with the new qty when the user edited it.
    /// `newLots` is present when the user changed the lot size via the QTY pill flyout during this edit session.
    case tradeLevelEdit(label: String, type: String, data: String, isFullscreen: Bool, newLots: Double?, changes: [TradeLevelChange])

    /// Live qty edit via the QTY pill flyout — fires before the level edit is confirmed,
    /// so hosts can refresh Estimated PNL on SL/TP brackets in real time instead of
    /// waiting for `tradeLevelEdit` at ✓ confirm. `type` is `"draft"` for the in-progress
    /// draft order, otherwise the parent level's type. `previousLots` is the qty at
    /// edit-session start (useful for revert-aware previews).
    case tradeLevelQtyChange(label: String, type: String, newLots: Double, previousLots: Double, isFullscreen: Bool)

    /// Chart ✓ button confirmed an edit (including draft orders).
    case tradeLevelConfirmed(label: String, type: String, isFullscreen: Bool)

    /// An in-progress level edit was cancelled from the chart (ESC key or inline ✕ cancel button).
    /// Mirrors `tradeLevelConfirmed` for the revert path. Not fired for draft orders
    /// (those emit `draftCancelled`). Hosts listen to reset their external modify-order panel.
    case tradeLevelEditCancelled(label: String, type: String, isFullscreen: Bool)

    /// User tapped the pencil/edit button to open the order panel for a level.
    case tradeLevelEditOpen(label: String, type: String, data: String, price: Double, side: String?, stopLossPrice: Double?, takeProfitPrice: Double?, isFullscreen: Bool)

    /// Emitted after `addLevelBracket()` auto-places a SL/TP bracket.
    /// Use `price` to populate your order form's SL/TP input field.
    case tradeLevelBracketActivated(label: String, bracketType: String, price: Double, isFullscreen: Bool)

    /// Emitted when a new draft order is shown on the chart (market, limit, or stop).
    /// Native layer should open the buy/sell form.
    case draftInitiated(side: String, price: Double, orderType: String, isFullscreen: Bool)

    /// Emitted when a draft order is cancelled (Escape, ✕ button, or external revert).
    case draftCancelled(label: String, isFullscreen: Bool)

    /// Chart engine is requesting data for a time range; native must respond with `resolveDataRequest`.
    case dataRequest(requestId: String, timeframe: String, interval: String, start: Int64, end: Int64)

    /// TFC (Trade from Charts) was toggled on or off via the top bar button or API.
    case tfcToggle(enabled: Bool)

    /// The crosshair was switched on or off — via the header switch (`enableCrossHairHeader`)
    /// or ``BridgeCommand/setCrosshairEnabled(_:)``. Persist `enabled` and seed it back
    /// through `crosshairEnabled` on the next init.
    case crosshairToggle(enabled: Bool)

    /// A horizontal (time-axis) badge drag started — before any movement. Requires
    /// `orderLineTimeDrag` and a level flagged `timeDraggable`. `fromTimestamp` is unix ms.
    case orderLineMoveStart(label: String, fromTimestamp: Int64, fromBarIndex: Int, isFullscreen: Bool)

    /// Live position during a horizontal badge drag — fires on every move, before release.
    case orderLineMoving(label: String, toTimestamp: Int64, toBarIndex: Int, isFullscreen: Bool)

    /// A horizontal badge drag ended on a different candle (after snapping, when enabled). The
    /// price is unchanged — only the level's time anchor moved. `data` is the level's original
    /// dictionary serialised as a raw JSON string.
    case orderLineMoved(label: String, fromTimestamp: Int64, toTimestamp: Int64,
                        fromBarIndex: Int, toBarIndex: Int, data: String, isFullscreen: Bool)

    /// Emitted whenever any dismissible chart UI (flyout, modal, dropdown, popover) opens or closes.
    /// Paired with ``BridgeCommand/dismissAllUI``, this lets the host decide whether the system
    /// back action should dismiss chart UI or propagate to normal navigation.
    ///
    /// ``ActtraderChartsView`` already listens for this event internally and mirrors the state into
    /// ``ActtraderChartsView/hasOpenUI``, so most hosts won't need to subscribe directly.
    case uiStateChange(hasOpenUI: Bool)

    /// User tapped the symbol name; fires when `onSymbolClick` is enabled in the init command.
    case symbolClick(symbol: String)

    /// User tapped the "Ask AI" (✦) button in the mobile header; fires when
    /// `onAskAiClick` is enabled in the init command.
    case askAiClick

    /// User picked a layout preset or toggled a cross-pane sync option in the
    /// chart-owned LayoutPopover. Fires only when `enableMultipleLayouts` is set
    /// in `BridgeCommand.initialize`. The native host should mount / teardown
    /// panes to match `presetId` (one of `"1"`, `"2-h"`, `"4-2x2"`, … — see the
    /// JS library's `LAYOUT_PRESETS` for the full list) and apply the sync flags.
    ///
    /// `syncJson` is the raw JSON of the `LayoutSyncState` object:
    /// `{"symbol":bool,"interval":bool,"crosshair":bool,"time":bool,"dateRange":bool}`.
    case layoutChange(presetId: String, syncJson: String)

    /// User picked Download or Copy from the chart-owned SnapshotPopover. Fires
    /// only when `enableSnapshot` is set in `BridgeCommand.initialize`. The
    /// native layer can save the PNG via platform APIs (Photos, UIPasteboard)
    /// using `dataUrl` (base64).
    /// - Parameter action: `"download"` or `"copy"`.
    case snapshot(dataUrl: String, action: String)

    /// Chart engine is requesting bars for a compare symbol; native must respond
    /// with ``BridgeCommand/resolveCompareDataRequest(requestId:bars:)``.
    case compareDataRequest(requestId: String, symbol: String, timeframe: String, interval: String, start: Int64, end: Int64)

    /// A compare symbol was added and assigned an auto-picked palette color.
    case compareAdded(symbol: String, color: String)

    /// A compare symbol was removed (×, ``ActtraderChartsView/removeCompare(_:)``, or ``ActtraderChartsView/clearCompares()``).
    case compareRemoved(symbol: String)

    /// Adding a compare or fetching its bars failed.
    case compareError(symbol: String, message: String)

    /// A study instance was added. Multiple instances of the same study can be
    /// active at once (e.g. EMA-20, EMA-50). Keep `instanceId` to later remove
    /// this specific instance via ``ActtraderChartsView/removeIndicator(_:)``.
    /// - Parameters:
    ///   - instanceId: Unique per-instance id (e.g. `"EMA#3"`).
    ///   - shortName:  Study short name (e.g. `"EMA"`).
    ///   - params:     Resolved params (period, color, source, timeframe, …).
    case indicatorAdded(instanceId: String, shortName: String, params: [String: Any])

    /// A study instance was removed (pill ×, settings dialog, or removeIndicator).
    case indicatorRemoved(instanceId: String, shortName: String)

    // ── Layouts ──────────────────────────────────────────────────────────────

    /// A workspace was saved as a named layout. **Persist `layoutJson`** — the chart
    /// holds it only for the lifetime of the view.
    case layoutSaved(id: String, name: String, layoutJson: String)

    /// A saved layout was restored. `layoutJson` carries every pane, for lazy mounting.
    case layoutApplied(id: String, name: String, presetId: String, layoutJson: String)

    /// A saved layout was deleted. Remove it from your storage too.
    case layoutDeleted(id: String)

    // ── Indicator templates ───────────────────────────────────────────────────

    /// An indicator set was saved as a named template. **Persist `templateJson`.**
    case indicatorTemplateSaved(id: String, name: String, templateJson: String)

    /// A template's indicators replaced the chart's active set.
    case indicatorTemplateApplied(id: String, name: String, count: Int)

    /// An indicator template was deleted. Remove it from your storage too.
    case indicatorTemplateDeleted(id: String)

    // ── Chart-settings templates ──────────────────────────────────────────────

    /// A settings template was saved. **Persist `templateJson`.**
    case settingsTemplateSaved(id: String, name: String, templateJson: String)

    /// A settings template was applied to this chart.
    case settingsTemplateApplied(id: String, name: String)

    /// A settings template was deleted. Remove it from your storage too.
    case settingsTemplateDeleted(id: String)

    /// Settings were applied from the Chart Settings dialog.
    ///
    /// This chart has already applied them. When `applyToAll` is `true` the user
    /// asked for every chart — pass `settingsJson` to each of your other chart
    /// views via ``ActtraderChartsView/applyChartSettings(_:)``.
    case chartSettingsApplied(settingsJson: String, applyToAll: Bool)

    // ── Quick Search ──────────────────────────────────────────────────────────

    /// A Quick Search command ran. It has already executed — use this for
    /// analytics, or to mirror the action into your own chrome.
    case quickSearchCommand(id: String, label: String, group: String)

    // ── Cursors ───────────────────────────────────────────────────────────────

    /// The pointer mode changed — via ``BridgeCommand/setCursorMode(mode:)`` or
    /// the Cursors group in the drawing toolbar. Persist it to restore the choice.
    case cursorModeChange(mode: String)

    // ── Drawing toolbar options ───────────────────────────────────────────────

    /// Magnet mode toggled from the toolbar. Persist it to restore the choice.
    case magnetModeChange(enabled: Bool)

    /// Keep-drawing mode toggled from the toolbar.
    case keepDrawingModeChange(enabled: Bool)

    /// "Copy to all charts" toggled from the toolbar.
    case copyDrawingsToAllChange(enabled: Bool)

    /// The drawing toolbar was shown or hidden.
    case drawingToolbarVisibility(visible: Bool)

    /// A drawing was completed. When `copyToAll` is true, send `drawingJson` to
    /// your other chart views — the chart cannot replicate it itself.
    case drawingCreated(type: String, drawingJson: String, copyToAll: Bool)

    /// Decimal places for prices changed, whether pinned or re-inferred.
    case pricePrecisionChange(digits: Int)

    /// Bar colouring switched. `source` is `"open"` or `"previousClose"`.
    case barColorSourceChange(source: String)

    /// The display timezone changed. Always a resolved IANA name, never `"local"`.
    case timezoneChange(timezone: String)

    /// A status-line field was shown or hidden. Carries the whole set as JSON.
    case statusLineChange(statusLineJson: String)

    /// A scales option changed. Carries the whole set as JSON.
    case scalesChange(scalesJson: String)

    /// A canvas option changed. Carries the whole set as JSON.
    case canvasOptionsChange(canvasJson: String)

    /// The price axis switched. `mode` is `"normal"`, `"log"` or `"percent"`.
    case priceScaleModeChange(mode: String)

    /// Automatic Y-range fitting was turned on or off.
    case autoScaleChange(enabled: Bool)

    /// The chart scrolled to a date. Carries the bar it settled on.
    case goToDate(time: Int64, barIndex: Int)

    /// The side panel was shown or hidden. `tab` is `"data"` or `"objects"`.
    case sidePanelVisibility(visible: Bool, tab: String)

    /// An error occurred inside the chart engine.
    case error(message: String, code: String?)

    // ── Parser ────────────────────────────────────────────────────────────────

    /// Parses a raw JSON string received from the WebView into a `BridgeEvent`.
    ///
    /// The bridge sends `{ "type": "...", "payload": { ... } }`.  All fields
    /// are read from the nested `payload` object.
    ///
    /// Returns `nil` for malformed or unrecognised messages.
    public static func parse(_ json: String) -> BridgeEvent? {
        guard
            let data = json.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let type = obj["type"] as? String
        else { return nil }

        // Every event except "ready" carries a payload object.
        let p = obj["payload"] as? [String: Any] ?? [:]

        switch type {

        case "ready":
            return .ready

        case "crosshair":
            guard let bar = p["bar"] as? [String: Any] else { return nil }
            let pos = p["position"] as? [String: Any]
            let chTime: Int64 = (bar["time"] as? Int64) ?? Int64(bar["time"] as? Double ?? 0)
            let chOpen:   Double = bar["open"]   as? Double ?? 0
            let chHigh:   Double = bar["high"]   as? Double ?? 0
            let chLow:    Double = bar["low"]    as? Double ?? 0
            let chClose:  Double = bar["close"]  as? Double ?? 0
            let chVol:    Double = bar["volume"] as? Double ?? 0
            let chX:      Double = pos?["x"]     as? Double ?? 0
            let chY:      Double = pos?["y"]     as? Double ?? 0
            return .crosshair(time: chTime, open: chOpen, high: chHigh, low: chLow,
                              close: chClose, volume: chVol, x: chX, y: chY)

        case "barClick":
            guard let bar = p["bar"] as? [String: Any] else { return nil }
            let bcTime:  Int64  = (bar["time"] as? Int64) ?? Int64(bar["time"] as? Double ?? 0)
            let bcOpen:  Double = bar["open"]   as? Double ?? 0
            let bcHigh:  Double = bar["high"]   as? Double ?? 0
            let bcLow:   Double = bar["low"]    as? Double ?? 0
            let bcClose: Double = bar["close"]  as? Double ?? 0
            let bcVol:   Double = bar["volume"] as? Double ?? 0
            return .barClick(time: bcTime, open: bcOpen, high: bcHigh, low: bcLow,
                             close: bcClose, volume: bcVol)

        case "viewportChange":
            guard let vp = p["viewport"] as? [String: Any] else { return nil }
            return .viewportChange(
                startIndex: vp["startIndex"] as? Int ?? 0,
                endIndex:   vp["endIndex"]   as? Int ?? 0,
                barWidth:   vp["barWidth"]   as? Double ?? 0
            )

        case "seriesChange":
            guard let series = p["series"] as? String else { return nil }
            return .seriesChange(series)

        case "priceSourceChange":
            guard let source = p["source"] as? String else { return nil }
            return .priceSourceChange(source)

        case "timeframeChange":
            guard let tf = p["timeframe"] as? String else { return nil }
            return .timeframeChange(tf)

        case "durationChange":
            guard let dur = p["duration"] as? String else { return nil }
            return .durationChange(dur)

        case "stateChange":
            guard
                let state = p["state"],
                let stateData = try? JSONSerialization.data(withJSONObject: state),
                let stateJson = String(data: stateData, encoding: .utf8)
            else { return nil }
            return .stateChange(stateJson)

        case "stateSnapshot":
            guard
                let stateData = try? JSONSerialization.data(withJSONObject: p),
                let stateJson = String(data: stateData, encoding: .utf8)
            else { return nil }
            return .stateSnapshot(stateJson)

        case "catalog":
            guard
                let catalogData = try? JSONSerialization.data(withJSONObject: p),
                let catalogJson = String(data: catalogData, encoding: .utf8)
            else { return nil }
            return .catalog(catalogVersion: p["catalogVersion"] as? String ?? "", catalogJson: catalogJson)

        case "dataLoaded":
            return .dataLoaded(barCount: p["barCount"] as? Int ?? 0)

        case "newBar":
            guard let bar = p["completedBar"] as? [String: Any] else { return nil }
            let nbTime:  Int64  = (bar["time"] as? Int64) ?? Int64(bar["time"] as? Double ?? 0)
            let nbOpen:  Double = bar["open"]   as? Double ?? 0
            let nbHigh:  Double = bar["high"]   as? Double ?? 0
            let nbLow:   Double = bar["low"]    as? Double ?? 0
            let nbClose: Double = bar["close"]  as? Double ?? 0
            let nbVol:   Double = bar["volume"] as? Double ?? 0
            return .newBar(time: nbTime, open: nbOpen, high: nbHigh, low: nbLow,
                           close: nbClose, volume: nbVol)

        case "streamStatus":
            guard let status = p["status"] as? String else { return nil }
            return .streamStatus(status)

        case "placeOrder":
            return .placeOrder(
                price:     p["price"]     as? Double ?? 0,
                side:      p["side"]      as? String ?? "",
                orderType: p["orderType"] as? String ?? "limit"
            )

        case "tradeLevelClose":
            let tlcData = p["data"].flatMap { try? JSONSerialization.data(withJSONObject: $0) }
                .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
            return .tradeLevelClose(
                label:        p["label"]       as? String ?? "",
                type:         p["type"]        as? String ?? "",
                action:       p["action"]      as? String ?? "",
                data:         tlcData,
                bracketType:  p["bracketType"] as? String,
                isFullscreen: p["isFullscreen"] as? Bool ?? false
            )

        case "tradeLevelDrag":
            let tldData = p["data"].flatMap { try? JSONSerialization.data(withJSONObject: $0) }
                .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
            return .tradeLevelDrag(
                label:        p["label"]        as? String ?? "",
                newPrice:     p["newPrice"]     as? Double ?? 0,
                data:         tldData,
                bracketType:  p["bracketType"]  as? String,
                isFullscreen: p["isFullscreen"] as? Bool ?? false
            )

        case "tradeLevelEdit":
            let tleData = p["data"].flatMap { try? JSONSerialization.data(withJSONObject: $0) }
                .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
            let rawChanges = p["changes"] as? [[String: Any]] ?? []
            let changes: [TradeLevelChange] = rawChanges.map { c in
                let cData = c["data"].flatMap { try? JSONSerialization.data(withJSONObject: $0) }
                    .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
                return TradeLevelChange(
                    field:             c["field"]             as? String ?? "",
                    newPrice:          c["newPrice"]          as? Double ?? 0,
                    data:              cData,
                    newLots:           c["newLots"]           as? Double,
                    bracketOrderLabel: c["bracketOrderLabel"] as? String
                )
            }
            return .tradeLevelEdit(
                label:        p["label"]        as? String ?? "",
                type:         p["type"]         as? String ?? "",
                data:         tleData,
                isFullscreen: p["isFullscreen"] as? Bool ?? false,
                newLots:      p["newLots"]      as? Double,
                changes:      changes
            )

        case "tradeLevelQtyChange":
            return .tradeLevelQtyChange(
                label:        p["label"]        as? String ?? "",
                type:         p["type"]         as? String ?? "",
                newLots:      p["newLots"]      as? Double ?? 0,
                previousLots: p["previousLots"] as? Double ?? 0,
                isFullscreen: p["isFullscreen"] as? Bool ?? false
            )

        case "tradeLevelConfirmed":
            return .tradeLevelConfirmed(
                label:        p["label"]        as? String ?? "",
                type:         p["type"]         as? String ?? "",
                isFullscreen: p["isFullscreen"] as? Bool ?? false
            )

        case "tradeLevelEditCancelled":
            return .tradeLevelEditCancelled(
                label:        p["label"]        as? String ?? "",
                type:         p["type"]         as? String ?? "",
                isFullscreen: p["isFullscreen"] as? Bool ?? false
            )

        case "tradeLevelEditOpen":
            let tleoData = p["data"].flatMap { try? JSONSerialization.data(withJSONObject: $0) }
                .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
            return .tradeLevelEditOpen(
                label:           p["label"]           as? String ?? "",
                type:            p["type"]            as? String ?? "",
                data:            tleoData,
                price:           p["price"]           as? Double ?? 0,
                side:            p["side"]            as? String,
                stopLossPrice:   p["stopLossPrice"]   as? Double,
                takeProfitPrice: p["takeProfitPrice"] as? Double,
                isFullscreen:    p["isFullscreen"]    as? Bool ?? false
            )

        case "tradeLevelBracketActivated":
            return .tradeLevelBracketActivated(
                label:        p["label"]        as? String ?? "",
                bracketType:  p["bracketType"]  as? String ?? "",
                price:        p["price"]        as? Double ?? 0,
                isFullscreen: p["isFullscreen"] as? Bool ?? false
            )

        case "draftInitiated":
            return .draftInitiated(
                side:         p["side"]         as? String ?? "",
                price:        p["price"]        as? Double ?? 0,
                orderType:    p["orderType"]    as? String ?? "",
                isFullscreen: p["isFullscreen"] as? Bool ?? false
            )

        case "draftCancelled":
            return .draftCancelled(
                label:        p["label"]        as? String ?? "",
                isFullscreen: p["isFullscreen"] as? Bool ?? false
            )

        case "dataRequest":
            guard
                let requestId  = p["requestId"] as? String,
                let timeframe  = p["timeframe"] as? String,
                let interval   = p["interval"]  as? String
            else { return nil }
            let drStart: Int64 = (p["start"] as? Int64) ?? Int64(p["start"] as? Double ?? 0)
            let drEnd:   Int64 = (p["end"]   as? Int64) ?? Int64(p["end"]   as? Double ?? 0)
            return .dataRequest(requestId: requestId, timeframe: timeframe, interval: interval,
                                start: drStart, end: drEnd)

        case "tfcToggle":
            return .tfcToggle(enabled: p["enabled"] as? Bool ?? false)

        case "crosshairToggle":
            return .crosshairToggle(enabled: p["enabled"] as? Bool ?? false)

        case "orderLineMoveStart":
            return .orderLineMoveStart(
                label:         p["label"] as? String ?? "",
                fromTimestamp: Self.int64(p["fromTimestamp"]),
                fromBarIndex:  Self.int(p["fromBarIndex"]),
                isFullscreen:  p["isFullscreen"] as? Bool ?? false
            )

        case "orderLineMoving":
            return .orderLineMoving(
                label:        p["label"] as? String ?? "",
                toTimestamp:  Self.int64(p["toTimestamp"]),
                toBarIndex:   Self.int(p["toBarIndex"]),
                isFullscreen: p["isFullscreen"] as? Bool ?? false
            )

        case "orderLineMoved":
            let olmData = p["data"].flatMap { try? JSONSerialization.data(withJSONObject: $0) }
                .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
            return .orderLineMoved(
                label:         p["label"] as? String ?? "",
                fromTimestamp: Self.int64(p["fromTimestamp"]),
                toTimestamp:   Self.int64(p["toTimestamp"]),
                fromBarIndex:  Self.int(p["fromBarIndex"]),
                toBarIndex:    Self.int(p["toBarIndex"]),
                data:          olmData,
                isFullscreen:  p["isFullscreen"] as? Bool ?? false
            )

        case "uiStateChange":
            return .uiStateChange(hasOpenUI: p["hasOpenUI"] as? Bool ?? false)

        case "symbolClick":
            return .symbolClick(symbol: p["symbol"] as? String ?? "")

        case "askAiClick":
            return .askAiClick

        case "layoutChange":
            guard let presetId = p["presetId"] as? String else { return nil }
            let syncJson: String = {
                guard
                    let sync = p["sync"],
                    let data = try? JSONSerialization.data(withJSONObject: sync),
                    let str  = String(data: data, encoding: .utf8)
                else { return "{}" }
                return str
            }()
            return .layoutChange(presetId: presetId, syncJson: syncJson)

        case "snapshot":
            guard let dataUrl = p["dataUrl"] as? String else { return nil }
            return .snapshot(dataUrl: dataUrl, action: p["action"] as? String ?? "download")

        case "compareDataRequest":
            guard
                let requestId  = p["requestId"] as? String,
                let symbol     = p["symbol"]    as? String,
                let timeframe  = p["timeframe"] as? String,
                let interval   = p["interval"]  as? String
            else { return nil }
            let cdStart: Int64 = (p["start"] as? Int64) ?? Int64(p["start"] as? Double ?? 0)
            let cdEnd:   Int64 = (p["end"]   as? Int64) ?? Int64(p["end"]   as? Double ?? 0)
            return .compareDataRequest(requestId: requestId, symbol: symbol,
                                       timeframe: timeframe, interval: interval,
                                       start: cdStart, end: cdEnd)

        case "compareAdded":
            guard
                let symbol = p["symbol"] as? String,
                let color  = p["color"]  as? String
            else { return nil }
            return .compareAdded(symbol: symbol, color: color)

        case "compareRemoved":
            guard let symbol = p["symbol"] as? String else { return nil }
            return .compareRemoved(symbol: symbol)

        case "compareError":
            guard let symbol = p["symbol"] as? String else { return nil }
            return .compareError(symbol: symbol, message: p["message"] as? String ?? "")

        case "indicatorAdded":
            guard
                let instanceId = p["instanceId"] as? String,
                let shortName  = p["shortName"]  as? String
            else { return nil }
            return .indicatorAdded(instanceId: instanceId, shortName: shortName,
                                   params: p["params"] as? [String: Any] ?? [:])

        case "indicatorRemoved":
            guard
                let instanceId = p["instanceId"] as? String,
                let shortName  = p["shortName"]  as? String
            else { return nil }
            return .indicatorRemoved(instanceId: instanceId, shortName: shortName)

        case "layoutSaved":
            guard
                let layout = p["layout"] as? [String: Any],
                let id   = layout["id"]   as? String,
                let name = layout["name"] as? String,
                let json = Self.jsonString(layout)
            else { return nil }
            return .layoutSaved(id: id, name: name, layoutJson: json)

        case "layoutApplied":
            guard
                let id = p["id"] as? String,
                let name = p["name"] as? String,
                let presetId = p["presetId"] as? String
            else { return nil }
            let json = Self.jsonString(p["layout"] as? [String: Any] ?? [:]) ?? "{}"
            return .layoutApplied(id: id, name: name, presetId: presetId, layoutJson: json)

        case "layoutDeleted":
            guard let id = p["id"] as? String else { return nil }
            return .layoutDeleted(id: id)

        case "indicatorTemplateSaved":
            guard
                let tpl = p["template"] as? [String: Any],
                let id   = tpl["id"]   as? String,
                let name = tpl["name"] as? String,
                let json = Self.jsonString(tpl)
            else { return nil }
            return .indicatorTemplateSaved(id: id, name: name, templateJson: json)

        case "indicatorTemplateApplied":
            guard
                let id = p["id"] as? String,
                let name = p["name"] as? String
            else { return nil }
            return .indicatorTemplateApplied(id: id, name: name, count: p["count"] as? Int ?? 0)

        case "indicatorTemplateDeleted":
            guard let id = p["id"] as? String else { return nil }
            return .indicatorTemplateDeleted(id: id)

        case "settingsTemplateSaved":
            guard
                let tpl = p["template"] as? [String: Any],
                let id   = tpl["id"]   as? String,
                let name = tpl["name"] as? String,
                let json = Self.jsonString(tpl)
            else { return nil }
            return .settingsTemplateSaved(id: id, name: name, templateJson: json)

        case "settingsTemplateApplied":
            guard
                let id = p["id"] as? String,
                let name = p["name"] as? String
            else { return nil }
            return .settingsTemplateApplied(id: id, name: name)

        case "settingsTemplateDeleted":
            guard let id = p["id"] as? String else { return nil }
            return .settingsTemplateDeleted(id: id)

        case "chartSettingsApplied":
            let settings = p["settings"] as? [String: Any] ?? [:]
            guard let json = Self.jsonString(settings) else { return nil }
            return .chartSettingsApplied(settingsJson: json,
                                         applyToAll: p["applyToAll"] as? Bool ?? false)

        case "quickSearchCommand":
            guard let id = p["id"] as? String else { return nil }
            return .quickSearchCommand(id: id,
                                       label: p["label"] as? String ?? "",
                                       group: p["group"] as? String ?? "")

        case "cursorModeChange":
            guard let mode = p["mode"] as? String else { return nil }
            return .cursorModeChange(mode: mode)

        case "magnetModeChange":
            return .magnetModeChange(enabled: p["enabled"] as? Bool ?? false)

        case "keepDrawingModeChange":
            return .keepDrawingModeChange(enabled: p["enabled"] as? Bool ?? false)

        case "copyDrawingsToAllChange":
            return .copyDrawingsToAllChange(enabled: p["enabled"] as? Bool ?? false)

        case "drawingToolbarVisibility":
            return .drawingToolbarVisibility(visible: p["visible"] as? Bool ?? true)

        case "drawingCreated":
            guard
                let drawing = p["drawing"] as? [String: Any],
                let json = Self.jsonString(drawing)
            else { return nil }
            return .drawingCreated(
                type: drawing["type"] as? String ?? "",
                drawingJson: json,
                copyToAll: p["copyToAll"] as? Bool ?? false
            )

        case "pricePrecisionChange":
            return .pricePrecisionChange(digits: p["digits"] as? Int ?? 2)

        case "barColorSourceChange":
            return .barColorSourceChange(source: p["source"] as? String ?? "open")

        case "timezoneChange":
            return .timezoneChange(timezone: p["timezone"] as? String ?? "UTC")

        case "statusLineChange":
            guard let o = p["statusLine"] as? [String: Any], let j = Self.jsonString(o)
            else { return nil }
            return .statusLineChange(statusLineJson: j)

        case "scalesChange":
            guard let o = p["scales"] as? [String: Any], let j = Self.jsonString(o)
            else { return nil }
            return .scalesChange(scalesJson: j)

        case "canvasOptionsChange":
            guard let o = p["canvas"] as? [String: Any], let j = Self.jsonString(o)
            else { return nil }
            return .canvasOptionsChange(canvasJson: j)

        case "priceScaleModeChange":
            return .priceScaleModeChange(mode: p["mode"] as? String ?? "normal")

        case "autoScaleChange":
            return .autoScaleChange(enabled: p["enabled"] as? Bool ?? true)

        case "goToDate":
            return .goToDate(
                time: (p["time"] as? NSNumber)?.int64Value ?? 0,
                barIndex: p["barIndex"] as? Int ?? 0
            )

        case "sidePanelVisibility":
            return .sidePanelVisibility(
                visible: p["visible"] as? Bool ?? false,
                tab: p["tab"] as? String ?? "data"
            )

        case "error":
            let message = p["message"] as? String ?? "Unknown error"
            let code    = p["code"]    as? String
            return .error(message: message, code: code?.isEmpty == false ? code : nil)

        default:
            return nil
        }
    }

    /// Re-serialises a payload sub-object back to a JSON string.
    ///
    /// Templates and layouts cross the bridge opaquely: the app stores the string
    /// the chart handed it and sends the same string back, so Swift never has to
    /// mirror a `ChartState` that only the chart interprets.
    /// A JSON number as `Int64`. JavaScriptCore hands numbers over as `Int` or
    /// `Double` depending on the value, so accept either. Kept out of line: the
    /// inline `as? Int64 ?? Int64(as? Double ?? 0)` form, repeated several times
    /// in one call, is more than the type checker will solve in reasonable time.
    private static func int64(_ value: Any?) -> Int64 {
        if let v = value as? Int64 { return v }
        if let v = value as? Double { return Int64(v) }
        return 0
    }

    /// A JSON number as `Int` — see ``int64(_:)``.
    private static func int(_ value: Any?) -> Int {
        if let v = value as? Int { return v }
        if let v = value as? Double { return Int(v) }
        return 0
    }

    private static func jsonString(_ object: [String: Any]) -> String? {
        guard
            let data = try? JSONSerialization.data(withJSONObject: object),
            let json = String(data: data, encoding: .utf8)
        else { return nil }
        return json
    }
}
