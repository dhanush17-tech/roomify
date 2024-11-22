import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import * as crypto from "crypto";
import { signAndStoreToken, verifyPassword } from '../helper/helper';

import { PrismaD1 } from '@prisma/adapter-d1';
import { PrismaClient } from '@prisma/client';
import { fileURLToPath } from 'url';

const app = new Hono<{
    Bindings: Env,
    Variables: {
        userId: string;
    }
}>();

app.get('/', async (c) => {
    try {
        const query = c.req.query('query') || '';
        const type = c.req.query('type') || 'Property';
        const minPrice = Number(c.req.query('minPrice'));
        const maxPrice = Number(c.req.query('maxPrice'));
        const location = c.req.query('location');
        const propertyTypes = c.req.query('propertyTypes')?.split(',');
        const amenities = c.req.query('amenities')?.split(',');
        const categories = c.req.query('categories')?.split(',');
        const numberOfBedrooms = Number(c.req.query('numberOfBedrooms'));
        const numberOfBathrooms = Number(c.req.query('numberOfBathrooms'));
        const rating = Number(c.req.query('rating'));
        const maxOccupancy = Number(c.req.query('maxOccupancy'));
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        console.log("This is the rating", rating);

        switch (type) {
            case 'Property':
                const results = await prisma.listing.findMany({
                    where: {
                        OR: [
                            { title: { contains: query } },
                            { description: { contains: query } },
                            { location: { contains: query } }
                        ],
                        AND: [
                            minPrice ? { price: { gte: minPrice } } : {},
                            maxPrice ? { price: { lte: maxPrice } } : {},
                            location ? { location: { contains: location } } : {},
                            {
                                property: {
                                    AND: [
                                        numberOfBedrooms ? {
                                            numberOfBedrooms: { equals: numberOfBedrooms }
                                        } : {},
                                        numberOfBathrooms ? {
                                            numberOfBathrooms: { equals: numberOfBathrooms }
                                        } : {},
                                        maxOccupancy ? {
                                            maxOccupancy: { equals: maxOccupancy }
                                        } : {},
                                        rating ? {
                                            rating: { gte: rating }
                                        } : {},
                                    ]
                                }
                            }
                        ]
                    },
                    include: {
                        property: {
                            include: {
                                amenities: true,
                                categories: true,
                                images: true,
                                comments: {
                                    include: {
                                        user: true
                                    }
                                }
                            }
                        },
                        user: true
                    },
                    orderBy: [
                        { createdAt: 'desc' },
                        {
                            property: {
                                rating: rating ? 'desc' : undefined
                            }
                        }
                    ].filter(order => {
                        // Remove any orderBy objects that have undefined values
                        if (order.property) {
                            return Object.values(order.property).some(value => value !== undefined);
                        }
                        return true;
                    }),
                    take: 50
                });

                const filteredResults = results.filter(listing => {
                    if (amenities?.length) {
                        const hasAllAmenities = amenities.every(amenity =>
                            listing.property?.amenities.some(a => a.amenity === amenity)
                        );
                        if (!hasAllAmenities) return false;
                    }

                    if (categories?.length) {
                        const hasAnyCategory = categories.some(category =>
                            listing.property?.categories.some(c => c.category === category)
                        );
                        if (!hasAnyCategory) return false;
                    }

                    return true;
                });

                return c.json({
                    results: filteredResults.map(listing => ({
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
                        rating: listing.property?.rating,
                        isLookingForRoomate: listing.property?.isLookingForRoomate,
                        comments: listing.property?.comments
                    }))
                });

            default:
                return c.json({ error: 'Invalid search type' }, 400);
        }
    } catch (error) {
        console.error('Search error:', error);
        return c.json({
            error: 'Search failed',
            details: (error as Error).message
        }, 500);
    }
});


export default app