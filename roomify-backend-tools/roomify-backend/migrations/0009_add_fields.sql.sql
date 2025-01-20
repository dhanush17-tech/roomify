-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Listing" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "user_id" TEXT NOT NULL,
    "location" TEXT NOT NULL,
    "price" REAL NOT NULL,
    "category" TEXT,
    "latitude" REAL,
    "longitude" REAL,
    "isFavorite" BOOLEAN NOT NULL DEFAULT false,
    "reported" BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT "Listing_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Listing" ("category", "created_at", "description", "id", "isFavorite", "latitude", "location", "longitude", "price", "reported", "title", "type", "user_id") SELECT "category", "created_at", "description", "id", "isFavorite", "latitude", "location", "longitude", "price", "reported", "title", "type", "user_id" FROM "Listing";
DROP TABLE "Listing";
ALTER TABLE "new_Listing" RENAME TO "Listing";
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
    "isAdmin" BOOLEAN NOT NULL DEFAULT true
);
INSERT INTO "new_User" ("age", "bio", "created_at", "display_name", "email", "fcmToken", "gender", "id", "language", "latitude", "location", "longitude", "password_hash", "profile_image_url", "receive_notifications", "status", "university") SELECT "age", "bio", "created_at", "display_name", "email", "fcmToken", "gender", "id", "language", "latitude", "location", "longitude", "password_hash", "profile_image_url", "receive_notifications", "status", "university" FROM "User";
DROP TABLE "User";
ALTER TABLE "new_User" RENAME TO "User";
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
