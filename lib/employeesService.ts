import { supabase } from './supabase';
import { Employee } from '../types';

export interface EmployeeFilters {
  entity?: string;
  department?: string;
  year?: number;
}

export interface EmployeeSummary {
  total_employees: number;
  total_salary_expense: number;
  total_esop_allocated: number;
  avg_salary: number;
  avg_esop_allocation: number;
}

export interface DepartmentData {
  department_name: string;
  employee_count: number;
  total_salary: number;
  total_esop: number;
}

export interface MonthlySalaryData {
  month_name: string;
  total_salary: number;
  total_esop: number;
}

class EmployeesService {
  // =====================================================
  // CRUD OPERATIONS
  // =====================================================

  async getEmployees(startupId: number, filters?: EmployeeFilters): Promise<Employee[]> {
    let query = supabase
      .from('employees')
      .select('*')
      .eq('startup_id', startupId)
      .order('joining_date', { ascending: false });

    if (filters?.entity && filters.entity !== 'All Entities') {
      query = query.eq('entity', filters.entity);
    }

    if (filters?.department && filters.department !== 'All Departments') {
      query = query.eq('department', filters.department);
    }

    if (filters?.year) {
      query = query.eq('EXTRACT(YEAR FROM joining_date)', filters.year);
    }

    const { data, error } = await query;
    if (error) throw error;

    return (data || []).map(record => ({
      id: record.id,
      name: record.name,
      joiningDate: record.joining_date,
      entity: record.entity,
      department: record.department,
      salary: record.salary,
      esopAllocation: record.esop_allocation,
      allocationType: record.allocation_type,
      esopPerAllocation: record.esop_per_allocation,
      contractUrl: record.contract_url
    }));
  }

  async addEmployee(startupId: number, employeeData: Omit<Employee, 'id'>): Promise<Employee> {
    const { data, error } = await supabase
      .from('employees')
      .insert({
        startup_id: startupId,
        name: employeeData.name,
        joining_date: employeeData.joiningDate,
        entity: employeeData.entity,
        department: employeeData.department,
        salary: employeeData.salary,
        esop_allocation: employeeData.esopAllocation,
        allocation_type: employeeData.allocationType,
        esop_per_allocation: employeeData.esopPerAllocation,
        contract_url: employeeData.contractUrl
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      name: data.name,
      joiningDate: data.joining_date,
      entity: data.entity,
      department: data.department,
      salary: data.salary,
      esopAllocation: data.esop_allocation,
      allocationType: data.allocation_type,
      esopPerAllocation: data.esop_per_allocation,
      contractUrl: data.contract_url
    };
  }

  async updateEmployee(id: string, employeeData: Partial<Employee>): Promise<Employee> {
    const updateData: any = {};
    
    if (employeeData.name !== undefined) updateData.name = employeeData.name;
    if (employeeData.joiningDate !== undefined) updateData.joining_date = employeeData.joiningDate;
    if (employeeData.entity !== undefined) updateData.entity = employeeData.entity;
    if (employeeData.department !== undefined) updateData.department = employeeData.department;
    if (employeeData.salary !== undefined) updateData.salary = employeeData.salary;
    if (employeeData.esopAllocation !== undefined) updateData.esop_allocation = employeeData.esopAllocation;
    if (employeeData.allocationType !== undefined) updateData.allocation_type = employeeData.allocationType;
    if (employeeData.esopPerAllocation !== undefined) updateData.esop_per_allocation = employeeData.esopPerAllocation;
    if (employeeData.contractUrl !== undefined) updateData.contract_url = employeeData.contractUrl;

    const { data, error } = await supabase
      .from('employees')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      name: data.name,
      joiningDate: data.joining_date,
      entity: data.entity,
      department: data.department,
      salary: data.salary,
      esopAllocation: data.esop_allocation,
      allocationType: data.allocation_type,
      esopPerAllocation: data.esop_per_allocation,
      contractUrl: data.contract_url
    };
  }

  async deleteEmployee(id: string): Promise<void> {
    const { error } = await supabase
      .from('employees')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }

  // =====================================================
  // ANALYTICS AND CHARTS DATA
  // =====================================================

  async getEmployeeSummary(startupId: number): Promise<EmployeeSummary> {
    try {
      const { data, error } = await supabase.rpc('get_employee_summary', { startup_id_param: startupId });
      if (error) throw error;
      if (data && Array.isArray(data) && data[0]) {
        const row = data[0];
        return {
          total_employees: row.total_employees ?? 0,
          total_salary_expense: row.total_salary_expense ?? 0,
          total_esop_allocated: row.total_esop_allocated ?? 0,
          avg_salary: row.avg_salary ?? 0,
          avg_esop_allocation: row.avg_esop_allocation ?? 0,
        };
      }
      // Fallback to manual if no data returned
      return this.calculateEmployeeSummaryManually(startupId);
    } catch (rpcError) {
      console.warn('RPC get_employee_summary failed, falling back to manual calc:', rpcError);
      return this.calculateEmployeeSummaryManually(startupId);
    }
  }

  async getEmployeesByDepartment(startupId: number): Promise<DepartmentData[]> {
    // Temporarily use only manual calculation until RPC functions are fixed
    console.log('🔍 Using manual calculation for department data (startup_id:', startupId, ')');
    return this.calculateEmployeesByDepartmentManually(startupId);
  }

  async getMonthlySalaryData(startupId: number, year: number): Promise<MonthlySalaryData[]> {
    // Temporarily use only manual calculation until RPC functions are fixed
    console.log('🔍 Using manual calculation for monthly data (startup_id:', startupId, ', year:', year, ')');
    return this.calculateMonthlySalaryDataManually(startupId, year);
  }

  // =====================================================
  // UTILITY FUNCTIONS
  // =====================================================

  async getEntities(startupId: number): Promise<string[]> {
    const { data, error } = await supabase
      .from('employees')
      .select('entity')
      .eq('startup_id', startupId)
      .order('entity');

    if (error) throw error;
    return [...new Set(data?.map(item => item.entity) || [])];
  }

  async getDepartments(startupId: number): Promise<string[]> {
    const { data, error } = await supabase
      .from('employees')
      .select('department')
      .eq('startup_id', startupId)
      .order('department');

    if (error) throw error;
    return [...new Set(data?.map(item => item.department) || [])];
  }

  async getAvailableYears(startupId: number): Promise<number[]> {
    const { data, error } = await supabase
      .from('employees')
      .select('joining_date')
      .eq('startup_id', startupId);

    if (error) throw error;
    
    const years = data?.map(item => new Date(item.joining_date).getFullYear()) || [];
    const uniqueYears = [...new Set(years)].sort((a, b) => b - a); // Descending order
    
    // If no years found, return current year
    if (uniqueYears.length === 0) {
      return [new Date().getFullYear()];
    }
    
    return uniqueYears;
  }

  // =====================================================
  // FILE UPLOAD HELPERS
  // =====================================================

  async uploadContract(file: File, startupId: number): Promise<string> {
    const fileName = `${startupId}/${Date.now()}_${file.name}`;
    const { data, error } = await supabase.storage
      .from('employee-contracts')
      .upload(fileName, file);

    if (error) throw error;

    const { data: urlData } = supabase.storage
      .from('employee-contracts')
      .getPublicUrl(fileName);

    return urlData.publicUrl;
  }

  async deleteContract(url: string): Promise<void> {
    const path = url.split('/').slice(-2).join('/'); // Extract path from URL
    const { error } = await supabase.storage
      .from('employee-contracts')
      .remove([path]);

    if (error) throw error;
  }

  // =====================================================
  // DOWNLOAD HELPERS
  // =====================================================

  async getContractDownloadUrl(contractUrl: string): Promise<string> {
    try {
      // If the URL is already a valid public URL, return it
      if (contractUrl && contractUrl.startsWith('http')) {
        return contractUrl;
      }

      // If it's a file path, generate the public URL
      if (contractUrl && !contractUrl.startsWith('http')) {
        const { data } = supabase.storage
          .from('employee-contracts')
          .getPublicUrl(contractUrl);
        
        return data.publicUrl;
      }

      throw new Error('Invalid contract URL');
    } catch (error) {
      console.error('Error generating download URL:', error);
      throw error;
    }
  }

  // =====================================================
  // MANUAL CALCULATION FALLBACKS
  // =====================================================

  private async calculateEmployeeSummaryManually(startupId: number): Promise<EmployeeSummary> {
    const employees = await this.getEmployees(startupId);
    
    const total_employees = employees.length;
    const total_salary_expense = employees.reduce((sum, emp) => sum + emp.salary, 0);
    const total_esop_allocated = employees.reduce((sum, emp) => sum + emp.esopAllocation, 0);
    const avg_salary = total_employees > 0 ? total_salary_expense / total_employees : 0;
    const avg_esop_allocation = total_employees > 0 ? total_esop_allocated / total_employees : 0;
    
    return {
      total_employees,
      total_salary_expense,
      total_esop_allocated,
      avg_salary,
      avg_esop_allocation
    };
  }

  private async calculateEmployeesByDepartmentManually(startupId: number): Promise<DepartmentData[]> {
    const employees = await this.getEmployees(startupId);
    
    const departmentMap = new Map<string, { count: number; salary: number; esop: number }>();
    
    employees.forEach(emp => {
      const existing = departmentMap.get(emp.department) || { count: 0, salary: 0, esop: 0 };
      departmentMap.set(emp.department, {
        count: existing.count + 1,
        salary: existing.salary + emp.salary,
        esop: existing.esop + emp.esopAllocation
      });
    });
    
    return Array.from(departmentMap.entries()).map(([department_name, data]) => ({
      department_name,
      employee_count: data.count,
      total_salary: data.salary,
      total_esop: data.esop
    })).sort((a, b) => b.employee_count - a.employee_count);
  }

  private async calculateMonthlySalaryDataManually(startupId: number, year: number): Promise<MonthlySalaryData[]> {
    const employees = await this.getEmployees(startupId);
    
    const monthlyMap = new Map<string, { salary: number; esop: number }>();
    
    employees.forEach(emp => {
      const joinYear = new Date(emp.joiningDate).getFullYear();
      if (joinYear === year) {
        const month = new Date(emp.joiningDate).toLocaleString('default', { month: 'short' });
        const existing = monthlyMap.get(month) || { salary: 0, esop: 0 };
        monthlyMap.set(month, {
          salary: existing.salary + emp.salary,
          esop: existing.esop + emp.esopAllocation
        });
      }
    });
    
    return Array.from(monthlyMap.entries()).map(([month_name, data]) => ({
      month_name,
      total_salary: data.salary,
      total_esop: data.esop
    }));
  }
}

export const employeesService = new EmployeesService();
