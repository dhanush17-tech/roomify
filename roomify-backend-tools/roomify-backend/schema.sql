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
 

-- -- Disable foreign key checks
-- PRAGMA foreign_keys = OFF;

-- -- 1. Delete messages and chat data (dependent on users)
-- DELETE FROM UnreadMessage;
-- DELETE FROM ChatMessage;
-- DELETE FROM ChatParticipant;

-- -- 2. Delete roommate matching data (dependent on users)
-- DELETE FROM RoommateSwipe;
-- DELETE FROM RoommateMatch;

-- -- 3. Delete property-related data (dependent on Property)
-- DELETE FROM FloorPlan;
-- DELETE FROM PropertyImage;
-- DELETE FROM PropertyTag;
-- DELETE FROM PropertyAmenity;
-- DELETE FROM PropertyCategory;

-- -- 4. Delete marketplace-related data (dependent on MarketplaceItem)
-- DELETE FROM MarketplaceImage;
-- DELETE FROM MarketplaceCategory;

-- -- 5. Delete cross-entity relations
-- DELETE FROM Comment;
-- DELETE FROM PropertyLead;
-- DELETE FROM Favorite;
-- DELETE FROM Report;
-- DELETE FROM DocumentRequest;

-- -- 6. Delete user-specific data
-- DELETE FROM UserSocialLink;
-- DELETE FROM UserPreference;
-- DELETE FROM ActiveToken;
-- DELETE FROM PasswordReset;

-- -- 7. Delete main entities
-- DELETE FROM Property;
-- DELETE FROM MarketplaceItem;
-- DELETE FROM Listing;

-- -- 8. Finally, delete users
-- DELETE FROM User;

-- -- Reset auto-increment counters
-- UPDATE sqlite_sequence SET seq = 0;

-- -- Re-enable foreign key checks
-- PRAGMA foreign_keys = ON;

--Delete all ChatRooms

DELETE FROM UnreadMessage;

-- Delete all document submissions as they reference chat messages
DELETE FROM DocumentSubmission;

-- Delete all document requests as they reference chat messages
DELETE FROM DocumentRequest;

-- Delete all chat messages as they reference chat rooms
DELETE FROM ChatMessage;

-- Delete all chat participants as they reference chat rooms
DELETE FROM ChatParticipant;

-- Finally delete all chat rooms
DELETE FROM ChatRoom;