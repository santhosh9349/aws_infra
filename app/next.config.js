/** @type {import('next').NextConfig} */
const nextConfig = {
  // Enable standalone output for optimized EC2 deployment
  // This creates a minimal production build with only necessary files
  output: 'standalone',
  
  // Strict mode for identifying potential problems
  reactStrictMode: true,
  
  // Optimize images
  images: {
    formats: ['image/avif', 'image/webp'],
  },
  
  // Security headers
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-DNS-Prefetch-Control',
            value: 'on'
          },
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=63072000; includeSubDomains; preload'
          },
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN'
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff'
          },
          {
            key: 'Content-Security-Policy',
            // NOTE: CSP allows 'unsafe-inline' and 'unsafe-eval' for backward compatibility
            // with Next.js inline scripts. For production, consider migrating to:
            // - Using nonces for inline scripts
            // - Removing 'unsafe-eval' if not strictly necessary
            // - Implementing stricter CSP policies gradually
            value: "default-src 'self'; img-src 'self' data: blob:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; font-src 'self' data:; connect-src 'self'; frame-ancestors 'self'; object-src 'none'; base-uri 'self'; form-action 'self'"
          },
          {
            key: 'Referrer-Policy',
            value: 'origin-when-cross-origin'
          }
        ]
      }
    ];
  }
};

module.exports = nextConfig;
