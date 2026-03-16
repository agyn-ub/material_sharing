-- Make radius optional in search_listings_nearby for global fallback
-- When radius_meters is NULL, return all active listings (no distance filter)

DROP FUNCTION IF EXISTS search_listings_nearby;

CREATE OR REPLACE FUNCTION search_listings_nearby(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_meters INTEGER DEFAULT 10000,
    search_text VARCHAR DEFAULT NULL,
    limit_count INTEGER DEFAULT 50,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    title VARCHAR,
    description TEXT,
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
      AND (radius_meters IS NULL OR ST_DWithin(
          l.location,
          ST_MakePoint(user_lng, user_lat)::geography,
          radius_meters
      ))
      AND (search_text IS NULL OR l.title ILIKE '%' || search_text || '%')
    ORDER BY
        CASE WHEN radius_meters IS NULL THEN l.created_at END DESC,
        CASE WHEN radius_meters IS NOT NULL THEN ST_Distance(
            l.location,
            ST_MakePoint(user_lng, user_lat)::geography
        ) END ASC
    LIMIT limit_count
    OFFSET offset_count;
$$;
