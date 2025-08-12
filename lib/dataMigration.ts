import { supabase } from './supabase'
import { mockStartups, mockNewInvestments, mockStartupAdditionRequests, mockUsers, mockVerificationRequests, mockInvestmentOffers } from '../constants'
import { InvestmentType, ComplianceStatus } from '../types'

export const dataMigrationService = {
  // Check if data already exists
  async checkDataExists(): Promise<boolean> {
    try {
      const { data: startups } = await supabase
        .from('startups')
        .select('id')
        .limit(1)
      
      return (startups && startups.length > 0)
    } catch (error) {
      console.error('Error checking data existence:', error)
      return false
    }
  },

  // Migrate all mock data to Supabase
  async migrateAllData() {
    console.log('Starting data migration...')
    
    // Check if data already exists
    const dataExists = await this.checkDataExists()
    if (dataExists) {
      console.log('Data already exists, skipping migration')
      return { success: true, error: null, message: 'Data already exists' }
    }
    
    try {
      // Migrate users first (if they don't exist)
      await this.migrateUsers()
      
      // Migrate startups
      await this.migrateStartups()
      
      // Migrate new investments
      await this.migrateNewInvestments()
      
      // Migrate startup addition requests
      await this.migrateStartupAdditionRequests()
      
      // Migrate verification requests
      await this.migrateVerificationRequests()
      
      // Migrate investment offers
      await this.migrateInvestmentOffers()
      
      console.log('Data migration completed successfully!')
      return { success: true, error: null, message: 'Data migration completed successfully' }
    } catch (error) {
      console.error('Data migration failed:', error)
      return { success: false, error: error.message, message: 'Data migration failed' }
    }
  },

  // Migrate users
  async migrateUsers() {
    console.log('Migrating users...')
    
    for (const mockUser of mockUsers) {
      try {
        // Check if user already exists
        const { data: existingUser } = await supabase
          .from('users')
          .select('id')
          .eq('email', mockUser.email)
          .single()

        if (!existingUser) {
          // Create user profile (without auth user for now)
          const { error } = await supabase
            .from('users')
            .insert({
              id: mockUser.id,
              email: mockUser.email,
              name: mockUser.name,
              role: mockUser.role,
              registration_date: mockUser.registrationDate
            })

          if (error) {
            console.error(`Failed to migrate user ${mockUser.email}:`, error)
          } else {
            console.log(`Migrated user: ${mockUser.email}`)
          }
        }
      } catch (error) {
        console.error(`Error migrating user ${mockUser.email}:`, error)
      }
    }
  },

  // Migrate startups
  async migrateStartups() {
    console.log('Migrating startups...')
    
    for (const mockStartup of mockStartups) {
      try {
        // Check if startup already exists
        const { data: existingStartup } = await supabase
          .from('startups')
          .select('id')
          .eq('name', mockStartup.name)
          .single()

        if (!existingStartup) {
          // Create startup
          const { data: startup, error: startupError } = await supabase
            .from('startups')
            .insert({
              id: mockStartup.id,
              name: mockStartup.name,
              investment_type: mockStartup.investmentType,
              investment_value: mockStartup.investmentValue,
              equity_allocation: mockStartup.equityAllocation,
              current_valuation: mockStartup.currentValuation,
              compliance_status: mockStartup.complianceStatus,
              sector: mockStartup.sector,
              total_funding: mockStartup.totalFunding,
              total_revenue: mockStartup.totalRevenue,
              registration_date: mockStartup.registrationDate
            })
            .select()
            .single()

          if (startupError) {
            console.error(`Failed to migrate startup ${mockStartup.name}:`, startupError)
          } else {
            console.log(`Migrated startup: ${mockStartup.name}`)
            
            // Add founders if they exist
            if (mockStartup.founders && mockStartup.founders.length > 0) {
              const foundersData = mockStartup.founders.map(founder => ({
                startup_id: startup.id,
                name: founder.name,
                email: founder.email
              }))

              const { error: foundersError } = await supabase
                .from('founders')
                .insert(foundersData)

              if (foundersError) {
                console.error(`Failed to migrate founders for ${mockStartup.name}:`, foundersError)
              } else {
                console.log(`Migrated ${mockStartup.founders.length} founders for ${mockStartup.name}`)
              }
            }
          }
        }
      } catch (error) {
        console.error(`Error migrating startup ${mockStartup.name}:`, error)
      }
    }
  },

  // Migrate new investments
  async migrateNewInvestments() {
    console.log('Migrating new investments...')
    
    for (const mockInvestment of mockNewInvestments) {
      try {
        // Check if investment already exists
        const { data: existingInvestment } = await supabase
          .from('new_investments')
          .select('id')
          .eq('name', mockInvestment.name)
          .single()

        if (!existingInvestment) {
          // Create new investment
          const { error } = await supabase
            .from('new_investments')
            .insert({
              id: mockInvestment.id,
              name: mockInvestment.name,
              investment_type: mockInvestment.investmentType,
              investment_value: mockInvestment.investmentValue,
              equity_allocation: mockInvestment.equityAllocation,
              sector: mockInvestment.sector,
              total_funding: mockInvestment.totalFunding,
              total_revenue: mockInvestment.totalRevenue,
              registration_date: mockInvestment.registrationDate,
              pitch_deck_url: mockInvestment.pitchDeckUrl,
              pitch_video_url: mockInvestment.pitchVideoUrl,
              compliance_status: mockInvestment.complianceStatus
            })

          if (error) {
            console.error(`Failed to migrate investment ${mockInvestment.name}:`, error)
          } else {
            console.log(`Migrated investment: ${mockInvestment.name}`)
          }
        }
      } catch (error) {
        console.error(`Error migrating investment ${mockInvestment.name}:`, error)
      }
    }
  },

  // Migrate startup addition requests
  async migrateStartupAdditionRequests() {
    console.log('Migrating startup addition requests...')
    
    for (const mockRequest of mockStartupAdditionRequests) {
      try {
        // Check if request already exists
        const { data: existingRequest } = await supabase
          .from('startup_addition_requests')
          .select('id')
          .eq('name', mockRequest.name)
          .single()

        if (!existingRequest) {
          // Create startup addition request
          const { error } = await supabase
            .from('startup_addition_requests')
            .insert({
              id: mockRequest.id,
              name: mockRequest.name,
              investment_type: mockRequest.investmentType,
              investment_value: mockRequest.investmentValue,
              equity_allocation: mockRequest.equityAllocation,
              sector: mockRequest.sector,
              total_funding: mockRequest.totalFunding,
              total_revenue: mockRequest.totalRevenue,
              registration_date: mockRequest.registrationDate
            })

          if (error) {
            console.error(`Failed to migrate request ${mockRequest.name}:`, error)
          } else {
            console.log(`Migrated request: ${mockRequest.name}`)
          }
        }
      } catch (error) {
        console.error(`Error migrating request ${mockRequest.name}:`, error)
      }
    }
  },

  // Migrate verification requests
  async migrateVerificationRequests() {
    console.log('Migrating verification requests...')
    
    for (const mockRequest of mockVerificationRequests) {
      try {
        // Check if request already exists
        const { data: existingRequest } = await supabase
          .from('verification_requests')
          .select('id')
          .eq('startup_name', mockRequest.startupName)
          .single()

        if (!existingRequest) {
          // Create verification request
          const { error } = await supabase
            .from('verification_requests')
            .insert({
              id: mockRequest.id,
              startup_id: mockRequest.startupId,
              startup_name: mockRequest.startupName,
              request_date: mockRequest.requestDate
            })

          if (error) {
            console.error(`Failed to migrate verification request for ${mockRequest.startupName}:`, error)
          } else {
            console.log(`Migrated verification request: ${mockRequest.startupName}`)
          }
        }
      } catch (error) {
        console.error(`Error migrating verification request for ${mockRequest.startupName}:`, error)
      }
    }
  },

  // Migrate investment offers
  async migrateInvestmentOffers() {
    console.log('Migrating investment offers...')
    
    for (const mockOffer of mockInvestmentOffers) {
      try {
        // Check if offer already exists
        const { data: existingOffer } = await supabase
          .from('investment_offers')
          .select('id')
          .eq('investor_email', mockOffer.investorEmail)
          .eq('startup_name', mockOffer.startupName)
          .single()

        if (!existingOffer) {
          // Create investment offer
          const { error } = await supabase
            .from('investment_offers')
            .insert({
              id: mockOffer.id,
              investor_email: mockOffer.investorEmail,
              startup_name: mockOffer.startupName,
              investment_id: mockOffer.investment.id,
              offer_amount: mockOffer.offerAmount,
              equity_percentage: mockOffer.equityPercentage,
              status: mockOffer.status
            })

          if (error) {
            console.error(`Failed to migrate offer for ${mockOffer.startupName}:`, error)
          } else {
            console.log(`Migrated investment offer: ${mockOffer.startupName}`)
          }
        }
      } catch (error) {
        console.error(`Error migrating investment offer for ${mockOffer.startupName}:`, error)
      }
    }
  },

  // Clear all data
  async clearAllData() {
    console.log('Clearing all data...')
    
    try {
      // Delete in reverse order to respect foreign key constraints
      await supabase.from('investment_offers').delete().neq('id', 0)
      await supabase.from('verification_requests').delete().neq('id', 0)
      await supabase.from('startup_addition_requests').delete().neq('id', 0)
      await supabase.from('new_investments').delete().neq('id', 0)
      await supabase.from('founders').delete().neq('id', 0)
      await supabase.from('startups').delete().neq('id', 0)
      // Don't delete users as they might be authenticated users
      
      console.log('All data cleared successfully!')
      return { success: true, error: null }
    } catch (error) {
      console.error('Error clearing data:', error)
      return { success: false, error: error.message }
    }
  }
}
