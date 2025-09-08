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
    return [
      {
        source: '/api/:path*',
        destination: 'http://localhost:8000/api/:path*',
      },
      {
        source: '/health',
        destination: 'http://localhost:8000/health',
      },
      {
        source: '/healthz',
        destination: 'http://localhost:8000/healthz',
      },
    ]
  },
}

module.exports = withPWA(nextConfig)
