# charts-ios

iOS Swift framework that embeds the ActTrader financial charting library inside a `WKWebView`.

## Requirements

- iOS 14.0+
- Swift 5.7+
- Xcode 15+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
.package(url: "https://github.com/acttrader/charts-ios.git", from: "0.1.0")
```

Or in Xcode: **File → Add Package Dependencies…** and enter the repo URL.

### CocoaPods

```ruby
pod 'ActtraderCharts', '~> 0.1'
```

### Beta releases

Pre-release builds are tagged as `vX.Y.Z-beta.N`. Both CocoaPods (`~>`) and SPM (`from:`) **exclude prereleases by default** — you must pin exactly to opt in.

**SPM:**

```swift
.package(url: "https://github.com/acttrader/charts-ios.git", exact: "1.1.0-beta.1")
```

**CocoaPods:**

```ruby
pod 'ActtraderCharts', '1.1.0-beta.1'
```

Existing dependency declarations using `from:` or `~>` continue to resolve only to stable releases.

## Usage

```swift
import ActtraderCharts

let chart = ActtraderChartsView(theme: "dark", symbol: "EURUSD")

chart.onReady = { [weak chart] in
    chart?.loadData(bars, fitAll: true)
}

chart.onCrosshair = { event in
    if case let .crosshair(time, open, high, low, close, volume, _, _) = event {
        print("Hovered bar — O:\(open) H:\(high) L:\(low) C:\(close)")
    }
}

chart.onError = { event in
    if case let .error(message, _) = event {
        print("Chart error:", message)
    }
}

view.addSubview(chart)
chart.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    chart.topAnchor.constraint(equalTo: view.topAnchor),
    chart.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    chart.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    chart.trailingAnchor.constraint(equalTo: view.trailingAnchor),
])
```

### SL/TP amounts instead of prices

By default the SL/TP pills read `SL 4159.00`. Pass `bracketLabelMode: "amount"`
and they read `SL -$290.80` — what the position gains or loses if that bracket
is hit, with the currency symbol in front.

The chart has no access to contract specs, so each level supplies what the maths
needs. These go in the level dictionaries you already pass to `setLevels`:

| key | meaning |
|---|---|
| `contractSize` | Units per lot — `100` for XAUUSD, `100000` for most FX pairs |
| `valuePerPoint` | Account-currency value of one price unit, folding in any quote → account conversion. Default `1` |
| `currencySymbol` | Per-level override of the chart-wide `currencySymbol` |

```swift
let chart = ActtraderChartsView(theme: "dark", bracketLabelMode: "amount", currencySymbol: "$")

chart.setLevels([[
    "label": "POS-1", "price": 4173.54, "side": "buy", "lots": 0.20,
    "stopLossPrice": 4159.00, "takeProfitPrice": 4183.00,
    "contractSize": 100, "valuePerPoint": 1,
]], labelKey: "label", priceKey: "price", type: "position")
// pills render: SL -$290.80   TP +$189.20
```

A trailing stop is still a working stop, so keep passing its price as `stopLossPrice` and add `"stopLossTrailing": true`: the line renders with a **TSL** pill and is read-only on the chart (no drag handle, no ×) — the trail is edited in pips from your own order form.

```swift
["label": "POS-2", "price": 1.0850, "side": "buy", "lots": 1.0,
 "stopLossPrice": 1.0800, "stopLossTrailing": true]
```

`amount = (bracket − entry) × direction × lots × contractSize × valuePerPoint`

A level missing `lots` or `contractSize` keeps showing its price, so a partial
rollout degrades level by level rather than rendering `NaN`. Switch at runtime
with `setBracketLabelMode("amount")`.

### Pre-warming (optional, recommended)

Call `prewarm()` before the chart screen appears to absorb the WKWebView process startup cost (200–400 ms):

```swift
// AppDelegate or SceneDelegate
ActtraderChartsView.prewarm()
```

## API

### Constructor parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `theme` | `String` | `"dark"` | `"dark"` or `"light"` |
| `symbol` | `String?` | `nil` | Symbol name shown in the top bar (e.g. `"EURUSD"`) |
| `instrument` | `InstrumentSpec?` | `nil` | Contract specs for `symbol` — see [Instrument specs](#instrument-specs) |
| `account` | `AccountSpec?` | `nil` | Account equity and per-trade risk — see [Position tools](#position-tools) |
| `enableForecasting` | `Bool?` | `nil` (`false`) | The reworked drawing tools, as one switch — see [Feature flags](#feature-flags) |
| `series` | `String?` | `nil` | Initial chart type (e.g. `"candlestick"`, `"line"`, `"area"`, `"ohlc"`, `"hollow_candle"`) |
| `timeframe` | `String?` | `nil` | Initial timeframe (e.g. `"1m"`, `"5m"`, `"1h"`, `"1D"`) |
| `duration` | `String?` | `nil` | Initial duration button (e.g. `"1D"`, `"1M"`, `"1Y"`, `"All"`) |
| `showVolume` | `Bool?` | `nil` | Show volume bars |
| `showUI` | `Bool?` | `nil` | Show top / bottom bars. When `false`, the loading overlay is also suppressed |
| `showDrawingTools` | `Bool?` | `nil` | Show drawing toolbar and pencil button |
| `showBidAskLines` | `Bool?` | `nil` | **Deprecated** — show bid and ask as dashed lines during a live stream. Prefer `showAskLine` / `showBidLine` |
| `showAskLine` | `Bool?` | `nil` | Show the Ask price line independently. `nil`: legacy `showBidAskLines` behavior |
| `showBidLine` | `Bool?` | `nil` | Show the Bid price line independently. `nil`: legacy `showBidAskLines` behavior |
| `showActLogo` | `Bool?` | `nil` | Show ACT watermark logo |
| `showCandleCountdown` | `Bool?` | `nil` | Show countdown timer on the live candle (time axis) |
| `candleCountdownTimeframes` | `[String]?` / `"all"` | `nil` | Timeframes where the countdown appears |
| `showPriceAxisCountdown` | `Bool?` | `nil` (`false`) | Show candle countdown on the right price axis just below the live price tag. Honours `candleCountdownTimeframes`. Toggleable from the in-chart Settings dialog. |
| `disableCountdownOnMobile` | `Bool?` | `nil` | Hide the countdown on small screens |
| `enableTrading` | `Bool` | `false` | Show the floating buy/sell order button |
| `minLots` | `Int?` | `nil` | Minimum lot size for order entry (requires `enableTrading`) |
| `maxSubPanes` | `Int?` | `nil` | Max simultaneous oscillator sub-panes |
| `prefetchThreshold` | `Int?` | `nil` | Bars from start of data at which historical fetch triggers (min 20, default 80) |
| `mobileBarDivisor` | `Int?` | `nil` | Divide desktop bar count on touch (`2`, `3`, or `4`) |
| `minInitialBars` | `Int?` | `nil` | If `onDataRequest` returns fewer bars, the fetch window auto-widens and retries. Default: `10` |
| `maxLookbackMs` | `Int64?` | `nil` | Hard ceiling (ms) for auto-widening retries. Default: 365 days |
| `momentumScrollEnabled` | `Bool?` | `nil` | Enable momentum (kinetic) scrolling — chart coasts after a fast flick. Default: `true`. Note: momentum runs in the JS layer, not `UIScrollView` |
| `momentumDecay` | `Double?` | `nil` | Per-frame velocity decay, normalised to 60 fps. Clamped `[0.80, 0.99]`. Default: `0.95` |
| `momentumThreshold` | `Double?` | `nil` | Min release velocity (px/ms) to launch momentum. Default: `0.3` |
| `momentumMaxVelocity` | `Double?` | `nil` | Max launch velocity (px/ms). Default: `6.0` |
| `targetCandleWidth` | `Double?` | `nil` | Target px width per candle for auto-calculating initial bar count |
| `tickClosePriceSource` | `String?` | `nil` | `"bid"` (default), `"ask"`, or `"ltp"` for live tick close/high/low. `"ltp"` builds candles from the last traded price (exchange/dealing feeds); ticks without a valid LTP fall back to the bid |
| `showLtpPrice` | `Bool?` | `nil` | Show the LTP marker (dashed price line + axis tag). `nil`: shown only in `"ltp"` mode. `true`: always shown when the feed supplies an LTP. `false`: hidden even in `"ltp"` mode |
| `priceSourceSelector` | `[String]?` | `nil` | Show a price-source dropdown in the chart header listing these sources, e.g. `["ltp", "bid"]` (dealing feeds). A user pick switches the live candle source and fires `onPriceSourceChange`. Hidden when `nil`/empty |
| `tradesThresholdForHorizontalLine` | `Int?` | `nil` | Level count above which render auto-switches to dot mode |
| `tradeDisplayFilter` | `String?` | `nil` | Which TFC levels are visible: `"all"` · `"positions"` · `"orders"` · `"none"` |
| `positionRenderStyle` | `String?` | `nil` | Force position render style: `"line"` or `"dot"` |
| `hideLevelConfirmCancel` | `Bool?` | `nil` | Hide on-canvas ✓/✗ confirm/cancel buttons for TFC level edits |
| `deselectActiveOnOutsideClick` | `Bool?` | `nil` (`false`) | When `true`, clicking/tapping outside a selected trade level dismisses it (reverts pending edits). Default `false` preserves the active level across outside clicks so incidental taps (price-axis resize, taps outside the QTY input) don't drop an in-progress edit. Set `true` to restore the legacy outside-click-to-cancel behavior |
| `showTradeLevelsAlways` | `Bool?` | `true` | Always render SL/TP bracket lines + price pills, even when the parent level isn't hovered or selected. Close (×) buttons stay hover-only. Pass `false` to hide them until hover/selection. Toggleable from the in-chart Settings dialog (Trading tab). |
| `showTradeLevelsAlways` | `Bool?` | `true` | Always render SL/TP bracket lines + price pills, even when the parent level isn't hovered or selected. Close (×) buttons stay hover-only. Pass `false` to show them only on hover/selection. Toggleable from the in-chart Settings dialog (Trading tab). |
| `tradeLevelButtonScale` | `Double?` | `nil` (`1.0`) | Multiplier for trade-level Confirm/Cancel/Edit/Close button radii and gaps. Scales visuals **and** hit/drag areas together — raise it on touch devices for easier tapping. Clamped to `[1.0, 3.0]` |
| `bracketLabelMode` | `String?` | `nil` (`"price"`) | `"amount"` makes SL/TP pills show the money at the bracket instead of its price — see below |
| `currencySymbol` | `String?` | `nil` (`"$"`) | Symbol for SL/TP amounts when `bracketLabelMode` is `"amount"` |
| `levelClusteringEnabled` | `Bool?` | `true` | Enable trade-level fan-out clustering; overlapping levels group into expandable badges |
| `clusterThresholdDistance` | `Int?` | `20` | Pixel proximity threshold for clustering (only when `levelClusteringEnabled` is `true`) |
| `hideQtyButton` | `Bool?` | `nil` | Hide the floating Qty input overlay on draft orders |
| `showQuantityField` | `Bool?` | `nil` (`false`) | Render an editable QTY pill at the left of the draft order info box. Tapping opens a flyout input to edit the quantity before submitting |
| `quantityFieldMinLots` | `Double?` | `nil` (`1.0`) | Minimum lot size, step size, and initial quantity for the QTY flyout (only used when `showQuantityField = true`) |
| `quantityFieldMaxLots` | `Double?` | `nil` (`100.0`) | Maximum lot size for the QTY flyout (only used when `showQuantityField = true`) |
| `tfcEnabled` | `Bool?` | `nil` (`true`) | Enable the TFC toggle button in the top bar. When `false`, TFC is completely disabled — the toggle button is hidden and all trade levels, draft orders, and the floating trade button are suppressed |
| `showSettings` | `Bool?` | `nil` | Show the settings gear button in the top bar; set to `false` to hide it entirely |
| `showFullscreenButton` | `Bool` | `false` | Show the fullscreen toggle button in the top bar. Hidden by default on mobile; set to `true` to surface it |
| `hideSymbolAndTick` | `Bool?` | `nil` | Hide the symbol name and tick-activity (streaming) dot in the top-left overlay. Does **not** affect the OHLC(V) strip — use `hideOHLCV` for that |
| `hideOHLCV` | `Bool?` | `nil` | Hide the OHLC(V) data strip (`O: H: L: C: V:`) in the top-left overlay. Independent of `hideSymbolAndTick` — set both to `true` to hide the entire overlay |
| `showBottomBar` | `Bool?` | `nil` | Show the bottom duration-selector bar (hidden by default) |
| `hideHeader` | `Bool?` | `nil` (`false`) | Hide the chart header entirely (whichever `headerLayout` variant would have rendered). Bottom bar, drawing tools, and on-canvas overlays remain on their own flags. Drive the chart from native UI via `setTimeframe(...)`, `setSeries(...)`, `addIndicatorByName(...)`, `removeIndicator(...)` |
| `enableCrossHairHeader` | `Bool?` | `nil` (`false`) | Crosshair on/off switch in the chart header. The crosshair starts on, so the icon is tinted; tapping it hides the crosshair (and the floating trade button riding on it) and drops the icon to its plain state, the next tap brings both back. Fires `onCrosshairToggle` — see [Header crosshair switch](#header-crosshair-switch) |
| `crosshairEnabled` | `Bool?` | `nil` (`true`) | Draw the crosshair at all. `false` hides it and the floating trade button until `setCrosshairEnabled(true)` — use it to restore a persisted `onCrosshairToggle` choice |
| `orderLineTimeDrag` | `Bool?` | `nil` (`false`) | Horizontal (time-axis) order-line dragging for levels flagged `"timeDraggable": true` — open positions **and pending orders**. Broker-gated; see [Horizontal order-line dragging](#horizontal-time-axis-order-line-dragging) |
| `orderLineDragSnap` | `Bool?` | `nil` (`true`) | Snap a horizontally dragged badge to the nearest candle on release |
| `orderLineAnchorPersistence` | `Bool?` | `nil` (`true`) | Remember dropped badge positions in the WebView's `localStorage` (keyed by level label) across reloads |
| `orderLineDefaultAnchor` | `String?` | `nil` (`"timestamp"`) | Where an un-dragged `timeDraggable` badge sits: `"timestamp"` (over the candle at the level's `timestamp`) or `"center"` (mid-chart) |
| `revealNewBrackets` | `Bool?` | `nil` (`false`) | When a level gains a new SL/TP (via `setLevels` or `updateLevelBracket`) whose price is outside the visible range, widen the price axis so the new line comes into view with the candles already on screen |
| `timezone` | `String?` | `nil` (`"UTC"`) | IANA timezone string for time-axis and crosshair labels. `"UTC"` (default), `"local"` (device timezone), or any IANA string (`"America/New_York"`, `"Europe/London"`, etc.) |
| `uiConfigJson` | `String?` | `nil` | Per-component UI configuration overrides (font sizes, icon sizes, spacing) as a raw JSON string. See *Mobile icon sizing* below. |
| `themeOverrides` | `ThemeOverrides?` | `nil` | Typed per-theme color overrides. See *Theme overrides* below. |
| `initialCompares` | `[String]?` | `nil` | Compare symbols to add automatically on init. Each one fires `onCompareDataRequest` against the initial primary range — respond via `resolveCompareDataRequest` |
| `maxCompares` | `Int?` | `nil` (`8`) | Maximum concurrent compare symbols. Adding beyond fires `onCompareError` |
| `initialState` | `String?` | `nil` | Raw JSON from a prior `onStateSnapshot` to restore atomically at init (timeframe, series, indicators, drawings). See *Restoring state without a flash* below. |

### Restoring state without a flash

When you need to restore a previously saved chart state (e.g. user re-opens the chart screen), pass the snapshot JSON as `initialState` instead of calling `setState()` inside `onReady`:

```swift
// ✅ Correct — init + setState are queued together and flushed atomically;
//    the engine never renders a frame with the default "1D" timeframe.
let chart = ActtraderChartsView(
    theme: "dark",
    symbol: "EURUSD",
    initialState: savedStateJson
)

// ❌ Avoid — setState fires after the chart has already rendered once with "1D".
let chart = ActtraderChartsView(theme: "dark", symbol: "EURUSD")
chart.onReady = { chart.setState(savedStateJson) }
```

For simple cases where you only need to set a specific timeframe (without full state restore), use the `timeframe` constructor parameter directly — no `initialState` required.

### Theme overrides

Use `themeOverrides` (in the constructor) or `setThemeOverrides(_:)` to selectively override colors for each theme mode. Only the keys you supply are merged on top of the built-in dark/light themes.

> **Canvas vs. chrome.** `themeOverrides` styles the whole chart — canvas *and* chrome
> (top/bottom/left bars, dialogs, popovers). The colours a user picks in the in-chart
> **Chart Settings** dialog are scoped to the canvas: `background`, `grid`, `axisText`,
> `axisBorder` and `crosshair` repaint the canvas only, so a custom chart background no
> longer repaints the toolbars and a custom axis-border colour no longer lands on the
> settings dialog's own frame. Candle and volume picks still apply everywhere so legends
> and indicator pills track them. Where a user picks a custom background but no explicit
> axis-text colour, the symbol name and OHLC strip switch to pure white or pure black —
> whichever contrasts with that background.


```swift
// At init time
let chart = ActtraderChartsView(
    theme: "dark",
    symbol: "EURUSD",
    themeOverrides: ThemeOverrides(
        dark: ChartThemeOverride(
            background: "#0a0a0a",
            candle: CandleColors(up: "#00e676", down: "#ff1744"),
            topBar: TopBarColors(btnColor: "#cccccc")
        )
    )
)

// Or update at runtime
chart.setThemeOverrides(ThemeOverrides(
    dark: ChartThemeOverride(background: "#111111"),
    light: ChartThemeOverride(background: "#fafafa")
))
```

All properties at every level are optional — only supply the ones you want to change. Available nested types: `TooltipColors`, `CandleColors`, `VolumeColors`, `UiColors`, `StreamColors`, `DrawingToolbarColors`, `TopBarColors`, `BottomBarColors`, `IndicatorOverlayColors`, `TradeLevelColors`, `TradePanelColors`.

> Raw JSON strings are still supported via `themeOverridesJson` / `setThemeOverrides(jsonString)` for backward compatibility.

#### Chart background: canvas only

`setThemeOverrides(ThemeOverrides(dark: ChartThemeOverride(background: …)))` recolours the **whole chart** by design — the theme's `background` token also paints the header, the bottom bar, the drawing toolbar and every popover. For a background that must stay inside the plot, use the canvas picks instead: `canvasColorsJson` in the constructor, or `setCanvasColors(_:)` at runtime. They are the same picks the in-chart Chart Settings dialog writes, so they are scoped to the plot and its axes and persisted in the state snapshot.

```swift
// In the constructor
let chart = ActtraderChartsView(canvasColorsJson: #"{"dark":{"background":"#ff00ff"},"light":{"background":"#ffffff"}}"#)

// At runtime — typed or raw JSON; nil clears the picks
chart.setCanvasColors(CanvasColors(dark: CanvasColorPicks(background: "#ff00ff", grid: "#5a005a")))
chart.setCanvasColors(nil)
```

### Fonts

The chart renders inside a `WKWebView`. The symbol name, O/H/L/C strip, and toolbar text
inherit the WebView document's `body` font. The bundled `chart.html` sets a system-font
stack (`'Inter', system-ui, -apple-system, …`), so these render in **San Francisco** — no
setup required.

> Fixed in `v1.1.0` (chart bundle from ActCharts): earlier beta bundles set no `body`
> font, so the symbol name and OHLC strip fell back to the WebView's default **serif**
> (Times). Updating to a build with the current `chart.html` resolves it — there are no
> Swift API changes.

### Mobile icon sizing

The chart automatically bumps top-bar icon buttons (settings, fullscreen, drawing toggle) and the floating trade ⊕ button to larger sizes when the container width drops below `uiConfig.drawingToolbar.mobileBreakpoint` (default `480px`). Defaults:

| Element | Desktop | Mobile |
|---------|---------|--------|
| Top-bar icon button container | 26px | 28px |
| Top-bar icon SVG | 14–15px | 16–17px |
| Trade ⊕ button container | 22px | 24px |
| Trade ⊕ icon SVG | 14px | 16px |

Override via `uiConfigJson`:

```swift
chart.initialize(
    theme: "dark",
    symbol: "AAPL",
    enableTrading: true,
    uiConfigJson: """
    {
      "topBar": {
        "mobileIconBtnSize": "30px",
        "mobileDrawBtnIconSize": "18px"
      },
      "tradeButton": {
        "mobileSize": 26,
        "mobileIconSize": 18
      }
    }
    """
)
```

### Commands

| Method | Description |
|---|---|
| `loadData(_ bars:, fitAll:)` | Replaces the full dataset |
| `pushTick(bid:ask:timestamp:ltp:ltpv:)` | Streams a live tick. `ltp`/`ltpv` (last traded price/volume) are optional — sent by exchange/dealing feeds and used when `tickClosePriceSource == "ltp"`, e.g. `chart.pushTick(bid: 1.2055, ask: 1.2057, timestamp: ts, ltp: 1.2056, ltpv: 120)` |
| `setShowLtpPrice(_:)` | Show/hide the LTP price marker at runtime; pass `nil` to restore the default (marker follows `tickClosePriceSource == "ltp"`) |
| `setTickClosePriceSource(_:)` | Switch which price drives live candle close/high/low at runtime (`"bid"`, `"ask"` or `"ltp"`); also syncs the header price-source dropdown when `priceSourceSelector` is enabled |
| `setTheme(_:)` | `"dark"` or `"light"` |
| `setSeries(_:)` | `"candlestick"`, `"line"`, `"area"`, `"ohlc"`, `"hollow_candle"` |
| `setTimeframe(_:)` | `"1m"` `"5m"` `"15m"` `"30m"` `"1h"` `"4h"` `"1D"` `"1W"` `"1M"` `"1Y"` |
| `setDuration(_:timeframe:)` | Select a duration (`"1D"` `"5D"` `"1M"` `"3M"` `"6M"` `"1Y"` `"5Y"` `"All"`) and refetch. The timeframe is paired from `durationTimeframeMap` unless given. The x-axis rescales from the new bars — no reinitialisation needed |
| `setBracketLabelMode(_:currencySymbol:)` | `"price"` (default), `"amount"`, or `"priceAndAmount"` — whether SL/TP pills show the bracket price, the money it is worth, or the price with the currency symbol plus the P/L while dragging |
| `setSymbol(_:)` | Updates the symbol name in the top bar |
| `setInstrument(_:)` | Contract specs used by the measurement tools — see [Instrument specs](#instrument-specs). Pair it with `setSymbol(_:)`; `nil` clears them |
| `setAccount(_:)` | Account equity and per-trade risk used to size the position tools — see [Position tools](#position-tools). Push it whenever equity moves |
| `addIndicator(_:params:)` | `"SMA"`, `"EMA"`, `"RSI"`, `"BB"`, etc. Parameterized studies add a **new instance** per call; observe `onIndicatorAdded` for its `instanceId` |
| `removeIndicator(_:)` | Remove a study — pass an `instanceId` (e.g. `"EMA#3"`) for one instance, or a short name (e.g. `"EMA"`) for all instances of that study |
| `setDrawingTool(_:)` | `"trend_line"`, `"horizontal_line"`, etc. — `nil` to deactivate |
| `clearAllDrawings()` | Removes all drawings |
| `getState()` | Fires `onStateSnapshot` asynchronously |
| `setState(_:)` | Restores from a prior `onStateSnapshot` JSON string |
| `resolveDataRequest(requestId:bars:)` | Resolves a pending `onDataRequest` with fetched bars |
| `setDebug(_:)` | Enable or disable verbose logging in the browser console |
| `destroy()` | Tears down the engine |
| **TFC — Trade Levels** | |
| `setLevels(_:labelKey:priceKey:type:pnlKey:pnlTextKey:)` | Replace all levels of a given type; pass `[]` to clear |
| `removeLevelByLabel(_:)` | Remove a single level by label |
| `updateLevelMainPrice(label:price:)` | Update the entry price of an existing level. Stages the edit in the chart's pending-edit buffer so it survives subsequent `setLevels` refreshes (e.g. per-tick PnL updates) until the server echoes the new price or `cancelLevelEdit` / `cancelCurrentEdit` is called. Call `cancelLevelEdit(label)` when your modify panel closes without submitting, otherwise the staged edit keeps overriding server state on the chart |
| `updateLevelQty(_:qty:)` | Update the quantity on an existing level's pill when your modify panel changes the size — stops the chart showing the broker's old lots while the modify is in flight. Staged like a chart-side qty edit: survives `setLevels` refreshes and is reverted by `cancelCurrentEdit()` |
| `updateLevelBracket(label:bracketType:price:)` | Update or remove a SL/TP bracket on an existing level; pass `nil` price to remove. Same staging semantics as `updateLevelMainPrice` |
| `addLevelBracket(label:bracketType:)` | Auto-place a SL or TP bracket at a default price offset; fires `onTradeLevelBracketActivated` with the computed price |
| `addBracket(bracketType:label:)` | Unified auto-price bracket placement — pass `label` for an existing order/position, omit it for the active draft order; fires `onTradeLevelBracketActivated` (`label` is `""` for drafts — check `label.isEmpty`) |
| `removeBracket(bracketType:label:)` | Unified bracket removal — pass `label` for an existing order/position, omit it for the active draft order |
| `cancelLevelEdit(_:)` | Cancel an in-progress level edit, reverting to last confirmed price |
| `selectLevel(_:)` | Programmatically highlight a level; pass `nil` to deselect all |
| | **Off-viewport indicators:** When a level's entry/SL/TP is outside the visible price range, a `▲ N` / `▼ N` pill appears near the chart's right edge. Tapping the pill smooth-scrolls the nearest off-screen marker to center. This is automatic — no configuration needed. |
| | **Trade level visuals:** Pending orders and ES/EL entry working orders render as **dashed** lines tinted by side (`pendingBuyLine` green / `pendingSellLine` red). True open positions render as **solid** lines — green/red when `pnl` is set, otherwise `positionLine` (purple/indigo). Each true open position shows a colored entry-price tag on the right-side price axis (same style as the Bid/Ask tag). |
| | **Brackets follow entry on drag:** dragging the entry line of a pending order, draft order, or an entry-editable open position translates any existing SL/TP brackets by the same price delta. The distance is whatever the user currently sees; if they manually adjust SL or TP, the new distance anchors subsequent entry drags. Missing brackets are not auto-created. On confirm, `onTradeLevelEdit` carries all translated fields together in one `changes` array; with `hideLevelConfirmCancel = true` the three changes arrive as a single atomic event. |
| | **Bracket pill auto-offset:** when an SL/TP price sits within about one pill-height of the entry price, the bracket's label pill is pushed vertically away from the entry pill and connected back to its real price line by a dashed leader. The horizontal bracket line stays at the true price; only the pill and its `×` button move, and drag/tap targets follow the displaced pill — so the bracket pill and entry pill never share a touch area. Works for both buy and sell orders, automatic (no configuration). |
| **TFC — Draft Orders** | |
| `showDraftOrder(price:side:orderType:)` | Show a draggable limit or stop draft order line |
| `showMarketDraft(price:side:)` | Show a non-draggable market-order preview line |
| `clearDraftOrder()` | Remove the active draft order |
| `cancelCurrentEdit()` | Cancel whatever is currently being edited or drafted (draft order or level edit); no-op when nothing is active |
| `setDraftOrderLots(_:)` | Update the lot quantity on the active draft order chip |
| `updateDraftOrderPrice(_:)` | Move the draft order price line to a new price |
| `updateDraftOrderBracket(bracketType:price:)` | Update or remove a SL/TP bracket on the draft order; pass `nil` to remove |
| `setDraftBracketPnl(bracketType:pnlText:)` | Display estimated P&L text next to the active bracket host's SL or TP line — a draft order while drafting, or the currently selected existing pending order / position while modifying; pass `nil` to clear |
| **UI / Utility** | |
| `setTfcActive(_:)` | Toggle TFC (Trade from Charts) on or off at runtime. Hides/shows all trade levels, draft orders, and the floating trade button. Fires `onTfcToggle` |
| `setVolume(_:)` | Show or hide the volume sub-pane |
| `setIsins(_:)` | Update the symbol list used by the ISIN picker |
| `setMinLots(_:)` | Update the minimum lot size in the trade popover |
| `resetView()` | Reset price and time axes to auto-fit. The built-in bottom-center reset button invokes this — it is hidden while the chart is at its default view and fades in only after the user pans, zooms, or price-scales |
| `resetData()` | Clear all bars, the live price line, any in-flight fetch, **all user drawings, and all trade/position levels** (including pending draft orders). Call before switching to a new symbol to prevent previous symbol state from bleeding in (see example below). For a same-symbol data refresh that should preserve drawings, call `loadData([])` directly instead |
| `setLoading(_:)` | Show or hide the loading overlay |
| `setTimezone(_:)` | Change display timezone at runtime — IANA string (`"America/New_York"`) or `"local"` |
| `setLayoutSync(_:)` | Update the layout popover's cross-pane sync toggles (`LayoutSync`, partial). Only with `enableMultipleLayouts: true`. See [Multi-pane layouts](#multi-pane-layouts--snapshot) |
| `setCrosshairEnabled(_:)` | Show or hide the crosshair at runtime, together with the floating trade button that rides on it. Same effect as tapping the header switch (`enableCrossHairHeader`); fires `onCrosshairToggle` when the state changes |
| `setThemeOverrides(_:)` | Update per-theme color overrides at runtime — canvas **and** chrome — accepts typed `ThemeOverrides` or raw JSON string |
| `setCanvasColors(_:)` | Recolour the **canvas only** at runtime (plot + axes; the header, bottom bar, drawing toolbar and popovers keep their theme) — typed `CanvasColors` or raw JSON string; `nil` clears. See [Chart background: canvas only](#chart-background-canvas-only) |
| `correctBar(barTime:bar:)` | Replace a specific bar with authoritative OHLCV data (e.g. server correction) |
| **Compare** | |
| `addCompare(_:)` | Add a compare symbol overlay. Fires `onCompareDataRequest` — reply via `resolveCompareDataRequest` |
| `removeCompare(_:)` | Remove a compare symbol. No-op if not active |
| `clearCompares()` | Remove every active compare symbol |
| `resolveCompareDataRequest(requestId:bars:)` | Resolve a pending `onCompareDataRequest` with fetched bars |

#### Symbol switch pattern

Always call `resetData()` before loading bars for a new symbol. This prevents
the previous symbol's candles, live price line, drawings, and trade levels
from bleeding into the new chart during the data-fetch window.

```swift
chart.setSymbol("GBPUSD")
chart.resetData()
// … fetch new bars for GBPUSD …
chart.loadData(bars)
```

### Events (callbacks)

| Callback | Fires when |
|---|---|
| `onReady` | Engine initialised |
| `onCrosshair` | Crosshair moved over a bar |
| `onBarClick` | User tapped a bar |
| `onViewportChange` | Pan or zoom changed |
| `onSeriesChange` | Series type changed |
| `onPriceSourceChange` | User picked a price source (BID / ASK / LTP) from the header dropdown (`priceSourceSelector`) |
| `onTimeframeChange` | Timeframe changed |
| `onDurationChange` | Duration changed |
| `onStateChange` | Any state mutation |
| `onStateSnapshot` | Response to `getState()` |
| `onDataLoaded` | `loadData` completed |
| `onNewBar` | New bar appended at live edge |
| `onStreamStatus` | Stream connection status changed |
| `onPlaceOrder` | User submitted an order (requires `enableTrading`) |
| `onTradeLevelEdit` | User confirmed a TFC level drag or bracket edit — payload includes `label`, `type`, `data`, `newLots?`, `changes[]` (each with `newLots?` on the `MAIN` change), `isFullscreen`. When qty was edited this session, the `lots` field embedded in `data` (and in the `MAIN` change's `data`) is overridden with the new value for convenience. |
| `onTradeLevelQtyChange` | Live qty edit via the QTY pill flyout — fires before the edit is confirmed, so hosts can refresh Estimated PNL on SL/TP brackets in real time — payload includes `label`, `type` (`"draft"` for draft orders, otherwise parent level's type), `newLots`, `previousLots`, `isFullscreen` |
| `onTradeLevelClose` | User tapped × on a level — payload includes `label`, `type`, `action`, `data`, `isFullscreen` |
| `onTradeLevelDrag` | Live price during drag, fires on every move — payload includes `label`, `newPrice`, `bracketType?`, `data`, `isFullscreen` |
| `onTradeLevelEditOpen` | User tapped the pencil button **or** (when `hideLevelConfirmCancel: true`) tapped a trade level line — payload includes `label`, `type`, `price`, `side?`, `stopLossPrice?`, `takeProfitPrice?`, `data`, `isFullscreen` |
| `onTradeLevelBracketActivated` | SL/TP bracket auto-placed via `addLevelBracket` or `addBracket` — use the `price` to pre-populate your bracket price input — payload includes `label` (`""` for draft orders, OrderID string for existing levels), `bracketType`, `price`, `isFullscreen` |
| `onTradeLevelConfirmed` | Chart ✓ button confirmed an edit — payload includes `label`, `type`, `isFullscreen` |
| `onTradeLevelEditCancelled` | In-progress level edit aborted from the chart (ESC key or inline ✕ cancel button). Not fired for draft orders (see `onDraftCancelled`). Hosts listen to reset an external modify-order panel — payload includes `label`, `type`, `isFullscreen` |
| `onDraftInitiated` | New draft order shown — payload includes `side`, `price`, `orderType`, `isFullscreen` |
| `onDraftCancelled` | Draft order cancelled — payload includes `label`, `isFullscreen` |
| `onTfcToggle` | TFC toggled on or off — payload includes `enabled: Bool` |
| `onCrosshairToggle` | Crosshair switched on or off via the header switch (`enableCrossHairHeader`) or `setCrosshairEnabled(_:)` — `.crosshairToggle(enabled:)`. Persist it and seed `crosshairEnabled` on the next init |
| `onOrderLineMoveStart` | Horizontal (time-axis) badge drag started (requires `orderLineTimeDrag`) — `.orderLineMoveStart(label:fromTimestamp:fromBarIndex:isFullscreen:)` |
| `onOrderLineMoving` | Fires on every move of a horizontal badge drag — `.orderLineMoving(label:toTimestamp:toBarIndex:isFullscreen:)` |
| `onOrderLineMoved` | Horizontal badge drag ended on another candle; the price is unchanged — `.orderLineMoved(label:fromTimestamp:toTimestamp:fromBarIndex:toBarIndex:data:isFullscreen:)` (`data` is the level's raw JSON) |
| `onUiStateChange` | Any chart flyout/modal/dropdown opened or closed — payload includes `hasOpenUI: Bool`. Most hosts don't need this directly; `ActtraderChartsView.hasOpenUI` mirrors the state automatically and `dismissAllUI()` is the usual integration point. |
| `onDataRequest` | Chart requests data for a time range — payload includes `requestId`, `from`, `to`, `timeframe`; call `resolveDataRequest` to respond |
| `onSymbolClick` | User tapped the symbol name (requires `onSymbolClick: true` in `init`) |
| `onCompareDataRequest` | Chart needs bars for a compare symbol — payload includes `requestId`, `symbol`, `timeframe`, `interval`, `start`, `end`; reply via `resolveCompareDataRequest` |
| `onCompareAdded` | Compare symbol added — payload includes `symbol`, `color` |
| `onCompareRemoved` | Compare symbol removed — payload includes `symbol` |
| `onCompareError` | Compare fetch / add failed — payload includes `symbol`, `message` |
| `onIndicatorAdded` | Study instance added — payload includes `instanceId`, `shortName`, `params`; keep `instanceId` to remove that instance later |
| `onIndicatorRemoved` | Study instance removed — payload includes `instanceId`, `shortName` |
| `onError` | Engine error |
| `onBridgeEvent` | Generic fallback — every event including those with typed callbacks |

> **`isFullscreen`** is `true` when the chart is in fullscreen mode at the time of the TFC action. Use it to gate toast notifications so they only appear while the chart is covering the full screen.

## Multi-pane layouts & snapshot

The WebView bundle includes the chart-owned multi-layout popover (26 grid
presets + 5 cross-pane sync toggles) and a snapshot popover (Download / Copy
PNG). Both are opt-in and dispatch bridge events back to the host.

### Enabling the layout & snapshot UI

```swift
let chart = ActtraderChartsView(
    theme:                 "dark",
    symbol:                "EURUSD",
    timeframe:             "1h",
    headerLayout:          "advanced",   // "simple" (default) | "advanced" | "compact"
    enableMultipleLayouts: true,         // Layout button + preset picker
    enableSnapshot:        true,         // Snapshot button + Download/Copy
    layoutSync:            LayoutSync(symbol: false, interval: true) // optional — seed the sync toggles
)

chart.onLayoutChange = { event in
    guard case let .layoutChange(presetId, syncJson) = event else { return }
    // presetId is one of "1", "2-h", "2-v", "4-2x2", "6-2x3", "8-4x2", … —
    // see the JS library's LAYOUT_PRESETS for the full catalogue.
    // syncJson is the raw LayoutSyncState JSON: {symbol, interval, crosshair, time, dateRange}.
    print("preset=\(presetId) sync=\(syncJson)")
    // The host owns the actual N-pane grid — mount/teardown sibling
    // ActtraderChartsViews to match preset.count and apply the sync flags.
}

chart.onSnapshot = { event in
    guard case let .snapshot(dataUrl, action) = event else { return }
    // action is "download" or "copy"; dataUrl is a base64 PNG.
    // Intercept here to save to Photos / UIPasteboard via platform APIs.
}
```

### Building a native layout picker

Apps that draw their own header get every grid preset from the catalog
(`onCatalog` / `getCatalog()`, from chart 1.3.0-beta.31): `layouts.presets` lists
the same presets the web popover shows — `id`, `label`, `count`, `cols`, `rows`,
`areas` / `areaOrder` for the uneven shapes, and an inline-SVG `icon` — grouped
by `layouts.counts`, plus `layouts.sync` with the five toggles and their
defaults. The `layouts` toolbar entry says the chart accepts the pick.

```swift
chart.onCatalog = { e in
    let catalog = try? JSONSerialization.jsonObject(with: Data(e.catalogJson.utf8)) as? [String: Any]
    let presets = (catalog?["layouts"] as? [String: Any])?["presets"] as? [[String: Any]] ?? []
    // build the picker from presets[i]["id"] / "label" / "count" / "icon"
}

chart.setLayoutPreset("4-2x2")        // → .layoutChange(presetId: "4-2x2", …)
```

The chart never splits itself: on `layoutChange` mount `count` sibling
`ActtraderChartsView`s in a grid shaped by `cols` × `rows`. With
`headerLayout: "mobile"` the chart's own header shows the Layout button and
preset popover when `enableMultipleLayouts: true`.

### `headerLayout`

| Value         | Use case
|---------------|----------------------------------------------------------------
| `"simple"`    | Classic TopBar (default) — symbol, type, timeframe, studies, drawings
| `"advanced"`  | Compact pill-style toolbar — recommended above multi-pane grids
| `"compact"`   | Slim per-pane toolbar — recommended for individual cells of a grid

> **Sync flags are intent, not action.** The native host is responsible for
> mirroring symbol/timeframe/viewport across sibling chart views — the
> JS-side `ChartGroup` only operates inside one WebView. On iOS each pane is
> its own `ActtraderChartsView`, so coordinate from Swift (e.g. call
> `setTimeframe(_:)` on every pane when the sync JSON's `interval` is `true`).

### Seeding & restoring the sync toggles

The layout popover's five sync toggles default to the library's `DEFAULT_LAYOUT_SYNC`.
Pass a partial `LayoutSync` to the initializer to open the popover in a saved state,
and call `setLayoutSync(_:)` to update an already-mounted chart (e.g. mirroring a
native settings screen). Omitted (`nil`) fields keep their current value.

```swift
// Seed at init — restore the user's persisted preference
let chart = ActtraderChartsView(
    enableMultipleLayouts: true,
    layoutSync: LayoutSync(symbol: false, interval: false, crosshair: false, time: false, dateRange: false)
)

// Update later — partial; other toggles unchanged. No layoutChange echo.
chart.setLayoutSync(LayoutSync(crosshair: true))
```

## Side panels

A right-hand docked panel with two tabs — **Data Window** (OHLC and indicator
values at the cursor) and **Objects** (everything drawn on the chart) — behind
the `enableSidePanels` init flag.

```swift
ActtraderChartsView(enableSidePanels: true)
```

```swift
chart.setSidePanelTab("objects")
chart.setSidePanelVisible(false)

// Per-object controls, for driving the list from your own UI.
chart.setDrawingVisible(id, visible: false)
chart.setDrawingLocked(id, locked: true)
chart.deleteDrawing(id)
chart.selectDrawing(id)        // nil clears the selection
```

**Closing it collapses the panel to a 30px icon rail, it does not hide it** —
a panel that vanished would leave nothing to tap to get it back. Expanded it
takes 232px out of the plot, which is why the feature is off by default and why
you will probably want it collapsed on a phone. `setSidePanelVisible` is the
expanded-versus-rail switch; the init flag is what removes it entirely.

The Data Window follows the crosshair, falling back to the last bar when the
cursor is off the plot. The Objects tab lists drawings and indicators with
show/hide, lock and remove per row; tapping a drawing selects it on the chart.

A change made inside the panel reaches your app:

```swift
case let .sidePanelVisibility(visible, tab): …
```


## Bottom bar & price scale

Five TradingView controls, behind the `enableScaleControls` init flag. The flag
adds a cluster to the left of the duration buttons — **Go to date**, a
**timezone** selector, and **%**, **log**, **auto** — and needs
`showBottomBar = true`, since the duration bar is off by default.

```swift
ActtraderChartsView(
    showBottomBar: true,
    enableScaleControls: true,
    priceScaleMode: "log",
    autoScale: true
)
```

```swift
chart.setPriceScaleMode("log")    // "normal" | "log" | "percent"
chart.setAutoScale(false)
chart.goToDate("2024-03-01")      // ISO 8601, or unix ms as a string
```

**`goToDate` centres the nearest bar**, not an exact match: the date asked for is
often a weekend or a holiday, and landing beside it beats not moving. It reports
back which bar it settled on.

**Log maps equal ratios to equal height** — a move from 10 to 20 takes the same
space as one from 100 to 200. It is unavailable on data that reaches zero or
below and maps linearly there rather than refusing to draw.

**Percent** re-expresses every price as change from the first visible bar's
close, so panning re-bases rather than pinning to the start of history. Log and
percent are one choice, not two flags.

**Turning auto-scale off freezes what is on screen**, so the chart does not jump
as it stops moving. A manual axis drag still wins.

Each fires a matching event, so a change made in the bar reaches your app:

```swift
case let .priceScaleModeChange(mode): …
case let .autoScaleChange(enabled): …
case let .goToDate(time, barIndex): …
```


## Chart settings

Six TradingView settings, behind the `enableChartSettings` init flag. The flag
adds three tabs — **Status Line**, **Scales**, **Canvas** — to the chart's
settings dialog and a bar-colouring choice to Appearance. Each is also an init
parameter and a runtime method, so you can drive them from your own UI and leave
the dialog alone.

```swift
ActtraderChartsView(
    enableChartSettings: true,
    statusLineJson: #"{"barChange":true}"#,
    scalesJson: #"{"pricePrecision":4,"timezone":"Asia/Tokyo"}"#,
    canvasJson: #"{"gridVertical":false,"watermarkVisible":true}"#,
    barColorSource: "previousClose"
)
```

The three group parameters take **raw JSON**, the same opaque-string convention
`themeOverrides` and `canvasColors` already use — the shapes are nested and
would otherwise need a parallel data class per group in each wrapper.

| Group | Keys |
| --- | --- |
| `statusLine` | `symbol`, `ohlc`, `barChange`, `volume` |
| `scales` | `lastPriceLabel`, `bidLabel`, `askLabel`, `highLowLabels`, `timeAxisCountdown`, `pricePrecision`, `timezone` |
| `canvas` | `gridHorizontal`, `gridVertical`, `watermarkVisible`, `watermarkText`, `watermarkSize`, `watermarkOpacity`, `crosshairStyle`, `crosshairWidth` |

```swift
chart.setStatusLineSettings(#"{"barChange":true}"#)
chart.setScalesSettings(#"{"highLowLabels":true}"#)
chart.setCanvasOptions(#"{"gridVertical":false}"#)
chart.setBarColorSource("previousClose")
chart.setPricePrecision(4)   // nil re-infers from the feed
```

**Every setter merges.** Keys you leave out keep whatever they are, so you can
flip one without restating the rest.

**Price precision is display only.** It does not change pip size, which is a
property of the contract and comes from `InstrumentSpec` — the Ruler keeps
saying what a move is actually worth however few decimals the axis shows.

**`barColorSource`** is `"open"` (the default) or `"previousClose"`. It applies
to candles, hollow candles, bars, HLC bars, columns and the volume pane
together. Heikin Ashi, Renko, Kagi and Point & Figure are unaffected —
direction is intrinsic to what those transforms compute.

Each setting fires a matching event, so a change made in the dialog reaches your
app:

```swift
case let .pricePrecisionChange(digits): …
case let .barColorSourceChange(source): …
case let .timezoneChange(timezone): …
case let .statusLineChange(json): …
case let .scalesChange(json): …
case let .canvasOptionsChange(json): …
```


## Icons & drawing toolbar options

### Icons, emojis & stickers — `"icon"`

A glyph placed at a bar and price, behind the `enableIconTools` init flag.
**One tool, not three**: emojis, stickers and icons are the same drawing with a
different character, so the toolbar's **Icons & Emojis** group picks the glyph
and the glyph travels in the drawing's text.

```swift
ActtraderChartsView(enableIconTools: true)
```

Opening the group gives a picker panel — category tabs across the top, a
scrolling grid, and **Emojis / Stickers / Icons** along the bottom. Stickers are
the same characters placed larger; Icons are monochrome and take the drawing's
colour, which an emoji cannot since it is a colour bitmap in the system font.

A placed icon is **resizable by dragging any of its four corner handles**, and
its size is also in the style popover. The size is in pixels, so it does not
rescale when the chart is zoomed — a pin dropped on a bar stays the size it was
put at. Touch drags resize it too.

`"zoomIn"` drags a box and zooms the chart to it, removing itself once applied.
Both tools are `setDrawingTool` strings — no wrapper change.


> **Fixed:** `enableCursorModes` was reaching the webview as a flat init key and
> being dropped before it got to the chart's `features`, so the Cursors group
> never appeared. It is mapped correctly now, along with `enableIconTools`.

### Toolbar options

| Method | What it does |
| --- | --- |
| `setMagnetMode(_)` | Drawing points snap to the nearest OHLC of the bar under the cursor. |
| `setKeepDrawingMode(_)` | The tool stays armed after each drawing. |
| `setCopyDrawingsToAllCharts(_)` | New drawings are announced for layout-wide replication. |
| `setDrawingToolbarVisible(_)` | Shows or hides the drawing toolbar at runtime. |

All four can also be set in `init`, and each has a matching event so a toggle
flipped from the toolbar reaches your app.

```swift
chart.setMagnetMode(true)
```

**Magnet snaps within a pixel threshold, not always** — a line deliberately drawn
through the middle of a range stays there. The threshold is in pixels so it feels
identical at every zoom.

**Copy-to-all is announced, not performed.** Only your app knows which panes
exist, so the chart emits the drawing and you replicate it:

```swift
case let .drawingCreated(_, json, copyToAll):
    if copyToAll { otherCharts.forEach { $0.addDrawing(json) } }
```

`addDrawing` appends — it leaves the drawings already on the target chart alone,
and the copy gets its own id, so dragging it in one pane does not move it in the
rest.


## Notes & text tools

Six annotation tools, all single-click then type. New `setDrawingTool` strings —
no wrapper change needed.

| `tool` | Form |
| --- | --- |
| `"anchoredText"` | Free text with a dot on the bar and price it refers to. |
| `"note"` | A compact page marker with the text beside it. |
| `"pin"` | A teardrop whose **tip** sits exactly on the price. |
| `"table"` | Rows of text in a bordered grid. |
| `"comment"` | A rounded speech bubble with its tail on the anchor. |
| `"signpost"` | A plaque on a post, rising clear of the candles. |

```swift
chart.setDrawingTool("signpost")
```

Each opens the chart's text editor on placement. **Anchored Text, Note, Table,
Comment and Signpost get a multi-line editor** where `Enter` inserts a newline
and `Ctrl`/`⌘`+`Enter` (or tapping away) commits; Text, Callout, Anchored Note
and Pin keep the single-line field where `Enter` commits. Double-tapping a
placed annotation reopens its editor.

**Table syntax**: newlines are rows and `|` separates columns, so a table is
typed into one text field rather than needing its own editor. The first row is
tinted as a header. **A new table arrives already a 4x2 grid**, with the syntax
visible in the editor — an empty one showed a single row and gave no hint that
rows and columns existed.

**Pin anchors by its tip, not its centre** — a marker whose middle sits on the
level is ambiguous about which price it means.


## Indicator library

**78 studies added**, taking the library from 30 to 108. They are reachable
through the existing `addIndicator` bridge command by short name — **no wrapper
change was needed**:

```swift
chart.addIndicatorByName("TRIX")
```

Short names include `ALMA`, `DEMA`, `TEMA`, `LSMA`, `McGinley`, `SMMA`, `VWMA`,
`AMA`, `Guppy`, `TRIX`, `TSI`, `UO`, `Fisher`, `KST`, `CMO`, `CRSI`, `Aroon`,
`DMI`, `Vortex`, `Chop`, `HV`, `StdDev`, `Env`, `PriceChannel`, `Alligator`,
`Fractal`, `ZigZag`, `VPVR` and more — see the main
[ActCharts README](../ActCharts/README.md) for the full table.

### Two things worth knowing

**Five studies need a second instrument.** Correlation Coefficient,
Correlation – Log, Ratio, Spread and Advance/Decline read the symbols the user
has added through **Compare**. With none added they draw nothing, rather than
substituting a stand-in series that would answer a different question than the
indicator's name promises.

**`maxSubPanes` caps concurrent sub-pane indicators.** Most of these 78 live in
their own pane, so adding many at once silently stops at the cap. Raise
`maxSubPanes` in the `init` payload if you need more on screen together.


## Shapes & arrow tools

| `tool` | Points | What it does |
| --- | --- | --- |
| `"arrowMarkLeft"` | 1 | A mark pointing at a price level from the right. |
| `"arrowMarkRight"` | 1 | A mark pointing at a price level from the left. |
| `"curve"` | 3 | A quadratic Bézier between two ends, bent by one handle. |
| `"doubleCurve"` | 3 | An S — two mirrored quadratics sharing that handle. |

```swift
chart.setDrawingTool("doubleCurve")
```

**The line arrow already existed.** `"arrowMarker"` is TradingView's Arrow — a
line with a filled arrowhead at the tip. It was only ever *labelled* "Arrow
Marker", which hid it; the label now reads **Arrow**. The tool string is
unchanged, so nothing in your integration breaks.

**Curve is not `"arc"`.** The arc tool fits a circle through three points, and a
circle's curvature is constant — it cannot leave one end steeply and arrive at
the other gently. A Bézier can, which is the whole reason to have both.


## Projection & measurement tools

| `tool` | Points | What it does |
| --- | --- | --- |
| `"anchoredVwap"` | 1 | Volume-weighted average price accumulated from the anchored bar. |
| `"forecast"` | 3 | A base move, a projected continuation, and a cone of uncertainty. |
| `"barsPattern"` | 3 | Replays a chosen bar range's price action at a new anchor. |
| `"longPosition"` / `"shortPosition"` | 2 | Risk/reward sketches — **already shipped**, see below. |

```swift
chart.setDrawingTool("anchoredVwap")
```

**Long / Short Position already exist.** They draw entry, target and stop as a
green profit zone and a red risk zone with the money and quantity your account's
risk budget implies, and need `enableForecasting` plus an `account`:

```swift
ActtraderChartsView(enableForecasting: true, account: AccountSpec(equity: 50_000, riskPercent: 1))
```

They are drawings, not Trade-From-Chart: nothing they draw reaches the broker.

**Anchored VWAP is not `"anchoredVP"`.** That one is Anchored Volume *Profile* —
a horizontal histogram of volume by price level. Anchored VWAP is a single line
from real volume, using the (H+L+C)/3 typical price. **It draws nothing when the
feed carries no volume**, rather than silently degrading into a running mean that
looks like a VWAP and is not one.


## Pattern tools

Two drawing tools added for TradingView parity. They are new `setDrawingTool`
strings — no wrapper API change is needed.

| `tool` | Points | What it does |
| --- | --- | --- |
| `"xabcdPattern"` | 5 | The free-form harmonic. Reports the measured AB/XA, BC/AB, CD/BC and AD/XA ratios instead of assuming a named set. |
| `"elliottTripleCombo"` | 6 | The triple three — W-X-Y-X-Z from an origin. |

```swift
chart.setDrawingTool("xabcdPattern")
```

**Why XABCD is not just another harmonic:** every named harmonic in the library
(Gartley, Bat, Butterfly, Crab, Shark, Cypher) draws the identical X→A→B→C→D
zigzag and differs only in colour — none measures anything. XABCD reports the
ratios the pivots actually produce, which is what tells you which harmonic the
structure is.

**Why Triple Combo is not the existing Combination tool:** `"elliottCombination"`
takes **seven** points and numbers its connectors `X2`/`X3`. A triple three has
six points and labels both connectors `X`. The existing tool is unchanged.


## Fibonacci & Gann tools

Five drawing tools added for TradingView parity. They are new `setDrawingTool`
strings — no wrapper API change is needed.

| `tool` | Points | What it does |
| --- | --- | --- |
| `"trendBasedFibTime"` | 3 | Projects the *duration* of the p1→p2 leg forward from p3 as vertical time lines. |
| `"fibSpeedResistanceArcs"` | 2 | Arcs at Fibonacci fractions of a trend's length — the Fan's curved counterpart. |
| `"fibWedge"` | 3 | Arcs bounded by two rays from a shared apex. |
| `"pitchfan"` | 3 | A pitchfork whose tines radiate from the handle instead of running parallel. |
| `"gannSquareFixed"` | 2 | A Gann Square forced square in pixels, so its diagonal is a true 45° at any zoom. |

```swift
chart.setDrawingTool("fibWedge")
```

Two behaviours worth knowing:

- **Speed Resistance Arcs are ellipses, not circles** — the x and y radii come
  separately from the trend's run and rise. A pixel-space circle would change
  shape as soon as the price axis was rescaled.
- **Gann Square Fixed takes the longer side of the drag for both sides**, so the
  45° diagonal really is 45°. The box therefore does not match the drag exactly:
  "fixed" means fixed *proportion*, not fixed size.


## Two-finger measure (mobile)

Hold two fingers on the chart and it shows what the TradingView app shows: the
close and date under each finger and, between them, the change in price and
percent, coloured by direction, with the range tinted. Moving the fingers moves
the measurement; lifting either finger ends it. Pinch still zooms — the measure
starts once both fingers have rested for about 0.3 s.

```swift
let chart = ActtraderChartsView(enableTwoFingerMeasure: true)

chart.onBridgeEvent = { event in
    if case let .twoFingerMeasure(phase, _, _, _, _, change, changePercent, bars) = event {
        print(phase, change, changePercent, bars)   // phase "start" / "update" / "end"
    }
}
```

## Bar Replay

Replay history bar by bar, as TradingView does. `enableReplay: true` adds a
**Replay** button to the chart header; it opens a control strip under the chart
with Select bar / Select date / First available date / Random bar, play, pause,
step, speed (0.1x–10x) and jump to real-time. Live ticks keep building the
hidden bars while a replay runs, so nothing is lost when it ends.

```swift
let chart = ActtraderChartsView(enableReplay: true)

// Or drive it from your own UI:
chart.openReplay()                 // show the strip, arm "Select bar"
chart.startReplay(timeMs: t)       // hide bars after this unix-ms time
chart.setReplaySpeed(3)            // bars per second
chart.playReplay(); chart.pauseReplay(); chart.replayStepForward()
chart.exitReplay()                 // back to real time, strip stays open
chart.closeReplay()                // back to real time and close the strip

chart.onBridgeEvent = { event in
    switch event {
    case let .replayStart(time): print("replay from", time)
    case .replayStep, .replayEnd, .replayExit: break
    default: break
    }
}
```

Four `BridgeEvent` cases come with this (`replayStart`, `replayStep`, `replayEnd`,
`replayExit`), so a `switch event` without a `default:` needs one.

## Cursors & line tools

### Extending lines

Four drawing tools that differ from a Trend Line only in where they stop being
drawn. They are new `setDrawingTool` strings — nothing else changes.

| `tool` | What it does |
| --- | --- |
| `"ray"` | Two anchors; continues past the second. |
| `"extendedLine"` | Two anchors; continues past both. |
| `"horizontalRay"` | One tap; a level that runs **forward only**, not back over history. |
| `"infoLine"` | A trend line that permanently reports price delta, percent, bars and duration. |

### Cursors

Pointer behaviour over the plot, **independent of the drawing tool** — switching
mode never cancels a drawing in progress.

| mode | Behaviour |
| --- | --- |
| `"cross"` | The default crosshair with its axis readouts. |
| `"dot"` | A dot follows the pointer instead of two lines across the candles. |
| `"arrow"` | A plain pointer, no crosshair. |
| `"demonstration"` | A laser trail that fades behind the pointer, for screen-sharing. |
| `"eraser"` | A tap deletes the drawing under it. |

```swift
ActtraderChartsView(
    cursorMode: "cross",
    valueTooltip: true,
    enableCursorModes: true
)

chart.setCursorMode("eraser")
```

`enableCursorModes` adds a **Cursors** group to the top of the drawing toolbar.
It is a flag rather than always-on because it adds a category to a toolbar apps
have laid out around its current contents. With it off the group is absent and
the toolbar is unchanged — the modes stay reachable from `setCursorMode`, so you
can drive them from your own chrome instead.

The eraser consumes every tap, hit or miss: a miss must not fall through to
selecting or panning, which would be a surprising thing to do with an eraser in
hand. It deletes through the same undo history as every other delete.

### Value tooltip on long press

`valueTooltip` shows a floating OHLCV readout beside a long press, on top of the
crosshair that gesture already arms. The OHLC strip at the top of the chart
carries the same numbers, but on a phone it is at the far end of the screen from
the finger — the user has to look away from what they are pointing at.

It flips to the other side of the touch rather than running off an edge, never
takes touch events (the drag is still in progress), and omits volume rather than
printing a zero when the feed carries none. Default `false`.

### Persisting the choice

```swift
case let .cursorModeChange(mode): store.set(mode, forKey: "cursorMode")
```


## Chart types

Five types beyond the time-based set, for TradingView parity. They are new values
of the same `series` string — nothing else about selecting a chart type changes.

| `series` | What it draws |
| --- | --- |
| `"hlc"` | HLC bars — the high-low range with a close tick, no open stub. |
| `"renko"` | Equal-height bricks; reversals need two boxes. |
| `"linebreak"` | Blocks that print when the close clears the last N blocks. |
| `"kagi"` | One connected line; thickness tracks breaks of structure. |
| `"pointfigure"` | Columns of X's and O's on a box grid. |

**The last four are not drawn per time bar.** A brick, block, segment or column
forms when *price* moves far enough, so 365 daily candles might be 24 bricks or
15 columns. The chart rebuilds its bar array from price movement, which means:

- the **time axis is non-linear** — labels show when each element completed;
- **indicators are computed over the elements**, not the underlying candles, the
  same as TradingView;
- switching in or out **refits the view**, since the element count changes;
- **market price still comes off the raw feed**, so trade levels and P&L never
  price against a brick top.

```swift
chart.setSeries("renko")

// Parameters travel as a JSON object. Omit entirely for ATR(14) on all of them.
chart.setSeriesOptions(#"{"renko":{"boxSize":{"kind":"fixed","size":5}}}"#)

// Or at init:
let chart = ActtraderChartsView(
    series: "pointfigure",
    seriesOptionsJson: #"{"pointFigure":{"boxSize":{"kind":"atr","length":20},"reversal":3}}"#
)
```

Every box/reversal size defaults to **ATR(14)** rather than a fixed price,
because a fixed box is meaningless until you know the instrument: ten points is
noise on an index and a lifetime on a forex pair. `setSeriesOptions` merges, so
retuning Renko leaves Kagi and Point & Figure alone.

`boxSize` accepts `{"kind":"atr","length":14}`, `{"kind":"fixed","size":5}` or
`{"kind":"percent","percent":2}`. When a box cannot be sized — too little history
for the ATR, or a non-positive size — the chart draws **nothing** rather than
guessing, because a wrong box size does not look wrong, it looks like a different
market.


## Top-toolbar features

Four opt-in features matching the web library's TradingView-parity header work:
**indicator templates**, **saved chart layouts**, **Quick Search**, and
**chart-settings templates with "Apply to all charts"**.

Two rules apply to all of them:

- **Nothing moves.** Every flag defaults to off, and with them off the chart renders
  exactly as before. Enabled, each extends a flyout, popover or dialog that already
  exists — none adds a header button (Quick Search can, if you ask).
- **The chart persists nothing.** Saving emits an event carrying the object as JSON;
  your app stores it and seeds it back at init. Templates and layouts cross the
  bridge as **opaque JSON strings** — store the string you were handed and send the
  same string back. Swift never has to mirror a `ChartState` only the chart reads.

### Enabling

The flags are grouped into one `HeaderFeatures` struct rather than nine more
arguments on `init` — they ship and roll back together.

```swift
let chart = ActtraderChartsView(
    theme: "dark",
    symbol: "EURUSD",
    enableMultipleLayouts: true,           // saved layouts live in this popover
    headerFeatures: HeaderFeatures(
        enableIndicatorTemplates: true,
        indicatorTemplatesJson: store.string(forKey: "indicatorTemplates") ?? "[]",
        enableSettingsTemplates: true,
        settingsTemplatesJson: store.string(forKey: "settingsTemplates") ?? "[]",
        enableSavedLayouts: true,
        savedLayoutsJson: store.string(forKey: "savedLayouts") ?? "[]",
        enableQuickSearch: true            // open it from your own toolbar
    )
)
```

A malformed stored JSON array is dropped rather than throwing — stale storage can
never stop the chart from starting.

### Commands

| Method | Does |
| --- | --- |
| `setIndicatorTemplates(_:)` | Replaces the list in the indicators flyout. |
| `captureIndicatorTemplate(_:)` | Saves the active indicators → `.indicatorTemplateSaved`. |
| `applyIndicatorTemplate(_:)` | Applies one. Accepts the id or the name. |
| `deleteIndicatorTemplate(_:)` | Removes it. |
| `setSettingsTemplates(_:)` | Replaces the list in the Settings dialog. |
| `captureSettingsTemplate(_:)` | Saves the current settings → `.settingsTemplateSaved`. |
| `applySettingsTemplate(_:)` / `deleteSettingsTemplate(_:)` | Apply / remove. |
| `applyChartSettings(_:)` | Applies a settings snapshot — the apply-to-all fan-out. |
| `setSavedLayouts(_:)` | Replaces the list in the layout popover. |
| `captureSavedLayout(_:paneId:)` | Saves the preset + this chart's state → `.layoutSaved`. |
| `applySavedLayout(_:paneId:)` / `deleteSavedLayout(_:)` | Apply / remove. |
| `setLayoutPreset(_:)` | Picks a grid shape → `.layoutChange`. |
| `openQuickSearch()` / `closeQuickSearch()` | Opens / closes the command palette. |
| `requestSnapshot(action:)` | Captures the chart → `.snapshot`. |

### Events

```swift
chart.onEvent = { event in
    switch event {
    // Persist whatever the chart hands you — it keeps nothing.
    case let .indicatorTemplateSaved(_, _, templateJson):
        store.set(append(templateJson), forKey: "indicatorTemplates")
    case let .indicatorTemplateDeleted(id):
        removeTemplate(id)

    case let .settingsTemplateSaved(_, _, templateJson):
        store.set(append(templateJson), forKey: "settingsTemplates")

    case let .layoutSaved(_, _, layoutJson):
        store.set(append(layoutJson), forKey: "savedLayouts")
    case let .layoutApplied(_, _, _, layoutJson):
        mountPanes(layoutJson)

    // "Apply to all charts": this chart already applied them, the fan-out is yours.
    case let .chartSettingsApplied(settingsJson, applyToAll):
        if applyToAll { otherCharts.forEach { $0.applyChartSettings(settingsJson) } }

    case let .quickSearchCommand(id, _, _):
        analytics.track(id)

    // The in-WebView browser download does nothing on iOS — handle it here.
    case let .snapshot(dataUrl, _):
        if let base64 = dataUrl.components(separatedBy: "base64,").last,
           let data = Data(base64Encoded: base64) {
            share(UIImage(data: data))
        }

    default:
        break
    }
}
```

### Quick Search on iOS

There is no Ctrl/⌘+K inside the WebView, so the palette has no keyboard entry point
— wire `openQuickSearch()` to a toolbar item. `closeQuickSearch()` is worth adding
to your dismiss handling alongside `dismissAllUI()`.


## Compare symbols

Overlay one or more comparison instruments on the main chart, normalized to
percent change from the leftmost visible bar. Historical-only — no live
streaming. The chart owns the picker UI (filtered by the symbols supplied via
the JS bundle's `isins`) and refetches every active compare automatically
when the primary timeframe / symbol changes or the user pans back into
history.

```swift
let chart = ActtraderChartsView(
    theme:           "dark",
    symbol:          "AAPL",
    headerLayout:    "advanced",     // Compare button lives in this toolbar
    initialCompares: ["SPY"],
    maxCompares:     8,
)

// Serve the chart's compare data requests.
chart.onCompareDataRequest = { [weak self] event in
    guard case let .compareDataRequest(requestId, symbol, _, interval, start, end) = event,
          let self else { return }
    Task {
        let bars = try await self.api.fetchBars(symbol: symbol,
                                                interval: interval,
                                                start: start,
                                                end: end)
        self.chart.resolveCompareDataRequest(requestId: requestId, bars: bars)
    }
}

chart.onCompareAdded   = { event in
    if case let .compareAdded(symbol, color) = event { print("+ \(symbol) \(color)") }
}
chart.onCompareRemoved = { event in
    if case let .compareRemoved(symbol) = event { print("- \(symbol)") }
}
chart.onCompareError   = { event in
    if case let .compareError(symbol, message) = event { print("⚠️ \(symbol): \(message)") }
}

// Programmatic control.
chart.addCompare("MSFT")
chart.removeCompare("MSFT")
chart.clearCompares()
```

When at least one compare is active the Y-axis switches to percent
(`+12.34%` / `-5.67%`); removing every compare returns it to absolute prices.

## Multiple instances of the same study

Parameterized studies (EMA, SMA, RSI, BB, …) support multiple simultaneous
instances, each with an auto-cycled color:

```swift
chart.addIndicator("EMA", params: ["period": 20])
chart.addIndicator("EMA", params: ["period": 50])   // a 2nd EMA, distinct color
chart.addIndicator("EMA", params: ["period": 200])  // a 3rd

// Track instance ids so you can remove a specific one.
var emaIds: [String] = []
chart.onIndicatorAdded = { event in
    if case let .indicatorAdded(instanceId, shortName, _) = event, shortName == "EMA" {
        emaIds.append(instanceId)
    }
}
chart.onIndicatorRemoved = { event in
    if case let .indicatorRemoved(instanceId, _) = event {
        emaIds.removeAll { $0 == instanceId }
    }
}

chart.removeIndicator(emaIds.first!)  // remove just that instance ("EMA#1")
chart.removeIndicator("EMA")          // or remove ALL EMA instances
```

A few studies stay single-instance and toggle off when re-added: `VOL`, `OBV`,
`A/D`, `AO`, `VWAP`, `Ichimoku`, `PSAR`, `Pivot`, and Heikin-Ashi.

## Handling back / dismiss actions

When a flyout, modal, or dropdown is open inside the chart and the user performs a back action (swipe-back gesture, custom back button, or dismiss button in your UI), call `dismissAllUI()` first. It returns `true` if something was dismissed — consume the event in that case and skip your normal back navigation.

```swift
// Custom back button wired to a UIBarButtonItem or UIButton
@objc func backTapped() {
    if !chart.dismissAllUI() {
        navigationController?.popViewController(animated: true)
    }
}
```

For swipe-back gesture interception, implement `UIGestureRecognizerDelegate` and intercept the interactive pop:

```swift
// In viewDidLoad — replace the interactive pop target with your own handler
override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.interactivePopGestureRecognizer?.addTarget(
        self, action: #selector(handleSwipeBack(_:))
    )
    navigationController?.interactivePopGestureRecognizer?.delegate = self
}

@objc func handleSwipeBack(_ gesture: UIScreenEdgePanGestureRecognizer) {
    if gesture.state == .began, chart.dismissAllUI() {
        gesture.state = .cancelled   // absorb the gesture; flyout is now closed
    }
}
```

`ActtraderChartsView.hasOpenUI` is updated synchronously from the `uiStateChange` bridge event, so checking it before calling `dismissAllUI()` is safe inside any synchronous gesture or button handler.

## Mobile mode — `hideLevelConfirmCancel`

Pass `hideLevelConfirmCancel: true` in the constructor to hide the on-canvas ✓/✗ buttons and drive the edit flow from your native UI instead.

Behaviour changes when this flag is active:

| Action | Result |
|---|---|
| Tap a trade level line | `onTradeLevelEditOpen` fires immediately (whole line is the edit target) |
| Tap empty canvas while a level is selected | Edit dismissed; pending drag changes reverted |
| Release a SL/TP bracket drag | `onTradeLevelEdit` fires automatically (no ✓ button needed) |

**Market orders from chart crosshair:** When live BID/ASK data is streaming and the crosshair trade button is tapped at a price inside the spread, `onDraftInitiated` fires with `orderType = "market"` — use this to open your market order form.

**Adding a bracket without a price:** Use `addBracket(bracketType:label:)` from your native form to auto-place a SL or TP bracket at a sensible default price:
- **Draft order (new order, no ID yet):** `chart.addBracket(bracketType: "sl")` — omit `label`; the chart operates on the active draft.
- **Existing order/position:** `chart.addBracket(bracketType: "sl", label: orderId)` — pass the OrderID/TradeID.

In both cases the chart fires `onTradeLevelBracketActivated` with the computed price — use it to populate your SL/TP input field. The event's `label` is `""` (empty string) for draft orders — check `label.isEmpty` — and the OrderID string for existing levels.

To remove a bracket without a price: use `removeBracket(bracketType: "sl")` (draft) or `removeBracket(bracketType: "sl", label: orderId)` (existing).

**Estimated P&L on bracket lines:** Call `setDraftBracketPnl(bracketType: "sl", pnlText: "-$12.50")` to display a consumer-calculated P&L string next to the active bracket line on the chart. The text attaches to whichever level is the active bracket host — the draft order while drafting, or the currently selected existing pending order / position while modifying. Call `selectLevel(label: orderId)` (or have the user tap a level) before pushing the P&L text for an existing order. Pass `nil` as `pnlText` to clear.

## Native UI catalog (`onCatalog` / `getCatalog()`)

Apps that build their **own** header, drawing-tools sheet, indicators list and chart-settings screen get everything they need from the chart as one JSON — no hard-coded lists. The chart sends it **automatically once after every init**; `getCatalog()` asks for it again at any time (also before init).

```swift
// 1. Receive and store it (e.g. UserDefaults / file / Core Data), keyed by version.
chart.onCatalog = { event in
    guard case let .catalog(catalogVersion, catalogJson) = event else { return }
    if catalogVersion != UserDefaults.standard.string(forKey: "chartCatalogVersion") {
        UserDefaults.standard.set(catalogVersion, forKey: "chartCatalogVersion")
        UserDefaults.standard.set(catalogJson, forKey: "chartCatalogJson")   // raw JSON, store as-is
    }
    ChartUIStore.shared.load(catalogJson)   // decode with Codable, build the native screens
}

// 2. Optional: request it again (refresh a cached copy, or before init).
chart.getCatalog()
```

| Associated value of `.catalog` | Meaning |
|---|---|
| `catalogVersion` | Chart library version the catalog belongs to — rebuild your UI only when it changes |
| `catalogJson` | The whole catalog, raw JSON |

Top-level keys inside `catalogJson`: `catalogVersion`, `toolbar`, `timeframes`, `durations`, `seriesTypes`, `cursors`, `drawingGroups` (tools with `points`, `hasText`, `styleFields`), `drawingToolbarOptions`, `drawingStyleDefaults`, `indicators` (with `pane` and editable `fields`), `chartSettings` (tabs → sections → items with `type`, `options`, `default`), `canvasColorKeys`, `priceSources`, `limits`. Every entry has `"available"`: `true` = works in this chart version, `false` = planned — hide those. Use each entry's `id` with the existing commands, e.g. `setSeries("hollow")`, `setDrawingTool("trendLine")`, `addIndicator("RSI")`, `setCanvasColors(...)`.

## Header crosshair switch

Pass `enableCrossHairHeader: true` to the constructor to put a crosshair icon in the chart header. The chart crosshair is shown as usual on load and the icon is tinted. Tapping the icon hides the crosshair — and the floating "place order at this price" button that rides on it — and the icon drops to its plain state; tapping again brings both back.

```swift
let chart = ActtraderChartsView(
    enableCrossHairHeader: true,
    crosshairEnabled: UserDefaults.standard.object(forKey: "crosshair") as? Bool ?? true // restore the last choice
)
chart.onCrosshairToggle = { event in
    if case let .crosshairToggle(enabled) = event {
        UserDefaults.standard.set(enabled, forKey: "crosshair")
    }
}
chart.setCrosshairEnabled(false) // same as tapping the icon while it is on
```

## Horizontal (time-axis) order-line dragging

Off by default — pass `orderLineTimeDrag: true` only for the users who should have it (it is a per-broker feature). Any level passed to `setLevels` with `"timeDraggable": true` can then have its info-box badge dragged left/right to re-anchor it to a different candle; `"timestamp"` (unix ms) says which candle the badge starts over. **Open positions and pending orders both qualify.** A position's badge grabs horizontally at once. A pending order keeps its entry-price drag: the first movement of its badge decides — sideways moves the time anchor with the price locked, up/down moves the entry price exactly as before. A tap that never moves still opens the edit panel.

```swift
let chart = ActtraderChartsView(orderLineTimeDrag: true, orderLineDragSnap: true, orderLineDefaultAnchor: "center")

chart.setLevels(
    [[
        "id": "ORD-1", "price": 1.21013, "side": "buy", "orderType": "limit",
        "lots": 0.05, "timestamp": 1_718_000_000_000, "timeDraggable": true,
    ]],
    labelKey: "id", priceKey: "price", type: "pending"
)

chart.onOrderLineMoved = { event in
    guard case let .orderLineMoved(label, _, toTimestamp, _, _, _, _) = event else { return }
    // Price is unchanged — only the badge's time anchor moved. The chart already remembers
    // the drop in localStorage (orderLineAnchorPersistence); store toTimestamp server-side
    // and echo it as "timestamp" in the next setLevels if you persist anchors yourself.
}
```

Sideways drags emit `onOrderLineMoveStart` / `onOrderLineMoving` / `onOrderLineMoved`; vertical price drags keep emitting `onTradeLevelDrag` / `onTradeLevelEdit`. `orderLineDragSnap` (default `true`) snaps the drop to the nearest candle, `orderLineAnchorPersistence` (default `true`) remembers it across reloads, and `orderLineDefaultAnchor: "center"` starts never-dragged badges mid-chart instead of over their `timestamp`.

## CI / CD

- **`sync-chart.yml`**: Triggered by `repository_dispatch` from `acttrader/stockchart` on release. Opens a PR that updates `Sources/ActtraderCharts/Resources/chart.html`.
- **`publish.yml`**: Triggered on `v*` tag push. Runs `swift test` on macOS and creates a GitHub Release (consumed by SPM consumers via git tag).

---

## Instrument specs

The chart reads prices, never contract specs — so a tool that reports a distance
in **pips**, or converts one to money, has to be told how.

The **ruler** uses this. With specs it reads:

```
0.00455 (0.80%) 45.5
43 bars, 9d 4h
Vol 102.27K
```

Without them a pip figure is still shown, but inferred from how many decimals
the feed quotes — the usual FX convention, which is wrong for metals, indices
and crypto.

```swift
let chart = ActtraderChartsView(
    theme: "dark",
    symbol: "EURUSD",
    instrument: InstrumentSpec(
        pipSize: 0.0001,       // 0.01 for JPY crosses
        contractSize: 100_000  // units per lot
    )
)

// Specs belong to the instrument — swap them with the symbol.
chart.setSymbol("USDJPY")
chart.setInstrument(InstrumentSpec(pipSize: 0.01, contractSize: 100_000))
```

| Field | Type | Default | Description |
|---|---|---|---|
| `pipSize` | `Double?` | inferred | Price distance counted as one pip |
| `contractSize` | `Double?` | `1` | Units per lot (`100` for XAUUSD, `100000` for most FX pairs) |
| `valuePerPoint` | `Double?` | `1` | Account-currency value of one price unit per contract unit |
| `currencySymbol` | `String?` | `"$"` | Prefixed to money figures |

Every field is optional and the whole struct can be omitted — tools fall back to
price-only readouts, so an existing integration keeps working untouched.

When `pipSize` is absent it is inferred from how many decimals the feed quotes:
five-decimal (`1.08531`) and three-decimal (`151.234`) feeds carry fractional
pips, so the pip is the second-to-last digit; two- and four-decimal feeds quote
whole pips. **That convention is wrong for metals, indices and crypto** — pass
`pipSize` explicitly if pips matter.

> A stale pip size reports a wrong number rather than failing visibly, so always
> call `setInstrument(_:)` alongside `setSymbol(_:)`.

## Freehand drawing

`brush` and `highlighter` draw freehand: press, drag, release. The pointer path
is sampled continuously and the finished stroke is thinned to the points that
carry its shape. (`polyline` and `path` remain tap-per-point.)

## Position tools

`"longPosition"` and `"shortPosition"` sketch a trade that hasn't been placed:
a green profit zone from entry to target, a red risk zone from entry to stop,
and live readouts.

```
Target: 0.00313 (0.549%) 31.3, Amount: 5622.13
Open PnL: 0.00146, Qty: 11323
Risk/reward ratio: 1.84
Stop: 0.00170 (0.298%) 17.0, Amount: 2887.5
```

Two taps place it — entry, then target — and the stop lands at a 2:1
reward:risk to be dragged. All three prices have handles.

Quantity is sized so hitting the stop costs exactly `riskPercent` of the
account:

```swift
chart.setAccount(AccountSpec(size: 10_000, riskPercent: 1))
```

| Field | Type | Default | Description |
|---|---|---|---|
| `size` | `Double?` | — | Account equity in the account currency |
| `riskPercent` | `Double?` | `1` | Percent of the account risked per trade |

Omit it and the tools still draw — price, percent, pips and risk/reward all
render; only quantity and money are left out. Money amounts and pips also need
[Instrument specs](#instrument-specs).

> **These are drawings, not orders.** Trade-From-Chart is what puts real broker
> orders on the chart. Nothing on a position tool reaches the broker.
>
> A sketch drawn against a stale balance reports the wrong quantity rather than
> failing visibly, so call `setAccount(_:)` whenever equity moves.

## Feature flags

The reworked drawing tools ship behind one init flag so each broker opts in.
**It defaults to `false`** — an app that doesn't set it keeps exactly the toolbar
it has today.

```swift
let chart = ActtraderChartsView(
    theme: "dark",
    symbol: "EURUSD",
    enableForecasting: true
)
```

`enableForecasting` turns on three things together:

| | What it changes |
|---|---|
| **Position tools** | Adds **Long Position** / **Short Position** in a **Forecasting** group. Off, the group is not rendered at all |
| **Freehand brush** | **Brush** and **Highlighter** draw freehand (press, drag, release). Off, they stay tap-per-point, ended by a double-tap |
| **Detailed ruler** | **Ruler** reports percent, pips, duration and volume. Off, it reports bar count and raw price delta |

One flag rather than three because they ship and roll back together. With it off
the Forecasting group is absent from both the drawing toolbar and the mobile
tools sheet.

> Pass these ids to `setDrawingTool` exactly as written — `"longPosition"` /
> `"shortPosition"`, camelCase. An unrecognised id silently draws a Trend Line.

The position tools show quantity and money only with `account`; pips on both the
position tools and the ruler come from `instrument`.
