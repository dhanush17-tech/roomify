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


app.post('/', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const formData = await c.req.formData();
        const listingData = JSON.parse(formData.get('listing') as string);

        // Handle image uploads
        const images = formData.getAll('images') as File[];
        const imageUrls: string[] = [];

        // Upload each image to R2
        for (const image of images) {
            const { fileUrl } = await uploadToR2(image, "propertyImages");
            imageUrls.push(fileUrl);
        }

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Check for existing property
        const existingListing = await prisma.listing.findFirst({
            where: {
                AND: [
                    { title: listingData.title },
                    { location: listingData.location },
                    { type: 'Property' }
                ]
            }
        });

        if (existingListing) {
            return c.json({
                error: 'A property with this title and location already exists'
            }, 400);
        }

        // Create listing with uploaded image URLs
        const listing = await prisma.listing.create({
            data: {
                type: 'Property',
                title: listingData.title,
                description: listingData.description,
                price: listingData.price,
                location: listingData.location,
                latitude: listingData.latitude,
                longitude: listingData.longitude,
                userId,
                isFavorite: false,
                property: {
                    create: {
                        moveInDate: listingData.property.moveInDate,
                        moveOutDate: listingData.property.moveOutDate,
                        numberOfBedrooms: listingData.property.numberOfBedrooms,
                        numberOfBathrooms: listingData.property.numberOfBathrooms,
                        maxOccupancy: listingData.property.maxOccupancy,
                        isLookingForRoomate: listingData.property.isLookingForRoomate,
                        rating: 0,
                        amenities: {
                            create: listingData.property.amenities?.map((amenity: string) => ({
                                amenity
                            })) || []
                        },
                        ...(listingData.property.tags && {
                            tags: {
                                create: listingData.property.tags.map((tag: string) => ({
                                    tag
                                }))
                            }
                        }),
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
                    include: {
                        preferences: true,
                    }
                }, property: {
                    include: {
                        amenities: true,
                        tags: true,
                        images: true,

                    }
                },
                favorites: true,
            }
        });

        const formattedListing = {
            id: listing.id,
            type: 'Property',
            title: listing.title,
            description: listing.description,
            createdAt: listing.createdAt.toISOString(),
            user: {
                id: listing.user.id,
                displayName: listing.user.displayName,
                profileImageUrl: listing.user.profileImageUrl,
                email: listing.user.email,
            },
            location: listing.location,
            price: listing.price,
            isFavorite: false,
            latitude: listing.latitude,
            longitude: listing.longitude,
            imageUrls: listing.property?.images.map(img => img.imageUrl) ?? [],
            property: {
                moveInDate: listing.property!.moveInDate, // Add this line
                moveOutDate: listing.property!.moveOutDate, // Add this line
                numberOfBedrooms: listing.property!.numberOfBedrooms,
                numberOfBathrooms: listing.property!.numberOfBathrooms,
                maxOccupancy: listing.property!.maxOccupancy,
                isLookingForRoomate: listing.property!.isLookingForRoomate,
                rating: listing.property!.rating,
                amenities: listing.property!.amenities.map(a => a.amenity),
                tags: listing.property!.tags?.map(t => t.tag) ?? [],
                comments: []
            },
            marketplaceItem: null
        };
        return c.json({ listing: formattedListing });
    } catch (error) {
        console.error('Create property error:', error);
        if (error instanceof SyntaxError) {
            return c.json({
                error: 'Invalid JSON format',
                details: error.message
            }, 400);
        }
        return c.json({
            error: 'Failed to create property',
            details: error.message
        }, 500);
    }
});

app.get('/', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);
        const userId = payload.sub;

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const listings = await prisma.listing.findMany({
            where: {
                type: 'Property',
                NOT: { userId },
            },

            include: {
                user: {
                    include: {
                        preferences: true,
                    }
                },

                property: {
                    include: {
                        amenities: true,
                        tags: true,

                        images: true,
                    }
                },
                favorites: true,
            },
            orderBy: {
                createdAt: 'desc'
            }
        });

        const formattedListings = listings.map(listing => ({
            id: listing.id,
            type: 'Property',
            title: listing.title,
            description: listing.description,
            createdAt: listing.createdAt.toISOString(),
            user: {
                id: listing.user.id,
                displayName: listing.user.displayName,
                profileImageUrl: listing.user.profileImageUrl,
                email: listing.user.email,
            },
            location: listing.location,
            price: listing.price,
            isFavorite: listing.favorites.length > 0,
            latitude: listing.latitude,
            longitude: listing.longitude,
            imageUrls: listing.property?.images.map(img => img.imageUrl) ?? [],
            property: listing.property ? {
                numberOfBedrooms: listing.property.numberOfBedrooms,
                numberOfBathrooms: listing.property.numberOfBathrooms,
                moveInDate: listing.property!.moveInDate, // Add this line
                moveOutDate: listing.property!.moveOutDate, // Add this line
                maxOccupancy: listing.property.maxOccupancy,
                isLookingForRoomate: listing.property.isLookingForRoomate,
                rating: listing.property.rating,
                amenities: listing.property.amenities.map(a => a.amenity),
                tags: listing.property.tags.map(t => t.tag),
                comments: listing.property.comments.map(comment => ({
                    id: comment.id,
                    propertyId: comment.propertyId,
                    userId: comment.userId,
                    comment: comment.comment,
                    createdAt: comment.createdAt.toISOString(),
                    user: {
                        id: comment.user.id,
                        displayName: comment.user.displayName,
                        profileImageUrl: comment.user.profileImageUrl,
                    }
                }))
            } : null,
            marketplaceItem: null
        }));

        return c.json({ listings: formattedListings });
    } catch (error) {
        console.error('Get properties error:', error);
        return c.json({ error: 'Failed to fetch properties' }, 500);
    }
});



app.get('/recommended-listings', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        const userId = payload.sub;
        const latitude = Number(c.req.query('latitude'));
        const longitude = Number(c.req.query('longitude'));
        const radius = Number(c.req.query('radius')) || 10;

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Get current user
        const currentUser = await prisma.user.findUnique({
            where: { id: userId },
            select: {
                university: true,
                preferences: true,
                socialLinks: true,
            }
        });

        // Find listings
        const listings = await prisma.listing.findMany({
            where: {
                type: 'Property',
                NOT: { userId: userId },
                user: currentUser?.university ? {
                    university: currentUser.university
                } : undefined
            },
            include: {
                user: {
                    include: {
                        preferences: true,
                    }
                },
                property: {
                    include: {
                        amenities: true,
                        tags: true,

                        images: true,
                    }
                },
                favorites: true,
            },
            orderBy: {
                createdAt: 'desc'
            }
        });

        const formattedListings = listings.map(listing => ({
            id: listing.id,
            type: 'Property',
            title: listing.title,
            description: listing.description,
            createdAt: listing.createdAt.toISOString(),
            user: listing.user,
            location: listing.location,
            price: listing.price,
            latitude: listing.latitude,
            longitude: listing.longitude,
            imageUrls: listing.property?.images.map(img => img.imageUrl) ?? [],
            property: listing.property ? {
                moveInDate: listing.property!.moveInDate, // Add this line
                moveOutDate: listing.property!.moveOutDate, // Add this line
                numberOfBedrooms: listing.property.numberOfBedrooms,
                numberOfBathrooms: listing.property.numberOfBathrooms,
                maxOccupancy: listing.property.maxOccupancy,
                isLookingForRoomate: listing.property.isLookingForRoomate,
                rating: listing.property.rating,


            } : null,
            marketplaceItem: null
        }));
        console.log(formattedListings)

        // Calculate distances and sort
        const recommendedListings = listings
        // .map(listing => ({
        //     ...listing,
        //     distance: calculateDistance(
        //         latitude,
        //         longitude,
        //         listing.property?.latitude || 0,
        //         listing.property?.longitude || 0
        //     )
        // }))
        // .filter(listing => listing.distance <= radius)
        // .sort((a, b) => {
        //     // First sort by university match
        //     const aMatch = a.user.university === currentUser?.university;
        //     const bMatch = b.user.university === currentUser?.university;
        //     if (aMatch !== bMatch) return bMatch ? 1 : -1;

        //     // Then sort by distance
        //     return a.distance - b.distance;
        // });

        return c.json({
            results: formattedListings
        });

    } catch (error) {
        console.error('Recommendation error:', error);
        return c.json({
            error: 'Failed to get recommendations',
            details: error.message
        }, 500);
    }

});


app.get('/pair-up', async (c) => {
    console.log("Dwedewdewew");
    try {
        const payload = c.get('jwtPayload');
        if (!payload) {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        const userId = payload.sub;
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Get current user
        const currentUser = await prisma.user.findUnique({
            where: { id: userId },
            select: {
                university: true,
                location: true,
            }
        });

        // Find properties with users looking for roommates
        const pairUps = await prisma.listing.findMany({
            where: {
                type: 'Property',
                NOT: { userId: userId },
                property: {
                    isLookingForRoomate: true,
                },
                user: currentUser?.university ? {
                    university: currentUser.university
                } : undefined
            },
            include: {
                property: {
                    include: {
                        amenities: true,
                        categories: true,
                        images: true,

                    }
                },
                user: {
                    include: {
                        preferences: true,
                    }
                }

            },
            orderBy: {
                createdAt: 'desc'
            }
        });


        const formattedListings = pairUps.map(listing => ({
            id: listing.id,
            type: 'Property',
            title: listing.title,
            description: listing.description,
            createdAt: listing.createdAt.toISOString(),
            user: listing.user,
            location: listing.location,
            price: listing.price,
            latitude: listing.latitude,
            longitude: listing.longitude,
            imageUrls: listing.property?.images.map(img => img.imageUrl) ?? [],
            property: listing.property ? {
                numberOfBedrooms: listing.property.numberOfBedrooms,
                numberOfBathrooms: listing.property.numberOfBathrooms,
                moveInDate: listing.property!.moveInDate, // Add this line
                moveOutDate: listing.property!.moveOutDate, // Add this line
                maxOccupancy: listing.property.maxOccupancy,
                isLookingForRoomate: listing.property.isLookingForRoomate,
                rating: listing.property.rating,
                amenities: listing.property.amenities.map(a => a.amenity),

            } : null,
            marketplaceItem: null

        })

        );


        return c.json({
            results: formattedListings
        });

    } catch (error) {
        console.error('Pair-up error:', error);
        return c.json({
            error: 'Failed to get pair-up suggestions',
            details: error.message
        }, 500);
    }
});
app.get('/favorites', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const favorites = await prisma.favorite.findMany({
            where: { userId },
            include: {
                listing: {
                    include: {
                        marketplace: {
                            include: {
                                images: true,
                                categories: true,
                            }
                        },
                        property: {
                            include: {
                                amenities: true,
                                tags: true,
                                images: true
                            }
                        },
                        user: {
                            include: {
                                preferences: true,
                            }
                        }

                    }
                }
            }
        });

        return c.json({
            favorites: favorites.map(f => ({
                ...f.listing,
                marketplaceItem: {
                    ...f.listing.marketplace,
                    categories: f.listing.marketplace?.categories.map(c => c.category),
                },
                property: f.listing.property ? {
                    ...f.listing.property,
                    amenities: f.listing.property.amenities.map(a => a.amenity),
                    tags: f.listing.property.tags.map(t => t.tag),
                    imageUrls: f.listing.property.images.map(i => i.imageUrl)
                } : null
            }))
        });
    } catch (error) {
        return c.json({ error: 'Failed to fetch favorites' }, 500);
    }
});

// Add favorite
app.post('/favorites', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const { listingId } = await c.req.json();

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Check if favorite already exists
        const existingFavorite = await prisma.favorite.findUnique({
            where: {
                userId_listingId: {
                    userId,
                    listingId
                }
            }
        });

        if (existingFavorite) {
            return c.json({
                error: 'Listing is already in favorites'
            }, 400);
        }

        // Create favorite if it doesn't exist
        await prisma.favorite.create({
            data: {
                userId,
                listingId
            }
        });

        return c.json({ success: true });
    } catch (error) {
        console.error('Add favorite error:', error);
        return c.json({
            error: 'Failed to add favorite',
            details: error.message
        }, 500);
    }
});

// Remove favorite
app.delete('/favorites/:listingId', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const listingId = parseInt(c.req.param('listingId'));

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        await prisma.favorite.delete({
            where: {
                userId_listingId: {
                    userId,
                    listingId
                }
            }
        });

        return c.json({ success: true });
    } catch (error) {
        return c.json({ error: 'Failed to remove favorite' }, 500);
    }
});


// Helper function to calculate distance between two points
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    // If coordinates are very close (essentially the same location)
    const tolerance = 0.0001; // Adjust this value as needed
    if (Math.abs(lat1 - lat2) < tolerance && Math.abs(lon1 - lon2) < tolerance) {
        return 0;
    }

    const R = 6371; // Earth's radius in km
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

function toRad(degrees: number): number {
    return degrees * (Math.PI / 180);
}



export default app;