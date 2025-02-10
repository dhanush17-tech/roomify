import { PrismaD1 } from "@prisma/adapter-d1";
import { PrismaClient } from "@prisma/client";
import { verify } from "hono/jwt";
import * as crypto from 'crypto';

interface User {
    id: string;
    displayName: string;
    profileImageUrl?: string;
}

interface ChatMessage {
    id: string;
    type: string;
    content: string;
    createdAt: Date;
    roomId: string;
    senderId: string;
    recipientId?: string;
    isDeleted: boolean;
    sender: User;
    documentRequest?: any;
    documentSubmission?: any;
}

interface PrismaUser {
    id: string;
    displayName: string;
    profileImageUrl: string | null;
}

interface PrismaChatMessage {
    id: string;
    type: string;
    content: string;
    createdAt: Date;
    roomId: string;
    senderId: string;
    recipientId: string | null;
    isDeleted: boolean;
    sender: PrismaUser;
    documentRequest?: any;
    documentSubmission?: any;
}

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
            return new Response('Expected WebSocket', { status: 400 });
        }

        const pair = new WebSocketPair();
        const [client, server] = Object.values(pair);

        // Verify JWT before accepting connection
        const authHeader = request.headers.get('Authorization');
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return new Response('Unauthorized', { status: 401 });
        }

        try {
            const token = authHeader.split(' ')[1];
            const decoded = await verify(token, this.env.JWT_SECRET);
            const userId = decoded.sub as string;
            if (!userId) {
                throw new Error('Invalid user ID');
            }

            // Accept the WebSocket
            server.accept();

            // Set up keep-alive
            const keepAliveInterval = setInterval(() => {
                if (server.readyState === WebSocket.OPEN) {
                    server.send(JSON.stringify({ type: 'ping' }));
                }
            }, 30000);

            server.addEventListener('close', () => {
                clearInterval(keepAliveInterval);
                this.sessions.delete(userId);
            });

            server.addEventListener('error', (error) => {
                console.error('WebSocket error:', error);
                clearInterval(keepAliveInterval);
                this.sessions.delete(userId);
            });

            this.sessions.set(userId, server);

            // Add message handler
            server.addEventListener('message', async (msg) => {
                try {
                    const data = JSON.parse(msg.data as string);
                    if (data.type === 'pong') this.broadcast({ type: 'ping' });

                    const adapter = new PrismaD1(this.env.DB);
                    const prisma = new PrismaClient({ adapter });

                    switch (data.type) {
                        case 'document_request':
                            await this.handleDocumentRequest(prisma, data, userId);
                            break;

                        case 'document_submission':
                            await this.handleDocumentSubmission(prisma, data, userId);
                            break;

                        case 'message_deleted':
                            await this.handleMessageDeleted(data);
                            break;

                        default:
                            await this.handleChatMessage(prisma, data, userId);
                            break;
                    }
                } catch (error) {
                    console.error('Message handling error:', error);
                }
            });

            return new Response(null, {
                status: 101,
                webSocket: client,
                headers: {
                    'Upgrade': 'websocket',
                    'Connection': 'Upgrade'
                }
            });
        } catch (error) {
            return new Response('Unauthorized', { status: 401 });
        }
    }

    private broadcast(message: any) {
        this.sessions.forEach((ws) => {
            if (ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify(message));
            }
        });
    }

    private async handleDocumentRequest(prisma: PrismaClient, data: any, senderId: string) {
        const message = await prisma.chatMessage.create({
            data: {
                type: 'DOCUMENT_REQUEST',
                content: 'Document Request',
                roomId: data.roomId,
                senderId,
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
                        profileImageUrl: true
                    }
                },
                documentRequest: {
                    include: {
                        recipient: {
                            select: {
                                id: true,
                                displayName: true,
                                profileImageUrl: true
                            }
                        }
                    }
                }
            }
        });

        const senderInfo: User = {
            id: message.sender.id,
            displayName: message.sender.displayName,
            profileImageUrl: message.sender.profileImageUrl || undefined
        };

        const broadcastMessage = {
            type: 'document_request',
            message: {
                id: message.id,
                type: message.type,
                content: message.content,
                createdAt: message.createdAt,
                roomId: message.roomId,
                senderId: message.senderId,
                documentRequest: message.documentRequest,
                sender: senderInfo
            }
        };

        this.broadcast(broadcastMessage);

        // Send notification to recipient
        const recipient = await prisma.user.findUnique({
            where: { id: data.recipientId },
            select: { fcmToken: true, email: true }
        });

        if (recipient?.fcmToken) {
            await sendNotification(recipient.fcmToken, {
                type: 'document_request',
                recipientFCMToken: recipient.fcmToken,
                message: {
                    content: `Document Request from ${message.sender.displayName}`,
                    roomId: message.roomId,
                    id: message.id,
                    recipientEmail: recipient.email
                },
                sender: senderInfo
            });
        }

        return message;
    }

    private async handleDocumentSubmission(prisma: PrismaClient, data: any, senderId: string) {
        // First find the document request message
        console.log('Handling document submission:', data);

        const documentRequest = await prisma.documentRequest.findUnique({
            where: { messageId: data.requestId }
        });

        if (!documentRequest) {
            throw new Error('Document request not found');
        }

        if (documentRequest.recipientId !== senderId) {
            throw new Error('Unauthorized to submit documents for this request');
        }

        // Update the original message with submission and status
        const message = await prisma.chatMessage.update({
            where: { id: data.requestId },
            data: {
                documentRequest: {
                    update: {
                        status: 'FULFILLED'
                    }
                },
                documentSubmission: {
                    create: {
                        requestId: documentRequest.id,
                        documents: JSON.stringify(data.documents)
                    }
                }
            },
            include: {
                sender: {
                    select: {
                        id: true,
                        displayName: true,
                        profileImageUrl: true
                    }
                },
                documentRequest: true,
                documentSubmission: true
            }
        });

        const senderInfo: User = {
            id: message.sender.id,
            displayName: message.sender.displayName,
            profileImageUrl: message.sender.profileImageUrl || undefined
        };

        this.broadcast({
            type: 'document_submission',
            message: {
                id: message.id,
                type: message.type,
                content: message.content,
                createdAt: message.createdAt,
                roomId: message.roomId,
                senderId: message.senderId,
                documentRequest: message.documentRequest,
                documentSubmission: message.documentSubmission,
                sender: senderInfo
            }
        });

        console.log('Document submission broadcasted:', message);


    }

    private async handleMessageDeleted(data: any) {
        this.broadcast({
            type: 'message_deleted',
            roomId: data.roomId,
            messageId: data.messageId,
        });
    }

    private async handleChatMessage(prisma: PrismaClient, data: any, senderId: string) {
        try {
            // Validate required fields
            if (!data.roomId || !data.content) {
                throw new Error('Missing required fields: roomId or content');
            }

            const message = await prisma.chatMessage.create({
                data: {
                    content: data.content,
                    roomId: data.roomId,
                    senderId: senderId,
                    type: 'TEXT'
                },
                include: {
                    sender: {
                        select: {
                            id: true,
                            displayName: true,
                            profileImageUrl: true
                        }
                    }
                }
            });

            const chatMessageData = JSON.stringify({
                type: 'message',
                message: {
                    id: message.id,
                    content: message.content,
                    createdAt: message.createdAt,
                    senderId: message.senderId,
                    roomId: message.roomId,
                    type: message.type,
                    sender: message.sender,
                }
            });

            // Get room participants for notifications
            const room = await prisma.chatRoom.findUnique({
                where: { id: data.roomId },
                include: {
                    participants: {
                        include: {
                            user: {
                                select: {
                                    id: true,
                                    fcmToken: true
                                }
                            }
                        }
                    }
                }
            });

            if (room) {
                for (const participant of room.participants) {
                    if (participant.user.id !== senderId && participant.user.fcmToken) {
                        await sendChatNotification(
                            participant.user.fcmToken,
                            message,
                            message.sender,
                            participant.user
                        );
                    }
                }
            }

            this.broadcast(chatMessageData);
        } catch (error) {
            console.error('Error handling chat message:', error);
            throw error;
        }
    }
}

async function sendNotification(recipientFCMToken: string, data: any) {
    try {
        if (recipientFCMToken) {
            await fetch(
                'https://notification-service-delicate-field-6176.fly.dev/send-notification',
                {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(data),
                }
            );
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
