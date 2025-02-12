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
        const {
            email,
            password,
            displayName,
            age,
            university,
            location,
            latitude,
            longitude,
            isProfessional,
            phoneNumber
        } = await c.req.json();

        // Log the received data for debugging
        console.log('Registration data:', {
            email,
            displayName,
            isProfessional,
            phoneNumber,
            location,
            latitude,
            longitude
        });

        // Validate required fields
        if (!email || !password || !displayName) {
            return c.json({ error: 'Missing required fields' }, 400);
        }

        // Validate phone number for non-professional users
        if (!isProfessional && !phoneNumber) {
            return c.json({ error: 'Phone number is required for regular users' }, 400);
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
            return c.json({ error: 'Email already exists' }, 400);
        }

        const hashedPassword = await hashPassword(password);

        // Create user with explicit boolean conversion for isProfessional
        const user = await prisma.user.create({
            data: {
                email,
                displayName,
                passwordHash: hashedPassword,
                age: age || null,
                university: university || null,
                location: location || null,
                latitude: latitude || null,
                longitude: longitude || null,
                isProfessional: Boolean(isProfessional),
                phoneNumber: !isProfessional ? phoneNumber : null,
            },
            include: {
                preferences: true,
                socialLinks: true,
            }
        });

        // Log the created user for debugging
        console.log('Created user:', {
            id: user.id,
            isProfessional: user.isProfessional,
            location: user.location,
            coordinates: `${user.latitude},${user.longitude}`
        });

        // Create token
        const token = await signAndStoreToken({ sub: user.id }, c);

        // Format the response to match the expected structure
        const formattedUser = {
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            age: user.age,
            university: user.university,
            location: user.location,
            latitude: user.latitude,
            longitude: user.longitude,
            isProfessional: user.isProfessional,
            profileImageUrl: user.profileImageUrl,
            preferences: user.preferences.map(p => ({ preference: p.preference })),
            phoneNumber: user.phoneNumber,
            bio: user.bio,
            gender: user.gender,
            status: user.status,
            isProfileComplete: () => true,
        };

        return c.json({
            user: formattedUser,
            token
        });
    } catch (error) {
        console.error('Registration error:', error);
        return c.json({ error: 'Failed to register' }, 500);
    }
});

export default app;