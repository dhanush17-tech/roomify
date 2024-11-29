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


app.put('/preferences', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        const userId = payload.sub;
        const { interests, preferences, socialLinks } = await c.req.json();

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Delete existing preferences
        await prisma.userInterest.deleteMany({
            where: { userId }
        });

        await prisma.userPreference.deleteMany({
            where: { userId }
        });

        await prisma.userSocialLink.deleteMany({
            where: { userId }
        });

        // Create new interests
        if (interests?.length) {
            for (const interest of interests) {
                await prisma.userInterest.create({
                    data: {
                        userId,
                        interest
                    }
                });
            }
        }

        // Create new preferences
        if (preferences?.length) {
            for (const preference of preferences) {
                await prisma.userPreference.create({
                    data: {
                        userId,
                        preference
                    }
                });
            }
        }

        // Create new social links
        if (socialLinks) {
            for (const [platform, username] of Object.entries(socialLinks)) {
                await prisma.userSocialLink.create({
                    data: {
                        userId,
                        platform,
                        username: username as string
                    }
                });
            }
        }

        // Get updated user data
        const updatedUser = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                interests: true,
                preferences: true,
                socialLinks: true
            }
        });
        console.log(updatedUser);
        return c.json(updatedUser);
    } catch (error) {
        console.error('Update preferences error:', error);
        return c.json({
            error: 'Failed to update preferences',
            details: error.message
        }, 500);
    }
});
app.put('/api/user/preferences', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        const userId = payload.sub;
        const { interests, preferences, socialLinks } = await c.req.json();

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Delete existing preferences
        await prisma.userInterest.deleteMany({
            where: { userId }
        });

        await prisma.userPreference.deleteMany({
            where: { userId }
        });

        await prisma.userSocialLink.deleteMany({
            where: { userId }
        });

        // Create new interests
        if (interests?.length) {
            for (const interest of interests) {
                await prisma.userInterest.create({
                    data: {
                        userId,
                        interest
                    }
                });
            }
        }

        // Create new preferences
        if (preferences?.length) {
            for (const preference of preferences) {
                await prisma.userPreference.create({
                    data: {
                        userId,
                        preference
                    }
                });
            }
        }

        // Create new social links
        if (socialLinks) {
            for (const [platform, username] of Object.entries(socialLinks)) {
                await prisma.userSocialLink.create({
                    data: {
                        userId,
                        platform,
                        username: username as string
                    }
                });
            }
        }

        // Get updated user data
        const updatedUser = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                interests: true,
                preferences: true,
                socialLinks: true
            }
        });

        return c.json(updatedUser);
    } catch (error) {
        console.error('Update preferences error:', error);
        return c.json({
            error: 'Failed to update preferences',
            details: error.message
        }, 500);
    }
});

export default app