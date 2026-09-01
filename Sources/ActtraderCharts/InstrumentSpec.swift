import Foundation

/// What a price *means* for the current instrument.
///
/// The chart reads prices, never contract specs — so a tool that reports a
/// distance in pips, or converts one to money, has to be told how. The ruler
/// uses this to show a pip count alongside the price delta; without it, the
/// readout stops after the percentage.
///
/// Every field is optional and every one degrades to a documented fallback, so
/// an app that omits the whole struct simply gets price-only readouts.
///
/// Pass it to ``ActtraderChartsView/init(...)`` and swap it with
/// ``ActtraderChartsView/setInstrument(_:)`` whenever the symbol changes — specs
/// belong to the instrument, and a stale pip size reports a wrong number rather
/// than failing visibly.
///
/// ```swift
/// chart.setSymbol("USDJPY")
/// chart.setInstrument(InstrumentSpec(pipSize: 0.01, contractSize: 100_000))
/// ```
public struct InstrumentSpec {
    /// Price distance counted as one pip — `0.0001` for most FX pairs, `0.01`
    /// for JPY crosses.
    ///
    /// When `nil` it is inferred from how many decimals the feed quotes, which
    /// follows the usual FX convention and is **wrong for metals, indices and
    /// crypto**. Pass it explicitly if pips matter.
    public var pipSize: Double?

    /// Units per lot (`100` for XAUUSD, `100000` for most FX pairs). Default `1`.
    public var contractSize: Double?

    /// Account-currency value of one price unit per contract unit. Default `1`.
    public var valuePerPoint: Double?

    /// Prefixed to money figures. Default `"$"`.
    public var currencySymbol: String?

    public init(
        pipSize: Double? = nil,
        contractSize: Double? = nil,
        valuePerPoint: Double? = nil,
        currencySymbol: String? = nil
    ) {
        self.pipSize = pipSize
        self.contractSize = contractSize
        self.valuePerPoint = valuePerPoint
        self.currencySymbol = currencySymbol
    }

    internal func toDictionary() -> [String: Any] {
        var o: [String: Any] = [:]
        if let pipSize { o["pipSize"] = pipSize }
        if let contractSize { o["contractSize"] = contractSize }
        if let valuePerPoint { o["valuePerPoint"] = valuePerPoint }
        if let currencySymbol { o["currencySymbol"] = currencySymbol }
        return o
    }
}
