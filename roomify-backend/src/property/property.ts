import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import * as crypto from "crypto";
import { signAndStoreToken, uploadToR2, verifyPassword } from '../helper/helper';
import prismaClients from '../prisma';


const app = new Hono<{
    Bindings: Env,
    Variables: {
        userId: string;
    }
}>();


app.post('/', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        const userId = payload.sub;
        const formData = await c.req.formData();
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        // Extract property data
        const data = {
            title: formData.get('title'),
            description: formData.get('description'),
            location: formData.get('location'),
            price: Number(formData.get('price')),
            numberOfBedrooms: Number(formData.get('numberOfBedrooms')),
            numberOfBathrooms: Number(formData.get('numberOfBathrooms')),
            maxOccupancy: Number(formData.get('maxOccupancy')),
            amenities: formData.get('amenities')?.toString().split(',') || [],
            categories: formData.get('categories')?.toString().split(',') || [],
            type: formData.get('type'),
        };

        // Get images
        const images = formData.getAll('images') as File[];

        // Create property using Prisma transaction
        const result = await prisma.$transaction(async (tx: any) => {
            // Create listing
            const listing = await tx.listing.create({
                data: {
                    type: 'Property',
                    title: data.title,
                    description: data.description,
                    userId: userId,
                    location: data.location,
                    price: data.price,
                },
            });

            // Create property
            const property = await tx.property.create({
                data: {
                    listingId: listing.id,
                    numberOfBedrooms: data.numberOfBedrooms,
                    numberOfBathrooms: data.numberOfBathrooms,
                    maxOccupancy: data.maxOccupancy,
                    amenities: {
                        create: data.amenities.map(amenity => ({
                            amenity: amenity
                        }))
                    },
                    categories: {
                        create: data.categories.map(category => ({
                            category: category
                        }))
                    }
                },
            });

            // Handle image uploads
            if (images.length) {
                for (const image of images) {
                    const { fileUrl } = await uploadToR2(image);
                    await tx.propertyImage.create({
                        data: {
                            propertyId: property.listingId,
                            imageUrl: fileUrl
                        }
                    });
                }
            }

            return property;
        });

        return c.json({
            success: true,
            propertyId: result.listingId
        });

    } catch (error) {
        console.error('Create property error:', error);
        return c.json({
            error: 'Failed to create property',
            //@ts-ignore

            details: error.message
        }, 500);
    }
});

export default app;