import Pokedex from 'pokedex-promise-v2';
import { Pokemon, PokemonType, PokemonMove } from './types';

const pokedex = new Pokedex();

// Type color mapping based on Pokemon types
const TYPE_COLORS: Record<string, string> = {
    normal: '#A8A878',
    fire: '#F08030',
    water: '#6890F0',
    electric: '#F8D030',
    grass: '#78C850',
    ice: '#98D8D8',
    fighting: '#C03028',
    poison: '#A040A0',
    ground: '#E0C068',
    flying: '#A890F0',
    psychic: '#F85888',
    bug: '#A8B820',
    rock: '#B8A038',
    ghost: '#705898',
    dragon: '#7038F8',
    dark: '#705848',
    steel: '#B8B8D0',
    fairy: '#EE99AC',
};

/**
 * Get a Pokemon by name with complete data synthesis
 */
export async function getPokemonByName(name: string): Promise<Pokemon> {
    try {
        // Fetch Pokemon basic data
        const pokemonData = await pokedex.getPokemonByName(name.toLowerCase());

        // Fetch species data for description
        const speciesData = await pokedex.getPokemonSpeciesByName(
            name.toLowerCase(),
        );

        // Extract description from flavor text entries (English)
        const englishFlavorText = speciesData.flavor_text_entries.find(
            (entry: any) => entry.language.name === 'en',
        );
        const description = englishFlavorText
            ? englishFlavorText.flavor_text.replace(/\f/g, ' ').replace(/\n/g, ' ')
            : 'No description available.';

        // Extract types with colors
        const types: PokemonType[] = pokemonData.types.map((typeInfo: any) => ({
            name: typeInfo.type.name.toUpperCase(),
            color: TYPE_COLORS[typeInfo.type.name] || '#777777',
        }));

        // Fetch move details in parallel (limit to first 4 moves for performance)
        const movePromises = pokemonData.moves
            .slice(0, 4)
            .map(async (moveInfo: any) => {
                try {
                    const moveData = await pokedex.getMoveByName(moveInfo.move.name);

                    // Extract English name
                    const englishName = moveData.names.find(
                        (n: any) => n.language.name === 'en',
                    );
                    const moveName = englishName ? englishName.name : moveInfo.move.name;

                    // Extract move type
                    const moveType: PokemonType = {
                        name: moveData.type.name.toUpperCase(),
                        color: TYPE_COLORS[moveData.type.name] || '#777777',
                    };

                    const move: PokemonMove = {
                        name: moveName,
                        power:
                            moveData.power && moveData.power > 0
                                ? moveData.power
                                : undefined,
                        type: moveType,
                    };

                    return move;
                } catch {
                    // If move fetch fails, return a basic move object
                    return {
                        name: moveInfo.move.name,
                        type: { name: 'NORMAL', color: TYPE_COLORS.normal },
                    };
                }
            });

        const moves = await Promise.all(movePromises);

        // Extract stats
        const statsMap = pokemonData.stats.reduce(
            (acc: any, stat: any) => {
                acc[stat.stat.name] = stat.base_stat;
                return acc;
            },
            {} as Record<string, number>,
        );

        const stats = {
            hp: statsMap.hp || 0,
            speed: statsMap.speed || 0,
            attack: statsMap.attack || 0,
            defense: statsMap.defense || 0,
            specialAttack: statsMap['special-attack'] || 0,
            specialDefense: statsMap['special-defense'] || 0,
        };

        // Construct the Pokemon object
        const pokemon: Pokemon = {
            id: pokemonData.id,
            name: pokemonData.name,
            description,
            types,
            moves,
            sprites: {
                front_default: pokemonData.sprites.front_default || '',
                back_default: pokemonData.sprites.back_default || '',
                front_shiny: pokemonData.sprites.front_shiny || '',
                back_shiny: pokemonData.sprites.back_shiny || '',
            },
            stats,
        };

        return pokemon;
    } catch (_error) {
        throw new Error(`Pokemon '${name}' not found`);
    }
}

/**
 * Get a paginated list of Pokemon
 */
export async function getPokemonList(
    limit: number,
    offset: number,
): Promise<Pokemon[]> {
    try {
        // Fetch the list of Pokemon names
        const pokemonList = await pokedex.getPokemonsList({ limit, offset });

        // Fetch full data for each Pokemon in parallel
        const pokemonPromises = pokemonList.results.map((pokemon: any) =>
            getPokemonByName(pokemon.name),
        );

        const pokemonData = await Promise.all(pokemonPromises);

        return pokemonData;
    } catch (_error) {
        throw new Error('Failed to fetch Pokemon list');
    }
}
