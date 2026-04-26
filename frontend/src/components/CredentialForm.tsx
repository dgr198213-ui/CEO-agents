'use client';

import React, { useState } from 'react';
import { CredentialFormData, LLMProvider } from '@/types/credentials';

interface CredentialFormProps {
  onSubmit: (data: CredentialFormData) => Promise<void>;
  loading?: boolean;
  error?: string | null;
}

const PROVIDERS: { value: LLMProvider; label: string; icon: string; description: string }[] = [
  { value: 'ollama', label: 'Ollama', icon: '🦙', description: 'Local, gratis' },
  { value: 'openai', label: 'OpenAI', icon: '🤖', description: 'GPT-4, GPT-3.5' },
  { value: 'anthropic', label: 'Anthropic', icon: '🧠', description: 'Claude 3' },
  { value: 'openrouter', label: 'OpenRouter', icon: '🌐', description: 'Multi-modelo' },
  { value: 'groq', label: 'Groq', icon: '⚡', description: 'Ultra rápido' },
  { value: 'deepseek', label: 'DeepSeek', icon: '🔍', description: 'Económico' },
  { value: 'mistral', label: 'Mistral', icon: '🌪️', description: 'Eficiente' },
];

const MODEL_SUGGESTIONS: Record<LLMProvider, string> = {
  ollama: 'llama3',
  openai: 'gpt-4o-mini',
  anthropic: 'claude-3-haiku-20240307',
  openrouter: 'gpt-3.5-turbo',
  groq: 'mixtral-8x7b-32768',
  deepseek: 'deepseek-chat',
  mistral: 'mistral-small-latest',
};

export function CredentialForm({ onSubmit, loading = false, error }: CredentialFormProps) {
  const [provider, setProvider] = useState<LLMProvider>('groq');
  const [apiKey, setApiKey] = useState('');
  const [apiUrl, setApiUrl] = useState('http://localhost:11434');
  const [model, setModel] = useState(MODEL_SUGGESTIONS.groq);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const handleProviderChange = (newProvider: LLMProvider) => {
    setProvider(newProvider);
    setModel(MODEL_SUGGESTIONS[newProvider]);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);

    try {
      const formData: CredentialFormData = {
        provider,
        ...(provider !== 'ollama' && { apiKey }),
        ...(provider === 'ollama' && { apiUrl }),
        model,
      };

      await onSubmit(formData);
      setApiKey('');
      setModel(MODEL_SUGGESTIONS[provider]);
    } catch (err) {
      setSubmitError(err instanceof Error ? err.message : 'Error al guardar credencial');
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4 bg-white p-6 rounded-lg shadow">
      <h3 className="text-lg font-semibold text-gray-900">Añadir Credencial</h3>

      {(error || submitError) && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded text-sm">
          {error || submitError}
        </div>
      )}

      {/* Provider Grid */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-3">Proveedor</label>
        <div className="grid grid-cols-2 gap-2">
          {PROVIDERS.map((p) => (
            <button
              key={p.value}
              type="button"
              onClick={() => handleProviderChange(p.value)}
              className={`p-3 rounded-lg border-2 transition text-left ${
                provider === p.value
                  ? 'border-blue-500 bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <div className="text-xl mb-1">{p.icon}</div>
              <div className="text-xs font-semibold text-gray-900">{p.label}</div>
              <div className="text-xs text-gray-500">{p.description}</div>
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
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
            />
            <p className="text-xs text-gray-500 mt-1">Ejecuta: curl https://ollama.ai/install.sh | sh</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Modelo</label>
            <input
              type="text"
              value={model}
              onChange={(e) => setModel(e.target.value)}
              placeholder="llama3"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
            />
          </div>
        </>
      ) : (
        <>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">API Key</label>
            <input
              type="password"
              value={apiKey}
              onChange={(e) => setApiKey(e.target.value)}
              placeholder={`Ingresa tu API Key para ${PROVIDERS.find(p => p.value === provider)?.label}`}
              required
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
            />
            <p className="text-xs text-gray-500 mt-1">
              {provider === 'openai' && (
                <>
                  Obtén en{' '}
                  <a href="https://platform.openai.com/api-keys" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
                    platform.openai.com
                  </a>
                </>
              )}
              {provider === 'anthropic' && (
                <>
                  Obtén en{' '}
                  <a href="https://console.anthropic.com/" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
                    console.anthropic.com
                  </a>
                </>
              )}
              {provider === 'openrouter' && (
                <>
                  Obtén en{' '}
                  <a href="https://openrouter.ai/keys" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
                    openrouter.ai
                  </a>
                </>
              )}
              {provider === 'groq' && (
                <>
                  Obtén en{' '}
                  <a href="https://console.groq.com/keys" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
                    console.groq.com
                  </a>
                </>
              )}
              {provider === 'deepseek' && (
                <>
                  Obtén en{' '}
                  <a href="https://platform.deepseek.com/api_keys" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
                    platform.deepseek.com
                  </a>
                </>
              )}
              {provider === 'mistral' && (
                <>
                  Obtén en{' '}
                  <a href="https://console.mistral.ai/api-keys/" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
                    console.mistral.ai
                  </a>
                </>
              )}
            </p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Modelo</label>
            <input
              type="text"
              value={model}
              onChange={(e) => setModel(e.target.value)}
              placeholder={MODEL_SUGGESTIONS[provider]}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
            />
            <p className="text-xs text-gray-500 mt-1">
              {provider === 'groq' && 'Modelos: mixtral-8x7b-32768, llama2-70b-4096'}
              {provider === 'deepseek' && 'Modelos: deepseek-chat, deepseek-coder'}
              {provider === 'mistral' && 'Modelos: mistral-small-latest, mistral-medium-latest, mistral-large-latest'}
            </p>
          </div>
        </>
      )}

      <button
        type="submit"
        disabled={loading}
        className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white font-medium py-2 px-4 rounded-lg transition text-sm"
      >
        {loading ? 'Guardando...' : 'Guardar Credencial'}
      </button>
    </form>
  );
}
