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
        if (!payload) {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        const userId = payload.sub;
        const formData = await c.req.formData();
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Extract property data
        const data = {
            title: formData.get('title'),
            description: formData.get('description'),
            location: formData.get('location'),
            price: Number(formData.get('price')),
            numberOfBedrooms: Number(formData.get('numberOfBedrooms')),
            numberOfBathrooms: Number(formData.get('numberOfBathrooms')),
            maxOccupancy: Number(formData.get('maxOccupancy')),
            amenities: formData.get('amenities')?.toString().split(',') || [],
            categories: formData.get('categories')?.toString().split(',') || [],
            type: formData.get('type'),
            longitude: Number(formData.get('longitude')),
            latitude: Number(formData.get('latitude')),
            isLookingForRoomate: formData.get("isLookingForRoomate") === 'true'
        };

        // Get images
        const images = formData.getAll('images') as File[];

        // Create listing
        const listing = await prisma.listing.create({
            data: {
                type: 'Property',
                title: data.title as string,
                description: data.description as string,
                userId: userId,
                location: data.location as string,
                price: data.price,
                latitude: data.latitude,
                longitude: data.longitude


            },
        });

        // Create property
        const property = await prisma.property.create({
            data: {
                listingId: listing.id,
                isLookingForRoomate: data.isLookingForRoomate,
                numberOfBedrooms: data.numberOfBedrooms,
                numberOfBathrooms: data.numberOfBathrooms,
                maxOccupancy: data.maxOccupancy,
            },
        });

        // Create amenities
        const amenityPromises = data.amenities.map(amenity =>
            prisma.propertyAmenity.create({
                data: {
                    propertyId: property.listingId,
                    amenity: amenity
                }
            })
        );
        await Promise.all(amenityPromises);

        // Create categories
        const categoryPromises = data.categories.map(category =>
            prisma.propertyCategory.create({
                data: {
                    propertyId: property.listingId,
                    category: category
                }
            })
        );
        await Promise.all(categoryPromises);

        // Handle image uploads
        if (images.length) {
            const imagePromises = images.map(async (image) => {
                const { fileUrl } = await uploadToR2(image);
                return prisma.propertyImage.create({
                    data: {
                        propertyId: property.listingId,
                        imageUrl: fileUrl
                    }
                });
            });
            await Promise.all(imagePromises);
        }

        return c.json({
            success: true,
            propertyId: property.listingId
        });

    } catch (error) {
        console.error('Create property error:', error);
        return c.json({
            error: 'Failed to create property',
            details: error instanceof Error ? error.message : 'Unknown error',
        }, 500);
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
                property: {
                    include: {
                        amenities: true,
                        categories: true,
                        images: true,
                    }
                },
                user: {
                    select: {
                        id: true,
                        displayName: true,
                        profileImageUrl: true,
                        university: true
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
            }
        });

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
            results: recommendedListings.map(listing => ({
                id: listing.id,
                title: listing.title,
                description: listing.description,
                location: listing.location,
                price: listing.price,
                distance: listing.distance,
                numberOfBedrooms: listing.property?.numberOfBedrooms,
                numberOfBathrooms: listing.property?.numberOfBathrooms,
                maxOccupancy: listing.property?.maxOccupancy,
                amenities: listing.property?.amenities.map(a => a.amenity) || [],
                categories: listing.property?.categories.map(c => c.category) || [],
                images: listing.property?.images.map(i => i.imageUrl) || [],
                isLookingForRoomate: listing.property?.isLookingForRoomate,
                user: listing.user,
                createdAt: listing.createdAt,
                universityMatch: listing.user.university === currentUser?.university
            }))
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
                    select: {
                        id: true,
                        displayName: true,
                        profileImageUrl: true,
                        university: true,
                        age: true,
                        gender: true,
                        bio: true,
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
            }
        });

        return c.json({
            results: pairUps.map(listing => ({
                id: listing.id,
                title: listing.title,
                description: listing.description,
                location: listing.location,
                price: listing.price,
                numberOfBedrooms: listing.property?.numberOfBedrooms,
                numberOfBathrooms: listing.property?.numberOfBathrooms,
                maxOccupancy: listing.property?.maxOccupancy,
                amenities: listing.property?.amenities.map(a => a.amenity) || [],
                categories: listing.property?.categories.map(c => c.category) || [],
                images: listing.property?.images.map(i => i.imageUrl) || [],
                user: listing.user,
                createdAt: listing.createdAt,
                isLookingForRoomate: listing.property?.isLookingForRoomate,
                universityMatch: listing.user.university === currentUser?.university
            }))
        });

    } catch (error) {
        console.error('Pair-up error:', error);
        return c.json({
            error: 'Failed to get pair-up suggestions',
            details: error.message
        }, 500);
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