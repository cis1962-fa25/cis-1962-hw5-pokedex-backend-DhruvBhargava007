Homework 5 AI Synthesis Activity

Activity: You used AI

Part 1: Citation of AI Usage

I used ChatGPT to help me with the backend for this Pokedex project.
Link to the full conversation: https://chatgpt.com/share/692d8ce9-98c4-8002-88eb-60970ec9cc99

In that chat, I mainly asked about:
- How JWT auth works in Express (token creation, middleware, and verification)
- The difference between jwt.sign() and jwt.verify()
- How to put the pennkey into the token and read it in middleware
- How to structure Redis keys like {pennkey}:pokedex:* and when to use GET/SET vs KEYS/SCAN
- How to delete keys by pattern
- How to write reusable auth middleware and pass data like the user into route handlers
- How to use Zod (min/max, optional fields, and handling validation errors)
- How to run multiple async calls in parallel with Promise.all() and combine results

Part 2: Why I Used AI

I used AI because I understood the basic ideas (like “use JWTs for auth” and “Redis is a cache”), but I didn’t know the best way to put everything together in a real Express + TypeScript codebase.

Docs and random Stack Overflow posts gave me pieces, but not one clear, end‑to‑end explanation tailored to this assignment. ChatGPT was helpful because I could ask very specific follow‑up questions like “how do I get the pennkey out of the JWT and into req.user?” or “is it bad to use redis.keys() in production?” and get answers that directly matched the patterns I needed.

It also saved time on API details. For example, I didn’t remember all the options to jwt.sign() or the exact shape of a Zod error, and AI quickly reminded me so I could focus on writing the actual assignment code.

Part 3: Evaluation of an AI Response

The most useful answer for me was the one about extracting the pennkey from a verified JWT and making it available to route handlers.

ChatGPT explained a clean pattern:
- Include pennkey in the JWT payload when signing the token
- Write a middleware that reads the Authorization header, verifies the token, and attaches the decoded payload to req.user
- Optionally, type this properly in TypeScript so req.user.pennkey is recognized everywhere

This lined up well with what I implemented in src/auth.ts: I verify the token with jwt.verify(), pull out the pennkey, and set request.user = { pennkey }. I also added a global type declaration so Express.Request knows about user.pennkey.

I did not notice any obvious hallucinations here: the jsonwebtoken usage was correct, and the TypeScript pattern for extending Express types matched other resources I found. I did, however, adjust a few details to fit the starter code, like using JWT_TOKEN_SECRET (the env var name given in the project) and returning my own ErrorResponse shape instead of the AI’s simpler error objects.

Overall, I mostly trusted the response but still double‑checked key parts (like the verify call and error handling) against the official docs. I used the structure it suggested but rewrote pieces so they matched the rest of my code.

Part 4: New or Unfamiliar Concepts I Learned

TypeScript declaration merging:
I had to extend Express.Request so req.user.pennkey is typed. The declare global / namespace Express / interface Request pattern was new to me. I now understand that this is how you “merge” new fields into an existing library type without editing node_modules.

Redis key patterns and KEYS vs SCAN:
The idea of using a pattern like {pennkey}:pokedex:<id> helped me keep each user’s data separate and consistently named. I also learned that redis.keys() scans the whole keyspace and can block Redis, while scan() walks through keys in chunks. For this small homework project I still used keys(pattern), but I now know that in production I’d want scan() or a different data structure.

Zod safeParse:
I learned the difference between parse() and safeParse(). parse() throws an exception on invalid input, while safeParse() returns an object with success or error. In my routes I use safeParse() so I can send a clean 400 response with details about what went wrong instead of crashing the handler.

Non‑null assertion operator (!):
In TypeScript, I used request.user!.pennkey in routes that are behind the auth middleware. The ! tells the compiler “I know this is defined here.” I also understand the risk: if I ever forget to use the middleware, this could throw at runtime, so it’s something I would be more careful with in a larger codebase.

In summary, AI helped me connect a lot of pieces: JWT auth flow, Redis key design, Express middleware patterns, and Zod validation. I didn’t just copy code; I asked why certain patterns were recommended, checked them against the starter files, and then adapted them so they fit cleanly into this project.
