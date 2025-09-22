// Co-Investment Service
// Handles all co-investment opportunity operations

export interface CoInvestmentOpportunity {
  id: number;
  startupId: number;
  startupName: string;
  startupSector: string;
  startupStage: string;
  listedByUserId: string; // UUID
  listedByName: string;
  listedByType: 'Investor' | 'Investment Advisor';
  investmentAmount: number;
  equityPercentage?: number;
  minimumCoInvestment?: number;
  maximumCoInvestment?: number;
  description?: string;
  status: 'active' | 'inactive' | 'completed' | 'cancelled';
  createdAt: string;
}

export interface CoInvestmentInterest {
  id: number;
  opportunityId: number;
  interestedUserId: string; // UUID
  interestedUserType: 'Investor' | 'Investment Advisor';
  message?: string;
  status: 'pending' | 'approved' | 'rejected' | 'withdrawn';
  createdAt: string;
}

export interface CoInvestmentApproval {
  id: number;
  opportunityId: number;
  advisorId: string; // UUID
  investorId: string; // UUID
  approved: boolean;
  approvalNotes?: string;
  createdAt: string;
}

class CoInvestmentService {
  private baseUrl: string;

  constructor() {
    this.baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
  }

  // Create a new co-investment opportunity
  async createOpportunity(opportunityData: {
    startupId: number;
    listedByUserId: string; // UUID
    listedByType: 'Investor' | 'Investment Advisor';
    investmentAmount: number;
    equityPercentage?: number;
    minimumCoInvestment?: number;
    maximumCoInvestment?: number;
    description?: string;
  }): Promise<number> {
    try {
      const response = await fetch('/api/co-investment/create-opportunity', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(opportunityData),
      });

      if (!response.ok) {
        throw new Error('Failed to create co-investment opportunity');
      }

      const result = await response.json();
      return result.opportunityId;
    } catch (error) {
      console.error('Error creating co-investment opportunity:', error);
      throw error;
    }
  }

  // Get co-investment opportunities for a specific user
  async getOpportunitiesForUser(userId: string): Promise<CoInvestmentOpportunity[]> {
    try {
      const response = await fetch(`/api/co-investment/opportunities/${userId}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error('Failed to fetch co-investment opportunities');
      }

      const result = await response.json();
      return result.opportunities;
    } catch (error) {
      console.error('Error fetching co-investment opportunities:', error);
      throw error;
    }
  }

  // Get all co-investment opportunities (for investment advisors)
  async getAllOpportunities(): Promise<CoInvestmentOpportunity[]> {
    try {
      const response = await fetch('/api/co-investment/opportunities', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error('Failed to fetch all co-investment opportunities');
      }

      const result = await response.json();
      return result.opportunities;
    } catch (error) {
      console.error('Error fetching all co-investment opportunities:', error);
      throw error;
    }
  }

  // Express interest in a co-investment opportunity
  async expressInterest(interestData: {
    opportunityId: number;
    interestedUserId: string; // UUID
    interestedUserType: 'Investor' | 'Investment Advisor';
    message?: string;
  }): Promise<number> {
    try {
      const response = await fetch('/api/co-investment/express-interest', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(interestData),
      });

      if (!response.ok) {
        throw new Error('Failed to express interest in co-investment opportunity');
      }

      const result = await response.json();
      return result.interestId;
    } catch (error) {
      console.error('Error expressing interest in co-investment opportunity:', error);
      throw error;
    }
  }

  // Approve/reject co-investment interest (for investment advisors)
  async approveInterest(approvalData: {
    opportunityId: number;
    advisorId: string; // UUID
    investorId: string; // UUID
    approved: boolean;
    approvalNotes?: string;
  }): Promise<number> {
    try {
      const response = await fetch('/api/co-investment/approve-interest', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(approvalData),
      });

      if (!response.ok) {
        throw new Error('Failed to approve/reject co-investment interest');
      }

      const result = await response.json();
      return result.approvalId;
    } catch (error) {
      console.error('Error approving/rejecting co-investment interest:', error);
      throw error;
    }
  }

  // Update opportunity status
  async updateOpportunityStatus(opportunityId: number, status: 'active' | 'inactive' | 'completed' | 'cancelled'): Promise<void> {
    try {
      const response = await fetch(`/api/co-investment/opportunity/${opportunityId}/status`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ status }),
      });

      if (!response.ok) {
        throw new Error('Failed to update opportunity status');
      }
    } catch (error) {
      console.error('Error updating opportunity status:', error);
      throw error;
    }
  }

  // Get interests for a specific opportunity
  async getOpportunityInterests(opportunityId: number): Promise<CoInvestmentInterest[]> {
    try {
      const response = await fetch(`/api/co-investment/opportunity/${opportunityId}/interests`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error('Failed to fetch opportunity interests');
      }

      const result = await response.json();
      return result.interests;
    } catch (error) {
      console.error('Error fetching opportunity interests:', error);
      throw error;
    }
  }

  // Get approvals for a specific opportunity
  async getOpportunityApprovals(opportunityId: number): Promise<CoInvestmentApproval[]> {
    try {
      const response = await fetch(`/api/co-investment/opportunity/${opportunityId}/approvals`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error('Failed to fetch opportunity approvals');
      }

      const result = await response.json();
      return result.approvals;
    } catch (error) {
      console.error('Error fetching opportunity approvals:', error);
      throw error;
    }
  }

  // Check if user has already expressed interest in an opportunity
  async hasUserExpressedInterest(opportunityId: number, userId: string): Promise<boolean> {
    try {
      const response = await fetch(`/api/co-investment/opportunity/${opportunityId}/user/${userId}/interest`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        return false;
      }

      const result = await response.json();
      return result.hasInterest;
    } catch (error) {
      console.error('Error checking user interest:', error);
      return false;
    }
  }

  // Get user's co-investment interests
  async getUserInterests(userId: string): Promise<CoInvestmentInterest[]> {
    try {
      const response = await fetch(`/api/co-investment/user/${userId}/interests`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error('Failed to fetch user interests');
      }

      const result = await response.json();
      return result.interests;
    } catch (error) {
      console.error('Error fetching user interests:', error);
      throw error;
    }
  }

  // Withdraw interest from an opportunity
  async withdrawInterest(interestId: number): Promise<void> {
    try {
      const response = await fetch(`/api/co-investment/interest/${interestId}/withdraw`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error('Failed to withdraw interest');
      }
    } catch (error) {
      console.error('Error withdrawing interest:', error);
      throw error;
    }
  }
}

// Export singleton instance
export const coInvestmentService = new CoInvestmentService();
export default coInvestmentService;
