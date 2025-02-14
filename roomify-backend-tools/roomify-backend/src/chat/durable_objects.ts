import { PrismaD1 } from "@prisma/adapter-d1";
import { PrismaClient } from "@prisma/client";
import { verify } from "hono/jwt";
import * as crypto from 'crypto';

interface User {
    id: string;
    displayName: string;
    profileImageUrl?: string;
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
                    if (data.type === 'pong') return;

                    const adapter = new PrismaD1(this.env.DB);
                    const prisma = new PrismaClient({ adapter });

                    switch (data.type) {
                        case 'document_request':
                            console.log('Received document request:', data);
                            await this.handleDocumentRequest(prisma, data, userId);
                            break;

                        case 'document_submission':
                            console.log('Received document submission:', data);
                            await this.handleDocumentSubmission(prisma, data, userId);
                            break;

                        case 'message_deleted':
                            console.log('Received message deletion:', data);
                            await this.handleMessageDeleted(data);
                            break;

                        default:
                            console.log('Received chat message:', data);
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
    private async handleChatMessage(prisma: PrismaClient, data: any, senderId: string) {
        const message = await prisma.chatMessage.create({
            data: {
                content: data.content,
                roomId: data.roomId,
                senderId,
            },
            include: {
                sender: {
                    select: {
                        id: true,
                        displayName: true,
                        profileImageUrl: true,
                        email: true,

                        fcmToken: true,
                    }
                }
            }
        });

        const room = await prisma.chatRoom.findUnique({
            where: { id: data.roomId },
            include: {
                participants: {
                    include: {
                        user: {
                            select: {
                                id: true,
                                fcmToken: true,
                                email: true,
                                displayName: true,
                                profileImageUrl: true
                            }
                        }
                    }
                }
            }
        });

        if (room) {
            for (const participant of room.participants) {
                if (participant.user.id !== senderId && participant.user.fcmToken) {
                    await sendNotification(participant.user.fcmToken, {
                        type: 'chat',
                        message: {
                            id: message.id,
                            content: message.content,
                            roomId: message.roomId,
                            createdAt: message.createdAt,
                        },
                        recipient: {
                            id: message.sender.id,
                            displayName: message.sender.displayName,
                            profileImageUrl: message.sender.profileImageUrl === null ? '' : message.sender.profileImageUrl
                        },
                        sender: {
                            id: message.sender.id,
                            displayName: message.sender.displayName,
                            profileImageUrl: message.sender.profileImageUrl === null ? '' : message.sender.profileImageUrl
                        }
                    });
                }
            }
        }

        this.broadcast(JSON.stringify({
            type: 'message',
            message: {
                id: message.id,
                content: message.content,
                createdAt: message.createdAt,
                senderId: message.senderId,
                roomId: message.roomId,
                sender: message.sender,
            }
        }));
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
                documentRequest: true
            }
        });

        const recipient = await prisma.user.findUnique({
            where: { id: data.recipientId },
            select: { fcmToken: true }
        });

        if (recipient?.fcmToken) {
            await sendNotification(recipient.fcmToken, {
                type: 'document_request',
                sender: {
                    id: message.sender.id,
                    displayName: message.sender.displayName,
                    profilePic: message.sender.profileImageUrl
                },
                recipient: {
                    id: message.sender.id,
                    displayName: message.sender.displayName,
                    profilePic: message.sender.profileImageUrl
                },
                documents: data.documents,
                roomId: data.roomId,
                requestId: message.id
            });
        }

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
                sender: message.sender
            }
        });
    }
    private async handleDocumentSubmission(prisma: PrismaClient, data: any, senderId: string) {
        const documentRequest = await prisma.documentRequest.findUnique({
            where: { messageId: data.requestId },
            include: {
                message: {
                    include: {
                        sender: true
                    }
                }
            }
        });

        if (!documentRequest) {
            throw new Error('Document request not found');
        }

        if (documentRequest.recipientId !== senderId) {
            throw new Error('Unauthorized to submit documents for this request');
        }

        // Ensure documents is properly formatted as an array
        const documents = Array.isArray(data.documents) ? data.documents : [data.documents];

        const message = await prisma.chatMessage.update({
            where: { id: data.requestId },
            data: {
                documentSubmission: {
                    create: {
                        requestId: documentRequest.id,
                        documents: JSON.stringify(documents),
                    }
                },
                documentRequest: {
                    update: {
                        status: 'FULFILLED'
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


        const senderInfo = {
            id: message.sender.id,
            displayName: message.sender.displayName,
            profileImageUrl: message.sender.profileImageUrl || undefined
        };

        // Send notification to the original document requester
        const originalRequester = await prisma.user.findUnique({
            where: { id: documentRequest.message.sender.id },
            select: { fcmToken: true }
        });

        if (originalRequester?.fcmToken) {
            await sendNotification(originalRequester.fcmToken, {
                type: 'document_submission',
                sender: senderInfo,
                recipient: {
                    id: documentRequest.message.sender.id
                },
                documents: data.documents,
                roomId: data.roomId,
                requestId: data.requestId
            });
        }

        this.broadcast({
            type: 'document_submission',
            message: {
                id: message.id,
                type: 'DOCUMENT_REQUEST',
                content: message.content,
                createdAt: message.createdAt,
                roomId: data.roomId,
                senderId: message.senderId,
                documentSubmission: {
                    ...message.documentSubmission,
                    originalRequestMessageId: data.requestId,
                    documents: data.documents
                },
                documentRequest: message.documentRequest,
                sender: message.sender
            }
        });

 
    }

    private async handleMessageDeleted(data: any) {
        this.broadcast({
            type: 'message_deleted',
            roomId: data.roomId,

            messageId: data.messageId,
        });
    }

}

async function sendNotification(recipientFCMToken: string, data: any) {
    try {
        if (recipientFCMToken) {
            await fetch(
                // 'http://localhost:3000/send-notification',
                'https://notification-service-delicate-field-6176.fly.dev/send-notification',
                {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        recipientFCMToken,
                        type: data.type,
                        ...data
                    }),
                }
            );
        }
    } catch (error) {
        console.error('Send notification error:', error);
    }

}


export { sendNotification };
