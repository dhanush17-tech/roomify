import app from ".";


// search-routes.ts
app.get('/api/search', async (c) => {
    try {
        const query = c.req.query('query') || '';
        const type = c.req.query('type') || 'Property';
        const filters: SearchFilters = {
            gender: c.req.query('gender'),
            minCompatibility: Number(c.req.query('minCompatibility')),
            maxCompatibility: Number(c.req.query('maxCompatibility')),
            lifestylePreferences: c.req.query('lifestylePreferences')?.split(','),
            proximity: Number(c.req.query('proximity')),
            location: c.req.query('location'),
            minPrice: Number(c.req.query('minPrice')),
            maxPrice: Number(c.req.query('maxPrice')),
            propertyTypes: c.req.query('propertyTypes')?.split(','),
            amenities: c.req.query('amenities')?.split(','),
            itemCategories: c.req.query('itemCategories')?.split(','),
        };

        let results;
        switch (type) {
            case 'Property':
                results = await searchProperties(c.env.DB, query, filters);
                break;
            case 'Roommate':
                results = await searchRoommates(c.env.DB, query, filters);
                break;
            case 'Marketplace':
                results = await searchMarketplace(c.env.DB, query, filters);
                break;
            default:
                return c.json({ error: 'Invalid search type' }, 400);
        }

        return c.json({ results });
    } catch (error) {
        console.error('Search error:', error);
        return c.json({ error: 'Search failed' }, 500);
    }
});

async function searchProperties(db: D1Database, query: string, filters: SearchFilters) {
    let sql = `
    SELECT 
      l.id,
      l.title,
      l.description,
      l.location,
      l.price,
      l.created_at,
      p.number_of_rooms,
      GROUP_CONCAT(DISTINCT pa.amenity) as amenities,
      GROUP_CONCAT(DISTINCT pi.image_url) as images
    FROM listings l
    JOIN properties p ON l.id = p.listing_id
    LEFT JOIN property_amenities pa ON p.listing_id = pa.property_id
    LEFT JOIN property_images pi ON p.listing_id = pi.property_id
    WHERE l.type = 'Property'
  `;

    const params: any[] = [];

    if (query) {
        sql += ` AND (l.title LIKE ? OR l.description LIKE ? OR l.location LIKE ?)`;
        params.push(`%${query}%`, `%${query}%`, `%${query}%`);
    }

    if (filters.location) {
        sql += ` AND l.location LIKE ?`;
        params.push(`%${filters.location}%`);
    }

    if (filters.minPrice) {
        sql += ` AND l.price >= ?`;
        params.push(filters.minPrice);
    }

    if (filters.maxPrice) {
        sql += ` AND l.price <= ?`;
        params.push(filters.maxPrice);
    }

    if (filters.propertyTypes?.length) {
        sql += ` AND l.category IN (${filters.propertyTypes.map(() => '?').join(',')})`;
        params.push(...filters.propertyTypes);
    }

    if (filters.amenities?.length) {
        sql += ` AND EXISTS (
      SELECT 1 FROM property_amenities pa2 
      WHERE pa2.property_id = p.listing_id 
      AND pa2.amenity IN (${filters.amenities.map(() => '?').join(',')})
    )`;
        params.push(...filters.amenities);
    }

    sql += ` GROUP BY l.id ORDER BY l.created_at DESC LIMIT 50`;

    const results = await db.prepare(sql).bind(...params).all();
    return results.results.map(row => ({
        ...row,
        amenities: row.amenities?.split(',') || [],
        images: row.images?.split(',') || [],
    }));
}

async function searchRoommates(db: D1Database, query: string, filters: SearchFilters) {
    let sql = `
    SELECT 
      u.id,
      u.username,
      u.display_name,
      u.profile_image_url,
      u.bio,
      u.university,
      u.age,
      u.gender,
      u.location
    FROM users u
    WHERE 1=1
  `;

    const params: any[] = [];

    if (query) {
        sql += ` AND (u.username LIKE ? OR u.display_name LIKE ? OR u.bio LIKE ?)`;
        params.push(`%${query}%`, `%${query}%`, `%${query}%`);
    }

    if (filters.gender) {
        sql += ` AND u.gender = ?`;
        params.push(filters.gender);
    }

    if (filters.location) {
        sql += ` AND u.location LIKE ?`;
        params.push(`%${filters.location}%`);
    }

    sql += ` ORDER BY u.created_at DESC LIMIT 50`;

    return await db.prepare(sql).bind(...params).all();
}

async function searchMarketplace(db: D1Database, query: string, filters: SearchFilters) {
    let sql = `
    SELECT 
      l.id,
      l.title,
      l.description,
      l.location,
      l.price,
      l.category,
      l.created_at
    FROM listings l
    WHERE l.type = 'Marketplace'
  `;

    const params: any[] = [];

    if (query) {
        sql += ` AND (l.title LIKE ? OR l.description LIKE ?)`;
        params.push(`%${query}%`, `%${query}%`);
    }

    if (filters.itemCategories?.length) {
        sql += ` AND l.category IN (${filters.itemCategories.map(() => '?').join(',')})`;
        params.push(...filters.itemCategories);
    }

    if (filters.minPrice) {
        sql += ` AND l.price >= ?`;
        params.push(filters.minPrice);
    }

    if (filters.maxPrice) {
        sql += ` AND l.price <= ?`;
        params.push(filters.maxPrice);
    }

    sql += ` ORDER BY l.created_at DESC LIMIT 50`;

    return await db.prepare(sql).bind(...params).all();
}