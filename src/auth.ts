import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { ErrorResponse } from './types';

// Extend Express Request type to include user
declare global {
    namespace Express {
        interface Request {
            user?: {
                pennkey: string;
            };
        }
    }
}

/**
 * Authentication middleware to verify JWT tokens
 */
export function authenticateToken(
    request: Request,
    response: Response,
    next: NextFunction,
): void {
    const authHeader = request.headers.authorization;

    // Check if Authorization header exists
    if (!authHeader) {
        const error: ErrorResponse = {
            code: 'UNAUTHORIZED',
            message: 'Missing authorization header',
        };
        response.status(401).json(error);
        return;
    }

    // Check if Authorization header has Bearer format
    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') {
        const error: ErrorResponse = {
            code: 'UNAUTHORIZED',
            message: 'Invalid authorization header format. Expected: Bearer <token>',
        };
        response.status(401).json(error);
        return;
    }

    const token = parts[1];

    // Verify token
    try {
        const jwtSecret = process.env.JWT_TOKEN_SECRET;
        if (!jwtSecret) {
            throw new Error('JWT_TOKEN_SECRET not configured');
        }

        const decoded = jwt.verify(token, jwtSecret) as { pennkey: string };

        // Add user information to request
        request.user = {
            pennkey: decoded.pennkey,
        };

        next();
    } catch (error) {
        const errorResponse: ErrorResponse = {
            code: 'UNAUTHORIZED',
            message: 'Invalid or expired token',
        };
        response.status(401).json(errorResponse);
    }
}
