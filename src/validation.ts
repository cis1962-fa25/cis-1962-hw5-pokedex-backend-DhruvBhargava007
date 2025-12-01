import { z } from 'zod';

// Validation schema for InsertBoxEntry
export const InsertBoxEntrySchema = z.object({
    createdAt: z.string().datetime(), // ISO 8601 date string
    level: z.number().int().min(1).max(100),
    location: z.string().min(1),
    notes: z.string().optional(),
    pokemonId: z.number().int().positive(),
});

// Validation schema for UpdateBoxEntry (all fields optional)
export const UpdateBoxEntrySchema = z.object({
    createdAt: z.string().datetime().optional(),
    level: z.number().int().min(1).max(100).optional(),
    location: z.string().min(1).optional(),
    notes: z.string().optional(),
    pokemonId: z.number().int().positive().optional(),
});

// Validation schema for BoxEntry
export const BoxEntrySchema = z.object({
    id: z.string(),
    createdAt: z.string().datetime(),
    level: z.number().int().min(1).max(100),
    location: z.string().min(1),
    notes: z.string().optional(),
    pokemonId: z.number().int().positive(),
});

// Validation schema for query parameters
export const PokemonListQuerySchema = z.object({
    limit: z.coerce.number().int().positive(),
    offset: z.coerce.number().int().nonnegative(),
});

// Validation schema for token request
export const TokenRequestSchema = z.object({
    pennkey: z.string().min(1),
});
