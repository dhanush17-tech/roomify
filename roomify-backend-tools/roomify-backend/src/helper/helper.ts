import nodemailer from 'nodemailer';
import * as crypto from "crypto";
import { Context, Next } from "hono";
import { sign } from "hono/jwt";
import { PrismaClient } from '@prisma/client';
import { PrismaD1 } from '@prisma/adapter-d1';
import { verify } from "hono/jwt";

export async function hashPassword(password: string,): Promise<string> {
    const salt = 'roomify_password_salt';
    

    // Hash the password with the salt
    const hash = crypto.scryptSync(password, salt, 64).toString('hex');

    // Return in format salt:hash
    return `${salt}:${hash}`;
}

function hashToken(token: string): string {
    // Use a consistent salt for token hashing
    const salt = 'roomify_token_salt'; // Using a constant salt for tokens
    return crypto.scryptSync(token, salt, 64).toString('hex');
}

async function signAndStoreToken(payload: any, c: Context): Promise<string> {
    try {
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        const token = await sign(payload, c.env.JWT_SECRET,);
        const tokenHash = hashToken(token);

        // Delete any existing tokens for the user
        await prisma.activeToken.deleteMany({
            where: {
                userId: payload.sub
            }
        });

        // Store new token
        await prisma.activeToken.create({
            data: {
                tokenHash: tokenHash,
                userId: payload.sub,
                expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
            }
        });

        return token;
    } catch (error) {
        console.error('Token creation error:', error);
        throw new Error('Failed to create token');
    }
}

export const validateToken = async (c: Context, next: Next) => {
    try {
        const authHeader = c.req.header('Authorization');
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return c.json({ error: 'Unauthorized - No token provided' }, 401);
        }

        const token = authHeader.split(' ')[1];
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Verify JWT token
        const payload = await verify(token, c.env.JWT_SECRET);
        if (!payload) {
            return c.json({ error: 'Unauthorized - Invalid token' }, 401);
        }

        // Check if token is in active tokens table
        const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
        const activeToken = await prisma.activeToken.findFirst({
            where: {
                tokenHash: tokenHash,
                userId: payload.sub,
                expiresAt: {
                    gt: new Date(),
                },
            },
        });

        if (!activeToken) {
            return c.json({ error: 'Unauthorized - Token expired or invalid' }, 401);
        }

        // Set the JWT payload in the context
        c.set('jwtPayload', payload);

        // Only call next() once and return its result
        return await next();
    } catch (error) {
        // Log the error for debugging
        console.error('Token validation error:', error);

        // Return error response instead of throwing
        return c.json({ error: 'Unauthorized - Token validation failed' }, 401);
    }
};

function verifyPassword(password: string, storedHash: string): boolean {
    try {
        // Split the stored hash into salt and hash
        const [salt, originalHash] = storedHash.split(':');

        if (!salt || !originalHash) {
            return false;
        }

        // Hash the provided password with the same salt
        const hash = crypto.scryptSync(password, salt, 64).toString('hex');

        // Compare the hashes
        return hash === originalHash;
    } catch (error) {
        console.error('Password verification error:', error);
        return false;
    }
}


async function uploadToR2(file: File, uploadType: string, c: Context): Promise<{ fileName: string; fileUrl: string }> {
    try {
        const bucket = c.env.BUCKET;
        const uniqueId = crypto.randomBytes(16).toString('hex');
        const fileExtension = file.name.split('.').pop();
        const fileName = `${uploadType}/${uniqueId}.${fileExtension}`;

        // Convert File to ArrayBuffer
        const arrayBuffer = await file.arrayBuffer();

        // Upload to R2
        await bucket.put(fileName, arrayBuffer, {
            httpMetadata: {
                contentType: file.type,
            }
        });

        // Generate public URL
        const fileUrl = `${c.env.R2_PUBLIC_URL}/${fileName}`;

        return {
            fileName,
            fileUrl
        };
    } catch (error) {
        console.error('R2 upload error:', error);
        throw new Error('Failed to upload file to R2');
    }
}

async function deleteFromR2(fileName: string, uploadType: string, c: Context): Promise<boolean> {
    try {
        const bucket = c.env.BUCKET;
        const fullPath = `${uploadType}/${fileName}`;

        // Delete from R2
        await bucket.delete(fullPath);
        return true;
    } catch (error) {
        console.error('R2 delete error:', error);
        return false;
    }
}


export { uploadToR2, hashToken, signAndStoreToken, verifyPassword, deleteFromR2 }