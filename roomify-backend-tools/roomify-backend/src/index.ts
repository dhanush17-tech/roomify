
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
import prefrences from './profile/prefrences'
import chat from "./chat/chat";
import marketplace from "./marketplace/marketplace";
import leads from "./property/leads";
export { ChatRoom } from './chat/durable_objects';

const app = new Hono<{
	Bindings: Env,
	Variables: {
		userId: string;
	}
}>();
 
// Middleware
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
app.route("/api/user", prefrences)
app.route("/api/chat", chat)
app.route("/api/marketplace", marketplace)
app.route("/api/leads", leads)
// Error handling
app.onError((err, c) => {
	console.error('Application error:', err);
	return c.json({ error: 'Internal Server Error' }, 500);
});

export default app;
