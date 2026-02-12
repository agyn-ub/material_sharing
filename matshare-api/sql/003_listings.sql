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
