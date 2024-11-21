import { Hono } from 'hono';
import { uploadToR2 } from '../helper/helper';
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
        const userId = payload.sub;
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                favorites: true,
                listings: true,
            }
        });

        if (!user) {
            return c.json({ error: 'User not found' }, 404);
        }

        return c.json(user);
    } catch (error) {
        console.error('Get profile error:', error);
        return c.json({ error: 'Failed to get profile' }, 500);
    }
});

app.put('/', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) {
            return c.json({ error: 'Unauthorized' }, 401);
        }
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        
        const userId = payload.sub;
        const formData = await c.req.formData();

        // Get current user to check existing profile photo
        const currentUser = await prisma.user.findUnique({
            where: { id: userId },
            select: { profileImageUrl: true },
        });

        if (!currentUser) {
            return c.json({ error: 'User not found' }, 404);
        }

        // Handle profile photo
        const profilePhoto = formData.get('profilePhoto') as File;
        let profileImageUrl = currentUser.profileImageUrl;

        // Check if a new file is uploaded
        if (profilePhoto) {
            const newFileName = profilePhoto.name;

            // Extract the file name from the existing URL for comparison
            const existingFileName = currentUser.profileImageUrl
                ? currentUser.profileImageUrl.split('/').pop()
                : null;

            // If the file name is the same, skip R2 upload
            if (newFileName !== existingFileName) {
                const { fileUrl } = await uploadToR2(profilePhoto);
                console.log('Uploaded new profile photo URL:', fileUrl);
                profileImageUrl = fileUrl;
            } else {
                console.log('Profile photo unchanged, skipping upload.');
            }
        }

        // Prepare update data
        const updateData = {
            displayName: formData.get('displayName'),
            email: formData.get('email'),
            bio: formData.get('bio'),
            university: formData.get('university'),
            age: parseInt(formData.get('age') as string) || undefined,
            location: formData.get('location'),
            gender: formData.get('gender'),
            profileImageUrl: profileImageUrl, // Add profile image URL to update data
        };

        // Update user in database
        const updatedUser = await prisma.user.update({
            where: { id: userId },
            data: {
                displayName: updateData.displayName as string,
                email: updateData.email as string,
                bio: updateData.bio as string,
                university: updateData.university as string,
                age: updateData.age,
                location: updateData.location as string,
                gender: updateData.gender as string,
                profileImageUrl: updateData.profileImageUrl,
            },
            select: {
                id: true,
                displayName: true,
                email: true,
                bio: true,
                university: true,
                age: true,
                gender: true,
                location: true,
                profileImageUrl: true,
                language: true,
                receiveNotifications: true,
            },
        });
        console.log(updatedUser)
        return c.json(updatedUser);
    } catch (error) {
        console.error('Update profile error:', error);
        return c.json(
            {
                error: 'Failed to update profile',
                //@ts-ignore
                details: error.message,
            },
            500
        );
    }
});
app.delete('/profile-photo', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        const userId = payload.sub;
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: { profileImageUrl: true }
        });

        if (!user || !user.profileImageUrl) {
            return c.json({ error: 'No profile photo found' }, 404);
        }

        // Delete from R2
        await c.env.BUCKET.delete(user.profileImageUrl);

        // Update database
        await prisma.user.update({
            where: { id: userId },
            data: { profileImageUrl: null }
        });

        return c.json({ message: 'Profile photo deleted successfully' });
    } catch (error) {
        console.error('Failed to delete profile photo:', error);
        return c.json({ error: 'Failed to delete profile photo' }, 500);
    }
});

export default app;