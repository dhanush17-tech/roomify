-- CreateTable
CREATE TABLE "PropertyLead" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "userId" TEXT NOT NULL,
    "propertyId" INTEGER NOT NULL,
    "viewCount" INTEGER NOT NULL DEFAULT 1,
    "lastViewed" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PropertyLead_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "PropertyLead_propertyId_fkey" FOREIGN KEY ("propertyId") REFERENCES "Listing" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_ChatMessage" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "type" TEXT NOT NULL DEFAULT 'TEXT',
    "content" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "roomId" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    CONSTRAINT "ChatMessage_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES "ChatRoom" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "ChatMessage_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_ChatMessage" ("content", "createdAt", "id", "roomId", "senderId", "type") SELECT "content", "createdAt", "id", "roomId", "senderId", "type" FROM "ChatMessage";
DROP TABLE "ChatMessage";
ALTER TABLE "new_ChatMessage" RENAME TO "ChatMessage";
CREATE TABLE "new_User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "display_name" TEXT NOT NULL,
    "profile_image_url" TEXT,
    "bio" TEXT,
    "email" TEXT NOT NULL,
    "language" TEXT NOT NULL DEFAULT 'English',
    "receive_notifications" BOOLEAN NOT NULL DEFAULT true,
    "password_hash" TEXT NOT NULL,
    "university" TEXT,
    "age" INTEGER,
    "gender" TEXT,
    "location" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "latitude" REAL,
    "longitude" REAL,
    "status" TEXT,
    "fcmToken" TEXT,
    "isAdmin" BOOLEAN NOT NULL DEFAULT false,
    "isProfessional" BOOLEAN NOT NULL DEFAULT false
);
INSERT INTO "new_User" ("age", "bio", "created_at", "display_name", "email", "fcmToken", "gender", "id", "isAdmin", "language", "latitude", "location", "longitude", "password_hash", "profile_image_url", "receive_notifications", "status", "university") SELECT "age", "bio", "created_at", "display_name", "email", "fcmToken", "gender", "id", "isAdmin", "language", "latitude", "location", "longitude", "password_hash", "profile_image_url", "receive_notifications", "status", "university" FROM "User";
DROP TABLE "User";
ALTER TABLE "new_User" RENAME TO "User";
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;

-- CreateIndex
CREATE INDEX "PropertyLead_userId_idx" ON "PropertyLead"("userId");

-- CreateIndex
CREATE INDEX "PropertyLead_propertyId_idx" ON "PropertyLead"("propertyId");

-- CreateIndex
CREATE UNIQUE INDEX "PropertyLead_userId_propertyId_key" ON "PropertyLead"("userId", "propertyId");
