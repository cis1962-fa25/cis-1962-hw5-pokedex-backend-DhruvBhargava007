import { Router, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { TokenRequestSchema } from './validation';
import { ErrorResponse } from './types';

const router = Router();

/**
 * POST /token - Generate JWT token for authentication
 */
router.post('/', (request: Request, response: Response) => {
    try {
        // Validate request body
        const result = TokenRequestSchema.safeParse(request.body);

        if (!result.success) {
            const error: ErrorResponse = {
                code: 'BAD_REQUEST',
                message: 'Missing or invalid pennkey in request body',
            };
            response.status(400).json(error);
            return;
        }

        const { pennkey } = result.data;

        // Get JWT secret from environment
        const jwtSecret = process.env.JWT_TOKEN_SECRET;
        if (!jwtSecret) {
            const error: ErrorResponse = {
                code: 'INTERNAL_SERVER_ERROR',
                message: 'JWT secret not configured',
            };
            response.status(500).json(error);
            return;
        }

        // Generate token with 24 hour expiration
        const token = jwt.sign({ pennkey }, jwtSecret, { expiresIn: '24h' });

        response.status(200).json({ token });
    } catch (error) {
        const errorResponse: ErrorResponse = {
            code: 'INTERNAL_SERVER_ERROR',
            message: 'Failed to generate token',
        };
        response.status(500).json(errorResponse);
    }
});

export default router;
