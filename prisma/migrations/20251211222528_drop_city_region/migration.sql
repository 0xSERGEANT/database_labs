/*
  Warnings:

  - You are about to drop the column `region` on the `city` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[name,country]` on the table `city` will be added. If there are existing duplicate values, this will fail.

*/
-- DropIndex
DROP INDEX "city_unique_location";

-- AlterTable
ALTER TABLE "city" DROP COLUMN "region";

-- CreateIndex
CREATE UNIQUE INDEX "city_unique_location" ON "city"("name", "country");
