-- DropTable
PRAGMA foreign_keys=off;
DROP TABLE "UserInterest";
PRAGMA foreign_keys=on;

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
    CONSTRAINT "Property_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "Listing" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Property" ("isLookingForRoomate", "listing_id", "max_occupancy", "move_in_date", "move_out_date", "number_of_bathrooms", "number_of_bedrooms", "rating") SELECT "isLookingForRoomate", "listing_id", "max_occupancy", "move_in_date", "move_out_date", "number_of_bathrooms", "number_of_bedrooms", "rating" FROM "Property";
DROP TABLE "Property";
ALTER TABLE "new_Property" RENAME TO "Property";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
