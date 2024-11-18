import { Context, Hono } from 'hono';
import { jwt, sign } from 'hono/jwt';
import { scryptSync, randomBytes } from 'crypto';
import { Next, Variables } from 'hono/types';
import { SignatureKey } from 'hono/utils/jwt/jws';
import { nanoid } from 'nanoid';

import nodemailer from 'nodemailer';

import * as crypto from "crypto";

const app = new Hono<{
	Bindings: Env,
	Variables: {
		userId: string
	}
}>();


const fs = require('fs');
const path = require('path');

app.use('/api/*', async (c, next) => {
	validateToken(c, next);
	const jwtMiddleware = jwt({
		secret: c.env.JWT_SECRET
	});
	return jwtMiddleware(c, next);
});

// Rest of the authentication helpers remain the same
function hashPassword(password: string, salt: string): string {
	const hash = scryptSync(password, salt, 64);
	return `${salt}:${hash.toString('hex')}`;
}

function verifyPassword(password: string, storedHash: string): boolean {
	const [salt, originalHash] = storedHash.split(':');
	const hash = scryptSync(password, salt, 64).toString('hex');
	return hash === originalHash;
}
app.post('/auth/register', async (c) => {
	try {
		const {
			username,
			email,
			password,
			displayName,
			age,
			university,
			location
		} = await c.req.json();

		// Validate required fields
		if (!username || !email || !password || !displayName) {
			return c.json({
				error: 'Username, email, password, and display name are required'
			}, 400);
		}

		const db = c.env.DB;

		const existingUser = await db
			.prepare('SELECT id FROM users WHERE email = ? OR username = ?')
			.bind(email, username)
			.first();

		if (existingUser) {
			return c.json({ error: 'User already exists' }, 400);
		}

		const salt = randomBytes(16).toString('hex');
		const hashedPassword = hashPassword(password, salt);
		const userId = crypto.randomUUID();

		// Use null coalescing for optional fields
		const ageValue = age !== undefined ? age : null;
		const universityValue = university || null;
		const locationValue = location || null;

		await db
			.prepare(`
        INSERT INTO users (
          id, 
          username, 
          email, 
          display_name, 
          password_hash, 
          age, 
          university, 
          location
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `)
			.bind(
				userId,
				username,
				email,
				displayName,
				hashedPassword,
				ageValue,
				universityValue,
				locationValue
			)
			.run();

		const token = await signAndStoreToken(
			{ sub: userId },
			c.env.JWT_SECRET,
			c.env.DB
		);

		return c.json({ token });
	} catch (error) {
		console.error('Error during registration:', error);
		return c.json({
			error: 'Internal Server Error',
			details: (error as Error).message
		}, 500);
	}
});

app.post('/auth/login', async (c) => {
	const { email, password } = await c.req.json();
	const db = c.env.DB;

	const user = await db
		.prepare('SELECT id, password_hash FROM users WHERE email = ?')
		.bind(email)
		.first();

	if (!user || !verifyPassword(password, user.password_hash as string)) {
		return c.json({ error: 'Invalid credentials' }, 401);
	}

	// Fix 2: Use proper JWT signing
	const token = await signAndStoreToken(
		{ sub: user.id },
		c.env.JWT_SECRET,
		c.env.DB
	);

	return c.json({ token });
});

app.get('/api/user/profile', async (c) => {
	// Fix 3: Access JWT payload correctly
	const payload = c.get('jwtPayload');
	const userId = payload.sub;

	const db = c.env.DB;
	const user = await db
		.prepare(`
      SELECT id, username, display_name, profile_image_url, bio, email, 
             language, receive_notifications
      FROM users WHERE id = ?
    `)
		.bind(userId)
		.first();

	if (!user) {
		return c.json({ error: 'User not found' }, 404);
	}

	const [favorites, listings] = await Promise.all([
		db.prepare(`
      SELECT l.* FROM listings l
      JOIN favorites f ON l.id = f.listing_id
      WHERE f.user_id = ?
    `).bind(userId).all(),
		db.prepare('SELECT * FROM listings WHERE user_id = ?')
			.bind(userId).all()
	]);

	return c.json({
		...user,
		favorites: favorites.results,
		listings: listings.results,
	});
});

app.post('/auth/password-reset', async (c) => {
	try {
		const { email } = await c.req.json();

		// Find user
		const user = await c.env.DB.prepare(
			'SELECT id, email FROM users WHERE email = ?'
		)
			.bind(email)
			.first();

		if (!user) {
			return c.json({ error: 'User not found' }, 400);
		}

		// Generate reset token
		const resetToken = randomBytes(32).toString('hex');
		const salt = randomBytes(16).toString('hex'); // Generate random salt
		const tokenHash = hashPassword(resetToken, salt);

		// Store reset token
		await c.env.DB.prepare(`
      INSERT INTO password_resets (user_id, token, expires_at)
      VALUES (?, ?, datetime('now', '+1 hour'))
    `)
			.bind(user.id, tokenHash)
			.run();

		// Send email
		const resetLink = `http://roomify_app/reset-password?token=${resetToken}`;
		await sendResetEmail(user.email as string, resetLink);

		return c.json({ message: 'Reset link sent' });
	} catch (error) {
		console.error(error);
		return c.json({ error: 'Failed to process request' }, 500);
	}
});

// Reset password
app.post('/auth/password-reset/confirm', async (c) => {
	try {
		const { token, password } = await c.req.json();

		// Find valid reset token
		const resetRequest = await c.env.DB.prepare(`
      SELECT user_id, token
      FROM password_resets
      WHERE expires_at > datetime('now')
      ORDER BY expires_at DESC
      LIMIT 1
    `).first();

		if (!resetRequest) {
			return c.json({ error: 'Invalid or expired token' }, 400);
		}

		// Verify token
		const isValid = verifyPassword(token, resetRequest.token as string);
		if (!isValid) {
			return c.json({ error: 'Invalid token' }, 400);
		}

		// Update password
		const salt = randomBytes(16).toString('hex'); // Generate random salt for password
		const hashedPassword = hashPassword(password, salt);
		await c.env.DB.prepare(
			'UPDATE users SET password_hash = ? WHERE id = ?'
		)
			.bind(hashedPassword, resetRequest.user_id)
			.run();

		// Delete used token
		await c.env.DB.prepare(
			'DELETE FROM password_resets WHERE user_id = ?'
		)
			.bind(resetRequest.user_id)
			.run();

		return c.json({ message: 'Password updated successfully' });
	} catch (error) {
		console.error(error);
		return c.json({ error: 'Failed to reset password' }, 500);
	}
});


// Helper function to delete file from R2 worker
async function deleteFromR2(fileName: string): Promise<void> {
	try {
		const response = await fetch(`http://localhost:57117/delete/${fileName}`, {
			method: 'DELETE',
		});

		if (!response.ok) {
			throw new Error('Failed to delete file');
		}

		const data: any = await response.json();

		if (!data.success) {
			throw new Error(data.error || 'Delete failed');
		}
	} catch (error) {
		console.error('R2 delete error:', error);
		throw new Error('Failed to delete file from R2');
	}
}


async function uploadToR2(file: File): Promise<{ fileName: string; fileUrl: string }> {
	try {
		const formData = new FormData();
		formData.append('file', file);

		const response = await fetch('http://localhost:57117/upload', {
			method: 'POST',
			body: formData,
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

app.put('/api/user/profile', async (c) => {
	try {
		const payload = c.get('jwtPayload');
		if (!payload) {
			return c.json({ error: 'Unauthorized' }, 401);
		}

		const userId = payload.sub;
		const formData = await c.req.formData();

		// Get profile photo from form data
		const profilePhoto = formData.get('profilePhoto') as File | null;

		// Get other form data
		const data = {
			displayName: formData.get('displayName'),
			email: formData.get('email'),
			password: formData.get('password'),
			university: formData.get('university'),
			bio: formData.get('bio'),
			age: formData.get('age'),
			gender: formData.get('gender'),
		};

		// Check if user exists
		const user = await c.env.DB.prepare(`
      SELECT id, profile_image_url FROM users WHERE id = ?
    `).bind(userId).first();

		if (!user) {
			return c.json({ error: 'User not found' }, 404);
		}

		// Handle profile photo upload
		let profileImageUrl = user.profile_image_url;
		if (profilePhoto) {
			// Delete old photo if exists
			if (typeof profileImageUrl === 'string') {
				try {
					const oldFileName = profileImageUrl.split('/').pop();
					if (oldFileName) {
						await deleteFromR2(oldFileName);
					}
				} catch (error) {
					console.error('Failed to delete old profile photo:', error);
				}
			}

			// Upload new photo
			const { fileUrl } = await uploadToR2(profilePhoto);
			console.log(fileUrl);
			profileImageUrl = fileUrl;
		}

		// Build update query
		const updateFields = [];
		const updateValues = [];

		if (data.displayName) {
			updateFields.push('display_name = ?');
			updateValues.push(data.displayName);
		}
		if (data.email) {
			updateFields.push('email = ?');
			updateValues.push(data.email);
		}
		if (data.university) {
			updateFields.push('university = ?');
			updateValues.push(data.university);
		}
		if (data.bio) {
			updateFields.push('bio = ?');
			updateValues.push(data.bio);
		}
		if (data.age) {
			updateFields.push('age = ?');
			updateValues.push(data.age);
		}
		if (data.gender) {
			updateFields.push('gender = ?');
			updateValues.push(data.gender);
		}
		if (profileImageUrl !== user.profile_image_url) {
			updateFields.push('profile_image_url = ?');
			updateValues.push(profileImageUrl);
		}

		// Update password if provided
		if (data.password) {
			const salt = randomBytes(16).toString('hex');
			const hashedPassword = hashPassword(data.password as string, salt);
			updateFields.push('password_hash = ?');
			updateValues.push(hashedPassword);
		}

		if (updateFields.length > 0) {
			updateValues.push(userId);
			await c.env.DB.prepare(`
        UPDATE users 
        SET ${updateFields.join(', ')}
        WHERE id = ?
      `).bind(...updateValues).run();
		}

		// Get updated user profile
		const updatedUser = await c.env.DB.prepare(`
      SELECT 
        id, 
        username, 
        display_name, 
        email, 
        bio, 
        university, 
        age, 
        gender,
        profile_image_url,
        language,
        receive_notifications
      FROM users 
      WHERE id = ?
    `).bind(userId).first();

		return c.json(updatedUser);
	} catch (error) {
		console.error('Profile update error:', error);
		return c.json({
			error: 'Failed to update profile',
			details: (error as Error).message
		}, 500);
	}
});

// Add endpoint to delete profile photo
app.delete('/api/user/profile-photo', async (c) => {
	const payload = c.get('jwtPayload');
	if (!payload) {
		return c.json({ error: 'Unauthorized' }, 401);
	}

	const userId = payload.sub;
	const db = c.env.DB;

	try {
		const user = await db.prepare(`
      SELECT profile_image_url FROM users WHERE id = ?
    `).bind(userId).first();

		if (!user || !user.profile_image_url) {
			return c.json({ error: 'No profile photo found' }, 404);
		}

		// Delete from R2
		await c.env.BUCKET.delete(user.profile_image_url as string);

		// Update database
		await db.prepare(`
      UPDATE users 
      SET profile_image_url = NULL 
      WHERE id = ?
    `).bind(userId).run();

		return c.json({ message: 'Profile photo deleted successfully' });
	} catch (error) {
		console.error('Failed to delete profile photo:', error);
		return c.json({ error: 'Failed to delete profile photo' }, 500);
	}
});


// Email sending function
async function sendResetEmail(email: string, resetLink: string) {
	const transporter = nodemailer.createTransport(
		{
			// Configure your email service
			service: 'gmail',
			host: 'smtp.gmail.com',
			port: 587,
			secure: false, // true for 465, false for other ports
			auth: {
				user: 'dhanush.kalaiselvan@gmail.com',
				pass: 'fkmcvdhjdimwdlmw' // Use App Password generated from Google Account
			}
		});

	await transporter.sendMail({
		from: 'dhanush.kalaiselvan@gmail.com',
		to: email,
		subject: 'Password Reset Request',
		html: `Click <a href="${resetLink}">here</a> to reset your password.`,
	});
}




app.post('/auth/signout', async (c) => {
	try {
		const token = c.req.header('Authorization')?.split(' ')[1];

		if (!token) {
			return c.json({ error: 'No token provided' }, 401);
		}

		const tokenHash = hashToken(token);

		// Delete token from active tokens
		await c.env.DB.prepare(`
      DELETE FROM active_tokens
      WHERE token_hash = ?
    `).bind(tokenHash).run();

		return c.json({ message: 'Successfully signed out' });
	} catch (error) {
		console.error('Sign out error:', error);
		return c.json({ error: 'Failed to sign out' }, 500);
	}
});

async function validateToken(c: Context, next: Next) {
	try {
		const authHeader = c.req.header('Authorization');
		if (!authHeader) {
			return c.json({ error: 'No token provided' }, 401);
		}

		const token = authHeader.split(' ')[1];
		const tokenHash = hashToken(token);

		// Check if token exists in active tokens
		const activeToken = await c.env.DB.prepare(`
      SELECT token_hash 
      FROM active_tokens 
      WHERE token_hash = ? AND expires_at > datetime('now')
    `).bind(tokenHash).first();

		if (!activeToken) {
			return c.json({ error: 'Token is invalid or expired' }, 401);
		}



		await next();
	} catch (error) {
		return c.json({ error: 'Authentication failed' }, 401);
	}
}
// Helper function to hash token
function hashToken(token: string): string {
	return crypto.createHash('sha256').update(token).digest('hex');
}

// Modified sign function to store token
async function signAndStoreToken(payload: any, secret: string, db: D1Database): Promise<string> {
	const token = await sign(
		payload,
		secret,
	);

	// Store token hash
	const tokenHash = hashToken(token);
	await db.prepare(`
    INSERT INTO active_tokens (
      token_hash,
      user_id,
      expires_at
    )
    VALUES (?, ?, datetime('now', '+24 hours'))
  `).bind(
		tokenHash,
		payload.sub
	).run();

	return token;
}

app.get('/api/roommate-match', async (c) => {
	try {
		const payload = c.get('jwtPayload');
		if (!payload) {
			return c.json({ error: 'Unauthorized' }, 401);
		}

		const currentUserId = payload.sub;

		// Get current user's preferences
		const currentUser = await c.env.DB.prepare(`
      SELECT 
        university,
        age,
        gender,
        location
      FROM users 
      WHERE id = ?
    `).bind(currentUserId).first();

		if (!currentUser) {
			return c.json({ error: 'User not found' }, 404);
		}

		// Fetch potential matches excluding current user
		// You can modify the WHERE clause based on your matching criteria
		const potentialMatches = await c.env.DB.prepare(`
      SELECT 
        id,
        username,
        display_name,
        profile_image_url,
        bio,
        university,
        age,
        gender,
        location,
        language
      FROM users 
      WHERE id != ? 
        AND (university = ? OR ? IS NULL)
        AND (location = ? OR ? IS NULL)
        AND (age BETWEEN ? - 3 AND ? + 3 OR ? IS NULL)
      ORDER BY 
        CASE 
          WHEN university = ? THEN 1
          WHEN location = ? THEN 2
          ELSE 3
        END,
        created_at DESC
      LIMIT 50
    `).bind(
			currentUserId,
			currentUser.university, currentUser.university,
			currentUser.location, currentUser.location,
			currentUser.age, currentUser.age, currentUser.age,
			currentUser.university,
			currentUser.location
		).all();
		console.log({
			matches: potentialMatches.results.map(user => ({
				id: user.id,
				username: user.username,
				displayName: user.display_name,
				profileImageUrl: user.profile_image_url,
				bio: user.bio,
				university: user.university,
				age: user.age,
				gender: user.gender,
				location: user.location,
				language: user.language,
				matchPercentage: calculateMatchPercentage(currentUser, user)
			}))
		})
		return c.json({
			matches: potentialMatches.results.map(user => ({
				id: user.id,
				username: user.username,
				displayName: user.display_name,
				profileImageUrl: user.profile_image_url,
				bio: user.bio,
				university: user.university,
				age: user.age,
				gender: user.gender,
				location: user.location,
				language: user.language,
				matchPercentage: calculateMatchPercentage(currentUser, user)
			}))
		});

	} catch (error: any) {
		console.error('Roommate match error:', error);
		return c.json({
			error: 'Failed to fetch matches',
			details: error.message
		}, 500);
	}
});

// Helper function to calculate match percentage
function calculateMatchPercentage(currentUser: any, potentialMatch: any): number {
	let score = 0;
	let totalFactors = 0;

	// University match
	if (currentUser.university && potentialMatch.university) {
		totalFactors++;
		if (currentUser.university === potentialMatch.university) {
			score++;
		}
	}

	// Location match
	if (currentUser.location && potentialMatch.location) {
		totalFactors++;
		if (currentUser.location === potentialMatch.location) {
			score++;
		}
	}

	// Age match (within 3 years)
	if (currentUser.age && potentialMatch.age) {
		totalFactors++;
		if (Math.abs(currentUser.age - potentialMatch.age) <= 3) {
			score++;
		}
	}

	// Gender preference match
	if (currentUser.gender && potentialMatch.gender) {
		totalFactors++;
		if (currentUser.gender === potentialMatch.gender) {
			score++;
		}
	}

	// Calculate percentage
	return totalFactors > 0 ? Math.round((score / totalFactors) * 100) : 0;
}

// Optional: Add route for filtering matches
app.post('/api/roommate-match/filter', async (c) => {
	try {
		const payload = c.get('jwtPayload');
		if (!payload) {
			return c.json({ error: 'Unauthorized' }, 401);
		}

		const { university, location, minAge, maxAge, gender } = await c.req.json();
		const currentUserId = payload.sub;

		let query = `
      SELECT 
        id,
        username,
        display_name,
        profile_image_url,
        bio,
        university,
        age,
        gender,
        location,
        language
      FROM users 
      WHERE id != ?
    `;
		const params = [currentUserId];

		if (university) {
			query += ` AND university = ?`;
			params.push(university);
		}
		if (location) {
			query += ` AND location = ?`;
			params.push(location);
		}
		if (minAge) {
			query += ` AND age >= ?`;
			params.push(minAge);
		}
		if (maxAge) {
			query += ` AND age <= ?`;
			params.push(maxAge);
		}
		if (gender) {
			query += ` AND gender = ?`;
			params.push(gender);
		}

		query += `ORDER BY created_at DESC LIMIT 50`;

		const matches = await c.env.DB.prepare(query)
			.bind(...params)
			.all();

		return c.json({ matches: matches.results });

	} catch (error: any) {
		console.error('Filter matches error:', error);
		return c.json({
			error: 'Failed to filter matches',
			details: error.message
		}, 500);
	}
});



export default app;