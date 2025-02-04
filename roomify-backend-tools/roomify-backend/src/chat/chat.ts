import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import * as crypto from "crypto";
import { signAndStoreToken, uploadToR2, verifyPassword } from '../helper/helper';
import { PrismaD1 } from '@prisma/adapter-d1';
import { PrismaClient } from '@prisma/client';

const app = new Hono<{
    Bindings: Env,
    Variables: {
        userId: string;
    }
}>();



app.get('/', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const rooms = await prisma.chatRoom.findMany({
            where: {
                participants: {
                    some: { userId }
                }
            },
            include: {
                participants: {
                    include: {
                        user: {
                            include: {
                                preferences: true,
                            }
                        }
                    }
                },
                messages: {
                    take: 1,
                    orderBy: { createdAt: 'desc' },
                    include: {
                        sender: {
                            select: {
                                id: true,
                                displayName: true,
                            }
                        }
                    }
                },
                unreadMessages: {
                    where: {
                        recipientId: userId,
                        isRead: false
                    }
                }
            },
            orderBy: {
                updatedAt: 'desc'
            }
        });

        const formattedRooms = rooms.map(room => ({
            ...room,
            unreadCount: room.unreadMessages.length
        }));

        return c.json({ rooms: formattedRooms });
    } catch (error) {
        console.error('Get chats error:', error);
        return c.json({ error: 'Failed to get chats' }, 500);
    }
});

app.get('/:roomId/ws', async (c) => {
    const roomId = c.req.param('roomId');
    //@ts-ignore
    const durableId = c.env.CHATROOM.idFromName(roomId);
    //@ts-ignore
    const room = c.env.CHATROOM.get(durableId);

    return room.fetch(c.req.raw);
});

// Get room messages
app.get('/:roomId/messages', async (c) => {
    const roomId = c.req.param('roomId');
    const payload = c.get('jwtPayload');
    if (!payload) return c.json({ error: 'Unauthorized' }, 401);

    const userId = payload.sub;
    const adapter = new PrismaD1(c.env.DB);
    const prisma = new PrismaClient({ adapter });

    try {
        await prisma.unreadMessage.updateMany({
            where: {
                roomId,
                recipientId: userId,
                isRead: false
            },
            data: {
                isRead: true
            }
        });

        const messages = await prisma.chatMessage.findMany({
            where: { roomId },
            include: {
                documentRequest: {
                    include: {
                        recipient: true,

                    }
                },
                documentSubmission: true,

                sender: {
                    select: {
                        id: true,
                        displayName: true,
                        profileImageUrl: true,

                    }
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        return c.json({ messages });
    } catch (error) {
        return c.json({ error: 'Failed to fetch messages' }, 500);
    }
});

app.post('/create', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        const userId = payload.sub;
        const { otherUserId } = await c.req.json();

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // First check if a chat room already exists between these users
        const existingRoom = await prisma.chatRoom.findFirst({
            where: {
                participants: {
                    every: {
                        userId: {
                            in: [userId, otherUserId]
                        }
                    }
                }
                
            },
            include: {
                participants: {
                    include: {
                        user: {
                            include: {
                                preferences: true,
                            }
                        }
                    }
                },
                messages: {
                    take: 1,
                    orderBy: {
                        createdAt: 'desc'
                    },
                    include: {
                        sender: {
                            select: {
                                id: true,
                                displayName: true,
                            }
                        }
                    }
                },
                unreadMessages: {
                    where: {
                        recipientId: userId,
                        isRead: false
                    }
                }
            }
        });

        if (existingRoom) {
            // Return the existing room with unread count
            console.log('Existing room found');
            console.log(existingRoom);
            return c.json({
                room: {
                    ...existingRoom,
                    unreadCount: existingRoom.unreadMessages.length
                }
            });
        }

 
        // If no existing room, create a new one
        const newRoom = await prisma.chatRoom.create({
            data: {
                participants: {
                    create: [
                        { userId: userId },
                        { userId: otherUserId }
                    ]
                }
            },
            include: {
                participants: {
                    include: {
                        user: {
                            include: {
                                preferences: true,
                            }
                        }
                    }
                },
                messages: {
                    take: 1,
                    orderBy: {
                        createdAt: 'desc'
                    },
                    include: {
                        sender: {
                            select: {
                                id: true,
                                displayName: true,
                            }
                        }
                    }
                },
                unreadMessages: {
                    where: {
                        recipientId: userId,
                        isRead: false
                    }
                }
            }
        });

        // Return the new room with unread count (which will be 0)
        return c.json({
            room: {
                ...newRoom,
                unreadCount: 0
            }
        });
    } catch (error) {
        console.error('Create chat room error:', error);
        return c.json({
            error: 'Failed to create chat room',
            details: error instanceof Error ? error.message : 'Unknown error'
        }, 500);
    }
});

// Add endpoint to mark messages as read
app.post('/:roomId/mark-read', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const roomId = c.req.param('roomId');

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Mark all unread messages in the room as read
        await prisma.unreadMessage.updateMany({
            where: {
                roomId,
                recipientId: userId,
                isRead: false
            },
            data: {
                isRead: true
            }
        });

        return c.json({ success: true });
    } catch (error) {
        console.error('Mark messages read error:', error);
        return c.json({ error: 'Failed to mark messages as read' }, 500);
    }
});

// Add document request endpoint
app.post("/:roomId/request-document", async (c) => {
    try {
        const roomId = c.req.param('roomId');
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const { requestedDocuments, recipientId, customDocumentName } = await c.req.json();

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Create the message and document request
        const message = await prisma.chatMessage.create({
            data: {
                type: 'DOCUMENT_REQUEST',
                content: 'Document Request',
                roomId,
                senderId: userId,
                documentRequest: {
                    create: {
                        requestedDocuments: JSON.stringify(requestedDocuments),
                        status: 'PENDING',
                        recipientId: recipientId,
                        customDocumentName: customDocumentName
                    }
                }
            },
            include: {
                documentRequest: true,
                sender: {
                    select: {
                        id: true,
                        displayName: true,
                    }
                }
            }
        });

        return c.json({ message });
    } catch (error) {
        console.error('Document request error:', error);
        return c.json({ error: 'Failed to create document request' }, 500);
    }
});

// Add document submission endpoint
app.post("/:roomId/submit-document", async (c) => {
    try {
        const roomId = c.req.param('roomId');
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;

        // Get the form data
        const formData = await c.req.formData();
        const requestId = formData.get('requestId') as string;
        const files = formData.getAll('documents') as File[];

        if (!requestId || !files.length) {
            return c.json({ error: 'Missing required fields' }, 400);
        }

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Upload each document to R2
        const uploadPromises = files.map(file => uploadToR2(file, 'documents', c));
        const uploadResults = await Promise.all(uploadPromises);
        const documentUrls = uploadResults.map(result => result.fileUrl);

        // Create the message and document submission
        const message = await prisma.chatMessage.create({
            data: {
                type: 'DOCUMENT_SUBMISSION',
                content: 'Document Submission',
                roomId,
                senderId: userId,
                documentSubmission: {
                    create: {
                        requestId,
                        documents: JSON.stringify(documentUrls)
                    }
                }
            },
            include: {
                documentSubmission: true,
                sender: {
                    select: {
                        id: true,
                        displayName: true,
                    }
                }
            }
        });

        // Update the original request status
        await prisma.documentRequest.update({
            where: { id: requestId },
            data: { status: 'FULFILLED' }
        });

        return c.json({
            message,
            documentUrls
        });
    } catch (error) {
        console.error('Document submission error:', error);
        return c.json({ error: 'Failed to submit documents' }, 500);
    }
});

// Add endpoint to get document request status
app.get("/:roomId/document-requests", async (c) => {
    try {
        const roomId = c.req.param('roomId');
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const requests = await prisma.chatMessage.findMany({
            where: {
                roomId,
                type: 'DOCUMENT_REQUEST'
            },
            include: {
                documentRequest: true,
                documentSubmission: true,
                sender: {
                    select: {
                        id: true,
                        displayName: true,
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
            }
        });

        return c.json({ requests });
    } catch (error) {
        console.error('Get document requests error:', error);
        return c.json({ error: 'Failed to get document requests' }, 500);
    }
});

// Add delete message endpoint
app.delete('/:roomId/messages/:messageId', async (c) => {
    try {
        const roomId = c.req.param('roomId');
        const messageId = c.req.param('messageId');
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Check if user owns the message
        const message = await prisma.chatMessage.findFirst({
            where: {
                id: messageId,
                senderId: userId,
            },
        });

        if (!message) {
            return c.json({ error: 'Message not found or unauthorized' }, 404);
        }

        // Soft delete the message
        await prisma.chatMessage.update({
            where: { id: messageId },
            data: { isDeleted: true }
        });

        // Get the durable object to broadcast the deletion
        //@ts-ignore
        const durableId = c.env.CHATROOM.idFromName(roomId);
        //@ts-ignore
        const room = c.env.CHATROOM.get(durableId);



        return c.json({ success: true });
    } catch (error) {
        console.error('Delete message error:', error);
        return c.json({ error: 'Failed to delete message' }, 500);
    }
});

// Add delete document request endpoint
app.delete('/:roomId/document-requests/:requestId', async (c) => {
    try {
        const roomId = c.req.param('roomId');
        const requestId = c.req.param('requestId');
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Find the document request and associated message
        const documentRequest = await prisma.documentRequest.findFirst({
            where: {
                id: requestId,
                message: {
                    senderId: userId,
                },
            },
            include: {
                message: true,
            },
        });

        if (!documentRequest) {
            return c.json({ error: 'Document request not found or unauthorized' }, 404);
        }

        // Mark the message as deleted
        await prisma.chatMessage.update({
            where: { id: documentRequest.messageId },
            data: { isDeleted: true }
        });

        // Mark the document request as deleted
        await prisma.documentRequest.update({
            where: { id: requestId },
            data: { status: 'DELETED' }
        });

        // Get the durable object to broadcast the deletion
        //@ts-ignore
        const durableId = c.env.CHATROOM.idFromName(roomId);
        //@ts-ignore
        const room = c.env.CHATROOM.get(durableId);

        await room.fetch(new Request('http://fake-host/broadcast-delete', {
            method: 'POST',
            body: JSON.stringify({
                type: 'message_deleted',
                roomId,
                messageId: documentRequest.messageId,
            })
        }));

        return c.json({ success: true });
    } catch (error) {
        console.error('Delete document request error:', error);
        return c.json({ error: 'Failed to delete document request' }, 500);
    }
});

export default app 
