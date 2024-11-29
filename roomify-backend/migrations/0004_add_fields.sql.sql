-- CreateTable
CREATE TABLE "UserInterest" (
    "user_id" TEXT NOT NULL,
    "interest" TEXT NOT NULL,

    PRIMARY KEY ("user_id", "interest"),
    CONSTRAINT "UserInterest_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "UserPreference" (
    "user_id" TEXT NOT NULL,
    "preference" TEXT NOT NULL,

    PRIMARY KEY ("user_id", "preference"),
    CONSTRAINT "UserPreference_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "UserSocialLink" (
    "user_id" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "username" TEXT NOT NULL,

    PRIMARY KEY ("user_id", "platform"),
    CONSTRAINT "UserSocialLink_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
