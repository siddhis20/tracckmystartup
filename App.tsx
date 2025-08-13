import React, { useState, useCallback, useEffect } from 'react';
import { Startup, NewInvestment, ComplianceStatus, StartupAdditionRequest, FundraisingDetails, InvestmentRecord, InvestmentType, UserRole, Founder, User, VerificationRequest, InvestmentOffer } from './types';
import { authService, AuthUser } from './lib/auth';
import { startupService, investmentService, verificationService, userService, realtimeService, startupAdditionService } from './lib/database';
import { dataMigrationService } from './lib/dataMigration';
import { storageService } from './lib/storage';
import InvestorView from './components/InvestorView';
import StartupHealthView from './components/StartupHealthView';
import AdminView from './components/AdminView';
import CAView from './components/CAView';
import CSView from './components/CSView';
import FacilitatorView from './components/FacilitatorView';
import LoginPage from './components/LoginPage';
import RegistrationPage from './components/RegistrationPage';

import { Briefcase, BarChart3, LogOut } from 'lucide-react';

const App: React.FC = () => {
  const [view, setView] = useState<'startupHealth'>('startupHealth');
  const [currentPage, setCurrentPage] = useState<'login' | 'register'>('login');
  
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [currentUser, setCurrentUser] = useState<AuthUser | null>(null);

  const [selectedStartup, setSelectedStartup] = useState<Startup | null>(null);
  const [startups, setStartups] = useState<Startup[]>([]);
  const [newInvestments, setNewInvestments] = useState<NewInvestment[]>([]);
  const [startupAdditionRequests, setStartupAdditionRequests] = useState<StartupAdditionRequest[]>([]);
  
  // Admin-related state
  const [users, setUsers] = useState<User[]>([]);
  const [verificationRequests, setVerificationRequests] = useState<VerificationRequest[]>([]);
  const [investmentOffers, setInvestmentOffers] = useState<InvestmentOffer[]>([]);

  const [isLoading, setIsLoading] = useState(true);
  const [loadingProgress, setLoadingProgress] = useState<string>('Initializing...');

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
      
      if ((event === 'SIGNED_IN' || event === 'INITIAL_SESSION') && session?.user) {
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
              setCurrentUser(profileUser);
            }
          } catch (e) {
            console.error('Failed to load/create full user profile after sign-in (non-blocking):', e);
          }
        })();
      } else if (event === 'INITIAL_SESSION' && !session?.user) {
        // No existing session; show login page
        if (isMounted) {
          setCurrentUser(null);
          setIsAuthenticated(false);
          setIsLoading(false);
        }
      } else if (event === 'SIGNED_OUT') {
        if (isMounted) {
          setCurrentUser(null);
          setIsAuthenticated(false);
          setIsLoading(false);
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

  // Fetch data when authenticated
  useEffect(() => {
    if (!isAuthenticated || !currentUser) return;

    const fetchData = async () => {
      try {
        console.log('Fetching data for authenticated user...');
        // Don't set loading to true here - it's already set during auth
        
        // Fetch data without timeout to prevent hanging
        const [startupsData, investmentsData, requestsData, usersData, verificationData, offersData] = await Promise.allSettled([
          // Use role-specific startup fetching
          currentUser?.role === 'Admin' 
            ? startupService.getAllStartupsForAdmin() 
            : startupService.getAllStartups(),
          investmentService.getNewInvestments(),
          userService.getStartupAdditionRequests(),
          userService.getAllUsers(),
          verificationService.getVerificationRequests(),
          investmentService.getAllInvestmentOffers()
        ]);

        // Set data with fallbacks
        setStartups(startupsData.status === 'fulfilled' ? startupsData.value : []);
        setNewInvestments(investmentsData.status === 'fulfilled' ? investmentsData.value : []);
        setStartupAdditionRequests(requestsData.status === 'fulfilled' ? requestsData.value : []);
        setUsers(usersData.status === 'fulfilled' ? usersData.value : []);
        setVerificationRequests(verificationData.status === 'fulfilled' ? verificationData.value : []);
        setInvestmentOffers(offersData.status === 'fulfilled' ? offersData.value : []);

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
    };

    fetchData();
  }, [isAuthenticated, currentUser]);

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

  const handleViewStartup = useCallback((startup: Startup) => {
    setSelectedStartup(startup);
    setView('startupHealth');
  }, []);

  const handleBackToPortfolio = useCallback(() => {
    setSelectedStartup(null);
    setView('investor');
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

  const handleInvestorAdded = useCallback((investment: InvestmentRecord, startup: Startup) => {
      const INVESTOR_CODE = 'INV-A7B3C9';
      if (investment.investorCode === INVESTOR_CODE) {
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
          };
          setStartupAdditionRequests(prev => [newRequest, ...prev]);
          alert(`You have been added to ${startup.name}'s cap table. Please review the request in your dashboard.`);
      }
  }, []);

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
      const newOffer = await investmentService.createInvestmentOffer({
        investor_email: currentUser.email,
        startup_name: opportunity.name,
        investment_id: opportunity.id,
        offer_amount: offerAmount,
        equity_percentage: equityPercentage
      });
      
      // Update local state
      setInvestmentOffers(prev => [newOffer, ...prev]);
      alert(`Your offer for ${opportunity.name} has been submitted to the administration for review.`);
    } catch (error) {
      console.error('Error submitting offer:', error);
      alert('Failed to submit offer. Please try again.');
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

  const handleProcessOffer = useCallback(async (offerId: number, status: 'approved' | 'rejected') => {
    try {
      const updatedOffer = await investmentService.updateOfferStatus(offerId, status);
      
      // Update local state
      setInvestmentOffers(prev => prev.map(o => 
        o.id === offerId ? { ...o, status } : o
      ));
      
      const offer = investmentOffers.find(o => o.id === offerId);
      if (offer) {
        alert(`The offer for ${offer.startupName} from ${offer.investorEmail} has been ${status}.`);
      }
    } catch (error) {
      console.error('Error processing offer:', error);
      alert('Failed to process offer. Please try again.');
    }
  }, [investmentOffers]);

  const handleUpdateCompliance = useCallback(async (startupId: number, status: ComplianceStatus) => {
    try {
      const updatedStartup = await startupService.updateCompliance(startupId, status);
      
      // Update local state
      setStartups(prev => prev.map(s => 
        s.id === startupId ? { ...s, complianceStatus: status } : s
      ));
      
      alert(`${updatedStartup.name} compliance status has been updated to ${status}.`);
    } catch (error) {
      console.error('Error updating compliance:', error);
      alert('Failed to update compliance status. Please try again.');
    }
  }, []);

  const getPanelTitle = () => {
    if (view === 'startupHealth' && selectedStartup) return `${selectedStartup.name} Health`;
    switch(currentUser?.role) {
      case 'Investor': return 'Investor Panel';
      case 'CA': return 'CA Panel';
      case 'CS': return 'CS Panel';
      case 'Admin': return 'Administrator Panel';
      case 'Startup Facilitation Center': return 'Facilitator Panel';
      default: return 'Dashboard';
    }
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

  if (!isAuthenticated) {
    return (
        <div className="flex items-center justify-center min-h-screen bg-slate-100">
            {currentPage === 'login' ? (
                <LoginPage 
                    onLogin={handleLogin} 
                    onNavigateToRegister={() => setCurrentPage('register')} 
                />
            ) : (
                <RegistrationPage onRegister={handleRegister} onNavigateToLogin={() => setCurrentPage('login')} />
            )}
        </div>
    )
  }

  const MainContent = () => {

    if (currentUser?.role === 'Admin') {
      return (
        <AdminView
          users={users}
          startups={startups}
          verificationRequests={verificationRequests}
          investmentOffers={investmentOffers}
          onProcessVerification={handleProcessVerification}
          onProcessOffer={handleProcessOffer}
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
        />
      );
    }

    if (currentUser?.role === 'CS') {
      return (
        <CSView
          startups={startups}
          verificationRequests={verificationRequests}
          onProcessVerification={handleProcessVerification}
          onViewStartup={handleViewStartup}
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
          />
        );
      }
      
      // If no startup found, show a message
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
        />
      );
    }
    
    if (currentUser?.role === 'Investor') {
       return (
          <InvestorView 
            startups={startups} 
            newInvestments={newInvestments}
            startupAdditionRequests={startupAdditionRequests}
            onViewStartup={handleViewStartup}
            onAcceptRequest={handleAcceptStartupRequest}
            onMakeOffer={handleSubmitOffer}
          />
        );
    }
    
    return (
      <div className="text-center py-20">
        <h2 className="text-xl font-semibold">Welcome, {currentUser?.email}</h2>
        <p className="text-slate-500 mt-2">Startup user view - select a startup to view details.</p>
      </div>
    );
  };


  return (
    <div className="min-h-screen bg-slate-100 text-slate-800">
      <header className="bg-white shadow-sm sticky top-0 z-50">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <div className="flex items-center gap-3">
            <Briefcase className="h-8 w-8 text-brand-primary" />
            <h1 className="text-2xl font-bold text-slate-800">
              {getPanelTitle()}
            </h1>
          </div>
           <div className="flex items-center gap-6">
            {currentUser?.role === 'Investor' && (
                <div className="hidden sm:block text-sm text-slate-500 bg-slate-100 px-3 py-1.5 rounded-md font-mono">
                    Investor Code: <span className="font-semibold text-brand-primary">INV-A7B3C9</span>
                </div>
            )}

            <button onClick={handleLogout} className="flex items-center gap-2 text-sm font-medium text-slate-600 hover:text-brand-primary transition-colors">
                <LogOut className="h-4 w-4" />
                Logout
            </button>
           </div>
        </div>
      </header>
      <main className="container mx-auto p-4 sm:p-6 lg:p-8">
        <MainContent />
      </main>
    </div>
  );
};

export default App;