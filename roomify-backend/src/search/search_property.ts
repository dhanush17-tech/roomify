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
        const query = c.req.query('query') || '';
        const type = c.req.query('type') || 'Property';
        const gender = c.req.query('gender');
        const minPrice = Number(c.req.query('minPrice'));
        const maxPrice = Number(c.req.query('maxPrice'));
        const location = c.req.query('location');
        const propertyTypes = c.req.query('propertyTypes')?.split(',');
        const amenities = c.req.query('amenities')?.split(',');
        const categories = c.req.query('categories')?.split(',');

        let results;

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        switch (type) {
            case 'Property':
                results = await prisma.property.findMany({
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
                            propertyTypes?.length ? { type: { in: propertyTypes } } : {},
                            amenities?.length ? {
                                amenities: {
                                    some: { name: { in: amenities } }
                                }
                            } : {},
                            categories?.length ? {
                                categories: {
                                    some: { name: { in: categories } }
                                }
                            } : {}
                        ]
                    },
                    include: {
                        amenities: true,
                        categories: true,
                        images: true,
                        listing: {
                            include: {
                                user: {
                                    select: {
                                        id: true,
                                        displayName: true,
                                        profileImageUrl: true
                                    }
                                }
                            }
                        }
                    },
                    orderBy: {
                        createdAt: 'desc'
                    },
                    take: 50
                });
                break;

            // Add other search types here...
        }

        return c.json({ results });
    } catch (error) {
        console.error('Search error:', error);
        return c.json({ error: 'Search failed' }, 500);
    }
});

export default app