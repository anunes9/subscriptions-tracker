import posthog from 'posthog-js'

// No-op without VITE_POSTHOG_KEY, so this is safe to call unconditionally
// (dev/test just won't have it set).
export function initObservability() {
  const postHogKey = import.meta.env.VITE_POSTHOG_KEY
  if (postHogKey) {
    posthog.init(postHogKey, {
      api_host: import.meta.env.VITE_POSTHOG_HOST || 'https://us.i.posthog.com',
      person_profiles: 'identified_only',
    })
  }
}
