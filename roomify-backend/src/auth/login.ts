import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import * as crypto from "crypto";
import { hashToken, signAndStoreToken, verifyPassword } from '../helper/helper';
import prismaClients from '../prisma';
import { PrismaD1 } from '@prisma/adapter-d1';
import { PrismaClient } from '@prisma/client';


const app = new Hono<{
    Bindings: Env,
    Variables: {
        userId: string;
    }
}>();


app.post('/login', async (c) => {
    try {
        const { email, password } = await c.req.json();
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        const user = await prisma.user.findUnique({
            where: { email },
            select: {
                id: true,
                passwordHash: true,
            },
        });

        if (!user || !verifyPassword(password, user.passwordHash)) {
            return c.json({ error: 'Invalid credentials' }, 401);
        }

        const token = await signAndStoreToken({ sub: user.id }, c);

        return c.json({ token });
    } catch (error) {
        console.error('Login error:', error);
        return c.json({ error: 'Failed to login' }, 500);
    }
});

app.post('/signout', async (c) => {
    try {
        const token = c.req.header('Authorization')?.split(' ')[1];
        if (!token) {
            return c.json({ error: 'No token provided' }, 401);
        }
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        const tokenHash = hashToken(token);

        // Delete token from active_tokens table using Prisma
        await prisma.activeToken.delete({
            where: {
                tokenHash: tokenHash
            }
        });

        return c.json({ message: 'Successfully signed out' });
    } catch (error) {
        //@ts-ignore
        if (error.code === 'P2025') {
            // Prisma error code for record not found
            return c.json({ message: 'Token already invalidated' });
        }
        console.error('Sign out error:', error);
        return c.json({
            error: 'Failed to sign out',
            //@ts-ignore

            details: error.message
        }, 500);
    }
});

export default app;