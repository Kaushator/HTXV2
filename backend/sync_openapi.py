#!/usr/bin/env python3
"""
Advanced OpenAPI synchronization script with validation and CI/CD integration
"""
import sys
import os
import json
import hashlib
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, Optional

def get_git_hash() -> Optional[str]:
    """Get current git commit hash"""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None

def calculate_file_hash(file_path: Path) -> str:
    """Calculate SHA256 hash of file"""
    with open(file_path, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()[:8]

def export_openapi_spec() -> Dict[str, Any]:
    """Export OpenAPI specification from FastAPI app"""
    backend_path = Path(__file__).parent
    sys.path.insert(0, str(backend_path))
    
    try:
        from app.main import app
        return app.openapi()
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("💡 Install dependencies: pip install fastapi uvicorn sqlalchemy asyncpg redis")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error generating OpenAPI spec: {e}")
        sys.exit(1)

def validate_openapi_spec(spec: Dict[str, Any]) -> bool:
    """Validate OpenAPI specification"""
    required_fields = ['openapi', 'info', 'paths']
    
    for field in required_fields:
        if field not in spec:
            print(f"❌ Missing required field: {field}")
            return False
    
    if not spec.get('paths'):
        print("❌ No API paths found in specification")
        return False
    
    info = spec.get('info', {})
    if not info.get('title') or not info.get('version'):
        print("❌ Missing title or version in API info")
        return False
    
    return True

def check_for_changes(old_file: Path, new_spec: Dict[str, Any]) -> bool:
    """Check if OpenAPI spec has changed"""
    if not old_file.exists():
        return True
    
    try:
        with open(old_file, 'r', encoding='utf-8') as f:
            old_spec = json.load(f)
        
        # Compare relevant fields (ignore metadata)
        old_paths = old_spec.get('paths', {})
        new_paths = new_spec.get('paths', {})
        
        old_components = old_spec.get('components', {})
        new_components = new_spec.get('components', {})
        
        return (old_paths != new_paths or 
                old_components != new_components or
                old_spec.get('info', {}).get('version') != new_spec.get('info', {}).get('version'))
    
    except (json.JSONDecodeError, FileNotFoundError):
        return True

def add_metadata(spec: Dict[str, Any]) -> Dict[str, Any]:
    """Add generation metadata to OpenAPI spec"""
    git_hash = get_git_hash()
    
    # Add custom extension with metadata
    spec['x-generated-at'] = datetime.now().isoformat()
    if git_hash:
        spec['x-git-hash'] = git_hash
    
    spec['x-generator'] = {
        'name': 'HTX Backend Export Script',
        'version': '1.0.0'
    }
    
    return spec

def write_spec_file(spec: Dict[str, Any], output_file: Path) -> None:
    """Write OpenAPI spec to file with proper formatting"""
    output_file.parent.mkdir(exist_ok=True)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(spec, f, indent=2, ensure_ascii=False, sort_keys=True)

def print_summary(spec: Dict[str, Any], output_file: Path, changed: bool) -> None:
    """Print operation summary"""
    info = spec.get('info', {})
    paths_count = len(spec.get('paths', {}))
    components_count = len(spec.get('components', {}).get('schemas', {}))
    
    print("🎯 OpenAPI Export Summary")
    print("=" * 40)
    print(f"📄 Output File: {output_file}")
    print(f"🏷️  API Title: {info.get('title', 'N/A')}")
    print(f"📝 API Version: {info.get('version', 'N/A')}")
    print(f"🔌 OpenAPI Version: {spec.get('openapi', 'N/A')}")
    print(f"📊 Endpoints: {paths_count}")
    print(f"🏗️  Schemas: {components_count}")
    print(f"📦 File Size: {output_file.stat().st_size:,} bytes")
    print(f"🔄 Changed: {'Yes' if changed else 'No'}")
    
    if 'x-git-hash' in spec:
        print(f"📋 Git Hash: {spec['x-git-hash']}")
    
    if 'x-generated-at' in spec:
        print(f"⏰ Generated: {spec['x-generated-at']}")

def main():
    """Main function"""
    print("🚀 HTX OpenAPI Export Script")
    print("-" * 30)
    
    # Paths
    backend_path = Path(__file__).parent
    docs_dir = backend_path.parent / "docs"
    output_file = docs_dir / "openapi.json"
    
    print(f"📁 Backend Path: {backend_path}")
    print(f"📁 Output Path: {output_file}")
    print()
    
    # Export OpenAPI spec
    print("📤 Exporting OpenAPI specification...")
    spec = export_openapi_spec()
    
    # Validate spec
    print("✅ Validating specification...")
    if not validate_openapi_spec(spec):
        sys.exit(1)
    
    # Check for changes
    changed = check_for_changes(output_file, spec)
    
    # Add metadata
    spec = add_metadata(spec)
    
    # Write file
    print("💾 Writing specification file...")
    write_spec_file(spec, output_file)
    
    # Print summary
    print_summary(spec, output_file, changed)
    
    # Success message
    if changed:
        print("\n✅ OpenAPI specification successfully updated!")
        print("💡 Don't forget to commit the changes to git")
    else:
        print("\n✅ OpenAPI specification is already up to date!")
    
    # Validation command suggestion
    print("\n🔍 To validate the specification:")
    print(f"   npx @apidevtools/swagger-parser validate docs/openapi.json")
    
    print("\n📖 To view interactive documentation:")
    print("   cd backend && uvicorn app.main:app --reload")
    print("   Then open: http://localhost:8000/docs")

if __name__ == "__main__":
    main()
