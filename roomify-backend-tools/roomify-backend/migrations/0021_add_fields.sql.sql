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
CREATE TABLE "new_Property" (
    "listing_id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "number_of_bedrooms" INTEGER NOT NULL,
    "number_of_bathrooms" INTEGER NOT NULL,
    "max_occupancy" INTEGER NOT NULL,
    "isLookingForRoomate" BOOLEAN NOT NULL DEFAULT false,
    "rating" REAL NOT NULL DEFAULT 0.0,
    "move_in_date" TEXT,
    "move_out_date" TEXT,
    "isRoomifyChoice" BOOLEAN NOT NULL DEFAULT false,
    "walk_score" INTEGER DEFAULT 0,
    "transit_details" TEXT DEFAULT '[]',
    "last_location_details_update" DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Property_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "Listing" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Property" ("isLookingForRoomate", "isRoomifyChoice", "last_location_details_update", "listing_id", "max_occupancy", "move_in_date", "move_out_date", "number_of_bathrooms", "number_of_bedrooms", "rating", "transit_details", "walk_score") SELECT "isLookingForRoomate", "isRoomifyChoice", "last_location_details_update", "listing_id", "max_occupancy", "move_in_date", "move_out_date", "number_of_bathrooms", "number_of_bedrooms", "rating", "transit_details", "walk_score" FROM "Property";
DROP TABLE "Property";
ALTER TABLE "new_Property" RENAME TO "Property";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
