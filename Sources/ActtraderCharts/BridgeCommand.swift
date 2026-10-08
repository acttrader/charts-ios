import Foundation

/// Cross-pane sync toggles for the chart-owned layout popover (Symbol / Interval
/// / Crosshair / Time / Date range). All fields are optional — a `nil` field is
/// omitted from the payload and keeps its current (or library-default) value on
/// the chart side. Only meaningful when `enableMultipleLayouts` is `true`.
public struct LayoutSync {
    public var symbol: Bool?
    public var interval: Bool?
    public var crosshair: Bool?
    public var time: Bool?
    public var dateRange: Bool?

    public init(symbol: Bool? = nil, interval: Bool? = nil, crosshair: Bool? = nil,
                time: Bool? = nil, dateRange: Bool? = nil) {
        self.symbol = symbol
        self.interval = interval
        self.crosshair = crosshair
        self.time = time
        self.dateRange = dateRange
    }

    var jsonObject: [String: Any] {
        var o: [String: Any] = [:]
        if let symbol { o["symbol"] = symbol }
        if let interval { o["interval"] = interval }
        if let crosshair { o["crosshair"] = crosshair }
        if let time { o["time"] = time }
        if let dateRange { o["dateRange"] = dateRange }
        return o
    }
}

/// The opt-in header features: indicator templates, chart-settings templates,
/// saved layouts and Quick Search.
///
/// Grouped into one struct rather than nine more associated values on
/// ``BridgeCommand/initialize(...)`` — they ship and roll back together, and a
/// struct keeps the init call readable. Every field is optional; a `nil` field is
/// omitted from the payload and the chart keeps its default, which is **off**.
/// With the struct omitted entirely the chart renders exactly as it did before
/// these features existed.
///
/// None of them persist anything. Each emits an event carrying the saved object
/// and your app stores it — the same contract `stateChange` already follows.
public struct HeaderFeatures {
    /// Show the Templates block at the foot of the indicators flyout — named,
    /// reusable indicator sets. No new header button.
    public var enableIndicatorTemplates: Bool?
    /// Indicator templates to list at init, as a JSON array string.
    public var indicatorTemplatesJson: String?
    /// Show the Templates row and the "Apply to all charts" switch in the Chart
    /// Settings dialog.
    public var enableSettingsTemplates: Bool?
    /// Settings templates to list at init, as a JSON array string.
    public var settingsTemplatesJson: String?
    /// Show the Saved layouts section in the layout popover — a grid preset plus
    /// every pane's full state. Requires `enableMultipleLayouts`.
    public var enableSavedLayouts: Bool?
    /// Saved layouts to list at init, as a JSON array string.
    public var savedLayoutsJson: String?
    /// Enable Quick Search, the command palette over everything the chart can do.
    /// iOS has no Ctrl/⌘+K, so open it with
    /// ``ActtraderChartsView/openQuickSearch()``.
    public var enableQuickSearch: Bool?
    /// Add a search button to the header for Quick Search. Default `false` — a new
    /// button would change a header this feature otherwise leaves alone.
    public var quickSearchShowButton: Bool?

    public init(enableIndicatorTemplates: Bool? = nil, indicatorTemplatesJson: String? = nil,
                enableSettingsTemplates: Bool? = nil, settingsTemplatesJson: String? = nil,
                enableSavedLayouts: Bool? = nil, savedLayoutsJson: String? = nil,
                enableQuickSearch: Bool? = nil, quickSearchShowButton: Bool? = nil) {
        self.enableIndicatorTemplates = enableIndicatorTemplates
        self.indicatorTemplatesJson = indicatorTemplatesJson
        self.enableSettingsTemplates = enableSettingsTemplates
        self.settingsTemplatesJson = settingsTemplatesJson
        self.enableSavedLayouts = enableSavedLayouts
        self.savedLayoutsJson = savedLayoutsJson
        self.enableQuickSearch = enableQuickSearch
        self.quickSearchShowButton = quickSearchShowButton
    }

    /// Merges these flags into an `init` payload. JSON-string fields are parsed;
    /// a malformed one is dropped rather than throwing, so a corrupt stored
    /// template can never stop the chart from starting.
    func merge(into payload: inout [String: Any]) {
        if let enableIndicatorTemplates { payload["enableIndicatorTemplates"] = enableIndicatorTemplates }
        if let enableSettingsTemplates { payload["enableSettingsTemplates"] = enableSettingsTemplates }
        if let enableSavedLayouts { payload["enableSavedLayouts"] = enableSavedLayouts }
        if let enableQuickSearch { payload["enableQuickSearch"] = enableQuickSearch }
        if let quickSearchShowButton { payload["quickSearch"] = ["showButton": quickSearchShowButton] }
        func embedArray(_ key: String, _ json: String?) {
            guard let json,
                  let data = json.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [Any]
            else { return }
            payload[key] = obj
        }
        embedArray("indicatorTemplates", indicatorTemplatesJson)
        embedArray("settingsTemplates", settingsTemplatesJson)
        embedArray("savedLayouts", savedLayoutsJson)
    }
}

/// Commands sent from native iOS code to the chart WebView.
///
/// Each case serialises itself to the JSON format expected by
/// `window.ChartBridge.send()`:
/// ```json
/// { "type": "<cmd>", "payload": { ...fields } }
/// ```
///
/// Pass the result of `jsonString` to `ActtraderChartsView`'s internal
/// `sendCommand(_:)` — do **not** call `evaluateJavaScript` directly.
public enum BridgeCommand {

    // ── Core ──────────────────────────────────────────────────────────────────

    /// Re-creates the chart engine. Sent automatically on first load via
    /// `ActtraderChartsView.init(...)`.
    case initialize(
        theme: String,
        symbol: String?,
        series: String?,
        timeframe: String?,
        duration: String?,
        enableTrading: Bool,
        showVolume: Bool?,
        showUI: Bool?,
        showDrawingTools: Bool?,
        showBidAskLines: Bool?,
        showAskLine: Bool?,
        showBidLine: Bool?,
        showActLogo: Bool?,
        showCandleCountdown: Bool?,
        candleCountdownTimeframes: [String]?,
        disableCountdownOnMobile: Bool?,
        maxSubPanes: Int?,
        mobileBarDivisor: Int?,
        /// Minimum bars expected from the initial fetch before giving up. If fewer bars
        /// are returned by `onDataRequest`, the chart engine auto-widens the lookback
        /// window and retries — handles weekends, market closures, and sparse symbols.
        /// Default: `10`.
        minInitialBars: Int?,
        /// Hard ceiling (in milliseconds) on fetch-window lookback for auto-widening
        /// retries. Default: 365 days.
        maxLookbackMs: Int64?,
        /// Enable momentum (kinetic) scrolling on drag release. Default: `true`.
        momentumScrollEnabled: Bool?,
        /// Per-frame velocity decay factor, normalised to 60 fps. Clamped [0.80, 0.99]. Default: `0.95`.
        momentumDecay: Double?,
        /// Minimum release velocity (px/ms) to trigger momentum. Default: `0.3`.
        momentumThreshold: Double?,
        /// Maximum launch velocity (px/ms) for momentum. Default: `6.0`.
        momentumMaxVelocity: Double?,
        targetCandleWidth: Double?,
        tickClosePriceSource: String?,
        showLtpPrice: Bool?,
        /// Show a price-source dropdown in the chart header listing these sources,
        /// e.g. `["ltp", "bid"]` (dealing feeds). A user pick switches the live
        /// candle source and emits `priceSourceChange`. Hidden when `nil` or empty.
        priceSourceSelector: [String]?,
        tradesThresholdForHorizontalLine: Int?,
        tradeDisplayFilter: String?,
        positionRenderStyle: String?,
        hideLevelConfirmCancel: Bool?,
        /// When `true`, clicking or tapping outside a selected/active trade level dismisses
        /// it (reverting any pending edits, mirroring ✗ Cancel). When `false` (default),
        /// the active level is preserved across outside clicks — only ✓ / ✗ buttons,
        /// tapping the level itself, or removing it via `setLevels` will dismiss it.
        /// Recommended `false` so incidental clicks (price-axis resize, taps outside the
        /// QTY input) don't drop an in-progress edit. Default: `false`.
        deselectActiveOnOutsideClick: Bool?,
        /// Always render SL/TP bracket lines + price pills, even when the parent
        /// trade level is not hovered/selected. Close (×) buttons stay hover-only.
        /// Default: `false`.
        showTradeLevelsAlways: Bool?,
        /// Show the candle countdown timer on the right price axis, just below
        /// the live price tag. Subject to the same `candleCountdownTimeframes`
        /// filter. Default: `false`.
        showPriceAxisCountdown: Bool?,
        /// Multiplier for trade-level Confirm/Cancel/Edit/Close button radii and gaps.
        /// Scales visuals AND hit/drag areas together — useful for touch targets.
        /// Clamped to `[1.0, 3.0]`. Default: `1.0`.
        tradeLevelButtonScale: Double?,
        bracketLabelMode: String?,
        currencySymbol: String?,
        levelClusteringEnabled: Bool?,
        clusterThresholdDistance: Int?,
        /// Enable TFC toggle button in the top bar. When `false`, TFC is completely disabled. Default: `true`.
        tfcEnabled: Bool?,
        showSettings: Bool?,
        /// Show the fullscreen toggle button in the top bar. Default: `false` on mobile (hidden).
        showFullscreenButton: Bool,
        hideSymbolAndTick: Bool?,
        hideOHLCV: Bool?,
        showBottomBar: Bool?,
        aggregateFrom: [String: String]?,
        canvasColorsJson: String?,
        themeOverridesJson: String?,
        labelsJson: String?,
        uiConfigJson: String?,
        durationTimeframeMap: [String: String]?,
        onSymbolClick: Bool?,
        /// When `true`, the `"mobile"` header renders an "Ask AI" (✦) button that
        /// fires an `askAiClick` event on tap. No effect in other header layouts.
        /// Default: `nil` (button hidden).
        onAskAiClick: Bool?,
        /// IANA timezone string for time-axis and crosshair labels. Default: `"UTC"`.
        timezone: String?,
        /// Top-bar variant. `"simple"` (default) shows the classic TopBar; `"advanced"`
        /// uses the pill-style AdvancedToolbar; `"compact"` uses the slim per-pane
        /// CompactToolbar (intended for cells of a host-rendered multi-pane grid);
        /// `"mobile"` renders the compact mobile header (Tools · timeframe pills ·
        /// optional Ask AI button).
        headerLayout: String?,
        /// Enables the chart-owned multi-layout popover (Layout button → 26 preset
        /// picker + cross-pane sync toggles). Fires `layoutChange` events; the host
        /// is responsible for mounting / tearing down panes — the chart only emits
        /// intent.
        enableMultipleLayouts: Bool?,
        /// Enables the chart-owned snapshot popover (Snapshot button → Download / Copy).
        /// Fires `snapshot` events with a base64 PNG so the native layer can intercept
        /// and save via platform APIs (Photos, UIPasteboard).
        enableSnapshot: Bool?,
        /// Hides the chart header entirely (whichever variant `headerLayout` would
        /// have rendered). Bottom bar, drawing tools, and on-canvas overlays remain
        /// on their own flags. Drive the chart from native UI via `setTimeframe`,
        /// `setSeries`, `addIndicatorByName`, `removeIndicator`. Default: `false`.
        hideHeader: Bool?,
        /// Compare symbols to add automatically on chart init. Each entry triggers
        /// a `compareDataRequest` event against the initial primary range —
        /// respond via ``BridgeCommand/resolveCompareDataRequest(requestId:bars:)``.
        initialCompares: [String]?,
        /// Maximum concurrent compare symbols. Adding beyond emits a
        /// `compareError` event. Default: `8`.
        maxCompares: Int?,
        /// Initial state of the chart-owned layout popover's cross-pane sync
        /// toggles (only meaningful with `enableMultipleLayouts`). Partial — any
        /// `nil` field falls back to the library default. Change it later on a
        /// live chart via ``ActtraderChartsView/setLayoutSync(_:)``.
        layoutSync: LayoutSync?,
        /// Contract specs for `symbol` — pip size, contract size, money
        /// conversion. Lets the ruler report pips instead of a bare price
        /// distance. Swap it later via
        /// ``ActtraderChartsView/setInstrument(_:)``.
        instrument: InstrumentSpec?,
        /// Account equity and per-trade risk used to size the Long/Short
        /// position tools. Keep it current via
        /// ``ActtraderChartsView/setAccount(_:)``.
        account: AccountSpec?,
        /// Enable the reworked drawing tools as one switch: Long/Short Position
        /// in a new Forecasting group, freehand Brush & Highlighter, and the full
        /// Ruler readout. Drawings only — nothing reaches the broker. Position
        /// quantity/money need `account`; pips need `instrument`. Default: `false`.
        enableForecasting: Bool?,
        /// Puts a crosshair on/off switch in the chart header. The crosshair itself
        /// starts on (see `crosshairEnabled`) so the icon is tinted; tapping it hides
        /// the crosshair — and the floating trade button that rides on it — and drops
        /// the icon to its plain state; tapping again brings both back. Each tap emits
        /// a `crosshairToggle` event so the host can persist the choice. Default: `false`.
        enableCrossHairHeader: Bool? = nil,
        /// Whether the crosshair is drawn at all. `false` hides it and the floating trade
        /// button, ignores mirrored crosshair positions and keeps the long-press crosshair
        /// from arming. Seeds the header switch when `enableCrossHairHeader` is on; change
        /// it later via ``ActtraderChartsView/setCrosshairEnabled(_:)``. Default: `true`.
        crosshairEnabled: Bool? = nil,
        /// Enables horizontal (time-axis) order-line dragging. A level passed to `setLevels`
        /// with `"timeDraggable": true` — open positions and pending orders alike — can have
        /// its info-box badge dragged left/right to re-anchor it to another candle; a
        /// `"timestamp"` (unix ms) says which candle the badge starts over. Sideways drags
        /// keep the price locked and end in an `orderLineMoved` event; a pending order's
        /// badge still drags vertically to move its entry price — the first movement picks
        /// the axis. Broker-gated: enable it only for the users who should have it.
        /// Default: `false`.
        orderLineTimeDrag: Bool? = nil,
        /// Snap a horizontally dragged badge to the nearest candle on release. Default: `true`.
        orderLineDragSnap: Bool? = nil,
        /// Remember where each badge was dropped (WebView `localStorage`, keyed by level
        /// label) so it comes back to the same candle after a reload. Default: `true`.
        orderLineAnchorPersistence: Bool? = nil,
        /// Where an un-dragged `timeDraggable` badge sits: `"timestamp"` (over the candle at
        /// the level's `timestamp`) or `"center"` (mid-chart, so a fresh market order does
        /// not land on the latest candle at the right edge). Default: `"timestamp"`.
        orderLineDefaultAnchor: String? = nil,
        /// When a level gains a new SL/TP (from `setLevels` or `updateLevelBracket`)
        /// whose price sits outside the visible price range, widen the price axis so
        /// the new line comes into view with the candles already on screen.
        /// Default: `false`.
        revealNewBrackets: Bool? = nil,
        /// The opt-in header features — indicator templates, settings templates,
        /// saved layouts and Quick Search. Omit for the chart's long-standing
        /// behaviour; see ``HeaderFeatures``.
        headerFeatures: HeaderFeatures? = nil,
        /// Box/reversal parameters for the price-transform chart types (Renko,
        /// Line Break, Kagi, Point & Figure) as a JSON object string — e.g.
        /// `{"renko":{"boxSize":{"kind":"fixed","size":5}}}`.
        ///
        /// Omit for the default of **ATR(14)** on all of them, which is what you
        /// want unless the instrument has a meaningful fixed tick: a box of "10"
        /// is noise on an index and a lifetime on a forex pair.
        seriesOptionsJson: String? = nil,
        /// Initial pointer behaviour over the plot: `"cross"` (default), `"dot"`,
        /// `"arrow"`, `"demonstration"` (a fading laser trail for screen-sharing)
        /// or `"eraser"` (a tap deletes the drawing under it). Independent of the
        /// drawing tool.
        cursorMode: String? = nil,
        /// Show an OHLCV readout beside a long press, on top of the crosshair it
        /// already arms. The OHLC strip carries the same numbers but sits at the
        /// far end of the screen from the finger. Default: `false`.
        valueTooltip: Bool? = nil,
        /// Add a **Cursors** group to the top of the drawing toolbar (Cross, Dot,
        /// Arrow, Demonstration, Eraser). Default `false`, because it adds a
        /// category to a toolbar apps have laid out around its current contents.
        enableCursorModes: Bool? = nil,
        /// Add an **Icons & Emojis** group to the drawing toolbar: a picker of
        /// emojis, stickers and monochrome icons, placed as `icon` drawings and
        /// resizable by dragging a corner. Default `false`, for the same reason
        /// as `enableCursorModes`.
        enableIconTools: Bool? = nil,
        /// Add the **Status Line**, **Scales** and **Canvas** tabs to Chart
        /// Settings, and the bar-colouring choice to Appearance. Default `false`.
        enableChartSettings: Bool? = nil,
        /// What the status line shows, as JSON, e.g. `{"barChange":true}`.
        statusLineJson: String? = nil,
        /// Price/time axis options, as JSON, e.g. `{"timezone":"Asia/Tokyo"}`.
        scalesJson: String? = nil,
        /// Grid, watermark and crosshair options, as JSON.
        canvasJson: String? = nil,
        /// `"open"` (default) or `"previousClose"` bar colouring.
        barColorSource: String? = nil,
        /// Add the bottom bar's Go-to-date / timezone / scale cluster. Needs
        /// `showBottomBar`. Default `false`.
        enableScaleControls: Bool? = nil,
        /// `"normal"` (default), `"log"` or `"percent"` price axis.
        priceScaleMode: String? = nil,
        /// Whether the Y range refits to the visible bars. Default `true`.
        autoScale: Bool? = nil,
        /// Add the right-hand Data Window / Objects panel. It takes 232px out
        /// of the plot, so it is off by default.
        enableSidePanels: Bool? = nil,
        /// Snap drawing points to the nearest OHLC of the bar under the cursor.
        /// Default: `false`.
        magnetMode: Bool? = nil,
        /// Keep the drawing tool armed after each completed drawing, so a series
        /// can be placed without returning to the toolbar. Default: `false`.
        keepDrawingMode: Bool? = nil,
        /// Announce every new drawing via `.drawingCreated` with `copyToAll`, so
        /// your app can replicate it across the other panes of a layout — the
        /// chart cannot, since only you know which panes exist. Default: `false`.
        copyDrawingsToAllCharts: Bool? = nil,
        /// Bar Replay — the Replay button and its control strip. Default: `false`.
        enableReplay: Bool? = nil
    )

    /// Replaces the full dataset.
    case loadData(bars: [OHLCVBar], fitAll: Bool)

    /// Pushes a live bid/ask tick for streaming updates.
    /// `ltp`/`ltpv` (last traded price/volume) are optional — sent by
    /// exchange/dealing feeds and consumed when `tickClosePriceSource == "ltp"`.
    case pushTick(bid: Double, ask: Double, timestamp: Int64, ltp: Double?, ltpv: Double?)

    /// Shows/hides the LTP price marker at runtime. Pass `nil` to restore the
    /// default (marker follows `tickClosePriceSource == "ltp"`).
    case setShowLtpPrice(show: Bool?)

    /// Switches which price drives live candle close/high/low at runtime
    /// (`"bid"`, `"ask"` or `"ltp"`). Also syncs the header price-source
    /// dropdown when `priceSourceSelector` is enabled.
    case setTickClosePriceSource(source: String)

    /// Backward-compatible factory matching the pre-LTP `pushTick` shape.
    public static func pushTick(bid: Double, ask: Double, timestamp: Int64) -> BridgeCommand {
        .pushTick(bid: bid, ask: ask, timestamp: timestamp, ltp: nil, ltpv: nil)
    }

    // ── Appearance ────────────────────────────────────────────────────────────

    /// Switches between `"dark"` and `"light"` themes.
    case setTheme(String)

    /// Changes the display timezone for time-axis and crosshair labels.
    /// Accepts any IANA string (e.g. `"America/New_York"`), `"UTC"`, or `"local"`.
    case setTimezone(String)

    /// Updates the chart-owned layout popover's cross-pane sync toggles. Partial —
    /// `nil` fields keep their current value. Only meaningful with
    /// `enableMultipleLayouts`.
    case setLayoutSync(LayoutSync)

    /// Shows or hides the crosshair at runtime — together with the floating trade button
    /// that rides on it. Same effect as tapping the header switch (`enableCrossHairHeader`);
    /// the switch follows, and a `crosshairToggle` event fires when the state changes.
    case setCrosshairEnabled(Bool)

    /// Changes the chart series type (e.g. `"candlestick"`, `"line"`, `"area"`).
    case setSeries(String)

    /// Changes the active timeframe (e.g. `"1m"`, `"1h"`, `"1D"`).
    case setTimeframe(String)

    /// Selects a duration and refetches; the timeframe is paired automatically
    /// unless one is supplied. The x-axis rescales from the new bars.
    case setDuration(duration: String, timeframe: String?)

    /// Switches SL/TP pills between the bracket price and the money it is worth.
    case setBracketLabelMode(mode: String, currencySymbol: String?)

    /// Updates the displayed symbol name.
    case setSymbol(String)

    /// Replaces the contract specs the measurement tools use to report pips and
    /// money. Pair it with ``setSymbol(_:)``; pass `nil` to clear them.
    case setInstrument(InstrumentSpec?)

    /// Updates the account figures the Long/Short position tools size against.
    /// Push it whenever equity moves; `nil` clears it.
    case setAccount(AccountSpec?)

    // ── Studies / Drawings ────────────────────────────────────────────────────

    /// Adds a study overlay or oscillator by short name (e.g. `"SMA"`, `"RSI"`).
    case addIndicator(name: String, params: [String: Any]?)

    /// Removes a study by name.
    case removeIndicator(String)

    /// Activates a drawing tool by ID, or `nil` to deactivate.
    case setDrawingTool(String?)

    /// Removes all drawings from the chart.
    case clearAllDrawings

    /// Chooses what the status line shows, as JSON, e.g. `{"barChange":true}`.
    /// Merges — fields left out keep whatever they are.
    case setStatusLineSettings(statusLineJson: String)

    /// Price- and time-axis options, as JSON, e.g.
    /// `{"highLowLabels":true,"pricePrecision":4,"timezone":"Asia/Tokyo"}`. Merges.
    case setScalesSettings(scalesJson: String)

    /// Grid, watermark and crosshair options, as JSON. Colours stay in
    /// `setCanvasColors`. Merges.
    case setCanvasOptions(canvasJson: String)

    /// Whether a bar is "up" against its own open (`"open"`, the default) or
    /// the previous bar's close (`"previousClose"`).
    case setBarColorSource(source: String)

    /// Decimal places for every price the chart writes; `nil` infers them from
    /// the feed again. Display only — it does not change pip size.
    case setPricePrecision(digits: Int?)

    /// Switches the price axis: `"normal"`, `"log"` or `"percent"`. Log maps
    /// equal ratios to equal height; it is unavailable on data that reaches
    /// zero or below and maps linearly there rather than refusing to draw.
    case setPriceScaleMode(mode: String)

    /// Turns automatic Y-range fitting on or off. Switching it off freezes
    /// what is on screen, so the chart does not jump as it stops moving.
    case setAutoScale(enabled: Bool)

    /// Scrolls to a date, centring the nearest bar. ISO 8601 or unix ms.
    /// Nearest, not exact: the date asked for is often a weekend or a holiday.
    case goToDate(date: String)

    /// Shows or hides the docked Data Window / Objects panel.
    case setSidePanelVisible(visible: Bool)

    // ── Bar Replay ───────────────────────────────────────────────────────────
    /// Opens the Bar Replay strip and arms "Select bar". Requires `enableReplay` on init.
    case openReplay
    /// Leaves any running replay and closes the strip.
    case closeReplay
    /// Starts a replay: bars after the last bar at or before `time` (unix ms) are hidden until revealed.
    case startReplay(time: Int64)
    /// Reveals bars one by one at the replay speed.
    case playReplay
    /// Pauses playback.
    case pauseReplay
    /// Reveals the next hidden bar.
    case replayStepForward
    /// Replay speed in bars per second (0.1 – 10).
    case setReplaySpeed(barsPerSecond: Double)
    /// Ends the replay and shows the live chart; the strip stays open.
    case exitReplay

    /// Switches the panel. `tab` is `"data"` or `"objects"`.
    case setSidePanelTab(tab: String)

    /// Shows or hides one drawing. Hiding the selected one deselects it.
    case setDrawingVisible(id: String, visible: Bool)

    /// Locks or unlocks one drawing. Locking the selected one deselects it.
    case setDrawingLocked(id: String, locked: Bool)

    /// Deletes one drawing by id, whether or not it is selected.
    case deleteDrawing(id: String)

    /// Selects a drawing by id. `nil` clears the selection.
    case selectDrawing(id: String?)

    /// Appends one drawing, leaving the existing ones alone — the receiving end
    /// of copy-to-all-charts. Pass the `drawingJson` from a `drawingCreated`
    /// event to every other chart view; each copy gets its own id.
    case addDrawing(drawingJson: String)

    // ── State ─────────────────────────────────────────────────────────────────

    /// Requests the current chart state; fires a `stateSnapshot` event in response.
    case getState

    /// Asks the chart to send the native-UI catalog again (`catalog` event). The chart already
    /// sends it once after every init; use this to refresh a cached copy. Works before init.
    case getCatalog

    /// Restores a previously captured chart state.
    /// - Parameter stateJson: Raw JSON string from a prior `stateSnapshot` event.
    case setState(String)

    /// Resolves a pending dataLoader request with fetched bars.
    /// - Parameters:
    ///   - requestId: The ID received in the `dataRequest` bridge event.
    ///   - bars: The fetched OHLCV bars to return to the chart engine.
    case resolveDataRequest(requestId: String, bars: [OHLCVBar])

    /// Enables or disables verbose tick/render logging in the chart engine.
    case setDebug(Bool)

    /// Destroys the chart engine and releases resources.
    case destroy

    // ── Trade levels ──────────────────────────────────────────────────────────

    /// Replaces all levels of the given type with the provided data array.
    /// - Parameters:
    ///   - levels: Array of level objects. Each must contain at least `labelKey` and `priceKey` fields.
    ///             Optional per-entry fields: `side`, `stopLossPrice`, `takeProfitPrice`,
    ///             `pnl`, `pnlText`, `text`, `lots`, `orderType`, `entryPriceEditable`.
    ///   - labelKey: Key in each object that holds the level's label string.
    ///   - priceKey: Key in each object that holds the level's price (Double).
    ///   - type: `"position"`, `"pending"`, or `"trade"`.
    ///   - pnlKey: Optional key for a numeric P&L value.
    ///   - pnlTextKey: Optional key for a formatted P&L string.
    case setLevels(
        levels: [[String: Any]],
        labelKey: String,
        priceKey: String,
        type: String,
        pnlKey: String?,
        pnlTextKey: String?
    )

    /// Removes a single level by its label. No-op if not found.
    case removeLevelByLabel(String)

    /// Updates the entry price of an existing level.
    case updateLevelMainPrice(label: String, price: Double)

    /// Mirrors a quantity change from the host's modify panel onto the level's pill.
    case updateLevelQty(label: String, qty: Double)

    /// Updates or removes a SL/TP bracket on an existing level.
    /// Pass `nil` for `price` to remove the bracket.
    /// - Parameter bracketType: `"sl"` or `"tp"`.
    case updateLevelBracket(label: String, bracketType: String, price: Double?)

    /// Adds a SL or TP bracket to an existing level at an auto-computed default price.
    /// Listen for `tradeLevelBracketActivated` to receive the chosen price so your form can populate its input.
    /// - Parameter bracketType: `"sl"` or `"tp"`.
    case addLevelBracket(label: String, bracketType: String)

    /// Unified bracket placement for mobile UIs — works for both existing levels and the active draft order.
    /// Pass `label` (OrderID/TradeID) for an existing level; omit it for the active draft order.
    /// Fires `tradeLevelBracketActivated` with the auto-computed price (label is nil in the event for draft orders).
    case addBracket(bracketType: String, label: String?)

    /// Unified bracket removal for mobile UIs — works for both existing levels and the active draft order.
    /// Pass `label` (OrderID/TradeID) for an existing level; omit it for the active draft order.
    case removeBracket(bracketType: String, label: String?)

    /// Cancels an in-progress level edit, reverting to the last confirmed price.
    case cancelLevelEdit(String)

    /// Programmatically selects (highlights) a level, or deselects all when `nil`.
    case selectLevel(String?)

    // ── Draft orders ──────────────────────────────────────────────────────────

    /// Shows a draggable limit or stop draft order line on the chart.
    /// While the user drags it, `tradeLevelDrag` events fire; confirming emits `tradeLevelConfirmed`.
    /// - Parameter orderType: `"limit"` or `"stop"`.
    case showDraftOrder(price: Double, side: String, orderType: String)

    /// Shows a non-draggable market-order preview line.
    /// SL/TP brackets can still be attached via `updateDraftOrderBracket`.
    case showMarketDraft(price: Double, side: String)

    /// Removes any active draft order from the chart.
    case clearDraftOrder

    /// Cancels whatever is currently being edited or drafted on the chart (draft order or level edit). No-op when nothing is active.
    case cancelCurrentEdit

    /// Updates the lot quantity shown on the active draft order chip.
    case setDraftOrderLots(Double)

    /// Moves the draft order price line to a new price.
    case updateDraftOrderPrice(Double)

    /// Updates or removes a SL/TP bracket on the active draft order.
    /// Pass `nil` for `price` to remove the bracket.
    /// - Parameter bracketType: `"sl"` or `"tp"`.
    case updateDraftOrderBracket(bracketType: String, price: Double?)

    /// Sets or clears the estimated PNL text shown on a draft order's SL or TP bracket line.
    /// Call this after `updateDraftOrderBracket` to display consumer-calculated P&L.
    /// - Parameter bracketType: `"sl"` or `"tp"`.
    /// - Parameter pnlText: Pre-formatted string (e.g. `"-$12.50"`). Pass `nil` to clear.
    case setDraftBracketPnl(bracketType: String, pnlText: String?)

    // ── UI controls ───────────────────────────────────────────────────────────

    /// Shows or hides the volume sub-pane.
    case setVolume(Bool)

    /// Toggles TFC (Trade from Charts) on or off at runtime.
    case setTfcActive(Bool)

    /// Updates the symbol list used by the ISIN picker modal after initial setup.
    case setIsins([String])

    /// Resets both price and time axes to their default auto-fit state.
    case resetView

    /// Completely resets the chart to a blank state — clears all bars, the live
    /// price line, and any in-flight fetch. Call before switching to a new symbol
    /// so that no previous symbol data bleeds into the new chart.
    case resetData

    /// Shows or hides the loading overlay.
    case setLoading(Bool)

    /// Updates per-theme deep-partial color overrides and rebuilds the active theme.
    /// - Parameter overridesJson: Raw JSON string, e.g. `{"dark":{"background":"#111"}}`.
    case setThemeOverrides(String)

    /// Recolours the **canvas only** at runtime — the plot and its axes — and leaves the
    /// chrome (header, bottom bar, drawing toolbar, dialogs, popovers) on the theme from
    /// ``setThemeOverrides(_:)``. Same per-theme picks as the in-chart Chart Settings dialog.
    /// - Parameter colorsJson: Raw JSON string, e.g. `{"dark":{"background":"#ff00ff"}}`; `nil` clears the picks.
    case setCanvasColors(String?)

    /// Replaces a specific bar with authoritative OHLCV data (e.g. a correction from the server).
    /// - Parameter barTime: Unix millisecond timestamp of the bar to replace.
    case correctBar(barTime: Int64, bar: OHLCVBar)

    /// Dismisses any open flyouts, modals, dropdowns, or popovers in the chart UI.
    ///
    /// Prefer calling ``ActtraderChartsView/dismissAllUI()``, which short-circuits
    /// the WebView round-trip when nothing is open and returns a boolean so you
    /// can decide whether to consume a back action.
    case dismissAllUI

    // ── Compare ───────────────────────────────────────────────────────────────

    /// Adds a compare symbol overlay. The chart fires a `compareDataRequest`
    /// event; reply via ``BridgeCommand/resolveCompareDataRequest(requestId:bars:)``.
    case addCompare(String)

    /// Removes a compare symbol. No-op when not active.
    case removeCompare(String)

    /// Removes every active compare symbol.
    case clearCompares

    /// Resolves a pending `compareDataRequest` with fetched bars.
    case resolveCompareDataRequest(requestId: String, bars: [OHLCVBar])

    // ── Snapshot ──────────────────────────────────────────────────────────────

    /// Captures the chart without the user opening the snapshot popover.
    ///
    /// Replies with a `snapshot` event carrying a PNG `data:` URL — decode it and
    /// hand it to `UIActivityViewController`, Photos or `UIPasteboard`; the
    /// in-WebView browser download does nothing on iOS. Requires `enableSnapshot`.
    ///
    /// - Parameter action: `"download"` or `"copy"`, echoed back on the event so one
    ///   handler can tell a share from a copy.
    case requestSnapshot(action: String)

    // ── Indicator templates ───────────────────────────────────────────────────

    /// Replaces the templates listed in the indicators flyout.
    /// - Parameter templatesJson: A JSON array of templates your app stored.
    case setIndicatorTemplates(templatesJson: String)

    /// Saves the chart's current indicators; replies with `indicatorTemplateSaved`.
    case captureIndicatorTemplate(name: String)

    /// Replaces the chart's indicators with a template's. Accepts the id or the name.
    case applyIndicatorTemplate(id: String)

    /// Removes a template from the flyout. Delete it from your storage too.
    case deleteIndicatorTemplate(id: String)

    // ── Chart-settings templates ──────────────────────────────────────────────

    /// Replaces the templates listed in the Chart Settings dialog.
    case setSettingsTemplates(templatesJson: String)

    /// Saves the chart's current settings; replies with `settingsTemplateSaved`.
    case captureSettingsTemplate(name: String)

    /// Applies a saved settings template. Accepts the id or the name.
    case applySettingsTemplate(id: String)

    /// Removes a settings template. Delete it from your storage too.
    case deleteSettingsTemplate(id: String)

    /// Applies a settings snapshot to this chart — the "Apply to all charts"
    /// fan-out, sent once per other pane.
    /// - Parameter settingsJson: The `settings` object from `chartSettingsApplied`.
    case applyChartSettings(settingsJson: String)

    // ── Saved layouts ─────────────────────────────────────────────────────────

    /// Replaces the layouts listed in the layout popover.
    case setSavedLayouts(layoutsJson: String)

    /// Saves the current preset and this chart's state; replies with `layoutSaved`.
    /// - Parameter paneId: Identifies this chart within the layout. `"main"` for a
    ///   single-chart screen; a distinct id per pane in a grid.
    case captureSavedLayout(name: String, paneId: String)

    /// Restores a saved layout into this chart. Accepts the id or the name.
    case applySavedLayout(id: String, paneId: String)

    /// Removes a saved layout. Delete it from your storage too.
    case deleteSavedLayout(id: String)

    /// Selects a grid preset. Emits `layoutChange`; mounting the panes stays your
    /// app's job — the chart owns only the picker.
    case setLayoutPreset(presetId: String)

    // ── Quick Search ──────────────────────────────────────────────────────────

    /// Opens the command palette. The entry point on iOS, which has no Ctrl/⌘+K —
    /// wire it to a toolbar item. Requires `enableQuickSearch`.
    case openQuickSearch

    /// Closes the command palette.
    case closeQuickSearch

    // ── Chart types ───────────────────────────────────────────────────────────

    /// Retunes the price-transform chart types — Renko, Line Break, Kagi and
    /// Point & Figure.
    ///
    /// Merged over the current options, so one series can be retuned without
    /// disturbing the others. The chart *type* is still chosen with
    /// ``BridgeCommand/setSeries(_:)``: `"hlc"`, `"renko"`, `"linebreak"`,
    /// `"kagi"` and `"pointfigure"` are new values of the same series string.
    case setSeriesOptions(optionsJson: String)

    // ── Cursors ───────────────────────────────────────────────────────────────

    /// Switches pointer behaviour over the plot.
    ///
    /// Independent of the drawing tool — switching mode never cancels a drawing in
    /// progress. Replies with `.cursorModeChange`.
    ///
    /// - Parameter mode: `"cross"`, `"dot"`, `"arrow"`, `"demonstration"` or `"eraser"`.
    case setCursorMode(mode: String)

    // ── Drawing toolbar options ───────────────────────────────────────────────

    /// Snaps drawing points to the nearest OHLC of the bar under the cursor.
    case setMagnetMode(enabled: Bool)

    /// Keeps the active tool armed after each drawing, for placing a series.
    case setKeepDrawingMode(enabled: Bool)

    /// Announces new drawings via `.drawingCreated` for layout-wide replication.
    case setCopyDrawingsToAllCharts(enabled: Bool)

    /// Shows or hides the drawing toolbar at runtime.
    case setDrawingToolbarVisible(visible: Bool)

    // ── Serialisation ─────────────────────────────────────────────────────────

    /// The JSON string to pass to `window.ChartBridge.send(...)`.
    public var jsonString: String {
        let envelope: [String: Any]
        switch self {

        case let .initialize(theme, symbol, series, timeframe, duration, enableTrading,
                             showVolume, showUI, showDrawingTools, showBidAskLines, showAskLine, showBidLine, showActLogo,
                             showCandleCountdown, candleCountdownTimeframes, disableCountdownOnMobile,
                             maxSubPanes, mobileBarDivisor,
                             minInitialBars, maxLookbackMs,
                             momentumScrollEnabled, momentumDecay, momentumThreshold, momentumMaxVelocity,
                             targetCandleWidth, tickClosePriceSource, showLtpPrice, priceSourceSelector,
                             tradesThresholdForHorizontalLine, tradeDisplayFilter, positionRenderStyle,
                             hideLevelConfirmCancel, deselectActiveOnOutsideClick,
                             showTradeLevelsAlways, showPriceAxisCountdown,
                             tradeLevelButtonScale,
                             bracketLabelMode,
                             currencySymbol,
                             levelClusteringEnabled, clusterThresholdDistance,
                             tfcEnabled, showSettings, showFullscreenButton,
                             hideSymbolAndTick, hideOHLCV, showBottomBar,
                             aggregateFrom, canvasColorsJson, themeOverridesJson, labelsJson,
                             uiConfigJson, durationTimeframeMap, onSymbolClick, onAskAiClick, timezone,
                             headerLayout, enableMultipleLayouts, enableSnapshot, hideHeader,
                             initialCompares, maxCompares, layoutSync, instrument, account,
                             enableForecasting, enableCrossHairHeader, crosshairEnabled,
                             orderLineTimeDrag, orderLineDragSnap, orderLineAnchorPersistence,
                             orderLineDefaultAnchor, revealNewBrackets, headerFeatures,
                             seriesOptionsJson, cursorMode, valueTooltip, enableCursorModes,
                             enableIconTools, enableChartSettings, statusLineJson,
                             scalesJson, canvasJson, barColorSource,
                             enableScaleControls, priceScaleMode, autoScale, enableSidePanels,
                             magnetMode, keepDrawingMode, copyDrawingsToAllCharts, enableReplay):
            var payload: [String: Any] = ["theme": theme]
            if let symbol { payload["symbol"] = symbol }
            if let instrument { payload["instrument"] = instrument.toDictionary() }
            if let account { payload["account"] = account.toDictionary() }
            if let enableForecasting { payload["enableForecasting"] = enableForecasting }
            if let series { payload["series"] = series }
            if let timeframe { payload["timeframe"] = timeframe }
            if let duration { payload["duration"] = duration }
            if enableTrading {
                payload["enableTrading"] = true
            }
            if let showVolume { payload["showVolume"] = showVolume }
            if let showUI { payload["showUI"] = showUI }
            if let showDrawingTools { payload["showDrawingTools"] = showDrawingTools }
            if let showBidAskLines { payload["showBidAskLines"] = showBidAskLines }
            if let showAskLine { payload["showAskLine"] = showAskLine }
            if let showBidLine { payload["showBidLine"] = showBidLine }
            if let showActLogo { payload["showActLogo"] = showActLogo }
            if let showCandleCountdown { payload["showCandleCountdown"] = showCandleCountdown }
            if let candleCountdownTimeframes { payload["candleCountdownTimeframes"] = candleCountdownTimeframes }
            if let disableCountdownOnMobile { payload["disableCountdownOnMobile"] = disableCountdownOnMobile }
            if let maxSubPanes { payload["maxSubPanes"] = maxSubPanes }
            if let mobileBarDivisor { payload["mobileBarDivisor"] = mobileBarDivisor }
            if let minInitialBars { payload["minInitialBars"] = minInitialBars }
            if let maxLookbackMs { payload["maxLookbackMs"] = maxLookbackMs }
            if let momentumScrollEnabled { payload["momentumScrollEnabled"] = momentumScrollEnabled }
            if let momentumDecay { payload["momentumDecay"] = momentumDecay }
            if let momentumThreshold { payload["momentumThreshold"] = momentumThreshold }
            if let momentumMaxVelocity { payload["momentumMaxVelocity"] = momentumMaxVelocity }
            if let targetCandleWidth { payload["targetCandleWidth"] = targetCandleWidth }
            if let tickClosePriceSource { payload["tickClosePriceSource"] = tickClosePriceSource }
            if let showLtpPrice { payload["showLtpPrice"] = showLtpPrice }
            if let priceSourceSelector { payload["priceSourceSelector"] = priceSourceSelector }
            if let tradesThresholdForHorizontalLine { payload["tradesThresholdForHorizontalLine"] = tradesThresholdForHorizontalLine }
            if let tradeDisplayFilter { payload["tradeDisplayFilter"] = tradeDisplayFilter }
            if let positionRenderStyle { payload["positionRenderStyle"] = positionRenderStyle }
            if let hideLevelConfirmCancel { payload["hideLevelConfirmCancel"] = hideLevelConfirmCancel }
            if let deselectActiveOnOutsideClick { payload["deselectActiveOnOutsideClick"] = deselectActiveOnOutsideClick }
            if let showTradeLevelsAlways { payload["showTradeLevelsAlways"] = showTradeLevelsAlways }
            if let showPriceAxisCountdown { payload["showPriceAxisCountdown"] = showPriceAxisCountdown }
            if let tradeLevelButtonScale { payload["tradeLevelButtonScale"] = tradeLevelButtonScale }
            if let bracketLabelMode { payload["bracketLabelMode"] = bracketLabelMode }
            if let currencySymbol { payload["currencySymbol"] = currencySymbol }
            if let levelClusteringEnabled { payload["levelClusteringEnabled"] = levelClusteringEnabled }
            if let clusterThresholdDistance { payload["clusterThresholdDistance"] = clusterThresholdDistance }
            if let tfcEnabled { payload["tfcEnabled"] = tfcEnabled }
            if let showSettings { payload["showSettings"] = showSettings }
            payload["showFullscreenButton"] = showFullscreenButton
            if let hideSymbolAndTick { payload["hideSymbolAndTick"] = hideSymbolAndTick }
            if let hideOHLCV { payload["hideOHLCV"] = hideOHLCV }
            if let showBottomBar { payload["showBottomBar"] = showBottomBar }
            if let aggregateFrom { payload["aggregateFrom"] = aggregateFrom }
            if let durationTimeframeMap { payload["durationTimeframeMap"] = durationTimeframeMap }
            if let onSymbolClick, onSymbolClick { payload["onSymbolClick"] = true }
            if let onAskAiClick, onAskAiClick { payload["onAskAiClick"] = true }
            if let timezone { payload["timezone"] = timezone }
            if let headerLayout { payload["headerLayout"] = headerLayout }
            if let enableMultipleLayouts { payload["enableMultipleLayouts"] = enableMultipleLayouts }
            if let enableSnapshot { payload["enableSnapshot"] = enableSnapshot }
            if let hideHeader { payload["hideHeader"] = hideHeader }
            if let initialCompares { payload["initialCompares"] = initialCompares }
            if let maxCompares { payload["maxCompares"] = maxCompares }
            if let layoutSync { payload["layoutSync"] = layoutSync.jsonObject }
            if let enableCrossHairHeader { payload["enableCrossHairHeader"] = enableCrossHairHeader }
            if let crosshairEnabled { payload["crosshairEnabled"] = crosshairEnabled }
            if let orderLineTimeDrag { payload["orderLineTimeDrag"] = orderLineTimeDrag }
            if let orderLineDragSnap { payload["orderLineDragSnap"] = orderLineDragSnap }
            if let orderLineAnchorPersistence { payload["orderLineAnchorPersistence"] = orderLineAnchorPersistence }
            if let orderLineDefaultAnchor { payload["orderLineDefaultAnchor"] = orderLineDefaultAnchor }
            if let revealNewBrackets { payload["revealNewBrackets"] = revealNewBrackets }
            headerFeatures?.merge(into: &payload)
            if let seriesOptionsJson,
               let data = seriesOptionsJson.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                payload["seriesOptions"] = obj
            }
            if let cursorMode { payload["cursorMode"] = cursorMode }
            if let valueTooltip { payload["valueTooltip"] = valueTooltip }
            if let enableCursorModes { payload["enableCursorModes"] = enableCursorModes }
            if let enableIconTools { payload["enableIconTools"] = enableIconTools }
            if let enableChartSettings { payload["enableChartSettings"] = enableChartSettings }
            if let barColorSource { payload["barColorSource"] = barColorSource }
            if let enableScaleControls { payload["enableScaleControls"] = enableScaleControls }
            if let priceScaleMode { payload["priceScaleMode"] = priceScaleMode }
            if let autoScale { payload["autoScale"] = autoScale }
            if let enableSidePanels { payload["enableSidePanels"] = enableSidePanels }
            if let magnetMode { payload["magnetMode"] = magnetMode }
            if let keepDrawingMode { payload["keepDrawingMode"] = keepDrawingMode }
            if let copyDrawingsToAllCharts { payload["copyDrawingsToAllCharts"] = copyDrawingsToAllCharts }
            if let enableReplay { payload["enableReplay"] = enableReplay }
            func embedJson(_ key: String, _ json: String?) {
                guard let json,
                      let data = json.data(using: .utf8),
                      let obj = try? JSONSerialization.jsonObject(with: data)
                else { return }
                payload[key] = obj
            }
            embedJson("canvasColors", canvasColorsJson)
            embedJson("themeOverrides", themeOverridesJson)
            embedJson("labels", labelsJson)
            embedJson("uiConfig", uiConfigJson)
            embedJson("statusLine", statusLineJson)
            embedJson("scales", scalesJson)
            embedJson("canvas", canvasJson)
            envelope = ["type": "init", "payload": payload]

        case let .loadData(bars, fitAll):
            let barsArray: [[String: Any]] = bars.map { bar in
                ["open": bar.open, "high": bar.high, "low": bar.low,
                 "close": bar.close, "volume": bar.volume, "time": bar.time]
            }
            envelope = ["type": "loadData", "payload": ["bars": barsArray, "fitAll": fitAll]]

        case let .pushTick(bid, ask, timestamp, ltp, ltpv):
            var tickPayload: [String: Any] = ["B": bid, "A": ask, "T": timestamp]
            if let ltp { tickPayload["LTP"] = ltp }
            if let ltpv { tickPayload["LTPV"] = ltpv }
            envelope = ["type": "pushTick", "payload": tickPayload]

        case let .setShowLtpPrice(show):
            var showPayload: [String: Any] = [:]
            if let show { showPayload["show"] = show }
            envelope = ["type": "setShowLtpPrice", "payload": showPayload]

        case let .setTickClosePriceSource(source):
            envelope = ["type": "setTickClosePriceSource", "payload": ["source": source]]

        case let .setTheme(theme):
            envelope = ["type": "setTheme", "payload": ["theme": theme]]

        case let .setTimezone(tz):
            envelope = ["type": "setTimezone", "payload": ["timezone": tz]]

        case let .setLayoutSync(sync):
            envelope = ["type": "setLayoutSync", "payload": sync.jsonObject]
        case let .setCrosshairEnabled(enabled):
            envelope = ["type": "setCrosshairEnabled", "payload": ["enabled": enabled]]

        case let .setSeries(series):
            envelope = ["type": "setSeries", "payload": ["series": series]]

        case let .setTimeframe(timeframe):
            envelope = ["type": "setTimeframe", "payload": ["timeframe": timeframe]]

        case let .setDuration(duration, timeframe):
            var payload: [String: Any] = ["duration": duration]
            if let timeframe { payload["timeframe"] = timeframe }
            envelope = ["type": "setDuration", "payload": payload]

        case let .setBracketLabelMode(mode, currencySymbol):
            var payload: [String: Any] = ["mode": mode]
            if let currencySymbol { payload["currencySymbol"] = currencySymbol }
            envelope = ["type": "setBracketLabelMode", "payload": payload]

        case let .setSymbol(symbol):
            envelope = ["type": "setSymbol", "payload": ["symbol": symbol]]

        case let .setInstrument(instrument):
            var payload: [String: Any] = [:]
            if let instrument { payload["instrument"] = instrument.toDictionary() }
            envelope = ["type": "setInstrument", "payload": payload]

        case let .setAccount(account):
            var payload: [String: Any] = [:]
            if let account { payload["account"] = account.toDictionary() }
            envelope = ["type": "setAccount", "payload": payload]

        case let .addIndicator(name, params):
            var payload: [String: Any] = ["shortName": name]
            if let params { payload["params"] = params }
            envelope = ["type": "addIndicator", "payload": payload]

        case let .removeIndicator(name):
            envelope = ["type": "removeIndicator", "payload": ["name": name]]

        case let .setDrawingTool(tool):
            let toolValue: Any = tool ?? NSNull()
            envelope = ["type": "setDrawingTool", "payload": ["tool": toolValue]]

        case .clearAllDrawings:
            envelope = ["type": "clearAllDrawings", "payload": [:]]

        case let .setStatusLineSettings(json):
            guard
                let data = json.data(using: .utf8),
                let obj = try? JSONSerialization.jsonObject(with: data)
            else { return "{}" }
            envelope = ["type": "setStatusLineSettings", "payload": ["statusLine": obj]]

        case let .setScalesSettings(json):
            guard
                let data = json.data(using: .utf8),
                let obj = try? JSONSerialization.jsonObject(with: data)
            else { return "{}" }
            envelope = ["type": "setScalesSettings", "payload": ["scales": obj]]

        case let .setCanvasOptions(json):
            guard
                let data = json.data(using: .utf8),
                let obj = try? JSONSerialization.jsonObject(with: data)
            else { return "{}" }
            envelope = ["type": "setCanvasOptions", "payload": ["canvas": obj]]

        case let .setBarColorSource(source):
            envelope = ["type": "setBarColorSource", "payload": ["source": source]]

        case let .setPriceScaleMode(mode):
            envelope = ["type": "setPriceScaleMode", "payload": ["mode": mode]]

        case let .setAutoScale(enabled):
            envelope = ["type": "setAutoScale", "payload": ["enabled": enabled]]

        case let .goToDate(date):
            envelope = ["type": "goToDate", "payload": ["date": date]]
        case .openReplay:
            envelope = ["type": "openReplay", "payload": [:]]
        case .closeReplay:
            envelope = ["type": "closeReplay", "payload": [:]]
        case let .startReplay(time):
            envelope = ["type": "startReplay", "payload": ["time": time]]
        case .playReplay:
            envelope = ["type": "playReplay", "payload": [:]]
        case .pauseReplay:
            envelope = ["type": "pauseReplay", "payload": [:]]
        case .replayStepForward:
            envelope = ["type": "replayStepForward", "payload": [:]]
        case let .setReplaySpeed(barsPerSecond):
            envelope = ["type": "setReplaySpeed", "payload": ["barsPerSecond": barsPerSecond]]
        case .exitReplay:
            envelope = ["type": "exitReplay", "payload": [:]]

        case let .setSidePanelVisible(visible):
            envelope = ["type": "setSidePanelVisible", "payload": ["visible": visible]]

        case let .setSidePanelTab(tab):
            envelope = ["type": "setSidePanelTab", "payload": ["tab": tab]]

        case let .setDrawingVisible(id, visible):
            envelope = ["type": "setDrawingVisible", "payload": ["id": id, "visible": visible]]

        case let .setDrawingLocked(id, locked):
            envelope = ["type": "setDrawingLocked", "payload": ["id": id, "locked": locked]]

        case let .deleteDrawing(id):
            envelope = ["type": "deleteDrawing", "payload": ["id": id]]

        case let .selectDrawing(id):
            // NSNull, not omission: null means "clear the selection", where an
            // absent key would read as "leave it alone".
            envelope = ["type": "selectDrawing", "payload": ["id": id as Any? ?? NSNull()]]

        case let .setPricePrecision(digits):
            // NSNull, not omission: null means "go back to inferring it", and
            // an absent key would read as "leave it alone".
            envelope = ["type": "setPricePrecision",
                        "payload": ["digits": digits as Any? ?? NSNull()]]

        case let .addDrawing(drawingJson):
            guard
                let data = drawingJson.data(using: .utf8),
                let drawing = try? JSONSerialization.jsonObject(with: data)
            else { return "{}" }
            envelope = ["type": "addDrawing", "payload": ["drawing": drawing]]

        case .getState:
            envelope = ["type": "getState", "payload": [:]]

        case .getCatalog:
            envelope = ["type": "getCatalog", "payload": [:]]

        case let .setState(stateJson):
            guard
                let data = stateJson.data(using: .utf8),
                let stateObj = try? JSONSerialization.jsonObject(with: data)
            else { return "{}" }
            envelope = ["type": "setState", "payload": stateObj]

        case let .resolveDataRequest(requestId, bars):
            let barsArray: [[String: Any]] = bars.map { bar in
                ["open": bar.open, "high": bar.high, "low": bar.low,
                 "close": bar.close, "volume": bar.volume, "time": bar.time]
            }
            envelope = ["type": "resolveDataRequest", "payload": ["requestId": requestId, "bars": barsArray]]

        case let .setDebug(enabled):
            envelope = ["type": "setDebug", "payload": ["enabled": enabled]]

        case .destroy:
            envelope = ["type": "destroy", "payload": [:]]

        // ── Trade levels ──────────────────────────────────────────────────────
        case let .setLevels(levels, labelKey, priceKey, type, pnlKey, pnlTextKey):
            var payload: [String: Any] = [
                "levels": levels, "labelKey": labelKey, "priceKey": priceKey, "type": type,
            ]
            if let pnlKey { payload["pnlKey"] = pnlKey }
            if let pnlTextKey { payload["pnlTextKey"] = pnlTextKey }
            envelope = ["type": "setLevels", "payload": payload]

        case let .removeLevelByLabel(label):
            envelope = ["type": "removeLevelByLabel", "payload": ["label": label]]

        case let .updateLevelMainPrice(label, price):
            envelope = ["type": "updateLevelMainPrice", "payload": ["label": label, "price": price]]


        case let .updateLevelQty(label, qty):

            envelope = ["type": "updateLevelQty", "payload": ["label": label, "qty": qty]]

        case let .updateLevelBracket(label, bracketType, price):
            let priceValue: Any = price ?? NSNull()
            envelope = ["type": "updateLevelBracket",
                        "payload": ["label": label, "bracketType": bracketType.lowercased(), "price": priceValue]]

        case let .addLevelBracket(label, bracketType):
            envelope = ["type": "addLevelBracket",
                        "payload": ["label": label, "bracketType": bracketType.lowercased()]]

        case let .addBracket(bracketType, label):
            var payload: [String: Any] = ["bracketType": bracketType.lowercased()]
            if let label { payload["label"] = label }
            envelope = ["type": "addBracket", "payload": payload]

        case let .removeBracket(bracketType, label):
            var payload: [String: Any] = ["bracketType": bracketType.lowercased()]
            if let label { payload["label"] = label }
            envelope = ["type": "removeBracket", "payload": payload]

        case let .cancelLevelEdit(label):
            envelope = ["type": "cancelLevelEdit", "payload": ["label": label]]

        case let .selectLevel(label):
            let labelValue: Any = label ?? NSNull()
            envelope = ["type": "selectLevel", "payload": ["label": labelValue]]

        // ── Draft orders ──────────────────────────────────────────────────────
        case let .showDraftOrder(price, side, orderType):
            envelope = ["type": "showDraftOrder",
                        "payload": ["price": price, "side": side, "orderType": orderType]]

        case let .showMarketDraft(price, side):
            envelope = ["type": "showMarketDraft", "payload": ["price": price, "side": side]]

        case .clearDraftOrder:
            envelope = ["type": "clearDraftOrder", "payload": [:]]

        case .cancelCurrentEdit:
            envelope = ["type": "cancelCurrentEdit", "payload": [:]]

        case let .setDraftOrderLots(lots):
            envelope = ["type": "setDraftOrderLots", "payload": ["lots": lots]]

        case let .updateDraftOrderPrice(price):
            envelope = ["type": "updateDraftOrderPrice", "payload": ["price": price]]

        case let .updateDraftOrderBracket(bracketType, price):
            let priceValue: Any = price ?? NSNull()
            envelope = ["type": "updateDraftOrderBracket",
                        "payload": ["bracketType": bracketType.lowercased(), "price": priceValue]]

        case let .setDraftBracketPnl(bracketType, pnlText):
            let pnlValue: Any = pnlText ?? NSNull()
            envelope = ["type": "setDraftBracketPnl",
                        "payload": ["bracketType": bracketType.lowercased(), "pnlText": pnlValue]]

        // ── UI controls ───────────────────────────────────────────────────────
        case let .setVolume(show):
            envelope = ["type": "setVolume", "payload": ["show": show]]

        case let .setTfcActive(enabled):
            envelope = ["type": "setTfcActive", "payload": ["enabled": enabled]]

        case let .setIsins(isins):
            envelope = ["type": "setIsins", "payload": ["isins": isins]]

        case .resetView:
            envelope = ["type": "resetView", "payload": [:]]

        case .resetData:
            envelope = ["type": "resetData", "payload": [:]]

        case let .setLoading(loading):
            envelope = ["type": "setLoading", "payload": ["loading": loading]]

        case let .setThemeOverrides(overridesJson):
            var payload: [String: Any] = [:]
            if let jsonData = overridesJson.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: jsonData) {
                payload["overrides"] = parsed
            }
            envelope = ["type": "setThemeOverrides", "payload": payload]

        case let .setCanvasColors(colorsJson):
            var payload: [String: Any] = ["colors": NSNull()]
            if let colorsJson,
               let jsonData = colorsJson.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: jsonData) {
                payload["colors"] = parsed
            }
            envelope = ["type": "setCanvasColors", "payload": payload]

        case let .correctBar(barTime, bar):
            let barObj: [String: Any] = [
                "open": bar.open, "high": bar.high, "low": bar.low,
                "close": bar.close, "volume": bar.volume, "time": bar.time,
            ]
            envelope = ["type": "correctBar", "payload": ["barTime": barTime, "bar": barObj]]

        case .dismissAllUI:
            envelope = ["type": "dismissAllUI", "payload": [:]]

        // ── Compare ───────────────────────────────────────────────────────────
        case let .addCompare(symbol):
            envelope = ["type": "addCompare", "payload": ["symbol": symbol]]

        case let .removeCompare(symbol):
            envelope = ["type": "removeCompare", "payload": ["symbol": symbol]]

        case .clearCompares:
            envelope = ["type": "clearCompares", "payload": [:]]

        case let .resolveCompareDataRequest(requestId, bars):
            let barsArray: [[String: Any]] = bars.map { bar in
                ["open": bar.open, "high": bar.high, "low": bar.low,
                 "close": bar.close, "volume": bar.volume, "time": bar.time]
            }
            envelope = ["type": "resolveCompareDataRequest",
                        "payload": ["requestId": requestId, "bars": barsArray]]

        case let .requestSnapshot(action):
            envelope = ["type": "requestSnapshot", "payload": ["action": action]]

        case let .setIndicatorTemplates(templatesJson):
            envelope = ["type": "setIndicatorTemplates",
                        "payload": ["templates": Self.jsonArray(templatesJson)]]

        case let .captureIndicatorTemplate(name):
            envelope = ["type": "captureIndicatorTemplate", "payload": ["name": name]]

        case let .applyIndicatorTemplate(id):
            envelope = ["type": "applyIndicatorTemplate", "payload": ["id": id]]

        case let .deleteIndicatorTemplate(id):
            envelope = ["type": "deleteIndicatorTemplate", "payload": ["id": id]]

        case let .setSettingsTemplates(templatesJson):
            envelope = ["type": "setSettingsTemplates",
                        "payload": ["templates": Self.jsonArray(templatesJson)]]

        case let .captureSettingsTemplate(name):
            envelope = ["type": "captureSettingsTemplate", "payload": ["name": name]]

        case let .applySettingsTemplate(id):
            envelope = ["type": "applySettingsTemplate", "payload": ["id": id]]

        case let .deleteSettingsTemplate(id):
            envelope = ["type": "deleteSettingsTemplate", "payload": ["id": id]]

        case let .applyChartSettings(settingsJson):
            guard
                let data = settingsJson.data(using: .utf8),
                let obj = try? JSONSerialization.jsonObject(with: data)
            else { return "{}" }
            envelope = ["type": "applyChartSettings", "payload": ["settings": obj]]

        case let .setSavedLayouts(layoutsJson):
            envelope = ["type": "setSavedLayouts",
                        "payload": ["layouts": Self.jsonArray(layoutsJson)]]

        case let .captureSavedLayout(name, paneId):
            envelope = ["type": "captureSavedLayout",
                        "payload": ["name": name, "paneId": paneId]]

        case let .applySavedLayout(id, paneId):
            envelope = ["type": "applySavedLayout", "payload": ["id": id, "paneId": paneId]]

        case let .deleteSavedLayout(id):
            envelope = ["type": "deleteSavedLayout", "payload": ["id": id]]

        case let .setLayoutPreset(presetId):
            envelope = ["type": "setLayoutPreset", "payload": ["presetId": presetId]]

        case .openQuickSearch:
            envelope = ["type": "openQuickSearch", "payload": [:]]

        case .closeQuickSearch:
            envelope = ["type": "closeQuickSearch", "payload": [:]]

        case let .setSeriesOptions(optionsJson):
            guard
                let data = optionsJson.data(using: .utf8),
                let obj = try? JSONSerialization.jsonObject(with: data)
            else { return "{}" }
            envelope = ["type": "setSeriesOptions", "payload": ["options": obj]]

        case let .setCursorMode(mode):
            envelope = ["type": "setCursorMode", "payload": ["mode": mode]]

        case let .setMagnetMode(enabled):
            envelope = ["type": "setMagnetMode", "payload": ["enabled": enabled]]

        case let .setKeepDrawingMode(enabled):
            envelope = ["type": "setKeepDrawingMode", "payload": ["enabled": enabled]]

        case let .setCopyDrawingsToAllCharts(enabled):
            envelope = ["type": "setCopyDrawingsToAllCharts", "payload": ["enabled": enabled]]

        case let .setDrawingToolbarVisible(visible):
            envelope = ["type": "setDrawingToolbarVisible", "payload": ["visible": visible]]
        }

        guard
            let data = try? JSONSerialization.data(withJSONObject: envelope),
            let json = String(data: data, encoding: .utf8)
        else { return "{}" }
        return json
    }

    /// Parses a JSON array string, yielding an empty array when it is malformed.
    ///
    /// Template and layout lists cross the bridge as opaque JSON — the native side
    /// stores what the chart handed it and sends it back verbatim, so neither
    /// Kotlin nor Swift has to mirror a type that only the chart interprets.
    /// A corrupt stored list must degrade to "no saved items", never to a dropped
    /// command or a crash.
    private static func jsonArray(_ json: String) -> [Any] {
        guard
            let data = json.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [Any]
        else { return [] }
        return obj
    }
}
