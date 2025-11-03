# WebEdt Service App

The containerized service application for WebEdt - deployed to individual containers for each user session.

## Overview

WebEdt Service App is a lightweight containerized application that runs in isolated Docker environments managed by Dokploy. Each user session gets its own instance of this service, providing an independent development workspace.

## Features

- **Isolated Environment**: Each instance runs in its own container with dedicated workspace
- **Agent Integration**: Supports Codex SDK, Claude Code SDK, and Droid CLI
- **WebSocket Streaming**: Real-time communication with main app
- **Workspace Management**: File system access within `/workspace`
- **Main App Communication**: Bidirectional messaging via WebSocket and HTTP

## Project Structure

```
webedt-service-app/
├── src/
│   ├── backend/              # Express server
│   │   ├── routes/           # API routes
│   │   └── services/         # Business logic
│   │       ├── agentRunner.ts      # AI agent execution
│   │       └── mainAppClient.ts    # Main app communication
│   ├── frontend/             # React frontend
│   │   └── src/
│   │       ├── App.tsx       # Main app component
│   │       └── hooks/        # Custom React hooks
│   └── shared/               # Shared types
├── scripts/
│   └── container-init.sh     # Container initialization script
├── Dockerfile                # Container build configuration
└── package.json
```

## Getting Started

### Prerequisites

- Node.js >= 18.17.0
- Docker (for containerized deployment)

### Installation

```bash
npm install
```

### Development (Local)

To run locally (simulating container environment):

```bash
# Set required environment variables
export SESSION_ID=test-session
export SESSION_TOKEN=test-token
export MAIN_APP_URL=http://localhost:3000

npm run dev
```

### Production Build

```bash
npm run build
npm start
```

### Docker Build

```bash
docker build -t webedt-service-app .
```

## Environment Variables

These are automatically injected by the main app when deployed via Dokploy:

```bash
# Core Configuration (Required)
SESSION_ID=<unique-session-identifier>
SESSION_TOKEN=<jwt-token-for-authentication>
MAIN_APP_URL=<main-app-http-url>
MAIN_APP_WS_URL=<main-app-websocket-url>

# App Configuration
PORT=3001                      # Container port
NODE_ENV=production
WORKSPACE_PATH=/workspace      # Workspace directory

# Optional: Agent Configuration
CODEX_API_KEY=<api-key>
CODEX_BASE_URL=<base-url>
CODEX_PATH=<path-override>
DROID_PATH=<droid-cli-path>
```

## API Endpoints

### Agent Execution
- `POST /api/agent/run` - Run AI agent with user message
- `GET /api/agent/status` - Get agent execution status

### Workspace
- `GET /api/workspace/files` - List workspace files
- `GET /api/workspace/file` - Read file content
- `POST /api/workspace/file` - Write file content

### Health
- `GET /api/health` - Health check endpoint

## Communication with Main App

The service communicates with the main app through two channels:

### 1. HTTP Webhook
```typescript
// POST to main app's webhook endpoint
fetch(`${MAIN_APP_URL}/api/webhook/session/${SESSION_ID}/message`, {
  headers: { 'Authorization': `Bearer ${SESSION_TOKEN}` },
  body: JSON.stringify(message)
})
```

### 2. WebSocket Streaming
```typescript
// Connect to main app WebSocket for real-time streaming
const ws = new WebSocket(`${MAIN_APP_WS_URL}/ws?token=${SESSION_TOKEN}&sessionId=${SESSION_ID}`)
```

### 3. PostMessage (Frontend)
```typescript
// Browser postMessage for iframe communication
window.parent.postMessage({ type: 'containerReady' }, '*')
```

## Docker Configuration

The Dockerfile builds a production-ready container:

1. **Base Image**: `node:20-slim`
2. **System Dependencies**: git, curl
3. **Build**: Runs `npm run build` (Vite + TypeScript)
4. **Production Dependencies**: Removes dev dependencies
5. **Workspace**: Creates `/workspace` directory
6. **Startup**: Runs initialization script then starts server

### Container Startup

```bash
/editor/scripts/container-init.sh && node /editor/dist/server/index.js
```

## Deployment via Dokploy

When deployed through the main app:

1. **GitHub Repository**: Dokploy clones this repository
2. **Build**: Uses Nixpacks (auto-detection) or Dockerfile
3. **Environment**: Injects all required variables
4. **Domain**: Automatically configured with HTTPS at `/{sessionId}`
5. **Port**: Exposes port 3001
6. **Strip Path**: Enabled (sessionId path stripped before forwarding)

## Scripts

```bash
npm run dev           # Start development server
npm run build         # Build for production (client + server)
npm run typecheck     # Run TypeScript type checking
npm start             # Start production server
```

## Development Workflow

### Local Testing

1. Start main app: `cd ../webedt-main-app && npm run dev`
2. Start service app with env vars:
   ```bash
   SESSION_ID=test \
   SESSION_TOKEN=test \
   MAIN_APP_URL=http://localhost:3000 \
   npm run dev
   ```

### Container Testing

```bash
# Build image
docker build -t webedt-service-test .

# Run container
docker run -p 3001:3001 \
  -e SESSION_ID=test \
  -e SESSION_TOKEN=test \
  -e MAIN_APP_URL=http://host.docker.internal:3000 \
  -e MAIN_APP_WS_URL=ws://host.docker.internal:3000 \
  webedt-service-test
```

## Integration with Main App

The service app is designed to be deployed by `webedt-main-app`. The main app:

- Creates Dokploy application pointing to this repository
- Injects environment variables
- Configures HTTPS domain
- Manages lifecycle (start, stop, delete)

**Repository**: This repository should be pushed to GitHub and configured in the main app's Dokploy settings.

## Recent Changes

- **2025-11-03**: Migrated from monorepo to standalone repository
- **2025-11-03**: Inlined shared types for independent deployment
- **2025-11-02**: Added relative asset paths for Vite build

## License

Private
