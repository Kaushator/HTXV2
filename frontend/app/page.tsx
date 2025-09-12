// @cursor: КОНТЕКСТ: HTXV2 - главная страница
// ТЕХНОЛОГИИ: Next.js App Router, TypeScript, shadcn/ui
// ЦЕЛЬ: Landing page с навигацией к основным функциям

import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-background to-muted">
      <div className="container mx-auto px-4 py-12 space-y-16">
        {/* Hero Section */}
        <section className="text-center space-y-6">
          <div className="space-y-4">
            <h1 className="text-6xl font-bold tracking-tight">
              HTX<span className="text-primary">V2</span>
            </h1>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              Персональный трейдинг-ассистент для HTX с быстрым импортом данных, 
              оперативными сводками P&L и анализом сигналов ИИ
            </p>
          </div>
          
          <div className="flex flex-wrap justify-center gap-2 mt-6">
            <Badge variant="secondary">Time-to-Insight ≤ 10 сек</Badge>
            <Badge variant="secondary">Real-time WebSocket</Badge>
            <Badge variant="secondary">AI-powered Analysis</Badge>
            <Badge variant="secondary">Multi-format Import</Badge>
          </div>

          <div className="flex flex-col sm:flex-row gap-4 justify-center mt-8">
            <Button asChild size="lg">
              <Link href="/trading">
                Start Trading Dashboard
              </Link>
            </Button>
            <Button asChild size="lg" variant="outline">
              <Link href="/demo">
                View Demo
              </Link>
            </Button>
          </div>
        </section>

        {/* Features Grid */}
        <section className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                📊 Trading Dashboard
              </CardTitle>
              <CardDescription>
                Real-time market data and portfolio management
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="text-sm text-muted-foreground">
                Live price updates via WebSocket, order book analysis, 
                P&L tracking, and intelligent trade recommendations.
              </p>
              <Button asChild className="w-full">
                <Link href="/trading">
                  Open Dashboard
                </Link>
              </Button>
            </CardContent>
          </Card>

          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                📁 File Upload
              </CardTitle>
              <CardDescription>
                Fast import from CSV/XLSX files
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="text-sm text-muted-foreground">
                Drag & drop your trading data files for instant analysis. 
                Supports CSV and Excel formats with automatic validation.
              </p>
              <Button asChild className="w-full" variant="outline">
                <Link href="/upload">
                  Upload Files
                </Link>
              </Button>
            </CardContent>
          </Card>

          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                🤖 AI Analysis
              </CardTitle>
              <CardDescription>
                FinGPT & multi-model intelligence
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="text-sm text-muted-foreground">
                Local FinGPT model, Vertex AI integration, and smart 
                signal analysis for better trading decisions.
              </p>
              <Button asChild className="w-full" variant="outline">
                <Link href="/demo">
                  See AI Features
                </Link>
              </Button>
            </CardContent>
          </Card>
        </section>

        {/* Architecture Overview */}
        <section className="space-y-8">
          <div className="text-center">
            <h2 className="text-3xl font-bold tracking-tight">Built for Performance</h2>
            <p className="text-muted-foreground mt-2">
              Async-first architecture designed for real-time data processing
            </p>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <Card className="text-center">
              <CardContent className="pt-6">
                <div className="text-2xl mb-2">⚡</div>
                <h3 className="font-semibold">FastAPI</h3>
                <p className="text-sm text-muted-foreground">Async backend</p>
              </CardContent>
            </Card>
            
            <Card className="text-center">
              <CardContent className="pt-6">
                <div className="text-2xl mb-2">⚛️</div>
                <h3 className="font-semibold">Next.js 14</h3>
                <p className="text-sm text-muted-foreground">Modern frontend</p>
              </CardContent>
            </Card>
            
            <Card className="text-center">
              <CardContent className="pt-6">
                <div className="text-2xl mb-2">🐘</div>
                <h3 className="font-semibold">PostgreSQL</h3>
                <p className="text-sm text-muted-foreground">+ pgvector</p>
              </CardContent>
            </Card>
            
            <Card className="text-center">
              <CardContent className="pt-6">
                <div className="text-2xl mb-2">☁️</div>
                <h3 className="font-semibold">GCP</h3>
                <p className="text-sm text-muted-foreground">Cloud AI</p>
              </CardContent>
            </Card>
          </div>
        </section>

        {/* Quick Start */}
        <section className="bg-muted rounded-lg p-8">
          <div className="text-center space-y-4">
            <h2 className="text-2xl font-bold">Ready to Get Started?</h2>
            <p className="text-muted-foreground">
              Choose your preferred way to explore HTXV2
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button asChild>
                <Link href="/demo">
                  Full Demo Experience
                </Link>
              </Button>
              <Button asChild variant="outline">
                <Link href="/trading">
                  Jump to Trading
                </Link>
              </Button>
              <Button asChild variant="outline">
                <Link href="/upload">
                  Import Your Data
                </Link>
              </Button>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}