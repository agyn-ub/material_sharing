# MatShare — Construction Materials Marketplace

## Development Plan for Claude Code

---

## Project Overview

A mobile marketplace that connects people with leftover construction materials/tools to those who need small quantities. Core feature: GPS-based distance search so seekers find nearby listings.

---

## Tech Stack

| Layer | Technology | Hosting |
|-------|-----------|---------|
| Mobile App | iOS / Swift / SwiftUI | App Store |
| Backend | Node.js / Express (REST API) | Railway |
| Database | PostgreSQL + PostGIS | Supabase |
| Auth | Supabase Auth (Apple Sign-In) | Supabase |
| Photo Storage | Supabase Storage | Supabase |
| Navigation | Deep links to 2GIS / Google Maps | External apps |

---

## Architecture

```
iOS App (Swift/SwiftUI)
  ├── Supabase Auth SDK (login → JWT token)
  ├── Supabase Storage SDK (upload photos directly)
  └── Railway Node.js REST API (all requests include JWT in Authorization header)
          └── Connects to Supabase PostgreSQL via connection string
```

---

## Phase 1: Backend Setup (Node.js on Railway)

### 1.1 Project Initialization

```
mkdir matshare-api
cd matshare-api
npm init -y
npm install express pg cors helmet dotenv jsonwebtoken multer
npm install -D nodemon
```

### 1.2 Project Structure

```
matshare-api/
├── src/
│   ├── server.js                 — Express app entry point
│   ├── config/
│   │   └── db.js                 — PostgreSQL connection pool (Supabase)
│   ├── middleware/
│   │   └── auth.js               — Verify Supabase JWT
│   ├── routes/
│   │   ├── listings.js           — CRUD + location search
│   │   └── users.js              — User profile
│   ├── controllers/
│   │   ├── listingsController.js
│   │   └── usersController.js
│   └── utils/
│       └── helpers.js
├── .env
├── .gitignore
├── package.json
└── README.md
```

### 1.3 Environment Variables (.env)

```
PORT=3000
DATABASE_URL=postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres
SUPABASE_URL=https://[project-ref].supabase.co
SUPABASE_SERVICE_KEY=your-service-role-key
SUPABASE_JWT_SECRET=your-jwt-secret
```

### 1.4 Database Connection (src/config/db.js)

- Use `pg` Pool with `DATABASE_URL` from Supabase
- Enable SSL for production (`ssl: { rejectUnauthorized: false }`)

### 1.5 Auth Middleware (src/middleware/auth.js)

- Extract Bearer token from Authorization header
- Verify JWT using Supabase JWT secret (HS256)
- Attach `req.user` with user id from token payload (`sub` field)
- Return 401 if invalid or missing

---

## Phase 2: Database Schema (Supabase PostgreSQL)

### 2.1 Enable PostGIS

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

### 2.2 Users Table

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone);
```

### 2.3 Listings Table

```sql
CREATE TABLE listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(20) NOT NULL CHECK (category IN ('materials', 'tools')),
    subcategory VARCHAR(50),
    quantity DECIMAL(10,2),
    unit VARCHAR(20) CHECK (unit IN ('kg', 'g', 'pieces', 'bags', 'liters', 'meters', 'sq_meters', 'boxes', 'sets', 'other')),
    price DECIMAL(10,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'KZT',
    is_free BOOLEAN DEFAULT FALSE,
    photo_urls TEXT[] DEFAULT '{}',
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    address_text VARCHAR(300),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'sold', 'reserved', 'expired')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_listings_location ON listings USING GIST(location);
CREATE INDEX idx_listings_status ON listings(status);
CREATE INDEX idx_listings_category ON listings(category);
CREATE INDEX idx_listings_user ON listings(user_id);
CREATE INDEX idx_listings_created ON listings(created_at DESC);
```

### 2.4 Spatial Search Function

```sql
CREATE OR REPLACE FUNCTION search_listings_nearby(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_meters INTEGER DEFAULT 10000,
    category_filter VARCHAR DEFAULT NULL,
    limit_count INTEGER DEFAULT 50,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    title VARCHAR,
    description TEXT,
    category VARCHAR,
    subcategory VARCHAR,
    quantity DECIMAL,
    unit VARCHAR,
    price DECIMAL,
    currency VARCHAR,
    is_free BOOLEAN,
    photo_urls TEXT[],
    address_text VARCHAR,
    status VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE,
    distance_meters DOUBLE PRECISION,
    seller_name VARCHAR,
    seller_phone VARCHAR
)
LANGUAGE SQL STABLE
AS $$
    SELECT
        l.id, l.user_id, l.title, l.description,
        l.category, l.subcategory, l.quantity, l.unit,
        l.price, l.currency, l.is_free, l.photo_urls,
        l.address_text, l.status, l.created_at,
        ST_Distance(
            l.location,
            ST_MakePoint(user_lng, user_lat)::geography
        ) AS distance_meters,
        u.name AS seller_name,
        u.phone AS seller_phone
    FROM listings l
    JOIN users u ON l.user_id = u.id
    WHERE l.status = 'active'
      AND ST_DWithin(
          l.location,
          ST_MakePoint(user_lng, user_lat)::geography,
          radius_meters
      )
      AND (category_filter IS NULL OR l.category = category_filter)
    ORDER BY distance_meters ASC
    LIMIT limit_count
    OFFSET offset_count;
$$;
```

---

## Phase 3: API Endpoints

### 3.1 Listings Routes

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/listings/nearby?lat=&lng=&radius=&category=&limit=&offset=` | Yes | Search listings by location |
| GET | `/api/listings/:id` | Yes | Get single listing details |
| POST | `/api/listings` | Yes | Create new listing |
| PUT | `/api/listings/:id` | Yes | Edit own listing |
| PATCH | `/api/listings/:id/status` | Yes | Update status (sold/reserved/active) |
| DELETE | `/api/listings/:id` | Yes | Delete own listing |
| GET | `/api/listings/my` | Yes | Get current user's listings |

### 3.2 Users Routes

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/users/profile` | Yes | Create/update user profile after auth |
| GET | `/api/users/profile` | Yes | Get current user profile |
| GET | `/api/users/:id/public` | Yes | Get seller's public info (name, phone) |

### 3.3 Request/Response Examples

**POST /api/listings**
```json
{
    "title": "Cement mix leftover",
    "description": "About 5 kg left after kitchen renovation",
    "category": "materials",
    "subcategory": "cement",
    "quantity": 5,
    "unit": "kg",
    "price": 0,
    "is_free": true,
    "photo_urls": ["https://supabase-storage-url/photo1.jpg"],
    "latitude": 51.1284,
    "longitude": 71.4306,
    "address_text": "Near Mega Silk Way, Astana"
}
```

**GET /api/listings/nearby?lat=51.13&lng=71.43&radius=5000**
```json
{
    "listings": [
        {
            "id": "uuid",
            "title": "Cement mix leftover",
            "category": "materials",
            "quantity": 5,
            "unit": "kg",
            "price": 0,
            "is_free": true,
            "photo_urls": ["url"],
            "distance_meters": 2300,
            "seller_name": "Arman",
            "seller_phone": "+77001234567",
            "created_at": "2025-01-15T10:00:00Z"
        }
    ],
    "total": 1
}
```

---

## Phase 4: iOS App (Swift/SwiftUI)

### 4.1 Project Setup

- Xcode project with SwiftUI
- Add Supabase Swift SDK via SPM: `https://github.com/supabase-community/supabase-swift`
- Minimum iOS target: 16.0

### 4.2 App Structure

```
MatShare/
├── App/
│   ├── MatShareApp.swift           — App entry point
│   └── AppState.swift              — Global state management
├── Config/
│   └── Config.swift                — API URLs, Supabase keys
├── Models/
│   ├── Listing.swift               — Listing data model
│   └── User.swift                  — User data model
├── Services/
│   ├── AuthService.swift           — Supabase auth wrapper
│   ├── APIService.swift            — REST API calls to Railway backend
│   ├── LocationService.swift       — CLLocationManager wrapper
│   └── StorageService.swift        — Supabase photo upload
├── Views/
│   ├── Auth/
│   │   └── LoginView.swift         — Apple Sign-In
│   ├── Listings/
│   │   ├── ListingsListView.swift  — Main feed (sorted by distance)
│   │   ├── ListingCardView.swift   — Single listing card component
│   │   ├── ListingDetailView.swift — Full listing details
│   │   └── FilterView.swift        — Category, radius filter
│   ├── CreateListing/
│   │   ├── CreateListingView.swift — Form to post a listing
│   │   ├── PhotoPickerView.swift   — Camera / photo library
│   │   └── LocationPickerView.swift — Pin GPS location
│   ├── Profile/
│   │   ├── ProfileView.swift       — User profile
│   │   └── MyListingsView.swift    — User's own listings
│   └── Components/
│       ├── DistanceBadge.swift     — "2.3 km" badge
│       ├── CategoryPicker.swift
│       └── PriceTag.swift          — "Free" or price display
└── Utilities/
    ├── DeepLinks.swift             — Open 2GIS / Google Maps
    └── Extensions.swift
```

### 4.3 Key Screens

**Screen 1: Login**
- "Sign in with Apple" button
- On success → create/update user profile via API
- User enters phone number on first login (for sellers to receive calls)

**Screen 2: Listings Feed (Home)**
- Request location permission on first launch
- Show list of nearby listings sorted by distance
- Pull to refresh
- Filter bar: [All] [Materials] [Tools] — radius slider
- Each card shows: photo, title, quantity, distance, price/free

**Screen 3: Listing Detail**
- Full photo(s)
- Description, quantity, category
- Distance from user
- Seller name + phone
- [📞 Call] button → opens phone dialer
- [🗺 Get Directions] button → opens 2GIS or Google Maps

**Screen 4: Create Listing**
- Photo picker (camera + library, up to 3 photos)
- Title, description
- Category picker (materials / tools)
- Subcategory
- Quantity + unit picker
- Price input (toggle for "Free")
- Location: "Use current location" button or tap on map to adjust
- [Post] button

**Screen 5: My Listings**
- List of user's own listings
- Swipe to mark as sold / delete
- Tap to edit

### 4.4 Location Service

```swift
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let manager = CLLocationManager()
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func getCurrentLocation() {
        manager.requestLocation()
    }
}
```

### 4.5 Deep Links (2GIS / Google Maps)

```swift
struct DeepLinks {
    static func openDirections(lat: Double, lng: Double) {
        // Priority: 2GIS → Google Maps → Apple Maps
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
        if let url = URL(string: "tel://\(phone)") {
            UIApplication.shared.open(url)
        }
    }
}
```

**Info.plist — add URL schemes:**
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>dgis</string>
    <string>comgooglemaps</string>
</array>
```

### 4.6 API Service

```swift
class APIService {
    static let shared = APIService()
    let baseURL = "https://matshare-api.up.railway.app/api"
    
    func fetchNearbyListings(lat: Double, lng: Double, radius: Int = 10000, category: String? = nil) async throws -> [Listing] {
        var urlString = "\(baseURL)/listings/nearby?lat=\(lat)&lng=\(lng)&radius=\(radius)"
        if let category { urlString += "&category=\(category)" }
        
        var request = URLRequest(url: URL(string: urlString)!)
        let token = try await SupabaseManager.shared.client.auth.session.accessToken
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ListingsResponse.self, from: data).listings
    }
}
```

---

## Phase 5: Supabase Storage Setup

### 5.1 Create Storage Bucket

In Supabase Dashboard → Storage → Create bucket:
- Name: `listing-photos`
- Public: Yes (so photos load without auth)
- File size limit: 5MB
- Allowed MIME types: `image/jpeg, image/png, image/webp`

### 5.2 Storage Policy

```sql
-- Anyone authenticated can upload
CREATE POLICY "Authenticated users can upload photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'listing-photos');

-- Anyone can view photos (public bucket)
CREATE POLICY "Anyone can view listing photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'listing-photos');

-- Users can delete only their own photos
CREATE POLICY "Users can delete own photos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'listing-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
```

### 5.3 Upload Flow (iOS)

```swift
func uploadPhoto(imageData: Data, userId: String) async throws -> String {
    let fileName = "\(userId)/\(UUID().uuidString).jpg"
    
    try await SupabaseManager.shared.client.storage
        .from("listing-photos")
        .upload(
            path: fileName,
            file: imageData,
            options: FileOptions(contentType: "image/jpeg")
        )
    
    let publicURL = try SupabaseManager.shared.client.storage
        .from("listing-photos")
        .getPublicURL(path: fileName)
    
    return publicURL.absoluteString
}
```

---

## Phase 6: Row Level Security (Supabase)

```sql
-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;

-- Note: Since we access DB from Railway backend using service_role key,
-- RLS is bypassed by the backend. These policies are a safety net
-- for any direct Supabase client access.

-- Users can read any user's public info
CREATE POLICY "Public user profiles" ON users
    FOR SELECT USING (true);

-- Users can update only their own profile
CREATE POLICY "Users update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Anyone authenticated can read active listings
CREATE POLICY "Read active listings" ON listings
    FOR SELECT USING (status = 'active' OR user_id = auth.uid());

-- Users can insert their own listings
CREATE POLICY "Create own listings" ON listings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update/delete only their own listings
CREATE POLICY "Update own listings" ON listings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Delete own listings" ON listings
    FOR DELETE USING (auth.uid() = user_id);
```

---

## Phase 7: Deployment

### 7.1 Railway Deployment

1. Push `matshare-api` to GitHub
2. Connect Railway to GitHub repo
3. Add environment variables in Railway dashboard
4. Railway auto-deploys on push to `main`
5. Get the public URL: `https://matshare-api.up.railway.app`

### 7.2 Supabase Setup

1. Create new Supabase project
2. Run SQL migrations (PostGIS, tables, functions, RLS, storage)
3. Configure Auth provider (Apple Sign-In)
4. Create storage bucket for photos

### 7.3 iOS App Deployment

1. TestFlight for beta testing
2. App Store submission when ready

---

## Phase 8: Categories / Subcategories

### Materials
- Cement / concrete mix
- Paint / primer
- Tiles / ceramic
- Wood / lumber
- Drywall / plaster
- Insulation
- Pipes / plumbing
- Electrical (wire, outlets)
- Adhesives / sealants
- Sand / gravel
- Wallpaper
- Flooring
- Other materials

### Tools
- Power drills
- Saws
- Sanders
- Mixers
- Ladders
- Measuring tools
- Hand tools (hammers, screwdrivers)
- Painting tools (rollers, brushes)
- Tiling tools
- Welding equipment
- Safety gear
- Other tools

---

## Build Order for Claude Code

### Step 1: Backend API
1. Initialize Node.js project with Express
2. Set up PostgreSQL connection to Supabase
3. Create auth middleware (JWT verification)
4. Build listings CRUD endpoints
5. Build location search endpoint using PostGIS function
6. Build user profile endpoints
7. Add input validation and error handling
8. Test all endpoints

### Step 2: Database
1. Enable PostGIS on Supabase
2. Create users table
3. Create listings table with geography column
4. Create search_listings_nearby function
5. Set up RLS policies
6. Create storage bucket and policies
7. Seed with test data

### Step 3: iOS App
1. Create Xcode project with SwiftUI
2. Add Supabase Swift SDK
3. Build auth flow (Apple Sign-In)
4. Build location service
5. Build API service (connect to Railway backend)
6. Build listings feed screen (sorted by distance)
7. Build listing detail screen (call + directions)
8. Build create listing screen (photo + location + form)
9. Build my listings / profile screen
10. Add deep links (2GIS, Google Maps)
11. Polish UI and test

---

## Notes

- Apple Sign-In is the only auth method
- User adds phone number after first login (so buyers can call them)
- 2GIS is primary navigation app (default over Google Maps)
- No in-app chat — users call each other directly
- No WebSockets — simple REST API with pull-to-refresh
- Price in KZT (Kazakhstani Tenge), with "Free" option
- Show distance in km (rounded to 1 decimal)
- Photo limit: 3 photos per listing, max 5MB each
- Search radius default: 10 km, adjustable by user
