
import nodemailer from 'nodemailer';
import * as crypto from "crypto";
import { Context, Next } from "hono";
import { sign } from "hono/jwt";
import { PrismaClient } from '@prisma/client';
import { PrismaD1 } from '@prisma/adapter-d1';
 
async function uploadToR2(file: File): Promise<{ fileName: string; fileUrl: string }> {
    try {
        const formData = new FormData();
        formData.append('file', new Blob([file], { type: 'image/png' }), file.name);

        const response = await fetch('http://r2-worker.plain-fire-9ab3.workers.dev/upload', {
            method: 'POST',
            body: formData,
            headers: {
                // Don't manually set the Content-Type for FormData
                'X-Custom-Auth-Key': '',
            },
        });

        if (!response.ok) {
            throw new Error('Failed to upload file');
        }

        const data: any = await response.json();

        if (!data.success) {
            throw new Error(data.error || 'Upload failed');
        }

        return {
            fileName: data.fileName as string,
            fileUrl: data.url as string,
        };
    } catch (error) {
        console.error('R2 upload error:', error);
        throw new Error('Failed to upload file to R2');
    }
}

export async function hashPassword(password: string, salt: string,): Promise<string> {

    const hash = crypto.scryptSync(password, salt, 64);
    return `${salt}:${hash.toString('hex')}`;
}

function hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
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

async function validateToken(c: Context, next: Next) {
    try {
        const authHeader = c.req.header('Authorization');
        if (!authHeader) {
            return c.json({ error: 'No token provided' }, 401);
        }

        const token = authHeader.split(' ')[1];
        const tokenHash = hashToken(token);
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        // Check if token exists and is not expired
        const activeToken = await prisma.activeToken.findFirst({
            where: {
                tokenHash: tokenHash,
                expiresAt: {
                    gt: new Date()
                }
            }
        });

        if (!activeToken) {
            return c.json({ error: 'Token is invalid or expired' }, 401);
        }

        await next();
    } catch (error) {
        console.error('Token validation error:', error);
        return c.json({ error: 'Authentication failed' }, 401);
    }
}
function verifyPassword(password: string, storedHash: string): boolean {
    const [salt, originalHash] = storedHash.split(':');
    const hash = crypto.scryptSync(password, salt, 64).toString('hex');
    console.log(originalHash);
    return hash === originalHash;
}

export { uploadToR2, validateToken, hashToken, signAndStoreToken, verifyPassword, }