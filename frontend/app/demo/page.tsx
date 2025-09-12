// @cursor: КОНТЕКСТ: HTXV2 - демо-страница всех компонентов
// ТЕХНОЛОГИИ: Next.js App Router, TypeScript, все созданные компоненты
// ЦЕЛЬ: Showcase всех функций платформы в одном месте

'use client';

import { TradingDashboard } from '@/components/trading/TradingDashboard';
import { FileUploadZone } from '@/components/upload/FileUploadZone';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';

export default function DemoPage() {
  const handleFileUpload = async (files: File[]) => {
    console.log('Demo: Files uploaded:', files);
  };

  const handleUploadProgress = (progress: any) => {
    console.log('Demo: Upload progress:', progress);
  };

  const handleUploadComplete = (file: any) => {
    console.log('Demo: Upload complete:', file);
  };

  const handleUploadError = (error: string) => {
    console.error('Demo: Upload error:', error);
  };

  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto p-6 space-y-6">
        {/* Header */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-4xl font-bold tracking-tight">HTXV2 Demo</h1>
              <p className="text-xl text-muted-foreground mt-2">
                Cryptocurrency Trading Assistant Platform
              </p>
            </div>
            <div className="flex gap-2">
              <Badge variant="secondary">FastAPI Backend</Badge>
              <Badge variant="secondary">Next.js Frontend</Badge>
              <Badge variant="secondary">Real-time WebSocket</Badge>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-center">
            <Card>
              <CardContent className="pt-6">
                <div className="text-2xl font-bold text-blue-600">≤ 10s</div>
                <p className="text-sm text-muted-foreground">Time-to-Insight</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6">
                <div className="text-2xl font-bold text-green-600">Real-time</div>
                <p className="text-sm text-muted-foreground">Market Updates</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6">
                <div className="text-2xl font-bold text-purple-600">AI-powered</div>
                <p className="text-sm text-muted-foreground">Trading Signals</p>
              </CardContent>
            </Card>
          </div>
        </div>

        {/* Main Demo Content */}
        <Tabs defaultValue="overview" className="space-y-6">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="overview">Overview</TabsTrigger>
            <TabsTrigger value="trading">Trading Dashboard</TabsTrigger>
            <TabsTrigger value="upload">File Upload</TabsTrigger>
            <TabsTrigger value="features">Features</TabsTrigger>
          </TabsList>

          <TabsContent value="overview" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Platform Overview</CardTitle>
                <CardDescription>
                  HTXV2 is a comprehensive cryptocurrency trading assistant designed for rapid data analysis and intelligent trading decisions.
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-3">
                    <h3 className="font-semibold">Key Features</h3>
                    <ul className="space-y-2 text-sm">
                      <li className="flex items-center gap-2">
                        <Badge variant="outline" className="w-2 h-2 p-0"></Badge>
                        Fast data import (API + CSV/XLSX)
                      </li>
                      <li className="flex items-center gap-2">
                        <Badge variant="outline" className="w-2 h-2 p-0"></Badge>
                        Real-time market data via WebSocket
                      </li>
                      <li className="flex items-center gap-2">
                        <Badge variant="outline" className="w-2 h-2 p-0"></Badge>
                        PnL and cashflow analytics
                      </li>
                      <li className="flex items-center gap-2">
                        <Badge variant="outline" className="w-2 h-2 p-0"></Badge>
                        AI-powered trading signals
                      </li>
                      <li className="flex items-center gap-2">
                        <Badge variant="outline" className="w-2 h-2 p-0"></Badge>
                        Multi-exchange integration
                      </li>
                    </ul>
                  </div>
                  
                  <div className="space-y-3">
                    <h3 className="font-semibold">Technology Stack</h3>
                    <div className="grid grid-cols-2 gap-2">
                      <Badge variant="secondary">FastAPI</Badge>
                      <Badge variant="secondary">Next.js 14</Badge>
                      <Badge variant="secondary">PostgreSQL</Badge>
                      <Badge variant="secondary">Redis</Badge>
                      <Badge variant="secondary">pgvector</Badge>
                      <Badge variant="secondary">TypeScript</Badge>
                      <Badge variant="secondary">shadcn/ui</Badge>
                      <Badge variant="secondary">Docker</Badge>
                    </div>
                  </div>
                </div>

                <div className="mt-6 p-4 bg-muted rounded-lg">
                  <h4 className="font-semibold mb-2">Architecture Highlights</h4>
                  <p className="text-sm text-muted-foreground">
                    Async-first design with FastAPI backend, MCP service orchestration, 
                    multi-model ML stack (FinGPT, Vertex AI, OpenAI), and real-time WebSocket updates. 
                    Built for high-performance data processing with rate limiting and intelligent caching.
                  </p>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="trading" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Live Trading Dashboard</CardTitle>
                <CardDescription>
                  Real-time market data, portfolio management, and trading interface
                </CardDescription>
              </CardHeader>
              <CardContent>
                <TradingDashboard />
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="upload" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>File Upload System</CardTitle>
                <CardDescription>
                  Drag & drop CSV/XLSX files for instant data import and analysis
                </CardDescription>
              </CardHeader>
              <CardContent>
                <FileUploadZone
                  onFileUpload={handleFileUpload}
                  onUploadProgress={handleUploadProgress}
                  onUploadComplete={handleUploadComplete}
                  onUploadError={handleUploadError}
                  maxFiles={5}
                  maxSizeBytes={25 * 1024 * 1024} // 25MB for demo
                  acceptedTypes={['.csv', '.xlsx', '.xls']}
                />
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="features" className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <Card>
                <CardHeader>
                  <CardTitle>Data Integration</CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="space-y-2">
                    <h4 className="font-medium">HTX API Integration</h4>
                    <p className="text-sm text-muted-foreground">
                      Direct connection to HTX exchange for real-time data
                    </p>
                  </div>
                  <div className="space-y-2">
                    <h4 className="font-medium">File Import</h4>
                    <p className="text-sm text-muted-foreground">
                      Support for CSV and Excel file formats
                    </p>
                  </div>
                  <div className="space-y-2">
                    <h4 className="font-medium">Data Validation</h4>
                    <p className="text-sm text-muted-foreground">
                      Automatic validation and error handling
                    </p>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>AI & Analytics</CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="space-y-2">
                    <h4 className="font-medium">FinGPT Integration</h4>
                    <p className="text-sm text-muted-foreground">
                      Local AI model for financial analysis
                    </p>
                  </div>
                  <div className="space-y-2">
                    <h4 className="font-medium">Vector Search</h4>
                    <p className="text-sm text-muted-foreground">
                      pgvector for semantic data analysis
                    </p>
                  </div>
                  <div className="space-y-2">
                    <h4 className="font-medium">Risk Assessment</h4>
                    <p className="text-sm text-muted-foreground">
                      AI-powered risk analysis and recommendations
                    </p>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Real-time Features</CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="space-y-2">
                    <h4 className="font-medium">WebSocket Updates</h4>
                    <p className="text-sm text-muted-foreground">
                      Live price feeds and market data
                    </p>
                  </div>
                  <div className="space-y-2">
                    <h4 className="font-medium">Portfolio Tracking</h4>
                    <p className="text-sm text-muted-foreground">
                      Real-time P&L and position updates
                    </p>
                  </div>
                  <div className="space-y-2">
                    <h4 className="font-medium">Alert System</h4>
                    <p className="text-sm text-muted-foreground">
                      Custom alerts and notifications
                    </p>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Infrastructure</CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="space-y-2">
                    <h4 className="font-medium">Docker Deployment</h4>
                    <p className="text-sm text-muted-foreground">
                      Containerized for easy development and deployment
                    </p>
                  </div>
                  <div className="space-y-2">
                    <h4 className="font-medium">GCP Integration</h4>
                    <p className="text-sm text-muted-foreground">
                      BigQuery, Pub/Sub, and Vertex AI
                    </p>
                  </div>
                  <div className="space-y-2">
                    <h4 className="font-medium">Security</h4>
                    <p className="text-sm text-muted-foreground">
                      Encrypted secrets and secure API access
                    </p>
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}