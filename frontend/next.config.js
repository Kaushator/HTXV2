/** @type {import('next').NextConfig} */
const withPWA = require('next-pwa')({
  dest: 'public',
  register: true,
  skipWaiting: true,
  disable: process.env.NODE_ENV === 'development',
  runtimeCaching: [
    {
      urlPattern: /^https?.*/,
      handler: 'NetworkFirst',
      options: {
        cacheName: 'offlineCache',
        expiration: {
          maxEntries: 200,
          maxAgeSeconds: 24 * 60 * 60 // 24 hours
        }
      }
    }
  ]
})

const nextConfig = {
  output: 'standalone',
  images: {
    domains: ['localhost'],
  },
  env: {
    BACKEND_BASE: process.env.BACKEND_BASE || 'http://localhost:8000',
    FINGPT_BASE: process.env.FINGPT_BASE || 'http://localhost:8055',
  },
  async rewrites() {
    const base = process.env.BACKEND_BASE || 'http://localhost:8000'
    return [
      {
        source: '/api/:path*',
        destination: `${base}/api/:path*`,
      },
      {
        source: '/health',
        destination: `${base}/health`,
      },
      {
        source: '/healthz',
        destination: `${base}/healthz`,
      },
    ]
  },
}

module.exports = withPWA(nextConfig)
