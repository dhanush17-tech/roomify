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

                isProfessional: false,
                AND: [
                    {
                        //name should not begin with Guest
                        displayName: {
                            not: {
                                startsWith: "Guest"
                            }
                        }
                    },
                    {
                        isProfessional: false,
                    },
                    // {
                    //     NOT: {
                    //         swipesReceived: {
                    //             some: {
                    //                 swiperId: currentUserId
                    //             }
                    //         }
                    //     }
                    // },
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
                        categories: listing.property.categories,
                        amenities: listing.property.amenities,
                        imageUrls: listing.property.images
                    } : null
                }))
            };
        });



        // Sort matches by score and other criteria
        const sortedMatches = matches.sort((a, b) => {
            // Primary sort by match score

            return b.matchScore - a.matchScore;

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
                            categories: listing.property.categories,
                            amenities: listing.property.amenities,
                            imageUrls: listing.property.images
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


function calculateMatchScore(currentUser: any, match: any): number {
    let score = 0;
    let maxScore = 0;

    // Preference matching (35%)
    if (currentUser.preferences?.length && match.preferences?.length) {
        maxScore += 35;
        const preferenceMatch = currentUser.preferences.filter((p: { preference: string }) =>
            match.preferences.some((mp: { preference: string }) => mp.preference === p.preference)
        ).length;
        score += preferenceMatch > 0 ? (preferenceMatch / currentUser.preferences.length) * 35 : 0;
    }

    // Location matching (20%)
    if (currentUser.latitude && currentUser.longitude && match.latitude && match.longitude) {
        maxScore += 20;
        const distance = calculateDistance(
            currentUser.latitude,
            currentUser.longitude,
            match.latitude,
            match.longitude
        );
        if (distance > 30) return 0;
        if (distance <= 5) score += 20;
        else if (distance <= 10) score += 35;
        else if (distance <= 20) score += 25;
        else if (distance <= 30) score += 15;
    }

    // University matching (15%)
    if (currentUser.university && match.university) {
        maxScore += 15;
        if (currentUser.university === match.university) {
            score += 15;
        }
    }

    // Age proximity (15%)
    if (currentUser.age && match.age) {
        maxScore += 15;
        const ageDiff = Math.abs(currentUser.age - match.age);
        if (ageDiff <= 2) score += 15;
        else if (ageDiff <= 4) score += 10;
        else if (ageDiff <= 6) score += 5;
    }

    // Language preference (10%)
    if (currentUser.language && match.language) {
        maxScore += 10;
        if (currentUser.language === match.language) {
            score += 10;
        }
    }

    // Gender preference (5%)
    if (currentUser.gender && match.gender) {
        maxScore += 5;
        if (currentUser.gender === match.gender) {
            score += 5;
        }
    }

    return maxScore > 0 ? (score / maxScore) * 100 : 0;
}


function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Earth's radius in kilometers
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

function toRad(value: number): number {
    return value * Math.PI / 180;
}

export default app