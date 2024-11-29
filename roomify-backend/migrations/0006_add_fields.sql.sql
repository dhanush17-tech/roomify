-- CreateTable
CREATE TABLE "marketplace_items" (
    "listingId" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    CONSTRAINT "marketplace_items_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "Listing" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "marketplace_categories" (
    "item_id" INTEGER NOT NULL,
    "category" TEXT NOT NULL,

    PRIMARY KEY ("item_id", "category"),
    CONSTRAINT "marketplace_categories_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "marketplace_items" ("listingId") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "MarketplaceImage" (
    "item_id" INTEGER NOT NULL,
    "image_url" TEXT NOT NULL,

    PRIMARY KEY ("item_id", "image_url"),
    CONSTRAINT "MarketplaceImage_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "marketplace_items" ("listingId") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Favorite" (
    "user_id" TEXT NOT NULL,
    "listing_id" INTEGER NOT NULL,
    "marketplaceItemListingId" INTEGER,

    PRIMARY KEY ("user_id", "listing_id"),
    CONSTRAINT "Favorite_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Favorite_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "Listing" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Favorite_marketplaceItemListingId_fkey" FOREIGN KEY ("marketplaceItemListingId") REFERENCES "marketplace_items" ("listingId") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_Favorite" ("listing_id", "user_id") SELECT "listing_id", "user_id" FROM "Favorite";
DROP TABLE "Favorite";
ALTER TABLE "new_Favorite" RENAME TO "Favorite";
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
    CONSTRAINT "Listing_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Listing" ("category", "created_at", "description", "id", "latitude", "location", "longitude", "price", "title", "type", "user_id") SELECT "category", "created_at", "description", "id", "latitude", "location", "longitude", "price", "title", "type", "user_id" FROM "Listing";
DROP TABLE "Listing";
ALTER TABLE "new_Listing" RENAME TO "Listing";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
