import { createClient } from '@supabase/supabase-js'

// Read env in a way compatible with Vite's define and provide safe fallbacks
// Direct references to process.env.* ensure Vite replaces them at build time.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const SUPABASE_URL_FROM_DEFINE: any = (process as any).env && (process as any).env.VITE_SUPABASE_URL
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const SUPABASE_ANON_FROM_DEFINE: any = (process as any).env && (process as any).env.VITE_SUPABASE_ANON_KEY

const supabaseUrl =
  (import.meta as any)?.env?.VITE_SUPABASE_URL ||
  SUPABASE_URL_FROM_DEFINE ||
  'https://dlesebbmlrewsbmqvuza.supabase.co'

const supabaseAnonKey =
  (import.meta as any)?.env?.VITE_SUPABASE_ANON_KEY ||
  SUPABASE_ANON_FROM_DEFINE ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRsZXNlYmJtbHJld3NibXF2dXphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NTMxMTcsImV4cCI6MjA3MDEyOTExN30.zFTVSgL5QpVqEDc-nQuKbaG_3egHZEm-V17UvkOpFCQ'

console.log('Initializing Supabase client with URL:', supabaseUrl);

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    storageKey: 'supabase-auth',
    autoRefreshToken: true,
    detectSessionInUrl: true,
    flowType: 'pkce',
    emailRedirectTo: `${window.location.origin}/complete-registration`
  },
  global: {
    headers: {
      'X-Client-Info': 'supabase-js/2.38.0'
    }
  },
  db: {
    schema: 'public'
  }
})

console.log('Supabase client initialized successfully');

// Types for our database schema
export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string
          email: string
          name: string
          role: 'Investor' | 'Startup' | 'CA' | 'CS' | 'Admin' | 'Startup Facilitation Center'
          registration_date: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          email: string
          name: string
          role: 'Investor' | 'Startup' | 'CA' | 'CS' | 'Admin' | 'Startup Facilitation Center'
          registration_date?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          email?: string
          name?: string
          role?: 'Investor' | 'Startup' | 'CA' | 'CS' | 'Admin' | 'Startup Facilitation Center'
          registration_date?: string
          created_at?: string
          updated_at?: string
        }
      }
      startups: {
        Row: {
          id: number
          name: string
          investment_type: 'Pre-Seed' | 'Seed' | 'Series A' | 'Series B' | 'Bridge'
          investment_value: number
          equity_allocation: number
          current_valuation: number
          compliance_status: 'Compliant' | 'Pending' | 'Non-Compliant'
          sector: string
          total_funding: number
          total_revenue: number
          registration_date: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: number
          name: string
          investment_type: 'Pre-Seed' | 'Seed' | 'Series A' | 'Series B' | 'Bridge'
          investment_value: number
          equity_allocation: number
          current_valuation: number
          compliance_status?: 'Compliant' | 'Pending' | 'Non-Compliant'
          sector: string
          total_funding: number
          total_revenue: number
          registration_date: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: number
          name?: string
          investment_type?: 'Pre-Seed' | 'Seed' | 'Series A' | 'Series B' | 'Bridge'
          investment_value?: number
          equity_allocation?: number
          current_valuation?: number
          compliance_status?: 'Compliant' | 'Pending' | 'Non-Compliant'
          sector?: string
          total_funding?: number
          total_revenue?: number
          registration_date?: string
          created_at?: string
          updated_at?: string
        }
      }
    }
  }
}