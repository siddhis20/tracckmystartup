import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { userService, startupService } from '../lib/database';
import Card from './ui/Card';
import Button from './ui/Button';

const SupabaseTest: React.FC = () => {
  const [connectionStatus, setConnectionStatus] = useState<'testing' | 'connected' | 'error'>('testing');
  const [userCount, setUserCount] = useState<number | null>(null);
  const [startupCount, setStartupCount] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    testConnection();
  }, []);

  const testConnection = async () => {
    try {
      setConnectionStatus('testing');
      setError(null);

      // Test basic connection
      const { data, error } = await supabase.from('users').select('count', { count: 'exact', head: true });
      
      if (error) {
        throw error;
      }

      setConnectionStatus('connected');
      
      // Get counts
      const { count: users } = await supabase.from('users').select('*', { count: 'exact', head: true });
      const { count: startups } = await supabase.from('startups').select('*', { count: 'exact', head: true });
      
      setUserCount(users || 0);
      setStartupCount(startups || 0);

    } catch (err: any) {
      setConnectionStatus('error');
      setError(err.message);
    }
  };

  const testAuth = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        alert(`Authenticated as: ${user.email}`);
      } else {
        alert('No user authenticated');
      }
    } catch (err: any) {
      alert(`Auth error: ${err.message}`);
    }
  };

  const testSignUp = async () => {
    try {
      const { data, error } = await supabase.auth.signUp({
        email: 'test@example.com',
        password: 'testpassword123'
      });

      if (error) throw error;
      
      alert('Sign up successful! Check your email for confirmation.');
    } catch (err: any) {
      alert(`Sign up error: ${err.message}`);
    }
  };

  return (
    <Card className="max-w-2xl mx-auto">
      <h2 className="text-2xl font-bold mb-6">Supabase Connection Test</h2>
      
      <div className="space-y-4">
        <div className="flex items-center gap-3">
          <div className={`w-3 h-3 rounded-full ${
            connectionStatus === 'connected' ? 'bg-green-500' :
            connectionStatus === 'error' ? 'bg-red-500' : 'bg-yellow-500'
          }`} />
          <span className="font-medium">
            Status: {connectionStatus === 'connected' ? 'Connected' : 
                    connectionStatus === 'error' ? 'Error' : 'Testing...'}
          </span>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-md p-3">
            <p className="text-red-800 text-sm">{error}</p>
          </div>
        )}

        {connectionStatus === 'connected' && (
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-blue-50 p-4 rounded-md">
              <p className="text-sm text-blue-600">Users in Database</p>
              <p className="text-2xl font-bold text-blue-800">{userCount}</p>
            </div>
            <div className="bg-green-50 p-4 rounded-md">
              <p className="text-sm text-green-600">Startups in Database</p>
              <p className="text-2xl font-bold text-green-800">{startupCount}</p>
            </div>
          </div>
        )}

        <div className="flex gap-3 pt-4">
          <Button onClick={testConnection} variant="secondary">
            Test Connection
          </Button>
          <Button onClick={testAuth}>
            Test Auth
          </Button>
          <Button onClick={testSignUp} variant="outline">
            Test Sign Up
          </Button>
        </div>

        <div className="text-sm text-gray-600 mt-4">
          <p>Make sure you have:</p>
          <ul className="list-disc list-inside mt-2 space-y-1">
            <li>Created a Supabase project</li>
            <li>Set up environment variables in .env.local</li>
            <li>Run the database schema from database/schema.sql</li>
          </ul>
        </div>
      </div>
    </Card>
  );
};

export default SupabaseTest;
