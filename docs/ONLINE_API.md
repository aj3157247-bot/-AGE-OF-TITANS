# Starter API

- `GET /health`
- `POST /api/register` body `{ "name": "Player" }`
- `GET /api/player/:id`
- `POST /api/search` body `{ "playerId": "..." }`
- `POST /api/raid/result` body `{ "playerId": "...", "stars": 0..3, "loot": number }`
- WebSocket: `/ws`

For production, never trust client-supplied stars/loot. Battle outcomes must be authoritative on the server.
