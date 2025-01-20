import { Context, Hono } from 'hono';
import { randomBytes } from 'crypto';
import { hashPassword, signAndStoreToken } from '../helper/helper';
import { PrismaD1 } from '@prisma/adapter-d1';
import { PrismaClient } from '@prisma/client';

const app = new Hono<{
    Bindings: Env,
    Variables: {
        userId: string;
    }
}>();

app.post('/register', async (c: Context<{
    Bindings: Env;
    Variables: {
        userId: string;
    };
}>,) => {
    try {
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        const { email, password, displayName, age, university, location } = await c.req.json();

        // Validate required fields
        if (!email || !password || !displayName) {
            return c.json({ error: 'Missing required fields' }, 400);
        }

        // Check existing user
        const existingUser = await prisma.user.findFirst({
            where: {
                OR: [
                    { email },
                ]
            }
        });

        if (existingUser) {
            return c.json({ error: 'User already exists' }, 400);
        }

        const salt = randomBytes(16).toString('hex');
        const hashedPassword = await hashPassword(password, salt);

        const user = await prisma.user.create({
            data: {
                email,
                displayName,
                passwordHash: hashedPassword,
                age,
                university,
                location,
            },
        });

        const token = await signAndStoreToken({ sub: user.id, }, c);

        return c.json({ token });
    } catch (error) {
        console.error('Registration error:', error);
        return c.json({ error: 'Failed to register' }, 500);
    }
});

export default app;