# Pokedex Backend - Setup Guide

This guide will help you set up and run the Pokedex backend server.

## Prerequisites

- Node.js (v18 or higher)
- npm
- Redis (local or cloud)

## Installation

1. Install dependencies:
```bash
npm install
```

2. Set up environment variables:
   - Copy `.env.example` to create your `.env` file
   - Generate a JWT secret using: https://generate-secret.vercel.app/32
   - Update `JWT_TOKEN_SECRET` in `.env` with your generated secret
   - Configure Redis URL (see Redis Setup below)

## Redis Setup

### Option 1: Local Redis (Recommended for Development)

**macOS:**
```bash
brew install redis
brew services start redis
```

**Linux:**
```bash
sudo apt-get install redis-server
sudo service redis-server start
```

Use this in your `.env`:
```
REDIS_URL=redis://localhost:6379
```

### Option 2: Redis Cloud

1. Sign up at https://redis.com/try-free/
2. Create a new database
3. Copy the connection URL
4. Update `.env` with your Redis Cloud URL:
```
REDIS_URL=redis://username:password@host:port
```

## Running the Server

### Development Mode (with auto-reload):
```bash
npm run dev
```

### Production Mode:
```bash
npm run build
npm start
```

## Testing the API

### 1. Generate a JWT Token

```bash
curl -X POST http://localhost:3000/token \
  -H "Content-Type: application/json" \
  -d '{"pennkey": "your_pennkey"}'
```

Save the returned token for authenticated requests.

### 2. Test Pokemon Endpoints

**List Pokemon:**
```bash
curl "http://localhost:3000/pokemon/?limit=5&offset=0"
```

**Get Pokemon by Name:**
```bash
curl "http://localhost:3000/pokemon/pikachu"
```

### 3. Test Box Endpoints (Authenticated)

Replace `YOUR_TOKEN` with the token from step 1.

**Create Box Entry:**
```bash
curl -X POST http://localhost:3000/box/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "createdAt": "2024-01-15T10:30:00Z",
    "level": 25,
    "location": "Route 1",
    "notes": "My first catch",
    "pokemonId": 25
  }'
```

**List Box Entries:**
```bash
curl http://localhost:3000/box/ \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Get Box Entry:**
```bash
curl http://localhost:3000/box/ENTRY_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Update Box Entry:**
```bash
curl -X PUT http://localhost:3000/box/ENTRY_ID \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"level": 30}'
```

**Delete Box Entry:**
```bash
curl -X DELETE http://localhost:3000/box/ENTRY_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Clear All Box Entries:**
```bash
curl -X DELETE http://localhost:3000/box/ \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Project Structure

```
src/
├── index.ts           # Main server entry point
├── types.ts           # TypeScript type definitions
├── validation.ts      # Zod validation schemas
├── redis.ts           # Redis client configuration
├── auth.ts            # JWT authentication middleware
├── pokemonService.ts  # Pokemon API data synthesis
├── boxService.ts      # Box CRUD operations
├── pokemonRoutes.ts   # Pokemon endpoints
├── boxRoutes.ts       # Box endpoints
└── tokenRoutes.ts     # Token generation endpoint
```

## Troubleshooting

### Redis Connection Error
- Ensure Redis is running: `redis-cli ping` (should return "PONG")
- Check your REDIS_URL in `.env`

### JWT Token Error
- Ensure JWT_TOKEN_SECRET is set in `.env`
- Token expires after 24 hours - generate a new one if needed

### Port Already in Use
- Change the PORT in `.env` to a different value (e.g., 3001)

## Development

- **Format code:** `npm run format`
- **Build:** `npm run build`
- **Type check:** `npx tsc --noEmit`
