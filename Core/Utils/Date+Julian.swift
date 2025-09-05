
import Foundation
extension Date {
    func shortLocalString() -> String {
        let f = DateFormatter()
        f.dateStyle = .medium; f.timeStyle = .short
        return f.string(from: self)
    }
}
