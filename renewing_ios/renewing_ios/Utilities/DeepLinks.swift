import UIKit

struct DeepLinks {
    static func openDirections(lat: Double, lng: Double) {
        let dgis = URL(string: "dgis://2gis.ru/routeSearch/rsType/car/to/\(lng),\(lat)")!
        let google = URL(string: "comgooglemaps://?daddr=\(lat),\(lng)")!
        let apple = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lng)")!

        if UIApplication.shared.canOpenURL(dgis) {
            UIApplication.shared.open(dgis)
        } else if UIApplication.shared.canOpenURL(google) {
            UIApplication.shared.open(google)
        } else {
            UIApplication.shared.open(apple)
        }
    }

    static func call(phone: String) {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
}
