-- Fix for missing RPC functions causing 404 errors
-- Run this in your Supabase SQL Editor

-- Function to get recommended co-investment opportunities for an investor
CREATE OR REPLACE FUNCTION get_recommended_co_investment_opportunities(
    p_investor_id UUID
) RETURNS TABLE (
    recommendation_id INTEGER,
    opportunity_id INTEGER,
    startup_name TEXT,
    sector TEXT,
    investment_amount DECIMAL(15,2),
    equity_percentage DECIMAL(5,2),
    lead_investor TEXT,
    compliance_status TEXT,
    recommended_at TIMESTAMP WITH TIME ZONE,
    recommendation_status TEXT,
    advisor_name TEXT
) AS $$
BEGIN
    -- For now, return empty result set to prevent 404 errors
    -- This can be enhanced later when the co-investment system is fully implemented
    RETURN QUERY
    SELECT 
        NULL::INTEGER as recommendation_id,
        NULL::INTEGER as opportunity_id,
        NULL::TEXT as startup_name,
        NULL::TEXT as sector,
        NULL::DECIMAL(15,2) as investment_amount,
        NULL::DECIMAL(5,2) as equity_percentage,
        NULL::TEXT as lead_investor,
        NULL::TEXT as compliance_status,
        NULL::TIMESTAMP WITH TIME ZONE as recommended_at,
        NULL::TEXT as recommendation_status,
        NULL::TEXT as advisor_name
    WHERE FALSE; -- This ensures no rows are returned
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_recommended_co_investment_opportunities(UUID) TO authenticated;

-- Alternative function that returns all co-investment opportunities (if needed)
CREATE OR REPLACE FUNCTION get_all_co_investment_opportunities()
RETURNS TABLE (
    opportunity_id INTEGER,
    startup_id INTEGER,
    startup_name TEXT,
    sector TEXT,
    investment_amount DECIMAL(15,2),
    equity_percentage DECIMAL(5,2),
    lead_investor TEXT,
    compliance_status TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    -- For now, return empty result set to prevent 404 errors
    -- This can be enhanced later when the co-investment system is fully implemented
    RETURN QUERY
    SELECT 
        NULL::INTEGER as opportunity_id,
        NULL::INTEGER as startup_id,
        NULL::TEXT as startup_name,
        NULL::TEXT as sector,
        NULL::DECIMAL(15,2) as investment_amount,
        NULL::DECIMAL(5,2) as equity_percentage,
        NULL::TEXT as lead_investor,
        NULL::TEXT as compliance_status,
        NULL::TIMESTAMP WITH TIME ZONE as created_at
    WHERE FALSE; -- This ensures no rows are returned
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_all_co_investment_opportunities() TO authenticated;
