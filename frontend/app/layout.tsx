import type { Metadata, Viewport } from 'next'
import Link from 'next/link'
import './globals.css'
import { QueryProvider } from '@/components/providers/query-provider'
import { ThemeProvider } from '@/components/providers/theme-provider'
import { Toaster } from '@/components/ui/toaster'

export const metadata: Metadata = {
  title: 'HTXV2 - Cryptocurrency Trading Platform',
  description: 'Advanced cryptocurrency trading platform with AI-powered insights',
  manifest: '/manifest.json',
}

export const viewport: Viewport = {
  themeColor: '#000000',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="font-sans antialiased">
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <QueryProvider>
            <div className="min-h-screen flex flex-col">
              <header className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
                <div className="container mx-auto px-4 py-3">
                  <nav className="flex items-center justify-between">
                    <div className="flex items-center space-x-6">
                      <Link href="/" className="text-xl font-bold">
                        HTXV2
                      </Link>
                      <div className="hidden md:flex space-x-4">
                        <Link 
                          href="/trading" 
                          className="text-sm font-medium hover:text-primary transition-colors"
                        >
                          Trading
                        </Link>
                        <Link 
                          href="/upload" 
                          className="text-sm font-medium hover:text-primary transition-colors"
                        >
                          Upload
                        </Link>
                        <Link 
                          href="/demo" 
                          className="text-sm font-medium hover:text-primary transition-colors"
                        >
                          Demo
                        </Link>
                      </div>
                    </div>
                    <div className="text-sm text-muted-foreground">
                      Crypto Trading Assistant
                    </div>
                  </nav>
                </div>
              </header>
              <main className="flex-1">
                {children}
              </main>
            </div>
            <Toaster />
          </QueryProvider>
        </ThemeProvider>
      </body>
    </html>
  )
}