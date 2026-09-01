import Foundation

/// Account figures the Long/Short position tools size themselves against.
///
/// TradingView asks the user to type these because it has no broker connection.
/// An ActTrader host does know the live account, so pass real equity here and
/// keep it current — a sketch drawn against a stale balance quietly reports the
/// wrong quantity rather than failing visibly.
///
/// Omit it and the position tools still draw, showing price, percent, pips and
/// risk/reward but no quantity or money amounts.
///
/// ```swift
/// chart.setAccount(AccountSpec(size: 10_000, riskPercent: 1))
/// ```
public struct AccountSpec {
    /// Account equity in the account currency.
    public var size: Double?

    /// Percent of the account risked per trade. Default `1`.
    public var riskPercent: Double?

    public init(size: Double? = nil, riskPercent: Double? = nil) {
        self.size = size
        self.riskPercent = riskPercent
    }

    internal func toDictionary() -> [String: Any] {
        var o: [String: Any] = [:]
        if let size { o["size"] = size }
        if let riskPercent { o["riskPercent"] = riskPercent }
        return o
    }
}
