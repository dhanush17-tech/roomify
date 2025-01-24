import { PrismaD1 } from "@prisma/adapter-d1";
import { PrismaClient } from "@prisma/client";
import { verify } from "hono/jwt";

export class ChatRoom {
    private sessions: Map<string, WebSocket>;
    private state: DurableObjectState;
    private env: Env;

    constructor(state: DurableObjectState, env: Env) {
        this.state = state;
        this.env = env;
        this.sessions = new Map();
    }
    async fetch(request: Request) {
        if (request.headers.get('Upgrade') !== 'websocket') {
            return new Response('Expected WebSocket connection', { status: 400 });
        }

        const authHeader = request.headers.get('Authorization');
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return new Response('Unauthorized: Missing or invalid Authorization header', { status: 401 });
        }

        try {
            const token = authHeader.split(' ')[1];

            // Verify the JWT
            const decoded = await verify(token, this.env.JWT_SECRET,);
            const userId = decoded.sub as string; // Assumes the user ID is in the `sub` claim of the token
            if (!userId) {
                throw new Error("Token does not contain a valid user ID");
            }

            const pair = new WebSocketPair();
            const [client, server] = Object.values(pair);

            server.accept();
            this.sessions.set(userId, server);

            console.log("WebSocket connection established for user", userId);

            // Add ping/pong mechanism
            let pingInterval = setInterval(() => {
                if (server.readyState === WebSocket.OPEN) {
                    server.send(JSON.stringify({ type: 'ping' }));
                } else {
                    clearInterval(pingInterval);
                }
            }, 30000); // Send ping every 30 seconds

            // Handle incoming messages
            server.addEventListener('message', async (msg) => {
                try {
                    const data = JSON.parse(msg.data as string);

                    // Handle pong response
                    if (data.type === 'pong') {
                        return;
                    }

                    const adapter = new PrismaD1(this.env.DB);
                    const prisma = new PrismaClient({ adapter });

                    switch (data.type) {
                        case 'document_request':
                            const documentRequest = await prisma.chatMessage.create({
                                data: {
                                    type: 'DOCUMENT_REQUEST',
                                    content: 'Document Request',
                                    roomId: data.roomId,
                                    senderId: userId,
                                    documentRequest: {
                                        create: {
                                            requestedDocuments: JSON.stringify(data.documents),
                                            status: 'PENDING',
                                            recipientId: data.recipientId,
                                            customDocumentName: data.customDocumentName
                                        }
                                    }
                                },
                                include: {
                                    sender: {
                                        select: {
                                            id: true,
                                            displayName: true,
                                            profileImageUrl: true,
                                        }
                                    },
                                    documentRequest: true
                                }
                            });
                            console.log(" successlly created documentRequest", documentRequest);
                            // Send notification to recipient
                            const recipient = await prisma.user.findUnique({
                                where: { id: data.recipientId },
                                select: { fcmToken: true }
                            });

                            if (recipient?.fcmToken) {
                                await sendNotification(recipient.fcmToken, {
                                    type: 'document_request',
                                    message: documentRequest,
                                    sender: documentRequest.sender
                                });
                            }

                            // Broadcast to all connected clients
                            const messageData = JSON.stringify({
                                type: 'document_request',
                                message: documentRequest
                            });

                            this.sessions.forEach((ws) => {
                                if (ws.readyState === WebSocket.OPEN) {
                                    ws.send(messageData);
                                }
                            });
                            break;

                        case 'document_submission':
                            const submission = await prisma.chatMessage.create({
                                data: {
                                    type: 'DOCUMENT_SUBMISSION',
                                    content: 'Document Submission',
                                    roomId: data.roomId,
                                    senderId: userId,
                                    documentSubmission: {
                                        create: {
                                            requestId: data.requestId,
                                            documents: JSON.stringify(data.documents)
                                        }
                                    }
                                },
                                include: {
                                    sender: {
                                        select: {
                                            id: true,
                                            displayName: true,
                                            profileImageUrl: true,
                                        }
                                    },
                                    documentSubmission: true
                                }
                            });

                            // Update the original request status
                            await prisma.documentRequest.update({
                                where: { id: data.requestId },
                                data: { status: 'FULFILLED' }
                            });

                            // Broadcast to all connected clients
                            const submissionData = JSON.stringify({
                                type: 'document_submission',
                                message: submission
                            });

                            this.sessions.forEach((ws) => {
                                if (ws.readyState === WebSocket.OPEN) {
                                    ws.send(submissionData);
                                }
                            });

                            //send notification to sender
                            const sender = await prisma.user.findUnique({
                                where: { id: userId },
                                select: { fcmToken: true }
                            });

                            if (sender?.fcmToken) {
                                await sendNotification(sender.fcmToken, {
                                    type: 'document_submission',
                                    message: submission
                                });
                            }

                            break;

                        case 'message_deleted':
                            // Broadcast deletion to all clients
                            const deleteData = JSON.stringify({
                                type: 'message_deleted',
                                roomId: data.roomId,
                                messageId: data.messageId,
                            });

                            this.sessions.forEach((ws) => {
                                if (ws.readyState === WebSocket.OPEN) {
                                    ws.send(deleteData);
                                }
                            });
                            break;

                        default:
                            // Handle regular chat message
                            const message = await prisma.chatMessage.create({
                                data: {
                                    content: data.content,
                                    roomId: data.roomId,
                                    senderId: userId,
                                },
                                include: {
                                    sender: {
                                        select: {
                                            id: true,
                                            displayName: true,
                                            profileImageUrl: true,
                                        }
                                    }
                                }
                            });

                            // Format message for broadcasting
                            const chatMessageData = JSON.stringify({
                                type: 'message',
                                message: {
                                    id: message.id,
                                    content: message.content,
                                    createdAt: message.createdAt,
                                    senderId: message.senderId,
                                    roomId: message.roomId,
                                    sender: message.sender,

                                }
                            });

                            // Get room participants to send notifications
                            const room = await prisma.chatRoom.findUnique({
                                where: { id: data.roomId },
                                include: {
                                    participants: {
                                        include: {
                                            user: {
                                                select: {
                                                    id: true,
                                                    email: true,
                                                    displayName: true,
                                                    profileImageUrl: true,
                                                    fcmToken: true,
                                                }
                                            }
                                        }
                                    }
                                }
                            });

                            // Send notifications to other participants
                            if (room) {
                                const otherParticipants = room.participants
                                    .filter(p => p.user.id !== userId && p.user.fcmToken);

                                for (const participant of otherParticipants) {
                                    if (participant.user.fcmToken) {
                                        sendChatNotification(
                                            participant.user.fcmToken,
                                            message,
                                            message.sender,
                                            participant.user
                                        );
                                    }
                                }
                            }

                            this.sessions.forEach((ws) => {
                                if (ws.readyState === WebSocket.OPEN) {
                                    ws.send(chatMessageData);
                                }
                            });
                            break;
                    }
                } catch (error) {
                    console.error('Message handling error:', error);
                }
            });


            // Handle connection closure
            server.addEventListener('close', () => {
                clearInterval(pingInterval);
                this.sessions.delete(userId);
                console.log(`Connection closed for user ${userId}`);
            });

            // Handle connection errors
            server.addEventListener('error', (error) => {
                console.error(`WebSocket error for user ${userId}:`, error);
                clearInterval(pingInterval);
                this.sessions.delete(userId);
            });

            // Return the WebSocket upgrade response with status 101
            return new Response(null, {
                status: 101,
                webSocket: client,
                headers: {
                    'Upgrade': 'websocket',
                    'Connection': 'Upgrade'
                }
            });
        } catch (error: any) {
            console.error('Authorization or WebSocket error:', error);
            return new Response(`Unauthorized: ${error.message}`, { status: 401 });
        }
    }
}

async function sendNotification(recipientFCMToken: string, data: any) {
    try {
        if (recipientFCMToken) {
            const response = await fetch(
                // 'https://notification-service-delicate-field-6176.fly.dev/send-notification'
                'http://localhost:3000/send-notification'
                , {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(data),
                });

            if (!response.ok) {
                throw new Error('Failed to send notification');
            }

            const responseData = await response.json();
            console.log("notification sent", responseData);
        }
    } catch (error) {
        console.error('Send notification error:', error);
    }
}

async function sendChatNotification(recipientFCMToken: string, message: any, sender: any, recipient: any) {
    const notificationData = {
        recipientFCMToken,
        type: 'chat',
        message: {
            content: `[${recipient.email}]: ${message.content}`,
            roomId: message.roomId,
            id: message.id,
            recipientEmail: recipient.email
        },
        sender: {
            id: sender.id,
            displayName: sender.displayName,
            profilePic: sender.profileImageUrl
        }
    };

    await sendNotification(recipientFCMToken, notificationData);
}

export { sendNotification, sendChatNotification };