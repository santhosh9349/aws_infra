# AI Chat Integration Guide

This guide explains how to integrate real LLM providers into the chat interface.

## Current Setup

The application currently uses a **mock chat API** that simulates streaming responses. This allows you to:
- Develop and test the UI without API costs
- Work offline
- Demo the application without real API keys

## Architecture

```
User Input (ChatWidget)
    ↓
useChat hook (Vercel AI SDK)
    ↓
POST /api/chat
    ↓
Mock Stream / Real LLM Provider
    ↓
Streaming Response
    ↓
ChatWidget (displays messages)
```

## Integration Options

### Option 1: OpenAI (GPT-4, GPT-3.5)

**1. Install SDK:**
```bash
npm install @ai-sdk/openai
```

**2. Add environment variable to `.env.local`:**
```bash
OPENAI_API_KEY=sk-proj-...
```

**3. Update `app/api/chat/route.ts`:**
```typescript
import { openai } from '@ai-sdk/openai';
import { streamText } from 'ai';

export async function POST(req: Request): Promise<Response> {
  const { messages } = await req.json();
  
  const result = streamText({
    model: openai('gpt-4'),
    messages,
    temperature: 0.7,
    maxTokens: 2000,
  });
  
  return result.toDataStreamResponse();
}
```

**Cost:** ~$0.03/1K tokens (GPT-4), ~$0.002/1K tokens (GPT-3.5)

---

### Option 2: Anthropic Claude

**1. Install SDK:**
```bash
npm install @ai-sdk/anthropic
```

**2. Add environment variable to `.env.local`:**
```bash
ANTHROPIC_API_KEY=sk-ant-...
```

**3. Update `app/api/chat/route.ts`:**
```typescript
import { anthropic } from '@ai-sdk/anthropic';
import { streamText } from 'ai';

export async function POST(req: Request): Promise<Response> {
  const { messages } = await req.json();
  
  const result = streamText({
    model: anthropic('claude-3-5-sonnet-20241022'),
    messages,
    temperature: 0.7,
    maxTokens: 2000,
  });
  
  return result.toDataStreamResponse();
}
```

**Cost:** ~$0.003/1K tokens (input), ~$0.015/1K tokens (output)

---

### Option 3: Google Gemini

**1. Install SDK:**
```bash
npm install @ai-sdk/google
```

**2. Add environment variable to `.env.local`:**
```bash
GOOGLE_GENERATIVE_AI_API_KEY=AI...
```

**3. Update `app/api/chat/route.ts`:**
```typescript
import { google } from '@ai-sdk/google';
import { streamText } from 'ai';

export async function POST(req: Request): Promise<Response> {
  const { messages } = await req.json();
  
  const result = streamText({
    model: google('gemini-1.5-pro'),
    messages,
    temperature: 0.7,
    maxTokens: 2000,
  });
  
  return result.toDataStreamResponse();
}
```

**Cost:** Free tier available, ~$0.00025/1K tokens (paid)

---

### Option 4: AWS Bedrock (Claude, Llama, etc.)

**1. Install SDK:**
```bash
npm install @ai-sdk/amazon-bedrock
```

**2. Add environment variables to `.env.local`:**
```bash
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
```

**3. Update `app/api/chat/route.ts`:**
```typescript
import { bedrock } from '@ai-sdk/amazon-bedrock';
import { streamText } from 'ai';

export async function POST(req: Request): Promise<Response> {
  const { messages } = await req.json();
  
  const result = streamText({
    model: bedrock('anthropic.claude-3-5-sonnet-20241022-v2:0'),
    messages,
    temperature: 0.7,
    maxTokens: 2000,
  });
  
  return result.toDataStreamResponse();
}
```

**Benefit:** Runs in your AWS account, good for compliance

---

## Advanced Features

### Adding System Prompts

```typescript
const result = streamText({
  model: openai('gpt-4'),
  system: 'You are a helpful AI assistant for AWS infrastructure questions.',
  messages,
  temperature: 0.7,
  maxTokens: 2000,
});
```

### Error Handling

```typescript
export async function POST(req: Request): Promise<Response> {
  try {
    const { messages } = await req.json();
    
    const result = streamText({
      model: openai('gpt-4'),
      messages,
    });
    
    return result.toDataStreamResponse();
    
  } catch (error) {
    console.error('Chat API error:', error);
    
    return Response.json(
      { error: 'Failed to generate response' },
      { status: 500 }
    );
  }
}
```

### Rate Limiting

```typescript
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '1 m'), // 10 requests per minute
});

export async function POST(req: Request): Promise<Response> {
  const ip = req.headers.get('x-forwarded-for') || 'unknown';
  const { success } = await ratelimit.limit(ip);
  
  if (!success) {
    return Response.json(
      { error: 'Rate limit exceeded' },
      { status: 429 }
    );
  }
  
  // ... rest of your code
}
```

### Authentication

```typescript
import { auth } from '@/lib/auth'; // Your auth library

export async function POST(req: Request): Promise<Response> {
  const session = await auth(req);
  
  if (!session) {
    return Response.json(
      { error: 'Unauthorized' },
      { status: 401 }
    );
  }
  
  // ... rest of your code
}
```

## Testing

### Test Mock API
```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello, how are you?"}
    ]
  }'
```

### Test Real LLM Integration
After integrating a provider, test the same way. You should see real AI responses.

## Monitoring

Consider adding monitoring for:
- API response times
- Error rates
- Token usage
- User satisfaction

Tools:
- Sentry for error tracking
- Vercel Analytics for performance
- Custom logging to CloudWatch

## Cost Management

1. **Set token limits** in your API calls (`maxTokens`)
2. **Implement rate limiting** to prevent abuse
3. **Cache responses** for common questions
4. **Monitor usage** with provider dashboards
5. **Use cheaper models** for simple queries (e.g., GPT-3.5 instead of GPT-4)

## Resources

- [Vercel AI SDK Docs](https://sdk.vercel.ai/docs)
- [OpenAI API Docs](https://platform.openai.com/docs)
- [Anthropic API Docs](https://docs.anthropic.com)
- [Google AI Docs](https://ai.google.dev/docs)
- [AWS Bedrock Docs](https://docs.aws.amazon.com/bedrock/)

## Troubleshooting

### "API key not found"
- Check `.env.local` file exists
- Verify environment variable names match exactly
- Restart development server after adding env vars

### "Model not found"
- Verify model name is correct
- Check your API key has access to the model
- Some models require special access (e.g., GPT-4)

### "Rate limit exceeded"
- Wait before retrying
- Implement exponential backoff
- Consider upgrading your API plan

### Slow responses
- Check your network connection
- Try a faster model (e.g., GPT-3.5-turbo)
- Reduce `maxTokens` parameter
- Add loading states in UI

## Production Checklist

- [ ] API keys stored in environment variables (not hardcoded)
- [ ] Rate limiting implemented
- [ ] Error handling in place
- [ ] Monitoring/logging configured
- [ ] Token limits set appropriately
- [ ] User authentication added (if needed)
- [ ] CORS configured properly
- [ ] Security headers in place
- [ ] Cost alerts set up
- [ ] Backup provider configured (optional)
