

const corsHeaders = {
	'Access-Control-Allow-Origin': '*',
	'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
	'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export default {
	async fetch(request: Request, env: Env): Promise<Response> {
		// Handle CORS preflight requests
		if (request.method === 'OPTIONS') {
			return new Response(null, {
				headers: corsHeaders,
			});
		}

		try {
			const url = new URL(request.url);

			// Handle different routes
			if (request.method === 'POST' && url.pathname === '/upload') {
				return handleUpload(request, env);
			} else if (request.method === 'DELETE' && url.pathname.startsWith('/delete/')) {
				return handleDelete(request, env);
			} else if (request.method === 'GET' && url.pathname.startsWith('/image/')) {
				return handleGet(request, env);
			}

			return new Response('Not found', { status: 404 });
		} catch (error) {
			console.error('Error:', error);
			return new Response('Internal Server Error', { status: 500 });
		}
	},
};
async function handleUpload(request: Request, env: Env): Promise<Response> {
	try {
		const contentType = request.headers.get('Content-Type') || '';

		if (!contentType.startsWith('multipart/form-data')) {
			return new Response('Invalid content type', { status: 400 });
		}

		const formData = await request.formData();
		const file = formData.get('file') as File;
		const uploadType = formData.get("uploadType") as string;

		if (!file) {
			return new Response('No file provided', { status: 400 });
		}

		console.log('File received:', {
			name: file.name,
			type: file.type,
			size: file.size,
		});

		// Upload logic here
		const fileExtension = file.name.split('.').pop() || '';
		const fileName = `${crypto.randomUUID()}.${fileExtension}`;
		const fullPath = `${uploadType}/${fileName}`;

		await env.BUCKET.put(fullPath, file.stream(), {
			httpMetadata: {
				contentType: file.type,
			},
		});

		const imageUrl = `${env.R2_PUBLIC_URL}/${fullPath}`;

		return new Response(
			JSON.stringify({
				success: true,
				url: imageUrl,
				fileName: fullPath,
			}),
			{
				headers: {
					'Content-Type': 'application/json',
					...corsHeaders,
				},
			}
		);
	} catch (error) {
		console.error('Upload error:', error);
		return new Response(
			JSON.stringify({
				success: false,
				error: 'Upload failed',
			}),
			{
				status: 500,
				headers: {
					'Content-Type': 'application/json',
					...corsHeaders,
				},
			}
		);
	}
}
async function handleDelete(request: Request, env: Env): Promise<Response> {
	try {
		// Ensure the request has a valid JSON body
		const contentType = request.headers.get('Content-Type') || '';
		if (!contentType.includes('application/json')) {
			return new Response('Invalid content type. Expected application/json.', { status: 400 });
		}

		// Parse the JSON body
		const { fileName, uploadType }: { fileName: string, uploadType: string } = await request.json();

		// Validate the required fields
		if (!fileName || !uploadType) {
			return new Response(
				JSON.stringify({ success: false, error: 'fileName and uploadType are required.' }),
				{
					status: 400,
					headers: {
						'Content-Type': 'application/json',
						...corsHeaders,
					},
				}
			);
		}

		// Delete the file from the bucket
		await env.BUCKET.delete(`${uploadType}/${fileName}`);

		return new Response(
			JSON.stringify({ success: true, message: 'File deleted successfully.' }),
			{
				headers: {
					'Content-Type': 'application/json',
					...corsHeaders,
				},
			}
		);
	} catch (error) {
		console.error('Delete error:', error);

		return new Response(
			JSON.stringify({
				success: false,
				error: 'Delete operation failed.',
				details: error.message || 'Unknown error',
			}),
			{
				status: 500,
				headers: {
					'Content-Type': 'application/json',
					...corsHeaders,
				},
			}
		);
	}
}

async function handleGet(request: Request, env: Env): Promise<Response> {
	try {
		const fileName = request.url.split('/image/')[1];
		if (!fileName) {
			return new Response('No file name provided', { status: 400 });
		}

		const object = await env.BUCKET.get(`images/${fileName}`);
		if (!object) {
			return new Response('File not found', { status: 404 });
		}

		return new Response(object.body, {
			headers: {
				'Content-Type': object.httpMetadata?.contentType || 'image/jpeg',
				...corsHeaders,
			},
		});
	} catch (error) {
		console.error('Get error:', error);
		return new Response('Failed to get image', { status: 500 });
	}
}