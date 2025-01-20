
wrangler d1 export <name>

Export the contents or schema of your database as a .sql file

POSITIONALS
  name  The name or binding of the DB  [string] [required]

GLOBAL FLAGS
  -j, --experimental-json-config  Experimental: support wrangler.json  [boolean]
  -c, --config                    Path to .toml configuration file  [string]
  -e, --env                       Environment to use for operations and .env files  [string]
  -h, --help                      Show help  [boolean]
  -v, --version                   Show version number  [boolean]

OPTIONS
      --local      Export from your local DB you use with wrangler dev  [boolean]
      --remote     Export from your live D1  [boolean]
      --no-schema  Only output table contents, not the DB schema  [boolean]
      --no-data    Only output table schema, not the contents of the DBs themselves  [boolean]
      --table      Specify which tables to include in export  [string]
      --output     Which .sql file to output to  [string] [required]
