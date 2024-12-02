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
                favorites: {
                    include: {
                        listing: true
                    }
                },
                listings: true,
                 preferences: true,
                socialLinks: true,
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

        console.log("This isteh status", formData.get('status'));
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
                const { fileUrl } = await uploadToR2(profilePhoto, "profilePhotos");
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
            status: formData.get('status'),
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
                status: updateData.status as string,
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
                status: true,
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


app.get('/listings', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const listings = await prisma.listing.findMany({
            where: { userId },
            include: {
                property: {
                    include: {
                        amenities: true,
                        tags: true,
                        images: true,
                    }
                },
                marketplace: {
                    include: {
                        images: true,
                        categories: true
                    }
                },
                user: {
                    select: {
                        id: true,
                        displayName: true,
                        profileImageUrl: true,
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
            }
        });

        const formattedListings = listings.map(listing => ({
            ...listing,
            property: listing.property ? {
                ...listing.property,
                amenities: listing.property.amenities.map(a => a.amenity),
                tags: listing.property.tags.map(t => t.tag),
                imageUrls: listing.property.images.map(i => i.imageUrl)
            } : null,
            marketplace: listing.marketplace ? {
                ...listing.marketplace,
                categories: listing.marketplace.categories.map(c => c.category),
                imageUrls: listing.marketplace.images.map(i => i.imageUrl)
            } : null
        }));

        return c.json({ listings: formattedListings });
    } catch (error) {
        return c.json({ error: 'Failed to fetch user listings' }, 500);
    }
});

app.delete('/listings/:id', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const listingId = parseInt(c.req.param('id'));

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Check if listing exists and belongs to user
        const listing = await prisma.listing.findFirst({
            where: {
                id: listingId,
                userId
            },
            include: {
                property: true,
                marketplace: true
            }
        });

        if (!listing) {
            return c.json({ error: 'Listing not found or unauthorized' }, 404);
        }

        if (listing.property) {
            // Delete property related records first
            await prisma.propertyAmenity.deleteMany({
                where: { propertyId: listing.property.listingId }
            });
            await prisma.propertyTag.deleteMany({
                where: { propertyId: listing.property.listingId }
            });
            await prisma.propertyImage.deleteMany({
                where: { propertyId: listing.property.listingId }
            });
            await prisma.propertyCategory.deleteMany({
                where: { propertyId: listing.property.listingId }
            });
            await prisma.comment.deleteMany({
                where: { propertyId: listing.property.listingId }
            });
            await prisma.property.delete({
                where: { listingId: listing.id }
            });
        }

        if (listing.marketplace) {
            // Delete marketplace related records
            await prisma.marketplaceImage.deleteMany({
                where: { itemId: listing.marketplace.listingId }
            });
            await prisma.marketplaceCategory.deleteMany({
                where: { itemId: listing.marketplace.listingId }
            });
            await prisma.marketplaceItem.delete({
                where: { listingId: listing.id }
            });
        }

        // Delete favorites
        await prisma.favorite.deleteMany({
            where: { listingId }
        });

        // Finally delete the listing
        await prisma.listing.delete({
            where: { id: listingId }
        });

        return c.json({ success: true });
    } catch (error) {
        console.error('Delete listing error:', error);
        return c.json({ error: 'Failed to delete listing' }, 500);
    }
});

app.put('/location', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const { latitude, longitude } = await c.req.json();

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        await prisma.user.update({
            where: { id: userId },
            data: {
                latitude,
                longitude,
            }
        });

        return c.json({ success: true });
    } catch (error) {
        return c.json({ error: 'Failed to update location' }, 500);
    }
});
export default app;