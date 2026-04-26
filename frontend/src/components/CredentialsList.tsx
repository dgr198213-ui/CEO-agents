'use client';

import React from 'react';
import { CredentialConfig } from '@/types/credentials';

interface CredentialsListProps {
  credentials: CredentialConfig[];
  activeId?: string;
  onActivate: (id: string) => Promise<void>;
  onDelete: (id: string) => Promise<void>;
  loading?: boolean;
}

const PROVIDER_ICONS: Record<string, string> = {
  ollama: '🦙',
  openai: '🤖',
  anthropic: '🧠',
  openrouter: '🌐',
  groq: '⚡',
  deepseek: '🔍',
  mistral: '🌪️',
};

export function CredentialsList({
  credentials,
  activeId,
  onActivate,
  onDelete,
  loading = false,
}: CredentialsListProps) {
  if (credentials.length === 0) {
    return (
      <div className="bg-gray-50 border border-gray-200 rounded-lg p-6 text-center">
        <p className="text-gray-600">No hay credenciales configuradas</p>
        <p className="text-sm text-gray-500 mt-1">Añade una credencial para comenzar</p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <h3 className="text-lg font-semibold text-gray-900">Credenciales Guardadas</h3>
      <div className="grid gap-3">
        {credentials.map((cred) => (
          <div
            key={cred.id}
            className={`p-4 rounded-lg border-2 transition ${
              activeId === cred.id
                ? 'border-green-500 bg-green-50'
                : 'border-gray-200 bg-white hover:border-gray-300'
            }`}
          >
            <div className="flex items-start justify-between">
              <div className="flex items-start gap-3 flex-1">
                <div className="text-2xl">
                  {PROVIDER_ICONS[cred.provider] || '⚙️'}
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <h4 className="font-medium text-gray-900">
                      {cred.provider.charAt(0).toUpperCase() + cred.provider.slice(1)}
                    </h4>
                    {activeId === cred.id && (
                      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        Activo
                      </span>
                    )}
                  </div>
                  {cred.model && (
                    <p className="text-sm text-gray-600">Modelo: {cred.model}</p>
                  )}
                  {cred.apiUrl && (
                    <p className="text-sm text-gray-600">URL: {cred.apiUrl}</p>
                  )}
                  <p className="text-xs text-gray-500 mt-1">
                    Creado: {new Date(cred.createdAt).toLocaleDateString()}
                  </p>
                </div>
              </div>

              <div className="flex gap-2 ml-4">
                {activeId !== cred.id && (
                  <button
                    onClick={() => onActivate(cred.id)}
                    disabled={loading}
                    className="px-3 py-1 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white text-sm rounded transition"
                  >
                    Activar
                  </button>
                )}
                <button
                  onClick={() => onDelete(cred.id)}
                  disabled={loading}
                  className="px-3 py-1 bg-red-600 hover:bg-red-700 disabled:bg-gray-400 text-white text-sm rounded transition"
                >
                  Eliminar
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
