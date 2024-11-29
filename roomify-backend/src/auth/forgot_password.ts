
import nodemailer from 'nodemailer';
import { Hono } from 'hono';
import { scryptSync, randomBytes } from 'crypto';
import { hashPassword, verifyPassword } from '../helper/helper';
import { PrismaD1 } from '@prisma/adapter-d1';
import { PrismaClient } from '@prisma/client';


const app = new Hono<{
    Bindings: Env,
    Variables: {
        userId: string;
    }
}>();

app.post('/', async (c) => {
    try {
        const { email } = await c.req.json();
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        const user = await prisma.user.findUnique({
            where: { email }
        });

        if (!user) {
            return c.json({ error: 'User not found' }, 404);
        }

        const resetToken = randomBytes(32).toString('hex');
        const salt = randomBytes(16).toString('hex');
        const tokenHash = await hashPassword(resetToken, salt);

        await prisma.passwordReset.create({
            data: {
                userId: user.id,
                token: tokenHash,
                expiresAt: new Date(Date.now() + 3600000), // 1 hour
            }
        });
        console.log("This is the resetToken: ", resetToken);

        await sendResetEmail(email, resetToken);

        return c.json({ message: 'Reset email sent' });
    } catch (error) {
        console.error('Password reset error:', error);
        return c.json({ error: 'Failed to process request' }, 500);
    }
});

app.post('/confirm', async (c) => {
    try {
        const { token, password } = await c.req.json();
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });
        // Find valid reset token
        const resetRequest = await prisma.passwordReset.findFirst({
            where: {
                expiresAt: {
                    gt: new Date()
                }
            },
            orderBy: {
                expiresAt: 'desc'
            },
            include: {
                user: true
            }
        });

        if (!resetRequest) {
            return c.json({ error: 'Invalid or expired token' }, 400);
        }

        // Verify token
        const isValid = verifyPassword(token, resetRequest.token);
        if (!isValid) {
            return c.json({ error: 'Invalid token' }, 400);
        }

        // Generate new password hash
        const salt = randomBytes(16).toString('hex');
        const hashedPassword = await hashPassword(password, salt);

        // Update password and delete reset token
        await prisma.$transaction([
            prisma.user.update({
                where: { id: resetRequest.userId },
                data: { passwordHash: hashedPassword }
            }),
            prisma.passwordReset.deleteMany({
                where: { userId: resetRequest.userId }
            })
        ]);

        return c.json({ message: 'Password updated successfully' });
    } catch (error) {
        console.error('Password reset error:', error);
        return c.json({ error: 'Failed to reset password' }, 500);
    }
});

async function sendResetEmail(email: string, resetToken: string) {
    const frontendUrl = `https://reset-password?token=${resetToken}`;
    const payload = {
        from: 'hi@geekydan.dev',
        to: email,
        subject: 'Password Reset Request',
        html: `Click <a href="${frontendUrl}">here</a> to reset your password.`,
    };

    console.log('Email payload:', payload);

    const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer re_hUWMWbHL_MZf3ckdjYypRLvCi76Bm3iae`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
    });

    if (!response.ok) {
        const errorText = await response.text();
        console.error('Email API failed:', errorText);
        throw new Error(`Failed to send email: ${errorText}`);
    }

    console.log('Email sent successfully.');
}



export default app;