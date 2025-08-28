import React, { useState, useCallback, useEffect } from 'react';
import { Startup, NewInvestment, ComplianceStatus, StartupAdditionRequest, FundraisingDetails, InvestmentRecord, InvestmentType, UserRole, Founder, User, VerificationRequest, InvestmentOffer } from './types';
import { authService, AuthUser } from './lib/auth';
import { startupService, investmentService, verificationService, userService, realtimeService, startupAdditionService } from './lib/database';
import { caService } from './lib/caService';
import { csService } from './lib/csService';
import { dataMigrationService } from './lib/dataMigration';
import { storageService } from './lib/storage';
import { validationService, ValidationRequest } from './lib/validationService';
import { supabase } from './lib/supabase';
import InvestorView from './components/InvestorView';
import StartupHealthView from './components/StartupHealthView';
import AdminView from './components/AdminView';
import CAView from './components/CAView';
import CSView from './components/CSView';
import FacilitatorView from './components/FacilitatorView';
import LoginPage from './components/LoginPage';
import { TwoStepRegistration } from './components/TwoStepRegistration';
import { CompleteRegistrationPage } from './components/CompleteRegistrationPage';
import ResetPasswordPage from './components/ResetPasswordPage';
import LandingPage from './components/LandingPage';

import { Briefcase, BarChart3, LogOut } from 'lucide-react';
import LogoTMS from './components/public/logoTMS.svg';
import { FacilitatorCodeDisplay } from './components/FacilitatorCodeDisplay';

const App: React.FC = () => {
  const [view, setView] = useState<'startupHealth' | 'dashboard'>('dashboard');
  const [viewKey, setViewKey] = useState(0); // Force re-render key
  const [forceRender, setForceRender] = useState(0); // Additional force render
  const [currentPage, setCurrentPage] = useState<'landing' | 'login' | 'register' | 'complete-registration' | 'reset-password'>('landing');
  
  const [currentUser, setCurrentUser] = useState<AuthUser | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [isProcessingAuthChange, setIsProcessingAuthChange] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [selectedStartup, setSelectedStartup] = useState<Startup | null>(null);
  const [isViewOnly, setIsViewOnly] = useState(false);
  
  // Monitor view changes
  useEffect(() => {
    console.log('🔍 View changed to:', view);
    console.log('🔍 Selected startup:', selectedStartup);
    console.log('🔍 isViewOnly:', isViewOnly);
  }, [view, selectedStartup, isViewOnly]);
  const [startups, setStartups] = useState<Startup[]>([]);
  const [newInvestments, setNewInvestments] = useState<NewInvestment[]>([]);
  const [startupAdditionRequests, setStartupAdditionRequests] = useState<StartupAdditionRequest[]>([]);
  
  // Admin-related state
  const [users, setUsers] = useState<User[]>([]);
  const [verificationRequests, setVerificationRequests] = useState<VerificationRequest[]>([]);
  const [investmentOffers, setInvestmentOffers] = useState<InvestmentOffer[]>([]);
  const [validationRequests, setValidationRequests] = useState<ValidationRequest[]>([]);

  const [loadingProgress, setLoadingProgress] = useState<string>('Initializing...');
  const [connectionError, setConnectionError] = useState(false);
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  useEffect(() => {
    let isMounted = true;
    
    const initializeAuth = async () => {
      try {
        console.log('Starting auth initialization...');
        
        // Remove timeout to prevent hanging
        // const authTimeout = new Promise((_, reject) => {
        //   setTimeout(() => reject(new Error('Auth initialization timeout')), 10000);
        // });
        
        const authPromise = (async () => {
          // Handle access token from email confirmation first
          const hash = window.location.hash;
          const searchParams = new URLSearchParams(window.location.search);
          
          // Check for access token in hash or query parameters
          let accessToken = null;
          if (hash.includes('access_token=')) {
            accessToken = hash.split('access_token=')[1]?.split('&')[0];
          } else if (searchParams.has('access_token')) {
            accessToken = searchParams.get('access_token');
          }
          
          if (accessToken) {
            console.log('Found access token in URL');
            try {
              console.log('Setting session with access token...');
              const { data, error } = await authService.supabase.auth.setSession({
                access_token: accessToken,
                refresh_token: ''
              });
              
              if (error) {
                console.error('Error setting session:', error);
              } else if (data.user) {
                console.log('Session set successfully, handling email confirmation...');
                const { user, error: profileError } = await authService.handleEmailConfirmation();
                if (user && isMounted) {
                  console.log('Email confirmation successful, user:', user.email);
                  setCurrentUser(user);
                  setIsAuthenticated(true);
                } else if (profileError) {
                  console.error('Email confirmation failed:', profileError);
                  // If profile creation failed, try to create it manually
                  console.log('Attempting to create profile manually...');
                  const { user: createdUser, error: createError } = await authService.createProfile(
                    data.user.user_metadata?.name || 'Unknown',
                    data.user.user_metadata?.role || 'Investor'
                  );
                  if (createdUser && isMounted) {
                    console.log('Profile created manually:', createdUser.email);
                    setCurrentUser(createdUser);
                    setIsAuthenticated(true);
                  } else {
                    console.error('Manual profile creation failed:', createError);
                  }
                }
              }
              
              // Clean up the URL
              window.history.replaceState({}, document.title, window.location.pathname);
            } catch (error) {
              console.error('Error during email confirmation:', error);
            }
          }

          // Don't call getCurrentUser here - let the auth state listener handle it
          console.log('Auth initialization complete, waiting for auth state...');
        })();
        
        await authPromise;
        
      } catch (error) {
        console.error('Error in auth initialization:', error);
      } finally {
        // Don't set loading to false here - let the auth state change handle it
        if (isMounted) {
          console.log('Auth initialization complete');
        }
      }
    };

    initializeAuth();

    // Set up auth state listener
    const { data: { subscription } } = authService.onAuthStateChange(async (event, session) => {
      console.log('Auth state changed:', event, session?.user?.email);
      
      if (!isMounted) return;
      
      // Prevent multiple simultaneous auth state changes
      if (event === 'SIGNED_IN' || event === 'INITIAL_SESSION') {
        // Check if we're already processing an auth state change
        if (isProcessingAuthChange) {
          console.log('Auth state change already in progress, skipping...');
          return;
        }
        
        setIsProcessingAuthChange(true);
        
        try {
          if (session?.user) {
            // Check if email is confirmed before allowing login
            if (!session.user.email_confirmed_at) {
              console.log('Email not confirmed, signing out user');
              await authService.supabase.auth.signOut();
              setError('Please confirm your email before logging in. Check your inbox for the confirmation link.');
              return;
            }
            
            // Immediately set minimal user so UI can proceed
            if (isMounted) {
              const basicUser: AuthUser = {
                id: session.user.id,
                email: session.user.email || '',
                name: session.user.user_metadata?.name || 'Unknown',
                role: session.user.user_metadata?.role || 'Investor',
                startup_name: session.user.user_metadata?.startupName || undefined,
                registration_date: new Date().toISOString().split('T')[0]
              };
              console.log('Setting basic user from session and stopping loading');
              setCurrentUser(basicUser);
              setIsAuthenticated(true);
              setIsLoading(false);
            }

            // Try to get full profile, and if it doesn't exist, create it automatically
            (async () => {
              try {
                console.log('Fetching full profile after sign-in...');
                let profileUser = await authService.getCurrentUser();
                
                if (!profileUser) {
                  console.log('Profile not found, attempting to create it automatically...');
                  // Profile doesn't exist, try to create it from user metadata
                  const metadata = session.user.user_metadata;
                  if (metadata?.name && metadata?.role) {
                    console.log('Creating profile automatically with metadata:', { name: metadata.name, role: metadata.role });
                    
                    // Create the profile
                    const { data: newProfile, error: createError } = await authService.supabase
                      .from('users')
                      .insert({
                        id: session.user.id,
                        email: session.user.email,
                        name: metadata.name,
                        role: metadata.role,
                        startup_name: metadata.startupName || null,
                        registration_date: new Date().toISOString().split('T')[0]
                      })
                      .select()
                      .single();

                    if (createError) {
                      console.error('Error creating profile automatically:', createError);
                    } else {
                      console.log('Profile created automatically:', newProfile);
                      
                      // If role is Startup and startup_name was provided, create startup record
                      if (metadata.role === 'Startup' && metadata.startupName) {
                        try {
                          const { data: existingStartup } = await authService.supabase
                            .from('startups')
                            .select('id')
                            .eq('name', metadata.startupName)
                            .single();

                          if (!existingStartup) {
                            await authService.supabase
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
                                user_id: session.user.id
                              });
                            console.log('Startup record created automatically');
                          }
                        } catch (e) {
                          console.warn('Failed to create startup record automatically (non-blocking):', e);
                        }
                      }
                      
                      // Now try to get the profile again
                      profileUser = await authService.getCurrentUser();
                    }
                  }
                }
                
                if (profileUser && isMounted) {
                  console.log('Full profile loaded. Updating currentUser with startup_name:', profileUser.startup_name);
                  console.log('Profile completion status:', profileUser.is_profile_complete);
                  
                  // Check if profile is complete before setting as authenticated
                  if (!profileUser.is_profile_complete) {
                    console.log('Profile not complete, redirecting to complete-registration page');
                    setCurrentUser(profileUser);
                    setCurrentPage('complete-registration');
                    setIsLoading(false);
                    setIsProcessingAuthChange(false);
                    return;
                  }
                  
                  setCurrentUser(profileUser);
                }
              } catch (e) {
                console.error('Failed to load/create full user profile after sign-in (non-blocking):', e);
              } finally {
                // Reset the flag when done
                if (isMounted) {
                  setIsProcessingAuthChange(false);
                }
              }
            })();
          } else {
            // No existing session; show login page
            if (isMounted) {
              setCurrentUser(null);
              setIsAuthenticated(false);
              setIsLoading(false);
              setIsProcessingAuthChange(false);
            }
          }
        } catch (error) {
          console.error('Error processing auth state change:', error);
          if (isMounted) {
            setIsProcessingAuthChange(false);
          }
        }
      } else if (event === 'SIGNED_OUT') {
        if (isMounted) {
          setCurrentUser(null);
          setIsAuthenticated(false);
          setIsLoading(false);
          setIsProcessingAuthChange(false);
        }
      }
    });

      // Remove the loading timeout - it's causing issues
  // const timeoutId = setTimeout(() => {
  //   if (isMounted && isLoading) {
  //     console.log('Loading timeout reached, setting loading to false');
  //     setIsLoading(false);
  //   }
  // }, 10000); // 10 seconds timeout

    return () => {
      isMounted = false;
      subscription?.unsubscribe();
      // clearTimeout(timeoutId); // Removed timeout
    };
  }, []);

  // Monitor online/offline status
  useEffect(() => {
    const handleOnline = () => {
      console.log('Browser went online');
      setIsOnline(true);
      setConnectionError(false);
    };

    const handleOffline = () => {
      console.log('Browser went offline');
      setIsOnline(false);
      setConnectionError(true);
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  // Fetch data function
  const fetchData = useCallback(async () => {
    if (!isAuthenticated || !currentUser) return;
    
    try {
      console.log('Fetching data for authenticated user...');
      console.log('Network status:', { isOnline, connectionError });
      
      // Quick network connectivity test
      if (!isOnline) {
        console.log('Browser reports offline, setting connection error');
        setConnectionError(true);
        return;
      }
      
      // Don't set loading to true here - it's already set during auth
      
      // Fetch data with timeout to detect network issues
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Request timeout - network may be unavailable')), 10000); // 10 second timeout
      });

             const dataPromise = Promise.allSettled([
         // Use role-specific startup fetching
         currentUser?.role === 'Admin' 
           ? startupService.getAllStartupsForAdmin() 
           : currentUser?.role === 'CA'
           ? caService.getAssignedStartups().then(startups => 
               startups.map(s => ({
                 id: s.id,
                 name: s.name,
                 investmentType: 'Seed' as any,
                 investmentValue: s.totalFunding || 0,
                 equityAllocation: 0,
                 currentValuation: s.totalFunding || 0,
                 complianceStatus: s.complianceStatus,
                 sector: s.sector,
                 totalFunding: s.totalFunding,
                 totalRevenue: s.totalRevenue,
                 registrationDate: s.registrationDate,
                 founders: []
               }))
             )
           : currentUser?.role === 'CS'
           ? csService.getAssignedStartups().then(startups =>
               startups.map(s => ({
                 id: s.id,
                 name: s.name,
                 investmentType: 'Seed' as any,
                 investmentValue: s.totalFunding || 0,
                 equityAllocation: 0,
                 currentValuation: s.totalFunding || 0,
                 complianceStatus: s.complianceStatus,
                 sector: s.sector,
                 totalFunding: s.totalFunding,
                 totalRevenue: s.totalRevenue,
                 registrationDate: s.registrationDate,
                 founders: []
               }))
             )
           : startupService.getAllStartups(),
         investmentService.getNewInvestments(),
         userService.getStartupAdditionRequests(),
         userService.getAllUsers(),
         verificationService.getVerificationRequests(),
         currentUser?.role === 'Investor' 
           ? investmentService.getUserInvestmentOffers(currentUser.email)
           : currentUser?.role === 'Admin'
             ? investmentService.getAllInvestmentOffers()
             : Promise.resolve([]),
         validationService.getAllValidationRequests()
       ]);

       const [startupsData, investmentsData, requestsData, usersData, verificationData, offersData, validationData] = await Promise.race([
         dataPromise,
         timeoutPromise
       ]) as any;

             // Set data with fallbacks
       let baseStartups = startupsData.status === 'fulfilled' ? startupsData.value : [];
       const requests = requestsData.status === 'fulfilled' ? requestsData.value : [];

       // If investor, augment portfolio with approved requests
      if (currentUser?.role === 'Investor' && Array.isArray(requests)) {
        const investorCode = (currentUser as any)?.investor_code || (currentUser as any)?.investorCode;
        const approvedNames = requests
          .filter((r: any) => (r.status || 'pending') === 'approved' && (
            // keep backward-compatible behavior when no investor_code stored
            !investorCode || !r?.investor_code || (r.investor_code === investorCode || r.investorCode === investorCode)
          ))
          .map((r: any) => r.name)
          .filter((n: any) => !!n);
        
        if (approvedNames.length > 0) {
          const canonical = await startupService.getStartupsByNames(approvedNames);
          
          // Merge unique by name (not id) to prevent duplicates
          const byName: Record<string, any> = {};
          
          // First add existing startups
          baseStartups.forEach((s: any) => { 
            if (s && s.name) byName[s.name] = s; 
          });
          
          // Then add approved startups (overwrite if duplicate name)
          canonical.forEach((s: any) => { 
            if (s && s.name) byName[s.name] = s; 
          });
          
          baseStartups = Object.values(byName) as any[];
        }
      }

       setStartups(baseStartups);
       setNewInvestments(investmentsData.status === 'fulfilled' ? investmentsData.value : []);
       setStartupAdditionRequests(requests);
       setUsers(usersData.status === 'fulfilled' ? usersData.value : []);
       setVerificationRequests(verificationData.status === 'fulfilled' ? verificationData.value : []);
       setInvestmentOffers(offersData.status === 'fulfilled' ? offersData.value : []);
       setValidationRequests(validationData.status === 'fulfilled' ? validationData.value : []);

      console.log('Data fetched successfully!');
      console.log('Startups loaded:', startupsData.status === 'fulfilled' ? startupsData.value.length : 0);
      console.log('Users loaded:', usersData.status === 'fulfilled' ? usersData.value.length : 0);
      console.log('Current user role:', currentUser?.role);
      
      // For startup users, automatically find their startup
      if (currentUser?.role === 'Startup' && startupsData.status === 'fulfilled') {
        console.log('🔍 Auto-finding startup for user:', currentUser.email);
        console.log('🔍 User startup_name:', currentUser.startup_name);
        console.log('🔍 Available startups:', startupsData.value.map(s => ({ name: s.name, id: s.id })));
        
        // Primary: match by startup_name from user profile
        let userStartup = startupsData.value.find(startup => startup.name === currentUser.startup_name);

        // Fallback: if startup_name missing or mismatch, but user has exactly one startup, use it
        if (!userStartup && startupsData.value.length === 1) {
          console.log('🔁 Fallback: selecting the only startup available for this user');
          userStartup = startupsData.value[0];
        }
        
        console.log('🔍 Auto-found startup:', userStartup);
        
        if (userStartup) {
          console.log('✅ Auto-setting startup and view');
          setSelectedStartup(userStartup);
          setView('startupHealth');
        } else {
          console.log('❌ No startup found during auto-find');
        }
      }
    } catch (error) {
      console.error('Error fetching data:', error);
      // Enhanced connection error detection
      const errorMessage = error instanceof Error ? error.message : String(error);
      const errorName = error instanceof Error ? error.name : '';
      
      // Check for various network/connection error patterns
      const isConnectionError = 
        !isOnline || // Browser reports offline
        errorMessage.includes('fetch') || 
        errorMessage.includes('network') || 
        errorMessage.includes('Failed to fetch') ||
        errorMessage.includes('ERR_NETWORK') ||
        errorMessage.includes('ERR_INTERNET_DISCONNECTED') ||
        errorMessage.includes('ERR_CONNECTION_REFUSED') ||
        errorMessage.includes('ERR_CONNECTION_TIMED_OUT') ||
        errorMessage.includes('ERR_NAME_NOT_RESOLVED') ||
        errorMessage.includes('ERR_EMPTY_RESPONSE') ||
        errorMessage.includes('ERR_INTERNET_DISCONNECTED') ||
        errorName === 'TypeError' ||
        errorName === 'NetworkError' ||
        errorName === 'AbortError';
      
      console.log('Connection error detection:', { 
        errorMessage, 
        errorName, 
        isConnectionError,
        error: error 
      });
      
      if (isConnectionError) {
        setConnectionError(true);
      }
      
      // Set empty arrays if data fetch fails
      setStartups([]);
      setNewInvestments([]);
      setStartupAdditionRequests([]);
      setUsers([]);
      setVerificationRequests([]);
      setInvestmentOffers([]);
    } finally {
      // Only set loading to false if we're still in loading state
      if (isLoading) {
        setIsLoading(false);
      }
    }
  }, [isAuthenticated, currentUser, isOnline, connectionError, isLoading]);

  // Fetch data when authenticated
  useEffect(() => {
    fetchData();
  }, [fetchData]);


  // Load startup-scoped offers after startup is resolved to avoid being overwritten by global fetch
  useEffect(() => {
    (async () => {
      if (currentUser?.role === 'Startup' && selectedStartup?.id) {
        const rows = await investmentService.getOffersForStartup(selectedStartup.id);
        setInvestmentOffers(rows);
      }
    })();
  }, [currentUser?.role, selectedStartup?.id]);



  const handleLogin = useCallback((user: AuthUser) => {
    console.log(`User ${user.email} logged in as ${user.role}`);
    setIsAuthenticated(true);
    setCurrentUser(user);
    
    // For startup users, we'll set the view after data is loaded
    if (user.role !== 'Startup') {
      setView('investor'); // Default view for non-startup users
    }
  }, []);

  const handleRegister = useCallback((user: AuthUser, foundersData: Founder[], startupName?: string) => {
    console.log(`User ${user.email} registered as ${user.role}`);
    
    if (user.role === 'Startup' && foundersData.length > 0) {
        console.log('Registering with founders:', foundersData);
        const newStartup: Startup = {
            id: Date.now(),
            name: startupName || "Newly Registered Co",
            investmentType: InvestmentType.Seed,
            investmentValue: 0,
            equityAllocation: 0,
            currentValuation: 0,
            complianceStatus: ComplianceStatus.Pending,
            sector: "Technology",
            totalFunding: 0,
            totalRevenue: 0,
            registrationDate: new Date().toISOString().split('T')[0],
            founders: foundersData,
        };
        setStartups(prev => [newStartup, ...prev]);
        setSelectedStartup(newStartup);
        setView('startupHealth');
    }
     
    handleLogin(user);
  }, [handleLogin]);

  const handleLogout = useCallback(async () => {
    try {
      await authService.signOut();
      setIsAuthenticated(false);
      setCurrentUser(null);
      setSelectedStartup(null);
      setCurrentPage('login');
      setView('investor');
    } catch (error) {
      console.error('Logout failed:', error);
    }
  }, []);

  const handleViewStartup = useCallback((startup: Startup | number, targetTab?: string) => {
    console.log('🔍 handleViewStartup called with startup:', startup, 'targetTab:', targetTab);
    console.log('🔍 Current user role:', currentUser?.role);
    
    // Handle both startup object and startup ID
    let startupObj: Startup;
    if (typeof startup === 'number') {
      // Find startup by ID
      startupObj = startups.find(s => s.id === startup);
      if (!startupObj) {
        console.error('Startup not found with ID:', startup, 'in available startups:', startups.map(s => ({ id: s.id, name: s.name })));
        
        // If facilitator is trying to access a startup, we need to fetch it from the database
        if (currentUser?.role === 'Startup Facilitation Center') {
          console.log('🔍 Facilitator accessing startup, fetching from database...');
          
          // Call the async function to fetch startup data
          handleFacilitatorStartupAccess(startup, targetTab);
          return;
        } else {
          return; // For non-facilitator users, return if startup not found
        }
      }
    } else {
      startupObj = startup;
    }
    
    console.log('🔍 Setting selectedStartup to:', startupObj);
    
    // Set view-only mode based on user role
    const isViewOnlyMode = currentUser?.role === 'CA' || currentUser?.role === 'CS' || currentUser?.role === 'Startup Facilitation Center' || currentUser?.role === 'Investor';
    console.log('🔍 Setting isViewOnly to:', isViewOnlyMode);
    
    // Set the startup and view
    setSelectedStartup(startupObj);
    setIsViewOnly(isViewOnlyMode);
    setView('startupHealth');
    
    // If facilitator is accessing, set the target tab
    if (currentUser?.role === 'Startup Facilitation Center' && targetTab) {
      // Store the target tab for the StartupHealthView to use
      (window as any).facilitatorTargetTab = targetTab;
    }
    
    setViewKey(prev => prev + 1); // Force re-render
    setForceRender(prev => prev + 1); // Additional force render
    
    // Force additional re-renders to ensure state changes are applied
    setTimeout(() => {
      console.log('🔍 Forcing additional re-render...');
      setViewKey(prev => prev + 1);
      setForceRender(prev => prev + 1);
    }, 50);
    
    setTimeout(() => {
      console.log('🔍 Forcing final re-render...');
      setViewKey(prev => prev + 1);
      setForceRender(prev => prev + 1);
    }, 100);
    
    console.log('🔍 handleViewStartup completed');
  }, [currentUser?.role, startups]);

  // Separate async function to handle facilitator startup access
  const handleFacilitatorStartupAccess = async (startupId: number, targetTab?: string) => {
    try {
      console.log('🔍 Fetching startup data for facilitator, ID:', startupId);
      
      const { data: fetchedStartup, error: fetchError } = await supabase
        .from('startups')
        .select('*')
        .eq('id', startupId)
        .single();
      
      if (fetchError || !fetchedStartup) {
        console.error('Error fetching startup from database:', fetchError);
        alert('Unable to access startup. Please check your permissions.');
        return;
      }
      
      // Convert database format to Startup interface
      const startupObj: Startup = {
        id: fetchedStartup.id,
        name: fetchedStartup.name,
        investmentType: fetchedStartup.investment_type,
        investmentValue: fetchedStartup.investment_value,
        equityAllocation: fetchedStartup.equity_allocation,
        currentValuation: fetchedStartup.current_valuation,
        complianceStatus: fetchedStartup.compliance_status,
        sector: fetchedStartup.sector,
        totalFunding: fetchedStartup.total_funding,
        totalRevenue: fetchedStartup.total_revenue,
        registrationDate: fetchedStartup.registration_date,
        founders: fetchedStartup.founders || []
      };
      
      console.log('✅ Startup fetched from database:', startupObj);
      
      // Set view-only mode for facilitator
      setIsViewOnly(true);
      setSelectedStartup(startupObj);
      setView('startupHealth');
      
      // Store the target tab for the StartupHealthView to use
      if (targetTab) {
        (window as any).facilitatorTargetTab = targetTab;
      }
      
      setViewKey(prev => prev + 1); // Force re-render
      setForceRender(prev => prev + 1); // Additional force render
      
      // Force additional re-renders to ensure state changes are applied
      setTimeout(() => {
        console.log('🔍 Forcing additional re-render...');
        setViewKey(prev => prev + 1);
        setForceRender(prev => prev + 1);
      }, 50);
      
      setTimeout(() => {
        console.log('🔍 Forcing final re-render...');
        setViewKey(prev => prev + 1);
        setForceRender(prev => prev + 1);
      }, 100);
      
      console.log('🔍 Facilitator startup access completed');
    } catch (error) {
      console.error('Error in facilitator startup access:', error);
      alert('Unable to access startup. Please try again.');
    }
  };

  const handleBackToPortfolio = useCallback(() => {
    setSelectedStartup(null);
    setIsViewOnly(false);
    setView('dashboard');
    setViewKey(prev => prev + 1); // Force re-render
  }, []);

  const handleAcceptStartupRequest = useCallback(async (requestId: number) => {
    try {
      const newStartup = await startupAdditionService.acceptStartupRequest(requestId);
      
      // Update local state
      setStartups(prev => [...prev, newStartup]);
      setStartupAdditionRequests(prev => prev.filter(req => req.id !== requestId));
      
      alert(`${newStartup.name} has been added to your portfolio.`);
    } catch (error) {
      console.error('Error accepting startup request:', error);
      alert('Failed to accept startup request. Please try again.');
    }
  }, []);
  
  const handleActivateFundraising = useCallback((details: FundraisingDetails, startup: Startup) => {
    const newOpportunity: NewInvestment = {
      id: Date.now(),
      name: startup.name,
      investmentType: details.type,
      investmentValue: details.value,
      equityAllocation: details.equity,
      sector: startup.sector,
      totalFunding: startup.totalFunding,
      totalRevenue: startup.totalRevenue,
      registrationDate: startup.registrationDate,
      pitchDeckUrl: details.pitchDeckUrl,
      pitchVideoUrl: details.pitchVideoUrl,
      complianceStatus: startup.complianceStatus,
    };
    setNewInvestments(prev => [newOpportunity, ...prev]);
    
    if (details.validationRequested) {
        const newRequest: VerificationRequest = {
            id: Date.now(),
            startupId: startup.id,
            startupName: startup.name,
            requestDate: new Date().toISOString().split('T')[0],
        };
        setVerificationRequests(prev => [newRequest, ...prev]);
        alert(`${startup.name} is now listed for fundraising and a verification request has been sent to the admin.`);
    } else {
        alert(`${startup.name} is now listed for fundraising.`);
    }
  }, []);

  const handleInvestorAdded = useCallback(async (investment: InvestmentRecord, startup: Startup) => {
      console.log('🔄 handleInvestorAdded called with:', { investment, startup });
      console.log('🔍 Investment object keys:', Object.keys(investment));
      console.log('🔍 Investment investor code:', investment.investorCode);
      console.log('🔍 Current user investor codes:', { 
          investor_code: (currentUser as any)?.investor_code, 
          investorCode: (currentUser as any)?.investorCode 
      });
      
      const normalizedInvestorCode = (currentUser as any)?.investor_code || (currentUser as any)?.investorCode || investment.investorCode;
      console.log('🔍 Normalized investor code:', normalizedInvestorCode);
      
      if (!investment.investorCode) {
          console.log('❌ No investor code found in investment, returning early');
          return;
      }
      
      console.log('✅ Investor code found, proceeding to create startup addition request...');
      
      try {
          // Create an approval request for the investor who owns this code
          const newRequest: StartupAdditionRequest = {
              id: Date.now(),
              name: startup.name,
              investmentType: startup.investmentType,
              investmentValue: investment.amount,
              equityAllocation: investment.equityAllocated,
              sector: startup.sector,
              totalFunding: startup.totalFunding + investment.amount,
              totalRevenue: startup.totalRevenue,
              registrationDate: startup.registrationDate,
              investorCode: investment.investorCode,
              status: 'pending'
          };
          
          // Save to database first
          const savedRequest = await startupAdditionService.createStartupAdditionRequest({
              name: startup.name,
              investment_type: startup.investmentType,
              investment_value: investment.amount,
              equity_allocation: investment.equityAllocated,
              sector: startup.sector,
              total_funding: startup.totalFunding + investment.amount,
              total_revenue: startup.totalRevenue,
              registration_date: startup.registrationDate,
              investor_code: investment.investorCode,
              status: 'pending'
          });
          
          // Update local state with the saved request (use database ID)
          const requestWithDbId = { ...newRequest, id: savedRequest.id };
          setStartupAdditionRequests(prev => [requestWithDbId, ...prev]);
          
          console.log('✅ Startup addition request created and saved to database:', savedRequest);
          console.log('✅ Local state updated with request ID:', requestWithDbId.id);
          
          alert(`Investor request created for ${startup.name}. It will appear in the investor's Approve Startup Requests.`);
      } catch (error) {
          console.error('❌ Error creating startup addition request:', error);
          alert('Failed to create investor request. Please try again.');
      }
  }, [currentUser]);

  const handleUpdateFounders = useCallback((startupId: number, founders: Founder[]) => {
    setStartups(prevStartups => 
        prevStartups.map(s => 
            s.id === startupId ? { ...s, founders } : s
        )
    );
    if (selectedStartup?.id === startupId) {
        setSelectedStartup(prev => prev ? { ...prev, founders } : null);
    }
    alert('Founder information updated successfully.');
  }, [selectedStartup]);

  const handleSubmitOffer = useCallback(async (opportunity: NewInvestment, offerAmount: number, equityPercentage: number) => {
    if (!currentUser) return;
    
    try {
      // Since we're now referencing new_investments table which has the same IDs as startups,
      // we can use the opportunity.id directly (which is the startup ID)
      const newOffer = await investmentService.createInvestmentOffer({
        investor_email: currentUser.email,
        startup_name: opportunity.name,
        startup_id: opportunity.id, // This is the startup ID from the startups table
        offer_amount: offerAmount,
        equity_percentage: equityPercentage
      });
      
      // Update local state
      setInvestmentOffers(prev => [newOffer, ...prev]);
      alert(`Your offer for ${opportunity.name} has been submitted to the administration for review.`);
    } catch (error) {
      console.error('Error submitting offer:', error);
      
      // Show more specific error message
      let errorMessage = 'Failed to submit offer. Please try again.';
      if (error instanceof Error) {
        errorMessage = error.message;
      } else if (typeof error === 'object' && error !== null) {
        errorMessage = `Submit failed: ${JSON.stringify(error)}`;
      }
      
      alert(errorMessage);
    }
  }, [currentUser]);

  const handleProcessVerification = useCallback(async (requestId: number, status: 'approved' | 'rejected') => {
    try {
      const result = await verificationService.processVerification(requestId, status);
      
      if (result.success) {
        // Update local state
        setVerificationRequests(prev => prev.filter(r => r.id !== requestId));
        
        if (status === 'approved') {
          alert(`Verification request has been approved and startup is now "Startup Nation Verified".`);
        } else {
          alert(`Verification request has been rejected.`);
        }
      }
    } catch (error) {
      console.error('Error processing verification:', error);
      alert('Failed to process verification. Please try again.');
    }
  }, []);

  const handleProcessOffer = useCallback(async (offerId: number, status: 'approved' | 'rejected' | 'accepted' | 'completed') => {
    try {
      await investmentService.updateOfferStatus(offerId, status);
      
      // Update local state
      setInvestmentOffers(prev => prev.map(o => 
        o.id === offerId ? { ...o, status } : o
      ));
      
      const offer = investmentOffers.find(o => o.id === offerId);
      if (offer) {
        let message = `The offer for ${offer.startupName} from ${offer.investorEmail} has been ${status}.`;
        
        if (status === 'accepted') {
          message += ' The investment deal is now finalized!';
        } else if (status === 'completed') {
          message += ' The investment transaction has been completed!';
        }
        
        alert(message);
      }
    } catch (error) {
      console.error('Error processing offer:', error);
      alert('Failed to process offer. Please try again.');
    }
  }, [investmentOffers]);

  const handleUpdateOffer = useCallback(async (offerId: number, offerAmount: number, equityPercentage: number) => {
    try {
      console.log('Attempting to update offer:', { offerId, offerAmount, equityPercentage });
      
      const updatedOffer = await investmentService.updateInvestmentOffer(offerId, offerAmount, equityPercentage);
      
      // Update local state
      setInvestmentOffers(prev => prev.map(o => 
        o.id === offerId ? { ...o, offerAmount, equityPercentage } : o
      ));
      
      alert('Offer updated successfully!');
    } catch (error) {
      console.error('Error updating offer:', error);
      
      // Show more specific error message
      let errorMessage = 'Failed to update offer. Please try again.';
      if (error instanceof Error) {
        errorMessage = `Update failed: ${error.message}`;
      } else if (typeof error === 'object' && error !== null) {
        errorMessage = `Update failed: ${JSON.stringify(error)}`;
      }
      
      alert(errorMessage);
    }
  }, []);

  const handleCancelOffer = useCallback(async (offerId: number) => {
    try {
      await investmentService.deleteInvestmentOffer(offerId);
      
      // Update local state
      setInvestmentOffers(prev => prev.filter(o => o.id !== offerId));
      
      alert('Offer cancelled successfully!');
    } catch (error) {
      console.error('Error cancelling offer:', error);
      alert('Failed to cancel offer. Please try again.');
    }
  }, []);

  const handleProcessValidationRequest = useCallback(async (requestId: number, status: 'approved' | 'rejected', notes?: string) => {
    try {
      const updatedRequest = await validationService.processValidationRequest(requestId, status, notes);
      
      // Update local state
      setValidationRequests(prev => prev.map(r => 
        r.id === requestId ? updatedRequest : r
      ));
      
      const request = validationRequests.find(r => r.id === requestId);
      if (request) {
        alert(`The validation request for ${request.startupName} has been ${status}.`);
      }
    } catch (error) {
      console.error('Error processing validation request:', error);
      alert('Failed to process validation request. Please try again.');
    }
  }, [validationRequests]);

  const handleUpdateCompliance = useCallback(async (startupId: number, status: ComplianceStatus) => {
    try {
      console.log(`🔄 Updating compliance status for startup ${startupId} to: ${status}`);
      console.log(`📊 Status type: ${typeof status}, Value: "${status}"`);
      
      // First, let's check if the startup actually exists in the database
      const { data: existingStartup, error: checkError } = await supabase
        .from('startups')
        .select('id, name, compliance_status')
        .eq('id', startupId)
        .single();
      
      if (checkError) {
        console.error('❌ Error checking startup existence:', checkError);
        throw new Error(`Startup with ID ${startupId} not found in database`);
      }
      
      console.log('🔍 Found startup in database:', existingStartup);
      console.log('🔍 Current database status:', existingStartup.compliance_status);
      
      // For CA compliance updates, we need to update the compliance_checks table
      // This function is called from CA dashboard when updating overall compliance
      const { data, error } = await supabase
        .from('startups')
        .update({ compliance_status: status })
        .eq('id', startupId)
        .select(); // Add select to see what was updated
      
      if (error) {
        console.error('❌ Database update error:', error);
        console.error('❌ Error details:', {
          code: error.code,
          message: error.message,
          details: error.details,
          hint: error.hint
        });
        throw error;
      }
      
      console.log('✅ Database update successful:', data);
      console.log('✅ Rows affected:', data.length);
      
      if (data.length === 0) {
        throw new Error(`No rows were updated. Startup ID ${startupId} may not exist or have different permissions.`);
      }
      
      // Update local state
      setStartups(prev => prev.map(s => 
        s.id === startupId ? { ...s, complianceStatus: status } : s
      ));
      
      // Get startup name for alert
      const startup = startups.find(s => s.id === startupId);
      const startupName = startup?.name || 'Startup';
      
      console.log(`✅ Successfully updated ${startupName} compliance status to ${status}`);
      alert(`${startupName} compliance status has been updated to ${status}.`);
    } catch (error) {
      console.error('❌ Error updating compliance:', error);
      alert(`Failed to update compliance status: ${error.message || 'Unknown error'}. Please try again.`);
    }
  }, [startups]);

  const handleProfileUpdate = useCallback((updatedUser: any) => {
    // Update the currentUser state with the new profile data
    setCurrentUser(prevUser => ({
      ...prevUser,
      ...updatedUser
    }));
    console.log('✅ Profile updated in App.tsx:', updatedUser);
  }, []);

  const getPanelTitle = () => {
    return 'TrackMyStartup';
  }



  if (isLoading) {
      console.log('Rendering loading screen...', { isAuthenticated, currentUser: !!currentUser });
      return (
          <div className="flex items-center justify-center min-h-screen bg-slate-50 text-brand-primary">
              <div className="flex flex-col items-center gap-4">
                  <BarChart3 className="w-16 h-16 animate-pulse" />
                  <p className="text-xl font-semibold">Loading Application...</p>
                  <p className="text-sm text-slate-600">
                    Auth: {isAuthenticated ? 'Yes' : 'No'} | 
                    User: {currentUser ? 'Yes' : 'No'} | 
                    Role: {currentUser?.role || 'None'}
                  </p>
                  {loadingProgress && (
                      <p className="text-sm text-slate-600">{loadingProgress}</p>
                  )}
              </div>
          </div>
      )
  }

  // Check if we need to show complete-registration page (even when authenticated)
  if (currentPage === 'complete-registration') {
    console.log('🎯 Showing CompleteRegistrationPage (Form 2)');
    return (
      <div className="flex items-center justify-center min-h-screen bg-slate-100">
        <CompleteRegistrationPage 
          onNavigateToRegister={() => setCurrentPage('register')}
          onNavigateToDashboard={() => {
            setCurrentPage('login');
            setIsAuthenticated(true);
          }}
        />
      </div>
    );
  }

  // Check if we need to show reset-password page
  if (currentPage === 'reset-password') {
    console.log('🎯 Showing ResetPasswordPage');
    return (
      <div className="flex items-center justify-center min-h-screen bg-slate-100">
        <ResetPasswordPage 
          onNavigateToLogin={() => setCurrentPage('login')}
        />
      </div>
    );
  }

  console.log('🔍 App.tsx render - currentPage:', currentPage, 'isAuthenticated:', isAuthenticated);
  
  if (!isAuthenticated) {
    return (
        <div className="flex items-center justify-center min-h-screen bg-slate-100">
            {currentPage === 'landing' ? (
                <LandingPage
                  onNavigateToLogin={() => setCurrentPage('login')}
                  onNavigateToRegister={() => setCurrentPage('register')}
                />
            ) : currentPage === 'login' ? (
                <LoginPage 
                    onLogin={handleLogin} 
                    onNavigateToRegister={() => setCurrentPage('register')} 
                    onNavigateToCompleteRegistration={() => {
                        console.log('🔄 Navigating to complete-registration page');
                        setCurrentPage('complete-registration');
                    }}
                    onNavigateToLanding={() => setCurrentPage('landing')}
                />
            ) : currentPage === 'register' ? (
                <TwoStepRegistration 
                  onRegister={handleRegister} 
                  onNavigateToLogin={() => setCurrentPage('login')} 
                  onNavigateToLanding={() => setCurrentPage('landing')}
                />
            ) : (
                <CompleteRegistrationPage 
                  onNavigateToRegister={() => setCurrentPage('register')}
                  onNavigateToDashboard={() => {
                    setCurrentPage('login');
                    setIsAuthenticated(true);
                  }}
                />
            )}
        </div>
    )
  }

  const MainContent = () => {
    // If a startup is selected for detailed view, show it regardless of role
    if (view === 'startupHealth' && selectedStartup) {
      return (
        <StartupHealthView 
          startup={selectedStartup}
          userRole={currentUser?.role}
          user={currentUser}
          onBack={handleBackToPortfolio}
          onActivateFundraising={handleActivateFundraising}
          onInvestorAdded={handleInvestorAdded}
          onUpdateFounders={handleUpdateFounders}
          isViewOnly={isViewOnly}
          investmentOffers={investmentOffers}
          onProcessOffer={handleProcessOffer}
        />
      );
    }

    // Handle connection error
    if (connectionError) {
      return (
        <div className="text-center py-20">
          <div className="w-16 h-16 mx-auto mb-4 bg-red-100 rounded-full flex items-center justify-center">
            <svg className="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
          </div>
          <h2 className="text-xl font-semibold text-red-600 mb-2">Connection Error</h2>
          <p className="text-slate-600 mb-4">
            {!isOnline 
              ? "Your device appears to be offline. Please check your internet connection."
              : "Unable to connect to the server. Please check your internet connection and try again."
            }
          </p>
          <div className="flex gap-3 justify-center mb-4">
            <button 
              onClick={() => window.location.reload()} 
              className="px-4 py-2 bg-brand-primary text-white rounded-md hover:bg-brand-primary/90 transition-colors"
            >
              Retry Connection
            </button>
            <button 
              onClick={() => {
                setConnectionError(false);
                setIsLoading(true);
                fetchData();
              }} 
              className="px-4 py-2 bg-slate-200 text-slate-700 rounded-md hover:bg-slate-300 transition-colors"
            >
              Try Again
            </button>
          </div>
          <div className="mt-4 text-sm text-slate-400">
            <p>Network Status: {isOnline ? 'Online' : 'Offline'}</p>
            <p>If the problem persists, please contact support.</p>
          </div>
        </div>
      );
    }

    // Role-based views
    if (currentUser?.role === 'Admin') {
      return (
        <AdminView
          users={users}
          startups={startups}
          verificationRequests={verificationRequests}
          investmentOffers={investmentOffers}
          validationRequests={validationRequests}
          onProcessVerification={handleProcessVerification}
          onProcessOffer={handleProcessOffer}
          onProcessValidationRequest={handleProcessValidationRequest}
          onViewStartup={handleViewStartup}
        />
      );
    }

    if (currentUser?.role === 'CA') {
      return (
        <CAView
          startups={startups}
          onUpdateCompliance={handleUpdateCompliance}
          onViewStartup={handleViewStartup}
          currentUser={currentUser}
          onProfileUpdate={handleProfileUpdate}
          onLogout={handleLogout}
        />
      );
    }

    if (currentUser?.role === 'CS') {
      return (
        <CSView
          startups={startups}
          onUpdateCompliance={handleUpdateCompliance}
          onViewStartup={handleViewStartup}
          currentUser={currentUser}
          onProfileUpdate={handleProfileUpdate}
          onLogout={handleLogout}
        />
      );
    }

    if (currentUser?.role === 'Startup Facilitation Center') {
      return (
        <FacilitatorView
          startups={startups}
          newInvestments={newInvestments}
          startupAdditionRequests={startupAdditionRequests}
          onViewStartup={handleViewStartup}
          onAcceptRequest={handleAcceptStartupRequest}
        />
      );
    }

    if (currentUser?.role === 'Investor') {
      return (
        <InvestorView 
          startups={startups} 
          newInvestments={newInvestments}
          startupAdditionRequests={startupAdditionRequests}
          investmentOffers={investmentOffers}
          currentUser={currentUser}
          onViewStartup={handleViewStartup}
          onAcceptRequest={handleAcceptStartupRequest}
          onMakeOffer={handleSubmitOffer}
          onUpdateOffer={handleUpdateOffer}
          onCancelOffer={handleCancelOffer}
        />
      );
    }

    if (currentUser?.role === 'Startup') {
      console.log('🔍 Startup user detected:', currentUser.email);
      console.log('🔍 User startup_name:', currentUser.startup_name);
      console.log('🔍 Available startups:', startups.map(s => ({ name: s.name, id: s.id })));
      
      // Find the user's startup by startup_name from users table
      let userStartup = startups.find(startup => startup.name === currentUser.startup_name);
      // Fallback: if no match but exactly one startup is available, pick it
      if (!userStartup && startups.length === 1) {
        console.log('🔁 Fallback in renderer: selecting the only startup available for this user');
        userStartup = startups[0];
      }
      
      console.log('🔍 Found user startup:', userStartup);
      
      // If user's startup is found, show the health view
      if (userStartup) {
        console.log('✅ Rendering StartupHealthView for startup:', userStartup.name);
        return (
          <StartupHealthView 
            startup={userStartup}
            userRole={currentUser?.role}
            user={currentUser}
            onBack={() => {}} // No back button needed for startup users
            onActivateFundraising={handleActivateFundraising}
            onInvestorAdded={handleInvestorAdded}
            onUpdateFounders={handleUpdateFounders}
            investmentOffers={investmentOffers}
            onProcessOffer={handleProcessOffer}
          />
        );
      }
      
      // If no startup found, show appropriate message
      console.log('❌ No startup found for user:', currentUser.email);
      return (
        <div className="text-center py-20">
          <h2 className="text-xl font-semibold">No Startup Found</h2>
          <p className="text-slate-500 mt-2">No startup associated with your account. Please contact support.</p>
          <div className="mt-4 text-sm text-slate-400">
            <p>Debug Info:</p>
            <p>User startup_name: {currentUser.startup_name || 'NULL'}</p>
            <p>Available startups: {startups.length}</p>
          </div>
        </div>
      );
    }

    // Default fallback
    return (
      <div className="text-center py-20">
        <h2 className="text-xl font-semibold">TrackMyStartup - Welcome, {currentUser?.email}</h2>
        <p className="text-slate-500 mt-2">Startup user view - select a startup to view details.</p>
      </div>
    );
  };


  return (
    <div className="min-h-screen bg-slate-100 text-slate-800">
      <header className="bg-white shadow-sm sticky top-0 z-50">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <div className="flex items-center gap-3">
            <img src={LogoTMS} alt="TrackMyStartup" className="h-8 w-8 scale-[5] md:scale-[8] lg:scale-[10] xl:scale-[12] origin-left" />
          </div>
           <div className="flex items-center gap-6">
            {currentUser?.role === 'Investor' && (
                <div className="hidden sm:block text-sm text-slate-500 bg-slate-100 px-3 py-1.5 rounded-md font-mono">
                    Investor Code: <span className="font-semibold text-brand-primary">
                        {currentUser.investor_code || currentUser.investorCode || 'Not Set'}
                    </span>
                    {!currentUser.investor_code && !currentUser.investorCode && (
                        <span className="text-red-500 text-xs ml-2">⚠️ Code missing</span>
                    )}
                </div>
            )}

            {currentUser?.role === 'Startup Facilitation Center' && (
                <FacilitatorCodeDisplay 
                    className="bg-blue-100 text-blue-800 px-3 py-1 rounded-md text-sm font-medium" 
                    currentUser={currentUser}
                />
            )}

            <button onClick={handleLogout} className="flex items-center gap-2 text-sm font-medium text-slate-600 hover:text-brand-primary transition-colors">
                <LogOut className="h-4 w-4" />
                Logout
            </button>
           </div>
        </div>
      </header>
      
      {/* Error Display */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-md p-4 mx-4 mt-4">
          <div className="flex items-center">
            <div className="text-sm text-red-800">
              <strong>Error:</strong> {error}
            </div>
            <button 
              onClick={() => setError(null)} 
              className="ml-auto text-red-600 hover:text-red-800"
            >
              ×
            </button>
          </div>
        </div>
      )}
      
      <main className="container mx-auto p-4 sm:p-6 lg:p-8">
        <MainContent key={`${viewKey}-${forceRender}`} />
      </main>
    </div>
  );
};

export default App;