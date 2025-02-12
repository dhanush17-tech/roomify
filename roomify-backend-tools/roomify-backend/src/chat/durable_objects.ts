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
    type: 'message' | 'document_request' | 'document_submission';
    content: string;
    createdAt: Date;
    roomId: string;
    senderId: string;
    isDeleted: boolean;
    sender?: User;
    documentRequest?: DocumentRequest;
    documentSubmission?: DocumentSubmission;
}

interface DocumentRequest {
    id: string;
    type: 'document_request';
    recipientId: string;
    documents: string[];
    customDocumentName?: string;
    status: 'PENDING' | 'COMPLETED' | 'REJECTED';
}

interface DocumentSubmission {
    id: string;
    type: 'document_submission';
    requestId: string;
    documentUrls: string[];
    status: 'PENDING' | 'APPROVED' | 'REJECTED';
}

interface PrismaUser {
    id: string;
    displayName: string;
    profileImageUrl?: string;
}

interface PrismaChatMessage {
    id: string;
    type: string;
    content: string;
    createdAt: Date;
    roomId: string;
    senderId: string;
    isDeleted: boolean;
    sender: PrismaUser;
    documentRequest?: {
        id: string;
        messageId: string;
        recipientId: string;
        requestedDocuments: string;
        status: 'PENDING' | 'COMPLETED' | 'REJECTED';
        customDocumentName?: string;
    };
    documentSubmission?: {
        id: string;
        messageId: string;
        requestId: string;
        documents: string;
        status: 'PENDING' | 'APPROVED' | 'REJECTED';
    };
}

export class ChatRoom {
    private sessions: Map<string, WebSocket>;
    private pingIntervals: Map<string, any>;
    private state: DurableObjectState;
    private env: Env;

    constructor(state: DurableObjectState, env: Env) {
        this.state = state;
        this.env = env;
        this.sessions = new Map();
        this.pingIntervals = new Map();
    }

    private getRoomId(): string {
        return this.state.id.toString();
    }

    private async handleWebSocketMessage(ws: WebSocket, userId: string, data: any) {
        try {
            switch (data.type) {
                case 'ping':
                    ws.send(JSON.stringify({ type: 'pong', roomId: data.roomId }));
                    break;
                case 'pong':
                    // Reset connection timeout on pong
                    break;
                case 'message':
                    await this.handleChatMessage(data, userId);
                    break;
                case 'document_request':
                    await this.handleDocumentRequest(data, userId);
                    break;
                case 'document_submission':
                    await this.handleDocumentSubmission(data, userId);
                    break;
                default:
                    console.error('Unknown message type:', data.type);
            }
        } catch (error) {
            console.error('Error handling WebSocket message:', error);
            ws.send(JSON.stringify({ type: 'error', error: 'Failed to process message' }));
        }
    }

    async fetch(request: Request) {
        const url = new URL(request.url);
        const path = url.pathname;

        if (request.headers.get('Upgrade') === 'websocket') {
            const pair = new WebSocketPair();
            const [client, server] = Object.values(pair);

            const token = request.headers.get('Authorization')?.split(' ')[1];
            if (!token) {
                server.close(1008, 'Unauthorized');
                return new Response('Unauthorized', { status: 401 });
            }

            try {
                const payload = await verify(token, this.env.JWT_SECRET);
                const userId = payload.sub as string;

                // Close any existing connection for this user
                const existingConnection = this.sessions.get(userId);
                if (existingConnection) {
                    existingConnection.close(1000, 'New connection established');
                    this.sessions.delete(userId);
                }

                // Set up the new connection
                server.accept();
                this.sessions.set(userId, server);

                // Set up keep-alive ping
                const pingInterval = setInterval(() => {
                    if (server.readyState === WebSocket.OPEN) {
                        try {
                            server.send(JSON.stringify({ type: 'ping' }));
                        } catch (error) {
                            clearInterval(pingInterval);
                            this.pingIntervals.delete(userId);
                            this.sessions.delete(userId);
                        }
                    }
                }, 15000); // Send ping every 15 seconds

                this.pingIntervals.set(userId, pingInterval);
                this.sessions.set(userId, server);

                // Send initial state
                await this.sendInitialState(server, userId);

                // Handle incoming messages
                server.addEventListener('message', async (msg) => {
                    try {
                        const data = JSON.parse(msg.data as string);
                        await this.handleWebSocketMessage(server, userId, data);
                    } catch (error) {
                        console.error('Error parsing message:', error);
                    }
                });

                server.addEventListener('close', () => {
                    clearInterval(this.pingIntervals.get(userId));
                    this.pingIntervals.delete(userId);
                    this.sessions.delete(userId);
                });

                server.addEventListener('error', () => {
                    this.sessions.delete(userId);
                });

                return new Response(null, { status: 101, webSocket: client });
            } catch (error) {
                server.close(1008, 'Invalid token');
                return new Response('Unauthorized', { status: 401 });
            }
        }

        // Handle other HTTP requests
        if (path.includes('/broadcast-delete')) {
            const data = await request.json() as { messageId: string; roomId: string };
            this.broadcast({
                type: 'message_deleted',
                messageId: data.messageId,
                roomId: data.roomId
            });
            return new Response('OK');
        }

        return new Response('Not found', { status: 404 });
    }

    private async sendInitialState(ws: WebSocket, userId: string) {
        try {
            const adapter = new PrismaD1(this.env.DB);
            const prisma = new PrismaClient({ adapter });

            const messages = await prisma.chatMessage.findMany({
                where: {
                    roomId: this.getRoomId(),
                    isDeleted: false
                },
                orderBy: { createdAt: 'desc' },
                take: 50,
                include: {
                    sender: true,
                    documentRequest: true,
                    documentSubmission: true
                }
            });

            const typedMessages = messages.map(msg => ({
                ...msg,
                documentRequest: msg.documentRequest ? {
                    ...msg.documentRequest,
                    status: msg.documentRequest.status as 'PENDING' | 'COMPLETED' | 'REJECTED'
                } : undefined,
                documentSubmission: msg.documentSubmission ? {
                    ...msg.documentSubmission,
                    documents: msg.documentSubmission.documents,
                    status: 'PENDING' // Default status for existing submissions
                } : undefined
            })) as PrismaChatMessage[];

            ws.send(JSON.stringify({
                type: 'initial_state',
                messages: typedMessages
            }));
        } catch (error) {
            console.error('Error sending initial state:', error);
            ws.send(JSON.stringify({
                type: 'error',
                error: 'Failed to load messages'
            }));
        }
    }

    private broadcast(message: any, excludeUserId?: string) {
        this.sessions.forEach((ws, userId) => {
            if (userId !== excludeUserId && ws.readyState === WebSocket.OPEN) {
                try {
                    ws.send(JSON.stringify(message));
                } catch (error) {
                    console.error(`Failed to send to ${userId}:`, error);
                    this.sessions.delete(userId);
                }
            }
        });
    }

    private async handleChatMessage(data: ChatMessage, senderId: string) {
        const adapter = new PrismaD1(this.env.DB);
        const prisma = new PrismaClient({ adapter });

        try {
            const message = await prisma.chatMessage.create({
                data: {
                    type: 'TEXT',
                    content: data.content,
                    roomId: this.getRoomId(),
                    senderId: senderId,
                },
                include: {
                    sender: true
                }
            }) as PrismaChatMessage;

            this.broadcast({
                type: 'message',
                message
            });

            // Create unread message records for other participants
            const participants = await prisma.chatParticipant.findMany({
                where: {
                    roomId: this.getRoomId(),
                    NOT: {
                        userId: senderId
                    }
                }
            });

            await Promise.all(participants.map(participant =>
                prisma.unreadMessage.create({
                    data: {
                        roomId: this.getRoomId(),
                        messageId: message.id,
                        recipientId: participant.userId
                    }
                })
            ));

        } catch (error) {
            console.error('Error creating message:', error);
            throw error;
        }
    }

    private async handleDocumentRequest(data: any, senderId: string) {
        const adapter = new PrismaD1(this.env.DB);
        const prisma = new PrismaClient({ adapter });

        const message = await prisma.chatMessage.create({
            data: {
                type: 'DOCUMENT_REQUEST',
                content: 'Document Request',
                roomId: this.getRoomId(),
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

        this.broadcast({
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
        });

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

    private async handleDocumentSubmission(data: any, senderId: string) {
        const adapter = new PrismaD1(this.env.DB);
        const prisma = new PrismaClient({ adapter });

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
