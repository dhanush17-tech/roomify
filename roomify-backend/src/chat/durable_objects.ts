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

            console.log("WebSocket connection established for user",);

            // Handle incoming messages
            server.addEventListener('message', async (msg) => {
                try {
                    const data = JSON.parse(msg.data);
                    const { content, roomId } = data;

                    const adapter = new PrismaD1(this.env.DB);
                    const prisma = new PrismaClient({ adapter });
                    // Store message in the database
                    const message = await prisma.chatMessage.create({
                        data: {
                            content: content,
                            roomId: roomId,
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
                    const messageData = JSON.stringify({
                        type: 'message',
                        message: {
                            id: message.id,
                            content: message.content,
                            createdAt: message.createdAt,
                            senderId: message.senderId,
                            roomId: message.roomId,
                            sender: message.sender
                        }
                    });


                    this.sessions.forEach((ws) => {
                        if (ws.readyState === WebSocket.OPEN) {
                            ws.send(messageData);
                        }
                    });
                } catch (error) {
                    console.error('Message handling error:', error);
                }
            });

            // Handle connection closure
            server.addEventListener('close', () => {
                this.sessions.delete(userId);
                console.log(`Connection closed for user`);
            });

            // Return the WebSocket upgrade response with status 101
            return new Response(null, {
                status: 101,
                webSocket: client
            });
        } catch (error) {
            console.error('Authorization or WebSocket error:', error);
            return new Response(`Unauthorized: ${error.message}`, { status: 401 });
        }
    }
}
