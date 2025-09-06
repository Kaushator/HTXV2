# Frontend

Next.js React application with TypeScript and shadcn/ui components.

## Features

- **Next.js 14**: Latest version with App Router
- **TypeScript**: Type-safe development
- **shadcn/ui**: Modern UI components
- **Tailwind CSS**: Utility-first CSS framework
- **React Query**: Data fetching and caching
- **Zustand**: State management
- **React Hook Form**: Form handling
- **WebSocket**: Real-time data streaming
- **PWA**: Progressive Web App capabilities

## Setup

1. Install dependencies:
   ```bash
   cd frontend
   npm install
   ```

2. Set up environment variables:
   ```bash
   cp .env.example .env.local
   # Edit .env.local with your configuration
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

4. Open [http://localhost:3000](http://localhost:3000) in your browser

## Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint
- `npm run type-check` - Run TypeScript compiler

## Project Structure

```
frontend/
├── app/                     # Next.js App Router
│   ├── (auth)/             # Authentication pages
│   ├── dashboard/          # Dashboard pages
│   ├── portfolio/          # Portfolio management
│   ├── trading/           # Trading interface
│   ├── globals.css        # Global styles
│   ├── layout.tsx         # Root layout
│   └── page.tsx          # Home page
├── components/             # Reusable components
│   ├── ui/                # shadcn/ui components
│   ├── charts/            # Chart components
│   ├── forms/             # Form components
│   └── layout/            # Layout components
├── lib/                   # Utility libraries
│   ├── api.ts            # API client
│   ├── auth.ts           # Authentication
│   ├── utils.ts          # Utility functions
│   └── validations.ts    # Form validations
├── hooks/                 # Custom React hooks
├── store/                 # Zustand stores
├── types/                 # TypeScript type definitions
├── public/               # Static assets
└── styles/               # Additional styles
```

## Technologies

- **Framework**: Next.js 14
- **Language**: TypeScript
- **Styling**: Tailwind CSS + shadcn/ui
- **State Management**: Zustand
- **Data Fetching**: React Query (TanStack Query)
- **Forms**: React Hook Form + Zod validation
- **Charts**: Recharts
- **WebSocket**: Native WebSocket API
- **PWA**: next-pwa