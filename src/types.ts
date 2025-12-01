// Type definitions for the Pokedex API

export interface PokemonType {
    name: string; // Type name in uppercase (e.g., "FIRE", "WATER")
    color: string; // Hex color code for the type
}

export interface PokemonMove {
    name: string;
    power?: number; // Optional, undefined if power is 0 or null
    type: PokemonType;
}

export interface Pokemon {
    id: number;
    name: string;
    description: string;
    types: PokemonType[];
    moves: PokemonMove[];
    sprites: {
        front_default: string;
        back_default: string;
        front_shiny: string;
        back_shiny: string;
    };
    stats: {
        hp: number;
        speed: number;
        attack: number;
        defense: number;
        specialAttack: number;
        specialDefense: number;
    };
}

export interface BoxEntry {
    id: string; // CUID2-generated unique identifier
    createdAt: string; // ISO 8601 date string
    level: number;
    location: string;
    notes?: string; // Optional notes about the entry
    pokemonId: number; // Pokemon ID from the Pokemon API
}

export interface InsertBoxEntry {
    createdAt: string; // ISO 8601 date string
    level: number;
    location: string;
    notes?: string; // Optional
    pokemonId: number;
}

export interface UpdateBoxEntry {
    createdAt?: string;
    level?: number;
    location?: string;
    notes?: string;
    pokemonId?: number;
}

export interface ErrorResponse {
    code: string; // Error code (e.g., "UNAUTHORIZED")
    message: string; // Human-readable error message
}

// Extended Express Request type with user information
export interface AuthenticatedRequest extends Express.Request {
    user?: {
        pennkey: string;
    };
}
