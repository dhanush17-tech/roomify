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

        // Check if chat room already exists
        const existingRoom = await prisma.chatRoom.findFirst({
            where: {
                AND: [
                    {
                        participants: {
                            some: {
                                userId: userId
                            }
                        }
                    },
                    {
                        participants: {
                            some: {
                                userId: otherUserId
                            }
                        }
                    }
                ]
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
                }
            }
        });

        if (existingRoom) {
            return c.json({ room: existingRoom });
        }

        // Create new chat room
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
                }
            }
        });

        return c.json({ room: newRoom });
    } catch (error) {
        console.error('Create chat room error:', error);
        return c.json({
            error: 'Failed to create chat room',
            details: error.message
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

export default app 