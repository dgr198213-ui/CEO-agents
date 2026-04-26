"use client";

import { useQuery } from "@tanstack/react-query";
import { fetchAgents } from "@/lib/api";
import { Bot, Wrench, Star, CheckCircle2 } from "lucide-react";
import type { Agent } from "@/types";

function AgentCard({ agent }: { agent: Agent }) {
  const performancePct = Math.round(agent.performance * 100);
  const levelColor =
    performancePct >= 85
      ? "text-green-400"
      : performancePct >= 65
      ? "text-yellow-400"
      : "text-red-400";

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl p-5 hover:border-indigo-700 transition-colors">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-indigo-600/20 rounded-lg flex items-center justify-center">
            <Bot className="w-5 h-5 text-indigo-400" />
          </div>
          <div>
            <h3 className="font-semibold text-white text-sm">{agent.name}</h3>
            <span className="text-xs text-green-400 flex items-center gap-1 mt-0.5">
              <span className="w-1.5 h-1.5 rounded-full bg-green-400 inline-block" />
              {agent.status}
            </span>
          </div>
        </div>
        <div className={`text-sm font-bold ${levelColor}`}>
          {performancePct}%
        </div>
      </div>

      {/* Specializations */}
      <div className="flex flex-wrap gap-1.5 mb-4">
        {agent.specializations.map((spec) => (
          <span
            key={spec}
            className="text-xs bg-gray-800 text-gray-300 px-2 py-0.5 rounded-full"
          >
            {spec}
          </span>
        ))}
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-3 text-xs">
        <div className="flex items-center gap-1.5 text-gray-400">
          <CheckCircle2 className="w-3.5 h-3.5 text-green-400" />
          <span>{agent.tasksCompleted} tareas</span>
        </div>
        <div className="flex items-center gap-1.5 text-gray-400">
          <Star className="w-3.5 h-3.5 text-yellow-400" />
          <span>Score: {agent.performance.toFixed(2)}</span>
        </div>
      </div>

      {/* Performance bar */}
      <div className="mt-3">
        <div className="bg-gray-800 rounded-full h-1.5">
          <div
            className="bg-indigo-500 h-1.5 rounded-full transition-all"
            style={{ width: `${performancePct}%` }}
          />
        </div>
      </div>
    </div>
  );
}

export default function AgentsPage() {
  const { data: agents, isLoading, isError } = useQuery({
    queryKey: ["agents"],
    queryFn: fetchAgents,
    refetchInterval: 20_000,
  });

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Agentes</h1>
          <p className="text-gray-400 text-sm mt-1">
            Stack de agentes especializados del sistema CEO
          </p>
        </div>
        {agents && (
          <div className="flex items-center gap-2 text-sm text-gray-400">
            <Wrench className="w-4 h-4" />
            <span>{agents.length} agentes registrados</span>
          </div>
        )}
      </div>

      {isError && (
        <div className="bg-red-900/30 border border-red-700 rounded-xl p-4">
          <p className="text-red-300 text-sm">
            Error al cargar los agentes. Verifica que la API esté activa.
          </p>
        </div>
      )}

      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 8 }).map((_, i) => (
            <div
              key={i}
              className="bg-gray-900 border border-gray-800 rounded-xl p-5 animate-pulse h-48"
            />
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {agents?.map((agent) => (
            <AgentCard key={agent.name} agent={agent} />
          ))}
        </div>
      )}
    </div>
  );
}
