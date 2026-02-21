-- Add residential_complex column to listings
ALTER TABLE listings ADD COLUMN residential_complex VARCHAR(200);

-- Recreate search_listings_nearby with residential_complex field
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
    subcategory VARCHAR,
    quantity DECIMAL,
    unit VARCHAR,
    price DECIMAL,
    currency VARCHAR,
    is_free BOOLEAN,
    photo_urls TEXT[],
    address_text VARCHAR,
    residential_complex VARCHAR,
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
        l.category, l.subcategory, l.quantity, l.unit,
        l.price, l.currency, l.is_free, l.photo_urls,
        l.address_text, l.residential_complex, l.status, l.created_at,
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
