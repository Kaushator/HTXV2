// @cursor: КОНТЕКСТ: HTXV2 - страница торгового дашборда
// ТЕХНОЛОГИИ: Next.js App Router, TypeScript, Server Components
// ЦЕЛЬ: Главная страница торговли с TradingDashboard

'use client';

import { TradingDashboard } from '@/components/trading/TradingDashboard';

export default function TradingPage() {
  return (
    <div className="min-h-screen bg-background">
      <TradingDashboard />
    </div>
  );
}