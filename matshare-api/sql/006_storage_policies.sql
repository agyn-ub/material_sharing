-- Run these in Supabase SQL Editor after creating the 'listing-photos' bucket

-- Authenticated users can upload photos
CREATE POLICY "Authenticated users can upload photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'listing-photos');

-- Anyone can view photos (public bucket)
CREATE POLICY "Anyone can view listing photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'listing-photos');

-- Users can delete only their own photos (folder = user id)
CREATE POLICY "Users can delete own photos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'listing-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
