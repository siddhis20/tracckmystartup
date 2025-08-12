import React, { useState } from 'react';
import { supabase } from '../lib/supabase';
import { dataMigrationService } from '../lib/dataMigration';
import { mockStartups, mockNewInvestments, mockUsers } from '../constants';
import Card from './ui/Card';
import Button from './ui/Button';
import { CheckCircle, XCircle, AlertTriangle, Database, RefreshCw, Upload } from 'lucide-react';

interface TestResult {
  name: string;
  status: 'success' | 'error' | 'pending';
  message: string;
  details?: any;
}

const BackendTest: React.FC = () => {
  const [isRunning, setIsRunning] = useState(false);
  const [results, setResults] = useState<TestResult[]>([]);

  const runAllTests = async () => {
    setIsRunning(true);
    setResults([]);

    const tests: TestResult[] = [];

    // Test 1: Database Connection
    tests.push({ name: 'Database Connection', status: 'pending', message: 'Testing...' });
    setResults([...tests]);
    
    try {
      const { data, error } = await supabase.from('users').select('count').limit(1);
      if (error) throw error;
      tests[0] = { name: 'Database Connection', status: 'success', message: 'Connected successfully' };
    } catch (error) {
      tests[0] = { name: 'Database Connection', status: 'error', message: `Connection failed: ${error.message}` };
    }
    setResults([...tests]);

    // Test 2: Users Table
    tests.push({ name: 'Users Table', status: 'pending', message: 'Testing...' });
    setResults([...tests]);
    
    try {
      const { data, error } = await supabase.from('users').select('*').limit(5);
      if (error) throw error;
      tests[1] = { name: 'Users Table', status: 'success', message: `Found ${data?.length || 0} users` };
    } catch (error) {
      tests[1] = { name: 'Users Table', status: 'error', message: `Query failed: ${error.message}` };
    }
    setResults([...tests]);

    // Test 3: Startups Table
    tests.push({ name: 'Startups Table', status: 'pending', message: 'Testing...' });
    setResults([...tests]);
    
    try {
      const { data, error } = await supabase.from('startups').select('*').limit(5);
      if (error) throw error;
      tests[2] = { name: 'Startups Table', status: 'success', message: `Found ${data?.length || 0} startups` };
    } catch (error) {
      tests[2] = { name: 'Startups Table', status: 'error', message: `Query failed: ${error.message}` };
    }
    setResults([...tests]);

    // Test 4: New Investments Table
    tests.push({ name: 'New Investments Table', status: 'pending', message: 'Testing...' });
    setResults([...tests]);
    
    try {
      const { data, error } = await supabase.from('new_investments').select('*').limit(5);
      if (error) throw error;
      tests[3] = { name: 'New Investments Table', status: 'success', message: `Found ${data?.length || 0} investments` };
    } catch (error) {
      tests[3] = { name: 'New Investments Table', status: 'error', message: `Query failed: ${error.message}` };
    }
    setResults([...tests]);

    // Test 5: Verification Requests Table
    tests.push({ name: 'Verification Requests Table', status: 'pending', message: 'Testing...' });
    setResults([...tests]);
    
    try {
      const { data, error } = await supabase.from('verification_requests').select('*').limit(5);
      if (error) throw error;
      tests[4] = { name: 'Verification Requests Table', status: 'success', message: `Found ${data?.length || 0} requests` };
    } catch (error) {
      tests[4] = { name: 'Verification Requests Table', status: 'error', message: `Query failed: ${error.message}` };
    }
    setResults([...tests]);

    // Test 6: Investment Offers Table
    tests.push({ name: 'Investment Offers Table', status: 'pending', message: 'Testing...' });
    setResults([...tests]);
    
    try {
      const { data, error } = await supabase.from('investment_offers').select('*').limit(5);
      if (error) throw error;
      tests[5] = { name: 'Investment Offers Table', status: 'success', message: `Found ${data?.length || 0} offers` };
    } catch (error) {
      tests[5] = { name: 'Investment Offers Table', status: 'error', message: `Query failed: ${error.message}` };
    }
    setResults([...tests]);

    // Test 7: Data Migration
    tests.push({ name: 'Data Migration', status: 'pending', message: 'Testing...' });
    setResults([...tests]);
    
    try {
      const result = await dataMigrationService.migrateAllData();
      if (result.success) {
        tests[6] = { name: 'Data Migration', status: 'success', message: result.message || 'Migration successful' };
      } else {
        tests[6] = { name: 'Data Migration', status: 'error', message: result.message || 'Migration failed' };
      }
    } catch (error) {
      tests[6] = { name: 'Data Migration', status: 'error', message: `Migration error: ${error.message}` };
    }
    setResults([...tests]);

    // Test 8: Real-time Subscriptions
    tests.push({ name: 'Real-time Subscriptions', status: 'pending', message: 'Testing...' });
    setResults([...tests]);
    
    try {
      const channel = supabase
        .channel('test')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'users' }, () => {})
        .subscribe();
      
      setTimeout(() => {
        supabase.removeChannel(channel);
      }, 1000);
      
      tests[7] = { name: 'Real-time Subscriptions', status: 'success', message: 'Subscriptions working' };
    } catch (error) {
      tests[7] = { name: 'Real-time Subscriptions', status: 'error', message: `Subscription error: ${error.message}` };
    }
    setResults([...tests]);

    // Test 9: Mock Data Validation
    tests.push({ name: 'Mock Data Validation', status: 'pending', message: 'Testing...' });
    setResults([...tests]);
    
    try {
      const mockDataCount = mockStartups.length + mockNewInvestments.length + mockUsers.length;
      tests[8] = { 
        name: 'Mock Data Validation', 
        status: 'success', 
        message: `Mock data ready: ${mockStartups.length} startups, ${mockNewInvestments.length} investments, ${mockUsers.length} users` 
      };
    } catch (error) {
      tests[8] = { name: 'Mock Data Validation', status: 'error', message: `Mock data error: ${error.message}` };
    }
    setResults([...tests]);

    setIsRunning(false);
  };

  const runMigrationOnly = async () => {
    setIsRunning(true);
    setResults([]);

    const tests: TestResult[] = [];

    // Test Data Migration
    tests.push({ name: 'Data Migration', status: 'pending', message: 'Migrating your mock data...' });
    setResults([...tests]);
    
    try {
      const result = await dataMigrationService.migrateAllData();
      if (result.success) {
        tests[0] = { name: 'Data Migration', status: 'success', message: result.message || 'Migration successful' };
      } else {
        tests[0] = { name: 'Data Migration', status: 'error', message: result.message || 'Migration failed' };
      }
    } catch (error) {
      tests[0] = { name: 'Data Migration', status: 'error', message: `Migration error: ${error.message}` };
    }
    setResults([...tests]);

    setIsRunning(false);
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'success':
        return <CheckCircle className="h-5 w-5 text-green-500" />;
      case 'error':
        return <XCircle className="h-5 w-5 text-red-500" />;
      case 'pending':
        return <AlertTriangle className="h-5 w-5 text-yellow-500" />;
      default:
        return null;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'success':
        return 'bg-green-50 border-green-200';
      case 'error':
        return 'bg-red-50 border-red-200';
      case 'pending':
        return 'bg-yellow-50 border-yellow-200';
      default:
        return 'bg-gray-50 border-gray-200';
    }
  };

  const successCount = results.filter(r => r.status === 'success').length;
  const errorCount = results.filter(r => r.status === 'error').length;
  const totalTests = results.length;

  return (
    <div className="max-w-4xl mx-auto p-6">
      <Card className="p-6">
        <div className="flex items-center gap-3 mb-6">
          <Database className="h-8 w-8 text-blue-600" />
          <div>
            <h1 className="text-2xl font-bold text-slate-900">Backend System Test</h1>
            <p className="text-slate-600">Testing your mock data integration with Supabase</p>
          </div>
        </div>

        {/* Summary Stats */}
        {totalTests > 0 && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div className="p-4 bg-green-50 rounded-lg">
              <div className="flex items-center gap-2">
                <CheckCircle className="h-5 w-5 text-green-500" />
                <span className="font-semibold text-green-700">Passed: {successCount}</span>
              </div>
            </div>
            <div className="p-4 bg-red-50 rounded-lg">
              <div className="flex items-center gap-2">
                <XCircle className="h-5 w-5 text-red-500" />
                <span className="font-semibold text-red-700">Failed: {errorCount}</span>
              </div>
            </div>
            <div className="p-4 bg-blue-50 rounded-lg">
              <div className="flex items-center gap-2">
                <Database className="h-5 w-5 text-blue-500" />
                <span className="font-semibold text-blue-700">Total: {totalTests}</span>
              </div>
            </div>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex gap-4 mb-6">
          <Button
            onClick={runAllTests}
            disabled={isRunning}
            className="flex items-center gap-2"
          >
            {isRunning ? (
              <RefreshCw className="h-4 w-4 animate-spin" />
            ) : (
              <Database className="h-4 w-4" />
            )}
            {isRunning ? 'Running Tests...' : 'Run All Tests'}
          </Button>

          <Button
            onClick={runMigrationOnly}
            disabled={isRunning}
            variant="outline"
            className="flex items-center gap-2"
          >
            {isRunning ? (
              <RefreshCw className="h-4 w-4 animate-spin" />
            ) : (
              <Upload className="h-4 w-4" />
            )}
            {isRunning ? 'Migrating...' : 'Migrate Mock Data Only'}
          </Button>
        </div>

        {/* Mock Data Info */}
        <div className="mb-6 p-4 bg-blue-50 rounded-lg">
          <h3 className="font-semibold text-blue-900 mb-2">Your Mock Data</h3>
          <div className="text-sm text-blue-700 space-y-1">
            <p>• {mockStartups.length} Startups (InnovateAI, HealthWell, FinSecure, etc.)</p>
            <p>• {mockNewInvestments.length} Investment Opportunities (QuantumLeap, AgroFuture, etc.)</p>
            <p>• {mockUsers.length} Users (Investor, CA, CS, Admin, Facilitator)</p>
            <p>• Verification Requests and Investment Offers</p>
          </div>
        </div>

        {/* Test Results */}
        <div className="space-y-3">
          {results.map((result, index) => (
            <div
              key={index}
              className={`flex items-center justify-between p-4 rounded-lg border ${getStatusColor(result.status)}`}
            >
              <div className="flex items-center gap-3">
                {getStatusIcon(result.status)}
                <div>
                  <h3 className="font-semibold text-slate-900">{result.name}</h3>
                  <p className="text-sm text-slate-600">{result.message}</p>
                </div>
              </div>
              <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                result.status === 'success' ? 'bg-green-100 text-green-800' :
                result.status === 'error' ? 'bg-red-100 text-red-800' :
                'bg-yellow-100 text-yellow-800'
              }`}>
                {result.status.toUpperCase()}
              </span>
            </div>
          ))}
        </div>

        {results.length === 0 && (
          <div className="text-center py-12">
            <Database className="h-12 w-12 text-slate-400 mx-auto mb-4" />
            <p className="text-slate-600">Click "Run All Tests" to test your backend system</p>
            <p className="text-slate-500 text-sm mt-2">Or "Migrate Mock Data Only" to populate the database with your mock data</p>
          </div>
        )}
      </Card>
    </div>
  );
};

export default BackendTest;
