-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
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
    "isProfessional" BOOLEAN NOT NULL DEFAULT false,
    "isAnonymous" BOOLEAN NOT NULL DEFAULT false,
    "phoneNumber" TEXT
);
INSERT INTO "new_User" ("age", "bio", "created_at", "display_name", "email", "fcmToken", "gender", "id", "isAdmin", "isProfessional", "language", "latitude", "location", "longitude", "password_hash", "phoneNumber", "profile_image_url", "receive_notifications", "status", "university") SELECT "age", "bio", "created_at", "display_name", "email", "fcmToken", "gender", "id", "isAdmin", "isProfessional", "language", "latitude", "location", "longitude", "password_hash", "phoneNumber", "profile_image_url", "receive_notifications", "status", "university" FROM "User";
DROP TABLE "User";
ALTER TABLE "new_User" RENAME TO "User";
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
