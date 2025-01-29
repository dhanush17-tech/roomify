import { Hono } from 'hono';
import { PrismaD1 } from '@prisma/adapter-d1';
import { PrismaClient, Listing } from '@prisma/client';

// Define the extended listing type that includes relations
interface ListingWithRelations extends Listing {
    favorites: Array<{ userId: string }>;
    property: {
        amenities: Array<{ amenity: string }>;
        categories: Array<{ category: string }>;
        images: Array<{ imageUrl: string }>;
    } | null;
}

const app = new Hono<{
    Bindings: Env,
    Variables: {
        userId: string;
    }
}>();


// Utility function to normalize text
function normalizeText(text: string): string {
    return text.replace(/[^a-zA-Z0-9]/g, '').trim().toLowerCase();
}
app.get('/', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userLatitude = parseFloat(c.req.query('userLatitude') || '');
        const userLongitude = parseFloat(c.req.query('userLongitude') || '');
        const originalQuery = normalizeText(c.req.query('query') || '');
        const type = c.req.query('type') || 'Property';
        const minPrice = parseFloat(c.req.query('minPrice') || '');
        const maxPrice = parseFloat(c.req.query('maxPrice') || '');
        const radius = parseFloat(c.req.query('radius') || '10');
        const userId = payload.sub;
        const currentDate = new Date().toISOString().slice(0, 7); // Get current date in YYYY-MM format

        console.log("This is the user latitude and longitude", userLatitude, userLongitude);

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // First get all titles for auto-correction
        const allTitles = await prisma.listing.findMany({
            where: {
                type,
                reported: false,
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
            select: { title: true }
        }) as { title: string }[];
        console.log("This is the all titles", allTitles);


        // Auto-correct function using Sift3 distance
        function sift3Distance(s1: string, s2: string): number {
            if (!s1 || !s1.length) return s2 ? s2.length : 0;
            if (!s2 || !s2.length) return s1.length;

            let c = 0;
            let offset1 = 0;
            let offset2 = 0;
            let lcs = 0;
            const maxOffset = 5;

            while ((c + offset1 < s1.length) && (c + offset2 < s2.length)) {
                if (s1[c + offset1] == s2[c + offset2]) {
                    lcs++;
                } else {
                    offset1 = 0;
                    offset2 = 0;
                    for (let i = 0; i < maxOffset; i++) {
                        if ((c + i < s1.length) && (s1[c + i] == s2[c])) {
                            offset1 = i;
                            break;
                        }
                        if ((c + i < s2.length) && (s1[c] == s2[c + i])) {
                            offset2 = i;
                            break;
                        }
                    }
                }
                c++;
            }
            return (s1.length + s2.length) / 2 - lcs;
        }

        // Find closest matching title
        const normalizedQuery = originalQuery.toLowerCase().replace(/\s+/g, '');
        let bestMatch = originalQuery;
        let minDistance = Infinity;

        allTitles.forEach((titleObj: { title: string }) => {
            const normalizedTitle = titleObj.title.toLowerCase().replace(/\s+/g, '');
            const distance = sift3Distance(normalizedQuery, normalizedTitle);
            if (distance < minDistance) {
                minDistance = distance;
                bestMatch = titleObj.title;
            }
        });

        // Get listings using Prisma query
        let listings;
        if (originalQuery === '') {
            listings = await prisma.listing.findMany({
                where: {
                    type,
                    reported: false,
                    userId: { not: userId },
                    latitude: { not: null },
                    longitude: { not: null },
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
                include: {
                    property: {
                        include: {
                            amenities: true,
                            categories: true,
                            images: true,
                        },
                    },
                    user: {
                        include: {
                            preferences: true,
                        },
                    },
                    favorites: {
                        where: { userId },
                    },
                },
            }) as ListingWithRelations[];
        } else {
            listings = await prisma.listing.findMany({
                where: {
                    type,
                    reported: false,
                    userId: { not: userId },
                    latitude: { not: null },
                    longitude: { not: null },
                    price: {
                        gte: !isNaN(minPrice) ? minPrice : undefined,
                        lte: !isNaN(maxPrice) ? maxPrice : undefined,
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
                    },
                    OR: [
                        { title: { contains: normalizedQuery } },
                        { title: { contains: bestMatch } }
                    ]
                },
                include: {
                    property: {
                        include: {
                            amenities: true,
                            categories: true,
                            images: true,
                        },
                    },
                    user: {
                        include: {
                            preferences: true,
                        },
                    },
                    favorites: {
                        where: { userId },
                    },
                },
            }) as ListingWithRelations[];
        }

        // Filter and sort listings by distance
        const nearbyListings = originalQuery === '' ? listings.filter(listing => {
            if (!listing.latitude || !listing.longitude) return false;
            const distance = calculateDistance(
                userLatitude,
                userLongitude,
                listing.latitude,
                listing.longitude
            );
            return distance <= radius;
        })
            .sort((a, b) => {
                const distanceA = calculateDistance(
                    userLatitude,
                    userLongitude,
                    a.latitude!,
                    a.longitude!
                );
                const distanceB = calculateDistance(
                    userLatitude,
                    userLongitude,
                    b.latitude!,
                    b.longitude!
                );
                return distanceA - distanceB;
            }) : listings;

        // Format results
        const enhancedListings = nearbyListings.map((listing: ListingWithRelations) => ({
            ...listing,
            isFavorite: listing.favorites?.length > 0,
            distance: calculateDistance(
                userLatitude,
                userLongitude,
                listing.latitude!,
                listing.longitude!
            ).toFixed(1),
            property: listing.property ? {
                ...listing.property,
                amenities: listing.property.amenities,
                categories: listing.property.categories,
                imageUrls: listing.property.images
            } : null
        }));

        return c.json({
            results: enhancedListings,
            suggestedQuery: bestMatch !== originalQuery ? bestMatch : null
        }, 200);
    } catch (error) {
        console.error('Search error:', error);
        return c.json({
            error: 'Search failed',
            message: error instanceof Error ? error.message : 'Unknown error'
        }, 500);
    }
});

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


app.get('/suggestions', async (c) => {
    try {
        const query = c.req.query('query')
        if (!query) {
            return c.json({ suggestions: [] });
        }

        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);
        const userId = payload.sub;

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Function to calculate Levenshtein distance
        function levenshteinDistance(s1: string, s2: string): number {
            const m = s1.length;
            const n = s2.length;
            const dp: number[][] = Array.from({ length: m + 1 }, () =>
                Array.from({ length: n + 1 }, () => 0)
            );

            for (let i = 0; i <= m; i++) dp[i][0] = i;
            for (let j = 0; j <= n; j++) dp[0][j] = j;

            for (let i = 1; i <= m; i++) {
                for (let j = 1; j <= n; j++) {
                    if (s1[i - 1] === s2[j - 1]) {
                        dp[i][j] = dp[i - 1][j - 1];
                    } else {
                        dp[i][j] = Math.min(
                            dp[i - 1][j - 1] + 1,
                            dp[i - 1][j] + 1,
                            dp[i][j - 1] + 1
                        );
                    }
                }
            }
            return dp[m][n];
        }

        // First get all titles for auto-correction
        const allTitles = await prisma.$queryRaw`
            SELECT DISTINCT title 
            FROM Listing 
            WHERE type = 'Property'
        `;

        // Find best matching title
        const normalizedQuery = query.toLowerCase().replace(/\s+/g, '');
        let bestMatch = query;
        let minDistance = Infinity;

        allTitles.forEach((titleObj: { title: string }) => {
            const normalizedTitle = titleObj.title.toLowerCase().replace(/\s+/g, '');
            const distance = levenshteinDistance(normalizedQuery, normalizedTitle);
            if (distance < minDistance && distance <= 3) { // Maximum 3 edits allowed
                minDistance = distance;
                bestMatch = titleObj.title;
            }
        });

        // Raw SQL query with fuzzy matching
        const listings = await prisma.$queryRaw`
            WITH normalized_listings AS (
                SELECT 
                    l.*,
                    LOWER(REPLACE(REPLACE(l.title, ' ', ''), '\n', '')) as normalized_title
                FROM Listing l
                WHERE l.type = 'Property' 
                AND l.user_id != ${userId}
            )
            SELECT l.*
            FROM normalized_listings l
            WHERE 
                normalized_title LIKE ${`%${normalizedQuery}%`}
                OR normalized_title LIKE ${`%${bestMatch.toLowerCase().replace(/\s+/g, '')}%`}
            ORDER BY 
                CASE 
                    WHEN normalized_title LIKE ${`%${normalizedQuery}%`} THEN 0
                    ELSE 1
                END
            LIMIT 10
        `;

        // Fetch related data for matched listings
        const enhancedListings = await Promise.all(listings.map(async (listing) => {
            const fullListing = await prisma.listing.findUnique({
                where: { id: listing.id, reported: false },
                include: {
                    user: {
                        select: {

                            id: true,
                            displayName: true,
                            profileImageUrl: true,
                            preferences: true,
                        },
                    },
                    property: {
                        include: {
                            categories: true,
                            amenities: true,
                            tags: true,
                            images: true,
                        },
                    },
                    favorites: {
                        where: { userId }
                    },
                },
            });

            return {
                id: fullListing.id,
                type: 'Property' as const,

                title: fullListing.title,
                description: fullListing.description,
                createdAt: fullListing.createdAt.toISOString(),
                user: {
                    id: fullListing.user.id,
                    displayName: fullListing.user.displayName,
                    profileImageUrl: fullListing.user.profileImageUrl,
                },
                location: fullListing.location,
                price: fullListing.price,
                isFavorite: fullListing.favorites.length > 0,
                latitude: fullListing.latitude,
                longitude: fullListing.longitude,
                imageUrls: fullListing.property?.images.map(img => img.imageUrl) ?? [],
                property: fullListing.property ? {
                    categories: fullListing.property.categories,
                    numberOfBedrooms: fullListing.property.numberOfBedrooms,
                    numberOfBathrooms: fullListing.property.numberOfBathrooms,
                    moveInDate: fullListing.property.moveInDate,
                    moveOutDate: fullListing.property.moveOutDate,
                    maxOccupancy: fullListing.property.maxOccupancy,
                    isLookingForRoomate: fullListing.property.isLookingForRoomate,
                    rating: fullListing.property.rating,
                    amenities: fullListing.property.amenities,
                    tags: fullListing.property.tags,
                } : null,
                marketplaceItem: null
            };
        }));

        return c.json({
            listings: enhancedListings,
            suggestedQuery: bestMatch !== query ? bestMatch : null
        });
    } catch (error) {
        console.error('Property suggestions error:', error);
        return c.json({ error: 'Failed to fetch property suggestions' }, 500);
    }
});

// Error handler for the entire app
app.onError((err, c) => {
    console.error('Application error:', err);
    return c.json({
        error: 'Internal server error',
        message: err instanceof Error ? err.message : 'Unknown error'
    }, 500);
});

export default app;
