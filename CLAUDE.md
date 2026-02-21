# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MatShare is a construction materials marketplace connecting people with leftover materials/tools to those who need small quantities. Core feature is GPS-based distance search for nearby listings.

The repo name is `renewing_flat` but the project is called **MatShare**. It contains two independent sub-projects (no monorepo tooling):

- `matshare-api/` — Node.js/Express REST API (deployed on Railway)
- `renewing_ios/` — iOS app in Swift/SwiftUI (separate git repo inside this directory)

## Common Commands

### Backend (matshare-api/)

```bash
# Install dependencies
cd matshare-api && npm install

# Run dev server with hot reload
npm run dev

# Run production server
npm start
```

The API runs on `PORT` from `.env` (default 3000). No test framework is configured yet.

### iOS App (renewing_ios/)

Open `renewing_ios/renewing_ios.xcodeproj` in Xcode. The project uses Swift Package Manager for dependencies (Supabase Swift SDK). Minimum target: iOS 16.0.

## Architecture

### Backend API (`matshare-api/src/`)

Standard Express MVC pattern:

- `server.js` — Entry point. Mounts routes at `/api/listings` and `/api/users`. Serves static files from `public/` (privacy policy, support pages for App Store)
- `config/db.js` — PostgreSQL connection pool using `pg`, connects to Supabase Postgres with SSL in production
- `middleware/auth.js` — JWT verification using JWKS (ES256 public keys fetched from Supabase). Attaches `req.user.id` (from JWT `sub`) and `req.user.email`
- `controllers/listingsController.js` — All listing logic: nearby search via PostGIS `search_listings_nearby()` SQL function, CRUD with ownership checks
- `controllers/usersController.js` — Profile upsert (INSERT...ON CONFLICT), get own profile, get public profile
- `routes/` — Thin route files, all routes require auth middleware
- `utils/helpers.js` — Validation helpers. Defines valid categories (`materials`, `tools`), units, and statuses (`active`, `sold`, `reserved`, `expired`)

All endpoints require Bearer token auth. The backend uses the Supabase service role key to bypass RLS and queries Postgres directly via connection string.

### Database (Supabase PostgreSQL + PostGIS)

Two tables: `users` (UUID PK referencing `auth.users`) and `listings` (with `GEOGRAPHY(POINT, 4326)` column, plus `residential_complex VARCHAR(200)`). The key spatial query is the `search_listings_nearby()` function which uses `ST_DWithin` for radius search, `ST_Distance` for sorting by distance, and supports optional `search_text` for title ILIKE filtering.

Location is stored as PostGIS geography but sent to/from the API as separate `latitude`/`longitude` fields. The controller converts between these using `ST_MakePoint(lng, lat)::geography` on write and `ST_Y/ST_X(location::geometry)` on read.

SQL migrations live in `matshare-api/supabase/migrations/` — apply them via Supabase dashboard or CLI. When modifying the `search_listings_nearby()` function, you must DROP and recreate it since its return type includes all columns.

### iOS App (`renewing_ios/renewing_ios/`)

- `Config/Config.swift` — API base URL (Railway), Supabase client init, app constants
- `Services/AuthService.swift` — Singleton wrapping Supabase Auth (Apple Sign-In only). Provides `getAccessToken()` for API calls
- `Services/APIService.swift` — Singleton REST client. All requests go through `authorizedRequest()` which attaches the Supabase JWT
- `Services/LocationService.swift` — CLLocationManager wrapper
- `Services/StorageService.swift` — Supabase Storage for photo uploads to `listing-photos` bucket
- `App/AppState.swift` — Global state: profile loading and setup flow
- `Views/` — SwiftUI views organized by feature: Auth, Listings, CreateListing, Profile, Components
- `Utilities/DeepLinks.swift` — Opens directions in 2GIS > Google Maps > Apple Maps (priority order)

### Auth Flow

1. User taps "Sign in with Apple" in iOS app
2. Supabase Auth SDK handles Apple Sign-In, returns JWT
3. All API calls include JWT as Bearer token
4. Backend verifies JWT with Supabase JWT secret, extracts user ID from `sub` claim

## Key Design Decisions

- No in-app chat — users call sellers directly via phone
- No WebSockets — simple REST with pull-to-refresh
- Photos uploaded directly to Supabase Storage from iOS, URLs stored in `photo_urls TEXT[]` on listings
- Currency is KZT (Kazakhstani Tenge) with a "Free" option
- 2GIS is the preferred navigation app (Kazakhstan market)
- Search radius default: 10km, max: 50km
- Max 3 photos per listing, 5MB each

## Environment Variables (matshare-api/.env)

```
PORT=3000
DATABASE_URL=postgresql://...
SUPABASE_URL=https://[project-ref].supabase.co
SUPABASE_SERVICE_KEY=...
```
