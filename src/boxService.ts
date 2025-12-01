import { createId } from '@paralleldrive/cuid2';
import { redisClient } from './redis';
import { BoxEntry, InsertBoxEntry, UpdateBoxEntry } from './types';

/**
 * Create a new Box entry for a user
 */
export async function createBoxEntry(
    pennkey: string,
    data: InsertBoxEntry,
): Promise<BoxEntry> {
    const id = createId();

    const boxEntry: BoxEntry = {
        id,
        ...data,
    };

    const key = `${pennkey}:pokedex:${id}`;
    await redisClient.set(key, JSON.stringify(boxEntry));

    return boxEntry;
}

/**
 * Get a Box entry by ID for a specific user
 */
export async function getBoxEntry(
    pennkey: string,
    id: string,
): Promise<BoxEntry | null> {
    const key = `${pennkey}:pokedex:${id}`;
    const data = await redisClient.get(key);

    if (!data) {
        return null;
    }

    return JSON.parse(data) as BoxEntry;
}

/**
 * List all Box entry IDs for a user
 */
export async function listBoxEntries(pennkey: string): Promise<string[]> {
    const pattern = `${pennkey}:pokedex:*`;
    const keys = await redisClient.keys(pattern);

    // Extract IDs from keys
    const ids = keys.map((key) => {
        const parts = key.split(':');
        return parts[parts.length - 1];
    });

    return ids;
}

/**
 * Update a Box entry
 */
export async function updateBoxEntry(
    pennkey: string,
    id: string,
    updates: UpdateBoxEntry,
): Promise<BoxEntry | null> {
    const existing = await getBoxEntry(pennkey, id);

    if (!existing) {
        return null;
    }

    const updated: BoxEntry = {
        ...existing,
        ...updates,
    };

    const key = `${pennkey}:pokedex:${id}`;
    await redisClient.set(key, JSON.stringify(updated));

    return updated;
}

/**
 * Delete a Box entry
 */
export async function deleteBoxEntry(
    pennkey: string,
    id: string,
): Promise<boolean> {
    const key = `${pennkey}:pokedex:${id}`;
    const result = await redisClient.del(key);

    return result > 0;
}

/**
 * Clear all Box entries for a user
 */
export async function clearAllBoxEntries(pennkey: string): Promise<void> {
    const pattern = `${pennkey}:pokedex:*`;
    const keys = await redisClient.keys(pattern);

    if (keys.length > 0) {
        await redisClient.del(keys);
    }
}
