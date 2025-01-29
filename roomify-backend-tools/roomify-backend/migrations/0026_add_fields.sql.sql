-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_FloorPlan" (
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
    "name" TEXT NOT NULL,
    CONSTRAINT "FloorPlan_propertyId_fkey" FOREIGN KEY ("propertyId") REFERENCES "Property" ("listing_id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_FloorPlan" ("bathrooms", "bedrooms", "createdAt", "id", "imageUrl", "price", "propertyId", "squareFootage", "unitsAvailable", "updatedAt") SELECT "bathrooms", "bedrooms", "createdAt", "id", "imageUrl", "price", "propertyId", "squareFootage", "unitsAvailable", "updatedAt" FROM "FloorPlan";
DROP TABLE "FloorPlan";
ALTER TABLE "new_FloorPlan" RENAME TO "FloorPlan";
CREATE INDEX "FloorPlan_propertyId_idx" ON "FloorPlan"("propertyId");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
