import { supabase } from './supabase'
import { UserRole, Founder } from '../types'

export interface AuthUser {
  id: string
  email: string
  name: string
  role: UserRole
  startup_name?: string
  registration_date: string
}

export interface SignUpData {
  email: string
  password: string
  name: string
  role: UserRole
  startupName?: string
}

export interface SignInData {
  email: string
  password: string
}

// Authentication service
export const authService = {
  // Export supabase client for direct access
  supabase,

  // Test function to check if Supabase auth is working
  async testAuthConnection(): Promise<{ success: boolean; error?: string }> {
    try {
      console.log('Testing basic Supabase auth connection...');
      const { data, error } = await supabase.auth.getUser();
      if (error) {
        console.error('Auth test failed:', error);
        return { success: false, error: error.message };
      }
      console.log('Auth test successful');
      return { success: true };
    } catch (error) {
      console.error('Auth test error:', error);
      return { success: false, error: 'Auth connection failed' };
    }
  },

  // Get current user profile
  async getCurrentUser(): Promise<AuthUser | null> {
    try {
      const { data: { user }, error } = await supabase.auth.getUser()
      
      if (error || !user) {
        console.log('No authenticated user found in Supabase auth');
        return null
      }

      console.log('Found user in Supabase auth:', user.email);

      // Get user profile from our users table with timeout
      const profilePromise = supabase
        .from('users')
        .select('*')
        .eq('id', user.id)
        .single();

      const profileTimeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Profile check timeout after 5 seconds')), 5000);
      });

      const { data: profile, error: profileError } = await Promise.race([profilePromise, profileTimeoutPromise]) as any;

      if (profileError || !profile) {
        console.log('No profile found for user:', user.email);
        return null
      }

      console.log('Found user profile:', profile.email);
      console.log('Profile data:', profile);
      console.log('Startup name from profile:', profile.startup_name);
      console.log('Profile keys:', Object.keys(profile));
      console.log('Profile startup_name type:', typeof profile.startup_name);

      return {
        id: profile.id,
        email: profile.email,
        name: profile.name,
        role: profile.role,
        startup_name: profile.startup_name,
        registration_date: profile.registration_date
      }
    } catch (error) {
      console.error('Error getting current user:', error)
      return null
    }
  },

  // Sign up new user
  async signUp(data: SignUpData & { founders?: Founder[]; fileUrls?: { [key: string]: string } }): Promise<{ user: AuthUser | null; error: string | null; confirmationRequired: boolean }> {
    try {
      console.log('=== SIGNUP START ===');
      console.log('Signing up user:', data.email);
      
      // Create Supabase auth user directly
      console.log('Creating Supabase auth user...');
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: data.email,
        password: data.password,
        options: {
          data: {
            name: data.name,
            role: data.role,
            startupName: data.startupName, // make available after confirmation
            fileUrls: data.fileUrls || {}
          }
        }
      });

      console.log('Auth response received:', { authData: !!authData, authError: !!authError });

      if (authError) {
        console.error('Auth error:', authError);
        // Check if it's a user already exists error
        if (authError.message.includes('already registered') || 
            authError.message.includes('already exists') || 
            authError.message.includes('User already registered')) {
          return { user: null, error: 'User with this email already exists. Please sign in instead.', confirmationRequired: false };
        }
        return { user: null, error: authError.message, confirmationRequired: false }
      }

      console.log('Auth user created successfully, session:', !!authData.session);
      console.log('=== SIGNUP END ===');

      // If confirmation is required, session will be null
      if (!authData.session) {
        console.log('Email confirmation required');
        return { user: null, error: null, confirmationRequired: true }
      }

      // If session exists (email confirmation not required), create profile now
      if (authData.user) {
        console.log('Creating user profile in database...');
        const { data: profile, error: profileError } = await supabase
          .from('users')
          .insert({
            id: authData.user.id,
            email: authData.user.email,
            name: data.name,
            role: data.role,
            startup_name: data.role === 'Startup' ? data.startupName : null,
            registration_date: new Date().toISOString().split('T')[0]
          })
          .select()
          .single()

        if (profileError) {
          console.error('Profile creation error:', profileError);
          return { user: null, error: 'Failed to create user profile', confirmationRequired: false }
        }

        console.log('User profile created successfully');

        // If user is a startup, ensure a startup record exists
        if (data.role === 'Startup') {
          console.log('Creating startup and founders...');
          try {
            let startup = null as any;
            const { data: existingStartup } = await supabase
              .from('startups')
              .select('id')
              .eq('name', data.startupName || `${data.name}'s Startup`)
              .single();

            if (!existingStartup) {
              const insertRes = await supabase
                .from('startups')
                .insert({
                  name: data.startupName || `${data.name}'s Startup`,
                  investment_type: 'Seed',
                  investment_value: 0,
                  equity_allocation: 0,
                  current_valuation: 0,
                  compliance_status: 'Pending',
                  sector: 'Technology',
                  total_funding: 0,
                  total_revenue: 0,
                  registration_date: new Date().toISOString().split('T')[0],
                  user_id: authData.user.id
                })
                .select()
                .single();
              startup = insertRes.data;
            } else {
              startup = existingStartup;
            }

            if (startup && data.founders && data.founders.length > 0) {
              // Add founders
              const foundersData = data.founders.map(founder => ({
                startup_id: startup.id,
                name: founder.name,
                email: founder.email
              }))

              const { error: foundersError } = await supabase
                .from('founders')
                .insert(foundersData)

              if (foundersError) {
                console.error('Error adding founders:', foundersError);
              }
            }
          } catch (error) {
            console.error('Error creating startup:', error);
          }
        }

        return {
          user: {
            id: profile.id,
            email: profile.email,
            name: profile.name,
            role: profile.role,
            registration_date: profile.registration_date
          },
          error: null,
          confirmationRequired: false
        }
      }

      return { user: null, error: null, confirmationRequired: true }
    } catch (error) {
      console.error('Error in signUp:', error)
      return { user: null, error: 'An unexpected error occurred', confirmationRequired: false }
    }
  },

  // Minimal signIn function for testing
  async signInMinimal(data: SignInData): Promise<{ user: AuthUser | null; error: string | null }> {
    try {
      console.log('=== MINIMAL SIGNIN START ===');
      console.log('Signing in user:', data.email);
      
      // Just do the basic auth call
      const { data: authData, error } = await supabase.auth.signInWithPassword({
        email: data.email,
        password: data.password
      });

      console.log('Minimal auth call completed:', { authData: !!authData, error: !!error });

      if (error) {
        console.error('Sign in error:', error);
        return { user: null, error: error.message };
      }

      if (!authData.user) {
        return { user: null, error: 'No user found' };
      }

      console.log('Minimal auth successful for:', authData.user.email);
      console.log('=== MINIMAL SIGNIN END ===');
      
      // Return a basic user object
      return {
        user: {
          id: authData.user.id,
          email: authData.user.email,
          name: authData.user.user_metadata?.name || 'Unknown',
          role: authData.user.user_metadata?.role || 'Investor',
          registration_date: new Date().toISOString().split('T')[0]
        },
        error: null
      }
    } catch (error) {
      console.error('Error in minimal sign in:', error)
      return { user: null, error: 'An unexpected error occurred. Please try again.' }
    }
  },

  // Create user profile (called from CompleteProfilePage)
  async createProfile(name: string, role: UserRole): Promise<{ user: AuthUser | null; error: string | null }> {
    try {
      const { data: { user }, error: userError } = await supabase.auth.getUser()
      
      if (userError || !user) {
        return { user: null, error: 'User not authenticated' }
      }

      const { data: profile, error: profileError } = await supabase
        .from('users')
        .insert({
          id: user.id,
          email: user.email,
          name: name,
          role: role,
          registration_date: new Date().toISOString().split('T')[0]
        })
        .select()
        .single()

      if (profileError) {
        console.error('Profile creation error:', profileError)
        return { user: null, error: 'Failed to create profile' }
      }

      return {
        user: {
          id: profile.id,
          email: profile.email,
          name: profile.name,
          role: profile.role,
          registration_date: profile.registration_date
        },
        error: null
      }
    } catch (error) {
      console.error('Error creating profile:', error)
      return { user: null, error: 'An unexpected error occurred' }
    }
  },

  // Sign out user
  async signOut(): Promise<{ error: string | null }> {
    try {
      const { error } = await supabase.auth.signOut()
      return { error: error?.message || null }
    } catch (error) {
      console.error('Error signing out:', error)
      return { error: 'An unexpected error occurred' }
    }
  },

  // Update user profile
  async updateProfile(userId: string, updates: { name?: string; role?: UserRole }): Promise<{ user: AuthUser | null; error: string | null }> {
    try {
      const { data, error } = await supabase
        .from('users')
        .update(updates)
        .eq('id', userId)
        .select()
        .single()

      if (error) {
        return { user: null, error: error.message }
      }

      return {
        user: {
          id: data.id,
          email: data.email,
          name: data.name,
          role: data.role,
          registration_date: data.registration_date
        },
        error: null
      }
    } catch (error) {
      console.error('Error updating profile:', error)
      return { user: null, error: 'An unexpected error occurred' }
    }
  },

  // Listen to auth state changes
  onAuthStateChange(callback: (event: string, session: any) => void) {
    return supabase.auth.onAuthStateChange(callback)
  },

  // Handle email confirmation
  async handleEmailConfirmation(): Promise<{ user: AuthUser | null; error: string | null }> {
    try {
      console.log('=== EMAIL CONFIRMATION START ===');
      const { data: { user }, error: userError } = await supabase.auth.getUser()
      
      if (userError || !user) {
        console.error('User not authenticated:', userError);
        return { user: null, error: 'User not authenticated' }
      }

      console.log('User authenticated:', user.email);
      console.log('User metadata:', user.user_metadata);

      // Check if user profile exists
      console.log('Checking if profile exists in database...');
      const { data: profile, error: profileError } = await supabase
        .from('users')
        .select('*')
        .eq('id', user.id)
        .single()

      if (profileError) {
        console.log('Profile not found, creating from metadata...');
        // Profile doesn't exist, try to create it from metadata
        const metadata = user.user_metadata
        if (metadata?.name && metadata?.role) {
          console.log('Creating profile with metadata:', { name: metadata.name, role: metadata.role });
          const { data: newProfile, error: createError } = await supabase
            .from('users')
            .insert({
              id: user.id,
              email: user.email,
              name: metadata.name,
              role: metadata.role,
              startup_name: metadata.startupName || null,
              registration_date: new Date().toISOString().split('T')[0]
            })
            .select()
            .single()

          if (createError) {
            console.error('Error creating profile from metadata:', createError);
            return { user: null, error: 'Failed to create profile from metadata' }
          }

          console.log('Profile created successfully:', newProfile);
          // If role is Startup and startup_name was provided in metadata, ensure a startups row exists
          try {
            if (metadata.role === 'Startup' && metadata.startupName) {
              const { data: existingStartup } = await supabase
                .from('startups')
                .select('id')
                .eq('name', metadata.startupName)
                .single();

              if (!existingStartup) {
                await supabase
                  .from('startups')
                  .insert({
                    name: metadata.startupName,
                    investment_type: 'Seed',
                    investment_value: 0,
                    equity_allocation: 0,
                    current_valuation: 0,
                    compliance_status: 'Pending',
                    sector: 'Technology',
                    total_funding: 0,
                    total_revenue: 0,
                    registration_date: new Date().toISOString().split('T')[0],
                    user_id: user.id
                  });
              }
            }
          } catch (e) {
            console.warn('Failed to ensure startup row during email confirmation (non-blocking):', e);
          }
          console.log('=== EMAIL CONFIRMATION END ===');
          return {
            user: {
              id: newProfile.id,
              email: newProfile.email,
              name: newProfile.name,
              role: newProfile.role,
              registration_date: newProfile.registration_date
            },
            error: null
          }
        } else {
          console.error('No metadata found:', metadata);
          return { user: null, error: 'No metadata found to create profile' }
        }
      }

      console.log('Profile found:', profile);
      console.log('=== EMAIL CONFIRMATION END ===');
      return {
        user: {
          id: profile.id,
          email: profile.email,
          name: profile.name,
          role: profile.role,
          registration_date: profile.registration_date
        },
        error: null
      }
    } catch (error) {
      console.error('Error handling email confirmation:', error)
      return { user: null, error: 'An unexpected error occurred' }
    }
  },

  // Refresh session
  async refreshSession(): Promise<{ user: AuthUser | null; error: string | null }> {
    try {
      const { data: { session }, error } = await supabase.auth.refreshSession()
      
      if (error || !session?.user) {
        return { user: null, error: error?.message || 'No session found' }
      }

      // Get user profile
      const { data: profile, error: profileError } = await supabase
        .from('users')
        .select('*')
        .eq('id', session.user.id)
        .single()

      if (profileError || !profile) {
        return { user: null, error: 'Profile not found' }
      }

      return {
        user: {
          id: profile.id,
          email: profile.email,
          name: profile.name,
          role: profile.role,
          registration_date: profile.registration_date
        },
        error: null
      }
    } catch (error) {
      console.error('Error refreshing session:', error)
      return { user: null, error: 'An unexpected error occurred' }
    }
  }
}
