import { supabase } from './supabase';

export interface OpportunityWithCode {
    id: string;
    facilitator_id: string;
    facilitator_code: string;
    facilitator_name: string;
    program_name: string;
    description: string;
    deadline: string;
    poster_url?: string;
    video_url?: string;
    created_at: string;
}

export interface ApplicationWithCode {
    id: string;
    opportunity_id: string;
    startup_id: number;
    startup_name: string;
    facilitator_code: string;
    facilitator_name: string;
    program_name: string;
    status: string;
    diligence_status: string;
    agreement_url?: string;
    created_at: string;
}

/**
 * Get all opportunities with facilitator codes
 */
export async function getOpportunitiesWithCodes(): Promise<OpportunityWithCode[]> {
    try {
        const { data, error } = await supabase
            .rpc('get_opportunities_with_codes');
        
        if (error) {
            console.error('Error getting opportunities with codes:', error);
            return [];
        }
        
        return data || [];
    } catch (err) {
        console.error('Error getting opportunities with codes:', err);
        return [];
    }
}

/**
 * Get all applications with facilitator codes
 */
export async function getApplicationsWithCodes(): Promise<ApplicationWithCode[]> {
    try {
        const { data, error } = await supabase
            .rpc('get_applications_with_codes');
        
        if (error) {
            console.error('Error getting applications with codes:', error);
            return [];
        }
        
        return data || [];
    } catch (err) {
        console.error('Error getting applications with codes:', err);
        return [];
    }
}

/**
 * Post a new opportunity (automatically includes facilitator code)
 */
export async function postOpportunity(opportunityData: {
    program_name: string;
    description: string;
    deadline: string;
    poster_url?: string;
    video_url?: string;
}): Promise<{ success: boolean; error?: string }> {
    try {
        const { data: { user } } = await supabase.auth.getUser();
        
        if (!user) {
            return { success: false, error: 'User not authenticated' };
        }

        const { data, error } = await supabase
            .from('incubation_opportunities')
            .insert({
                facilitator_id: user.id,
                program_name: opportunityData.program_name,
                description: opportunityData.description,
                deadline: opportunityData.deadline,
                poster_url: opportunityData.poster_url,
                video_url: opportunityData.video_url
            })
            .select()
            .single();

        if (error) {
            console.error('Error posting opportunity:', error);
            return { success: false, error: error.message };
        }

        return { success: true };
    } catch (err) {
        console.error('Error posting opportunity:', err);
        return { success: false, error: 'Failed to post opportunity' };
    }
}

/**
 * Get opportunities for a specific facilitator
 */
export async function getFacilitatorOpportunities(facilitatorId: string): Promise<OpportunityWithCode[]> {
    try {
        const { data, error } = await supabase
            .from('incubation_opportunities')
            .select(`
                *,
                users!incubation_opportunities_facilitator_id_fkey (
                    name,
                    facilitator_code
                )
            `)
            .eq('facilitator_id', facilitatorId)
            .order('created_at', { ascending: false });

        if (error) {
            console.error('Error getting facilitator opportunities:', error);
            return [];
        }

        return data?.map(opp => ({
            id: opp.id,
            facilitator_id: opp.facilitator_id,
            facilitator_code: opp.users?.facilitator_code || 'FAC-XXXXXX',
            facilitator_name: opp.users?.name || 'Unknown Facilitator',
            program_name: opp.program_name,
            description: opp.description,
            deadline: opp.deadline,
            poster_url: opp.poster_url,
            video_url: opp.video_url,
            created_at: opp.created_at
        })) || [];
    } catch (err) {
        console.error('Error getting facilitator opportunities:', err);
        return [];
    }
}

/**
 * Get applications for a specific facilitator
 */
export async function getFacilitatorApplications(facilitatorId: string): Promise<ApplicationWithCode[]> {
    try {
        const { data, error } = await supabase
            .from('opportunity_applications')
            .select(`
                *,
                incubation_opportunities!opportunity_applications_opportunity_id_fkey (
                    program_name,
                    facilitator_id,
                    users!incubation_opportunities_facilitator_id_fkey (
                        name,
                        facilitator_code
                    )
                ),
                startups!opportunity_applications_startup_id_fkey (
                    name
                )
            `)
            .eq('incubation_opportunities.facilitator_id', facilitatorId)
            .order('created_at', { ascending: false });

        if (error) {
            console.error('Error getting facilitator applications:', error);
            return [];
        }

        return data?.map(app => ({
            id: app.id,
            opportunity_id: app.opportunity_id,
            startup_id: app.startup_id,
            startup_name: app.startups?.name || 'Unknown Startup',
            facilitator_code: app.incubation_opportunities?.users?.facilitator_code || 'FAC-XXXXXX',
            facilitator_name: app.incubation_opportunities?.users?.name || 'Unknown Facilitator',
            program_name: app.incubation_opportunities?.program_name || 'Unknown Program',
            status: app.status,
            diligence_status: app.diligence_status || 'none',
            agreement_url: app.agreement_url,
            created_at: app.created_at
        })) || [];
    } catch (err) {
        console.error('Error getting facilitator applications:', err);
        return [];
    }
}
