import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { Database } from './types';

export type { SupabaseClient };

/**
 * Creates a client scoped to a user's JWT (for respecting RLS)
 */
export function createSupabaseUserClient(
  supabaseUrl: string,
  anonKey: string,
  accessToken?: string,
): SupabaseClient<Database> {
  return createClient<Database>(supabaseUrl, anonKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
    global: {
      headers: accessToken ? { Authorization: `Bearer ${accessToken}` } : {},
    },
  });
}

/**
 * Creates an admin client using the service-role key (Bypasses RLS).
 * CAUTION: Only use in trusted backend environments for administrative tasks.
 */
export function createSupabaseAdminClient(
  supabaseUrl: string,
  serviceRoleKey: string,
): SupabaseClient<Database> {
  return createClient<Database>(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}
