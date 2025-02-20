import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import * as crypto from "crypto";
import { hashToken, signAndStoreToken, verifyPassword } from '../helper/helper';
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

        if (!email || !password) {
            return c.json({ error: 'Email and password are required' }, 400);
        }

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const user = await prisma.user.findUnique({
            where: { email },
            select: {
                preferences: true,
                passwordHash: true,
                id: true,
                email: true,
                displayName: true,
                profileImageUrl: true,
                isProfessional: true,
                age: true,
                university: true,
                location: true,
                bio: true,
                gender: true,
                status: true,
            },
        });
        console.log(user);

        if (!user) {
            return c.json({ error: 'Invalid email or password' }, 401);
        }
        //decrypt the password to the original password


        const isValidPassword = await verifyPassword(password, user.passwordHash);
        if (!isValidPassword) {
            return c.json({ error: 'Invalid email or password' }, 401);
        }

        const token = await sign({ sub: user.id }, c.env.JWT_SECRET);

        return c.json({
            token,
            user: {
                id: user.id,
                email: user.email,
                displayName: user.displayName,
                profileImageUrl: user.profileImageUrl,
                isProfessional: user.isProfessional ?? false,
                age: user.age ?? null,
                university: user.university ?? null,
                location: user.location ?? null,
                bio: user.bio ?? null,
                gender: user.gender ?? null,
                status: user.status ?? null,
                preferences: user.preferences
            },
        });
    } catch (error) {
        console.error('Login error:', error);
        return c.json({
            error: 'Failed to login',
            details: error instanceof Error ? error.message : 'Unknown error',
        }, 500);
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

app.post('/auth/anonymous', async (c) => {
    try {
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Create an anonymous user with temporary data
        const anonymousUser = await prisma.user.create({
            data: {
                email: `anonymous_${Date.now()}@temp.roomify.com`,
                displayName: 'Guest User',
                passwordHash: '', // Empty password hash for anonymous users
                isAnonymous: true,
            },
            select: {
                id: true,
                email: true,
                displayName: true,
                profileImageUrl: true,
                isProfessional: true,
                isAnonymous: true,
                preferences: true,
            },
        });

        // Generate a temporary session token that expires in 24 hours
        const token = await signAndStoreToken({
            sub: anonymousUser.id,
            exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60) // 24 hours
        }, c);

        return c.json({
            token,
            user: anonymousUser,
        });
    } catch (error) {
        console.error('Anonymous login error:', error);
        return c.json({
            error: 'Failed to create anonymous session',
            details: error instanceof Error ? error.message : 'Unknown error',
        }, 500);
    }
});

//todo: when the user email is given, change th euser to professional
app.post('/make-professional', async (c) => {
    const { email } = await c.req.json();
    const adapter = new PrismaD1(c.env.DB);
    const prisma = new PrismaClient({ adapter });
    const user = await prisma.user.findUnique({ where: { email } });
    if (user) {
        await prisma.user.update({ where: { id: user.id }, data: { isProfessional: true } });
    }
    return c.json({ message: 'User made professional' });
});

export default app;