
import { Hono } from 'hono';
import { jwt } from 'hono/jwt';
import { cors } from 'hono/cors';
import { validateToken } from './helper/helper';
import register from "./auth/register"
import login from './auth/login'
import profile from './auth/profile'
import password_reset from './auth/forgot_password'
import roomate_match from "./rommate_match/load_matchs"
import search from './search/search_property'
import properties from './property/property'

const app = new Hono<{
	Bindings: Env,
	Variables: {
		userId: string;
	}
}>();

// Middleware
app.use(cors());
app.use('/api/*', async (c, next) => {

	validateToken(c, next);
	const jwtMiddleware = jwt({
		secret: c.env.JWT_SECRET
	});
	return jwtMiddleware(c, next);
});

// Routes
app.route('/', register);
app.route('/', login)
app.route('/auth/password-reset', password_reset)
app.route('/api/user/profile', profile)
app.route("/api/roommate-match", roomate_match)
app.route("/api/search", search)
app.route("/api/properties", properties)


// Error handling
app.onError((err, c) => {
	console.error('Application error:', err);
	return c.json({ error: 'Internal Server Error' }, 500);
});

export default app;
 