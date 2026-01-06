import Foundation

class AspectCalculator {
    /// Calcule la distance la plus courte sur un cercle (0-360)
    static func shortestDistance(_ a1: Double, _ a2: Double) -> Double {
        let diff = abs(a1 - a2)
        return diff > 180 ? 360 - diff : diff
    }
}
