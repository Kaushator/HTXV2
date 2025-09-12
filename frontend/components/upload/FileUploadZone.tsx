// @cursor: КОНТЕКСТ: HTXV2 - криптотрейдинг платформа, загрузка CSV/XLSX
// ТЕХНОЛОГИИ: TypeScript, React, drag&drop, file validation, shadcn/ui
// ЦЕЛЬ: Drag&drop зона для загрузки файлов с прогрессом и валидацией
// ПАТТЕРН: Переиспользуемый компонент с обработкой ошибок

'use client';

import { useState, useCallback, useRef } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Upload, FileText, X, CheckCircle, AlertCircle, Loader } from 'lucide-react';

interface FileUploadProgress {
  file_id: string;
  filename: string;
  progress: number;
  status: 'uploading' | 'processing' | 'completed' | 'error';
  error_message?: string;
}

interface UploadedFile {
  id: string;
  filename: string;
  size: number;
  type: string;
  url: string;
  uploaded_at: string;
  processed_rows?: number;
}

interface FileUploadZoneProps {
  onFileUpload?: (files: File[]) => Promise<void>;
  onUploadProgress?: (progress: FileUploadProgress) => void;
  onUploadComplete?: (file: UploadedFile) => void;
  onUploadError?: (error: string) => void;
  maxFiles?: number;
  maxSizeBytes?: number;
  acceptedTypes?: string[];
  className?: string;
}

export function FileUploadZone({
  onFileUpload,
  onUploadProgress,
  onUploadComplete,
  onUploadError,
  maxFiles = 5,
  maxSizeBytes = 10 * 1024 * 1024, // 10MB default
  acceptedTypes = ['.csv', '.xlsx', '.xls'],
  className
}: FileUploadZoneProps) {
  const [isDragOver, setIsDragOver] = useState(false);
  const [uploadQueue, setUploadQueue] = useState<FileUploadProgress[]>([]);
  const [uploadedFiles, setUploadedFiles] = useState<UploadedFile[]>([]);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // File validation
  const validateFile = (file: File): string | null => {
    // Check file size
    if (file.size > maxSizeBytes) {
      return `File size exceeds ${(maxSizeBytes / 1024 / 1024).toFixed(1)}MB limit`;
    }

    // Check file type
    const fileExtension = '.' + file.name.split('.').pop()?.toLowerCase();
    if (!acceptedTypes.includes(fileExtension)) {
      return `File type ${fileExtension} not supported. Accepted: ${acceptedTypes.join(', ')}`;
    }

    return null;
  };

  // Handle file selection
  const handleFiles = useCallback(async (files: FileList) => {
    const fileArray = Array.from(files);
    
    // Validate total number of files
    if (uploadQueue.length + fileArray.length > maxFiles) {
      onUploadError?.(`Maximum ${maxFiles} files allowed`);
      return;
    }

    // Validate each file
    const validFiles: File[] = [];
    const errors: string[] = [];

    for (const file of fileArray) {
      const error = validateFile(file);
      if (error) {
        errors.push(`${file.name}: ${error}`);
      } else {
        validFiles.push(file);
      }
    }

    if (errors.length > 0) {
      onUploadError?.(errors.join('\n'));
    }

    if (validFiles.length === 0) return;

    // Create upload progress entries
    const newUploads: FileUploadProgress[] = validFiles.map(file => ({
      file_id: `${Date.now()}-${file.name}`,
      filename: file.name,
      progress: 0,
      status: 'uploading'
    }));

    setUploadQueue(prev => [...prev, ...newUploads]);

    // Simulate file upload (replace with actual API call)
    try {
      await simulateFileUpload(validFiles, newUploads);
      onFileUpload?.(validFiles);
    } catch (error) {
      onUploadError?.(error instanceof Error ? error.message : 'Upload failed');
    }
  }, [uploadQueue.length, maxFiles, maxSizeBytes, acceptedTypes, onFileUpload, onUploadError]);

  // Simulate file upload progress (replace with real API)
  const simulateFileUpload = async (files: File[], uploads: FileUploadProgress[]) => {
    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      const upload = uploads[i];

      try {
        // Simulate upload progress
        for (let progress = 0; progress <= 100; progress += 10) {
          await new Promise(resolve => setTimeout(resolve, 100));
          
          setUploadQueue(prev => 
            prev.map(item => 
              item.file_id === upload.file_id 
                ? { ...item, progress }
                : item
            )
          );
        }

        // Mark as processing
        setUploadQueue(prev => 
          prev.map(item => 
            item.file_id === upload.file_id 
              ? { ...item, status: 'processing' }
              : item
          )
        );

        // Simulate processing time
        await new Promise(resolve => setTimeout(resolve, 1000));

        // Mark as completed
        const completedFile: UploadedFile = {
          id: upload.file_id,
          filename: file.name,
          size: file.size,
          type: file.type,
          url: `https://example.com/files/${upload.file_id}`,
          uploaded_at: new Date().toISOString(),
          processed_rows: Math.floor(Math.random() * 1000) + 100 // Mock data
        };

        setUploadQueue(prev => 
          prev.map(item => 
            item.file_id === upload.file_id 
              ? { ...item, status: 'completed', progress: 100 }
              : item
          )
        );

        setUploadedFiles(prev => [...prev, completedFile]);
        onUploadComplete?.(completedFile);

      } catch (error) {
        setUploadQueue(prev => 
          prev.map(item => 
            item.file_id === upload.file_id 
              ? { 
                  ...item, 
                  status: 'error', 
                  error_message: 'Upload failed'
                }
              : item
          )
        );
      }
    }
  };

  // Drag and drop handlers
  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
    
    const files = e.dataTransfer.files;
    if (files.length > 0) {
      handleFiles(files);
    }
  }, [handleFiles]);

  // File input change handler
  const handleFileInputChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (files) {
      handleFiles(files);
    }
    // Reset input
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  }, [handleFiles]);

  // Remove file from queue
  const removeFromQueue = (fileId: string) => {
    setUploadQueue(prev => prev.filter(item => item.file_id !== fileId));
  };

  // Remove uploaded file
  const removeUploadedFile = (fileId: string) => {
    setUploadedFiles(prev => prev.filter(item => item.id !== fileId));
  };

  return (
    <div className={`space-y-4 ${className}`}>
      {/* Upload Zone */}
      <Card 
        className={`transition-colors ${
          isDragOver 
            ? 'border-primary bg-primary/5' 
            : 'border-dashed border-muted-foreground/25 hover:border-muted-foreground/50'
        }`}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
      >
        <CardContent className="p-8">
          <div className="text-center space-y-4">
            <Upload className={`w-12 h-12 mx-auto ${isDragOver ? 'text-primary' : 'text-muted-foreground'}`} />
            
            <div className="space-y-2">
              <h3 className="text-lg font-medium">
                {isDragOver ? 'Drop files here' : 'Upload your trading data'}
              </h3>
              <p className="text-sm text-muted-foreground">
                Drag and drop your CSV or Excel files here, or click to browse
              </p>
            </div>

            <div className="flex flex-wrap justify-center gap-2">
              {acceptedTypes.map(type => (
                <Badge key={type} variant="outline" className="text-xs">
                  {type.toUpperCase()}
                </Badge>
              ))}
            </div>

            <Button 
              variant="outline"
              onClick={() => fileInputRef.current?.click()}
              className="mt-4"
            >
              <FileText className="w-4 h-4 mr-2" />
              Choose Files
            </Button>

            <p className="text-xs text-muted-foreground">
              Max {maxFiles} files, {(maxSizeBytes / 1024 / 1024).toFixed(1)}MB each
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Hidden file input */}
      <input
        ref={fileInputRef}
        type="file"
        multiple
        accept={acceptedTypes.join(',')}
        onChange={handleFileInputChange}
        className="hidden"
      />

      {/* Upload Queue */}
      {uploadQueue.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Upload Progress</CardTitle>
            <CardDescription>
              {uploadQueue.filter(f => f.status === 'completed').length} of {uploadQueue.length} files completed
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {uploadQueue.map((upload) => (
              <div key={upload.file_id} className="flex items-center space-x-3 p-3 border rounded-lg">
                <div className="flex-1 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="font-medium text-sm">{upload.filename}</span>
                    <div className="flex items-center space-x-2">
                      {upload.status === 'uploading' && (
                        <Loader className="w-4 h-4 animate-spin text-blue-600" />
                      )}
                      {upload.status === 'processing' && (
                        <Loader className="w-4 h-4 animate-spin text-yellow-600" />
                      )}
                      {upload.status === 'completed' && (
                        <CheckCircle className="w-4 h-4 text-green-600" />
                      )}
                      {upload.status === 'error' && (
                        <AlertCircle className="w-4 h-4 text-red-600" />
                      )}
                      
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => removeFromQueue(upload.file_id)}
                        className="h-6 w-6 p-0"
                      >
                        <X className="w-3 h-3" />
                      </Button>
                    </div>
                  </div>
                  
                  {upload.status !== 'error' && (
                    <div className="w-full bg-muted rounded-full h-2">
                      <div 
                        className={`h-2 rounded-full transition-all ${
                          upload.status === 'completed' ? 'bg-green-600' : 'bg-blue-600'
                        }`}
                        style={{ width: `${upload.progress}%` }}
                      />
                    </div>
                  )}
                  
                  {upload.error_message && (
                    <p className="text-xs text-red-600">{upload.error_message}</p>
                  )}
                </div>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Uploaded Files */}
      {uploadedFiles.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Uploaded Files</CardTitle>
            <CardDescription>Successfully processed files</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {uploadedFiles.map((file) => (
              <div key={file.id} className="flex items-center justify-between p-3 border rounded-lg">
                <div className="space-y-1">
                  <div className="font-medium text-sm">{file.filename}</div>
                  <div className="text-xs text-muted-foreground">
                    {(file.size / 1024).toFixed(1)} KB
                    {file.processed_rows && ` • ${file.processed_rows.toLocaleString()} rows processed`}
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <CheckCircle className="w-4 h-4 text-green-600" />
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => removeUploadedFile(file.id)}
                    className="h-6 w-6 p-0"
                  >
                    <X className="w-3 h-3" />
                  </Button>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>
      )}
    </div>
  );
}