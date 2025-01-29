-- AlterTable
ALTER TABLE "Property" ADD COLUMN "last_location_details_update" DATETIME;
ALTER TABLE "Property" ADD COLUMN "transitDetails" TEXT;
ALTER TABLE "Property" ADD COLUMN "transitScore" INTEGER;
ALTER TABLE "Property" ADD COLUMN "walkScore" INTEGER;
