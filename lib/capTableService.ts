import { supabase } from './supabase';
import { InvestmentRecord, InvestorType, InvestmentRoundType, Founder, FundraisingDetails, InvestmentType } from '../types';

export interface InvestmentSummary {
  total_equity_funding: number;
  total_debt_funding: number;
  total_grant_funding: number;
  total_investments: number;
  avg_equity_allocated: number;
}

export interface ValuationHistoryData {
  round_name: string;
  valuation: number;
  investment_amount: number;
  date: string;
}

export interface EquityDistributionData {
  holder_type: string;
  equity_percentage: number;
  total_amount: number;
}

export interface FundraisingStatus {
  active: boolean;
  type: string;
  value: number;
  equity: number;
  validation_requested: boolean;
  pitch_deck_url?: string;
  pitch_video_url?: string;
}

export interface InvestmentFilters {
  investorType?: InvestorType;
  investmentType?: InvestmentRoundType;
  dateFrom?: string;
  dateTo?: string;
}

class CapTableService {
  // =====================================================
  // INVESTMENT RECORDS CRUD
  // =====================================================

  async getInvestmentRecords(startupId: number, filters?: InvestmentFilters): Promise<InvestmentRecord[]> {
    let query = supabase
      .from('investment_records')
      .select('*')
      .eq('startup_id', startupId)
      .order('date', { ascending: false });

    if (filters?.investorType) {
      query = query.eq('investor_type', filters.investorType);
    }

    if (filters?.investmentType) {
      query = query.eq('investment_type', filters.investmentType);
    }

    if (filters?.dateFrom) {
      query = query.gte('date', filters.dateFrom);
    }

    if (filters?.dateTo) {
      query = query.lte('date', filters.dateTo);
    }

    const { data, error } = await query;
    if (error) throw error;

    return (data || []).map(record => ({
      id: record.id,
      date: record.date,
      investorType: record.investor_type as InvestorType,
      investmentType: record.investment_type as InvestmentRoundType,
      investorName: record.investor_name,
      investorCode: record.investor_code,
      amount: record.amount,
      equityAllocated: record.equity_allocated,
      preMoneyValuation: record.pre_money_valuation,
      proofUrl: record.proof_url
    }));
  }

  async addInvestmentRecord(startupId: number, investmentData: Omit<InvestmentRecord, 'id'>): Promise<InvestmentRecord> {
    console.log('Service: Adding investment record with data:', { startupId, investmentData });
    
    // Validate required fields
    if (!investmentData.date) {
      throw new Error('Date is required');
    }
    if (!investmentData.investorType) {
      throw new Error('Investor type is required');
    }
    if (!investmentData.investmentType) {
      throw new Error('Investment type is required');
    }
    if (!investmentData.investorName) {
      throw new Error('Investor name is required');
    }
    if (!investmentData.amount || investmentData.amount <= 0) {
      throw new Error('Valid investment amount is required');
    }
    if (!investmentData.equityAllocated || investmentData.equityAllocated < 0) {
      throw new Error('Valid equity allocation is required');
    }
    if (!investmentData.preMoneyValuation || investmentData.preMoneyValuation <= 0) {
      throw new Error('Valid pre-money valuation is required');
    }

    const { data, error } = await supabase
      .from('investment_records')
      .insert({
        startup_id: startupId,
        date: investmentData.date,
        investor_type: investmentData.investorType,
        investment_type: investmentData.investmentType,
        investor_name: investmentData.investorName,
        investor_code: investmentData.investorCode,
        amount: investmentData.amount,
        equity_allocated: investmentData.equityAllocated,
        pre_money_valuation: investmentData.preMoneyValuation,
        proof_url: investmentData.proofUrl
      })
      .select()
      .single();

    if (error) {
      console.error('Supabase error adding investment record:', error);
      throw error;
    }

    return {
      id: data.id,
      date: data.date,
      investorType: data.investor_type as InvestorType,
      investmentType: data.investment_type as InvestmentRoundType,
      investorName: data.investor_name,
      investorCode: data.investor_code,
      amount: data.amount,
      equityAllocated: data.equity_allocated,
      preMoneyValuation: data.pre_money_valuation,
      proofUrl: data.proof_url
    };
  }

  async updateInvestmentRecord(id: string, investmentData: Partial<InvestmentRecord>): Promise<InvestmentRecord> {
    const updateData: any = {};
    
    if (investmentData.date !== undefined) updateData.date = investmentData.date;
    if (investmentData.investorType !== undefined) updateData.investor_type = investmentData.investorType;
    if (investmentData.investmentType !== undefined) updateData.investment_type = investmentData.investmentType;
    if (investmentData.investorName !== undefined) updateData.investor_name = investmentData.investorName;
    if (investmentData.investorCode !== undefined) updateData.investor_code = investmentData.investorCode;
    if (investmentData.amount !== undefined) updateData.amount = investmentData.amount;
    if (investmentData.equityAllocated !== undefined) updateData.equity_allocated = investmentData.equityAllocated;
    if (investmentData.preMoneyValuation !== undefined) updateData.pre_money_valuation = investmentData.preMoneyValuation;
    if (investmentData.proofUrl !== undefined) updateData.proof_url = investmentData.proofUrl;

    const { data, error } = await supabase
      .from('investment_records')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      date: data.date,
      investorType: data.investor_type as InvestorType,
      investmentType: data.investment_type as InvestmentRoundType,
      investorName: data.investor_name,
      investorCode: data.investor_code,
      amount: data.amount,
      equityAllocated: data.equity_allocated,
      preMoneyValuation: data.pre_money_valuation,
      proofUrl: data.proof_url
    };
  }

  async deleteInvestmentRecord(id: string): Promise<void> {
    const { error } = await supabase
      .from('investment_records')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }

  // =====================================================
  // FOUNDERS CRUD
  // =====================================================

  async getFounders(startupId: number): Promise<Founder[]> {
    const { data, error } = await supabase
      .from('founders')
      .select('*')
      .eq('startup_id', startupId)
      .order('created_at', { ascending: true });

    if (error) throw error;

    return (data || []).map(founder => ({
      name: founder.name,
      email: founder.email
    }));
  }

  async updateFounders(startupId: number, founders: Founder[]): Promise<void> {
    // First, delete existing founders
    const { error: deleteError } = await supabase
      .from('founders')
      .delete()
      .eq('startup_id', startupId);

    if (deleteError) throw deleteError;

    // Then, insert new founders
    if (founders.length > 0) {
      const foundersData = founders.map(founder => ({
        startup_id: startupId,
        name: founder.name,
        email: founder.email
      }));

      const { error: insertError } = await supabase
        .from('founders')
        .insert(foundersData);

      if (insertError) throw insertError;
    }
  }

  async deleteAllFounders(startupId: number): Promise<void> {
    const { error } = await supabase
      .from('founders')
      .delete()
      .eq('startup_id', startupId);

    if (error) throw error;
  }

  async addFounder(startupId: number, founder: Founder): Promise<void> {
    const { error } = await supabase
      .from('founders')
      .insert({
        startup_id: startupId,
        name: founder.name,
        email: founder.email
      });

    if (error) throw error;
  }

  // =====================================================
  // FUNDRAISING DETAILS CRUD
  // =====================================================

  async getFundraisingDetails(startupId: number): Promise<FundraisingDetails[]> {
    const { data, error } = await supabase
      .from('fundraising_details')
      .select('*')
      .eq('startup_id', startupId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching fundraising details:', error);
      return [];
    }

    return (data || []).map(item => ({
      active: item.active,
      type: item.type as InvestmentType,
      value: item.value,
      equity: item.equity,
      validationRequested: item.validation_requested,
      pitchDeckUrl: item.pitch_deck_url,
      pitchVideoUrl: item.pitch_video_url
    }));
  }

  async updateFundraisingDetails(startupId: number, fundraisingData: FundraisingDetails): Promise<FundraisingDetails> {
    // Check if fundraising details exist
    const existing = await this.getFundraisingDetails(startupId);

    if (existing.length > 0) {
      // Update existing record
      const { data, error } = await supabase
        .from('fundraising_details')
        .update({
          active: fundraisingData.active,
          type: fundraisingData.type,
          value: fundraisingData.value,
          equity: fundraisingData.equity,
          validation_requested: fundraisingData.validationRequested,
          pitch_deck_url: fundraisingData.pitchDeckUrl,
          pitch_video_url: fundraisingData.pitchVideoUrl
        })
        .eq('startup_id', startupId)
        .select()
        .single();

      if (error) throw error;

      return {
        active: data.active,
        type: data.type as InvestmentType,
        value: data.value,
        equity: data.equity,
        validationRequested: data.validation_requested,
        pitchDeckUrl: data.pitch_deck_url,
        pitchVideoUrl: data.pitch_video_url
      };
    } else {
      // Insert new record
      const { data, error } = await supabase
        .from('fundraising_details')
        .insert({
          startup_id: startupId,
          active: fundraisingData.active,
          type: fundraisingData.type,
          value: fundraisingData.value,
          equity: fundraisingData.equity,
          validation_requested: fundraisingData.validationRequested,
          pitch_deck_url: fundraisingData.pitchDeckUrl,
          pitch_video_url: fundraisingData.pitchVideoUrl
        })
        .select()
        .single();

      if (error) throw error;

      return {
        active: data.active,
        type: data.type as InvestmentType,
        value: data.value,
        equity: data.equity,
        validationRequested: data.validation_requested,
        pitchDeckUrl: data.pitch_deck_url,
        pitchVideoUrl: data.pitch_video_url
      };
    }
  }

  // =====================================================
  // VALUATION HISTORY CRUD
  // =====================================================

  async getValuationHistory(startupId: number): Promise<ValuationHistoryData[]> {
    const { data, error } = await supabase
      .from('valuation_history')
      .select('*')
      .eq('startup_id', startupId)
      .order('date', { ascending: true });

    if (error) throw error;

    return (data || []).map(record => ({
      round_name: record.round_type,
      valuation: record.valuation,
      investment_amount: record.investment_amount,
      date: record.date
    }));
  }

  async addValuationRecord(startupId: number, valuationData: {
    date: string;
    valuation: number;
    roundType: string;
    investmentAmount?: number;
    notes?: string;
  }): Promise<void> {
    const { error } = await supabase
      .from('valuation_history')
      .insert({
        startup_id: startupId,
        date: valuationData.date,
        valuation: valuationData.valuation,
        round_type: valuationData.roundType,
        investment_amount: valuationData.investmentAmount || 0,
        notes: valuationData.notes
      });

    if (error) throw error;
  }

  // =====================================================
  // EQUITY HOLDINGS CRUD
  // =====================================================

  async getEquityHoldings(startupId: number): Promise<EquityDistributionData[]> {
    const { data, error } = await supabase
      .from('equity_holdings')
      .select('*')
      .eq('startup_id', startupId)
      .order('equity_percentage', { ascending: false });

    if (error) throw error;

    return (data || []).map(record => ({
      holder_type: record.holder_type,
      equity_percentage: record.equity_percentage,
      total_amount: 0 // This would need to be calculated from investment records
    }));
  }

  async updateEquityHoldings(startupId: number, equityData: {
    holderType: string;
    holderName: string;
    equityPercentage: number;
  }[]): Promise<void> {
    // First, delete existing equity holdings
    const { error: deleteError } = await supabase
      .from('equity_holdings')
      .delete()
      .eq('startup_id', startupId);

    if (deleteError) throw deleteError;

    // Then, insert new equity holdings
    if (equityData.length > 0) {
      const holdingsData = equityData.map(holding => ({
        startup_id: startupId,
        holder_type: holding.holderType,
        holder_name: holding.holderName,
        equity_percentage: holding.equityPercentage
      }));

      const { error: insertError } = await supabase
        .from('equity_holdings')
        .insert(holdingsData);

      if (insertError) throw insertError;
    }
  }

  // =====================================================
  // ANALYTICS AND SUMMARY FUNCTIONS
  // =====================================================

  async getInvestmentSummary(startupId: number): Promise<InvestmentSummary> {
    try {
      const { data, error } = await supabase.rpc('get_investment_summary', {
        p_startup_id: startupId
      });

      if (error) {
        console.log('❌ Error calling get_investment_summary RPC, using manual calculation');
        return this.calculateInvestmentSummaryManually(startupId);
      }

      return data[0] || {
        total_equity_funding: 0,
        total_debt_funding: 0,
        total_grant_funding: 0,
        total_investments: 0,
        avg_equity_allocated: 0
      };
    } catch (error) {
      console.log('🔄 Falling back to manual calculation for investment summary');
      return this.calculateInvestmentSummaryManually(startupId);
    }
  }

  async getValuationHistoryData(startupId: number): Promise<ValuationHistoryData[]> {
    try {
      const { data, error } = await supabase.rpc('get_valuation_history', {
        p_startup_id: startupId
      });

      if (error) {
        console.log('❌ Error calling get_valuation_history RPC, using manual calculation');
        return this.calculateValuationHistoryManually(startupId);
      }

      return data || [];
    } catch (error) {
      console.log('🔄 Falling back to manual calculation for valuation history');
      return this.calculateValuationHistoryManually(startupId);
    }
  }

  async getEquityDistributionData(startupId: number): Promise<EquityDistributionData[]> {
    try {
      const { data, error } = await supabase.rpc('get_equity_distribution', {
        p_startup_id: startupId
      });

      if (error) {
        console.log('❌ Error calling get_equity_distribution RPC, using manual calculation');
        return this.calculateEquityDistributionManually(startupId);
      }

      return data || [];
    } catch (error) {
      console.log('🔄 Falling back to manual calculation for equity distribution');
      return this.calculateEquityDistributionManually(startupId);
    }
  }

  async getFundraisingStatus(startupId: number): Promise<FundraisingStatus | null> {
    try {
      const { data, error } = await supabase.rpc('get_fundraising_status', {
        p_startup_id: startupId
      });

      if (error) {
        console.log('❌ Error calling get_fundraising_status RPC, using direct query');
        return this.getFundraisingDetails(startupId);
      }

      return data[0] || null;
    } catch (error) {
      console.log('🔄 Falling back to direct query for fundraising status');
      return this.getFundraisingDetails(startupId);
    }
  }

  // =====================================================
  // MANUAL CALCULATION FALLBACKS
  // =====================================================

  private async calculateInvestmentSummaryManually(startupId: number): Promise<InvestmentSummary> {
    const investments = await this.getInvestmentRecords(startupId);
    
    const total_equity_funding = investments
      .filter(inv => inv.investmentType === InvestmentRoundType.Equity)
      .reduce((sum, inv) => sum + inv.amount, 0);
    
    const total_debt_funding = investments
      .filter(inv => inv.investmentType === InvestmentRoundType.Debt)
      .reduce((sum, inv) => sum + inv.amount, 0);
    
    const total_grant_funding = investments
      .filter(inv => inv.investmentType === InvestmentRoundType.Grant)
      .reduce((sum, inv) => sum + inv.amount, 0);
    
    const total_investments = investments.length;
    const avg_equity_allocated = total_investments > 0 
      ? investments.reduce((sum, inv) => sum + inv.equityAllocated, 0) / total_investments 
      : 0;
    
    return {
      total_equity_funding,
      total_debt_funding,
      total_grant_funding,
      total_investments,
      avg_equity_allocated
    };
  }

  private async calculateValuationHistoryManually(startupId: number): Promise<ValuationHistoryData[]> {
    const investments = await this.getInvestmentRecords(startupId);
    
    // Group investments by date and calculate cumulative valuation
    const valuationMap = new Map<string, { valuation: number; investment: number }>();
    
    investments.forEach(inv => {
      const existing = valuationMap.get(inv.date) || { valuation: 0, investment: 0 };
      valuationMap.set(inv.date, {
        valuation: existing.valuation + inv.preMoneyValuation,
        investment: existing.investment + inv.amount
      });
    });
    
    return Array.from(valuationMap.entries()).map(([date, data]) => ({
      round_name: 'Investment Round',
      valuation: data.valuation,
      investment_amount: data.investment,
      date
    })).sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
  }

  private async calculateEquityDistributionManually(startupId: number): Promise<EquityDistributionData[]> {
    const investments = await this.getInvestmentRecords(startupId);
    const founders = await this.getFounders(startupId);
    
    const distribution: EquityDistributionData[] = [];
    
    // Add founders (assuming equal distribution if not specified)
    if (founders.length > 0) {
      const founderEquity = 100 - investments.reduce((sum, inv) => sum + inv.equityAllocated, 0);
      const equityPerFounder = founderEquity / founders.length;
      
      founders.forEach(founder => {
        distribution.push({
          holder_type: 'Founder',
          equity_percentage: equityPerFounder,
          total_amount: 0
        });
      });
    }
    
    // Add investors
    investments.forEach(inv => {
      distribution.push({
        holder_type: 'Investor',
        equity_percentage: inv.equityAllocated,
        total_amount: inv.amount
      });
    });
    
    return distribution.sort((a, b) => b.equity_percentage - a.equity_percentage);
  }

  // =====================================================
  // UTILITY FUNCTIONS
  // =====================================================

  async getInvestorTypes(): Promise<string[]> {
    return Object.values(InvestorType);
  }

  async getInvestmentTypes(): Promise<string[]> {
    return Object.values(InvestmentRoundType);
  }

  async getInvestmentRounds(): Promise<string[]> {
    return Object.values(InvestmentType);
  }

  // =====================================================
  // FILE UPLOAD HELPERS
  // =====================================================

  async uploadProofDocument(startupId: number, file: File): Promise<string> {
    const fileName = `${startupId}/investment-proofs/${Date.now()}_${file.name}`;
    const { data, error } = await supabase.storage
      .from('cap-table-documents')
      .upload(fileName, file);

    if (error) throw error;

    const { data: urlData } = supabase.storage
      .from('cap-table-documents')
      .getPublicUrl(fileName);

    return urlData.publicUrl;
  }

  async uploadPitchDeck(file: File, startupId: number): Promise<string> {
    const fileName = `${startupId}/pitch-decks/${Date.now()}_${file.name}`;
    const { data, error } = await supabase.storage
      .from('cap-table-documents')
      .upload(fileName, file);

    if (error) throw error;

    const { data: urlData } = supabase.storage
      .from('cap-table-documents')
      .getPublicUrl(fileName);

    return urlData.publicUrl;
  }

  async getAttachmentDownloadUrl(url: string): Promise<string> {
    // If it's already a public URL, return it
    if (url.startsWith('http')) {
      return url;
    }

    // Extract file path from storage URL
    const filePath = this.extractFilePathFromUrl(url);
    if (!filePath) {
      throw new Error('Invalid file URL');
    }

    const { data } = supabase.storage
      .from('cap-table-documents')
      .getPublicUrl(filePath);

    return data.publicUrl;
  }

  private extractFilePathFromUrl(url: string): string | null {
    // Handle different URL formats
    if (url.includes('/storage/v1/object/public/')) {
      return url.split('/storage/v1/object/public/')[1];
    }
    if (url.includes('/storage/v1/object/sign/')) {
      return url.split('/storage/v1/object/sign/')[1];
    }
    return null;
  }

  // =====================================================
  // REAL-TIME SUBSCRIPTIONS
  // =====================================================

  subscribeToInvestmentRecords(startupId: number, callback: (records: InvestmentRecord[]) => void) {
    const channel = supabase
      .channel('investment_records_changes')
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'investment_records',
        filter: `startup_id=eq.${startupId}`
      }, async () => {
        try {
          const records = await this.getInvestmentRecords(startupId);
          callback(records);
        } catch (e) {
          console.warn('Failed to refresh investment records after realtime event:', e);
        }
      })
      .subscribe();
    return channel;
  }

  subscribeToFounders(startupId: number, callback: (founders: Founder[]) => void) {
    const channel = supabase
      .channel('founders_changes')
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'founders',
        filter: `startup_id=eq.${startupId}`
      }, async () => {
        try {
          const founders = await this.getFounders(startupId);
          callback(founders);
        } catch (e) {
          console.warn('Failed to refresh founders after realtime event:', e);
        }
      })
      .subscribe();
    return channel;
  }

  subscribeToFundraisingDetails(startupId: number, callback: (details: FundraisingDetails[]) => void) {
    const channel = supabase
      .channel('fundraising_details_changes')
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'fundraising_details',
        filter: `startup_id=eq.${startupId}`
      }, async () => {
        try {
          const details = await this.getFundraisingDetails(startupId);
          callback(details);
        } catch (e) {
          console.warn('Failed to refresh fundraising details after realtime event:', e);
        }
      })
      .subscribe();
    return channel;
  }

  async addFundraisingDetails(startupId: number, fundraisingData: FundraisingDetails): Promise<FundraisingDetails> {
    const { data, error } = await supabase
      .from('fundraising_details')
      .insert({
        startup_id: startupId,
        active: fundraisingData.active,
        type: fundraisingData.type,
        value: fundraisingData.value,
        equity: fundraisingData.equity,
        validation_requested: fundraisingData.validationRequested,
        pitch_deck_url: fundraisingData.pitchDeckUrl,
        pitch_video_url: fundraisingData.pitchVideoUrl
      })
      .select()
      .single();

    if (error) throw error;

    return {
      active: data.active,
      type: data.type as InvestmentType,
      value: data.value,
      equity: data.equity,
      validationRequested: data.validation_requested,
      pitchDeckUrl: data.pitch_deck_url,
      pitchVideoUrl: data.pitch_video_url
    };
  }

  // Expose supabase client for direct subscriptions
  get supabase() {
    return supabase;
  }
}

export const capTableService = new CapTableService();
