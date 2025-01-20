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

        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);
        const userId = payload.sub;

        // Extract price range from query parameters
        const { minPrice, maxPrice } = c.req.query();

        const items = await prisma.listing.findMany({
            where: {
                NOT: { userId },
                type: 'Marketplace',
                reported: false,
                // Add price range filtering
                ...(minPrice && { price: { gte: parseFloat(minPrice) } }),
                ...(maxPrice && { price: { lte: parseFloat(maxPrice) } })
            },
            include: {
                user: {
                    include: {
                        preferences: true,
                    }
                }
                ,

                marketplace: {
                    include: {
                        images: true,
                        categories: {
                            select: {
                                category: true
                            }
                        }
                    },

                },
                favorites: true
            },
            orderBy: {
                createdAt: 'desc'
            }
        });
        return c.json({ items });
    } catch (error) {
        return c.json({ error: 'Failed to fetch marketplace items' }, 500);
    }
});

// Search marketplace items
app.get('/search', async (c) => {
    try {
        const { query, location } = c.req.query();

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });


        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);
        const userId = payload.sub;

        const searchConditions: any = {
            type: 'Marketplace',
        };

        // Add search conditions if query parameter exists
        if (query) {
            searchConditions.OR = [
                {
                    location: {
                        contains: query.toLowerCase()
                    }
                },
                {
                    title: {
                        contains: query.toLowerCase()
                    }
                },
                {
                    description: {
                        contains: query.toLowerCase()
                    }
                }
            ];
        }

        // Add location search if location parameter exists
        if (location) {
            searchConditions.location = {
                contains: location,
                mode: 'insensitive'
            };
        }

        const items = await prisma.listing.findMany({
            where: {
                ...searchConditions,
                NOT: { userId },
                reported: false,
            },
            include: {
                user: {
                    include: {
                        preferences: true,
                    }
                },

                marketplace: {
                    include: {
                        images: true,
                        categories: {
                            select: {
                                category: true
                            }
                        }
                    },

                },
                favorites: true
            },
            orderBy: {
                createdAt: 'desc'
            }
        });

        return c.json({ items });
    } catch (error) {
        console.error('Search error:', error);
        return c.json({ error: 'Failed to search marketplace items' }, 500);
    }
});

// Get search suggestions
app.get('/suggestions', async (c) => {
    try {
        const query = c.req.query('query');
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
            WHERE type = 'Marketplace'
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
                WHERE l.type = 'Marketplace' 
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
                    marketplace: {
                        include: {
                            images: true,
                            categories: true
                        }
                    },
                    favorites: {
                        where: { userId }
                    },
                },
            });

            return {
                id: fullListing.id,
                type: 'Marketplace' as const,
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
                imageUrls: fullListing.marketplace?.images.map(img => img.imageUrl) ?? [],
                marketplaceItem: {
                    categories: fullListing.marketplace?.categories.map(c => c.category) ?? []
                },
                property: null
            };
        }));
        console.log("enhancedListings", enhancedListings);
        return c.json({
            listings: enhancedListings,
            suggestedQuery: bestMatch !== query ? bestMatch : null
        });
    } catch (error) {
        console.error('Marketplace suggestions error:', error);
        return c.json({ error: 'Failed to fetch marketplace suggestions' }, 500);
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
            const { fileUrl } = await uploadToR2(image, "marketplaceImages", c);
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
                    include: {
                        preferences: true,
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
                        user: true
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