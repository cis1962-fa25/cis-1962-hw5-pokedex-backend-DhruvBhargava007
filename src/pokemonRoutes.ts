import { Router, Request, Response } from 'express';
import { getPokemonByName, getPokemonList } from './pokemonService';
import { PokemonListQuerySchema } from './validation';
import { ErrorResponse } from './types';

const router = Router();

/**
 * GET /pokemon/ - List Pokemon with pagination
 */
router.get('/', async (request: Request, response: Response) => {
    try {
        // Validate query parameters
        const result = PokemonListQuerySchema.safeParse(request.query);

        if (!result.success) {
            const error: ErrorResponse = {
                code: 'BAD_REQUEST',
                message:
                    'Invalid query parameters. Required: limit (positive number) and offset (non-negative number)',
            };
            response.status(400).json(error);
            return;
        }

        const { limit, offset } = result.data;

        const pokemon = await getPokemonList(limit, offset);
        response.status(200).json(pokemon);
    } catch (error) {
        const errorResponse: ErrorResponse = {
            code: 'INTERNAL_SERVER_ERROR',
            message: 'Failed to fetch Pokemon list',
        };
        response.status(500).json(errorResponse);
    }
});

/**
 * GET /pokemon/:name - Get Pokemon by name
 */
router.get('/:name', async (request: Request, response: Response) => {
    try {
        const { name } = request.params;

        if (!name || name.trim() === '') {
            const error: ErrorResponse = {
                code: 'BAD_REQUEST',
                message: 'Pokemon name is required',
            };
            response.status(400).json(error);
            return;
        }

        const pokemon = await getPokemonByName(name);
        response.status(200).json(pokemon);
    } catch (error) {
        const errorResponse: ErrorResponse = {
            code: 'NOT_FOUND',
            message: `Pokemon '${request.params.name}' not found`,
        };
        response.status(404).json(errorResponse);
    }
});

export default router;
