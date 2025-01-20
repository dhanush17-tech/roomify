-- AlterTable
ALTER TABLE "Property" ADD COLUMN "walk_score" INTEGER DEFAULT 0;
ALTER TABLE "Property" ADD COLUMN "transit_details" TEXT DEFAULT '[]';
ALTER TABLE "Property" ADD COLUMN "last_location_details_update" DATETIME DEFAULT '1970-01-01 00:00:00';

-- Update existing rows to set current timestamp
UPDATE "Property" SET "last_location_details_update" = DATETIME('now') WHERE "last_location_details_update" = '1970-01-01 00:00:00';
