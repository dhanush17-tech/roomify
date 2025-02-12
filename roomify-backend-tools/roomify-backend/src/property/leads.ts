import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { PrismaD1 } from '@prisma/adapter-d1';
import { Hono } from 'hono';

const app = new Hono<{
    Bindings: Env,
    Variables: {
        userId: string;
    }
}>();

// Change user to professional
app.patch('/users/professional', async (c) => {
    try {
        const authHeader = c.req.header('key');
        if (authHeader !== 'changeProfessional') {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        const { email, isProfessional } = await c.req.json();
        if (!email) {
            return c.json({ error: 'Email is required' }, 400);
        }

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Find and update the user
        const user = await prisma.user.update({
            where: { email: email },
            data: { isProfessional: isProfessional }
        });

        if (!user) {
            return c.json({ error: 'User not found' }, 404);
        }

        return c.json({
            message: 'User updated successfully',
            user: {
                id: user.id,
                email: user.email,
                isProfessional: user.isProfessional
            }
        }, 200);
    } catch (error) {
        console.error('Error updating user:', error);
        return c.json({ error: 'Failed to update user' }, 500);
    }
});

// Track property view
app.post('/:id/view', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const propertyId = parseInt(c.req.param('id'));
        const userId = payload.sub;

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Get the property and its owner
        const listing = await prisma.listing.findUnique({
            where: { id: propertyId },
            include: {
                user: true // Include the owner's details
            }
        });

        if (!listing) {
            return c.json({ error: 'Property not found' }, 404);
        }

        // Only track leads for professional users' properties
        if (!listing.user.isProfessional) {
            return c.json({ message: 'View recorded' }, 200);
        }

        // Don't track if user is viewing their own property
        if (listing.userId === userId) {
            return c.json({ message: 'Own property view' }, 200);
        }

        // Update or create lead
        const lead = await prisma.propertyLead.upsert({
            where: {
                userId_propertyId: {
                    userId: userId,
                    propertyId: propertyId
                }
            },
            update: {
                viewCount: { increment: 1 },
                lastViewed: new Date()
            },
            create: {
                userId: userId,
                propertyId: propertyId,
                viewCount: 1,
                lastViewed: new Date()
            }
        });

        return c.json({ message: 'View recorded', lead }, 200);
    } catch (error) {
        console.error('Error recording view:', error);
        return c.json({ error: 'Failed to record view' }, 500);
    }
});

// Get leads for professional user's properties
app.get('/', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Check if user is professional
        const user = await prisma.user.findUnique({
            where: { id: userId }
        });

        if (!user?.isProfessional) {
            return c.json({ error: 'Only professional users can view leads' }, 403);
        }

        // Get all leads for user's properties
        const leads = await prisma.propertyLead.findMany({
            where: {
                property: {
                    userId: userId // Property owner's ID
                }
            },
            include: {
                property: {
                    select: {
                        id: true,
                        title: true
                    }
                },
                // Get the viewer's information, not the property owner's
                user: {
                    select: {
                        id: true,
                        displayName: true,
                        email: true,
                        profileImageUrl: true,
                        university: true,
                        phoneNumber: true
                    }
                }
            },
            orderBy: {
                lastViewed: 'desc'
            }
        });

        // Format the response
        const formattedLeads = leads.map(lead => ({
            user: {
                id: lead.user.id,
                displayName: lead.user.displayName,
                email: lead.user.email,
                profileImageUrl: lead.user.profileImageUrl,
                university: lead.user.university,
                phoneNumber: lead.user.phoneNumber,
                
            },
            propertyId: lead.propertyId,
            propertyTitle: lead.property.title,
            viewCount: lead.viewCount,
            lastViewed: lead.lastViewed.toISOString()
        }));

        return c.json({ leads: formattedLeads }, 200);
    } catch (error) {
        console.error('Error fetching leads:', error);
        return c.json({ error: 'Failed to fetch leads' }, 500);
    }
});

export default app;