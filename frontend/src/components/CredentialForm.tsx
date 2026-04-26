'use client';

import React, { useState } from 'react';
import { CredentialFormData, LLMProvider } from '@/types/credentials';

interface CredentialFormProps {
  onSubmit: (data: CredentialFormData) => Promise<void>;
  loading?: boolean;
  error?: string | null;
}

const PROVIDERS: { value: LLMProvider; label: string; icon: string }[] = [
  { value: 'ollama', label: 'Ollama (Local)', icon: '🦙' },
  { value: 'openai', label: 'OpenAI', icon: '🤖' },
  { value: 'anthropic', label: 'Anthropic', icon: '🧠' },
  { value: 'openrouter', label: 'OpenRouter', icon: '🌐' },
];

export function CredentialForm({ onSubmit, loading = false, error }: CredentialFormProps) {
  const [provider, setProvider] = useState<LLMProvider>('openrouter');
  const [apiKey, setApiKey] = useState('');
  const [apiUrl, setApiUrl] = useState('http://localhost:11434');
  const [model, setModel] = useState('gpt-3.5-turbo');
  const [submitError, setSubmitError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);

    try {
      const formData: CredentialFormData = {
        provider,
        ...(provider !== 'ollama' && { apiKey }),
        ...(provider === 'ollama' && { apiUrl }),
        model: provider === 'ollama' ? model : model,
      };

      await onSubmit(formData);
      // Reset form
      setApiKey('');
      setModel(provider === 'openrouter' ? 'gpt-3.5-turbo' : 'llama3');
    } catch (err) {
      setSubmitError(err instanceof Error ? err.message : 'Error al guardar credencial');
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4 bg-white p-6 rounded-lg shadow">
      <h3 className="text-lg font-semibold text-gray-900">Añadir Credencial</h3>

      {/* Error messages */}
      {(error || submitError) && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error || submitError}
        </div>
      )}

      {/* Provider Selection */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">Proveedor</label>
        <div className="grid grid-cols-2 gap-2">
          {PROVIDERS.map((p) => (
            <button
              key={p.value}
              type="button"
              onClick={() => setProvider(p.value)}
              className={`p-3 rounded-lg border-2 transition ${
                provider === p.value
                  ? 'border-blue-500 bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <div className="text-2xl mb-1">{p.icon}</div>
              <div className="text-xs font-medium text-gray-700">{p.label}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Provider-specific fields */}
      {provider === 'ollama' ? (
        <>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">URL Base</label>
            <input
              type="url"
              value={apiUrl}
              onChange={(e) => setApiUrl(e.target.value)}
              placeholder="http://localhost:11434"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Modelo</label>
            <input
              type="text"
              value={model}
              onChange={(e) => setModel(e.target.value)}
              placeholder="llama3"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </>
      ) : provider === 'openrouter' ? (
        <>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">API Key</label>
            <input
              type="password"
              value={apiKey}
              onChange={(e) => setApiKey(e.target.value)}
              placeholder="sk-or-..."
              required
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            <p className="text-xs text-gray-500 mt-1">
              Obtén tu API Key en{' '}
              <a href="https://openrouter.ai/keys" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
                https://openrouter.ai/keys
              </a>
            </p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Modelo</label>
            <input
              type="text"
              value={model}
              onChange={(e) => setModel(e.target.value)}
              placeholder="gpt-3.5-turbo"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            <p className="text-xs text-gray-500 mt-1">
              Ver modelos disponibles en{' '}
              <a href="https://openrouter.ai/docs/models" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
                https://openrouter.ai/docs/models
              </a>
            </p>
          </div>
        </>
      ) : (
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">API Key</label>
          <input
            type="password"
            value={apiKey}
            onChange={(e) => setApiKey(e.target.value)}
            placeholder={provider === 'openai' ? 'sk-...' : 'sk-ant-...'}
            required
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <p className="text-xs text-gray-500 mt-1">
            {provider === 'openai' && (
              <>
                Obtén tu API Key en{' '}
                <a href="https://platform.openai.com/api-keys" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
                  https://platform.openai.com/api-keys
                </a>
              </>
            )}
            {provider === 'anthropic' && (
              <>
                Obtén tu API Key en{' '}
                <a href="https://console.anthropic.com/" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
                  https://console.anthropic.com/
                </a>
              </>
            )}
          </p>
        </div>
      )}

      <button
        type="submit"
        disabled={loading}
        className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white font-medium py-2 px-4 rounded-lg transition"
      >
        {loading ? 'Guardando...' : 'Guardar Credencial'}
      </button>
    </form>
  );
}
