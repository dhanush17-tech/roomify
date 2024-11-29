-- AlterTable
ALTER TABLE "User" ADD COLUMN "status" TEXT;

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Favorite" (
    "user_id" TEXT NOT NULL,
    "listing_id" INTEGER NOT NULL,
    "marketplace_item_listing_id" INTEGER,
    "property_id" INTEGER,

    PRIMARY KEY ("user_id", "listing_id"),
    CONSTRAINT "Favorite_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Favorite_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "Listing" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Favorite_marketplace_item_listing_id_fkey" FOREIGN KEY ("marketplace_item_listing_id") REFERENCES "marketplace_items" ("listingId") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Favorite_property_id_fkey" FOREIGN KEY ("property_id") REFERENCES "Property" ("listing_id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_Favorite" ("listing_id", "user_id") SELECT "listing_id", "user_id" FROM "Favorite";
DROP TABLE "Favorite";
ALTER TABLE "new_Favorite" RENAME TO "Favorite";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
