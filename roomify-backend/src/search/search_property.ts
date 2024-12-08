import { Hono } from 'hono';
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

        const userLatitude = parseFloat(c.req.query('userLatitude') || '');
        const userLongitude = parseFloat(c.req.query('userLongitude') || '');

        if (isNaN(userLatitude) || isNaN(userLongitude)) {
            return c.json({ error: 'Valid location coordinates required' }, 400);
        }
        console.log("userLatitude", userLatitude);
        console.log("userLongitude", userLongitude);

        const query = c.req.query('query') || '';
        const type = c.req.query('type') || 'Property';
        const minPrice = parseFloat(c.req.query('minPrice') || '');
        const maxPrice = parseFloat(c.req.query('maxPrice') || '');
        const propertyTypes = c.req.query('propertyTypes')?.split(',');
        const amenities = c.req.query('amenities')?.split(',');
        const categories = c.req.query('categories')?.split(',');
        const numberOfBedrooms = parseInt(c.req.query('numberOfBedrooms') || '');
        const numberOfBathrooms = parseInt(c.req.query('numberOfBathrooms') || '');
        const rating = parseFloat(c.req.query('rating') || '');
        const maxOccupancy = parseInt(c.req.query('maxOccupancy') || '');
        const radius = parseFloat(c.req.query('radius') || '10'); // Default 10km radius
        const userId = payload.sub;

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Function to calculate distance between two points
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

        // Base query conditions
        const baseConditions: any = {
            type,
            latitude: { not: null },
            longitude: { not: null },
            userId: { not: userId },
        };

        // Apply filters
        if (query) {
            baseConditions.OR = [
                { title: { contains: query, } },
                { description: { contains: query, } },
                { location: { contains: query, } },
            ];
        }

        if (!isNaN(minPrice)) baseConditions.price = { ...baseConditions.price, gte: minPrice };
        if (!isNaN(maxPrice)) baseConditions.price = { ...baseConditions.price, lte: maxPrice };
        if (propertyTypes?.length) baseConditions.propertyType = { in: propertyTypes };
        if (!isNaN(numberOfBedrooms)) baseConditions.property = { ...baseConditions.property, numberOfBedrooms };
        if (!isNaN(numberOfBathrooms)) baseConditions.property = { ...baseConditions.property, numberOfBathrooms };
        if (!isNaN(maxOccupancy)) baseConditions.property = { ...baseConditions.property, maxOccupancy };
        if (!isNaN(rating)) baseConditions.property = { ...baseConditions.property, rating: { gte: rating } };

        // Fetch listings based on conditions
        const listings = await prisma.listing.findMany({
            where: baseConditions,
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
                },
                favorites: {
                    where: { userId }
                }
            }
        });

        // Filter by amenities and categories
        const filteredListings = listings.filter(listing => {
            const hasAmenities = amenities?.every(amenity =>
                listing.property?.amenities.some(a => a.amenity === amenity)
            ) ?? true;

            const hasCategories = categories?.some(category =>
                listing.property?.categories.some(c => c.category === category)
            ) ?? true;

            return hasAmenities && hasCategories;
        });

        // Filter by distance
        const nearbyListings = filteredListings.filter(listing => {
            if (!listing.latitude || !listing.longitude) return false;
            const distance = calculateDistance(userLatitude, userLongitude, listing.latitude, listing.longitude);
            return distance <= radius;
        });

        // Sort by distance
        nearbyListings.sort((a, b) => {
            const distanceA = calculateDistance(userLatitude, userLongitude, a.latitude!, a.longitude!);
            const distanceB = calculateDistance(userLatitude, userLongitude, b.latitude!, b.longitude!);
            return distanceA - distanceB;
        });

        // Format results
        const results = nearbyListings.map(listing => ({
            ...listing,
            isFavorite: listing.favorites.length > 0,
            distance: calculateDistance(userLatitude, userLongitude, listing.latitude!, listing.longitude!).toFixed(1),
            property: listing.property ? {
                ...listing.property,
                amenities: listing.property.amenities.map(a => a.amenity),
                categories: listing.property.categories.map(c => c.category),
                imageUrls: listing.property.images.map(i => i.imageUrl)
            } : null
        }));
        console.log("results", results);
        return c.json({ results });
    } catch (error) {
        console.error('Search error:', error);
        return c.json({ error: 'Search failed' }, 500);
    }
});

export default app;
