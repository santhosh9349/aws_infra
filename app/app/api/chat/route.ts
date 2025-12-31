/**
 * AI Chat API - Mock Implementation
 * 
 * This endpoint simulates streaming responses from an AI assistant.
 * 
 * SECURITY NOTES:
 * - Authentication is handled in middleware.ts (currently disabled for dev)
 * - In production, ensure middleware enforces authentication before reaching this handler
 * - User context is available via request headers (x-user-id, x-user-email)
 * - Consider implementing conversation history per user
 * - Add audit logging for compliance requirements
 * 
 * PRODUCTION INTEGRATION:
 * 1. Install provider SDK (e.g., @ai-sdk/openai, @anthropic-ai/sdk)
 * 2. Add API key to environment variables (never hardcode)
 * 3. Replace mock stream with real provider streaming
 * 4. Implement RAG system for your knowledge base
 * 5. Add conversation memory and context management
 * 
 * Example with OpenAI (with authentication):
 * ```typescript
 * import { openai } from '@ai-sdk/openai';
 * import { streamText } from 'ai';
 * 
 * export async function POST(req: Request): Promise<Response> {
 *   // Get user context from middleware
 *   const userId = req.headers.get('x-user-id');
 *   const userEmail = req.headers.get('x-user-email');
 *   
 *   if (!userId) {
 *     return Response.json({ error: 'Unauthorized' }, { status: 401 });
 *   }
 *   
 *   const { messages } = await req.json();
 *   
 *   const result = streamText({
 *     model: openai('gpt-4'),
 *     system: `You are an AI assistant, an expert in AI training, enterprise solutions, and AI agent integration.
 *              User: ${userEmail}`,
 *     messages,
 *     temperature: 0.7,
 *     maxTokens: 2000,
 *   });
 *   
 *   // Log conversation for analytics and compliance
 *   await logConversation(userId, messages);
 *   
 *   return result.toDataStreamResponse();
 * }
 * ```
 */

interface Message {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

interface ChatRequest {
  messages: Message[];
}

/**
 * Simulate streaming text response
 */
async function* simulateStream(text: string): AsyncGenerator<string, void, unknown> {
  const words: string[] = text.split(' ');
  
  for (const word of words) {
    yield word + ' ';
    // Simulate network delay
    await new Promise<void>(resolve => setTimeout(resolve, 50));
  }
}

/**
 * Generate mock AI response based on user message
 * In production, this would be replaced with actual LLM calls
 * customized with your knowledge base via RAG
 */
function generateMockResponse(userMessage: string): string {
  const lowerMessage: string = userMessage.toLowerCase();
  
  if (lowerMessage.includes('hello') || lowerMessage.includes('hi')) {
    return "Hello! I'm an AI assistant, your partner in business acceleration. I can help you with AI training programs, enterprise solutions, or AI agent integration. What would you like to explore today?";
  }
  
  if (lowerMessage.includes('training') || lowerMessage.includes('uplift') || lowerMessage.includes('learn')) {
    return "Our AI Engineering Uplift program empowers your in-house teams with cutting-edge AI knowledge. We offer custom workshops on LLM integration, prompt engineering, RAG systems, and AI architecture. Our hands-on training covers OpenAI, Claude, and Gemini, with ongoing mentorship. Would you like to discuss a custom training program for your team?";
  }
  
  if (lowerMessage.includes('enterprise') || lowerMessage.includes('ecommerce') || lowerMessage.includes('scale')) {
    return "We specialize in building high-performance, AI-enhanced enterprise platforms. We use Next.js 15, React 19, and AWS infrastructure (EC2, ALB, CloudFront) with Terraform IaC. Our solutions deliver sub-50ms response times at scale with real-time AI-powered insights. Let's discuss how we can transform your digital presence!";
  }
  
  if (lowerMessage.includes('agent') || lowerMessage.includes('chatbot') || lowerMessage.includes('support')) {
    return "Our AI Agent Integration service provides intelligent 24/7 customer support. We create custom-trained AI agents on your business data, with multi-channel deployment (web, Slack, WhatsApp), seamless human handoff, and real-time sentiment analysis. All with enterprise security and compliance. Interested in seeing a demo?";
  }
  
  if (lowerMessage.includes('price') || lowerMessage.includes('cost') || lowerMessage.includes('pricing')) {
    return "We offer flexible engagement models tailored to your needs - from fixed-price projects to ongoing retainers. Our pricing depends on the scope, complexity, and timeline. I'd be happy to schedule a consultation to discuss your specific requirements and provide a custom quote. Shall I connect you with our team?";
  }
  
  if (lowerMessage.includes('aws') || lowerMessage.includes('infrastructure') || lowerMessage.includes('deploy')) {
    return "We deploy all solutions on enterprise-grade AWS infrastructure using Infrastructure as Code (Terraform). Our stack includes EC2 for compute, ALB for load balancing, CloudFront for CDN, and VPC for networking. Everything is version-controlled, reproducible, and optimized for high availability. Want to learn more about our deployment process?";
  }
  
  if (lowerMessage.includes('company') || lowerMessage.includes('mission')) {
    return "Our mission is to elevate businesses to move as fast as modern technology utilizing AI. We believe in leapfrogging the competition through AI-driven acceleration. Our team combines deep technical expertise with business acumen to deliver transformative solutions. We're not just consultants - we're your acceleration partners!";
  }
  
  // Default response
  return "I'm an AI assistant, here to help you accelerate your business with AI! I can discuss:\n\n• AI Engineering Uplift (team training)\n• Scalable Enterprise & E-commerce Solutions\n• AI Agent Integration (24/7 chatbots)\n• AWS Infrastructure & Deployment\n• Custom AI Solutions\n\nWhat would you like to know more about?";
}

export async function POST(req: Request): Promise<Response> {
  try {
    // SECURITY: In production, user authentication is enforced in middleware.ts
    // Access user context via headers if needed:
    // const userId = req.headers.get('x-user-id');
    // const userEmail = req.headers.get('x-user-email');
    
    const body: ChatRequest = await req.json();
    const { messages } = body;

    // Get the last user message
    const lastMessage: Message | undefined = messages[messages.length - 1];
    
    if (!lastMessage || lastMessage.role !== 'user') {
      throw new Error('Invalid message format');
    }

    // PRODUCTION: Log conversation for analytics and compliance
    // await logConversation(userId, lastMessage.content);

    // Generate mock response
    const responseText: string = generateMockResponse(lastMessage.content);

    // Create a ReadableStream for simulated streaming
    const stream = new ReadableStream({
      async start(controller) {
        const encoder = new TextEncoder();
        
        for await (const chunk of simulateStream(responseText)) {
          controller.enqueue(encoder.encode(chunk));
        }
        
        controller.close();
      },
    });

    // Return streaming response
    return new Response(stream, {
      headers: {
        'Content-Type': 'text/plain; charset=utf-8',
        'Transfer-Encoding': 'chunked',
      },
    });
    
  } catch (error: unknown) {
    console.error('Chat API error:', error);
    
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    
    // PRODUCTION: Log errors to monitoring service (Sentry, CloudWatch, etc.)
    
    return new Response(
      new ReadableStream({
        start(controller) {
          controller.enqueue(
            new TextEncoder().encode(`Error: ${errorMessage}`)
          );
          controller.close();
        },
      }),
      { 
        status: 500,
        headers: {
          'Content-Type': 'text/plain; charset=utf-8',
        },
      }
    );
  }
}

// Health check for this API route
export async function GET(): Promise<Response> {
  return Response.json(
    {
      status: 'ok',
      service: 'AI Chat',
      endpoint: '/api/chat',
      mode: 'mock',
      message: 'Chat API is ready. Integrate real LLM provider for production.',
      security: 'Authentication enforced in middleware (currently dev mode)',
    },
    { status: 200 }
  );
}
