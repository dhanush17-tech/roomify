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
                        user: true,
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
                currentUser.university ? { university: 'asc' as const } : null,
                currentUser.location ? { location: 'asc' as const } : null,
                { createdAt: 'desc' as const }
            ].filter(Boolean) as any,
            take: 50
        });

        const matches = potentialMatches.map((user: any) => {
            const matchScore = calculateMatchPercentage(currentUser, user);
            return {
                ...user,
                matchPercentage: matchScore,
                listings: user.listings.map((listing: any) => ({
                    ...listing,
                    property: listing.property ? {
                        ...listing.property,
                        amenities: listing.property.amenities == null ?
                            [] :
                            listing.property.amenities.map((amenity: any) => amenity.amenity),
                        tags: listing.property.tags ?
                            listing.property.tags.map((t: any) => t.tag) :
                            [],
                        imageUrls: listing.property.images ?
                            listing.property.images.map((i: any) => i.imageUrl) :
                            []
                    } : null
                })),
            };
        });

        // Sort matches based on multiple criteria
        const sortedMatches = matches.sort((a, b) => {
            // First, prioritize match percentage
            if (a.matchPercentage !== b.matchPercentage) {
                return b.matchPercentage - a.matchPercentage;
            }

            // Then consider university match if user has a preference
            if (currentUser.university) {
                const aUniversityMatch = a.university === currentUser.university;
                const bUniversityMatch = b.university === currentUser.university;
                if (aUniversityMatch !== bUniversityMatch) {
                    return aUniversityMatch ? -1 : 1;
                }
            }

            // Then consider location match if user has a preference
            if (currentUser.location) {
                const aLocationMatch = a.location === currentUser.location;
                const bLocationMatch = b.location === currentUser.location;
                if (aLocationMatch !== bLocationMatch) {
                    return aLocationMatch ? -1 : 1;
                }
            }

            // Consider age proximity if both users have age
            if (currentUser.age && a.age && b.age) {
                const aAgeDiff = Math.abs(currentUser.age - a.age);
                const bAgeDiff = Math.abs(currentUser.age - b.age);
                if (aAgeDiff !== bAgeDiff) {
                    return aAgeDiff - bAgeDiff;
                }
            }

            // Finally, sort by most recent
            return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
        });

        return c.json({ matches: sortedMatches });
    } catch (error: any) {
        console.error('Roommate match error:', error);
        return c.json({
            error: 'Failed to fetch matches',
            details: error?.message || 'Unknown error'
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

        // Check if the swipe is already recorded
        const existingSwipe = await prisma.roommateSwipe.findFirst({
            where: {
                swiperId: currentUserId,
                swipedId: userId,
                direction: direction
            }
        });

        if (existingSwipe) {
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
                    // Match already exists, return match and matchedUser
                    const matchedUser = await prisma.user.findUnique({
                        where: { id: userId }
                    });
                    return c.json({
                        matched: true,
                        matchedUser: matchedUser
                    });
                } else {
                    // No match, return success but not matched
                    return c.json({
                        matched: false,
                        success: true
                    });
                }
            } else {
                // If it's not a right swipe, just return success
                return c.json({
                    matched: false,
                    success: true
                });
            }
        } else {
            // If the swipe is not already recorded, create or update it
            await prisma.roommateSwipe.upsert({
                where: {
                    swiperId_swipedId: {
                        swiperId: currentUserId,
                        swipedId: userId
                    }
                },
                update: {
                    direction: direction,
                },
                create: {
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

                    // Return match and matchedUser
                    const matchedUser = await prisma.user.findUnique({
                        where: { id: userId }
                    });
                    return c.json({
                        matched: true,
                        matchedUser: matchedUser
                    });
                } else {
                    // No match, return success but not matched
                    return c.json({
                        matched: false,
                        success: true
                    });
                }
            } else {
                // If it's not a right swipe, just return success
                return c.json({
                    matched: false,
                    success: true
                });
            }
        }
    } catch (error) {
        console.error('Swipe error:', error);
        return c.json({ error: 'Failed to process swipe' }, 500);
    }
});


function calculateMatchPercentage(currentUser: any, potentialMatch: any): number {
    let score = 0;
    let totalWeight = 0;

    // University match (weight: 3)
    if (currentUser.university && potentialMatch.university) {
        totalWeight += 3;
        if (currentUser.university === potentialMatch.university) {
            score += 3;
        }
    }

    // Location match (weight: 3)
    if (currentUser.location && potentialMatch.location) {
        totalWeight += 3;
        if (currentUser.location === potentialMatch.location) {
            score += 3;
        }
    }

    // Age proximity (weight: 2)
    if (currentUser.age && potentialMatch.age) {
        totalWeight += 2;
        const ageDiff = Math.abs(currentUser.age - potentialMatch.age);
        if (ageDiff <= 1) score += 2;
        else if (ageDiff <= 2) score += 1.5;
        else if (ageDiff <= 3) score += 1;
    }

    // Gender preference (weight: 2)
    if (currentUser.gender && potentialMatch.gender) {
        totalWeight += 2;
        if (currentUser.gender === potentialMatch.gender) {
            score += 2;
        }
    }

    // Language match (weight: 1)
    if (currentUser.language && potentialMatch.language) {
        totalWeight += 1;
        if (currentUser.language === potentialMatch.language) {
            score += 1;
        }
    }

    // Calculate percentage
    return totalWeight > 0 ? Math.round((score / totalWeight) * 100) : 0;
}
export default app