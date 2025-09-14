// @cursor: КОНТЕКСТ: HTXV2 - демо-страница всех компонентов
// ТЕХНОЛОГИИ: Next.js App Router, TypeScript, все созданные компоненты
// ЦЕЛЬ: Showcase всех функций платформы в одном месте

'use client';

import { ConfigurationDemo } from '@/components/config/ConfigurationDemo';
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
    <div className="container mx-auto p-6 space-y-6">
      <div className="space-y-4">
        {/* Header */}
        <div className="text-center space-y-4">
          <h1 className="text-4xl font-bold bg-gradient-to-r from-blue-600 to-violet-600 bg-clip-text text-transparent">
            HTXV2 Demo Platform
          </h1>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Comprehensive cryptocurrency trading assistant with real-time data analysis, AI-powered insights, 
            and seamless integration with HTX exchange.
          </p>
          <div className="flex justify-center gap-2">
            <Badge variant="secondary">FastAPI Backend</Badge>
            <Badge variant="secondary">Next.js Frontend</Badge>
            <Badge variant="secondary">Real-time WebSocket</Badge>
            <Badge variant="secondary">Enhanced Configuration</Badge>
          </div>
        </div>

        {/* Main Demo Content */}
        <Tabs defaultValue="overview" className="space-y-6">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="overview">Overview</TabsTrigger>
            <TabsTrigger value="trading">Trading Dashboard</TabsTrigger>
            <TabsTrigger value="upload">File Upload</TabsTrigger>
            <TabsTrigger value="config">Configuration</TabsTrigger>
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
                        Enhanced configuration management
                      </li>
                      <li className="flex items-center gap-2">
                        <Badge variant="outline" className="w-2 h-2 p-0"></Badge>
                        Performance monitoring and analytics
                      </li>
                      <li className="flex items-center gap-2">
                        <Badge variant="outline" className="w-2 h-2 p-0"></Badge>
                        Feature flags and environment settings
                      </li>
                    </ul>
                  </div>
                  <div className="space-y-3">
                    <h3 className="font-semibold">Technical Stack</h3>
                    <ul className="space-y-2 text-sm">
                      <li className="flex items-center gap-2">
                        <Badge variant="outline" className="w-2 h-2 p-0"></Badge>
                        Next.js 14 with App Router
                      </li>
                      <li className="flex items-center gap-2">
                        <Badge variant="outline" className="w-2 h-2 p-0"></Badge>
                        TypeScript with strict mode
                      </li>
                      <li className="flex items-center gap-2">
                        <Badge variant="outline" className="w-2 h-2 p-0"></Badge>
                        Enhanced API client with retries
                      </li>
                      <li className="flex items-center gap-2">
                        <Badge variant="outline" className="w-2 h-2 p-0"></Badge>
                        WebSocket with auto-reconnection
                      </li>
                      <li className="flex items-center gap-2">
                        <Badge variant="outline" className="w-2 h-2 p-0"></Badge>
                        Progressive Web App (PWA) support
                      </li>
                    </ul>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="trading" className="space-y-6">
            <TradingDashboard />
          </TabsContent>

          <TabsContent value="upload" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>File Upload Demo</CardTitle>
                <CardDescription>
                  Upload CSV or Excel files to process trading data
                </CardDescription>
              </CardHeader>
              <CardContent>
                <FileUploadZone />
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="config" className="space-y-6">
            <ConfigurationDemo />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}