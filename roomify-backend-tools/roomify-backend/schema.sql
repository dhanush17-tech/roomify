-- --  give me the code to delete all listings

-- -- Delete all related data first to handle foreign key constraints
-- DELETE FROM PropertyLead;
-- DELETE FROM Comment;
-- DELETE FROM Favorite;
-- DELETE FROM Reports;

-- -- Delete property-related data
-- DELETE FROM PropertyImage;
-- DELETE FROM PropertyTag;
-- DELETE FROM PropertyAmenity;
-- DELETE FROM PropertyCategory;
-- DELETE FROM FloorPlan;
-- DELETE FROM Property;

-- -- Delete marketplace-related data
-- DELETE FROM MarketplaceImage;
-- DELETE FROM marketplace_categories;
-- DELETE FROM marketplace_items;

-- -- Finally, delete the listings
-- DELETE FROM Listing;

-- -- Reset the auto-increment counters
-- UPDATE sqlite_sequence SET seq = 0 WHERE name = 'Listing';
-- UPDATE sqlite_sequence SET seq = 0 WHERE name = 'Property';
-- UPDATE sqlite_sequence SET seq = 0 WHERE name = 'MarketplaceItem';
-- UPDATE sqlite_sequence SET seq = 0 WHERE name = 'PropertyLead';
-- UPDATE sqlite_sequence SET seq = 0 WHERE name = 'Comment';
-- UPDATE sqlite_sequence SET seq = 0 WHERE name = 'Report';

Select * from user;