-- ============================================
-- MatShare: Initial Schema Migration
-- ============================================

-- 1. Enable PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Users table
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone);

-- 3. Listings table
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

-- 4. Spatial search function
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

-- 5. Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public user profiles" ON users
    FOR SELECT USING (true);

CREATE POLICY "Users update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Read active listings" ON listings
    FOR SELECT USING (status = 'active' OR user_id = auth.uid());

CREATE POLICY "Create own listings" ON listings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Update own listings" ON listings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Delete own listings" ON listings
    FOR DELETE USING (auth.uid() = user_id);

-- 6. Storage bucket policies (bucket must be created first via dashboard or API)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('listing-photos', 'listing-photos', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Authenticated users can upload photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'listing-photos');

CREATE POLICY "Anyone can view listing photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'listing-photos');

CREATE POLICY "Users can delete own photos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'listing-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
