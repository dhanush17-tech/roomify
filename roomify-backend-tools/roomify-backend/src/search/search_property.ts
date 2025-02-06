import { Hono } from 'hono';
import { PrismaD1 } from '@prisma/adapter-d1';
import { PrismaClient, Listing, Property, Prisma } from '@prisma/client';

// Define the extended listing type that includes relations
interface ListingWithRelations extends Listing {
    favorites: Array<{ userId: string }>;
    property: {
        floorPlans: Array<{ price: number, bedrooms: number, bathrooms: number, imageUrl: string, name: string, availableUnits: number, squareFootage: number }>;
        amenities: Array<{ amenity: string }>;
        categories: Array<{ category: string }>;
        images: Array<{ imageUrl: string }>;
        address?: string;
        city?: string;
        state?: string;
    } | null;
}

interface MapboxFeature {
    id: string;
    place_name: string;
    text: string;
    place_type: string[];
    center: [number, number];
    context: Array<{
        id: string;
        text: string;
    }>;
}

interface MapboxResponse {
    features: MapboxFeature[];
}

interface ListingSuggestion {
    id: string;
    title: string;
    property: {
        city: string | null;
        state: string | null;
    } | null;
}

const app = new Hono<{
    Bindings: Env & {
        MAPBOX_TOKEN: string;
    },
    Variables: {
        userId: string;
    }
}>();

// Utility function to normalize text
function normalizeText(text: string): string {
    return text.replace(/[^a-zA-Z0-9]/g, '').trim().toLowerCase();
}

// Function to get location suggestions from Mapbox
async function getLocationSuggestions(query: string, token: string): Promise<MapboxFeature[]> {
    try {
        const response = await fetch(
            `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(query)}.json?` +
            `access_token=${token}&` +
            `types=place,address,locality,neighborhood&` +
            `country=US&` +
            `limit=5`
        );

        if (!response.ok) {
            throw new Error('Failed to fetch location suggestions');
        }

        const data = await response.json() as MapboxResponse;
        return data.features;
    } catch (error) {
        console.error('Error fetching location suggestions:', error);
        return [];
    }
}

// Add endpoint for location suggestions
app.get('/suggestions', async (c) => {
    try {
        const query = c.req.query('query');
        if (!query) {
            return c.json({ suggestions: [] });
        }

        const [locationSuggestions, titleSuggestions] = await Promise.all([
            // Get location suggestions from Mapbox
            getLocationSuggestions(query, c.env.MAPBOX_TOKEN),

            // Get only title suggestions from database
            (async () => {
                const adapter = new PrismaD1(c.env.DB);
                const prisma = new PrismaClient({ adapter });

                return await prisma.listing.findMany({
                    where: {
                        title: { contains: query },
                        reported: false
                    },
                    select: {
                        id: true,
                        title: true,
                        location: true
                    },
                    take: 5
                });
            })()
        ]);

        // Format suggestions
        const suggestions = {
            // Location suggestions from Mapbox
            locations: locationSuggestions.map(feature => {
                // Extract the main place name and context
                const mainText = feature.text;
                const context = feature.context
                    ?.map(ctx => ctx.text)
                    .filter(Boolean)
                    .join(', ');

                return {
                    id: feature.id,
                    name: mainText,
                    full_name: feature.place_name,
                    type: feature.place_type[0],
                    coordinates: feature.center,
                    context: context
                };
            }),
            // Property title suggestions from database
            properties: titleSuggestions.map(listing => ({
                id: listing.id,
                title: listing.title,
                location: listing.location
            }))
        };
        return c.json(suggestions);
    } catch (error) {
        console.error('Error getting suggestions:', error);
        return c.json({ error: 'Failed to get suggestions' }, 500);
    }
});

// Add the sift3Distance function at the top of the file
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

// Existing search endpoint
app.get('/', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const searchLatitude = parseFloat(c.req.query('userLatitude') || '');
        const searchLongitude = parseFloat(c.req.query('userLongitude') || '');
        const originalQuery = normalizeText(c.req.query('query') || '');
        const type = c.req.query('type') || 'Property';
        const minPrice = parseFloat(c.req.query('minPrice') || '10') - 10;
        const maxPrice = parseFloat(c.req.query('maxPrice') || '') + 10;
        const bedrooms = parseInt(c.req.query('bedrooms') || '0');
        const bathrooms = parseInt(c.req.query('bathrooms') || '0');
        const radius = parseFloat(c.req.query('radius') || '10');
        const userId = payload.sub;
        const currentDate = new Date().toISOString().slice(0, 7);

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // First get all available listings with their details
        const listings = await prisma.listing.findMany({
            where: {
                type,
                reported: false,
                userId: {
                    not: userId
                },
                price: {
                    gte: minPrice ? minPrice : 0,
                    lte: maxPrice ? maxPrice : 1000000
                },
                property: {

                    OR: [
                        { moveInDate: { equals: 'Anytime' } },
                        {
                            AND: [
                                { moveInDate: { not: 'Anytime' } },
                                { moveInDate: { gte: currentDate } }
                            ]
                        },

                    ]
                }
            },
            include: {
                property: {
                    include: {
                        amenities: true,
                        categories: true,
                        images: true,
                        floorPlans: {
                            select: {
                                id: true,
                                price: true,
                                bedrooms: true,
                                bathrooms: true,
                                imageUrl: true,
                                name: true,
                                unitsAvailable: true,
                                squareFootage: true,
                            }
                        },
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

        // Filter listings by location and other criteria
        const filteredListings = listings.filter(listing => {
            // Filter by location if coordinates are provided
            if (searchLatitude && searchLongitude && listing.latitude && listing.longitude) {
                const distance = calculateDistance(
                    searchLatitude,
                    searchLongitude,
                    listing.latitude,
                    listing.longitude
                );
                if (distance > radius) return false;
            }

            // Filter by price if provided
            if (!isNaN(minPrice) && !isNaN(maxPrice)) {
                const listingPrice = listing.property?.floorPlans?.length
                    ? Math.min(...listing.property.floorPlans.map(plan => plan.price))
                    : listing.price;
                if (listingPrice < minPrice || listingPrice > maxPrice) return false;
            }

            // Filter by bedrooms if provided
            if (bedrooms > 0 && !listing.property?.floorPlans.some(plan => plan.bedrooms >= bedrooms)) return false;

            // Filter by bathrooms if provided
            if (bathrooms > 0 && !listing.property?.floorPlans.some(plan => plan.bathrooms >= bathrooms)) return false;

            return true;
        });

        // Sort listings by query relevance and distance
        const sortedListings = filteredListings.sort((a, b) => {
            if (originalQuery) {
                // If there's a search query, prioritize title matches
                const titleA = normalizeText(a.title);
                const titleB = normalizeText(b.title);

                // Exact matches get highest priority
                if (titleA === originalQuery && titleB !== originalQuery) return -1;
                if (titleB === originalQuery && titleA !== originalQuery) return 1;

                // Then check for partial matches
                const matchScoreA = sift3Distance(titleA, originalQuery);
                const matchScoreB = sift3Distance(titleB, originalQuery);

                if (matchScoreA !== matchScoreB) {
                    return matchScoreA - matchScoreB;
                }
            }

            // If no query or equal match scores, sort by distance
            if (searchLatitude && searchLongitude) {
                const distanceA = calculateDistance(
                    searchLatitude,
                    searchLongitude,
                    a.latitude!,
                    a.longitude!
                );
                const distanceB = calculateDistance(
                    searchLatitude,
                    searchLongitude,
                    b.latitude!,
                    b.longitude!
                );
                return distanceA - distanceB;
            }

            // Default to sorting by title
            return a.title.localeCompare(b.title);
        });

        // Format results
        const enhancedListings = sortedListings.map(listing => ({
            ...listing,
            isFavorite: listing.favorites?.length > 0,
            distance: searchLatitude && searchLongitude ?
                calculateDistance(
                    searchLatitude,
                    searchLongitude,
                    listing.latitude!,
                    listing.longitude!
                ).toFixed(1) : null,
            property: listing.property ? {
                ...listing.property,
                amenities: listing.property.amenities,
                categories: listing.property.categories,
                imageUrls: listing.property.images,
                floorPlans: listing.property.floorPlans,
            } : null
        }));
        return c.json({
            results: enhancedListings,
            suggestedQuery: originalQuery
        }, 200);
    } catch (error) {
        console.error('Error in search:', error);
        return c.json({ error: 'Search failed' }, 500);
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

// Error handler for the entire app
app.onError((err, c) => {
    console.error('Application error:', err);
    return c.json({
        error: 'Internal server error',
        message: err instanceof Error ? err.message : 'Unknown error'
    }, 500);
});

export default app;