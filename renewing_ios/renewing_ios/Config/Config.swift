import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://yborrqitngwfksrkpeij.supabase.co")!,
    supabaseKey: "sb_publishable_-1QyUrEs0K1R4Nau_xlGSA_gW6UWHMv"
)

enum Config {
    static let apiBaseURL = "https://handsome-creation-production.up.railway.app/api"

    static let maxPhotosPerListing = 3
    static let maxPhotoSizeMB = 5
    static let defaultSearchRadiusMeters = 10_000
    static let maxSearchRadiusMeters = 50_000
}
