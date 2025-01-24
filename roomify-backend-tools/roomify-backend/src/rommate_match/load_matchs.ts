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
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const currentUserId = payload.sub;
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Get current user with preferences
        const currentUser = await prisma.user.findUnique({
            where: { id: currentUserId },
            include: {
                preferences: true,

            }
        });

        if (!currentUser) {
            return c.json({ error: 'User not found' }, 404);
        }

        // Fetch potential matches with their preferences
        const potentialMatches = await prisma.user.findMany({
            where: {
                id: { not: currentUserId },
                NOT: {
                    // exclude current user from the list and the matches should not be professional
                    id: currentUserId,
                },
                isProfessional: false,
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
            include: {
                preferences: true,
                listings: {
                    where: {
                        reported: false,  // Only include non-reported listings
                        property: {
                            OR: [
                                { moveInDate: 'Anytime' },
                                {
                                    moveInDate: {
                                        gte: new Date().toISOString().slice(0, 7) // Filter out listings with past move-in dates
                                    }
                                }
                            ]
                        }
                    },
                    include: {
                        user: true,
                        property: {
                            include: {
                                categories: true,
                                amenities: true,
                                images: true
                            }
                        }
                    }
                }
            }
        });

        const matches = potentialMatches.map(match => {
            const score = calculateMatchScore(currentUser, match);
            return {
                ...match,
                matchScore: score,
                listings: match.listings.map(listing => ({
                    ...listing,
                    property: listing.property ? {
                        ...listing.property,
                        categories: listing.property.categories.map(c => c.category),
                        amenities: listing.property.amenities.map(a => a.amenity),
                        imageUrls: listing.property.images.map(i => i.imageUrl)
                    } : null
                }))
            };
        });

        // Sort matches by score and other criteria
        const sortedMatches = matches.sort((a, b) => {
            // Primary sort by match score
            if (b.matchScore !== a.matchScore) {
                return b.matchScore - a.matchScore;
            }

            // Secondary sort by location match
            if (currentUser.location) {
                const aLocationMatch = a.location === currentUser.location;
                const bLocationMatch = b.location === currentUser.location;
                if (aLocationMatch !== bLocationMatch) {
                    return bLocationMatch ? 1 : -1;
                }
            }

            // Tertiary sort by university match
            if (currentUser.university) {
                const aUniMatch = a.university === currentUser.university;
                const bUniMatch = b.university === currentUser.university;
                if (aUniMatch !== bUniMatch) {
                    return bUniMatch ? 1 : -1;
                }
            }

            // Finally sort by age difference
            if (currentUser.age && a.age && b.age) {
                const aAgeDiff = Math.abs(currentUser.age - a.age);
                const bAgeDiff = Math.abs(currentUser.age - b.age);
                return aAgeDiff - bAgeDiff;
            }

            return 0;
        });

        return c.json({ matches: sortedMatches });
    } catch (error) {
        console.error('Match error:', error);
        return c.json({ error: 'Failed to fetch matches' }, 500);
    }
});


app.post('/swipe', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const currentUserId = payload.sub;
        const { userId, direction } = await c.req.json();

        if (!userId || !direction) {
            return c.json({ error: 'Missing required fields' }, 400);
        }

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Record the swipe
        await prisma.roommateSwipe.upsert({
            where: {
                swiperId_swipedId: {
                    swiperId: currentUserId,
                    swipedId: userId
                }
            },
            update: { direction },
            create: {
                swiperId: currentUserId,
                swipedId: userId,
                direction,
                createdAt: new Date(),
            }
        });

        // Check for match only if it's a right swipe
        if (direction === 'right') {
            const mutualSwipe = await prisma.roommateSwipe.findFirst({
                where: {
                    swiperId: userId,
                    swipedId: currentUserId,
                    direction: 'right'
                }
            });

            if (mutualSwipe) {
                // Check if match already exists
                const existingMatch = await prisma.roommateMatch.findFirst({
                    where: {
                        OR: [
                            { AND: [{ user1Id: currentUserId }, { user2Id: userId }] },
                            { AND: [{ user1Id: userId }, { user2Id: currentUserId }] }
                        ]
                    }
                });

                if (!existingMatch) {
                    // Create new match
                    await prisma.roommateMatch.create({
                        data: {
                            user1Id: currentUserId,
                            user2Id: userId,
                            matchedAt: new Date()
                        }
                    });
                }

                const matchedUser = await prisma.user.findUnique({
                    where: { id: userId }
                });

                return c.json({
                    matched: true,
                    matchedUser
                });
            }
        }

        return c.json({
            matched: false,
            success: true
        });

    } catch (error) {
        console.error('Swipe error:', error);
        return c.json({ error: 'Failed to process swipe' }, 500);
    }
});

function calculateMatchScore(currentUser: any, match: any): number {
    let score = 0;
    let maxScore = 0;

    // Preference matching (40%)
    if (currentUser.preferences && match.preferences) {
        maxScore += 40;
        const preferenceMatch = currentUser.preferences.filter((p: { preference: string }) =>
            match.preferences.some((mp: { preference: string }) => mp.preference === p.preference)
        ).length;
        score += (preferenceMatch / currentUser.preferences.length) * 40;
    }


    // Location matching (15%)
    if (currentUser.location && match.location) {
        maxScore += 15;
        if (currentUser.location === match.location) {
            score += 15;
        }
    }

    // Age proximity (15%)
    if (currentUser.age && match.age) {
        maxScore += 15;
        const ageDiff = Math.abs(currentUser.age - match.age);
        if (ageDiff <= 1) score += 15;
        else if (ageDiff <= 2) score += 10;
        else if (ageDiff <= 3) score += 5;
    }

    return maxScore > 0 ? (score / maxScore) * 100 : 0;
}

// Add this new endpoint to get mutual matches
app.get('/matches', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const currentUserId = payload.sub;
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Fetch all mutual matches where the current user is either user1 or user2
        const matches = await prisma.roommateMatch.findMany({
            where: {
                OR: [
                    { user1Id: currentUserId },
                    { user2Id: currentUserId }
                ]
            },
            include: {
                user1: {
                    select: {
                        id: true,
                        displayName: true,
                        profileImageUrl: true,
                        bio: true,
                        university: true,
                        age: true,
                        location: true,
                        preferences: true,
                        listings: {
                            include: {
                                property: {
                                    include: {
                                        categories: true,
                                        amenities: true,
                                        images: true
                                    }
                                }
                            }
                        }
                    }
                },
                user2: {
                    select: {
                        id: true,
                        displayName: true,
                        profileImageUrl: true,
                        bio: true,
                        university: true,
                        age: true,
                        location: true,
                        preferences: true,
                        listings: {
                            include: {
                                property: {
                                    include: {
                                        categories: true,
                                        amenities: true,
                                        images: true
                                    }
                                }
                            }
                        }
                    }
                }
            },
            orderBy: {
                matchedAt: 'desc'
            }
        });

        // Format the matches to always show the other user's data
        const formattedMatches = matches.map(match => {
            const otherUser = match.user1Id === currentUserId ? match.user2 : match.user1;
            return {
                matchId: match.id,
                matchedAt: match.matchedAt,
                user: {
                    ...otherUser,
                    listings: otherUser.listings.map(listing => ({
                        ...listing,
                        property: listing.property ? {
                            ...listing.property,
                            categories: listing.property.categories.map(c => c.category),
                            amenities: listing.property.amenities.map(a => a.amenity),
                            imageUrls: listing.property.images.map(i => i.imageUrl)
                        } : null
                    }))
                }
            };
        });

        return c.json({ matches: formattedMatches });
    } catch (error) {
        console.error('Fetch matches error:', error);
        return c.json({ error: 'Failed to fetch matches' }, 500);
    }
});

export default app