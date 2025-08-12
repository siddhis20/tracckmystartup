import { supabase } from './supabase';
import { FinancialRecord, Employee, InvestmentRecord, Subsidiary, InternationalOp } from '../types';

// =====================================================
// STARTUP DASHBOARD SERVICE
// =====================================================

export interface MonthlyFinancialData {
  month_name: string;
  revenue: number;
  expenses: number;
}

export interface FundUsageData {
  category: string;
  amount: number;
  percentage: number;
}

export interface VerticalData {
  vertical: string;
  amount: number;
  percentage: number;
}

export interface MonthlySalaryData {
  month_name: string;
  salary_expense: number;
  esop_expense: number;
}

export interface EmployeeDepartmentData {
  department: string;
  employee_count: number;
  total_salary: number;
  total_esop: number;
}

export interface StartupSummaryStats {
  total_funding: number;
  total_revenue: number;
  total_expenses: number;
  available_funds: number;
  employee_count: number;
  esop_reserved_value: number;
  esop_allocated_value: number;
}

export const startupDashboardService = {
  // =====================================================
  // ANALYTICS FUNCTIONS
  // =====================================================

  // Get monthly revenue vs expenses data for charts
  async getMonthlyFinancialData(startupId: number, year: number = new Date().getFullYear()): Promise<MonthlyFinancialData[]> {
    try {
      const { data, error } = await supabase
        .rpc('get_monthly_financial_data', {
          startup_id_param: startupId,
          year_param: year
        });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching monthly financial data:', error);
      return [];
    }
  },

  // Get fund usage breakdown for pie chart
  async getFundUsageBreakdown(startupId: number): Promise<FundUsageData[]> {
    try {
      const { data, error } = await supabase
        .rpc('get_fund_usage_breakdown', {
          startup_id_param: startupId
        });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching fund usage breakdown:', error);
      return [];
    }
  },

  // Get revenue by vertical
  async getRevenueByVertical(startupId: number, year: number = new Date().getFullYear()): Promise<VerticalData[]> {
    try {
      const { data, error } = await supabase
        .rpc('get_revenue_by_vertical', {
          startup_id_param: startupId,
          year_param: year
        });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching revenue by vertical:', error);
      return [];
    }
  },

  // Get expenses by vertical
  async getExpensesByVertical(startupId: number, year: number = new Date().getFullYear()): Promise<VerticalData[]> {
    try {
      const { data, error } = await supabase
        .rpc('get_expenses_by_vertical', {
          startup_id_param: startupId,
          year_param: year
        });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching expenses by vertical:', error);
      return [];
    }
  },

  // Get monthly salary data
  async getMonthlySalaryData(startupId: number, year: number = new Date().getFullYear()): Promise<MonthlySalaryData[]> {
    try {
      const { data, error } = await supabase
        .rpc('get_monthly_salary_data', {
          startup_id_param: startupId,
          year_param: year
        });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching monthly salary data:', error);
      return [];
    }
  },

  // Get employee distribution by department
  async getEmployeeDepartmentDistribution(startupId: number): Promise<EmployeeDepartmentData[]> {
    try {
      const { data, error } = await supabase
        .rpc('get_employee_department_distribution', {
          startup_id_param: startupId
        });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching employee department distribution:', error);
      return [];
    }
  },

  // Get startup summary statistics
  async getStartupSummaryStats(startupId: number): Promise<StartupSummaryStats | null> {
    try {
      const { data, error } = await supabase
        .rpc('get_startup_summary_stats', {
          startup_id_param: startupId
        });

      if (error) throw error;
      return data?.[0] || null;
    } catch (error) {
      console.error('Error fetching startup summary stats:', error);
      return null;
    }
  },

  // =====================================================
  // CRUD OPERATIONS
  // =====================================================

  // Add financial record
  async addFinancialRecord(recordData: {
    startup_id: number;
    date: string;
    entity: string;
    description: string;
    vertical: string;
    amount: number;
    funding_source?: string;
    cogs?: number;
    attachment_url?: string;
  }): Promise<string | null> {
    try {
      const { data, error } = await supabase
        .rpc('add_financial_record', {
          startup_id_param: recordData.startup_id,
          date_param: recordData.date,
          entity_param: recordData.entity,
          description_param: recordData.description,
          vertical_param: recordData.vertical,
          amount_param: recordData.amount,
          funding_source_param: recordData.funding_source || null,
          cogs_param: recordData.cogs || null,
          attachment_url_param: recordData.attachment_url || null
        });

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error adding financial record:', error);
      return null;
    }
  },

  // Get financial records for a startup
  async getFinancialRecords(startupId: number): Promise<FinancialRecord[]> {
    try {
      const { data, error } = await supabase
        .from('financial_records')
        .select('*')
        .eq('startup_id', startupId)
        .order('date', { ascending: false });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching financial records:', error);
      return [];
    }
  },

  // Add employee
  async addEmployee(employeeData: {
    startup_id: number;
    name: string;
    joining_date: string;
    entity: string;
    department: string;
    salary: number;
    esop_allocation?: number;
    allocation_type?: 'one-time' | 'annually' | 'quarterly' | 'monthly';
    esop_per_allocation?: number;
    contract_url?: string;
  }): Promise<string | null> {
    try {
      const { data, error } = await supabase
        .rpc('add_employee', {
          startup_id_param: employeeData.startup_id,
          name_param: employeeData.name,
          joining_date_param: employeeData.joining_date,
          entity_param: employeeData.entity,
          department_param: employeeData.department,
          salary_param: employeeData.salary,
          esop_allocation_param: employeeData.esop_allocation || 0,
          allocation_type_param: employeeData.allocation_type || 'one-time',
          esop_per_allocation_param: employeeData.esop_per_allocation || 0,
          contract_url_param: employeeData.contract_url || null
        });

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error adding employee:', error);
      return null;
    }
  },

  // Get employees for a startup
  async getEmployees(startupId: number): Promise<Employee[]> {
    try {
      const { data, error } = await supabase
        .from('employees')
        .select('*')
        .eq('startup_id', startupId)
        .order('joining_date', { ascending: false });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching employees:', error);
      return [];
    }
  },

  // Add investment record
  async addInvestmentRecord(recordData: {
    startup_id: number;
    date: string;
    investor_type: 'Angel' | 'VC Firm' | 'Corporate' | 'Government';
    investment_type: 'Equity' | 'Debt' | 'Grant';
    investor_name: string;
    investor_code?: string;
    amount: number;
    equity_allocated: number;
    pre_money_valuation: number;
    proof_url?: string;
  }): Promise<string | null> {
    try {
      const { data, error } = await supabase
        .rpc('add_investment_record', {
          startup_id_param: recordData.startup_id,
          date_param: recordData.date,
          investor_type_param: recordData.investor_type,
          investment_type_param: recordData.investment_type,
          investor_name_param: recordData.investor_name,
          investor_code_param: recordData.investor_code || null,
          amount_param: recordData.amount,
          equity_allocated_param: recordData.equity_allocated,
          pre_money_valuation_param: recordData.pre_money_valuation,
          proof_url_param: recordData.proof_url || null
        });

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error adding investment record:', error);
      return null;
    }
  },

  // Get investment records for a startup
  async getInvestmentRecords(startupId: number): Promise<InvestmentRecord[]> {
    try {
      const { data, error } = await supabase
        .from('investment_records')
        .select('*')
        .eq('startup_id', startupId)
        .order('date', { ascending: false });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching investment records:', error);
      return [];
    }
  },

  // =====================================================
  // PROFILE MANAGEMENT
  // =====================================================

  // Get subsidiaries for a startup
  async getSubsidiaries(startupId: number): Promise<Subsidiary[]> {
    try {
      const { data, error } = await supabase
        .from('subsidiaries')
        .select('*')
        .eq('startup_id', startupId)
        .order('registration_date', { ascending: false });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching subsidiaries:', error);
      return [];
    }
  },

  // Add subsidiary
  async addSubsidiary(subsidiaryData: {
    startup_id: number;
    country: string;
    company_type: string;
    registration_date: string;
  }): Promise<number | null> {
    try {
      const { data, error } = await supabase
        .from('subsidiaries')
        .insert(subsidiaryData)
        .select('id')
        .single();

      if (error) throw error;
      return data?.id || null;
    } catch (error) {
      console.error('Error adding subsidiary:', error);
      return null;
    }
  },

  // Get international operations for a startup
  async getInternationalOps(startupId: number): Promise<InternationalOp[]> {
    try {
      const { data, error } = await supabase
        .from('international_ops')
        .select('*')
        .eq('startup_id', startupId)
        .order('start_date', { ascending: false });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching international operations:', error);
      return [];
    }
  },

  // Add international operation
  async addInternationalOp(opData: {
    startup_id: number;
    country: string;
    start_date: string;
  }): Promise<number | null> {
    try {
      const { data, error } = await supabase
        .from('international_ops')
        .insert(opData)
        .select('id')
        .single();

      if (error) throw error;
      return data?.id || null;
    } catch (error) {
      console.error('Error adding international operation:', error);
      return null;
    }
  },

  // =====================================================
  // REAL-TIME SUBSCRIPTIONS
  // =====================================================

  // Subscribe to financial records changes
  subscribeToFinancialRecords(startupId: number, callback: (payload: any) => void) {
    return supabase
      .channel(`financial_records_${startupId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'financial_records',
          filter: `startup_id=eq.${startupId}`
        },
        callback
      )
      .subscribe();
  },

  // Subscribe to employees changes
  subscribeToEmployees(startupId: number, callback: (payload: any) => void) {
    return supabase
      .channel(`employees_${startupId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'employees',
          filter: `startup_id=eq.${startupId}`
        },
        callback
      )
      .subscribe();
  },

  // Subscribe to investment records changes
  subscribeToInvestmentRecords(startupId: number, callback: (payload: any) => void) {
    return supabase
      .channel(`investment_records_${startupId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'investment_records',
          filter: `startup_id=eq.${startupId}`
        },
        callback
      )
      .subscribe();
  },

  // =====================================================
  // UTILITY FUNCTIONS
  // =====================================================

  // Get user's startup
  async getUserStartup(): Promise<any | null> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return null;

      const { data, error } = await supabase
        .from('startups')
        .select('*')
        .eq('user_id', user.id)
        .single();

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error fetching user startup:', error);
      return null;
    }
  },

  // Update startup basic info
  async updateStartup(startupId: number, updates: {
    name?: string;
    current_valuation?: number;
    total_revenue?: number;
    compliance_status?: string;
  }): Promise<boolean> {
    try {
      const { error } = await supabase
        .from('startups')
        .update(updates)
        .eq('id', startupId);

      if (error) throw error;
      return true;
    } catch (error) {
      console.error('Error updating startup:', error);
      return false;
    }
  }
};
