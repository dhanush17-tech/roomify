-- -- Drop existing tables if they exist
-- DROP TABLE IF EXISTS favorites;
-- DROP TABLE IF EXISTS comments;
-- DROP TABLE IF EXISTS property_images;
-- DROP TABLE IF EXISTS property_tags;
-- DROP TABLE IF EXISTS property_amenities;
-- DROP TABLE IF EXISTS properties;
-- DROP TABLE IF EXISTS listings;
-- DROP TABLE IF EXISTS password_resets;
-- DROP TABLE IF EXISTS users;

-- -- Users table
-- CREATE TABLE users (
--   id TEXT PRIMARY KEY,
--   username TEXT UNIQUE NOT NULL,
--   display_name TEXT NOT NULL,
--   profile_image_url TEXT,
--   bio TEXT,
--   email TEXT UNIQUE NOT NULL,
--   language TEXT DEFAULT 'English',
--   receive_notifications BOOLEAN DEFAULT true,
--   password_hash TEXT NOT NULL,
--   university TEXT,
--   age INTEGER,
--   gender TEXT,
--   location TEXT,
--   is_professional BOOLEAN DEFAULT false,
--   created_at DATETIME DEFAULT CURRENT_TIMESTAMP
-- );

-- -- Password resets table
-- CREATE TABLE password_resets (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   user_id TEXT NOT NULL,
--   token TEXT NOT NULL,
--   created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
--   expires_at DATETIME NOT NULL,
--   FOREIGN KEY (user_id) REFERENCES users(id)
-- );

-- -- Listings table
-- CREATE TABLE listings (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   type TEXT NOT NULL,
--   title TEXT NOT NULL,
--   description TEXT,
--   created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
--   user_id TEXT NOT NULL,
--   location TEXT NOT NULL,
--   price REAL NOT NULL,
--   category TEXT,
--   FOREIGN KEY (user_id) REFERENCES users(id)
-- );

-- -- Properties table
-- CREATE TABLE properties (
--   listing_id INTEGER PRIMARY KEY,
--   number_of_rooms INTEGER NOT NULL,
--   FOREIGN KEY (listing_id) REFERENCES listings(id)
-- );

-- -- Property amenities
-- CREATE TABLE property_amenities (
--   property_id INTEGER,
--   amenity TEXT NOT NULL,
--   FOREIGN KEY (property_id) REFERENCES properties(listing_id),
--   PRIMARY KEY (property_id, amenity)
-- );

-- -- Property tags
-- CREATE TABLE property_tags (
--   property_id INTEGER,
--   tag TEXT NOT NULL,
--   FOREIGN KEY (property_id) REFERENCES properties(listing_id),
--   PRIMARY KEY (property_id, tag)
-- );

-- -- Property images
-- CREATE TABLE property_images (
--   property_id INTEGER,
--   image_url TEXT NOT NULL,
--   FOREIGN KEY (property_id) REFERENCES properties(listing_id),
--   PRIMARY KEY (property_id, image_url)
-- );

-- -- Comments
-- CREATE TABLE comments (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   property_id INTEGER,
--   user_id TEXT NOT NULL,
--   comment TEXT NOT NULL,
--   created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
--   FOREIGN KEY (property_id) REFERENCES properties(listing_id),
--   FOREIGN KEY (user_id) REFERENCES users(id)
-- );

-- -- Favorites
-- CREATE TABLE favorites (
--   user_id TEXT,
--   listing_id INTEGER,
--   FOREIGN KEY (user_id) REFERENCES users(id),
--   FOREIGN KEY (listing_id) REFERENCES listings(id),
--   PRIMARY KEY (user_id, listing_id)
-- );

-- -- Create indexes for better performance
-- CREATE INDEX idx_listings_user_id ON listings(user_id);
-- CREATE INDEX idx_properties_listing_id ON properties(listing_id);
-- CREATE INDEX idx_comments_property_id ON comments(property_id);
-- CREATE INDEX idx_comments_user_id ON comments(user_id);
-- CREATE INDEX idx_favorites_user_id ON favorites(user_id);
-- CREATE INDEX idx_favorites_listing_id ON favorites(listing_id);

-- CREATE TABLE IF NOT EXISTS active_tokens (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   token_hash TEXT UNIQUE NOT NULL,
--   user_id TEXT NOT NULL,
--   expires_at DATETIME NOT NULL,
--   created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
--   FOREIGN KEY (user_id) REFERENCES users(id)
-- );
-- CREATE INDEX IF NOT EXISTS idx_token_hash ON active_tokens(token_hash);
-- CREATE INDEX IF NOT EXISTS idx_expires_at ON active_tokens(expires_at);


-- -- Add this to your schema.sql file
-- CREATE TABLE IF NOT EXISTS property_categories (
--   property_id INTEGER,
--   category TEXT NOT NULL,
--   FOREIGN KEY (property_id) REFERENCES properties(listing_id),
--   PRIMARY KEY (property_id, category)
-- );

-- -- Add an index for better performance
-- CREATE INDEX IF NOT EXISTS idx_property_categories_property_id 
-- ON property_categories(property_id);

-- UPDATE user
-- SET latitude = CAST(0.1 AS DOUBLE), longitude = CAST(0.1 AS DOUBLE);

-- UPDATE listing
-- SET latitude = CAST(0.1 AS DOUBLE), longitude = CAST(0.1 AS DOUBLE);

-- Check all document requests with related messages and users

-- Check if messages are being created with correct type

-- Delete all listings and related data
SELECT property_id FROM Favorite WHERE property_id NOT IN (SELECT id FROM Property);