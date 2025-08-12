import { supabase } from './supabase'
import { UserRole, InvestmentType, ComplianceStatus, InvestorType, InvestmentRoundType, EsopAllocationType, OfferStatus } from '../types'

// User Management
export const userService = {
  // Get current user profile
  async getCurrentUser() {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return null

    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', user.id)
      .single()

    if (error) throw error
    return data
  },

  // Update user profile
  async updateUser(userId: string, updates: { name?: string; role?: UserRole }) {
    const { data, error } = await supabase
      .from('users')
      .update(updates)
      .eq('id', userId)
      .select()
      .single()

    if (error) throw error
    return data
  },

  // Get all users (admin only)
  async getAllUsers(): Promise<any[]> {
    console.log('Fetching all users...');
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .order('created_at', { ascending: false })
      
      if (error) {
        console.error('Error fetching users:', error)
        return []
      }
      
      console.log('Users fetched successfully:', data?.length || 0);
      return data || []
    } catch (error) {
      console.error('Error in getAllUsers:', error)
      return []
    }
  },

  // Get startup addition requests
  async getStartupAdditionRequests(): Promise<any[]> {
    console.log('Fetching startup addition requests...');
    try {
      const { data, error } = await supabase
        .from('startup_addition_requests')
        .select('*')
        .order('created_at', { ascending: false })
      
      if (error) {
        console.error('Error fetching startup addition requests:', error)
        return []
      }
      
      console.log('Startup addition requests fetched successfully:', data?.length || 0);
      return data || []
    } catch (error) {
      console.error('Error in getStartupAdditionRequests:', error)
      return []
    }
  }
}

// Startup Management
export const startupService = {
  // Get all startups for current user
  async getAllStartups() {
    console.log('Fetching startups for current user...');
    try {
      // Get current user ID
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        console.log('No authenticated user found');
        return [];
      }

      const { data, error } = await supabase
        .from('startups')
        .select(`
          *,
          founders (*)
        `)
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Error fetching startups:', error);
        return [];
      }
      
      console.log('Startups fetched successfully:', data?.length || 0);
      
      // Map database fields to frontend expected format
      const mappedData = (data || []).map(startup => ({
        id: startup.id,
        name: startup.name,
        investmentType: startup.investment_type,
        investmentValue: startup.investment_value,
        equityAllocation: startup.equity_allocation,
        currentValuation: startup.current_valuation,
        complianceStatus: startup.compliance_status,
        sector: startup.sector,
        totalFunding: startup.total_funding,
        totalRevenue: startup.total_revenue,
        registrationDate: startup.registration_date,
        founders: startup.founders || []
      }));
      
      return mappedData;
    } catch (error) {
      console.error('Error in getAllStartups:', error);
      return [];
    }
  },

  // Get all startups (for admin users)
  async getAllStartupsForAdmin() {
    console.log('Fetching all startups for admin...');
    try {
      const { data, error } = await supabase
        .from('startups')
        .select(`
          *,
          founders (*)
        `)
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Error fetching all startups:', error);
        return [];
      }
      
      console.log('All startups fetched successfully:', data?.length || 0);
      
      // Map database fields to frontend expected format
      const mappedData = (data || []).map(startup => ({
        id: startup.id,
        name: startup.name,
        investmentType: startup.investment_type,
        investmentValue: startup.investment_value,
        equityAllocation: startup.equity_allocation,
        currentValuation: startup.current_valuation,
        complianceStatus: startup.compliance_status,
        sector: startup.sector,
        totalFunding: startup.total_funding,
        totalRevenue: startup.total_revenue,
        registrationDate: startup.registration_date,
        founders: startup.founders || []
      }));
      
      return mappedData;
    } catch (error) {
      console.error('Error in getAllStartupsForAdmin:', error);
      return [];
    }
  },

  // Get startup by ID
  async getStartupById(id: number) {
    const { data, error } = await supabase
      .from('startups')
      .select(`
        *,
        founders (*)
      `)
      .eq('id', id)
      .single()

    if (error) throw error
    return data
  },

  // Update startup compliance status (for CA)
  async updateCompliance(startupId: number, status: string) {
    console.log(`Updating compliance for startup ${startupId} to ${status}`);
    try {
      const { data, error } = await supabase
        .from('startups')
        .update({ compliance_status: status })
        .eq('id', startupId)
        .select()
        .single()

      if (error) {
        console.error('Error updating compliance:', error);
        throw error;
      }
      
      console.log('Compliance updated successfully');
      return data;
    } catch (error) {
      console.error('Error in updateCompliance:', error);
      throw error;
    }
  },

  // Create startup
  async createStartup(startupData: {
    name: string
    investment_type: InvestmentType
    investment_value: number
    equity_allocation: number
    current_valuation: number
    sector: string
    total_funding: number
    total_revenue: number
    registration_date: string
    founders?: { name: string; email: string }[]
  }) {
    // Get current user ID
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      throw new Error('User not authenticated')
    }
    const { data: startup, error: startupError } = await supabase
      .from('startups')
      .insert({
        name: startupData.name,
        investment_type: startupData.investment_type,
        investment_value: startupData.investment_value,
        equity_allocation: startupData.equity_allocation,
        current_valuation: startupData.current_valuation,
        compliance_status: 'Pending',
        sector: startupData.sector,
        total_funding: startupData.total_funding,
        total_revenue: startupData.total_revenue,
        registration_date: startupData.registration_date,
        user_id: user.id
      })
      .select()
      .single()

    if (startupError) throw startupError

    // Add founders if provided
    if (startupData.founders && startupData.founders.length > 0) {
      const foundersData = startupData.founders.map(founder => ({
        startup_id: startup.id,
        name: founder.name,
        email: founder.email
      }))

      const { error: foundersError } = await supabase
        .from('founders')
        .insert(foundersData)

      if (foundersError) {
        console.error('Error adding founders:', foundersError)
      }
    }

    return startup
  },

  // Update startup
  async updateStartup(id: number, updates: any) {
    const { data, error } = await supabase
      .from('startups')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (error) throw error
    return data
  },

  // Update startup founders
  async updateStartupFounders(startupId: number, founders: { name: string; email: string }[]) {
    // Delete existing founders
    await supabase
      .from('founders')
      .delete()
      .eq('startup_id', startupId)

    // Add new founders
    if (founders.length > 0) {
      const foundersData = founders.map(founder => ({
        startup_id: startupId,
        name: founder.name,
        email: founder.email
      }))

      const { error } = await supabase
        .from('founders')
        .insert(foundersData)

      if (error) throw error
    }
  }
}

// Investment Management
export const investmentService = {
  // Get new investments
  async getNewInvestments() {
    console.log('Fetching new investments...');
    try {
      const { data, error } = await supabase
        .from('new_investments')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Error fetching new investments:', error);
        return [];
      }
      
      console.log('New investments fetched successfully:', data?.length || 0);
      
      // Map database fields to frontend expected format
      const mappedData = (data || []).map(investment => ({
        id: investment.id,
        name: investment.name,
        investmentType: investment.investment_type,
        investmentValue: investment.investment_value,
        equityAllocation: investment.equity_allocation,
        sector: investment.sector,
        totalFunding: investment.total_funding,
        totalRevenue: investment.total_revenue,
        registrationDate: investment.registration_date,
        pitchDeckUrl: investment.pitch_deck_url,
        pitchVideoUrl: investment.pitch_video_url,
        complianceStatus: investment.compliance_status
      }));
      
      return mappedData;
    } catch (error) {
      console.error('Error in getNewInvestments:', error);
      return [];
    }
  },

  // Create investment offer
  async createInvestmentOffer(offerData: {
    investor_email: string
    startup_name: string
    investment_id: number
    offer_amount: number
    equity_percentage: number
  }) {
    const { data, error } = await supabase
      .from('investment_offers')
      .insert({
        investor_email: offerData.investor_email,
        startup_name: offerData.startup_name,
        investment_id: offerData.investment_id,
        offer_amount: offerData.offer_amount,
        equity_percentage: offerData.equity_percentage,
        status: 'pending'
      })
      .select()
      .single()

    if (error) throw error
    return data
  },

  // Get user's investment offers
  async getUserOffers(userEmail: string) {
    const { data, error } = await supabase
      .from('investment_offers')
      .select(`
        *,
        investment:new_investments(*)
      `)
      .eq('investor_email', userEmail)
      .order('created_at', { ascending: false })

    if (error) throw error
    return data
  },

  // Update offer status
  async updateOfferStatus(offerId: number, status: OfferStatus) {
    const { data, error } = await supabase
      .from('investment_offers')
      .update({ status })
      .eq('id', offerId)
      .select()
      .single()

    if (error) throw error
    return data
  },

  // Get all investment offers (admin)
  async getAllInvestmentOffers() {
    console.log('Fetching all investment offers...');
    try {
      const { data, error } = await supabase
        .from('investment_offers')
        .select(`
          *,
          investment:new_investments(*)
        `)
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Error fetching investment offers:', error);
        return [];
      }
      
      console.log('Investment offers fetched successfully:', data?.length || 0);
      
      // Map database fields to frontend expected format
      const mappedData = (data || []).map(offer => ({
        id: offer.id,
        investorEmail: offer.investor_email,
        startupName: offer.startup_name,
        investment: offer.investment ? {
          id: offer.investment.id,
          name: offer.investment.name,
          investmentType: offer.investment.investment_type,
          investmentValue: offer.investment.investment_value,
          equityAllocation: offer.investment.equity_allocation,
          sector: offer.investment.sector,
          totalFunding: offer.investment.total_funding,
          totalRevenue: offer.investment.total_revenue,
          registrationDate: offer.investment.registration_date,
          pitchDeckUrl: offer.investment.pitch_deck_url,
          pitchVideoUrl: offer.investment.pitch_video_url,
          complianceStatus: offer.investment.compliance_status
        } : null,
        offerAmount: offer.offer_amount,
        equityPercentage: offer.equity_percentage,
        status: offer.status
      }));
      
      return mappedData;
    } catch (error) {
      console.error('Error in getAllInvestmentOffers:', error);
      return [];
    }
  }
}

// Verification function to check all table connections
export const verificationService = {
  // Get verification requests
  async getVerificationRequests() {
    console.log('Fetching verification requests...');
    try {
      const { data, error } = await supabase
        .from('verification_requests')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Error fetching verification requests:', error);
        return [];
      }
      
      console.log('Verification requests fetched successfully:', data?.length || 0);
      return data || [];
    } catch (error) {
      console.error('Error in getVerificationRequests:', error);
      return [];
    }
  },

  // Process verification request (approve/reject)
  async processVerification(requestId: number, status: 'approved' | 'rejected') {
    console.log(`Processing verification request ${requestId} with status ${status}`);
    try {
      // Get the verification request to find the startup
      const { data: request, error: requestError } = await supabase
        .from('verification_requests')
        .select('*')
        .eq('id', requestId)
        .single()

      if (requestError) {
        console.error('Error fetching verification request:', requestError);
        throw requestError;
      }

      // Update startup compliance status based on verification result
      const complianceStatus = status === 'approved' ? 'Compliant' : 'Non-Compliant';
      
      const { error: updateError } = await supabase
        .from('startups')
        .update({ compliance_status: complianceStatus })
        .eq('id', request.startup_id)

      if (updateError) {
        console.error('Error updating startup compliance:', updateError);
        throw updateError;
      }

      // Delete the verification request
      const { error: deleteError } = await supabase
        .from('verification_requests')
        .delete()
        .eq('id', requestId)

      if (deleteError) {
        console.error('Error deleting verification request:', deleteError);
        throw deleteError;
      }

      console.log('Verification processed successfully');
      return { success: true, status };
    } catch (error) {
      console.error('Error in processVerification:', error);
      throw error;
    }
  },

  // Create verification request
  async createVerificationRequest(requestData: {
    startup_id: number
    startup_name: string
  }) {
    const { data, error } = await supabase
      .from('verification_requests')
      .insert({
        startup_id: requestData.startup_id,
        startup_name: requestData.startup_name,
        request_date: new Date().toISOString().split('T')[0]
      })
      .select()
      .single()

    if (error) throw error
    return data
  },

  // Delete verification request
  async deleteVerificationRequest(requestId: number) {
    const { error } = await supabase
      .from('verification_requests')
      .delete()
      .eq('id', requestId)

    if (error) throw error
  },

  // Verify all table connections and column names
  async verifyDatabaseConnections() {
    console.log('Verifying database connections...');
    const results = {
      users: false,
      startups: false,
      founders: false,
      new_investments: false,
      investment_offers: false,
      verification_requests: false,
      startup_addition_requests: false,
      financial_records: false,
      employees: false
    };

    try {
      // Test users table
      const { data: users, error: usersError } = await supabase.from('users').select('count').limit(1);
      results.users = !usersError;
      console.log('Users table:', usersError ? '❌' : '✅');

      // Test startups table
      const { data: startups, error: startupsError } = await supabase.from('startups').select('count').limit(1);
      results.startups = !startupsError;
      console.log('Startups table:', startupsError ? '❌' : '✅');

      // Test founders table
      const { data: founders, error: foundersError } = await supabase.from('founders').select('count').limit(1);
      results.founders = !foundersError;
      console.log('Founders table:', foundersError ? '❌' : '✅');

      // Test new_investments table
      const { data: newInvestments, error: newInvestmentsError } = await supabase.from('new_investments').select('count').limit(1);
      results.new_investments = !newInvestmentsError;
      console.log('New investments table:', newInvestmentsError ? '❌' : '✅');

      // Test investment_offers table
      const { data: investmentOffers, error: investmentOffersError } = await supabase.from('investment_offers').select('count').limit(1);
      results.investment_offers = !investmentOffersError;
      console.log('Investment offers table:', investmentOffersError ? '❌' : '✅');

      // Test verification_requests table
      const { data: verificationRequests, error: verificationRequestsError } = await supabase.from('verification_requests').select('count').limit(1);
      results.verification_requests = !verificationRequestsError;
      console.log('Verification requests table:', verificationRequestsError ? '❌' : '✅');

      // Test startup_addition_requests table
      const { data: startupAdditionRequests, error: startupAdditionRequestsError } = await supabase.from('startup_addition_requests').select('count').limit(1);
      results.startup_addition_requests = !startupAdditionRequestsError;
      console.log('Startup addition requests table:', startupAdditionRequestsError ? '❌' : '✅');

      // Test financial_records table
      const { data: financialRecords, error: financialRecordsError } = await supabase.from('financial_records').select('count').limit(1);
      results.financial_records = !financialRecordsError;
      console.log('Financial records table:', financialRecordsError ? '❌' : '✅');

      // Test employees table
      const { data: employees, error: employeesError } = await supabase.from('employees').select('count').limit(1);
      results.employees = !employeesError;
      console.log('Employees table:', employeesError ? '❌' : '✅');

      const allConnected = Object.values(results).every(result => result);
      console.log(`Database verification complete: ${allConnected ? '✅ All tables connected' : '❌ Some tables failed'}`);
      
      return { success: allConnected, results };
    } catch (error) {
      console.error('Error verifying database connections:', error);
      return { success: false, error: error.message };
    }
  }
}

// Startup Addition Request Management
export const startupAdditionService = {
  // Accept startup addition request (move to startups table)
  async acceptStartupRequest(requestId: number) {
    console.log(`Accepting startup addition request ${requestId}`);
    try {
      // Get the request data
      const { data: request, error: requestError } = await supabase
        .from('startup_addition_requests')
        .select('*')
        .eq('id', requestId)
        .single()

      if (requestError) {
        console.error('Error fetching startup addition request:', requestError);
        throw requestError;
      }

      // Create new startup from the request
      const { data: startup, error: startupError } = await supabase
        .from('startups')
        .insert({
          name: request.name,
          investment_type: request.investment_type,
          investment_value: request.investment_value,
          equity_allocation: request.equity_allocation,
          current_valuation: request.investment_value * (100 / request.equity_allocation), // Estimate
          compliance_status: 'Pending',
          sector: request.sector,
          total_funding: request.total_funding,
          total_revenue: request.total_revenue,
          registration_date: request.registration_date
        })
        .select()
        .single()

      if (startupError) {
        console.error('Error creating startup:', startupError);
        throw startupError;
      }

      // Delete the request
      const { error: deleteError } = await supabase
        .from('startup_addition_requests')
        .delete()
        .eq('id', requestId)

      if (deleteError) {
        console.error('Error deleting startup addition request:', deleteError);
        throw deleteError;
      }

      console.log('Startup addition request accepted successfully');
      return startup;
    } catch (error) {
      console.error('Error in acceptStartupRequest:', error);
      throw error;
    }
  }
}

// Financial Records Management
export const financialService = {
  // Get startup financial records
  async getStartupFinancialRecords(startupId: number) {
    const { data, error } = await supabase
      .from('financial_records')
      .select('*')
      .eq('startup_id', startupId)
      .order('date', { ascending: false })

    if (error) throw error
    return data
  },

  // Add financial record
  async addFinancialRecord(recordData: {
    startup_id: number
    date: string
    entity: string
    description: string
    vertical: string
    amount: number
    funding_source?: string
    cogs?: number
    attachment_url?: string
  }) {
    const { data, error } = await supabase
      .from('financial_records')
      .insert(recordData)
      .select()
      .single()

    if (error) throw error
    return data
  }
}

// Employee Management
export const employeeService = {
  // Get startup employees
  async getStartupEmployees(startupId: number) {
    const { data, error } = await supabase
      .from('employees')
      .select('*')
      .eq('startup_id', startupId)
      .order('joining_date', { ascending: false })

    if (error) throw error
    return data
  },

  // Add employee
  async addEmployee(employeeData: {
    startup_id: number
    name: string
    joining_date: string
    entity: string
    department: string
    salary: number
    esop_allocation?: number
    allocation_type?: EsopAllocationType
    esop_per_allocation?: number
    contract_url?: string
  }) {
    const { data, error } = await supabase
      .from('employees')
      .insert(employeeData)
      .select()
      .single()

    if (error) throw error
    return data
  }
}

// Analytics and Reporting
export const analyticsService = {
  // Get user growth data
  async getUserGrowthData() {
    const { data, error } = await supabase
      .from('users')
      .select('registration_date, role')
      .order('registration_date', { ascending: true })

    if (error) throw error
    return data
  },

  // Get portfolio distribution by sector
  async getPortfolioDistribution() {
    const { data, error } = await supabase
      .from('startups')
      .select('sector')

    if (error) throw error
    return data
  },

  // Get compliance statistics
  async getComplianceStats() {
    const { data, error } = await supabase
      .from('startups')
      .select('compliance_status')

    if (error) throw error
    return data
  }
}

// Real-time subscriptions
export const realtimeService = {
  // Subscribe to new investment opportunities
  subscribeToNewInvestments(callback: (payload: any) => void) {
    return supabase
      .channel('new_investments')
      .on('postgres_changes', 
        { event: 'INSERT', schema: 'public', table: 'new_investments' },
        callback
      )
      .subscribe()
  },

  // Subscribe to investment offers
  subscribeToInvestmentOffers(callback: (payload: any) => void) {
    return supabase
      .channel('investment_offers')
      .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'investment_offers' },
        callback
      )
      .subscribe()
  },

  // Subscribe to verification requests
  subscribeToVerificationRequests(callback: (payload: any) => void) {
    return supabase
      .channel('verification_requests')
      .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'verification_requests' },
        callback
      )
      .subscribe()
  }
}
