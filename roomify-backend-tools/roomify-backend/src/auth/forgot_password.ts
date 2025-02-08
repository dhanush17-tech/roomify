import { Context, Hono } from 'hono';
import { randomBytes } from 'crypto';
import { hashPassword, verifyPassword } from '../helper/helper';
import { PrismaD1 } from '@prisma/adapter-d1';
import { PrismaClient } from '@prisma/client';

const app = new Hono<{
    Bindings: Env,
    Variables: {
        userId: string;
    }
}>();

// Request password reset
app.post('/', async (c) => {
    try {
        const { email } = await c.req.json();
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Find user
        const user = await prisma.user.findUnique({
            where: { email }
        });

        if (!user) {
            return c.json({ error: 'User not found' }, 404);
        }

        // Delete any existing reset tokens for this user
        await prisma.passwordReset.deleteMany({
            where: { userId: user.id }
        });

        // Generate plain token for email
        const resetToken = randomBytes(32).toString('hex');

        // Hash token for storage
        const hashedToken = await hashPassword(resetToken,);

        // Store hashed token
        await prisma.passwordReset.create({
            data: {
                userId: user.id,
                token: hashedToken,
                expiresAt: new Date(Date.now() + 3600000), // 1 hour
            }
        });

        console.log('Reset token generated:', resetToken);
        console.log('Hashed token stored:', hashedToken);

        // Send email with plain token
        await sendResetEmail(
            //email,
            "dhanush.kalaiselvan@gmail.com",
            resetToken, c);

        return c.json({ message: 'Reset email sent successfully' });
    } catch (error) {
        console.error('Password reset request error:', error);
        return c.json({ error: 'Failed to process reset request' }, 500);
    }
});

// Confirm password reset
app.post('/confirm', async (c) => {
    try {
        const { token, password } = await c.req.json();
        const adapter = new PrismaD1(c.env.DB);
        const prisma = new PrismaClient({ adapter });

        // Get all valid reset tokens
        const resetRequests = await prisma.passwordReset.findMany({
            where: {
                expiresAt: {
                    gt: new Date()
                }
            },
            include: {
                user: true
            }
        });

        // Find matching token
        const resetRequest = resetRequests.find(request =>
            verifyPassword(token, request.token)
        );

        if (!resetRequest) {
            return c.json({ error: 'Invalid or expired reset token' }, 400);
        }

        // Hash new password
        const hashedPassword = await hashPassword(password,);

        // Update password and clean up
        await prisma.$transaction([
            // Update user password
            prisma.user.update({
                where: { id: resetRequest.userId },
                data: { passwordHash: hashedPassword }
            }),
            // Delete all reset tokens for this user
            prisma.passwordReset.deleteMany({
                where: { userId: resetRequest.userId }
            })
        ]);

        return c.json({ message: 'Password reset successful' });
    } catch (error) {
        console.error('Password reset confirmation error:', error);
        return c.json({ error: 'Failed to reset password' }, 500);
    }
});

async function sendResetEmail(email: string, resetToken: string, c: Context) {
    const webResetUrl = `https://roomify-landingpage.vercel.app/forgot-password/${resetToken}`;
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.roomify.app';
    const appStoreUrl = 'https://apps.apple.com/app/roomify/id123456789';

    const emailContent = `
        <html>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                <h2>Reset Your Roomify Password</h2>
                <p>You requested to reset your password. Click the button below to reset your password:</p>
                <p>
                    <a href="${webResetUrl}" style="background-color: #E67E22; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0;">
                        Reset Password
                    </a>
                </p>
                <p style="margin-top: 20px;">Have the Roomify app installed? Use this link instead:</p>
                <p>
                    <a href="${webResetUrl}" style="background-color: #4A90E2; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0;">
                        Open in App
                    </a>
                </p>
                <p style="margin-top: 20px;">Don't have the Roomify app? Download it here:</p>
                <p>
                    <a href="${playStoreUrl}" style="color: #E67E22; text-decoration: none; margin-right: 15px;">Download for Android</a>
                    <a href="${appStoreUrl}" style="color: #E67E22; text-decoration: none;">Download for iOS</a>
                </p>
                <p style="margin-top: 20px; font-size: 0.9em; color: #666;">
                    This reset link will expire in 1 hour.
                    <br>
                    If you didn't request this password reset, please ignore this email.
                </p>
            </body>
        </html>
    `;

    const payload = {
        from: 'Roomify <hi@geekydan.dev>',
        to: email,
        subject: 'Reset Your Roomify Password',
        html: emailContent,
    };

    try {
        const response = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${c.env.RESEND_API_KEY}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(payload),
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error('Email API failed:', errorText);
            throw new Error(`Failed to send email: ${errorText}`);
        }

        console.log('Password reset email sent successfully');
    } catch (error) {
        console.error('Failed to send password reset email:', error);
        throw error;
    }
}

export default app;