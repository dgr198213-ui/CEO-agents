"use client";

import { useQuery } from "@tanstack/react-query";
import { fetchStats } from "@/lib/api";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  RadialBarChart,
  RadialBar,
} from "recharts";
import { BarChart3, TrendingUp, DollarSign, Zap } from "lucide-react";

function formatUptime(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  if (h > 0) return `${h}h ${m}m`;
  return `${m}m`;
}

export default function StatsPage() {
  const { data: stats, isLoading, isError } = useQuery({
    queryKey: ["stats"],
    queryFn: fetchStats,
    refetchInterval: 15_000,
  });

  if (isLoading) {
    return (
      <div className="max-w-6xl mx-auto space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Estadísticas</h1>
          <p className="text-gray-400 text-sm mt-1">Métricas del sistema</p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="bg-gray-900 border border-gray-800 rounded-xl p-6 animate-pulse h-64" />
          ))}
        </div>
      </div>
    );
  }

  if (isError || !stats) {
    return (
      <div className="max-w-6xl mx-auto">
        <div className="bg-red-900/30 border border-red-700 rounded-xl p-4">
          <p className="text-red-300 text-sm">Error al cargar estadísticas. Verifica que la API esté activa.</p>
        </div>
      </div>
    );
  }

  const agentChartData = stats.agents
    .filter((a) => a.tasksCompleted > 0)
    .sort((a, b) => b.tasksCompleted - a.tasksCompleted)
    .map((a) => ({
      name: a.name.replace("Agent", ""),
      tareas: a.tasksCompleted,
      performance: Math.round(a.performance * 100),
    }));

  const successData = [
    {
      name: "Éxito",
      value: stats.ceo.successRate,
      fill: "#6366f1",
    },
  ];

  return (
    <div className="max-w-6xl mx-auto space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-white">Estadísticas</h1>
        <p className="text-gray-400 text-sm mt-1">Métricas detalladas del sistema CEO-Agents</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
          <div className="flex items-center gap-2 mb-2">
            <Zap className="w-4 h-4 text-yellow-400" />
            <p className="text-xs text-gray-400">Total Requests LLM</p>
          </div>
          <p className="text-2xl font-bold text-white">{stats.llm.totalRequests}</p>
        </div>
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
          <div className="flex items-center gap-2 mb-2">
            <TrendingUp className="w-4 h-4 text-indigo-400" />
            <p className="text-xs text-gray-400">Tokens Totales</p>
          </div>
          <p className="text-2xl font-bold text-white">{stats.llm.totalTokens.toLocaleString()}</p>
        </div>
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
          <div className="flex items-center gap-2 mb-2">
            <DollarSign className="w-4 h-4 text-green-400" />
            <p className="text-xs text-gray-400">Costo LLM</p>
          </div>
          <p className="text-2xl font-bold text-white">${stats.llm.totalCost.toFixed(4)}</p>
        </div>
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
          <div className="flex items-center gap-2 mb-2">
            <BarChart3 className="w-4 h-4 text-blue-400" />
            <p className="text-xs text-gray-400">Uptime</p>
          </div>
          <p className="text-2xl font-bold text-white">{formatUptime(stats.server.uptimeSeconds)}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Agent Tasks Chart */}
        {agentChartData.length > 0 && (
          <div className="bg-gray-900 border border-gray-800 rounded-xl p-6">
            <h2 className="font-semibold text-white mb-4">Tareas por Agente</h2>
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={agentChartData} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                <XAxis dataKey="name" tick={{ fill: "#9ca3af", fontSize: 11 }} />
                <YAxis tick={{ fill: "#9ca3af", fontSize: 11 }} />
                <Tooltip
                  contentStyle={{ backgroundColor: "#111827", border: "1px solid #374151", borderRadius: "8px" }}
                  labelStyle={{ color: "#f9fafb" }}
                  itemStyle={{ color: "#a5b4fc" }}
                />
                <Bar dataKey="tareas" fill="#6366f1" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        )}

        {/* Success Rate Radial */}
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-6">
          <h2 className="font-semibold text-white mb-4">Tasa de Éxito Global</h2>
          <div className="flex items-center justify-center">
            <div className="relative">
              <ResponsiveContainer width={200} height={200}>
                <RadialBarChart
                  innerRadius="60%"
                  outerRadius="90%"
                  data={successData}
                  startAngle={90}
                  endAngle={-270}
                >
                  <RadialBar dataKey="value" cornerRadius={10} />
                </RadialBarChart>
              </ResponsiveContainer>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <p className="text-3xl font-bold text-white">{stats.ceo.successRate.toFixed(1)}%</p>
                <p className="text-xs text-gray-400">éxito</p>
              </div>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4 mt-4 text-center">
            <div>
              <p className="text-lg font-bold text-green-400">{stats.ceo.successfulTasks}</p>
              <p className="text-xs text-gray-400">Exitosas</p>
            </div>
            <div>
              <p className="text-lg font-bold text-red-400">{stats.ceo.totalTasks - stats.ceo.successfulTasks}</p>
              <p className="text-xs text-gray-400">Fallidas</p>
            </div>
          </div>
        </div>

        {/* Performance Chart */}
        {agentChartData.length > 0 && (
          <div className="bg-gray-900 border border-gray-800 rounded-xl p-6 lg:col-span-2">
            <h2 className="font-semibold text-white mb-4">Performance por Agente (%)</h2>
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={agentChartData} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                <XAxis dataKey="name" tick={{ fill: "#9ca3af", fontSize: 11 }} />
                <YAxis domain={[0, 100]} tick={{ fill: "#9ca3af", fontSize: 11 }} />
                <Tooltip
                  contentStyle={{ backgroundColor: "#111827", border: "1px solid #374151", borderRadius: "8px" }}
                  labelStyle={{ color: "#f9fafb" }}
                  itemStyle={{ color: "#34d399" }}
                />
                <Bar dataKey="performance" fill="#10b981" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        )}
      </div>
    </div>
  );
}
