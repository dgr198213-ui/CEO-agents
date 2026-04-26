/**
 * CEO-Agents - Tipos de Credenciales
 * Gestión de API Keys y configuración de proveedores LLM
 */

export type LLMProvider = 'ollama' | 'openai' | 'anthropic' | 'openrouter' | 'groq' | 'deepseek' | 'mistral';

export interface CredentialConfig {
  id: string;
  provider: LLMProvider;
  apiKey: string;
  apiUrl?: string;
  model?: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface OllamaConfig {
  provider: 'ollama';
  baseUrl: string;
  model: string;
  timeout?: number;
}

export interface OpenAIConfig {
  provider: 'openai';
  apiKey: string;
  model: string;
  organization?: string;
}

export interface AnthropicConfig {
  provider: 'anthropic';
  apiKey: string;
  model: string;
}

export interface OpenRouterConfig {
  provider: 'openrouter';
  apiKey: string;
  model: string;
  referer?: string;
}

export interface GroqConfig {
  provider: 'groq';
  apiKey: string;
  model: string;
}

export interface DeepSeekConfig {
  provider: 'deepseek';
  apiKey: string;
  model: string;
}

export interface MistralConfig {
  provider: 'mistral';
  apiKey: string;
  model: string;
}

export type LLMConfig = OllamaConfig | OpenAIConfig | AnthropicConfig | OpenRouterConfig | GroqConfig | DeepSeekConfig | MistralConfig;

export interface CredentialsState {
  credentials: CredentialConfig[];
  activeCredential: CredentialConfig | null;
  loading: boolean;
  error: string | null;
}

export interface CredentialFormData {
  provider: LLMProvider;
  apiKey?: string;
  apiUrl?: string;
  model?: string;
}

export interface CredentialValidationError {
  field: string;
  message: string;
}
