# Lessons Learned — MatShare Development

Problems encountered during development. Reference this in future similar projects.

## 1. PostgreSQL returns numbers as strings
The `pg` driver returns NUMERIC/DECIMAL columns as strings, not JS numbers. Every response needed `parseFloat()` wrappers in `formatListing()`. **Fix:** either use `pg-types` to override parsers globally, or define columns as `DOUBLE PRECISION` instead of `NUMERIC`.

## 2. Price: 0 vs null vs "free"
`price || 0` in create vs `price || null` in update caused inconsistency. Zero price should mean "free" but JS falsy coercion treats `0` same as `null`. **Fix:** use explicit checks (`price !== undefined && price !== null`) instead of `||`.

## 3. JWT verification flow (Supabase + Express)
Supabase switched from HS256 (symmetric) to ES256 (asymmetric) JWTs. The initial `jsonwebtoken.verify()` with `SUPABASE_JWT_SECRET` broke silently. Had to decode header first, fetch JWKS public key, then verify. **Fix:** check Supabase project's JWT algorithm upfront; use `jwks-rsa` for ES256 projects.

## 4. iOS location permission race condition
Calling `requestPermission()` then immediately `getCurrentLocation()` doesn't work — permission dialog is async. Location returns nil until user approves. **Fix:** use `onChange(of: authorizationStatus)` to trigger location fetch only after permission is granted.

## 5. Photo upload fire-and-forget
`loadPhotos()` spawns independent Tasks per photo with no completion tracking. User can tap "Post" before photos finish loading, resulting in missing images. **Fix:** track loading state with a counter or use `TaskGroup`, disable submit until all photos are loaded.

## 6. Orphaned storage files
When deleting a listing, Supabase Storage cleanup is wrapped in try-catch that silently swallows errors. If cleanup fails, photos stay forever with no reference. **Fix:** log orphaned paths to a cleanup queue table, or run periodic storage audits.

## 7. Supabase auth token expiration
`getAccessToken()` returns `session.accessToken` without checking expiry. When JWT expires, all API calls fail with 401 and user gets stuck. Supabase Swift SDK does handle refresh internally via `session`, but the error path doesn't trigger re-auth gracefully. **Fix:** catch 401 in APIService and trigger `supabase.auth.refreshSession()` before retrying.

## 8. Localization over-engineering
Built full String Catalog (kk/ru/en) + in-app language switcher early on, then had to rip it all out. Every string went through `String(localized:bundle:)` with a custom `LanguageManager`. **Fix:** start with hardcoded strings in your primary language. Add localization only when you actually need a second language.

## 9. Tab bar "create" hack
Middle tab is an empty `Text("")` that triggers a sheet then resets selection to tab 0. Works but fragile. **Fix:** this is a known SwiftUI pattern; just document it clearly. Alternative: use a floating action button instead.

## 10. Profile fetch error = "needs setup"
Any error from profile fetch (network, 500, timeout) sets `needsProfileSetup = true`, sending existing users to the setup screen. **Fix:** only treat 404 as "needs setup"; show retry UI for other errors.

## 11. Supabase keys in source code
Supabase URL and anon key are hardcoded in `Config.swift`. They're designed to be public, but still shouldn't be in git history for production apps. **Fix:** use xcconfig files or Info.plist with build-time substitution.

## 12. No input validation on lat/lng
Backend `validateListing()` checks presence but not numeric validity. Passing `"abc"` for latitude passes validation, then `parseFloat` returns `NaN`, and PostGIS query breaks. **Fix:** validate with `!isNaN(parseFloat(lat))` and range checks (-90 to 90, -180 to 180).
