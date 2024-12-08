-- CreateTable
CREATE TABLE "UnreadMessage" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "roomId" TEXT NOT NULL,
    "messageId" TEXT NOT NULL,
    "recipientId" TEXT NOT NULL,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "UnreadMessage_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES "ChatRoom" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "UnreadMessage_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "ChatMessage" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "UnreadMessage_recipientId_fkey" FOREIGN KEY ("recipientId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "UnreadMessage_roomId_idx" ON "UnreadMessage"("roomId");

-- CreateIndex
CREATE INDEX "UnreadMessage_messageId_idx" ON "UnreadMessage"("messageId");

-- CreateIndex
CREATE INDEX "UnreadMessage_recipientId_idx" ON "UnreadMessage"("recipientId");
