import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

/**
 * Enterprise Security Middleware for Leapmove
 * 
 * This middleware provides security guardrails for the chat API and other sensitive endpoints.
 * Currently configured for development. Enable authentication in production.
 * 
 * PRODUCTION SECURITY CHECKLIST:
 * [ ] Enable authentication (uncomment auth checks below)
 * [ ] Configure your identity provider (Auth0, Clerk, NextAuth, AWS Cognito)
 * [ ] Add rate limiting per user/IP
 * [ ] Implement CORS policies
 * [ ] Add request logging and monitoring
 * [ ] Set up API key rotation
 */

// FUTURE: Uncomment and configure your authentication provider
// import { auth } from '@/lib/auth'; // Your auth library
// import { verifyJWT } from '@/lib/jwt'; // JWT verification

export async function middleware(request: NextRequest): Promise<NextResponse> {
  const { pathname } = request.nextUrl;

  // ===========================================================================
  // AUTHENTICATION LAYER (Currently Disabled for Development)
  // ===========================================================================
  
  // Protect sensitive API routes in production
  if (pathname.startsWith('/api/chat')) {
    
    // PRODUCTION: Uncomment to enable authentication
    /*
    try {
      // Option 1: Session-based authentication
      const session = await auth(request);
      if (!session || !session.user) {
        return NextResponse.json(
          { error: 'Unauthorized. Please sign in to access chat.' },
          { status: 401 }
        );
      }

      // Option 2: JWT token authentication
      const token = request.headers.get('authorization')?.replace('Bearer ', '');
      if (!token) {
        return NextResponse.json(
          { error: 'Missing authentication token' },
          { status: 401 }
        );
      }

      const payload = await verifyJWT(token);
      if (!payload) {
        return NextResponse.json(
          { error: 'Invalid or expired token' },
          { status: 401 }
        );
      }

      // Option 3: API Key authentication (for service-to-service)
      const apiKey = request.headers.get('x-api-key');
      const validApiKey = process.env.LEAPMOVE_API_KEY;
      
      if (!apiKey || apiKey !== validApiKey) {
        return NextResponse.json(
          { error: 'Invalid API key' },
          { status: 401 }
        );
      }

      // Add user context to request headers for downstream use
      const requestHeaders = new Headers(request.headers);
      requestHeaders.set('x-user-id', session.user.id);
      requestHeaders.set('x-user-email', session.user.email);
      
      return NextResponse.next({
        request: {
          headers: requestHeaders,
        },
      });
      
    } catch (error) {
      console.error('Authentication error:', error);
      return NextResponse.json(
        { error: 'Authentication failed' },
        { status: 500 }
      );
    }
    */

    // DEVELOPMENT MODE: Allow all requests (REMOVE IN PRODUCTION)
    console.log(`[DEV MODE] Chat API accessed: ${pathname}`);
    return NextResponse.next();
  }

  // ===========================================================================
  // RATE LIMITING (Optional but Recommended)
  // ===========================================================================
  
  // PRODUCTION: Add rate limiting to prevent abuse
  /*
  import { Ratelimit } from '@upstash/ratelimit';
  import { Redis } from '@upstash/redis';

  const ratelimit = new Ratelimit({
    redis: Redis.fromEnv(),
    limiter: Ratelimit.slidingWindow(10, '1 m'), // 10 requests per minute
    analytics: true,
  });

  const ip = request.ip ?? request.headers.get('x-forwarded-for') ?? 'unknown';
  const { success, limit, reset, remaining } = await ratelimit.limit(ip);

  if (!success) {
    return NextResponse.json(
      { 
        error: 'Rate limit exceeded',
        limit,
        remaining,
        reset: new Date(reset),
      },
      { status: 429 }
    );
  }

  // Add rate limit headers
  const response = NextResponse.next();
  response.headers.set('X-RateLimit-Limit', limit.toString());
  response.headers.set('X-RateLimit-Remaining', remaining.toString());
  response.headers.set('X-RateLimit-Reset', reset.toString());
  return response;
  */

  // ===========================================================================
  // SECURITY HEADERS
  // ===========================================================================
  
  const response = NextResponse.next();
  
  // Add security headers to all responses
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('Referrer-Policy', 'origin-when-cross-origin');
  response.headers.set(
    'Permissions-Policy',
    'camera=(), microphone=(), geolocation=()'
  );

  return response;
}

// ===========================================================================
// MIDDLEWARE CONFIGURATION
// ===========================================================================

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
