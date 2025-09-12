// @cursor: КОНТЕКСТ: HTXV2 - страница загрузки файлов
// ТЕХНОЛОГИИ: Next.js App Router, TypeScript, FileUploadZone
// ЦЕЛЬ: Страница для демонстрации загрузки CSV/XLSX файлов

'use client';

import { FileUploadZone } from '@/components/upload/FileUploadZone';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';

export default function UploadPage() {
  const handleFileUpload = async (files: File[]) => {
    console.log('Files uploaded:', files);
    // TODO: Implement actual file upload to backend
  };

  const handleUploadProgress = (progress: any) => {
    console.log('Upload progress:', progress);
  };

  const handleUploadComplete = (file: any) => {
    console.log('Upload complete:', file);
  };

  const handleUploadError = (error: string) => {
    console.error('Upload error:', error);
    // TODO: Show error toast
  };

  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto p-6 space-y-6">
        {/* Header */}
        <div className="space-y-2">
          <h1 className="text-3xl font-bold tracking-tight">File Upload</h1>
          <p className="text-muted-foreground">
            Upload your trading data files for analysis and portfolio management
          </p>
        </div>

        {/* Main Upload Area */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2">
            <FileUploadZone
              onFileUpload={handleFileUpload}
              onUploadProgress={handleUploadProgress}
              onUploadComplete={handleUploadComplete}
              onUploadError={handleUploadError}
              maxFiles={10}
              maxSizeBytes={50 * 1024 * 1024} // 50MB
              acceptedTypes={['.csv', '.xlsx', '.xls']}
            />
          </div>

          {/* Info Panel */}
          <div className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Supported Files</CardTitle>
                <CardDescription>
                  We support the following file formats
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="space-y-2">
                  <h4 className="font-medium">CSV Files</h4>
                  <p className="text-sm text-muted-foreground">
                    Standard comma-separated values format. Ensure headers include: symbol, date, price, quantity.
                  </p>
                </div>
                
                <div className="space-y-2">
                  <h4 className="font-medium">Excel Files</h4>
                  <p className="text-sm text-muted-foreground">
                    Both .xlsx and .xls formats supported. Data should be in the first sheet.
                  </p>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-lg">File Requirements</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span>Max file size:</span>
                  <span className="font-medium">50MB</span>
                </div>
                <div className="flex justify-between">
                  <span>Max files:</span>
                  <span className="font-medium">10 per upload</span>
                </div>
                <div className="flex justify-between">
                  <span>Required columns:</span>
                  <span className="font-medium">symbol, date, price</span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Processing</CardTitle>
              </CardHeader>
              <CardContent className="text-sm text-muted-foreground">
                <p>
                  Files are processed automatically after upload. 
                  You'll see progress updates and can view the results 
                  in your portfolio dashboard once processing is complete.
                </p>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}