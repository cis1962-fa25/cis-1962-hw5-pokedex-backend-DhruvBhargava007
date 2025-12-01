import express from 'express';
import dotenv from 'dotenv';
import { connectRedis } from './redis';
import pokemonRoutes from './pokemonRoutes';
import boxRoutes from './boxRoutes';
import tokenRoutes from './tokenRoutes';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Routes
app.use('/pokemon', pokemonRoutes);
app.use('/box', boxRoutes);
app.use('/token', tokenRoutes);

// Health check endpoint
app.get('/', (request, response) => {
    response.json({ message: 'Pokedex API is running' });
});

// Start server
async function startServer() {
    try {
        // Connect to Redis
        await connectRedis();

        // Start Express server
        app.listen(PORT, () => {
            console.log(`Server is running on port ${PORT}`);
        });
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
}

startServer();
