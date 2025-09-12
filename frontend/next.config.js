/** @type {import('next').NextConfig} */
const withPWA = require('next-pwa')({
  dest: 'public',
  disable: process.env.NODE_ENV === 'development',
  register: true,
  skipWaiting: true,
})

const nextConfig = {
  output: 'standalone',
  
  // Image optimization
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'localhost',
      },
      {
        protocol: 'https',
        hostname: 'api.htxv2.com',
      },
      {
        protocol: 'https',
        hostname: 'images.coingecko.com',
      },
    ],
    formats: ['image/webp', 'image/avif'],
  },
  
  // Environment variables to expose to client
  env: {
    CUSTOM_KEY: process.env.CUSTOM_KEY,
    // API Configuration
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
    NEXT_PUBLIC_WS_URL: process.env.NEXT_PUBLIC_WS_URL,
    NEXT_PUBLIC_API_TIMEOUT: process.env.NEXT_PUBLIC_API_TIMEOUT,
    NEXT_PUBLIC_API_RETRIES: process.env.NEXT_PUBLIC_API_RETRIES,
    NEXT_PUBLIC_API_RETRY_DELAY: process.env.NEXT_PUBLIC_API_RETRY_DELAY,
    
    // Feature Flags
    NEXT_PUBLIC_ENABLE_ADVANCED_TRADING: process.env.NEXT_PUBLIC_ENABLE_ADVANCED_TRADING,
    NEXT_PUBLIC_ENABLE_AI_ANALYSIS: process.env.NEXT_PUBLIC_ENABLE_AI_ANALYSIS,
    NEXT_PUBLIC_ENABLE_CHAT: process.env.NEXT_PUBLIC_ENABLE_CHAT,
    NEXT_PUBLIC_ENABLE_PERFORMANCE_MONITORING: process.env.NEXT_PUBLIC_ENABLE_PERFORMANCE_MONITORING,
    NEXT_PUBLIC_ENABLE_ERROR_TRACKING: process.env.NEXT_PUBLIC_ENABLE_ERROR_TRACKING,
    
    // WebSocket Configuration
    NEXT_PUBLIC_WS_RECONNECT_INTERVAL: process.env.NEXT_PUBLIC_WS_RECONNECT_INTERVAL,
    NEXT_PUBLIC_WS_MAX_RECONNECT_ATTEMPTS: process.env.NEXT_PUBLIC_WS_MAX_RECONNECT_ATTEMPTS,
  },
  
  // Security headers
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
        ],
      },
    ]
  },
  
  // Experimental features - disabled for compatibility
  // experimental: {
  //   optimizeCss: true,
  // },
}

module.exports = withPWA(nextConfig)