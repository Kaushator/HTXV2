/** @type {import('next').NextConfig} */
const withPWA = require('next-pwa')({
  dest: 'public',
  disable: process.env.NODE_ENV === 'development',
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
