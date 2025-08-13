import React, { useState, useEffect } from 'react';
import { profileService } from '../lib/profileService';

const ProfileTest: React.FC = () => {
  const [testResults, setTestResults] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  const addResult = (message: string) => {
    setTestResults(prev => [...prev, `${new Date().toLocaleTimeString()}: ${message}`]);
  };

  const runTests = async () => {
    setIsLoading(true);
    setTestResults([]);
    
    try {
      addResult('Starting profile service tests...');
      
      // Test 1: Get company types
      try {
        const companyTypes = profileService.getCompanyTypesByCountry('USA');
        addResult(`✅ Company types for USA: ${companyTypes.join(', ')}`);
      } catch (error) {
        addResult(`❌ Company types test failed: ${error}`);
      }
      
      // Test 2: Get all countries
      try {
        const countries = profileService.getAllCountries();
        addResult(`✅ Available countries: ${countries.join(', ')}`);
      } catch (error) {
        addResult(`❌ Countries test failed: ${error}`);
      }
      
      // Test 3: Validate profile data
      try {
        const validation = profileService.validateProfileData({
          country: 'USA',
          companyType: 'C-Corporation'
        });
        addResult(`✅ Profile validation: ${validation.isValid ? 'Valid' : 'Invalid'}`);
        if (!validation.isValid) {
          addResult(`❌ Validation errors: ${validation.errors.join(', ')}`);
        }
      } catch (error) {
        addResult(`❌ Validation test failed: ${error}`);
      }
      
      // Test 4: Try to get a startup profile (this might fail if no startups exist)
      try {
        const profile = await profileService.getStartupProfile(1);
        if (profile) {
          addResult(`✅ Got startup profile: ${JSON.stringify(profile, null, 2)}`);
        } else {
          addResult(`⚠️ No profile found for startup ID 1 (this is normal if no startups exist)`);
        }
      } catch (error) {
        addResult(`❌ Get startup profile failed: ${error}`);
      }
      
      addResult('Profile service tests completed!');
      
    } catch (error) {
      addResult(`❌ Test suite failed: ${error}`);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">Profile Service Test</h1>
      
      <button
        onClick={runTests}
        disabled={isLoading}
        className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 disabled:opacity-50 mb-4"
      >
        {isLoading ? 'Running Tests...' : 'Run Profile Service Tests'}
      </button>
      
      <div className="bg-gray-100 p-4 rounded">
        <h2 className="text-lg font-semibold mb-2">Test Results:</h2>
        <div className="space-y-1">
          {testResults.map((result, index) => (
            <div key={index} className="text-sm font-mono">
              {result}
            </div>
          ))}
          {testResults.length === 0 && (
            <div className="text-gray-500">No tests run yet. Click the button above to start testing.</div>
          )}
        </div>
      </div>
      
      <div className="mt-6 p-4 bg-yellow-50 border border-yellow-200 rounded">
        <h3 className="font-semibold text-yellow-800">Instructions:</h3>
        <ul className="text-sm text-yellow-700 mt-2 space-y-1">
          <li>• This component tests the profile service functions</li>
          <li>• It will show which functions are working and which are failing</li>
          <li>• Check the browser console for additional error details</li>
          <li>• If tests fail, the issue is likely in the database functions</li>
        </ul>
      </div>
    </div>
  );
};

export default ProfileTest;
