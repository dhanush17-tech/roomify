import { Hono } from 'hono';
import { PrismaD1 } from '@prisma/adapter-d1';
import { PrismaClient } from '@prisma/client';
import { uploadToR2 } from '../helper/helper';

const app = new Hono<{
    Bindings: Env,
    Variables: {
        userId: string;
    }
}>();

// Get all marketplace items
app.get('/', async (c) => {
    try {
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const items = await prisma.listing.findMany({
            where: {
                type: 'Marketplace'
            },
            include: {
                user: {
                    select: {
                        id: true,
                        displayName: true,
                        profileImageUrl: true,
                    }
                },
                
                marketplace: {
                    include: {
                        images: true
                    }
                },
                favorites: true
            },
            orderBy: {
                createdAt: 'desc'
            }
        });
        console.log(items);
        return c.json({ items });
    } catch (error) {
        return c.json({ error: 'Failed to fetch marketplace items' }, 500);
    }
});


// Create marketplace item
app.post('/', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const formData = await c.req.formData();

        const listingData = JSON.parse(formData.get('listing') as string);
        const images = formData.getAll('images') as File[];
        const imageUrls: string[] = [];

        for (const image of images) {
            const { fileUrl } = await uploadToR2(image, "marketplaceImages");
            imageUrls.push(fileUrl);
        }

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const listing = await prisma.listing.create({
            data: {
                type: 'Marketplace',
                title: listingData.title,
                description: listingData.description,
                price: listingData.price,
                location: listingData.location,
                latitude: listingData.latitude,
                longitude: listingData.longitude,
                userId,
                isFavorite: false,
                marketplace: {
                    create: {
                        categories: {
                            create: listingData.categories.map((category: string) => ({
                                category
                            }))
                        },
                        images: {
                            create: imageUrls.map(url => ({
                                imageUrl: url
                            }))
                        }
                    }
                }
            },
            include: {
                user: {
                    select: {
                        id: true,
                        displayName: true,
                        profileImageUrl: true,
                    }
                },
                marketplace: {
                    include: {
                        categories: true,
                        images: true
                    }
                }
            }
        });

        const formattedListing = {
            id: listing.id,
            type: 'Marketplace',
            title: listing.title,
            description: listing.description,
            createdAt: listing.createdAt.toISOString(),
            user: listing.user,
            location: listing.location,
            price: listing.price,
            isFavorite: false,
            latitude: listing.latitude,
            longitude: listing.longitude,
            imageUrls: listing.marketplace?.images.map(img => img.imageUrl) ?? [],
            marketplaceItem: {
                categories: listing.marketplace?.categories.map(c => c.category) ?? []
            },
            property: null
        };

        return c.json({ listing: formattedListing });
    } catch (error) {
        return c.json({ error: 'Failed to create marketplace item' }, 500);
    }
});

app.put('/:id', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const id = parseInt(c.req.param('id'));
        const data = await c.req.json();

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Check if user owns the listing
        const existingItem = await prisma.listing.findUnique({
            where: { id },
            select: { userId: true }
        });

        if (!existingItem || existingItem.userId !== userId) {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        // Update listing
        await prisma.listing.update({
            where: { id },
            data: {
                title: data.title,
                description: data.description,
                price: parseFloat(data.price),
                location: data.location,
                latitude: data.latitude ? parseFloat(data.latitude) : null,
                longitude: data.longitude ? parseFloat(data.longitude) : null,
            }
        });

        // Update marketplace item relations
        const marketplaceItem = await prisma.marketplaceItem.update({
            where: { listingId: id },
            data: {
                // Update categories
                categories: {
                    deleteMany: {},
                    create: data.categories.map((category: string) => ({
                        category: category
                    }))
                },
                // Update images
                images: {
                    deleteMany: {},
                    create: data.imageUrls.map((url: string) => ({
                        imageUrl: url
                    }))
                }
            },
            include: {
                listing: {
                    include: {
                        user: {
                            select: {
                                id: true,
                                displayName: true,
                                profileImageUrl: true,
                            }
                        }
                    }
                },
                categories: true,
                images: true
            }
        });

        return c.json({
            success: true,
            item: {
                ...marketplaceItem.listing,
                categories: marketplaceItem.categories.map(c => c.category),
                imageUrls: marketplaceItem.images.map(i => i.imageUrl)
            }
        });

    } catch (error) {
        return c.json({ error: 'Failed to update marketplace item' }, 500);
    }
});

export default app;