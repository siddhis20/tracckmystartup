# Investment Offers CapTable Fix

## Problem
Investment offers made by investors were not being displayed in the "Offers Received" section of the CapTable in startup dashboards.

## Root Cause
The `loadOffersReceived` function in `components/startup-health/CapTableTab.tsx` was only fetching incubation opportunity applications from the `opportunity_applications` table, but it was not fetching actual investment offers from the `investment_offers` table.

## Solution Implemented

### 1. **Updated `loadOffersReceived` Function**
- **File**: `components/startup-health/CapTableTab.tsx`
- **Changes**:
  - Added import for `investmentService` from `../../lib/database`
  - Modified the function to fetch both investment offers and incubation applications
  - Combined both types of offers into a single array
  - Sorted offers by creation date (newest first)

### 2. **Enhanced OfferReceived Interface**
- **File**: `components/startup-health/CapTableTab.tsx`
- **Changes**:
  - Added `'Investment'` to the `type` union type
  - Added optional fields: `isInvestmentOffer?: boolean` and `investmentOfferId?: number`
  - Made `applicationId` optional since investment offers don't have application IDs

### 3. **Added Investment Offer Formatting**
- **File**: `components/startup-health/CapTableTab.tsx`
- **Changes**:
  - Created `investmentOffersFormatted` array that transforms investment offers into the `OfferReceived` format
  - Investment offers show as: `"$X,XXX for Y% equity"`
  - Each investment offer gets a unique ID prefixed with `investment_`

### 4. **Enhanced Table Rendering**
- **File**: `components/startup-health/CapTableTab.tsx`
- **Changes**:
  - Added handling for `'Investment'` type in the offers table
  - Added Accept/Reject buttons for pending investment offers
  - Added status indicators for accepted/rejected investment offers
  - Investment offers show their offer ID as the "Code"

### 5. **Added Investment Offer Handlers**
- **File**: `components/startup-health/CapTableTab.tsx`
- **Changes**:
  - Added `handleAcceptInvestmentOffer` function
  - Added `handleRejectInvestmentOffer` function
  - Both functions update the offer status in the database and reload the offers list

## Code Changes Summary

### Import Addition
```typescript
import { startupAdditionService, investmentService } from '../../lib/database';
```

### Interface Update
```typescript
interface OfferReceived {
  id: string;
  from: string;
  type: 'Incubation' | 'Due Diligence' | 'Investment'; // Added 'Investment'
  offerDetails: string;
  status: 'pending' | 'accepted' | 'rejected';
  code: string;
  agreementUrl?: string;
  applicationId?: string; // Made optional
  createdAt: string;
  isInvestmentOffer?: boolean; // New field
  investmentOfferId?: number; // New field
}
```

### Function Enhancement
```typescript
const loadOffersReceived = async () => {
  // ... existing code ...
  
  // Fetch investment offers for this startup
  const investmentOffers = await investmentService.getOffersForStartup(startup.id);
  
  // Transform investment offers into OfferReceived format
  const investmentOffersFormatted: OfferReceived[] = investmentOffers.map((offer: any) => ({
    id: `investment_${offer.id}`,
    from: offer.investorEmail,
    type: 'Investment' as const,
    offerDetails: `${formatCurrency(offer.offerAmount, startupCurrency)} for ${offer.equityPercentage}% equity`,
    status: offer.status as 'pending' | 'accepted' | 'rejected',
    code: offer.id.toString(),
    createdAt: offer.createdAt,
    isInvestmentOffer: true,
    investmentOfferId: offer.id
  }));
  
  // Combine and sort all offers
  const allOffers: OfferReceived[] = [...investmentOffersFormatted, ...incubationOffers]
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    
  setOffersReceived(allOffers);
};
```

### Table Rendering Enhancement
```typescript
{offer.type === 'Investment' && offer.status === 'pending' && (
  <div className="flex gap-2">
    <Button onClick={() => handleAcceptInvestmentOffer(offer)}>
      Accept
    </Button>
    <Button onClick={() => handleRejectInvestmentOffer(offer)}>
      Reject
    </Button>
  </div>
)}
```

## Result
- ✅ Investment offers now appear in the "Offers Received" section
- ✅ Startups can see all investment offers made to them
- ✅ Startups can accept or reject investment offers directly from the CapTable
- ✅ Investment offers are properly formatted and sorted by date
- ✅ The table shows both incubation opportunities and investment offers in one unified view

## Testing
To verify the fix:
1. Have an investor make an investment offer to a startup
2. Go to the startup's CapTable tab
3. Check the "Offers Received" section
4. Verify that the investment offer appears with proper formatting
5. Test accepting/rejecting the offer

The fix ensures that all types of offers (incubation and investment) are properly displayed and manageable from the startup's CapTable interface.
