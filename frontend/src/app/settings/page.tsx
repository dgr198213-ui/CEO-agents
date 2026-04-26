'use client';

import React, { useState } from 'react';
import { useCredentials } from '@/hooks/useCredentials';
import { CredentialForm } from '@/components/CredentialForm';
import { CredentialsList } from '@/components/CredentialsList';
import { CredentialFormData } from '@/types/credentials';

export default function SettingsPage() {
  const {
    credentials,
    activeCredential,
    loading,
    error,
    addCredential,
    deleteCredential,
    activateCredential,
  } = useCredentials();

  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const handleAddCredential = async (formData: CredentialFormData) => {
    try {
      await addCredential(formData);
      setSuccessMessage('Credencial añadida correctamente');
      setTimeout(() => setSuccessMessage(null), 3000);
    } catch (err) {
      // Error ya está manejado en el hook
    }
  };

  const handleDeleteCredential = async (id: string) => {
    if (confirm('¿Estás seguro de que deseas eliminar esta credencial?')) {
      try {
        await deleteCredential(id);
        setSuccessMessage('Credencial eliminada correctamente');
        setTimeout(() => setSuccessMessage(null), 3000);
      } catch (err) {
        // Error ya está manejado en el hook
      }
    }
  };

  const handleActivateCredential = async (id: string) => {
    try {
      await activateCredential(id);
      setSuccessMessage('Credencial activada correctamente');
      setTimeout(() => setSuccessMessage(null), 3000);
    } catch (err) {
      // Error ya está manejado en el hook
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Configuración</h1>
          <p className="text-gray-600 mt-2">Gestiona tus credenciales y configuración de LLM</p>
        </div>

        {/* Success Message */}
        {successMessage && (
          <div className="mb-6 bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg">
            {successMessage}
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column: Form */}
          <div className="lg:col-span-1">
            <CredentialForm
              onSubmit={handleAddCredential}
              loading={loading}
              error={error}
            />
          </div>

          {/* Right Column: Credentials List */}
          <div className="lg:col-span-2">
            <CredentialsList
              credentials={credentials}
              activeId={activeCredential?.id}
              onActivate={handleActivateCredential}
              onDelete={handleDeleteCredential}
              loading={loading}
            />

            {/* Active Credential Info */}
            {activeCredential && (
              <div className="mt-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
                <h4 className="font-medium text-blue-900 mb-2">Credencial Activa</h4>
                <div className="space-y-1 text-sm text-blue-800">
                  <p><strong>Proveedor:</strong> {activeCredential.provider}</p>
                  {activeCredential.model && (
                    <p><strong>Modelo:</strong> {activeCredential.model}</p>
                  )}
                  {activeCredential.apiUrl && (
                    <p><strong>URL:</strong> {activeCredential.apiUrl}</p>
                  )}
                  <p><strong>Última actualización:</strong> {new Date(activeCredential.updatedAt).toLocaleString()}</p>
                </div>
              </div>
            )}

            {/* Información de Seguridad */}
            <div className="mt-6 bg-yellow-50 border border-yellow-200 rounded-lg p-4">
              <h4 className="font-medium text-yellow-900 mb-2">🔒 Información de Seguridad</h4>
              <ul className="text-sm text-yellow-800 space-y-1">
                <li>• Las API Keys se cifran y se almacenan de forma segura</li>
                <li>• Nunca se transmiten credenciales a través de conexiones inseguras</li>
                <li>• Solo el servidor tiene acceso a las credenciales</li>
                <li>• Puedes eliminar credenciales en cualquier momento</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Providers Info */}
        <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-white rounded-lg p-6 shadow">
            <div className="text-3xl mb-2">🦙</div>
            <h3 className="font-semibold text-gray-900">Ollama</h3>
            <p className="text-sm text-gray-600 mt-2">
              Ejecuta modelos LLM localmente sin necesidad de API Keys. Perfecto para desarrollo.
            </p>
            <a
              href="https://ollama.ai"
              target="_blank"
              rel="noopener noreferrer"
              className="text-blue-600 hover:text-blue-700 text-sm mt-3 inline-block"
            >
              Descargar Ollama →
            </a>
          </div>

          <div className="bg-white rounded-lg p-6 shadow">
            <div className="text-3xl mb-2">🤖</div>
            <h3 className="font-semibold text-gray-900">OpenAI</h3>
            <p className="text-sm text-gray-600 mt-2">
              Acceso a GPT-4, GPT-3.5 y otros modelos de última generación.
            </p>
            <a
              href="https://platform.openai.com/api-keys"
              target="_blank"
              rel="noopener noreferrer"
              className="text-blue-600 hover:text-blue-700 text-sm mt-3 inline-block"
            >
              Obtener API Key →
            </a>
          </div>

          <div className="bg-white rounded-lg p-6 shadow">
            <div className="text-3xl mb-2">🧠</div>
            <h3 className="font-semibold text-gray-900">Anthropic</h3>
            <p className="text-sm text-gray-600 mt-2">
              Acceso a Claude, un modelo de IA de última generación con excelente razonamiento.
            </p>
            <a
              href="https://console.anthropic.com/"
              target="_blank"
              rel="noopener noreferrer"
              className="text-blue-600 hover:text-blue-700 text-sm mt-3 inline-block"
            >
              Obtener API Key →
            </a>
          </div>

          <div className="bg-white rounded-lg p-6 shadow">
            <div className="text-3xl mb-2">🌐</div>
            <h3 className="font-semibold text-gray-900">OpenRouter</h3>
            <p className="text-sm text-gray-600 mt-2">
              Acceso a múltiples modelos LLM (GPT-4, Claude, Llama, etc.) con una única API.
            </p>
            <a
              href="https://openrouter.ai"
              target="_blank"
              rel="noopener noreferrer"
              className="text-blue-600 hover:text-blue-700 text-sm mt-3 inline-block"
            >
              Obtener API Key →
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}

// Nota: Se agregó soporte para OpenRouter
