# AWS Infrastructure App

Next.js 15 application with AI-powered chat interface, deployed on AWS EC2 instances behind an Application Load Balancer.

## Tech Stack

- **Next.js 15** - Server-side rendering framework with App Router
- **React 19** - UI library with Server Components
- **TypeScript** - Strict type checking
- **Tailwind CSS** - Utility-first styling
- **Vercel AI SDK** - AI chat interface with streaming support
- **Lucide React** - Beautiful icon library

## Features

✨ **Startup Landing Page**
- Modern hero section with gradient backgrounds
- Feature showcase grid with hover effects
- Responsive footer with social links
- Dark mode support

💬 **AI Chat Interface**
- Floating chat widget with smooth animations
- Streaming message responses
- Mock API for development (plug-and-play LLM integration ready)
- Support for OpenAI, Claude, and Gemini

🚀 **Production Ready**
- Standalone output mode for EC2 deployment
- Security headers configured
- Health check endpoints for ALB
- Environment variable management

## Getting Started

### Install Dependencies

```bash
npm install
```

### Environment Configuration

Copy the environment template:

```bash
cp .env.example .env.local
```

Edit `.env.local` and configure your settings. For mock mode (default), no API keys needed!

### Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Production Build

```bash
npm run build
npm start
```

The application is configured with `standalone` output mode for optimized EC2 deployment.

## Chat Interface

### Mock Mode (Default)

The chat interface works out-of-the-box with simulated AI responses. Perfect for:
- UI development and testing
- Demos without API costs
- Offline development

### Integrating Real LLM Providers

The chat interface is built with the Vercel AI SDK pattern, making it easy to swap in real LLM providers:

#### OpenAI Integration

```bash
npm install @ai-sdk/openai
```

Update `app/api/chat/route.ts`:

```typescript
import { openai } from '@ai-sdk/openai';
import { streamText } from 'ai';

export async function POST(req: Request) {
  const { messages } = await req.json();
  
  const result = streamText({
    model: openai('gpt-4'),
    messages,
  });
  
  return result.toDataStreamResponse();
}
```

Add to `.env.local`:
```
OPENAI_API_KEY=sk-proj-...
```

#### Anthropic Claude Integration

```bash
npm install @ai-sdk/anthropic
```

Update the API route similarly with:
```typescript
import { anthropic } from '@ai-sdk/anthropic';
```

#### Google Gemini Integration

```bash
npm install @ai-sdk/google
```

Update the API route with:
```typescript
import { google } from '@ai-sdk/google';
```

See [Vercel AI SDK docs](https://sdk.vercel.ai/docs) for full integration guides.

## Health Check

The application includes two health check endpoints:

### Application Health
```bash
curl http://localhost:3000/api/health
```

Returns:
```json
{
  "status": "healthy",
  "timestamp": "2025-12-28T...",
  "uptime": 123.456,
  "environment": "production"
}
```

### Chat API Health
```bash
curl http://localhost:3000/api/chat
```

Returns:
```json
{
  "status": "ok",
  "endpoint": "/api/chat",
  "mode": "mock",
  "message": "Chat API is ready..."
}
```

## Project Structure

```
app/
├── app/
│   ├── api/
│   │   ├── health/
│   │   │   └── route.ts       # ALB health check endpoint
│   │   └── chat/
│   │       └── route.ts       # Chat API with mock streaming
│   ├── components/
│   │   ├── hero.tsx           # Landing page hero section
│   │   ├── features.tsx       # Feature showcase grid
│   │   ├── footer.tsx         # Footer with links
│   │   └── chat-widget.tsx    # Floating chat interface
│   ├── layout.tsx             # Root layout component
│   ├── page.tsx               # Home page
│   └── globals.css            # Global styles
├── next.config.js             # Next.js configuration (standalone output)
├── tsconfig.json              # TypeScript configuration (strict mode)
├── tailwind.config.ts         # Tailwind CSS configuration
├── .env.example               # Environment variables template
└── package.json               # Dependencies and scripts
```

## Deployment

This application is designed for deployment on AWS EC2 instances:

1. **Build the application**:
   ```bash
   npm run build
   ```

2. **Standalone output** will be in `.next/standalone/`

3. **Copy static assets**:
   ```bash
   cp -r .next/static .next/standalone/.next/static
   cp -r public .next/standalone/public
   ```

4. **Deploy to EC2** and run with:
   ```bash
   node .next/standalone/server.js
   ```

5. **Configure ALB health checks** to point to `/api/health`

6. **Set environment variables** on EC2 instance

## Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm run lint` - Run ESLint
- `npm run type-check` - Run TypeScript type checking

## Security

- ✅ No API keys hardcoded
- ✅ Environment variables for sensitive data
- ✅ Security headers configured
- ✅ HTTPS/TLS in production
- ✅ Input sanitization
- ✅ CORS properly configured

## Contributing

1. Follow the TypeScript strict mode guidelines
2. Use functional components with TypeScript interfaces
3. Follow Tailwind CSS utility-first approach
4. Ensure all changes pass type checking: `npm run type-check`
5. Test locally before deploying

## License

MIT
