#!/usr/bin/env python3
"""
Script to export OpenAPI specification from HTX Backend API
"""
import sys
import os
import json
from pathlib import Path

# Add backend to path
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

try:
    from app.main import app
    
    # Get OpenAPI schema
    openapi_schema = app.openapi()
    
    # Output directory
    docs_dir = backend_path.parent / "docs"
    docs_dir.mkdir(exist_ok=True)
    
    # Write OpenAPI JSON
    openapi_file = docs_dir / "openapi.json"
    with open(openapi_file, 'w', encoding='utf-8') as f:
        json.dump(openapi_schema, f, indent=2, ensure_ascii=False)
    
    print(f"✅ OpenAPI specification exported to: {openapi_file}")
    print(f"📊 Endpoints found: {len(openapi_schema.get('paths', {}))}")
    print(f"🏷️ API Title: {openapi_schema.get('info', {}).get('title', 'N/A')}")
    print(f"📝 API Version: {openapi_schema.get('info', {}).get('version', 'N/A')}")
    
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("Please make sure all dependencies are installed")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error generating OpenAPI spec: {e}")
    sys.exit(1)
