"use client";

import { useQuery } from "@tanstack/react-query";
import { fetchHealth, fetchStats } from "@/lib/api";
import { Activity, Bot, CheckCircle, Clock, Cpu, TrendingUp, Zap } from "lucide-react";

function StatCard({ title, value, subtitle, icon: Icon, color = "indigo" }: {
  title: string; value: string | number; subtitle?: string; icon: React.ElementType; color?: string;
}) {
  const colorMap: Record<string, string> = {
    indigo: "bg-indigo-500/10 text-indigo-400",
    green:  "bg-green-500/10 text-green-400",
    yellow: "bg-yellow-500/10 text-yellow-400",
    blue:   "bg-blue-500/10 text-blue-400",
    purple: "bg-purple-500/10 text-purple-400",
  };
  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-gray-400">{title}</p>
          <p className="text-2xl font-bold text-white mt-1">{value}</p>
          {subtitle && <p className="text-xs text-gray-500 mt-1">{subtitle}</p>}
        </div>
        <div className={`p-2.5 rounded-lg ${colorMap[color] ?? colorMap.indigo}`}>
          <Icon className="w-5 h-5" />
        </div>
      </div>
    </div>
  );
}

function formatUptime(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  if (h > 0) return `${h}h ${m}m`;
  if (m > 0) return `${m}m ${s}s`;
  return `${s}s`;
}

export default function DashboardPage() {
  const { data: health, isLoading: healthLoading, isError: healthError } =
    useQuery({ queryKey: ["health"], queryFn: fetchHealth, refetchInterval: 10_000 });
  const { data: stats, isLoading: statsLoading } =
    useQuery({ queryKey: ["stats"], queryFn: fetchStats, refetchInterval: 15_000 });
  const isLoading = healthLoading || statsLoading;

  return (
    <div className="max-w-6xl mx-auto space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-white">Dashboard</h1>
        <p className="text-gray-400 text-sm mt-1">Estado en tiempo real del sistema CEO-Agents</p>
      </div>

      {healthError ? (
        <div className="bg-red-900/30 border border-red-700 rounded-xl p-4 flex items-center gap-3">
          <div className="w-2 h-2 rounded-full bg-red-400 animate-pulse" />
          <p className="text-red-300 text-sm">
            No se puede conectar con la API. Asegúrate de que el servidor Nim esté corriendo en localhost:8080.
          </p>
        </div>
      ) : health ? (
        <div className="bg-green-900/20 border border-green-800 rounded-xl p-4 flex items-center gap-3">
          <div className="w-2 h-2 rounded-full bg-green-400" />
          <p className="text-green-300 text-sm">
            Sistema operativo · v{health.version} · Uptime {formatUptime(health.uptimeSeconds)} · LLM: {health.llmProvider}
          </p>
        </div>
      ) : null}

      {isLoading ? (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="bg-gray-900 border border-gray-800 rounded-xl p-5 animate-pulse h-24" />
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard title="Agentes Activos" value={health?.agents ?? 0} subtitle="Stack especializados" icon={Bot} color="indigo" />
          <StatCard title="Herramientas" value={health?.tools ?? 0} subtitle="Registradas" icon={Cpu} color="blue" />
          <StatCard title="Tareas Totales" value={stats?.ceo.totalTasks ?? 0} subtitle="Ejecutadas" icon={Zap} color="yellow" />
          <StatCard title="Tasa de Exito" value={`${(stats?.ceo.successRate ?? 0).toFixed(1)}%`} subtitle="Completadas" icon={CheckCircle} color="green" />
          <StatCard title="Requests API" value={stats?.server.totalRequests ?? 0} subtitle="Total recibidas" icon={Activity} color="purple" />
          <StatCard title="Tokens LLM" value={stats?.llm.totalTokens ?? 0} subtitle="Consumidos" icon={TrendingUp} color="indigo" />
          <StatCard title="Cache Hits" value={stats?.llm.cacheHits ?? 0} subtitle="LLM cacheados" icon={Zap} color="green" />
          <StatCard title="Uptime" value={formatUptime(stats?.server.uptimeSeconds ?? 0)} subtitle="Tiempo activo" icon={Clock} color="blue" />
        </div>
      )}

      {stats && stats.agents.filter(a => a.tasksCompleted > 0).length > 0 && (
        <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-800">
            <h2 className="font-semibold text-white">Performance por Agente</h2>
          </div>
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-800">
                <th className="text-left px-6 py-3 text-gray-400 font-medium">Agente</th>
                <th className="text-right px-6 py-3 text-gray-400 font-medium">Tareas</th>
                <th className="text-right px-6 py-3 text-gray-400 font-medium">Performance</th>
                <th className="px-6 py-3 text-gray-400 font-medium">Nivel</th>
              </tr>
            </thead>
            <tbody>
              {stats.agents.filter(a => a.tasksCompleted > 0).sort((a, b) => b.performance - a.performance).map((agent) => (
                <tr key={agent.name} className="border-b border-gray-800/50 hover:bg-gray-800/30 transition-colors">
                  <td className="px-6 py-3 text-white font-medium">{agent.name}</td>
                  <td className="px-6 py-3 text-right text-gray-300">{agent.tasksCompleted}</td>
                  <td className="px-6 py-3 text-right text-gray-300">{(agent.performance * 100).toFixed(0)}%</td>
                  <td className="px-6 py-3">
                    <div className="flex items-center gap-2">
                      <div className="flex-1 bg-gray-800 rounded-full h-1.5">
                        <div className="bg-indigo-500 h-1.5 rounded-full" style={{ width: `${agent.performance * 100}%` }} />
                      </div>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
