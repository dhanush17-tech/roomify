-- CreateTable
CREATE TABLE "FloorPlan" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "propertyId" INTEGER NOT NULL,
    "imageUrl" TEXT NOT NULL,
    "bedrooms" INTEGER NOT NULL,
    "bathrooms" INTEGER NOT NULL,
    "unitsAvailable" INTEGER NOT NULL DEFAULT 0,
    "squareFootage" REAL,
    "price" REAL NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "FloorPlan_propertyId_fkey" FOREIGN KEY ("propertyId") REFERENCES "Property" ("listing_id") ON DELETE RESTRICT ON UPDATE CASCADE
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
    "companyName" TEXT,
    "companyWebsite" TEXT,
    "companyDescription" TEXT,
    "isProfessionalListing" BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT "Property_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "Listing" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Property" ("isLookingForRoomate", "isRoomifyChoice", "listing_id", "max_occupancy", "move_in_date", "move_out_date", "number_of_bathrooms", "number_of_bedrooms", "rating") SELECT "isLookingForRoomate", "isRoomifyChoice", "listing_id", "max_occupancy", "move_in_date", "move_out_date", "number_of_bathrooms", "number_of_bedrooms", "rating" FROM "Property";
DROP TABLE "Property";
ALTER TABLE "new_Property" RENAME TO "Property";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;

-- CreateIndex
CREATE INDEX "FloorPlan_propertyId_idx" ON "FloorPlan"("propertyId");
