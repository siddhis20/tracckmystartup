# Troubleshooting Supabase Connection Issues

## Error: "Failed to fetch (api.supabase.com)"

This error typically indicates a network connectivity issue or Supabase service problem. Here are the steps to resolve it:

## 🔍 **Immediate Checks**

### 1. **Check Supabase Status**
- Visit [status.supabase.com](https://status.supabase.com)
- Look for any ongoing incidents or outages
- If there's an outage, wait for Supabase to resolve it

### 2. **Check Your Internet Connection**
- Try accessing other websites
- Test your internet speed
- Try using a different network (mobile hotspot, different WiFi)

### 3. **Check Browser Console**
- Open Developer Tools (F12)
- Go to Console tab
- Look for any specific error messages
- Check Network tab for failed requests

## 🛠️ **Troubleshooting Steps**

### Step 1: Clear Browser Cache
```bash
# Clear browser cache and cookies
# Or use Ctrl+Shift+Delete (Windows) / Cmd+Shift+Delete (Mac)
```

### Step 2: Check Supabase Configuration
Verify your Supabase configuration in your project:

1. **Check Environment Variables**
   - Ensure `VITE_SUPABASE_URL` is correct
   - Ensure `VITE_SUPABASE_ANON_KEY` is correct
   - No extra spaces or quotes

2. **Check Supabase Project Settings**
   - Go to your Supabase dashboard
   - Check if your project is active
   - Verify API keys are correct

### Step 3: Test Supabase Connection
Run this test in your browser console:

```javascript
// Test Supabase connection
const { createClient } = window.supabase;
const supabase = createClient(
  'YOUR_SUPABASE_URL',
  'YOUR_SUPABASE_ANON_KEY'
);

// Test connection
supabase.from('startups').select('count').then(console.log).catch(console.error);
```

### Step 4: Check CORS Settings
If you're getting CORS errors:

1. Go to Supabase Dashboard → Settings → API
2. Check "CORS Origins" settings
3. Add your domain if it's not listed

### Step 5: Check RLS Policies
The error might be due to Row Level Security blocking requests:

```sql
-- Temporarily disable RLS for testing
ALTER TABLE public.investment_offers DISABLE ROW LEVEL SECURITY;

-- Test if data loads
-- Then re-enable RLS
ALTER TABLE public.investment_offers ENABLE ROW LEVEL SECURITY;
```

## 🔧 **Quick Fixes**

### Fix 1: Restart Your Application
```bash
# Stop your development server
# Then restart it
npm run dev
# or
yarn dev
```

### Fix 2: Update Supabase Client
```bash
# Update Supabase client
npm update @supabase/supabase-js
# or
yarn upgrade @supabase/supabase-js
```

### Fix 3: Check Network Settings
- Disable VPN if you're using one
- Check firewall settings
- Try a different browser

## 🚨 **Common Causes & Solutions**

### Cause 1: Incorrect API URL
**Solution**: Verify your Supabase URL in environment variables

### Cause 2: Expired API Key
**Solution**: Generate new API key in Supabase dashboard

### Cause 3: Network/Firewall Issues
**Solution**: Check network settings, try different network

### Cause 4: Supabase Service Outage
**Solution**: Check status.supabase.com, wait for resolution

### Cause 5: CORS Issues
**Solution**: Update CORS settings in Supabase dashboard

## 📋 **Diagnostic Commands**

### Check Supabase Connection
```javascript
// Add this to your browser console
console.log('Supabase URL:', import.meta.env.VITE_SUPABASE_URL);
console.log('Supabase Key:', import.meta.env.VITE_SUPABASE_ANON_KEY?.substring(0, 20) + '...');
```

### Test Database Connection
```javascript
// Test if you can connect to database
const { data, error } = await supabase.from('startups').select('count');
console.log('Connection test:', { data, error });
```

## 🔄 **Alternative Solutions**

### Option 1: Use Different Network
- Try mobile hotspot
- Try different WiFi network
- Try from different location

### Option 2: Use VPN
- If your ISP is blocking Supabase
- Try connecting through VPN

### Option 3: Check Supabase Project
- Verify project is not paused
- Check billing status
- Ensure project is active

## 📞 **If Nothing Works**

1. **Check Supabase Status Page**: [status.supabase.com](https://status.supabase.com)
2. **Contact Supabase Support**: Through their dashboard
3. **Check Supabase Discord**: For community help
4. **Try Again Later**: Sometimes it's a temporary issue

## 🎯 **Quick Test**

Run this in your browser console to test the connection:

```javascript
fetch('https://api.supabase.com/health')
  .then(response => response.json())
  .then(data => console.log('Supabase API Status:', data))
  .catch(error => console.error('Connection Error:', error));
```

## 📝 **Next Steps**

1. **Try the quick fixes first**
2. **Check browser console for specific errors**
3. **Verify Supabase configuration**
4. **Test with a simple query**
5. **Contact support if issue persists**

The "Failed to fetch" error is usually temporary and resolves itself, but these steps should help identify and fix the root cause.

