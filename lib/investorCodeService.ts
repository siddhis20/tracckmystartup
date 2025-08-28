import { supabase } from './supabase';
import { InvestmentRecord } from '../types';

export interface InvestorInvestment {
  id: string;
  startupId: number;
  startupName: string;
  date: string;
  investorType: string;
  investmentType: string;
  investorName: string;
  investorCode: string;
  amount: number;
  equityAllocated: number;
  preMoneyValuation: number;
  proofUrl?: string;
  createdAt: string;
}

class InvestorCodeService {
  // Generate a unique investor code
  generateInvestorCode(): string {
    const prefix = 'INV';
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substring(2, 8).toUpperCase();
    return `${prefix}-${timestamp}-${random}`;
  }

  // Get investments for a specific investor code
  async getInvestmentsByCode(investorCode: string): Promise<InvestorInvestment[]> {
    try {
      console.log('🔍 Service: Fetching investments for investor code:', investorCode);
      
      const { data, error } = await supabase
        .from('investment_records')
        .select(`
          *,
          startups (
            id,
            name
          )
        `)
        .eq('investor_code', investorCode)
        .order('created_at', { ascending: false });

      if (error) {
        console.error('❌ Service: Error fetching investments by investor code:', error);
        return [];
      }

      console.log('🔍 Service: Raw data from Supabase:', data);
      console.log('🔍 Service: Investments fetched successfully:', data?.length || 0);
      
      const mappedData = (data || []).map(item => ({
        id: item.id,
        startupId: item.startup_id,
        startupName: item.startups?.name || 'Unknown Startup',
        date: item.date,
        investorType: item.investor_type,
        investmentType: item.investment_type,
        investorName: item.investor_name,
        investorCode: item.investor_code,
        amount: item.amount,
        equityAllocated: item.equity_allocated,
        preMoneyValuation: item.pre_money_valuation,
        proofUrl: item.proof_url,
        createdAt: item.created_at
      }));
      
      console.log('🔍 Service: Mapped investments:', mappedData);
      return mappedData;
    } catch (error) {
      console.error('❌ Service: Error in getInvestmentsByCode:', error);
      return [];
    }
  }

  // Get investment summary for an investor code
  async getInvestmentSummary(investorCode: string) {
    try {
      const investments = await this.getInvestmentsByCode(investorCode);
      
      const totalInvested = investments.reduce((sum, inv) => sum + inv.amount, 0);
      const totalEquity = investments.reduce((sum, inv) => sum + inv.equityAllocated, 0);
      const uniqueStartups = new Set(investments.map(inv => inv.startupId)).size;
      
      return {
        totalInvestments: investments.length,
        totalAmountInvested: totalInvested,
        totalEquityOwned: totalEquity,
        uniqueStartups: uniqueStartups,
        averageInvestment: investments.length > 0 ? totalInvested / investments.length : 0
      };
    } catch (error) {
      console.error('Error getting investment summary:', error);
      return {
        totalInvestments: 0,
        totalAmountInvested: 0,
        totalEquityOwned: 0,
        uniqueStartups: 0,
        averageInvestment: 0
      };
    }
  }

  // Update user's investor code
  async updateUserInvestorCode(userId: string, investorCode: string): Promise<void> {
    try {
      console.log('Updating investor code for user:', userId, investorCode);
      
      const { error } = await supabase
        .from('users')
        .update({ investor_code: investorCode })
        .eq('id', userId);

      if (error) {
        console.error('Error updating user investor code:', error);
        throw error;
      }

      console.log('Investor code updated successfully');
    } catch (error) {
      console.error('Error in updateUserInvestorCode:', error);
      throw error;
    }
  }

  // Get user's investor code
  async getUserInvestorCode(userId: string): Promise<string | null> {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('investor_code')
        .eq('id', userId)
        .single();

      if (error) {
        console.error('Error fetching user investor code:', error);
        return null;
      }

      return data?.investor_code || null;
    } catch (error) {
      console.error('Error in getUserInvestorCode:', error);
      return null;
    }
  }

  // Validate investor code format
  validateInvestorCode(code: string): boolean {
    // Format: INV-{timestamp}-{random}
    const pattern = /^INV-[a-z0-9]+-[A-Z0-9]{6}$/;
    return pattern.test(code);
  }
}

export const investorCodeService = new InvestorCodeService();
