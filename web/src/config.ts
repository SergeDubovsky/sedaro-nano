// Configuration for API endpoints
export const CONFIG = {
  // In Kubernetes, the API is accessible via the ingress at /api/
  // For local development, use the full localhost URL
  // Use VITE_API_BASE_URL if set, otherwise auto-detect based on environment
  API_BASE_URL: import.meta.env.VITE_API_BASE_URL || 
    (import.meta.env.PROD ? '/api' : 'http://localhost:8000'),
} as const;
