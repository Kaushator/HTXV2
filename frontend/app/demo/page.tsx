import { TickerDisplay } from '@/components/ticker-display'
import { FileUpload } from '@/components/file-upload'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

export default function DemoPage() {
  const handleUploadComplete = (result: any) => {
    console.log('Upload completed:', result);
    // Here you could add the uploaded data to a state or send it to an API
  };

  const handleUploadError = (error: string) => {
    console.error('Upload error:', error);
  };

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="container mx-auto px-4">
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">HTXV2 Demo</h1>
          <p className="text-gray-600">
            Experience real-time cryptocurrency data and file upload capabilities
          </p>
        </div>

        <div className="space-y-8">
          {/* Real-time Ticker Section */}
          <section>
            <Card>
              <CardHeader>
                <CardTitle>Real-time Cryptocurrency Tickers</CardTitle>
              </CardHeader>
              <CardContent>
                <TickerDisplay 
                  symbols={['BTC', 'ETH']}
                  wsUrl={process.env.NODE_ENV === 'development' ? 'ws://localhost:8000/api/v1/ws/ticker' : `wss://${process.env.NEXT_PUBLIC_API_URL?.replace('https://', '')}/api/v1/ws/ticker`}
                />
              </CardContent>
            </Card>
          </section>

          {/* File Upload Section */}
          <section>
            <Card>
              <CardHeader>
                <CardTitle>File Upload & Validation</CardTitle>
              </CardHeader>
              <CardContent>
                <FileUpload 
                  onUploadComplete={handleUploadComplete}
                  onError={handleUploadError}
                />
              </CardContent>
            </Card>
          </section>

          {/* API Status Section */}
          <section>
            <Card>
              <CardHeader>
                <CardTitle>API Information</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <h4 className="font-semibold mb-2">WebSocket Endpoints</h4>
                    <ul className="text-sm space-y-1">
                      <li><code>/api/v1/ws/ticker</code> - Real-time ticker data</li>
                      <li><code>/api/v1/ws/ticker?symbol=btc</code> - BTC only</li>
                      <li><code>/api/v1/ws/ticker?symbol=eth</code> - ETH only</li>
                    </ul>
                  </div>
                  <div>
                    <h4 className="font-semibold mb-2">File Upload Endpoints</h4>
                    <ul className="text-sm space-y-1">
                      <li><code>POST /api/v1/files/upload</code> - Upload file</li>
                      <li><code>POST /api/v1/files/validate</code> - Validate file</li>
                      <li><code>GET /api/v1/files/download/:id</code> - Download file</li>
                    </ul>
                  </div>
                </div>
                
                <div className="mt-4 p-4 bg-blue-50 rounded-lg">
                  <h4 className="font-semibold text-blue-800 mb-2">Features Demonstrated</h4>
                  <ul className="text-sm text-blue-700 space-y-1">
                    <li>✓ Real-time WebSocket connections with auto-reconnect</li>
                    <li>✓ CoinGecko API integration with quota management</li>
                    <li>✓ File upload validation (CSV/Excel)</li>
                    <li>✓ GCS signed URLs for secure file access</li>
                    <li>✓ Structured logging and error handling</li>
                    <li>✓ API key management and rate limiting</li>
                  </ul>
                </div>
              </CardContent>
            </Card>
          </section>
        </div>
      </div>
    </div>
  );
}