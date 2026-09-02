# Architecture

Client: Godot 4.x / GDScript
Backend: Node.js 20 / HTTP JSON API
Persistence: JSON starter store (replace with PostgreSQL for production)

Core flow:
Client -> POST /api/search -> match -> POST /api/raid/result -> player progression

Production additions:
- PostgreSQL/Redis
- JWT/refresh-token authentication
- authoritative battle resolution on server
- rate limiting and replay validation
- HTTPS/WSS
- cloud object storage/CDN for assets
