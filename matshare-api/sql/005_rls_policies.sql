-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;

-- Users can read any user's public info
CREATE POLICY "Public user profiles" ON users
    FOR SELECT USING (true);

-- Users can update only their own profile
CREATE POLICY "Users update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Anyone authenticated can read active listings (or their own)
CREATE POLICY "Read active listings" ON listings
    FOR SELECT USING (status = 'active' OR user_id = auth.uid());

-- Users can insert their own listings
CREATE POLICY "Create own listings" ON listings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update only their own listings
CREATE POLICY "Update own listings" ON listings
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete only their own listings
CREATE POLICY "Delete own listings" ON listings
    FOR DELETE USING (auth.uid() = user_id);
