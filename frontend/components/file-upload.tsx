"use client";

import React, { useState, useRef } from 'react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';

interface FileUploadProps {
  onUploadComplete?: (result: any) => void;
  onError?: (error: string) => void;
  apiUrl?: string;
}

interface UploadResult {
  success: boolean;
  filename: string;
  signed_url: string;
  file_info: {
    size: number;
    rows: number;
    columns: number;
    sample_data: any[];
  };
  expires_at: string;
}

export const FileUpload: React.FC<FileUploadProps> = ({
  onUploadComplete,
  onError,
  apiUrl = process.env.NODE_ENV === 'development' ? 'http://localhost:8000/api/v1' : '/api/v1'
}) => {
  const [file, setFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [validating, setValidating] = useState(false);
  const [uploadResult, setUploadResult] = useState<UploadResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [validation, setValidation] = useState<any>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = event.target.files?.[0];
    if (!selectedFile) return;

    setFile(selectedFile);
    setError(null);
    setUploadResult(null);
    setValidation(null);

    // Validate file immediately
    await validateFile(selectedFile);
  };

  const validateFile = async (fileToValidate: File) => {
    setValidating(true);
    
    try {
      const formData = new FormData();
      formData.append('file', fileToValidate);

      const response = await fetch(`${apiUrl}/files/validate`, {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error('Validation failed');
      }

      const result = await response.json();
      setValidation(result);

      if (!result.valid) {
        setError(result.errors?.join(', ') || 'Validation failed');
      }
    } catch (err) {
      setError('Failed to validate file');
      console.error('Validation error:', err);
    } finally {
      setValidating(false);
    }
  };

  const handleUpload = async () => {
    if (!file || !validation?.valid) return;

    setUploading(true);
    setError(null);

    try {
      const formData = new FormData();
      formData.append('file', file);

      const response = await fetch(`${apiUrl}/files/upload`, {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.detail?.errors?.join(', ') || 'Upload failed');
      }

      const result = await response.json();
      setUploadResult(result);
      onUploadComplete?.(result);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Upload failed';
      setError(errorMessage);
      onError?.(errorMessage);
    } finally {
      setUploading(false);
    }
  };

  const handleReset = () => {
    setFile(null);
    setUploadResult(null);
    setError(null);
    setValidation(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  return (
    <Card className="p-6">
      <div className="space-y-4">
        <div>
          <h3 className="text-lg font-semibold mb-2">Upload CSV/Excel File</h3>
          <p className="text-sm text-gray-600 mb-4">
            Upload your trading data in CSV or Excel format. Max file size: 10MB.
          </p>
        </div>

        {/* File Input */}
        <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center">
          <input
            ref={fileInputRef}
            type="file"
            accept=".csv,.xlsx,.xls"
            onChange={handleFileSelect}
            className="hidden"
            id="file-upload"
          />
          <label
            htmlFor="file-upload"
            className="cursor-pointer flex flex-col items-center space-y-2"
          >
            <div className="text-4xl text-gray-400">📁</div>
            <div className="text-sm text-gray-600">
              Click to select file or drag and drop
            </div>
            <div className="text-xs text-gray-500">
              Supported formats: CSV, XLSX, XLS
            </div>
          </label>
        </div>

        {/* File Info */}
        {file && (
          <div className="bg-gray-50 p-4 rounded-lg">
            <div className="flex items-center justify-between">
              <div>
                <div className="font-medium">{file.name}</div>
                <div className="text-sm text-gray-600">
                  {formatFileSize(file.size)}
                </div>
              </div>
              <Button variant="outline" size="sm" onClick={handleReset}>
                Remove
              </Button>
            </div>
          </div>
        )}

        {/* Validation Status */}
        {validating && (
          <div className="flex items-center space-x-2 text-blue-600">
            <div className="animate-spin w-4 h-4 border-2 border-blue-600 border-t-transparent rounded-full"></div>
            <span>Validating file...</span>
          </div>
        )}

        {/* Validation Results */}
        {validation && (
          <div className={`p-4 rounded-lg ${validation.valid ? 'bg-green-50 border border-green-200' : 'bg-red-50 border border-red-200'}`}>
            {validation.valid ? (
              <div className="text-green-800">
                <div className="font-medium">✓ File is valid</div>
                <div className="text-sm mt-1">
                  {validation.row_count} rows, {validation.column_count} columns
                </div>
                {validation.columns && (
                  <div className="text-xs mt-1">
                    Columns: {validation.columns.join(', ')}
                  </div>
                )}
              </div>
            ) : (
              <div className="text-red-800">
                <div className="font-medium">✗ Validation failed</div>
                {validation.errors && (
                  <ul className="text-sm mt-1 list-disc list-inside">
                    {validation.errors.map((error: string, index: number) => (
                      <li key={index}>{error}</li>
                    ))}
                  </ul>
                )}
              </div>
            )}
          </div>
        )}

        {/* Error Display */}
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-800 p-4 rounded-lg">
            <div className="font-medium">Error</div>
            <div className="text-sm mt-1">{error}</div>
          </div>
        )}

        {/* Upload Button */}
        {file && validation?.valid && !uploadResult && (
          <Button
            onClick={handleUpload}
            disabled={uploading}
            className="w-full"
          >
            {uploading ? (
              <>
                <div className="animate-spin w-4 h-4 border-2 border-white border-t-transparent rounded-full mr-2"></div>
                Uploading...
              </>
            ) : (
              'Upload File'
            )}
          </Button>
        )}

        {/* Upload Success */}
        {uploadResult && (
          <div className="bg-green-50 border border-green-200 p-4 rounded-lg">
            <div className="text-green-800">
              <div className="font-medium">✓ Upload successful</div>
              <div className="text-sm mt-2 space-y-1">
                <div>File: {uploadResult.filename}</div>
                <div>Size: {formatFileSize(uploadResult.file_info.size)}</div>
                <div>Rows: {uploadResult.file_info.rows}</div>
                <div>Columns: {uploadResult.file_info.columns}</div>
                <div>Expires: {new Date(uploadResult.expires_at).toLocaleString()}</div>
              </div>
              
              {uploadResult.signed_url && (
                <div className="mt-3">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => window.open(uploadResult.signed_url, '_blank')}
                  >
                    Download File
                  </Button>
                </div>
              )}

              {uploadResult.file_info.sample_data.length > 0 && (
                <details className="mt-3">
                  <summary className="cursor-pointer text-sm font-medium">
                    View sample data
                  </summary>
                  <pre className="text-xs bg-white p-2 rounded mt-1 overflow-auto">
                    {JSON.stringify(uploadResult.file_info.sample_data, null, 2)}
                  </pre>
                </details>
              )}
            </div>
          </div>
        )}
      </div>
    </Card>
  );
};