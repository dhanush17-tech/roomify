import { Hono } from 'hono';
import { uploadToR2, deleteFromR2, getAddressFromLatLong } from '../helper/helper';
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
        const userId = payload.sub;
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                favorites: {
                    include: {
                        listing: true
                    }
                },
                listings: {
                    include: {
                        property: {
                            include: {
                                categories: true,
                                amenities: true,
                                floorPlans: true,
                                images: true,
                                offers: true
                            }
                        }
                    }
                },
                preferences: true,
                socialLinks: true,
            }
        });

        if (!user) {
            return c.json({ error: 'User not found' }, 404);
        }

        return c.json(user);
    } catch (error) {
        console.error('Get profile error:', error);
        return c.json({ error: 'Failed to get profile' }, 500);
    }
});

app.put('/', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) {
            return c.json({ error: 'Unauthorized' }, 401);
        }
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const userId = payload.sub;
        const formData = await c.req.formData();

        // Get current user to check existing profile photo
        const currentUser = await prisma.user.findUnique({
            where: { id: userId },
            select: { profileImageUrl: true },
        });

        if (!currentUser) {
            return c.json({ error: 'User not found' }, 404);
        }

        console.log("This isteh status", formData.get('status'));
        // Handle profile photo
        const profilePhoto = formData.get('profilePhoto') as File;
        let profileImageUrl = currentUser.profileImageUrl;

        // Check if a new file is uploaded
        if (profilePhoto) {
            const newFileName = profilePhoto.name;

            // Extract the file name from the existing URL for comparison
            const existingFileName = currentUser.profileImageUrl
                ? currentUser.profileImageUrl.split('/').pop()
                : null;

            // If the file name is the same, skip R2 upload
            if (newFileName !== existingFileName) {
                const { fileUrl } = await uploadToR2(profilePhoto, "profilePhotos", c);
                console.log('Uploaded new profile photo URL:', fileUrl);
                profileImageUrl = fileUrl;
            } else {
                console.log('Profile photo unchanged, skipping upload.');
            }
        }

        // Prepare update data
        const updateData = {
            displayName: formData.get('displayName'),
            email: formData.get('email'),
            bio: formData.get('bio'),
            university: formData.get('university'),
            age: parseInt(formData.get('age') as string) || undefined,
            location: formData.get('location'),
            gender: formData.get('gender'),
            phoneNumber: formData.get('phoneNumber'),
            profileImageUrl: profileImageUrl,
            latitude: parseFloat(formData.get('latitude') as string) || undefined,
            longitude: parseFloat(formData.get('longitude') as string) || undefined,
            status: formData.get('status'),
            preferences: formData.get('preferences'),
        };

        // Update user in database
        const updatedUser = await prisma.user.update({
            where: { id: userId },
            data: {
                displayName: updateData.displayName as string,
                email: updateData.email as string,
                bio: updateData.bio as string,
                university: updateData.university as string,
                age: updateData.age,
                location: updateData.location as string,
                gender: updateData.gender as string,
                phoneNumber: updateData.phoneNumber as string,
                profileImageUrl: updateData.profileImageUrl,
                status: updateData.status as string,


            },
            select: {
                id: true,
                displayName: true,
                email: true,
                bio: true,
                university: true,
                age: true,
                gender: true,
                location: true,
                phoneNumber: true,
                profileImageUrl: true,
                language: true,
                receiveNotifications: true,
                status: true,
            },
        });
        console.log(updatedUser)
        return c.json(updatedUser);
    } catch (error) {
        console.error('Update profile error:', error);
        return c.json(
            {
                error: 'Failed to update profile',
                //@ts-ignore
                details: error.message,
            },
            500
        );
    }
});



app.delete('/profile-photo', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) {
            return c.json({ error: 'Unauthorized' }, 401);
        }

        const userId = payload.sub;
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: { profileImageUrl: true }
        });

        if (!user || !user.profileImageUrl) {
            return c.json({ error: 'No profile photo found' }, 404);
        }

        // Delete from R2
        await c.env.BUCKET.delete(user.profileImageUrl);

        // Update database
        await prisma.user.update({
            where: { id: userId },
            data: { profileImageUrl: null }
        });

        return c.json({ message: 'Profile photo deleted successfully' });
    } catch (error) {
        console.error('Failed to delete profile photo:', error);
        return c.json({ error: 'Failed to delete profile photo' }, 500);
    }
});


app.get('/listings', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        // Get userId from query parameter, if not provided use current user's id
        const queryUserId = c.req.query('userId');
        const currentUserId = payload.sub;
        const targetUserId = queryUserId || currentUserId;

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const listings = await prisma.listing.findMany({
            where: { userId: targetUserId },
            include: {
                property: {
                    include: {
                        amenities: true,
                        tags: true,
                        floorPlans: true,

                        categories: true,
                        images: true,
                        offers: true,

                    }
                },
                marketplace: {
                    include: {
                        images: true,
                        categories: true
                    }
                },
                user: {
                    include: {
                        preferences: true,
                    }
                },
                reports: {
                    orderBy: {
                        createdAt: 'desc'
                    },
                    select: {
                        id: true,

                        reason: true,
                        status: true,
                        createdAt: true,
                        updatedAt: true
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
            }
        });

        const formattedListings = listings.map(listing => ({
            ...listing,
            property: listing.property ? {
                ...listing.property,
                categories: listing.property.categories,
                amenities: listing.property.amenities,
                tags: listing.property.tags,
                images: listing.property.images,
                offers: listing.property.offers
            } : null,
            marketplace: listing.marketplace ? {
                ...listing.marketplace,
            } : null,
            reportStatus: {
                hasActiveReport: listing.reported,
                reports: listing.reports.map(report => ({
                    id: report.id,
                    reason: report.reason,
                    status: report.status,
                    createdAt: report.createdAt,
                    updatedAt: report.updatedAt
                }))
            }
        }));

        return c.json({ listings: formattedListings });
    } catch (error) {
        console.error('Fetch listings error:', error);
        return c.json({ error: 'Failed to fetch user listings' }, 500);
    }
});

//admin to delete listings with listingId
app.delete('/admin/listings/:id', async (c) => {
    try {

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const listingId = parseInt(c.req.param('id'));

        const listing = await prisma.listing.findUnique({
            where: { id: listingId }
        });

        if (!listing) {
            return c.json({ error: 'Listing not found' }, 404);
        }

        await prisma.listing.delete({ where: { id: listingId } });
        return c.json({ success: true });
    } catch (error) {
        console.error('Delete listing error:', error);
        return c.json({ error: 'Failed to delete listing' }, 500);
    }
});


app.delete('/listings/:id', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const listingId = parseInt(c.req.param('id'));

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Check if listing exists and belongs to user
        const listing = await prisma.listing.findFirst({
            where: {
                id: listingId,
                userId: userId
            },
            include: {
                property: {
                    include: {
                        images: true,
                        amenities: true,
                        tags: true,
                        categories: true
                    }
                },
                marketplace: true,
                favorites: true,
                reports: true
            }
        });

        if (!listing) {
            return c.json({ error: 'Listing not found or unauthorized' }, 404);
        }

        // Store image URLs to delete later
        const imageUrls = listing.property?.images.map(img => img.imageUrl) || [];

        // Create an array of operations for batch transaction
        const operations = [];

        // First delete all records that reference the listing directly
        operations.push(
            // Delete favorites that reference the listing
            prisma.favorite.deleteMany({
                where: { listingId }
            }),

            // Delete reports that reference the listing
            prisma.report.deleteMany({
                where: { listingId }
            })
        );

        if (listing.property) {
            // Then delete all property-related records
            operations.push(
                // Delete property leads
                prisma.propertyLead.deleteMany({
                    where: { propertyId: listing.property.listingId }
                }),

                // Delete comments
                prisma.comment.deleteMany({
                    where: { propertyId: listing.property.listingId }
                }),

                // Delete property related records
                prisma.propertyAmenity.deleteMany({
                    where: { propertyId: listing.property.listingId }
                }),

                prisma.propertyTag.deleteMany({
                    where: { propertyId: listing.property.listingId }
                }),

                prisma.propertyCategory.deleteMany({
                    where: { propertyId: listing.property.listingId }
                }),

                prisma.propertyImage.deleteMany({
                    where: { propertyId: listing.property.listingId }
                }),

                // Delete the property record
                prisma.property.delete({
                    where: { listingId }
                })
            );
        }

        if (listing.marketplace) {
            operations.push(
                // Delete marketplace images
                prisma.marketplaceImage.deleteMany({
                    where: { itemId: listing.marketplace.listingId }
                }),

                // Delete marketplace categories
                prisma.marketplaceCategory.deleteMany({
                    where: { itemId: listing.marketplace.listingId }
                }),

                // Delete the marketplace item
                prisma.marketplaceItem.delete({
                    where: { listingId }
                })
            );
        }

        // Finally, delete the listing itself
        operations.push(
            prisma.listing.delete({
                where: { id: listingId }
            })
        );

        // Execute all operations in a batch transaction
        await prisma.$transaction(operations);

        // After successful database deletion, delete images from R2
        for (const imageUrl of imageUrls) {
            const fileName = imageUrl.split('/').pop();
            if (fileName) {
                try {
                    await deleteFromR2(fileName, "propertyImages", c);
                } catch (e) {
                    console.error('Failed to delete image from R2:', e);
                    // Continue even if image deletion fails
                }
            }
        }

        return c.json({ success: true });
    } catch (error) {
        console.error('Delete listing error:', error);
        return c.json({
            error: 'Failed to delete listing',
            details: error instanceof Error ? error.message : 'Unknown error'
        }, 500);
    }
});

app.put('/location', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const userId = payload.sub;
        const { latitude, longitude } = await c.req.json();

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const address = await getAddressFromLatLong(latitude, longitude, c);

        await prisma.user.update({
            where: { id: userId },
            data: {
                latitude,
                longitude,
                location: address
            }
        });

        return c.json({ success: true });
    } catch (error) {
        return c.json({ error: 'Failed to update location' }, 500);
    }
});


app.put('/fcm-token', async (c) => {
    const payload = c.get('jwtPayload');
    if (!payload) return c.json({ error: 'Unauthorized' }, 401);

    const userId = payload.sub;
    const { fcmToken } = await c.req.json();

    const adapter = new PrismaD1(c.env.DB);
    const prisma = new PrismaClient({ adapter })

    const existingUser = await prisma.user.findUnique({
        where: { id: userId },
        select: { fcmToken: true }
    });

    if (existingUser && existingUser.fcmToken !== fcmToken) {
        await prisma.user.update({
            where: { id: userId },
            data: { fcmToken }
        });
    }

    return c.json({ success: true });
});

app.delete('/delete-account', async (c) => {
    try {
        const payload = c.get('jwtPayload');
        if (!payload) return c.json({ error: 'Unauthorized' }, 401);

        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Turn off foreign key constraints
        await prisma.$executeRaw`PRAGMA foreign_keys = OFF`;

        try {
            // 1. Delete chat-related data
            await prisma.chatParticipant.deleteMany({
                where: { userId: payload.sub }
            });

            const messages = await prisma.chatMessage.findMany({
                where: { senderId: payload.sub },
                select: { id: true }
            });
            const messageIds = messages.map(m => m.id);

            await prisma.unreadMessage.deleteMany({
                where: {
                    OR: [
                        { messageId: { in: messageIds } },
                        { recipientId: payload.sub }
                    ]
                }
            });

            await prisma.documentSubmission.deleteMany({
                where: { messageId: { in: messageIds } }
            });

            await prisma.documentRequest.deleteMany({
                where: {
                    OR: [
                        { messageId: { in: messageIds } },
                        { recipientId: payload.sub }
                    ]
                }
            });

            await prisma.chatMessage.deleteMany({
                where: { senderId: payload.sub }
            });

            // 2. Delete roommate-related data
            await prisma.roommateSwipe.deleteMany({
                where: {
                    OR: [
                        { swiperId: payload.sub },
                        { swipedId: payload.sub }
                    ]
                }
            });

            await prisma.roommateMatch.deleteMany({
                where: {
                    OR: [
                        { user1Id: payload.sub },
                        { user2Id: payload.sub }
                    ]
                }
            });

            // 3. Delete property and listing related data
            const listings = await prisma.listing.findMany({
                where: { userId: payload.sub },
                select: { id: true }
            });
            const listingIds = listings.map(l => l.id);

            await prisma.propertyLead.deleteMany({
                where: {
                    OR: [
                        { propertyId: { in: listingIds } },
                        { userId: payload.sub }
                    ]
                }
            });

            await prisma.favorite.deleteMany({
                where: {
                    OR: [
                        { listingId: { in: listingIds } },
                        { userId: payload.sub }
                    ]
                }
            });

            await prisma.comment.deleteMany({
                where: {
                    OR: [
                        { propertyId: { in: listingIds } },
                        { userId: payload.sub }
                    ]
                }
            });

            await prisma.report.deleteMany({
                where: {
                    OR: [
                        { listingId: { in: listingIds } },
                        { userId: payload.sub }
                    ]
                }
            });

            // Delete property-specific data
            for (const listingId of listingIds) {
                await prisma.propertyImage.deleteMany({
                    where: { propertyId: listingId }
                });
                await prisma.propertyAmenity.deleteMany({
                    where: { propertyId: listingId }
                });
                await prisma.propertyTag.deleteMany({
                    where: { propertyId: listingId }
                });
                await prisma.propertyCategory.deleteMany({
                    where: { propertyId: listingId }
                });
                await prisma.floorPlan.deleteMany({
                    where: { propertyId: listingId }
                });
                await prisma.property.deleteMany({
                    where: { listingId: listingId }
                });
            }

            // Delete marketplace-specific data
            await prisma.marketplaceImage.deleteMany({
                where: { itemId: { in: listingIds } }
            });
            await prisma.marketplaceCategory.deleteMany({
                where: { itemId: { in: listingIds } }
            });
            await prisma.marketplaceItem.deleteMany({
                where: { listingId: { in: listingIds } }
            });

            // Delete the listings themselves
            await prisma.listing.deleteMany({
                where: { userId: payload.sub }
            });

            // 4. Delete user preferences and social links
            await prisma.userPreference.deleteMany({
                where: { userId: payload.sub }
            });
            await prisma.userSocialLink.deleteMany({
                where: { userId: payload.sub }
            });

            // 5. Delete authentication related data
            await prisma.activeToken.deleteMany({
                where: { userId: payload.sub }
            });
            await prisma.passwordReset.deleteMany({
                where: { userId: payload.sub }
            });

            // 6. Finally delete the user
            await prisma.user.delete({
                where: { id: payload.sub }
            });

            // Turn foreign key constraints back on
            await prisma.$executeRaw`PRAGMA foreign_keys = ON`;

            return c.json({ success: true, message: 'Account deleted successfully' });
        } catch (innerError) {
            // Turn foreign key constraints back on before throwing
            await prisma.$executeRaw`PRAGMA foreign_keys = ON`;
            throw innerError;
        }
    } catch (error) {
        console.error('Delete account error:', error);
        return c.json({
            error: 'Failed to delete account',
            details: error instanceof Error ? error.message : 'Unknown error'
        }, 500);
    }
});


export default app;