import { Router, Request, Response } from 'express';
import { authenticateToken } from './auth';
import {
    createBoxEntry,
    getBoxEntry,
    listBoxEntries,
    updateBoxEntry,
    deleteBoxEntry,
    clearAllBoxEntries,
} from './boxService';
import { InsertBoxEntrySchema, UpdateBoxEntrySchema } from './validation';
import { ErrorResponse } from './types';

const router = Router();

// Apply authentication middleware to all Box routes
router.use(authenticateToken);

/**
 * GET /box/ - List all Box entry IDs for authenticated user
 */
router.get('/', async (request: Request, response: Response) => {
    try {
        const pennkey = request.user!.pennkey;
        const ids = await listBoxEntries(pennkey);
        response.status(200).json(ids);
    } catch (_error) {
        const errorResponse: ErrorResponse = {
            code: 'INTERNAL_SERVER_ERROR',
            message: 'Failed to list Box entries',
        };
        response.status(500).json(errorResponse);
    }
});

/**
 * POST /box/ - Create a new Box entry
 */
router.post('/', async (request: Request, response: Response) => {
    try {
        // Validate request body
        const result = InsertBoxEntrySchema.safeParse(request.body);

        if (!result.success) {
            const error: ErrorResponse = {
                code: 'BAD_REQUEST',
                message: `Invalid request body: ${result.error.issues.map((e: any) => e.message).join(', ')}`,
            };
            response.status(400).json(error);
            return;
        }

        const pennkey = request.user!.pennkey;
        const boxEntry = await createBoxEntry(pennkey, result.data);

        response.status(201).json(boxEntry);
    } catch (_error) {
        const errorResponse: ErrorResponse = {
            code: 'INTERNAL_SERVER_ERROR',
            message: 'Failed to create Box entry',
        };
        response.status(500).json(errorResponse);
    }
});

/**
 * GET /box/:id - Get a specific Box entry
 */
router.get('/:id', async (request: Request, response: Response) => {
    try {
        const { id } = request.params;
        const pennkey = request.user!.pennkey;

        const boxEntry = await getBoxEntry(pennkey, id);

        if (!boxEntry) {
            const error: ErrorResponse = {
                code: 'NOT_FOUND',
                message: `Box entry '${id}' not found`,
            };
            response.status(404).json(error);
            return;
        }

        response.status(200).json(boxEntry);
    } catch (_error) {
        const errorResponse: ErrorResponse = {
            code: 'INTERNAL_SERVER_ERROR',
            message: 'Failed to get Box entry',
        };
        response.status(500).json(errorResponse);
    }
});

/**
 * PUT /box/:id - Update a Box entry
 */
router.put('/:id', async (request: Request, response: Response) => {
    try {
        const { id } = request.params;
        const pennkey = request.user!.pennkey;

        // Validate request body
        const result = UpdateBoxEntrySchema.safeParse(request.body);

        if (!result.success) {
            const error: ErrorResponse = {
                code: 'BAD_REQUEST',
                message: `Invalid request body: ${result.error.issues.map((e: any) => e.message).join(', ')}`,
            };
            response.status(400).json(error);
            return;
        }

        const updated = await updateBoxEntry(pennkey, id, result.data);

        if (!updated) {
            const error: ErrorResponse = {
                code: 'NOT_FOUND',
                message: `Box entry '${id}' not found`,
            };
            response.status(404).json(error);
            return;
        }

        response.status(200).json(updated);
    } catch (_error) {
        const errorResponse: ErrorResponse = {
            code: 'INTERNAL_SERVER_ERROR',
            message: 'Failed to update Box entry',
        };
        response.status(500).json(errorResponse);
    }
});

/**
 * DELETE /box/:id - Delete a specific Box entry
 */
router.delete('/:id', async (request: Request, response: Response) => {
    try {
        const { id } = request.params;
        const pennkey = request.user!.pennkey;

        const deleted = await deleteBoxEntry(pennkey, id);

        if (!deleted) {
            const error: ErrorResponse = {
                code: 'NOT_FOUND',
                message: `Box entry '${id}' not found`,
            };
            response.status(404).json(error);
            return;
        }

        response.status(204).send();
    } catch (_error) {
        const errorResponse: ErrorResponse = {
            code: 'INTERNAL_SERVER_ERROR',
            message: 'Failed to delete Box entry',
        };
        response.status(500).json(errorResponse);
    }
});

/**
 * DELETE /box/ - Clear all Box entries for authenticated user
 */
router.delete('/', async (request: Request, response: Response) => {
    try {
        const pennkey = request.user!.pennkey;
        await clearAllBoxEntries(pennkey);
        response.status(204).send();
    } catch (_error) {
        const errorResponse: ErrorResponse = {
            code: 'INTERNAL_SERVER_ERROR',
            message: 'Failed to clear Box entries',
        };
        response.status(500).json(errorResponse);
    }
});

export default router;
