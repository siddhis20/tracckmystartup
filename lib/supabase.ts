import { createClient } from '@supabase/supabase-js'

// Updated Supabase project credentials
const supabaseUrl = 'https://dlesebbmlrewsbmqvuza.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRsZXNlYmJtbHJld3NibXF2dXphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NTMxMTcsImV4cCI6MjA3MDEyOTExN30.zFTVSgL5QpVqEDc-nQuKbaG_3egHZEm-V17UvkOpFCQ'

console.log('Initializing Supabase client with URL:', supabaseUrl);

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    storageKey: 'supabase-auth',
    autoRefreshToken: true,
    detectSessionInUrl: true
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
