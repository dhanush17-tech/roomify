import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import * as crypto from "crypto";
import { signAndStoreToken, verifyPassword } from '../helper/helper';
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
        if (!payload) {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        const currentUserId = payload.sub;

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        // Get current user's preferences
        const currentUser = await prisma.user.findUnique({
            where: { id: currentUserId },
            select: {
                university: true,
                age: true,
                gender: true,
                location: true
            }
        });

        if (!currentUser) {
            return c.json({ error: 'User not found' }, 404);
        }


        // Fetch potential matches
        const potentialMatches = await prisma.user.findMany({
            where: {
                id: { not: currentUserId },
                AND: [
                    {
                        OR: [
                            { university: currentUser.university },
                            { university: null }
                        ]
                    },
                    {
                        OR: [
                            { location: currentUser.location },
                            { location: null }
                        ]
                    },
                    {
                        OR: [
                            {
                                age: {
                                    gte: currentUser.age ? currentUser.age - 3 : undefined,
                                    lte: currentUser.age ? currentUser.age + 3 : undefined
                                }
                            },
                            { age: null }
                        ]
                    }
                ]
            },
            select: {
                id: true,
                displayName: true,
                profileImageUrl: true,
                bio: true,
                university: true,
                age: true,
                gender: true,
                location: true,
                language: true,
                preferences: true,
                socialLinks: true,
                listings: {
                    select: {
                        id: true,
                        type: true,
                        title: true,

                        description: true,
                        createdAt: true,
                        user: {
                            select: {
                                id: true,
                                displayName: true,
                                profileImageUrl: true,
                                email: true,
                            }
                        },
                        location: true,
                        price: true,
                        isFavorite: true,
                        latitude: true,
                        longitude: true,
                        property: {
                            select: {
                                numberOfBedrooms: true,
                                numberOfBathrooms: true,
                                maxOccupancy: true,
                                isLookingForRoomate: true,
                                rating: true,
                                amenities: true,
                                tags: true,
                                comments: true,
                                images: {
                                    select: {
                                        imageUrl: true
                                    }
                                }
                            }
                        },
                    }
                },
            },
            orderBy: [
                { university: currentUser.university ? 'asc' : undefined },
                { location: currentUser.location ? 'asc' : undefined },
                { createdAt: 'desc' }
            ].filter(order => Object.values(order)[0] !== undefined),
            take: 50
        });

        const matches = potentialMatches.map((user: any) => ({
            ...user,
            matchPercentage: calculateMatchPercentage(currentUser, user),
            listings: user.listings.map((listing: any) => ({
                ...listing,
                property: listing.property ? {
                    ...listing.property,
                    amenities: listing.property.amenities.map((a: any) => a.amenity),
                    tags: listing.property.tags.map((t: any) => t.tag),
                    imageUrls: listing.property.images.map((i: any) => i.imageUrl)
                } : null
            })),
            amenities: user.listings
                .map((listing: any) => listing.property?.amenities?.map((amenity: any) => amenity.amenity))
                .flat()
                .join(', ')
        }));


        console.log(matches.map((match: any) => match.listings.map((listing: any) => listing.property.amenities)));
        return c.json({ matches });
    } catch (error) {
        console.error('Roommate match error:', error);
        return c.json({
            error: 'Failed to fetch matches',
            details: error.message
        }, 500);
    }
});


app.post('/swipe', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        const currentUserId = payload.sub;
        const { userId, direction } = await c.req.json();

        if (!userId || !direction) {
            return c.json({ error: 'Missing required fields' }, 400);
        }
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        // Record the swipe
        await prisma.roommateSwipe.create({
            data: {
                swiperId: currentUserId,
                swipedId: userId,
                direction: direction,
                createdAt: new Date(),
            }
        });

        // Check for match if it's a right swipe
        if (direction === 'right') {
            const mutualSwipe = await prisma.roommateSwipe.findFirst({
                where: {
                    swiperId: userId,
                    swipedId: currentUserId,
                    direction: 'right'
                }
            });

            if (mutualSwipe) {
                // Create a match
                await prisma.roommateMatch.create({
                    data: {
                        user1Id: currentUserId,
                        user2Id: userId,
                        matchedAt: new Date()
                    }
                });

                return c.json({
                    matched: true,
                    matchedUser: await prisma.user.findUnique({
                        where: { id: userId },
                        select: {
                            id: true,
                            displayName: true,
                            profileImageUrl: true
                        }
                    })
                });
            }
        }

        return c.json({ success: true });
    } catch (error) {
        console.error('Swipe error:', error);
        return c.json({ error: 'Failed to process swipe' }, 500);
    }
});


function calculateMatchPercentage(currentUser: any, potentialMatch: any): number {
    let score = 0;
    let totalFactors = 0;

    if (currentUser.university && potentialMatch.university) {
        totalFactors++;
        if (currentUser.university === potentialMatch.university) {
            score++;
        }
    }

    if (currentUser.location && potentialMatch.location) {
        totalFactors++;
        if (currentUser.location === potentialMatch.location) {
            score++;
        }
    }

    if (currentUser.age && potentialMatch.age) {
        totalFactors++;
        if (Math.abs(currentUser.age - potentialMatch.age) <= 3) {
            score++;
        }
    }

    if (currentUser.gender && potentialMatch.gender) {
        totalFactors++;
        if (currentUser.gender === potentialMatch.gender) {
            score++;
        }
    }

    return totalFactors > 0 ? Math.round((score / totalFactors) * 100) : 0;
}
export default app