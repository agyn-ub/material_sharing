import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://ycerbilignjmtzkytyrn.supabase.co")!,
    supabaseKey: "sb_publishable_Y7n4k2mtXblfEdzuhNr1ew_jCVWu8PF"
)

enum Config {
    static let apiBaseURL = "https://handsome-creation-production.up.railway.app/api"

    static let maxPhotosPerListing = 3
    static let maxPhotoSizeMB = 5
    static let defaultSearchRadiusMeters = 10_000
    static let maxSearchRadiusMeters = 50_000
}
