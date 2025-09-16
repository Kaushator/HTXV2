#!/usr/bin/env python3
"""
Token Optimization Scripts for HTXV2 Development

This script provides utilities for optimizing token usage when working
with AI coding assistants like Cursor, Codex, and Copilot.
"""

import os
import re
import argparse
from pathlib import Path
from typing import List, Dict, Tuple
import json


class TokenOptimizer:
    """Utilities for optimizing AI assistant token usage."""
    
    def __init__(self, project_root: str = "."):
        self.project_root = Path(project_root)
        self.patterns = {
            'cursor_prompts': r'// @cursor:.*',
            'codex_prompts': r'# @codex:.*',
            'todo_items': r'(TODO|FIXME|XXX):.*',
            'large_functions': r'(def|function|const).*{',
        }
    
    def analyze_codebase_for_optimization(self) -> Dict:
        """Analyze codebase for token optimization opportunities."""
        analysis = {
            'large_files': [],
            'repetitive_patterns': [],
            'optimization_suggestions': [],
            'token_heavy_areas': []
        }
        
        # Find large files that could be split
        for file_path in self.project_root.rglob("*.py"):
            if file_path.stat().st_size > 10000:  # Files larger than 10KB
                analysis['large_files'].append({
                    'path': str(file_path),
                    'size_kb': file_path.stat().st_size / 1024,
                    'suggestion': 'Consider splitting into smaller modules'
                })
        
        for file_path in self.project_root.rglob("*.ts"):
            if file_path.stat().st_size > 8000:  # TypeScript files larger than 8KB
                analysis['large_files'].append({
                    'path': str(file_path),
                    'size_kb': file_path.stat().st_size / 1024,
                    'suggestion': 'Consider splitting into smaller components'
                })
        
        return analysis
    
    def generate_context_template(self, component_type: str) -> str:
        """Generate optimized context templates for AI assistants."""
        templates = {
            'react_component': """
// @cursor: КОНТЕКСТ: HTXV2 - криптотрейдинг платформа
// ТЕХНОЛОГИИ: TypeScript, Next.js, shadcn/ui, React Query, Zustand
// ЦЕЛЬ: {purpose}
// ПАТТЕРН: {pattern}

interface {ComponentName}Props {{
  // @cursor: добавь необходимые props для функциональности
}}

export const {ComponentName}: React.FC<{ComponentName}Props> = () => {{
  // @cursor: реализация по паттерну выше
}}
""",
            'fastapi_endpoint': """
# @codex: КОНТЕКСТ: HTXV2 backend, FastAPI, async SQLAlchemy
# БЕЗОПАСНОСТЬ: только paper trading, rate limiting обязательно  
# ЦЕЛЬ: {purpose}
# ПАТТЕРН: {pattern}

@router.{method}("/{endpoint}")
async def {function_name}(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    '''
    @codex: Реализуй с валидацией, кешированием, error handling
    '''
    pass
""",
            'service_class': """
# @codex: КОНТЕКСТ: HTXV2 бизнес-логика, async operations
# ПАТТЕРН: Service layer с dependency injection
# ЦЕЛЬ: {purpose}

class {ServiceName}Service:
    '''
    @codex: Реализуй сервис с методами:
    {methods}
    
    Включи: async/await, error handling, logging, type hints
    '''
    pass
"""
        }
        
        return templates.get(component_type, "# Template not found")
    
    def create_prompt_library(self) -> Dict[str, str]:
        """Create a library of optimized prompts for common tasks."""
        return {
            'create_crud_endpoints': """
@codex: Создай CRUD endpoints для модели {model_name}
Включи: GET (list, detail), POST (create), PUT (update), DELETE
Используй: async SQLAlchemy, Pydantic schemas, proper HTTP статусы
Добавь: валидацию, rate limiting, кеширование для GET операций
""",
            
            'create_websocket_handler': """
@cursor: Создай WebSocket handler для real-time {data_type}
Требования: auto-reconnect, message validation, subscription management
Интеграция с: Zustand store, React Query, error boundaries
""",
            
            'create_form_component': """
@cursor: Создай форму {form_name} с валидацией
Используй: react-hook-form, zod, shadcn/ui компоненты
Включи: loading states, error handling, success notifications
""",
            
            'optimize_database_queries': """
@codex: Оптимизируй database queries в {module_name}
Добавь: eager loading для relationships, индексы, pagination
Используй: async SQLAlchemy, query optimization patterns
""",
            
            'add_testing_infrastructure': """
@codex: Создай тесты для {component_name}
Включи: unit tests, integration tests, mock dependencies
Используй: pytest, asyncio, test fixtures, proper assertions
"""
        }
    
    def estimate_token_usage(self, file_path: str) -> Dict:
        """Estimate token usage for a file when sent to AI assistant."""
        path = Path(file_path)
        if not path.exists():
            return {'error': 'File not found'}
        
        content = path.read_text(encoding='utf-8')
        
        # Rough token estimation (1 token ≈ 4 characters for code)
        char_count = len(content)
        estimated_tokens = char_count // 4
        
        lines = content.split('\n')
        
        return {
            'file_path': str(path),
            'character_count': char_count,
            'line_count': len(lines),
            'estimated_tokens': estimated_tokens,
            'optimization_level': self._get_optimization_level(estimated_tokens),
            'suggestions': self._get_optimization_suggestions(content, estimated_tokens)
        }
    
    def _get_optimization_level(self, tokens: int) -> str:
        """Get optimization level based on token count."""
        if tokens < 1000:
            return 'Low - можно отправлять целиком'
        elif tokens < 3000:
            return 'Medium - рассмотрите разбиение на части'
        else:
            return 'High - обязательно разбейте на части или используйте контекстные промпты'
    
    def _get_optimization_suggestions(self, content: str, tokens: int) -> List[str]:
        """Get specific optimization suggestions."""
        suggestions = []
        
        if tokens > 2000:
            suggestions.append("Разбейте файл на логические блоки и отправляйте по частям")
            suggestions.append("Используйте контекстные комментарии @cursor/@codex")
        
        if content.count('function') > 10 or content.count('def ') > 10:
            suggestions.append("Много функций - создайте отдельные модули")
        
        if content.count('interface') > 5:
            suggestions.append("Много интерфейсов - вынесите в types файл")
        
        if content.count('import') > 20:
            suggestions.append("Много импортов - упростите зависимости")
        
        return suggestions
    
    def generate_deployment_checklist(self) -> str:
        """Generate deployment checklist with token optimization in mind."""
        return """
# HTXV2 Deployment Checklist - Token Optimized

## Pre-deployment Code Review
- [ ] Все файлы < 10KB (для эффективного AI ассистирования)
- [ ] Контекстные комментарии @cursor/@codex добавлены
- [ ] Repetitive код вынесен в utils/helpers
- [ ] Types и interfaces в отдельных файлах
- [ ] Документация обновлена

## Backend Checklist  
- [ ] Все endpoints имеют proper docstrings для Codex
- [ ] Сервисы разбиты на логические модули < 500 строк
- [ ] Схемы Pydantic в отдельном файле schemas/
- [ ] Database модели оптимизированы
- [ ] Rate limiting настроен
- [ ] Тесты покрывают основную функциональность

## Frontend Checklist
- [ ] Компоненты < 200 строк каждый
- [ ] Hooks вынесены в отдельные файлы
- [ ] Types в types/ директории
- [ ] State management оптимизирован
- [ ] WebSocket интеграция работает
- [ ] UI компоненты переиспользуются

## AI Assistant Optimization
- [ ] Prompt library создана и протестирована
- [ ] Template файлы для быстрого создания компонентов
- [ ] Context comments используются везде
- [ ] Code patterns documented для consistency
"""


def main():
    """Main CLI interface for token optimization tools."""
    parser = argparse.ArgumentParser(description='HTXV2 Token Optimization Tools')
    parser.add_argument('action', choices=[
        'analyze', 'estimate', 'template', 'checklist', 'prompts'
    ], help='Action to perform')
    parser.add_argument('--file', '-f', help='File to analyze or estimate')
    parser.add_argument('--type', '-t', help='Template type to generate')
    parser.add_argument('--output', '-o', help='Output file for results')
    
    args = parser.parse_args()
    optimizer = TokenOptimizer()
    
    if args.action == 'analyze':
        result = optimizer.analyze_codebase_for_optimization()
        print(json.dumps(result, indent=2, ensure_ascii=False))
    
    elif args.action == 'estimate' and args.file:
        result = optimizer.estimate_token_usage(args.file)
        print(json.dumps(result, indent=2, ensure_ascii=False))
    
    elif args.action == 'template' and args.type:
        template = optimizer.generate_context_template(args.type)
        print(template)
    
    elif args.action == 'checklist':
        checklist = optimizer.generate_deployment_checklist()
        print(checklist)
    
    elif args.action == 'prompts':
        prompts = optimizer.create_prompt_library()
        print(json.dumps(prompts, indent=2, ensure_ascii=False))
    
    else:
        parser.print_help()


if __name__ == '__main__':
    main()