/**
 * CEO-Agents - Hook: useCredentials
 * Gestión de credenciales y configuración de LLM
 */

import { useState, useCallback, useEffect } from 'react';
import { CredentialConfig, CredentialFormData, LLMProvider } from '@/types/credentials';
import { api } from '@/lib/api';

export function useCredentials() {
  const [credentials, setCredentials] = useState<CredentialConfig[]>([]);
  const [activeCredential, setActiveCredential] = useState<CredentialConfig | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Cargar credenciales guardadas
  const loadCredentials = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.get('/api/v1/credentials');
      if (response.ok) {
        const data = await response.json();
        setCredentials(data.credentials || []);
        const active = data.credentials?.find((c: CredentialConfig) => c.isActive);
        setActiveCredential(active || null);
      } else {
        throw new Error('Failed to load credentials');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  }, []);

  // Añadir nueva credencial
  const addCredential = useCallback(async (formData: CredentialFormData) => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.post('/api/v1/credentials', formData);
      if (response.ok) {
        const newCredential = await response.json();
        setCredentials((prev) => [...prev, newCredential]);
        return newCredential;
      } else {
        throw new Error('Failed to add credential');
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      setError(message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  // Actualizar credencial
  const updateCredential = useCallback(async (id: string, formData: Partial<CredentialFormData>) => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.put(`/api/v1/credentials/${id}`, formData);
      if (response.ok) {
        const updated = await response.json();
        setCredentials((prev) =>
          prev.map((c) => (c.id === id ? updated : c))
        );
        if (activeCredential?.id === id) {
          setActiveCredential(updated);
        }
        return updated;
      } else {
        throw new Error('Failed to update credential');
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      setError(message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [activeCredential]);

  // Eliminar credencial
  const deleteCredential = useCallback(async (id: string) => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.delete(`/api/v1/credentials/${id}`);
      if (response.ok) {
        setCredentials((prev) => prev.filter((c) => c.id !== id));
        if (activeCredential?.id === id) {
          setActiveCredential(null);
        }
      } else {
        throw new Error('Failed to delete credential');
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      setError(message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, [activeCredential]);

  // Activar credencial
  const activateCredential = useCallback(async (id: string) => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.post(`/api/v1/credentials/${id}/activate`);
      if (response.ok) {
        const activated = await response.json();
        setCredentials((prev) =>
          prev.map((c) => ({
            ...c,
            isActive: c.id === id,
          }))
        );
        setActiveCredential(activated);
      } else {
        throw new Error('Failed to activate credential');
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      setError(message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  // Validar credencial
  const validateCredential = useCallback(async (formData: CredentialFormData): Promise<boolean> => {
    try {
      const response = await api.post('/api/v1/credentials/validate', formData);
      return response.ok;
    } catch {
      return false;
    }
  }, []);

  // Cargar credenciales al montar
  useEffect(() => {
    loadCredentials();
  }, [loadCredentials]);

  return {
    credentials,
    activeCredential,
    loading,
    error,
    loadCredentials,
    addCredential,
    updateCredential,
    deleteCredential,
    activateCredential,
    validateCredential,
  };
}
