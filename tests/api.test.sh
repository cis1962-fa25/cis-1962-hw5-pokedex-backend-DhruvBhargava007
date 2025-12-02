#!/bin/bash

# =============================================================================
# Pokedex API Test Suite
# Based on info.md testing requirements
# =============================================================================

# Configuration
BASE_URL="${BASE_URL:-http://localhost:3000}"
TEST_PENNKEY="testuser123"
PASSED=0
FAILED=0
TOTAL=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
    ((TOTAL++))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    echo -e "${RED}       Response: $2${NC}"
    ((FAILED++))
}

log_section() {
    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}========================================${NC}"
}

# Check HTTP status code
check_status() {
    local response="$1"
    local expected="$2"
    local actual=$(echo "$response" | tail -1)
    
    if [ "$actual" == "$expected" ]; then
        return 0
    else
        return 1
    fi
}

# Get response body (all but last line which is status code)
get_body() {
    echo "$1" | sed '$d'
}

# Make HTTP request and capture both body and status
http_get() {
    curl -s -w "\n%{http_code}" "$@"
}

http_post() {
    curl -s -w "\n%{http_code}" -X POST "$@"
}

http_put() {
    curl -s -w "\n%{http_code}" -X PUT "$@"
}

http_delete() {
    curl -s -w "\n%{http_code}" -X DELETE "$@"
}

# =============================================================================
# Test: Health Check
# =============================================================================

test_health_check() {
    log_section "Health Check Tests"
    
    log_test "Health check endpoint should return 200"
    response=$(http_get "$BASE_URL/")
    if check_status "$response" "200"; then
        log_pass "Health check successful"
    else
        log_fail "Health check failed" "$(get_body "$response")"
    fi
}

# =============================================================================
# Test: Token Generation
# =============================================================================

test_token_generation() {
    log_section "Token Generation Tests"
    
    # Test: Generate token with valid pennkey
    log_test "POST /token with valid pennkey should return 200 and token"
    response=$(http_post "$BASE_URL/token" \
        -H "Content-Type: application/json" \
        -d "{\"pennkey\": \"$TEST_PENNKEY\"}")
    
    if check_status "$response" "200"; then
        body=$(get_body "$response")
        if echo "$body" | grep -q "token"; then
            log_pass "Token generated successfully"
            # Extract token for later use
            TOKEN=$(echo "$body" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
            export TOKEN
        else
            log_fail "Token not found in response" "$body"
        fi
    else
        log_fail "Token generation failed" "$(get_body "$response")"
    fi
    
    # Test: Missing pennkey in request body
    log_test "POST /token with missing pennkey should return 400"
    response=$(http_post "$BASE_URL/token" \
        -H "Content-Type: application/json" \
        -d "{}")
    
    if check_status "$response" "400"; then
        log_pass "Missing pennkey returns 400"
    else
        log_fail "Expected 400 for missing pennkey" "$(get_body "$response")"
    fi
    
    # Test: Empty pennkey
    log_test "POST /token with empty pennkey should return 400"
    response=$(http_post "$BASE_URL/token" \
        -H "Content-Type: application/json" \
        -d '{"pennkey": ""}')
    
    if check_status "$response" "400"; then
        log_pass "Empty pennkey returns 400"
    else
        log_fail "Expected 400 for empty pennkey" "$(get_body "$response")"
    fi
    
    # Test: Invalid JSON body
    log_test "POST /token with invalid JSON should return 400"
    response=$(http_post "$BASE_URL/token" \
        -H "Content-Type: application/json" \
        -d "not json")
    
    status=$(echo "$response" | tail -1)
    if [ "$status" == "400" ] || [ "$status" == "500" ]; then
        log_pass "Invalid JSON handled"
    else
        log_fail "Expected 400 or 500 for invalid JSON" "$(get_body "$response")"
    fi
}

# =============================================================================
# Test: Authentication Middleware
# =============================================================================

test_authentication() {
    log_section "Authentication Middleware Tests"
    
    # Test: Missing Authorization header
    log_test "Request without Authorization header should return 401"
    response=$(http_get "$BASE_URL/box/")
    
    if check_status "$response" "401"; then
        body=$(get_body "$response")
        if echo "$body" | grep -q "UNAUTHORIZED"; then
            log_pass "Missing auth header returns 401 UNAUTHORIZED"
        else
            log_fail "Missing UNAUTHORIZED code" "$body"
        fi
    else
        log_fail "Expected 401 for missing auth header" "$(get_body "$response")"
    fi
    
    # Test: Invalid token format (no Bearer prefix)
    log_test "Request with invalid token format (no Bearer) should return 401"
    response=$(http_get "$BASE_URL/box/" \
        -H "Authorization: invalidtoken")
    
    if check_status "$response" "401"; then
        log_pass "Invalid token format returns 401"
    else
        log_fail "Expected 401 for invalid format" "$(get_body "$response")"
    fi
    
    # Test: Invalid token format (missing token)
    log_test "Request with Bearer but no token should return 401"
    response=$(http_get "$BASE_URL/box/" \
        -H "Authorization: Bearer")
    
    if check_status "$response" "401"; then
        log_pass "Bearer without token returns 401"
    else
        log_fail "Expected 401 for missing token" "$(get_body "$response")"
    fi
    
    # Test: Invalid token signature
    log_test "Request with invalid token signature should return 401"
    response=$(http_get "$BASE_URL/box/" \
        -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwZW5ua2V5IjoidGVzdCIsImlhdCI6MTYwMDAwMDAwMH0.invalidsignature")
    
    if check_status "$response" "401"; then
        log_pass "Invalid signature returns 401"
    else
        log_fail "Expected 401 for invalid signature" "$(get_body "$response")"
    fi
    
    # Test: Valid token
    log_test "Request with valid token should succeed"
    response=$(http_get "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN")
    
    if check_status "$response" "200"; then
        log_pass "Valid token accepted"
    else
        log_fail "Expected 200 for valid token" "$(get_body "$response")"
    fi
}

# =============================================================================
# Test: Pokemon Endpoints
# =============================================================================

test_pokemon_endpoints() {
    log_section "Pokemon Endpoint Tests"
    
    # Test: List Pokemon with valid pagination
    log_test "GET /pokemon/?limit=2&offset=0 should return Pokemon list"
    response=$(http_get "$BASE_URL/pokemon/?limit=2&offset=0")
    
    if check_status "$response" "200"; then
        body=$(get_body "$response")
        if echo "$body" | grep -q "id"; then
            log_pass "Pokemon list returned successfully"
        else
            log_fail "Response missing expected data" "$body"
        fi
    else
        log_fail "Pokemon list request failed" "$(get_body "$response")"
    fi
    
    # Test: List Pokemon with missing limit
    log_test "GET /pokemon/?offset=0 (missing limit) should return 400"
    response=$(http_get "$BASE_URL/pokemon/?offset=0")
    
    if check_status "$response" "400"; then
        log_pass "Missing limit returns 400"
    else
        log_fail "Expected 400 for missing limit" "$(get_body "$response")"
    fi
    
    # Test: List Pokemon with missing offset
    log_test "GET /pokemon/?limit=10 (missing offset) should return 400"
    response=$(http_get "$BASE_URL/pokemon/?limit=10")
    
    if check_status "$response" "400"; then
        log_pass "Missing offset returns 400"
    else
        log_fail "Expected 400 for missing offset" "$(get_body "$response")"
    fi
    
    # Test: List Pokemon with negative limit
    log_test "GET /pokemon/?limit=-5&offset=0 should return 400"
    response=$(http_get "$BASE_URL/pokemon/?limit=-5&offset=0")
    
    if check_status "$response" "400"; then
        log_pass "Negative limit returns 400"
    else
        log_fail "Expected 400 for negative limit" "$(get_body "$response")"
    fi
    
    # Test: List Pokemon with negative offset
    log_test "GET /pokemon/?limit=5&offset=-1 should return 400"
    response=$(http_get "$BASE_URL/pokemon/?limit=5&offset=-1")
    
    if check_status "$response" "400"; then
        log_pass "Negative offset returns 400"
    else
        log_fail "Expected 400 for negative offset" "$(get_body "$response")"
    fi
    
    # Test: List Pokemon with non-numeric parameters
    log_test "GET /pokemon/?limit=abc&offset=0 should return 400"
    response=$(http_get "$BASE_URL/pokemon/?limit=abc&offset=0")
    
    if check_status "$response" "400"; then
        log_pass "Non-numeric limit returns 400"
    else
        log_fail "Expected 400 for non-numeric limit" "$(get_body "$response")"
    fi
    
    # Test: Get Pokemon by valid name
    log_test "GET /pokemon/pikachu should return Pokemon data"
    response=$(http_get "$BASE_URL/pokemon/pikachu")
    
    if check_status "$response" "200"; then
        body=$(get_body "$response")
        if echo "$body" | grep -q "pikachu" && echo "$body" | grep -q "ELECTRIC"; then
            log_pass "Pokemon pikachu returned correctly"
        else
            log_fail "Pokemon data incomplete" "$body"
        fi
    else
        log_fail "Failed to get pikachu" "$(get_body "$response")"
    fi
    
    # Test: Get Pokemon with different casing
    log_test "GET /pokemon/PIKACHU (uppercase) should work"
    response=$(http_get "$BASE_URL/pokemon/PIKACHU")
    
    if check_status "$response" "200"; then
        log_pass "Pokemon name case-insensitive"
    else
        log_fail "Expected case-insensitive name lookup" "$(get_body "$response")"
    fi
    
    # Test: Get Pokemon by invalid name
    log_test "GET /pokemon/notarealpokemon should return 404"
    response=$(http_get "$BASE_URL/pokemon/notarealpokemon")
    
    if check_status "$response" "404"; then
        body=$(get_body "$response")
        if echo "$body" | grep -q "NOT_FOUND"; then
            log_pass "Invalid Pokemon returns 404 NOT_FOUND"
        else
            log_fail "Missing NOT_FOUND code" "$body"
        fi
    else
        log_fail "Expected 404 for invalid Pokemon" "$(get_body "$response")"
    fi
}

# =============================================================================
# Test: Box Endpoints
# =============================================================================

test_box_endpoints() {
    log_section "Box Endpoint Tests"
    
    # First, clear all entries to start fresh
    log_test "DELETE /box/ - Clear all entries before tests"
    response=$(http_delete "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN")
    
    if check_status "$response" "204"; then
        log_pass "Box cleared successfully"
    else
        log_fail "Failed to clear box" "$(get_body "$response")"
    fi
    
    # Test: List empty box
    log_test "GET /box/ with empty box should return empty array"
    response=$(http_get "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN")
    
    if check_status "$response" "200"; then
        body=$(get_body "$response")
        if [ "$body" == "[]" ]; then
            log_pass "Empty box returns empty array"
        else
            log_fail "Expected empty array" "$body"
        fi
    else
        log_fail "Failed to list empty box" "$(get_body "$response")"
    fi
    
    # Test: Create Box entry with all required fields
    log_test "POST /box/ with valid data should return 201"
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "createdAt": "2024-01-15T10:30:00Z",
            "level": 25,
            "location": "Route 1",
            "pokemonId": 25
        }')
    
    if check_status "$response" "201"; then
        body=$(get_body "$response")
        if echo "$body" | grep -q '"id"' && echo "$body" | grep -q '"level":25'; then
            log_pass "Box entry created successfully"
            # Extract ID for later tests
            BOX_ENTRY_ID=$(echo "$body" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
            export BOX_ENTRY_ID
        else
            log_fail "Box entry response incomplete" "$body"
        fi
    else
        log_fail "Failed to create box entry" "$(get_body "$response")"
    fi
    
    # Test: Create Box entry with optional notes field
    log_test "POST /box/ with optional notes should work"
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "createdAt": "2024-01-16T12:00:00Z",
            "level": 50,
            "location": "Viridian Forest",
            "notes": "Caught during morning walk",
            "pokemonId": 1
        }')
    
    if check_status "$response" "201"; then
        body=$(get_body "$response")
        if echo "$body" | grep -q '"notes":"Caught during morning walk"'; then
            log_pass "Box entry with notes created"
            BOX_ENTRY_ID_2=$(echo "$body" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
            export BOX_ENTRY_ID_2
        else
            log_fail "Notes field not saved" "$body"
        fi
    else
        log_fail "Failed to create box entry with notes" "$(get_body "$response")"
    fi
    
    # Test: Create with boundary level (1)
    log_test "POST /box/ with level=1 (min boundary) should work"
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "createdAt": "2024-01-17T08:00:00Z",
            "level": 1,
            "location": "Starter Town",
            "pokemonId": 4
        }')
    
    if check_status "$response" "201"; then
        log_pass "Level 1 (minimum) accepted"
    else
        log_fail "Level 1 should be valid" "$(get_body "$response")"
    fi
    
    # Test: Create with boundary level (100)
    log_test "POST /box/ with level=100 (max boundary) should work"
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "createdAt": "2024-01-18T16:00:00Z",
            "level": 100,
            "location": "Elite Four",
            "pokemonId": 6
        }')
    
    if check_status "$response" "201"; then
        log_pass "Level 100 (maximum) accepted"
    else
        log_fail "Level 100 should be valid" "$(get_body "$response")"
    fi
    
    # Test: Create with invalid level (0)
    log_test "POST /box/ with level=0 should return 400"
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "createdAt": "2024-01-15T10:30:00Z",
            "level": 0,
            "location": "Route 1",
            "pokemonId": 25
        }')
    
    if check_status "$response" "400"; then
        log_pass "Level 0 returns 400"
    else
        log_fail "Expected 400 for level 0" "$(get_body "$response")"
    fi
    
    # Test: Create with invalid level (101)
    log_test "POST /box/ with level=101 should return 400"
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "createdAt": "2024-01-15T10:30:00Z",
            "level": 101,
            "location": "Route 1",
            "pokemonId": 25
        }')
    
    if check_status "$response" "400"; then
        log_pass "Level 101 returns 400"
    else
        log_fail "Expected 400 for level 101" "$(get_body "$response")"
    fi
    
    # Test: Create with missing required fields
    log_test "POST /box/ with missing level should return 400"
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "createdAt": "2024-01-15T10:30:00Z",
            "location": "Route 1",
            "pokemonId": 25
        }')
    
    if check_status "$response" "400"; then
        log_pass "Missing level returns 400"
    else
        log_fail "Expected 400 for missing level" "$(get_body "$response")"
    fi
    
    # Test: Create with missing createdAt
    log_test "POST /box/ with missing createdAt should return 400"
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "level": 25,
            "location": "Route 1",
            "pokemonId": 25
        }')
    
    if check_status "$response" "400"; then
        log_pass "Missing createdAt returns 400"
    else
        log_fail "Expected 400 for missing createdAt" "$(get_body "$response")"
    fi
    
    # Test: Create with invalid date format
    log_test "POST /box/ with invalid date format should return 400"
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "createdAt": "not-a-date",
            "level": 25,
            "location": "Route 1",
            "pokemonId": 25
        }')
    
    if check_status "$response" "400"; then
        log_pass "Invalid date format returns 400"
    else
        log_fail "Expected 400 for invalid date" "$(get_body "$response")"
    fi
    
    # Test: Create with empty location
    log_test "POST /box/ with empty location should return 400"
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "createdAt": "2024-01-15T10:30:00Z",
            "level": 25,
            "location": "",
            "pokemonId": 25
        }')
    
    if check_status "$response" "400"; then
        log_pass "Empty location returns 400"
    else
        log_fail "Expected 400 for empty location" "$(get_body "$response")"
    fi
    
    # Test: Create with invalid pokemonId (negative)
    log_test "POST /box/ with negative pokemonId should return 400"
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "createdAt": "2024-01-15T10:30:00Z",
            "level": 25,
            "location": "Route 1",
            "pokemonId": -1
        }')
    
    if check_status "$response" "400"; then
        log_pass "Negative pokemonId returns 400"
    else
        log_fail "Expected 400 for negative pokemonId" "$(get_body "$response")"
    fi
    
    # Test: Create with invalid type (string level)
    log_test "POST /box/ with string level should return 400"
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "createdAt": "2024-01-15T10:30:00Z",
            "level": "twenty-five",
            "location": "Route 1",
            "pokemonId": 25
        }')
    
    if check_status "$response" "400"; then
        log_pass "String level returns 400"
    else
        log_fail "Expected 400 for string level" "$(get_body "$response")"
    fi
    
    # Test: Get existing Box entry
    log_test "GET /box/:id for existing entry should return 200"
    response=$(http_get "$BASE_URL/box/$BOX_ENTRY_ID" \
        -H "Authorization: Bearer $TOKEN")
    
    if check_status "$response" "200"; then
        body=$(get_body "$response")
        if echo "$body" | grep -q "$BOX_ENTRY_ID"; then
            log_pass "Box entry retrieved successfully"
        else
            log_fail "Box entry data mismatch" "$body"
        fi
    else
        log_fail "Failed to get box entry" "$(get_body "$response")"
    fi
    
    # Test: Get non-existent Box entry
    log_test "GET /box/:id for non-existent entry should return 404"
    response=$(http_get "$BASE_URL/box/nonexistentid123" \
        -H "Authorization: Bearer $TOKEN")
    
    if check_status "$response" "404"; then
        body=$(get_body "$response")
        if echo "$body" | grep -q "NOT_FOUND"; then
            log_pass "Non-existent entry returns 404 NOT_FOUND"
        else
            log_fail "Missing NOT_FOUND code" "$body"
        fi
    else
        log_fail "Expected 404 for non-existent entry" "$(get_body "$response")"
    fi
    
    # Test: List Box entries
    log_test "GET /box/ should return array of entry IDs"
    response=$(http_get "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN")
    
    if check_status "$response" "200"; then
        body=$(get_body "$response")
        if echo "$body" | grep -q "$BOX_ENTRY_ID"; then
            log_pass "Box entries listed with created entry"
        else
            log_fail "Created entry not in list" "$body"
        fi
    else
        log_fail "Failed to list box entries" "$(get_body "$response")"
    fi
    
    # Test: Update Box entry with partial fields
    log_test "PUT /box/:id with partial update should return 200"
    response=$(http_put "$BASE_URL/box/$BOX_ENTRY_ID" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "level": 30,
            "notes": "Updated notes"
        }')
    
    if check_status "$response" "200"; then
        body=$(get_body "$response")
        if echo "$body" | grep -q '"level":30' && echo "$body" | grep -q '"notes":"Updated notes"'; then
            log_pass "Box entry updated successfully"
        else
            log_fail "Update values not applied" "$body"
        fi
    else
        log_fail "Failed to update box entry" "$(get_body "$response")"
    fi
    
    # Test: Update non-existent entry
    log_test "PUT /box/:id for non-existent entry should return 404"
    response=$(http_put "$BASE_URL/box/nonexistentid123" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"level": 30}')
    
    if check_status "$response" "404"; then
        log_pass "Update non-existent entry returns 404"
    else
        log_fail "Expected 404 for updating non-existent entry" "$(get_body "$response")"
    fi
    
    # Test: Update with invalid data
    log_test "PUT /box/:id with invalid level should return 400"
    response=$(http_put "$BASE_URL/box/$BOX_ENTRY_ID" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"level": 150}')
    
    if check_status "$response" "400"; then
        log_pass "Invalid update data returns 400"
    else
        log_fail "Expected 400 for invalid level in update" "$(get_body "$response")"
    fi
    
    # Test: Delete existing entry
    log_test "DELETE /box/:id for existing entry should return 204"
    response=$(http_delete "$BASE_URL/box/$BOX_ENTRY_ID_2" \
        -H "Authorization: Bearer $TOKEN")
    
    if check_status "$response" "204"; then
        log_pass "Box entry deleted successfully"
    else
        log_fail "Failed to delete box entry" "$(get_body "$response")"
    fi
    
    # Test: Verify deletion
    log_test "GET /box/:id after deletion should return 404"
    response=$(http_get "$BASE_URL/box/$BOX_ENTRY_ID_2" \
        -H "Authorization: Bearer $TOKEN")
    
    if check_status "$response" "404"; then
        log_pass "Deleted entry returns 404"
    else
        log_fail "Entry should not exist after deletion" "$(get_body "$response")"
    fi
    
    # Test: Delete non-existent entry
    log_test "DELETE /box/:id for non-existent entry should return 404"
    response=$(http_delete "$BASE_URL/box/nonexistentid123" \
        -H "Authorization: Bearer $TOKEN")
    
    if check_status "$response" "404"; then
        log_pass "Delete non-existent entry returns 404"
    else
        log_fail "Expected 404 for deleting non-existent entry" "$(get_body "$response")"
    fi
    
    # Test: Clear all entries
    log_test "DELETE /box/ should return 204"
    response=$(http_delete "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN")
    
    if check_status "$response" "204"; then
        log_pass "All entries cleared successfully"
    else
        log_fail "Failed to clear all entries" "$(get_body "$response")"
    fi
    
    # Test: Verify clear
    log_test "GET /box/ after clear should return empty array"
    response=$(http_get "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN")
    
    if check_status "$response" "200"; then
        body=$(get_body "$response")
        if [ "$body" == "[]" ]; then
            log_pass "Box is empty after clear"
        else
            log_fail "Box should be empty" "$body"
        fi
    else
        log_fail "Failed to list after clear" "$(get_body "$response")"
    fi
}

# =============================================================================
# Test: Edge Cases
# =============================================================================

test_edge_cases() {
    log_section "Edge Case Tests"
    
    # Test: Very long location string
    log_test "POST /box/ with very long location string should work"
    long_location=$(printf 'A%.0s' {1..500})
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"createdAt\": \"2024-01-15T10:30:00Z\",
            \"level\": 25,
            \"location\": \"$long_location\",
            \"pokemonId\": 25
        }")
    
    if check_status "$response" "201"; then
        log_pass "Long location string accepted"
    else
        log_fail "Long location string should be valid" "$(get_body "$response")"
    fi
    
    # Test: Very long notes string
    log_test "POST /box/ with very long notes string should work"
    long_notes=$(printf 'B%.0s' {1..1000})
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"createdAt\": \"2024-01-15T10:30:00Z\",
            \"level\": 50,
            \"location\": \"Test Location\",
            \"notes\": \"$long_notes\",
            \"pokemonId\": 1
        }")
    
    if check_status "$response" "201"; then
        log_pass "Long notes string accepted"
    else
        log_fail "Long notes string should be valid" "$(get_body "$response")"
    fi
    
    # Test: Special characters in location
    log_test "POST /box/ with special characters in location should work"
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "createdAt": "2024-01-15T10:30:00Z",
            "level": 25,
            "location": "Route #1 - Test & More! <special>",
            "pokemonId": 25
        }')
    
    if check_status "$response" "201"; then
        log_pass "Special characters accepted"
    else
        log_fail "Special characters should be valid" "$(get_body "$response")"
    fi
    
    # Test: Unicode characters
    log_test "POST /box/ with unicode characters should work"
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "createdAt": "2024-01-15T10:30:00Z",
            "level": 25,
            "location": "Route 1 🌟 日本",
            "pokemonId": 25
        }')
    
    if check_status "$response" "201"; then
        log_pass "Unicode characters accepted"
    else
        log_fail "Unicode characters should be valid" "$(get_body "$response")"
    fi
    
    # Clean up
    http_delete "$BASE_URL/box/" -H "Authorization: Bearer $TOKEN" > /dev/null 2>&1
}

# =============================================================================
# Test: User Data Isolation
# =============================================================================

test_user_isolation() {
    log_section "User Data Isolation Tests"
    
    # Create entry for first user
    response=$(http_post "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "createdAt": "2024-01-15T10:30:00Z",
            "level": 25,
            "location": "User 1 Location",
            "pokemonId": 25
        }')
    USER1_ENTRY_ID=$(echo "$(get_body "$response")" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    
    # Get token for second user
    response=$(http_post "$BASE_URL/token" \
        -H "Content-Type: application/json" \
        -d '{"pennkey": "otheruser456"}')
    TOKEN2=$(echo "$(get_body "$response")" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    
    # Test: Second user should not see first user's entries in list
    log_test "User 2 should not see User 1's entries in list"
    response=$(http_get "$BASE_URL/box/" \
        -H "Authorization: Bearer $TOKEN2")
    
    if check_status "$response" "200"; then
        body=$(get_body "$response")
        if ! echo "$body" | grep -q "$USER1_ENTRY_ID"; then
            log_pass "User isolation working for list"
        else
            log_fail "User 2 can see User 1's entries" "$body"
        fi
    else
        log_fail "Failed to list for User 2" "$(get_body "$response")"
    fi
    
    # Test: Second user should not be able to get first user's entry
    log_test "User 2 should not be able to get User 1's entry"
    response=$(http_get "$BASE_URL/box/$USER1_ENTRY_ID" \
        -H "Authorization: Bearer $TOKEN2")
    
    if check_status "$response" "404"; then
        log_pass "User isolation working for get"
    else
        log_fail "User 2 can access User 1's entry" "$(get_body "$response")"
    fi
    
    # Clean up
    http_delete "$BASE_URL/box/" -H "Authorization: Bearer $TOKEN" > /dev/null 2>&1
    http_delete "$BASE_URL/box/" -H "Authorization: Bearer $TOKEN2" > /dev/null 2>&1
}

# =============================================================================
# Run All Tests
# =============================================================================

run_all_tests() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           POKEDEX API TEST SUITE                             ║${NC}"
    echo -e "${BLUE}║           Based on info.md requirements                      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Base URL: $BASE_URL"
    echo ""
    
    # Run tests in order
    test_health_check
    test_token_generation
    test_authentication
    test_pokemon_endpoints
    test_box_endpoints
    test_edge_cases
    test_user_isolation
    
    # Summary
    log_section "TEST SUMMARY"
    echo ""
    echo -e "Total Tests: ${TOTAL}"
    echo -e "${GREEN}Passed: ${PASSED}${NC}"
    echo -e "${RED}Failed: ${FAILED}${NC}"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

# Run the test suite
run_all_tests

