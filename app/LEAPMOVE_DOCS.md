# Leapmove Website - Technical Documentation

## Overview

This is the official website for **Leapmove** - an AI acceleration company with the mission: *"Elevating business to move as fast as modern technology utilizing AI."*

The website showcases Leapmove's three core service offerings and includes an AI-powered chat interface for customer engagement.

## Tech Stack

### Frontend
- **Next.js 15** (App Router) - Server-side rendering framework
- **React 19** - UI library with latest features
- **TypeScript** (Strict Mode) - Type safety throughout
- **Tailwind CSS** - Utility-first styling with custom gradients
- **Vercel AI SDK** - Chat interface with streaming support

### Infrastructure
- **AWS EC2** - Application hosting
- **AWS ALB** - Application Load Balancer
- **Node.js Runtime** - Standalone output mode
- **Terraform** - Infrastructure as Code (in terraform/ directory)

### Design System
- **Color Palette**: Indigo-900 → Purple-900 → Blue-900 gradients
- **Typography**: Bold, futuristic aesthetic
- **Animations**: Pulsing elements, smooth transitions, backdrop blur effects
- **Iconography**: Lucide React icons

## Project Structure

```
app/
├── app/
│   ├── api/
│   │   ├── health/route.ts        # ALB health check
│   │   └── chat/route.ts          # AI chat API (mock with security)
│   ├── components/
│   │   ├── hero.tsx               # Hero section with Leapmove branding
│   │   ├── features.tsx           # Service blocks (3 offerings)
│   │   ├── footer.tsx             # Footer with company links
│   │   └── chat-widget.tsx        # Floating AI chat widget
│   ├── layout.tsx                 # Root layout with metadata
│   ├── page.tsx                   # Home page
│   └── globals.css                # Global styles
├── middleware.ts                  # Security middleware with auth guardrails
├── next.config.js                 # Standalone output for EC2
├── tsconfig.json                  # Strict TypeScript config
└── package.json                   # Dependencies
```

## Services Overview

### 1. AI Engineering Uplift
**Mission**: Train in-house teams on latest AI advancements

**Key Features**:
- Custom AI/ML workshops
- LLM integration training (OpenAI, Claude, Gemini)
- Prompt engineering masterclasses
- RAG systems and vector databases
- Hands-on labs
- Ongoing mentorship

**Target Audience**: Enterprise development teams, CTOs, tech leads

### 2. Scalable Enterprise & E-commerce
**Mission**: High-performance site delivery

**Key Features**:
- Next.js 15 and React 19 applications
- AWS infrastructure (EC2, ALB, CloudFront)
- Terraform IaC deployments
- Real-time AI-powered analytics
- Headless CMS and e-commerce
- Sub-50ms response times

**Target Audience**: E-commerce businesses, SaaS companies, enterprise clients

### 3. AI Agent Integration
**Mission**: First-line customer support chatbots

**Key Features**:
- Custom-trained AI agents
- Multi-channel deployment (web, Slack, WhatsApp)
- Seamless human handoff
- Real-time sentiment analysis
- Automated ticket routing
- Enterprise security and compliance

**Target Audience**: Customer support teams, SaaS platforms, enterprise help desks

## Chat Interface

### Current Implementation (Mock Mode)
The chat widget uses a **mock streaming API** that simulates AI responses. Perfect for:
- Development and testing
- Demos without API costs
- Offline functionality

### Mock Responses Cover:
- Greetings and general inquiries
- AI training and uplift programs
- Enterprise and e-commerce solutions
- AI agent integration services
- Pricing and consultation requests
- Infrastructure and deployment questions
- Company mission and values

### Production Integration Path

**Step 1: Choose LLM Provider**
- OpenAI (GPT-4, GPT-3.5)
- Anthropic (Claude)
- Google (Gemini)
- AWS Bedrock (multiple models)

**Step 2: Install SDK**
```bash
npm install @ai-sdk/openai  # or @ai-sdk/anthropic, @ai-sdk/google
```

**Step 3: Add Environment Variables**
```bash
# .env.local
OPENAI_API_KEY=sk-proj-...
```

**Step 4: Update Chat API Route**
See inline comments in `app/api/chat/route.ts` for full examples.

**Step 5: Implement RAG (Recommended)**
- Create vector database with Leapmove knowledge
- Integrate with Pinecone, Weaviate, or Supabase Vector
- Enhance responses with company-specific data

## Security Architecture

### Middleware Protection (`middleware.ts`)

**Current State**: Development mode (authentication disabled)

**Production Checklist**:
- [ ] Enable authentication (code included, commented out)
- [ ] Configure identity provider (Auth0, Clerk, NextAuth, AWS Cognito)
- [ ] Implement rate limiting (Upstash Redis example included)
- [ ] Add request logging and monitoring
- [ ] Set up API key rotation
- [ ] Configure CORS policies

### Authentication Options

**Option 1: Session-Based (NextAuth)**
```typescript
const session = await auth(request);
if (!session?.user) {
  return unauthorized();
}
```

**Option 2: JWT Tokens**
```typescript
const token = request.headers.get('authorization')?.replace('Bearer ', '');
const payload = await verifyJWT(token);
```

**Option 3: API Keys (Service-to-Service)**
```typescript
const apiKey = request.headers.get('x-api-key');
if (apiKey !== process.env.LEAPMOVE_API_KEY) {
  return unauthorized();
}
```

### Security Headers
Automatically applied to all responses:
- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: origin-when-cross-origin`
- `Permissions-Policy: camera=(), microphone=(), geolocation=()`

### Chat API Security
- User context passed via headers (`x-user-id`, `x-user-email`)
- Conversation logging for compliance
- Error tracking and monitoring
- Rate limiting per user

## Deployment

### Development
```bash
npm install
npm run dev
```

Visit `http://localhost:3000`

### Production Build
```bash
npm run build
```

Output: `.next/standalone/` (optimized for EC2)

### EC2 Deployment
1. Build application: `npm run build`
2. Copy standalone output to EC2
3. Copy static assets: `cp -r .next/static .next/standalone/.next/static`
4. Copy public folder: `cp -r public .next/standalone/public`
5. Set environment variables
6. Run: `node .next/standalone/server.js`
7. Configure ALB health checks: `/api/health`

### Environment Variables

**Required for Production**:
```bash
NODE_ENV=production
NEXT_PUBLIC_APP_URL=https://leapmove.com

# LLM Provider (choose one)
OPENAI_API_KEY=sk-proj-...
# ANTHROPIC_API_KEY=sk-ant-...
# GOOGLE_GENERATIVE_AI_API_KEY=AI...

# Authentication (configure based on provider)
NEXTAUTH_SECRET=...
NEXTAUTH_URL=https://leapmove.com

# Rate Limiting (if using Upstash)
UPSTASH_REDIS_REST_URL=...
UPSTASH_REDIS_REST_TOKEN=...

# Monitoring
SENTRY_DSN=...
```

## Branding Guidelines

### Mission Statement
"Elevating business to move as fast as modern technology utilizing AI."

### Core Values
- **AI-Driven Acceleration**: Speed and efficiency through AI
- **Leapfrogging Competition**: Help clients stay ahead
- **Modern Technology**: Cutting-edge stack and practices
- **Business Elevation**: Focus on ROI and business impact

### Visual Identity
- **Primary Colors**: Blue (#3B82F6) → Purple (#9333EA) gradients
- **Background**: Dark mode (Indigo-900, Gray-900)
- **Accents**: Pink (#EC4899), Light Blue (#60A5FA)
- **Typography**: Bold, large headings with gradient text
- **Effects**: Backdrop blur, pulsing animations, glowing borders

### Voice & Tone
- Confident and forward-thinking
- Technical yet accessible
- Focus on acceleration and transformation
- Use terms: "leapfrog", "elevate", "accelerate", "transform"

## Testing

### Type Checking
```bash
npm run type-check
```

### Linting
```bash
npm run lint
```

### Health Checks
```bash
# Application health
curl http://localhost:3000/api/health

# Chat API health
curl http://localhost:3000/api/chat
```

### Chat Testing
```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Tell me about AI training"}
    ]
  }'
```

## Performance Targets

- **First Contentful Paint**: < 1.5s
- **Time to Interactive**: < 3s
- **Lighthouse Score**: > 90
- **API Response Time**: < 50ms
- **Chat Stream Latency**: < 200ms

## Monitoring & Analytics

### Recommended Services
- **Error Tracking**: Sentry
- **Performance**: Vercel Analytics or Google Analytics
- **Logs**: AWS CloudWatch
- **Uptime**: UptimeRobot or Pingdom
- **Chat Analytics**: Custom dashboard (conversation tracking)

### Key Metrics to Track
- Page views and unique visitors
- Service block click-through rates
- Chat widget open/close rates
- Chat conversation completion rates
- API error rates
- Response times (ALB, API, Chat)

## Future Enhancements

### Phase 1 (Current)
- [x] Landing page with hero section
- [x] Three service blocks
- [x] Mock chat interface
- [x] Security middleware (dev mode)
- [x] Health check endpoints

### Phase 2 (Next)
- [ ] Real LLM integration (OpenAI/Claude)
- [ ] Enable authentication
- [ ] Rate limiting
- [ ] Contact form
- [ ] Case studies page
- [ ] Blog section

### Phase 3 (Future)
- [ ] RAG system with Leapmove knowledge base
- [ ] Conversation history per user
- [ ] Multi-language support
- [ ] CMS integration for content management
- [ ] A/B testing framework
- [ ] Advanced analytics dashboard

## Support & Maintenance

### Development Team
- Principal Full-Stack Engineer (architecture and implementation)
- DevOps Engineer (AWS infrastructure)
- UI/UX Designer (branding and design)

### Code Quality Standards
- Strict TypeScript mode (no implicit any)
- Functional components with interfaces
- Tailwind CSS only (no custom CSS)
- Comprehensive error handling
- Security-first mindset

### Deployment Frequency
- Development: Continuous deployment
- Staging: Daily builds
- Production: Weekly releases (or as needed)

## License

Proprietary - © 2025 Leapmove. All rights reserved.

---

**Built with ❤️ by Leapmove Engineering Team**
