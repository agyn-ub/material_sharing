import Foundation
import SwiftUI
import CoreLocation

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension Color {
    static let matshareOrange = Color(red: 0.96, green: 0.55, blue: 0.15)
    static let matshareGreen = Color(red: 0.22, green: 0.78, blue: 0.45)
    static let matshareBg = Color(UIColor.systemGroupedBackground)
}

extension Date {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ru")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
