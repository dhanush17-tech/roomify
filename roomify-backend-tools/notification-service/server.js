const express = require("express");
const { initializeApp, cert } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

// Constants
const PORT = process.env.PORT || 3000;
const NOTIFICATION_TYPES = {
  CHAT: "chat",
  LISTING_REPORTED: "listing_reported",
  LISTING_REMOVED: "listing_removed",
  DOCUMENT_REQUEST: "document_request",
  DOCUMENT_SUBMISSION: "document_submission",
};

const CHANNEL_IDS = {
  CHAT: "chat_messages",
  LISTING: "listing_notifications",
};

// Initialize Firebase Admin SDK
initializeApp({
  credential: cert(
    require("./roomify-f1a1c-firebase-adminsdk-46b0s-7717eebbef.json") || "{}"
  ),
});

const app = express();
app.use(express.json());

// Helper functions
const createNotificationConfig = (token, notification, data) => ({
  token,
  notification,
  data,
  android: {
    priority: "high",
    notification: {
      clickAction: "FLUTTER_NOTIFICATION_CLICK",
      channelId:
        data.type === NOTIFICATION_TYPES.CHAT
          ? CHANNEL_IDS.CHAT
          : CHANNEL_IDS.LISTING,
    },
  },
  apns: {
    payload: {
      aps: {
        contentAvailable: true,
        badge: 1,
        sound: "default",
      },
    },
  },
});

const handleChatNotification = (message, sender, recipientFCMToken) =>
  createNotificationConfig(
    recipientFCMToken,
    {
      title: `New message from ${sender.displayName}`,
      body: message.content.substring(0, 100),
    },
    {
      type: NOTIFICATION_TYPES.CHAT,
      roomId: message.roomId,
      senderId: sender.id,
      messageId: message.id,
      senderName: sender.displayName,
      profileImageUrl: sender.profilePic,
    }
  );

const handleListingReportedNotification = (
  notification,
  data,
  recipientFCMToken
) =>
  createNotificationConfig(
    recipientFCMToken,
    {
      title: notification.title,
      body: notification.body,
    },
    {
      type: NOTIFICATION_TYPES.LISTING_REPORTED,
      listingId: data.listingId,
      reportId: data.reportId,
      reason: data.reason,
      reportedBy: data.reportedBy,
    }
  );

const handleListingRemovedNotification = (listing, recipientFCMToken) =>
  createNotificationConfig(
    recipientFCMToken,
    {
      title: "Your Listing Has Been Removed",
      body: `Your listing "${listing.title}" has been removed due to community guidelines violation.`,
    },
    {
      type: NOTIFICATION_TYPES.LISTING_REMOVED,
      listingId: listing.id.toString(),
      title: listing.title,
      reason: listing.reason || "Community guidelines violation",
    }
  );

const handleDocumentRequestNotification = (
  sender,
  documents,
  roomId,
  requestId,
  recipientFCMToken
) =>
  createNotificationConfig(
    recipientFCMToken,
    {
      title: `Document Request from ${sender.displayName}`,
      body: `${sender.displayName} has requested ${documents.length} documents`,
    },
    {
      type: NOTIFICATION_TYPES.DOCUMENT_REQUEST,
      roomId,
      requestId,
      senderId: sender.id,
      documents: JSON.stringify(documents),
    }
  );

const handleDocumentSubmissionNotification = (
  sender,
  documents,
  roomId,
  requestId,
  recipientFCMToken
) =>
  createNotificationConfig(
    recipientFCMToken,
    {
      title: `Document Submission from ${sender.displayName}`,
      body: `${sender.displayName} has submitted ${documents.length} documents`,
    },
    {
      type: NOTIFICATION_TYPES.DOCUMENT_SUBMISSION,
      roomId,
      requestId,
      senderId: sender.id,
      documents: JSON.stringify(documents),
    }
  );

// Routes
app.post("/send-notification", async (req, res) => {
  const { recipientFCMToken, type } = req.body;

  try {
    if (!recipientFCMToken) {
      return res.status(400).send("Recipient FCM token is required");
    }

    let notificationPayload;

    switch (type) {
      case NOTIFICATION_TYPES.CHAT: {
        const { message, sender } = req.body;
        notificationPayload = handleChatNotification(
          message,
          sender,
          recipientFCMToken
        );
        break;
      }

      case NOTIFICATION_TYPES.LISTING_REPORTED: {
        const { notification, data } = req.body;
        notificationPayload = handleListingReportedNotification(
          notification,
          data,
          recipientFCMToken
        );
        break;
      }

      case NOTIFICATION_TYPES.LISTING_REMOVED: {
        const { listing } = req.body;
        notificationPayload = handleListingRemovedNotification(
          listing,
          recipientFCMToken
        );
        break;
      }

      case NOTIFICATION_TYPES.DOCUMENT_SUBMISSION: {
        const { sender, documents } = req.body;
        notificationPayload = handleDocumentSubmissionNotification(
          sender,
          documents,
          req.body.roomId,
          req.body.requestId,
          recipientFCMToken
        );
        break;
      }

      case NOTIFICATION_TYPES.DOCUMENT_REQUEST: {
        const { sender, documents } = req.body;
        notificationPayload = handleDocumentRequestNotification(
          sender,
          documents,
          req.body.roomId,
          req.body.requestId,
          recipientFCMToken
        );
        break;
      }

      default:
        return res.status(400).send("Invalid notification type");
    }

    try {
      const response = await getMessaging().send(notificationPayload);
      console.log("Notification sent successfully", {
        type,
        recipient: recipientFCMToken,
        response,
      });

      return res.status(200).json({
        success: true,
        message: "Notification sent successfully",
        messageId: response,
      });
    } catch (error) {
      console.log("Notification sent error", {
        type,
        recipient: recipientFCMToken,
        error,
      });
      throw error;
    }
  } catch (error) {
    console.error("Send notification error:", error);
    return res.status(500).json({
      success: false,
      error: "Error sending notification",
      details: error.message,
    });
  }
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
