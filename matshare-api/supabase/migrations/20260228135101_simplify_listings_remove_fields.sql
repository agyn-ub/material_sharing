-- Simplify listings: remove category, subcategory, quantity, unit, residential_complex

-- 1. Drop NOT NULL and CHECK constraint on category, set default
ALTER TABLE listings ALTER COLUMN category DROP NOT NULL;
ALTER TABLE listings ALTER COLUMN category SET DEFAULT 'materials';
ALTER TABLE listings DROP CONSTRAINT IF EXISTS listings_category_check;

-- 2. Drop unused columns
ALTER TABLE listings DROP COLUMN IF EXISTS subcategory;
ALTER TABLE listings DROP COLUMN IF EXISTS quantity;
ALTER TABLE listings DROP COLUMN IF EXISTS unit;
ALTER TABLE listings DROP COLUMN IF EXISTS residential_complex;

-- 3. Drop category index (no longer filtering by category)
DROP INDEX IF EXISTS idx_listings_category;

-- 4. Recreate search function without removed columns
DROP FUNCTION IF EXISTS search_listings_nearby;

CREATE OR REPLACE FUNCTION search_listings_nearby(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_meters INTEGER DEFAULT 10000,
    category_filter VARCHAR DEFAULT NULL,
    search_text VARCHAR DEFAULT NULL,
    limit_count INTEGER DEFAULT 50,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    title VARCHAR,
    description TEXT,
    category VARCHAR,
    price DECIMAL,
    currency VARCHAR,
    is_free BOOLEAN,
    photo_urls TEXT[],
    address_text VARCHAR,
    status VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE,
    distance_meters DOUBLE PRECISION,
    seller_name VARCHAR,
    seller_phone VARCHAR,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION
)
LANGUAGE SQL STABLE
AS $$
    SELECT
        l.id, l.user_id, l.title, l.description,
        l.category,
        l.price, l.currency, l.is_free, l.photo_urls,
        l.address_text, l.status, l.created_at,
        ST_Distance(
            l.location,
            ST_MakePoint(user_lng, user_lat)::geography
        ) AS distance_meters,
        u.name AS seller_name,
        u.phone AS seller_phone,
        ST_Y(l.location::geometry) AS latitude,
        ST_X(l.location::geometry) AS longitude
    FROM listings l
    JOIN users u ON l.user_id = u.id
    WHERE l.status = 'active'
      AND ST_DWithin(
          l.location,
          ST_MakePoint(user_lng, user_lat)::geography,
          radius_meters
      )
      AND (category_filter IS NULL OR l.category = category_filter)
      AND (search_text IS NULL OR l.title ILIKE '%' || search_text || '%')
    ORDER BY distance_meters ASC
    LIMIT limit_count
    OFFSET offset_count;
$$;
