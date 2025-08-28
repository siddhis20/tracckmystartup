import { supabase } from './supabase';
import { NewInvestment, InvestmentType, ComplianceStatus } from '../types';

export interface ActiveFundraisingStartup {
  id: number;
  name: string;
  sector: string;
  investmentValue: number;
  equityAllocation: number;
  complianceStatus: ComplianceStatus;
  pitchDeckUrl?: string;
  pitchVideoUrl?: string;
  fundraisingType: InvestmentType;
  description?: string;
  createdAt: string;
  fundraisingId: string; // UUID of the fundraising_details record
  isStartupNationValidated: boolean;
  validationDate?: string;
}

class InvestorService {
    // Fetch all active fundraising startups with their pitch data
  async getActiveFundraisingStartups(): Promise<ActiveFundraisingStartup[]> {
    try {
      const { data, error } = await supabase
        .from('fundraising_details')
        .select(`
          *,
          startups (
            id,
            name,
            sector,
            compliance_status,
            startup_nation_validated,
            validation_date,
            created_at
          )
        `)
        .eq('active', true)
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Error fetching active fundraising startups:', error);
        return [];
      }

      if (error) {
        console.error('Error fetching active fundraising startups:', error);
        return [];
      }

      const filteredData = (data || []).filter(item => item.startups !== null);

      // Show ALL active fundraising startups, but mark their validation status
      return filteredData.map(item => ({
        id: item.startups.id,
        name: item.startups.name,
        sector: item.startups.sector || 'Technology',
        investmentValue: item.value,
        equityAllocation: item.equity,
        complianceStatus: item.startups.compliance_status as ComplianceStatus,
        pitchDeckUrl: item.pitch_deck_url,
        pitchVideoUrl: item.pitch_video_url,
        fundraisingType: item.type as InvestmentType,
        description: item.startups.description || `${item.startups.name} - ${item.startups.sector || 'Technology'} startup`,
        createdAt: item.startups.created_at,
        fundraisingId: item.id,
        isStartupNationValidated: item.startups.startup_nation_validated || false,
        validationDate: item.startups.validation_date
      }));
    } catch (error) {
      console.error('Error in getActiveFundraisingStartups:', error);
      return [];
    }
  }

  // Fetch startup details for a specific startup
  async getStartupDetails(startupId: number): Promise<ActiveFundraisingStartup | null> {
    try {
      const { data, error } = await supabase
        .from('fundraising_details')
        .select(`
          *,
          startups (
            id,
            name,
            sector,
            compliance_status,
            created_at
          )
        `)
        .eq('startup_id', startupId)
        .eq('active', true)
        .single();

      if (error || !data) {
        console.error('Error fetching startup details:', error);
        return null;
      }

      return {
        id: data.startups.id,
        name: data.startups.name,
        sector: data.startups.sector || 'Technology',
        investmentValue: data.value,
        equityAllocation: data.equity,
        complianceStatus: data.startups.compliance_status as ComplianceStatus,
        pitchDeckUrl: data.pitch_deck_url,
        pitchVideoUrl: data.pitch_video_url,
        fundraisingType: data.type as InvestmentType,
        description: data.startups.description || `${data.startups.name} - ${data.startups.sector || 'Technology'} startup`,
        createdAt: data.startups.created_at,
        fundraisingId: data.id,
        isStartupNationValidated: data.startups.startup_nation_validated || false,
        validationDate: data.startups.validation_date
      };
    } catch (error) {
      console.error('Error in getStartupDetails:', error);
      return null;
    }
  }

  // Get YouTube embed URL from various YouTube URL formats
  getYoutubeEmbedUrl(url?: string): string | null {
    if (!url) return null;
    
    // Handle various YouTube URL formats
    const patterns = [
      // YouTube watch URLs: youtube.com/watch?v=VIDEO_ID
      /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]+)/,
      // YouTube watch URLs with additional parameters: youtube.com/watch?param=value&v=VIDEO_ID
      /youtube\.com\/watch\?.*v=([a-zA-Z0-9_-]+)/,
      // YouTube Shorts URLs: youtube.com/shorts/VIDEO_ID
      /youtube\.com\/shorts\/([a-zA-Z0-9_-]+)/
    ];
    
    for (const pattern of patterns) {
      const match = url.match(pattern);
      if (match) {
        return `https://www.youtube.com/embed/${match[1]}`;
      }
    }
    
    return null;
  }

  // Format currency for display
  formatCurrency(amount: number): string {
    if (amount >= 1000000) {
      return `$${(amount / 1000000).toFixed(1)}M`;
    } else if (amount >= 1000) {
      return `$${(amount / 1000).toFixed(1)}K`;
    } else {
      return `$${amount.toLocaleString()}`;
    }
  }
}

export const investorService = new InvestorService();
