import { Context, Hono } from 'hono';
import { sign } from 'hono/jwt';
import * as crypto from "crypto";
import { signAndStoreToken, uploadToR2, deleteFromR2, verifyPassword, getAddressFromLatLong } from '../helper/helper';
import { PrismaD1 } from '@prisma/adapter-d1';
import { PrismaClient } from '@prisma/client';
import { sendNotification } from '../chat/durable_objects';

// Add these type definitions at the top of the file after the imports
interface WalkScoreResponse {
    status: number;
    walkscore: number;
    description: string;
    transit?: {
        score: number;
        description: string;
        summary: string;
    };
}




const app = new Hono<{
    Bindings: {
        DB: D1Database;
        JWT_SECRET: string;
        WALK_SCORE_API_KEY: string;
    },
    Variables: {
        userId: string;
    }
}>();


app.post('/', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Check if user is professional and already has a listing
        const user = await prisma.user.findUnique({
            where: { id: payload.sub },
            include: {
                listings: true,
            },
        });

        if (!user) {
            return c.json({ error: 'User not found' }, 404);
        }

        if (user.isProfessional && user.listings.length > 0) {
            return c.json({ error: 'Professional users can only have one listing' }, 400);
        }

        const formData = await c.req.formData();
        const listingData = JSON.parse(formData.get('listing') as string);

        // Handle image uploads
        const images = formData.getAll('images') as File[];
        const imageUrls: string[] = [];

        // Upload each image to R2
        for (const image of images) {
            const { fileUrl } = await uploadToR2(image, "propertyImages", c);
            imageUrls.push(fileUrl);
        }

        //take the lat and long and use the mapbox geocoding api to get the address
        const address = await getAddressFromLatLong(listingData.latitude, listingData.longitude, c);

        // Create the listing
        const listing = await prisma.listing.create({
            data: {
                type: 'Property',
                title: listingData.title,
                location: address,
                price: listingData.price,
                latitude: listingData.latitude,
                longitude: listingData.longitude,
                description: listingData.description,
                userId: payload.sub,
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
                        categories: {
                            create: listingData.property.categories?.map((category: string) => ({
                                category
                            })) || []
                        },
                        images: {
                            create: imageUrls.map(url => ({
                                imageUrl: url
                            }))
                        },
                        floorPlans: {
                            create: listingData.floorPlans.map((floorPlan: any) => ({
                                imageUrl: floorPlan.imageUrl,
                                unitsAvailable: floorPlan.unitsAvailable,
                                price: floorPlan.price,
                                bedrooms: floorPlan.bedrooms,
                                bathrooms: floorPlan.bathrooms,
                                squareFootage: floorPlan.squareFootage,
                                name: floorPlan.name,
                            }))
                        },
                        offers: {
                            create: listingData.property.offers?.map((offer: any) => ({
                                title: offer.title,
                                description: offer.description,
                                validUntil: new Date(offer.validUntil),
                            })) || []
                        }
                    }
                }
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
                        categories: true,
                        images: true,
                        floorPlans: true,
                        offers: true
                    }
                }
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
            location: address,
            price: listing.price,
            isFavorite: false,
            latitude: listing.latitude,
            longitude: listing.longitude,
            imageUrls: listing.property?.images.map(img => img.imageUrl) ?? [],
            floorPlans: listing.property!.floorPlans,
            property: {
                categories: listing.property!.categories,
                moveInDate: listing.property!.moveInDate, // Add this line
                moveOutDate: listing.property!.moveOutDate, // Add this line
                numberOfBedrooms: listing.property!.numberOfBedrooms,
                numberOfBathrooms: listing.property!.numberOfBathrooms,
                maxOccupancy: listing.property!.maxOccupancy,
                isLookingForRoomate: listing.property!.isLookingForRoomate,
                rating: listing.property!.rating,
                amenities: listing.property!.amenities,
                tags: listing.property!.tags ?? [],
                comments: [],
                offers: listing.property!.offers
            },
            marketplaceItem: null
        };
        return c.json({ listing: formattedListing });
    } catch (error: unknown) {
        console.error('Create property error:', error);
        if (error instanceof SyntaxError) {
            return c.json({
                error: 'Invalid JSON format',
                details: error.message
            }, 400);
        }
        return c.json({
            error: 'Failed to create property',
            details: error instanceof Error ? error.message : 'Unknown error'
        }, 500);
    }
});

app.get('/', async (c) => {
    try {
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const userId = c.get('jwtPayload')?.sub;

        const listings =
        
            await prisma.listing.findMany({
            where: {
                type: 'Property',
                reported: false,
                OR: [
                    // For normal users' listings with valid move-in dates
                    {
                        user: {
                            isProfessional: false
                        },
                        property: {
                            OR: [
                                { moveInDate: 'Anytime' },
                                {
                                    moveInDate: {
                                        gte: new Date().toISOString().slice(0, 7) // Current date in YYYY-MM format
                                    }
                                }
                            ]
                        }
                    },
                    // For professional users' listings with available units
                    {
                        user: {
                            isProfessional: true
                        },
                        property: {
                            floorPlans: {
                                some: {
                                    unitsAvailable: {
                                        gt: 0
                                    }
                                }
                            }
                        }
                    }
                ]
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
                        categories: true,
                        images: true,
                        floorPlans: true,
                        offers: true,
                    }
                },
                favorites: {
                    where: userId ? { userId } : undefined
                }
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
                isProfessional: listing.user.isProfessional
            },
            location: listing.location,
            price: listing.price,
            isFavorite: listing.favorites.length > 0,
            moveInDate: listing.property?.moveInDate,
            moveOutDate: listing.property?.moveOutDate,
            latitude: listing.latitude,
            longitude: listing.longitude,
            imageUrls: listing.property?.images.map(img => img.imageUrl) ?? [],
            property: listing.property ? {
                categories: listing.property.categories,
                numberOfBedrooms: listing.property.numberOfBedrooms,
                numberOfBathrooms: listing.property.numberOfBathrooms,
                maxOccupancy: listing.property.maxOccupancy,
                amenities: listing.property.amenities,
                tags: listing.property.tags,
                floorPlans: listing.property.floorPlans,
                walkScore: listing.property.walkScore,
                transitScore: listing.property.transitScore,
                offers: listing.property.offers,
                transitDetails: listing.property.transitDetails ? JSON.parse(listing.property.transitDetails) : { railLines: [], busLines: [] }
            } : null,
            marketplaceItem: null
        }));

        return c.json({ listings: formattedListings });
    } catch (error) {
        console.error('Get properties error:', error);
        return c.json({ error: 'Failed to fetch properties' }, 500);
    }
});



app.get('/', async (c) => {
    try {
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const userId = c.get('jwtPayload')?.sub;

        const listings = await prisma.listing.findMany({
            where: {
                type: 'Property',
                reported: false,
                OR: [
                    // For normal users' listings with valid move-in dates
                    {
                        user: {
                            isProfessional: false
                        },
                        property: {
                            OR: [
                                { moveInDate: 'Anytime' },
                                {
                                    moveInDate: {
                                        gte: new Date().toISOString().slice(0, 7) // Current date in YYYY-MM format
                                    }
                                }
                            ]
                        }
                    },
                    // For professional users' listings with available units
                    {
                        user: {
                            isProfessional: true
                        },
                        property: {
                            floorPlans: {
                                some: {
                                    unitsAvailable: {
                                        gt: 0
                                    }
                                }
                            }
                        }
                    }
                ]
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
                        categories: true,
                        images: true,
                        floorPlans: true,
                        offers: true,
                    }
                },
                favorites: {
                    where: userId ? { userId } : undefined
                }
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
                isProfessional: listing.user.isProfessional
            },
            location: listing.location,
            price: listing.price,
            isFavorite: listing.favorites.length > 0,
            moveInDate: listing.property?.moveInDate,
            moveOutDate: listing.property?.moveOutDate,
            latitude: listing.latitude,
            longitude: listing.longitude,
            imageUrls: listing.property?.images.map(img => img.imageUrl) ?? [],
            property: listing.property ? {
                categories: listing.property.categories,
                numberOfBedrooms: listing.property.numberOfBedrooms,
                numberOfBathrooms: listing.property.numberOfBathrooms,
                maxOccupancy: listing.property.maxOccupancy,
                amenities: listing.property.amenities,
                tags: listing.property.tags,
                floorPlans: listing.property.floorPlans,
                walkScore: listing.property.walkScore,
                transitScore: listing.property.transitScore,
                offers: listing.property.offers,
                transitDetails: listing.property.transitDetails ? JSON.parse(listing.property.transitDetails) : { railLines: [], busLines: [] }
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
        const radius = parseFloat(c.req.query('radius') || '10');

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        const currentDate = new Date().toISOString().slice(0, 7);

        // Get current user with preferences and details
        const currentUser = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                preferences: true,
            }
        });

        if (!currentUser) {
            return c.json({ error: 'User not found' }, 404);
        }

        // Find all listings (both regular and professional)
        const listings = await prisma.listing.findMany({
            where: {
                reported: false,
                type: 'Property',
                NOT: { userId: userId },
                OR: [
                    // For regular users' listings
                    {
                        user: {
                            isProfessional: false
                        },
                        property: {
                            OR: [
                                { moveInDate: 'Anytime' },
                                {
                                    moveInDate: {
                                        gte: currentDate
                                    }
                                }
                            ]
                        }
                    },
                    // For professional users' listings with available units
                    {
                        user: {
                            isProfessional: true
                        },
                        property: {
                            floorPlans: {
                                some: {
                                    unitsAvailable: {
                                        gt: 0
                                    }
                                }
                            }
                        }
                    }
                ]
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
                        categories: true,
                        images: true,
                        floorPlans: true,
                        offers: true,
                    }
                },
                favorites: {
                    where: { userId }
                }
            }
        });

        // Calculate similarity scores and filter by distance
        const scoredListings = listings
            .map(listing => {
                // Calculate distance
                const distance = listing.latitude && listing.longitude
                    ? calculateDistance(latitude, longitude, listing.latitude, listing.longitude)
                    : Infinity;

                // Skip if outside radius
                if (distance > radius) return null;

                let similarityScore = 0;

                // For non-professional users, calculate full similarity score
                if (!listing.user.isProfessional) {
                    // University match (highest weight)
                    if (currentUser.university && listing.user.university === currentUser.university) {
                        similarityScore += 30;
                    }

                    // Age similarity (if both users have age)
                    if (currentUser.age && listing.user.age) {
                        const ageDiff = Math.abs(currentUser.age - listing.user.age);
                        if (ageDiff <= 2) similarityScore += 25;
                        else if (ageDiff <= 5) similarityScore += 15;
                        else if (ageDiff <= 10) similarityScore += 5;
                    }

                    // Preference matching
                    const currentUserPrefs = new Set(currentUser.preferences.map(p => p.preference));
                    const listingUserPrefs = new Set(listing.user.preferences.map(p => p.preference));
                    const commonPrefs = [...currentUserPrefs].filter(x => listingUserPrefs.has(x));
                    similarityScore += (commonPrefs.length * 10); // 10 points per matching preference
                } else {
                    // For professional listings, focus on location and available units
                    const hasAvailableUnits = listing.property?.floorPlans?.some(plan => plan.unitsAvailable > 0);
                    if (hasAvailableUnits) {
                        similarityScore += 20; // Bonus for having available units
                    }
                }

                // Distance score (closer = better, max 25 points)
                const distanceScore = Math.max(0, 25 - (distance * 2)); // Lose 2 points per mile
                similarityScore += distanceScore;

                // Roomify Choice bonus
                if (listing.property?.isRoomifyChoice) {
                    similarityScore += 15;
                }

                return {
                    listing,
                    similarityScore,
                    distance
                };
            })
            .filter(item => item !== null)
            .sort((a, b) => b!.similarityScore - a!.similarityScore);

        const formattedListings = scoredListings.map(item => ({
            ...item!.listing,
            isFavorite: item!.listing.favorites.length > 0,
            distance: item!.distance.toFixed(1),
            property: item!.listing.property ? {
                ...item!.listing.property,
                amenities: item!.listing.property.amenities,
                categories: item!.listing.property.categories,
                imageUrls: item!.listing.property.images.map(img => img.imageUrl),
                floorPlans: item!.listing.property.floorPlans,
                offers: item!.listing.property.offers,
            } : null
        }));
        console.log("this is formatted listings", formattedListings);
        return c.json({
            results: formattedListings
        });

    } catch (error: unknown) {
        console.error('Recommendation error:', error);
        return c.json({
            error: 'Failed to get recommendations',
            details: error instanceof Error ? error.message : 'Unknown error'
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
                reported: false,
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
                isRoomifyChoice: listing.property.isRoomifyChoice,
                categories: listing.property.categories,
                numberOfBedrooms: listing.property.numberOfBedrooms,
                numberOfBathrooms: listing.property.numberOfBathrooms,
                moveInDate: listing.property!.moveInDate, // Add this line
                moveOutDate: listing.property!.moveOutDate, // Add this line
                maxOccupancy: listing.property.maxOccupancy,
                isLookingForRoomate: listing.property.isLookingForRoomate,
                rating: listing.property.rating,
                amenities: listing.property.amenities,

            } : null,
            marketplaceItem: null

        })

        );


        return c.json({
            results: formattedListings
        });

    } catch (error: unknown) {
        console.error('Pair-up error:', error);
        return c.json({
            error: 'Failed to get pair-up suggestions',
            details: error instanceof Error ? error.message : 'Unknown error'
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
                                images: true,
                                categories: true,
                                floorPlans: true
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
                    categories: f.listing.marketplace?.categories,
                },
                property: f.listing.property ? {
                    ...f.listing.property,
                    categories: f.listing.property.categories,
                    amenities: f.listing.property.amenities,
                    tags: f.listing.property.tags,
                    imageUrls: f.listing.property.images
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
    } catch (error: unknown) {
        console.error('Add favorite error:', error);
        return c.json({
            error: 'Failed to add favorite',
            details: error instanceof Error ? error.message : 'Unknown error'
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
    const R = 6371; // Earth's radius in km
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLon = (lon2 - lon1) * (Math.PI / 180);
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

// Add report endpoint
app.post('/report/:listingId', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const listingId = parseInt(c.req.param('listingId'));
        const { reason, details } = await c.req.json();

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Check if listing exists and get listing owner
        const listing = await prisma.listing.findUnique({
            where: { id: listingId, },
            include: {
                user: {
                    select: {
                        id: true,
                        fcmToken: true,
                        displayName: true
                    }
                }
            }
        });

        if (!listing) {
            return c.json({ error: 'Listing not found' }, 404);
        }

        // Check if user has already reported this listing
        const existingReport = await prisma.report.findFirst({
            where: {
                listingId,
                userId,
                status: 'pending'
            }
        });

        if (existingReport) {
            return c.json({
                error: 'You have already reported this listing'
            }, 400);
        }

        // Create report and update listing
        const [report] = await prisma.$transaction([
            prisma.report.create({
                data: {
                    listingId,
                    userId,
                    reason,
                    details,
                    status: 'pending'
                }
            }),
            prisma.listing.update({
                where: { id: listingId },
                data: { reported: true }
            })
        ]);

        // Send notification to listing owner
        if (listing.user.fcmToken) {
            await sendNotification(listing.user.fcmToken, {
                type: 'listing_reported',
                recipientFCMToken: listing.user.fcmToken,
                notification: {
                    title: 'Your Listing Has Been Reported',
                    body: `Your listing "${listing.title}" has been reported for ${reason}`
                },
                data: {
                    listingId: listing.id.toString(),
                    reportId: report.id.toString(),
                    reason,
                    reportedBy: userId
                }
            });
        }

        return c.json({
            success: true,
            report
        });
    } catch (error: unknown) {
        console.error('Report listing error:', error);
        return c.json({
            error: 'Failed to report listing',
            details: error instanceof Error ? error.message : 'Unknown error'
        }, 500);
    }
});


app.get('/admin/reports', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) {
            return c.json({ error: 'No authentication token provided' }, 401);
        }

        // Ensure payload has the required structure
        if (typeof payload !== 'object' || !('isAdmin' in payload)) {
            return c.json({ error: 'Invalid token structure' }, 401);
        }

        if (!payload.isAdmin) {
            return c.json({ error: 'Unauthorized: Admin access required' }, 403);
        }

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const reports = await prisma.report.findMany({
            include: {
                listing: true,
                user: {
                    select: {
                        id: true,
                        displayName: true,
                        email: true
                    }
                }
            }
        });

        return c.json({
            success: true,
            reports
        });
    } catch (error: unknown) {
        console.error('Admin reports error:', error);
        return c.json({
            error: 'Failed to fetch reports',
            details: error instanceof Error ? error.message : 'Unknown error'
        }, 500);
    }
});
// Update admin endpoints to manage reports
app.put('/admin/reports/:reportId', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload || !payload.isAdmin) {
            return c.json({ error: 'Unauthorized' }, 401);
        }


        const reportId = parseInt(c.req.param('reportId'));
        const { status } = await c.req.json();

        // Validate status
        const validStatuses = ['pending', 'green', 'listing_removed'];
        if (!validStatuses.includes(status)) {
            return c.json({
                error: 'Invalid status. Must be one of: pending, green, listing_removed'
            }, 400);
        }

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const report = await prisma.report.findUnique({
            where: { id: reportId },
            include: { listing: true }
        });

        if (!report) {
            return c.json({ error: 'Report not found' }, 404);
        }

        let updatedReport;

        if (status === 'listing_removed') {
            // Delete the listing and all related data in a transaction
            const [deletedReport] = await prisma.$transaction([
                prisma.report.update({
                    where: { id: reportId },
                    data: { status }
                }),
                // Delete all related data first
                prisma.favorite.deleteMany({
                    where: { listingId: report.listingId }
                }),
                prisma.propertyImage.deleteMany({
                    where: { propertyId: report.listingId }
                }),
                prisma.propertyAmenity.deleteMany({
                    where: { propertyId: report.listingId }
                }),
                prisma.propertyTag.deleteMany({
                    where: { propertyId: report.listingId }
                }),
                prisma.propertyCategory.deleteMany({
                    where: { propertyId: report.listingId }
                }),
                prisma.property.deleteMany({
                    where: { listingId: report.listingId }
                }),
                // Finally delete the listing itself
                prisma.listing.delete({
                    where: { id: report.listingId }
                })
            ]);
            updatedReport = deletedReport;
        } else {
            // For other statuses, just update the report and listing status
            const [reportUpdate] = await prisma.$transaction([
                prisma.report.update({
                    where: { id: reportId },
                    data: { status }
                }),
                prisma.listing.update({
                    where: { id: report.listingId },
                    data: {
                        reported: status !== 'green'
                    }
                })
            ]);
            updatedReport = reportUpdate;
        }

        // Prepare response message and send notifications
        let message = '';
        switch (status) {
            case 'listing_removed':
                // Get the listing owner's FCM token
                const listingOwner = await prisma.user.findUnique({
                    where: { id: report.listing.userId },
                    select: { fcmToken: true }
                });

                if (listingOwner?.fcmToken) {
                    await sendNotification(listingOwner.fcmToken, {
                        type: 'listing_removed',
                        recipientFCMToken: listingOwner.fcmToken,
                        listing: {
                            id: report.listing.id,
                            title: report.listing.title,
                            reason: report.reason
                        }
                    });
                }
                message = 'Report accepted and listing has been permanently removed';
                break;
            case 'green':
                message = 'Report has been marked as safe and listing restored';
                break;
            case 'pending':
                message = 'Report status updated to pending';
                break;
        }

        return c.json({
            success: true,
            message,
            report: updatedReport
        });
    } catch (error: unknown) {
        console.error('Update report error:', error);
        return c.json({
            error: 'Failed to update report',
            details: error instanceof Error ? error.message : 'Unknown error'
        }, 500);
    }
});

app.put('/:id', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const listingId = parseInt(c.req.param('id'));
        const formData = await c.req.formData();
        const listingData = JSON.parse(formData.get('listing') as string);

        const deletedImageUrls = JSON.parse(formData.get('deletedImageUrls') as string || '[]');
        const images = formData.getAll('images') as File[];
        console.log("this is the images", images);

        console.log("this is the deletedImageUrls", deletedImageUrls);
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });



        // Check if listing exists
        const existingListing = await prisma.listing.findUnique({
            where: { id: listingId },
            include: {
                user: true,
                property: {
                    include: {
                        images: true,
                        amenities: true,
                        tags: true,
                        categories: true,
                        floorPlans: true,
                        offers: true
                    }
                }
            }
        });

        // If listing doesn't exist, create new one
        if (!existingListing) {
            const imageUrls: string[] = [];
            console.log("this is the images", images);
            for (const image of images) {
                const { fileUrl } = await uploadToR2(image, "propertyImages", c);
                imageUrls.push(fileUrl);
            }
            const address = await getAddressFromLatLong(listingData.latitude, listingData.longitude, c);
            const newListing = await prisma.listing.create({
                data: {
                    type: 'Property',
                    title: listingData.title,
                    location: address,
                    price: listingData.price,
                    latitude: listingData.latitude,
                    longitude: listingData.longitude,
                    description: listingData.description,
                    userId: userId,
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
                            categories: {
                                create: listingData.property.categories?.map((category: string) => ({
                                    category
                                })) || []
                            },
                            images: {
                                create: imageUrls.map(url => ({
                                    imageUrl: url
                                }))
                            },
                            floorPlans: {
                                create: listingData.floorPlans?.map((floorPlan: any) => ({
                                    name: floorPlan.name,
                                    bedrooms: floorPlan.bedrooms,
                                    bathrooms: floorPlan.bathrooms,
                                    price: floorPlan.price,
                                    squareFootage: floorPlan.squareFootage,
                                    unitsAvailable: floorPlan.unitsAvailable,
                                    imageUrl: floorPlan.imageUrl,
                                })) || []
                            },
                            offers: {
                                create: listingData.property.offers?.map((offer: any) => ({
                                    title: offer.title,
                                    description: offer.description,
                                    validUntil: new Date(offer.validUntil),
                                })) || []
                            }
                        }
                    }
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
                            categories: true,
                            images: true,
                            floorPlans: true
                        }
                    }
                }
            });

            return c.json({ listing: newListing });
        }

        // Handle existing listing update
        // Delete specified images from R2
        for (const imageUrl of deletedImageUrls) {
            const fileName = imageUrl.split('/').pop();
            if (fileName) {
                await deleteFromR2(fileName, "propertyImages", c);
            }
        }

        //Upload new images to R2
        const imageUrls: string[] = [];
        for (const image of images) {
            const { fileUrl } = await uploadToR2(image, "propertyImages", c);
            imageUrls.push(fileUrl);
        }

        if (deletedImageUrls.length > 0) {
            await prisma.propertyImage.deleteMany({
                where: {
                    propertyId: listingId,
                    imageUrl: {
                        in: deletedImageUrls
                    }
                }
            });
        }

        console.log("this is the amenities", existingListing.property?.amenities);
        // Delete and recreate amenities
        await prisma.propertyAmenity.deleteMany({
            where: { propertyId: listingId }
        });

        // Delete and recreate categories
        await prisma.propertyCategory.deleteMany({
            where: { propertyId: listingId }
        });

        // Delete and recreate offers
        await prisma.propertyOffer.deleteMany({
            where: { propertyId: listingId }
        });


        // Update basic listing info
        await prisma.listing.update({
            where: { id: listingId },
            data: {
                title: listingData.title,
                description: listingData.description,
                price: listingData.price,
                location: listingData.location,
                latitude: listingData.latitude,
                longitude: listingData.longitude
            }
        });

        // Update property
        await prisma.property.update({
            where: { listingId },
            data: {
                moveInDate: listingData.property.moveInDate,
                moveOutDate: listingData.property.moveOutDate,
                numberOfBedrooms: listingData.property.numberOfBedrooms,
                numberOfBathrooms: listingData.property.numberOfBathrooms,
                maxOccupancy: listingData.property.maxOccupancy,
                isLookingForRoomate: listingData.property.isLookingForRoomate,
                offers: {
                    create: listingData.property.offers?.map((offer: any) => ({
                        title: offer.title,
                        description: offer.description,
                        validUntil: new Date(offer.validUntil),
                    })) || []
                },
                amenities: {
                    create: listingData.property.amenities?.map((amenity: string) => ({
                        amenity
                    })) || []
                },
            }
        });


        // Create new categories
        for (const category of listingData.property.categories) {
            await prisma.propertyCategory.create({
                data: {
                    propertyId: listingId,
                    category
                }
            });
        }

        // Create new image entries
        for (const url of imageUrls) {
            await prisma.propertyImage.create({
                data: {
                    propertyId: listingId,
                    imageUrl: url
                }
            });
        }

        // Fetch updated listing
        const updatedListing = await prisma.listing.findUnique({
            where: { id: listingId },
            include: {
                user: true,
                property: {
                    include: {
                        amenities: true,
                        categories: true,
                        images: true,
                        floorPlans: true,
                        offers: true,

                    }
                }
            }
        });

        if (!updatedListing || !updatedListing.property) {
            throw new Error('Failed to fetch updated listing');
        }
        console.log("this is the updated listing", updatedListing);

        return c.json({
            success: true,
            listing: updatedListing
        });
    } catch (error) {
        console.error('Update property error:', error);
        return c.json({
            error: 'Failed to update property',
            details: error instanceof Error ? error.message : 'Unknown error'
        }, 500);
    }
});


app.patch('/roomify-choice', async (c) => {
    try {
        const { email, status } = await c.req.json();

        if (!email) {
            return c.json({ error: 'Email is required' }, 400);
        }

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Find user by email first
        const user = await prisma.user.findUnique({
            where: { email }
        });

        if (!user) {
            return c.json({ error: 'User not found' }, 404);
        }

        // Update all properties of the user using updateMany
        const result = await prisma.property.updateMany({
            where: {
                listing: {
                    userId: user.id,
                    type: 'Property'
                }
            },
            data: {
                isRoomifyChoice: status === 'true'
            }
        });

        return c.json({
            success: true,
            message: `Updated ${result.count} properties to Roomify Choice status: ${status}`,
            updatedCount: result.count
        });
    } catch (error) {
        console.error('Roomify choice update error:', error);
        return c.json({
            error: 'Failed to update Roomify Choice status',
            details: error instanceof Error ? error.message : 'Unknown error'
        }, 500);
    }
});

// Add new route to get walk score and transit details
app.get('/:id/location-details', async (c) => {
    try {
        const listingId = parseInt(c.req.param('id'));
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // First check if we have cached data
        const listing = await prisma.listing.findUnique({
            where: { id: listingId },
            select: {
                latitude: true,
                longitude: true,
                property: {
                    select: {
                        transitDetails: true,
                        lastLocationDetailsUpdate: true,
                        walkScore: true,
                        transitScore: true,
                        offers: true
                    }
                }
            }
        });


        if (!listing) {
            return c.json({ error: 'Listing not found' }, 404);
        }

        // Parse transitDetails from string to JSON if it exists
        const parsedTransitDetails =
            listing.property?.transitDetails
                ? JSON.parse(listing.property.transitDetails)
                :
                { railLines: [], busLines: [] };

        // If we have recent data (less than 7 days old), return it
        const CACHE_DURATION = 7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds
        if (
            listing.property?.walkScore &&
            listing.property?.transitScore &&
            listing.property?.transitDetails &&
            listing.property?.lastLocationDetailsUpdate &&
            (new Date().getTime() - listing.property.lastLocationDetailsUpdate.getTime()) < CACHE_DURATION
        ) {
            const parsedTransitDetails = JSON.parse(listing.property.transitDetails);
            return c.json({
                walkScore: listing.property.walkScore,
                transitScore: listing.property.transitScore,
                transitDetails: parsedTransitDetails
            });
        }

        // Otherwise, fetch new data from Walk Score API
        if (!c.env.WALK_SCORE_API_KEY) {
            throw new Error('Walk Score API key not configured');
        }

        // First get the walk score
        const walkScoreUrl = `https://api.walkscore.com/score?format=json&lat=${listing.latitude}&lon=${listing.longitude}&transit=1&bike=0&wsapikey=${c.env.WALK_SCORE_API_KEY}`;
        const walkScoreResponse = await fetch(walkScoreUrl);
        const walkScoreData = await walkScoreResponse.json() as WalkScoreResponse;

        // Get stop details which include routes
        const stopsUrl = `https://transit.walkscore.com/transit/search/stops/?lat=${listing.latitude}&lon=${listing.longitude}&wsapikey=${c.env.WALK_SCORE_API_KEY}`;
        const stopsResponse = await fetch(stopsUrl);
        const stopsData = await stopsResponse.json();

        // Process all routes from all stops
        const routeMap = new Map<string, { route: any; distance: number }>();

        // Collect unique routes with their closest stop distance
        stopsData.forEach(stop => {
            stop.route_summary.forEach(route => {
                if (!routeMap.has(route.id) || stop.distance < routeMap.get(route.id)!.distance) {
                    routeMap.set(route.id, {
                        route: {
                            name: route.name,
                            distance: parseFloat((stop.distance * 0.621371).toFixed(1)), // Convert km to miles
                            description: route.long_name || route.description || '',
                            agency: route.agency || 'Unknown Agency',
                            type: route.category || 'Unknown'
                        },
                        distance: stop.distance
                    });
                }
            });
        });

        // Separate routes into rail and bus lines
        const railLines: any[] = [];
        const busLines: any[] = [];

        routeMap.forEach(({ route }) => {
            if (route.type.toLowerCase() === 'rail') {
                railLines.push(route);
            } else if (route.type.toLowerCase() === 'bus') {
                busLines.push(route);
            }
        });

        // Sort by distance and limit to closest 6 for each type
        const sortByDistance = (a: any, b: any) => a.distance - b.distance;
        const sortedRailLines = railLines.sort(sortByDistance).slice(0, 6);
        const sortedBusLines = busLines.sort(sortByDistance).slice(0, 6);

        const formattedTransitDetails = {
            railLines: sortedRailLines,
            busLines: sortedBusLines
        };

        // Update or create property with new data
        if (!listing.property) {
            await prisma.property.create({
                data: {
                    listingId: listingId,
                    numberOfBedrooms: 0,
                    numberOfBathrooms: 0,
                    maxOccupancy: 0,
                    transitScore: walkScoreData.transit?.score || 0,
                    walkScore: walkScoreData.walkscore || 0,
                    transitDetails: JSON.stringify(formattedTransitDetails),
                    lastLocationDetailsUpdate: new Date()
                }
            });
        } else {
            await prisma.property.update({
                where: { listingId: listingId },
                data: {
                    transitScore: walkScoreData.transit?.score || 0,
                    walkScore: walkScoreData.walkscore || 0,
                    transitDetails: JSON.stringify(formattedTransitDetails),
                    lastLocationDetailsUpdate: new Date()
                }
            });
        }

        return c.json({
            transitScore: walkScoreData.transit?.score || 0,
            walkScore: walkScoreData.walkscore || 0,
            transitDetails: formattedTransitDetails
        });
    } catch (error: unknown) {
        console.error('Error fetching location details:', error);
        return c.json({
            error: 'Failed to fetch location details',
            details: error instanceof Error ? error.message : 'Unknown error'
        }, 500);
    }
});

// Add endpoint to update unit availability
app.put('/floor-plan/:id/units', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const floorPlanId = c.req.param('id');
        const { availableUnits, squareFootage, price, name, bedrooms, bathrooms, imageUrl, } = await c.req.json();

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Verify user owns the property
        const floorPlan = await prisma.floorPlan.findUnique({
            where: { id: floorPlanId },
            include: {
                property: {
                    include: {
                        listing: {
                            include: {
                                user: true
                            }
                        }
                    }
                }
            }
        });

        if (!floorPlan || floorPlan.property.listing.user.id !== userId) {
            return c.json({ error: 'Unauthorized or floor plan not found' }, 401);
        }

        // Update available units
        const updatedListing = await prisma.listing.update({
            where: { id: floorPlan.property.listingId },
            data: {
                property: {
                    update: {
                        where: {
                            floorPlans: { some: { id: floorPlanId } }
                        },
                        data: {
                            floorPlans: {
                                update: {
                                    where: { id: floorPlanId },
                                    data: {
                                        unitsAvailable: availableUnits,
                                        squareFootage: squareFootage,
                                        price: price,
                                        name: name,
                                        bedrooms: bedrooms,
                                        bathrooms: bathrooms,
                                        imageUrl: imageUrl
                                    }
                                }
                            }
                        }
                    }
                }

            },
            include: {
                property: {
                    include: {
                        amenities: true,
                        categories: true,
                        images: true,
                        offers: true
                    }
                }
            }
        });

        return c.json({ listing: updatedListing });
    } catch (error) {
        console.error('Update units error:', error);
        return c.json({
            error: 'Failed to update units',
            details: error instanceof Error ? error.message : 'Unknown error'
        }, 500);
    }
});


// Floor Plan Management Routes
app.post('/:listingId/floor-plans', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const listingId = parseInt(c.req.param('listingId'));
        const formData = await c.req.formData();
        const floorPlanData = JSON.parse(formData.get('floorPlan') as string);
        const image = formData.get('image') as File;

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Check if listing exists and belongs to user
        const listing = await prisma.listing.findFirst({
            where: {
                id: listingId,
                userId: payload.sub,
            },
        });

        if (!listing) {
            return c.json({ error: 'Listing not found or unauthorized' }, 404);
        }

        // Upload image if provided
        let imageUrl = null;
        if (image) {
            const { fileUrl } = await uploadToR2(image, "floorPlanImages", c);
            imageUrl = fileUrl;
        }

        // Create floor plan
        const floorPlan = await prisma.floorPlan.create({
            data: {
                name: floorPlanData.name,
                bedrooms: floorPlanData.bedrooms,
                bathrooms: floorPlanData.bathrooms,
                squareFootage: floorPlanData.squareFootage,
                price: floorPlanData.price,
                unitsAvailable: floorPlanData.unitsAvailable ?? '',
                imageUrl: imageUrl ?? '',
                propertyId: listing.id,
            },

        });

        // Get updated listing
        const updatedListing = await prisma.listing.findUnique({
            where: { id: listingId },
            include: {
                property: {
                    include: {
                        images: true,
                        amenities: true,
                        categories: true,
                        floorPlans: true,
                        offers: true,
                    },
                },
                user: true,
            },
        });

        return c.json({ listing: updatedListing });
    } catch (error) {
        console.error('Add floor plan error:', error);
        return c.json({ error: 'Failed to add floor plan' }, 500);
    }
});

app.put('/:listingId/floor-plans/:floorPlanId', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const listingId = parseInt(c.req.param('listingId'));
        const floorPlanId = c.req.param('floorPlanId');
        const formData = await c.req.formData();
        const floorPlanData = JSON.parse(formData.get('floorPlanData') as string);
        const image = formData.get('image') as File;

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Check if listing exists and belongs to user
        const listing = await prisma.listing.findFirst({
            where: {
                id: listingId,
                userId: payload.sub,
            },
        });

        if (!listing) {
            return c.json({ error: 'Listing not found or unauthorized' }, 404);
        }

        // Upload image if provided
        let imageUrl = undefined;
        if (image) {
            const { fileUrl } = await uploadToR2(image, "floorPlanImages", c);
            imageUrl = fileUrl;
        }

        // Update floor plan with consistent field names
        await prisma.floorPlan.update({
            where: { id: floorPlanId },
            data: {
                name: floorPlanData.name,
                bedrooms: floorPlanData.bedrooms,
                bathrooms: floorPlanData.bathrooms,
                squareFootage: floorPlanData.squareFootage,
                price: floorPlanData.price,
                unitsAvailable: floorPlanData.unitsAvailable,
                ...(imageUrl && { imageUrl }),
            },
        });

        // Get updated listing
        const updatedListing = await prisma.listing.findUnique({
            where: { id: listingId },
            include: {
                property: {
                    include: {
                        images: true,
                        amenities: true,
                        categories: true,
                        floorPlans: true,
                    },
                },
                user: true,
            },
        });

        return c.json({ listing: updatedListing });
    } catch (error) {
        console.error('Update floor plan error:', error);
        return c.json({ error: 'Failed to update floor plan' }, 500);
    }
});

app.put('/:listingId/floor-plans/:floorPlanId/image', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const listingId = parseInt(c.req.param('listingId'));
        const floorPlanId = c.req.param('floorPlanId');
        const formData = await c.req.formData();
        const image = formData.get('image') as File;

        if (!image) {
            return c.json({ error: 'No image provided' }, 400);
        }

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Verify property ownership
        const property = await prisma.property.findUnique({
            where: { listingId: listingId },
            include: { listing: true }
        });

        if (!property || property.listing.userId !== payload.sub) {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        // Upload image to R2
        const { fileUrl } = await uploadToR2(image, "floorPlanImages", c);

        // Update floor plan image
        const updatedListing = await prisma.listing.update({
            where: { id: listingId },
            data: {
                property: {
                    update: {
                        where: { floorPlans: { some: { id: floorPlanId } } },
                        data: {
                            floorPlans: {
                                update: {
                                    where: { id: floorPlanId },
                                    data: { imageUrl: fileUrl }
                                }
                            }
                        }
                    }
                }
            },
            include: {
                property: {
                    include: {
                        floorPlans: true
                    }
                }
            }
        });

        return c.json({ listing: updatedListing });
    } catch (error) {
        console.error('Update floor plan image error:', error);
        return c.json({
            error: 'Failed to update floor plan image',
            details: error instanceof Error ? error.message : 'Unknown error'
        }, 500);
    }
});

app.delete('/:listingId/floor-plans/:floorPlanId', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const listingId = parseInt(c.req.param('listingId'));
        const floorPlanId = c.req.param('floorPlanId');

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Verify property ownership
        const property = await prisma.property.findUnique({
            where: { listingId: listingId },
            include: { listing: true }
        });

        if (!property || property.listing.userId !== payload.sub) {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        // Delete floor plan image from R2 if it exists
        const floorPlan = await prisma.floorPlan.findUnique({
            where: { id: floorPlanId }
        });

        if (floorPlan?.imageUrl) {
            await deleteFromR2(floorPlan.imageUrl, "floorPlanImages", c);
        }

        // Delete floor plan
        const updatedListing = await prisma.listing.update({
            where: { id: listingId },
            data: {
                property: {
                    update: {
                        data: {
                            floorPlans: {
                                delete: {
                                    id: floorPlanId
                                }
                            }
                        }
                    }
                }
            },
            include: {
                property: {

                    include: {

                        floorPlans: true
                    }
                }
            }
        });

        return c.json({ listing: updatedListing });
    } catch (error) {
        console.error('Delete floor plan error:', error);
        return c.json({
            error: 'Failed to delete floor plan',
            details: error instanceof Error ? error.message : 'Unknown error'
        }, 500);
    }
});

app.get('/:id', async (c) => {
    try {
        const listingId = parseInt(c.req.param('id'));
        const userId = c.get('jwtPayload')?.sub;

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const listing = await prisma.listing.findUnique({
            where: {
                id: listingId,
                type: 'Property'
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
                        categories: true,
                        images: true,
                        floorPlans: true,
                    }
                },
                favorites: {
                    where: userId ? { userId } : undefined
                }
            }
        });

        if (!listing) {
            return c.json({ error: 'Property not found' }, 404);
        }

        const formattedListing = {
            ...listing,
            isFavorite: listing.favorites.length > 0,
            property: listing.property ? {
                ...listing.property,
                amenities: listing.property.amenities,
                categories: listing.property.categories,
                imageUrls: listing.property.images.map(img => img.imageUrl),
                floorPlans: listing.property.floorPlans,
            } : null
        };

        return c.json({ listing: formattedListing });
    } catch (error) {
        console.error('Get property error:', error);
        return c.json({ error: 'Failed to fetch property' }, 500);
    }
});

// Add new endpoint for managing offers
app.post('/:listingId/offers', async (c) => {
    try {
        const listingId = parseInt(c.req.param('listingId'));
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const { title, description, validUntil } = await c.req.json();

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Check if user owns the property
        const listing = await prisma.listing.findFirst({
            where: {
                id: listingId,
                userId,
            },
            include: {
                user: true,
            },
        });

        if (!listing) {
            return c.json({ error: 'Property not found or unauthorized' }, 404);
        }

        if (!listing.user.isProfessional) {
            return c.json({ error: 'Only professional users can add offers' }, 403);
        }

        const offer = await prisma.propertyOffer.create({
            data: {
                title,
                description,
                validUntil: new Date(validUntil),
                propertyId: listingId,
            },
        });

        return c.json({ offer });
    } catch (error) {
        console.error('Add offer error:', error);
        return c.json({ error: 'Failed to add offer' }, 500);
    }
});

app.delete('/:listingId/offers/:offerId', async (c) => {
    try {
        const listingId = parseInt(c.req.param('listingId'));
        const offerId = c.req.param('offerId');
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Check if user owns the property
        const listing = await prisma.listing.findFirst({
            where: {
                id: listingId,
                userId,
            },
            include: {
                property: {
                    include: {
                        offers: true,
                    },
                },
            },
        });

        if (!listing) {
            return c.json({ error: 'Property not found or unauthorized' }, 404);
        }

        // Check if offer exists and belongs to this property
        const offer = listing.property?.offers.find(o => o.id === offerId);
        if (!offer) {
            return c.json({ error: 'Offer not found' }, 404);
        }

        // Delete the offer
        await prisma.propertyOffer.delete({
            where: {
                id: offerId,
            },
        });

        return c.json({ success: true });
    } catch (error) {
        console.error('Delete offer error:', error);
        return c.json({ error: 'Failed to delete offer' }, 500);
    }
});

app.get('/:id/similar', async (c) => {
    try {
        const propertyId = parseInt(c.req.param('id'));
        if (isNaN(propertyId)) {
            return c.json({ error: 'Invalid property ID' }, 400);
        }

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Get the reference property first
        const referenceProperty = await prisma.listing.findUnique({
            where: { id: propertyId },
            include: {
                property: {
                    include: {
                        amenities: true,
                        images: true,
                        floorPlans: true
                    }
                }
            }
        });

        if (!referenceProperty) {
            return c.json({ error: 'Property not found' }, 404);
        }

        // Calculate bounding box for location-based search (5km radius)
        const lat = referenceProperty.latitude;
        const lng = referenceProperty.longitude;
        const radius = 5; // km
        const latRange = radius / 111.0; // Convert km to degrees (roughly)
        const lngRange = radius / (111.0 * Math.cos(lat * Math.PI / 180));

        // Get similar properties
        const similarProperties = await prisma.listing.findMany({
            where: {
                id: { not: propertyId }, // Exclude the reference property
                type: 'Property',
                reported: false,
                OR: [
                    // Similar by title
                    {
                        title: {
                            contains: referenceProperty.title?.split(' ')[0] // Match first word
                        }
                    },
                    // Similar by location
                    {
                        AND: [
                            {
                                latitude: {
                                    gte: lat - latRange,
                                    lte: lat + latRange
                                }
                            },
                            {
                                longitude: {
                                    gte: lng - lngRange,
                                    lte: lng + lngRange
                                }
                            }
                        ]
                    },
                    // Similar by price range (±20%)
                    {
                        price: {
                            gte: referenceProperty.price * 0.8,
                            lte: referenceProperty.price * 1.2
                        }
                    },
                    {
                        property: {
                            floorPlans: {
                                some: {
                                    price: {
                                        gt: referenceProperty.price * 0.8,
                                        lt: referenceProperty.price * 1.2
                                    }
                                }
                            }
                        },
                    },

                    // Similar by bedrooms/bathrooms
                    {
                        property: {
                            AND: [
                                {
                                    numberOfBedrooms: referenceProperty.property?.numberOfBedrooms
                                },
                                {
                                    numberOfBathrooms: referenceProperty.property?.numberOfBathrooms
                                }
                            ]
                        }
                    }
                ]
            },
            include: {
                property: {
                    include: {
                        amenities: true,
                        images: true,
                        floorPlans: true
                    }
                },
                user: {
                    select: {
                        id: true,
                        displayName: true,
                        profileImageUrl: true,
                        isProfessional: true
                    }
                }
            },
            take: 10 // Limit results
        });

        // Calculate similarity score for better sorting
        const scoredProperties = similarProperties.map(property => {
            let score = 0;

            // Location similarity (max 40 points)
            if (property.latitude && property.longitude) {
                const distance = calculateDistance(
                    lat!, lng!,
                    property.latitude, property.longitude
                );
                score += Math.max(0, 40 - (distance * 8)); // Decrease score with distance
            }

            // Price similarity (max 30 points)
            const priceDiff = Math.abs(property.price - referenceProperty.price) / referenceProperty.price;
            score += Math.max(0, 30 - (priceDiff * 100));

            // Bedroom/bathroom match (max 30 points)
            if (property.property?.numberOfBedrooms === referenceProperty.property?.numberOfBedrooms) {
                score += 15;
            }
            if (property.property?.numberOfBathrooms === referenceProperty.property?.numberOfBathrooms) {
                score += 15;
            }

            return {
                ...property,
                similarityScore: score
            };
        });

        // Sort by similarity score
        scoredProperties.sort((a, b) => b.similarityScore - a.similarityScore);

        return c.json({ properties: scoredProperties });
    } catch (error) {
        console.error('Error getting similar properties:', error);
        return c.json({ error: 'Failed to get similar properties' }, 500);
    }
});



export default app;