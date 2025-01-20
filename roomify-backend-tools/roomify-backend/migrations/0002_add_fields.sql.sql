-- -- CreateTable
-- CREATE TABLE "User" (
--     "id" TEXT NOT NULL PRIMARY KEY,
--     "display_name" TEXT NOT NULL,
--     "profile_image_url" TEXT,
--     "bio" TEXT,
--     "email" TEXT NOT NULL,
--     "language" TEXT NOT NULL DEFAULT 'English',
--     "receive_notifications" BOOLEAN NOT NULL DEFAULT true,
--     "password_hash" TEXT NOT NULL,
--     "university" TEXT,
--     "age" INTEGER,
--     "gender" TEXT,
--     "location" TEXT,
--     "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
--     "latitude" REAL,
--     "longitude" REAL,
--     "status" TEXT,
--     "fcmToken" TEXT
-- );

-- -- CreateTable
-- CREATE TABLE "PasswordReset" (
--     "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
--     "user_id" TEXT NOT NULL,
--     "token" TEXT NOT NULL,
--     "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
--     "expires_at" DATETIME NOT NULL,
--     CONSTRAINT "PasswordReset_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "Listing" (
--     "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
--     "type" TEXT NOT NULL,
--     "title" TEXT NOT NULL,
--     "description" TEXT,
--     "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
--     "user_id" TEXT NOT NULL,
--     "location" TEXT NOT NULL,
--     "price" REAL NOT NULL,
--     "category" TEXT,
--     "latitude" REAL,
--     "longitude" REAL,
--     "isFavorite" BOOLEAN NOT NULL DEFAULT false,
--     CONSTRAINT "Listing_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "Property" (
--     "listing_id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
--     "number_of_bedrooms" INTEGER NOT NULL,
--     "number_of_bathrooms" INTEGER NOT NULL,
--     "max_occupancy" INTEGER NOT NULL,
--     "isLookingForRoomate" BOOLEAN NOT NULL DEFAULT false,
--     "rating" REAL NOT NULL DEFAULT 0.0,
--     "move_in_date" TEXT,
--     "move_out_date" TEXT,
--     CONSTRAINT "Property_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "Listing" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "PropertyAmenity" (
--     "property_id" INTEGER NOT NULL,
--     "amenity" TEXT NOT NULL,

--     PRIMARY KEY ("property_id", "amenity"),
--     CONSTRAINT "PropertyAmenity_property_id_fkey" FOREIGN KEY ("property_id") REFERENCES "Property" ("listing_id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "PropertyTag" (
--     "property_id" INTEGER NOT NULL,
--     "tag" TEXT NOT NULL,

--     PRIMARY KEY ("property_id", "tag"),
--     CONSTRAINT "PropertyTag_property_id_fkey" FOREIGN KEY ("property_id") REFERENCES "Property" ("listing_id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "PropertyImage" (
--     "property_id" INTEGER NOT NULL,
--     "image_url" TEXT NOT NULL,

--     PRIMARY KEY ("property_id", "image_url"),
--     CONSTRAINT "PropertyImage_property_id_fkey" FOREIGN KEY ("property_id") REFERENCES "Property" ("listing_id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "PropertyCategory" (
--     "property_id" INTEGER NOT NULL,
--     "category" TEXT NOT NULL,

--     PRIMARY KEY ("property_id", "category"),
--     CONSTRAINT "PropertyCategory_property_id_fkey" FOREIGN KEY ("property_id") REFERENCES "Property" ("listing_id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "marketplace_items" (
--     "listingId" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
--     CONSTRAINT "marketplace_items_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "Listing" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "marketplace_categories" (
--     "item_id" INTEGER NOT NULL,
--     "category" TEXT NOT NULL,

--     PRIMARY KEY ("item_id", "category"),
--     CONSTRAINT "marketplace_categories_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "marketplace_items" ("listingId") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "MarketplaceImage" (
--     "item_id" INTEGER NOT NULL,
--     "image_url" TEXT NOT NULL,

--     PRIMARY KEY ("item_id", "image_url"),
--     CONSTRAINT "MarketplaceImage_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "marketplace_items" ("listingId") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "Comment" (
--     "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
--     "property_id" INTEGER NOT NULL,
--     "user_id" TEXT NOT NULL,
--     "comment" TEXT NOT NULL,
--     "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
--     CONSTRAINT "Comment_property_id_fkey" FOREIGN KEY ("property_id") REFERENCES "Property" ("listing_id") ON DELETE RESTRICT ON UPDATE CASCADE,
--     CONSTRAINT "Comment_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "Favorite" (
--     "user_id" TEXT NOT NULL,
--     "listing_id" INTEGER NOT NULL,
--     "marketplace_item_listing_id" INTEGER,
--     "property_id" INTEGER,

--     PRIMARY KEY ("user_id", "listing_id"),
--     CONSTRAINT "Favorite_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
--     CONSTRAINT "Favorite_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "Listing" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
--     CONSTRAINT "Favorite_marketplace_item_listing_id_fkey" FOREIGN KEY ("marketplace_item_listing_id") REFERENCES "marketplace_items" ("listingId") ON DELETE SET NULL ON UPDATE CASCADE,
--     CONSTRAINT "Favorite_property_id_fkey" FOREIGN KEY ("property_id") REFERENCES "Property" ("listing_id") ON DELETE SET NULL ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "ActiveToken" (
--     "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
--     "token_hash" TEXT NOT NULL,
--     "user_id" TEXT NOT NULL,
--     "expires_at" DATETIME NOT NULL,
--     "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
--     CONSTRAINT "ActiveToken_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "RoommateSwipe" (
--     "id" TEXT NOT NULL PRIMARY KEY,
--     "swiperId" TEXT NOT NULL,
--     "swipedId" TEXT NOT NULL,
--     "direction" TEXT NOT NULL,
--     "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
--     CONSTRAINT "RoommateSwipe_swiperId_fkey" FOREIGN KEY ("swiperId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
--     CONSTRAINT "RoommateSwipe_swipedId_fkey" FOREIGN KEY ("swipedId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "RoommateMatch" (
--     "id" TEXT NOT NULL PRIMARY KEY,
--     "user1Id" TEXT NOT NULL,
--     "user2Id" TEXT NOT NULL,
--     "matchedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
--     CONSTRAINT "RoommateMatch_user1Id_fkey" FOREIGN KEY ("user1Id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
--     CONSTRAINT "RoommateMatch_user2Id_fkey" FOREIGN KEY ("user2Id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "UserPreference" (
--     "user_id" TEXT NOT NULL,
--     "preference" TEXT NOT NULL,

--     PRIMARY KEY ("user_id", "preference"),
--     CONSTRAINT "UserPreference_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "UserSocialLink" (
--     "user_id" TEXT NOT NULL,
--     "platform" TEXT NOT NULL,
--     "username" TEXT NOT NULL,

--     PRIMARY KEY ("user_id", "platform"),
--     CONSTRAINT "UserSocialLink_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "ChatRoom" (
--     "id" TEXT NOT NULL PRIMARY KEY,
--     "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
--     "updatedAt" DATETIME NOT NULL
-- );

-- -- CreateTable
-- CREATE TABLE "ChatParticipant" (
--     "userId" TEXT NOT NULL,
--     "roomId" TEXT NOT NULL,

--     PRIMARY KEY ("userId", "roomId"),
--     CONSTRAINT "ChatParticipant_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
--     CONSTRAINT "ChatParticipant_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES "ChatRoom" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "ChatMessage" (
--     "id" TEXT NOT NULL PRIMARY KEY,
--     "content" TEXT NOT NULL,
--     "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
--     "roomId" TEXT NOT NULL,
--     "senderId" TEXT NOT NULL,
--     CONSTRAINT "ChatMessage_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES "ChatRoom" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
--     CONSTRAINT "ChatMessage_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateTable
-- CREATE TABLE "UnreadMessage" (
--     "id" TEXT NOT NULL PRIMARY KEY,
--     "roomId" TEXT NOT NULL,
--     "messageId" TEXT NOT NULL,
--     "recipientId" TEXT NOT NULL,
--     "isRead" BOOLEAN NOT NULL DEFAULT false,
--     "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
--     CONSTRAINT "UnreadMessage_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES "ChatRoom" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
--     CONSTRAINT "UnreadMessage_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "ChatMessage" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
--     CONSTRAINT "UnreadMessage_recipientId_fkey" FOREIGN KEY ("recipientId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
-- );

-- -- CreateIndex
-- CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- -- CreateIndex
-- CREATE UNIQUE INDEX "ActiveToken_token_hash_key" ON "ActiveToken"("token_hash");

-- -- CreateIndex
-- CREATE UNIQUE INDEX "RoommateSwipe_swiperId_swipedId_key" ON "RoommateSwipe"("swiperId", "swipedId");

-- -- CreateIndex
-- CREATE UNIQUE INDEX "RoommateMatch_user1Id_user2Id_key" ON "RoommateMatch"("user1Id", "user2Id");

-- -- CreateIndex
-- CREATE INDEX "UnreadMessage_roomId_idx" ON "UnreadMessage"("roomId");

-- -- CreateIndex
-- CREATE INDEX "UnreadMessage_messageId_idx" ON "UnreadMessage"("messageId");

-- -- CreateIndex
-- CREATE INDEX "UnreadMessage_recipientId_idx" ON "UnreadMessage"("recipientId");
