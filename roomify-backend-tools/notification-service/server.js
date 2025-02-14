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

const handleChatNotification = (message,recipient, sender, recipientFCMToken) =>{
  console.log(recipient);
  return createNotificationConfig(
    recipientFCMToken,
    {
      title: `[${recipient.displayName}] New message from ${sender.displayName}`,
      body: message.content.substring(0, 100),
    },
    {
      type: NOTIFICATION_TYPES.CHAT,
      roomId: message.roomId,
      senderId: sender.id,
      recipientId: recipient.id,
      messageId: message.id,
      senderName: sender.displayName,
      profileImageUrl: sender.profileImageUrl,
    }
  )
};

const handleListingReportedNotification = (
  notification,
  data,
  recipient,
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
      recipientId: data.recipientId,
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
  recipient,
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
      recipientId: recipient.id,
      senderId: sender.id,
      documents: JSON.stringify(documents),
    }
  );

const handleDocumentSubmissionNotification = (
  sender,
  documents,
  roomId,
  requestId,
  recipient,
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
      recipientId: recipient.id,
      requestId,
      senderId: sender.id,
      documents: JSON.stringify(documents),
    }
  );

  app.post("/send-notification", async (req, res) => {
  const { recipientFCMToken, type } = req.body;

  try {
    // Validate required fields
    if (!recipientFCMToken) {
      console.log("Recipient FCM token is required");
      return res.status(400).json({
        success: false,
        error: "Recipient FCM token is required"
      });
    }

    if (!type || !Object.values(NOTIFICATION_TYPES).includes(type)) {
      console.log("Invalid notification type:", type);
      return res.status(400).json({
        success: false,
        error: "Invalid notification type"
      });
    }

    let notificationPayload;

    console.log("Notification type:", type);

    // Create notification payload based on type
    switch (type) {
      
      case NOTIFICATION_TYPES.CHAT: {
        const { message, sender, recipient } = req.body;
        if (!message || !sender) {
          return res.status(400).json({
            success: false,
            error: "Message and sender are required for chat notifications"
          });
        }
        notificationPayload = handleChatNotification(message, recipient, sender, recipientFCMToken);
        break;
      }

      case NOTIFICATION_TYPES.LISTING_REPORTED: {
        const { notification, data, recipient, recipientFCMToken } = req.body;
        if (!notification || !data) {
          return res.status(400).json({
            success: false,
            error: "Notification and data are required for listing reported notifications"
          });
        }
        notificationPayload = handleListingReportedNotification(notification, data, recipient, recipientFCMToken);
        break;
      }

      case NOTIFICATION_TYPES.LISTING_REMOVED: {
        const { listing , recipient} = req.body;
        if (!listing) {
          return res.status(400).json({
            success: false,
            error: "Listing is required for listing removed notifications"
          });
        }
        notificationPayload = handleListingRemovedNotification(listing, recipientFCMToken, recipient);
        break;
      }

      case NOTIFICATION_TYPES.DOCUMENT_SUBMISSION: {
        const { sender, documents, roomId, requestId, recipient, recipientFCMToken } = req.body;
        if (!sender || !documents || !roomId || !requestId) {
          return res.status(400).json({
            success: false,
            error: "Sender, documents, roomId, and requestId are required for document submission notifications"
          });
        }
        notificationPayload = handleDocumentSubmissionNotification(
          sender,
          documents,
          roomId,
          requestId,
          recipient,
          recipientFCMToken
        );
        break;
      }

      case NOTIFICATION_TYPES.DOCUMENT_REQUEST: {
        const { sender, documents, roomId, requestId, recipient, recipientFCMToken } = req.body;
        if (!sender || !documents || !roomId || !requestId) {
          return res.status(400).json({
            success: false,
            error: "Sender, documents, roomId, and requestId are required for document request notifications"
          });
        }
        notificationPayload = handleDocumentRequestNotification(
          sender,
          documents,
          roomId,
          requestId,
          recipient,
          recipientFCMToken
        );
        break;
      }

      default:
        return res.status(400).json({
          success: false,
          error: "Unsupported notification type"
        });
    }

    console.log("Notification payload:", notificationPayload);

    // Send notification with retry logic
    let retries = 3;
    let response;

    while (retries > 0) {
      try {
        response = await getMessaging().send(notificationPayload);
        console.log("Notification sent successfully", {
          type,
          recipient: recipientFCMToken,
          response,
        });
        break;
      } catch (error) {
        if (error.code === 'messaging/server-unavailable' && retries > 1) {
          retries--;
          await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second before retry
          continue;
        }
        throw error;
      }
    }

    console.log("Notification sent successfully", {
      type,
      recipient: recipientFCMToken,
      response,
    })
    return res.status(200).json({
      success: true,
      message: "Notification sent successfully",
      messageId: response
    });

  } catch (error) {
    console.error("Send notification error:", error);

    // Handle specific FCM errors
    if (error.code === 'messaging/invalid-registration-token') {
      return res.status(400).json({
        success: false,
        error: "Invalid FCM token",
        details: error.message
      });
    }

    if (error.code === 'messaging/registration-token-not-registered') {
      return res.status(400).json({
        success: false,
        error: "FCM token is no longer valid",
        details: error.message
      });
    }

    return res.status(500).json({
      success: false,
      error: "Error sending notification",
      details: error.message
    });
  }
  });

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
