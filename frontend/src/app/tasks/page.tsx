"use client";

import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { executeTask, fetchTaskTypes } from "@/lib/api";
import type { TaskRequest, TaskResult } from "@/types";
import {
  PlayCircle,
  CheckCircle2,
  XCircle,
  Loader2,
  FileText,
  Clock,
  Star,
  Package,
} from "lucide-react";

const PRIORITIES = ["low", "normal", "high", "critical"] as const;

function ResultPanel({ result }: { result: TaskResult }) {
  return (
    <div
      className={`border rounded-xl overflow-hidden ${
        result.success
          ? "border-green-700 bg-green-900/10"
          : "border-red-700 bg-red-900/10"
      }`}
    >
      {/* Header */}
      <div className="px-5 py-4 border-b border-gray-800 flex items-center justify-between">
        <div className="flex items-center gap-2">
          {result.success ? (
            <CheckCircle2 className="w-5 h-5 text-green-400" />
          ) : (
            <XCircle className="w-5 h-5 text-red-400" />
          )}
          <span className="font-semibold text-white">
            {result.success ? "Tarea completada" : "Tarea fallida"}
          </span>
        </div>
        <span className="text-xs text-gray-400">Agente: {result.agent}</span>
      </div>

      {/* Metrics */}
      <div className="grid grid-cols-3 gap-px bg-gray-800">
        <div className="bg-gray-900 px-4 py-3 text-center">
          <div className="flex items-center justify-center gap-1 text-yellow-400 mb-1">
            <Star className="w-3.5 h-3.5" />
          </div>
          <p className="text-lg font-bold text-white">
            {(result.qualityScore * 100).toFixed(0)}%
          </p>
          <p className="text-xs text-gray-500">Calidad</p>
        </div>
        <div className="bg-gray-900 px-4 py-3 text-center">
          <div className="flex items-center justify-center gap-1 text-blue-400 mb-1">
            <Clock className="w-3.5 h-3.5" />
          </div>
          <p className="text-lg font-bold text-white">
            {result.executionMetrics.durationMs.toFixed(0)}ms
          </p>
          <p className="text-xs text-gray-500">Duración</p>
        </div>
        <div className="bg-gray-900 px-4 py-3 text-center">
          <div className="flex items-center justify-center gap-1 text-purple-400 mb-1">
            <Package className="w-3.5 h-3.5" />
          </div>
          <p className="text-lg font-bold text-white">
            {result.artifacts.length}
          </p>
          <p className="text-xs text-gray-500">Artefactos</p>
        </div>
      </div>

      {/* Output */}
      <div className="p-5">
        <p className="text-xs text-gray-400 mb-2 flex items-center gap-1">
          <FileText className="w-3.5 h-3.5" />
          Salida
        </p>
        <pre className="text-sm text-gray-200 whitespace-pre-wrap bg-gray-800/50 rounded-lg p-3 max-h-64 overflow-y-auto font-mono">
          {result.output}
        </pre>
      </div>

      {/* Artifacts */}
      {result.artifacts.length > 0 && (
        <div className="px-5 pb-5">
          <p className="text-xs text-gray-400 mb-2">Artefactos generados</p>
          <div className="space-y-1.5">
            {result.artifacts.map((artifact, i) => (
              <div
                key={i}
                className="flex items-center gap-2 text-xs bg-gray-800 rounded-lg px-3 py-2"
              >
                <Package className="w-3.5 h-3.5 text-indigo-400" />
                <span className="text-gray-300 font-mono">{artifact.path}</span>
                <span className="ml-auto text-gray-500">{artifact.artifactType}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export default function TasksPage() {
  const [form, setForm] = useState<TaskRequest>({
    name: "",
    description: "",
    taskType: "code_generation",
    priority: "normal",
  });

  const { data: taskTypes } = useQuery({
    queryKey: ["taskTypes"],
    queryFn: fetchTaskTypes,
  });

  const mutation = useMutation({ mutationFn: executeTask });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim() || !form.description.trim()) return;
    mutation.mutate(form);
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Ejecutar Tarea</h1>
        <p className="text-gray-400 text-sm mt-1">
          El CEO asignará automáticamente el agente más adecuado
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Form */}
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-6">
          <h2 className="font-semibold text-white mb-5">Nueva Tarea</h2>
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Name */}
            <div>
              <label className="block text-xs text-gray-400 mb-1.5">
                Nombre de la tarea *
              </label>
              <input
                type="text"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                placeholder="Ej: Implementar API REST"
                className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2.5 text-sm text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500 transition-colors"
                required
              />
            </div>

            {/* Description */}
            <div>
              <label className="block text-xs text-gray-400 mb-1.5">
                Descripción *
              </label>
              <textarea
                value={form.description}
                onChange={(e) =>
                  setForm({ ...form, description: e.target.value })
                }
                placeholder="Describe la tarea en detalle..."
                rows={4}
                className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2.5 text-sm text-white placeholder-gray-500 focus:outline-none focus:border-indigo-500 transition-colors resize-none"
                required
              />
            </div>

            {/* Task Type */}
            <div>
              <label className="block text-xs text-gray-400 mb-1.5">
                Tipo de tarea
              </label>
              <select
                value={form.taskType}
                onChange={(e) =>
                  setForm({ ...form, taskType: e.target.value })
                }
                className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2.5 text-sm text-white focus:outline-none focus:border-indigo-500 transition-colors"
              >
                {taskTypes?.map((t) => (
                  <option key={t.type} value={t.type}>
                    {t.type}
                  </option>
                )) ?? (
                  <>
                    <option value="code_generation">code_generation</option>
                    <option value="code_review">code_review</option>
                    <option value="documentation">documentation</option>
                    <option value="testing">testing</option>
                    <option value="security_scan">security_scan</option>
                    <option value="api_design">api_design</option>
                    <option value="generic">generic</option>
                  </>
                )}
              </select>
              {taskTypes && (
                <p className="text-xs text-gray-500 mt-1">
                  {taskTypes.find((t) => t.type === form.taskType)?.description}
                </p>
              )}
            </div>

            {/* Priority */}
            <div>
              <label className="block text-xs text-gray-400 mb-1.5">
                Prioridad
              </label>
              <div className="grid grid-cols-4 gap-2">
                {PRIORITIES.map((p) => (
                  <button
                    key={p}
                    type="button"
                    onClick={() => setForm({ ...form, priority: p })}
                    className={`py-2 rounded-lg text-xs font-medium transition-colors ${
                      form.priority === p
                        ? "bg-indigo-600 text-white"
                        : "bg-gray-800 text-gray-400 hover:bg-gray-700"
                    }`}
                  >
                    {p}
                  </button>
                ))}
              </div>
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={mutation.isPending}
              className="w-full flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed text-white font-medium py-2.5 rounded-lg transition-colors text-sm"
            >
              {mutation.isPending ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Ejecutando...
                </>
              ) : (
                <>
                  <PlayCircle className="w-4 h-4" />
                  Ejecutar Tarea
                </>
              )}
            </button>
          </form>
        </div>

        {/* Result */}
        <div>
          {mutation.isPending && (
            <div className="bg-gray-900 border border-gray-800 rounded-xl p-8 flex flex-col items-center justify-center gap-3">
              <Loader2 className="w-8 h-8 text-indigo-400 animate-spin" />
              <p className="text-gray-400 text-sm">El CEO está asignando y ejecutando la tarea...</p>
            </div>
          )}

          {mutation.isError && (
            <div className="bg-red-900/20 border border-red-700 rounded-xl p-5">
              <div className="flex items-center gap-2 mb-2">
                <XCircle className="w-5 h-5 text-red-400" />
                <p className="font-semibold text-red-300">Error de conexión</p>
              </div>
              <p className="text-sm text-red-400">
                {(mutation.error as Error)?.message ?? "No se pudo conectar con la API"}
              </p>
            </div>
          )}

          {mutation.isSuccess && mutation.data && (
            <ResultPanel result={mutation.data} />
          )}

          {!mutation.isPending && !mutation.isError && !mutation.isSuccess && (
            <div className="bg-gray-900 border border-gray-800 rounded-xl p-8 flex flex-col items-center justify-center gap-3 text-center">
              <PlayCircle className="w-10 h-10 text-gray-600" />
              <p className="text-gray-500 text-sm">
                Completa el formulario y ejecuta una tarea para ver los resultados aquí.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
