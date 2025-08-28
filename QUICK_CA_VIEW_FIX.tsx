// Quick fix for CA View Details button
// Add this debugging to see what's happening

// In CAView.tsx, replace the View Details button with this:
<Button
  variant="outline"
  size="sm"
  onClick={() => {
    console.log('🔍 Button clicked!');
    console.log('🔍 Startup object:', startup);
    console.log('🔍 onViewStartup function:', onViewStartup);
    
    // Direct navigation test
    window.location.href = `#startup-${startup.id}`;
    
    // Also try the normal way
    onViewStartup(startup);
  }}
>
  View Details
</Button>

// In App.tsx, add this to the handleViewStartup function:
const handleViewStartup = useCallback((startup: Startup) => {
  console.log('🔍 handleViewStartup called with startup:', startup);
  
  // Force immediate state updates
  setSelectedStartup(startup);
  setIsViewOnly(currentUser?.role === 'CA');
  setView('startupHealth');
  setViewKey(prev => prev + 1);
  
  // Force a re-render
  setTimeout(() => {
    console.log('🔍 Forcing re-render...');
    setViewKey(prev => prev + 1);
  }, 100);
  
  console.log('🔍 handleViewStartup completed');
}, [currentUser?.role]);

