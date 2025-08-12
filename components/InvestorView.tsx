import React, { useState, useEffect } from 'react';
import { Startup, NewInvestment, ComplianceStatus, StartupAdditionRequest, InvestmentType } from '../types';
import Card from './ui/Card';
import Button from './ui/Button';
import Badge from './ui/Badge';
import PortfolioDistributionChart from './charts/PortfolioDistributionChart';
import Modal from './ui/Modal';
import Input from './ui/Input';
import { TrendingUp, DollarSign, CheckSquare, Eye, PlusCircle, Activity, FileText, Video, Users, Heart, CheckCircle, LayoutGrid, Film } from 'lucide-react';

interface InvestorViewProps {
  startups: Startup[];
  newInvestments: NewInvestment[];
  startupAdditionRequests: StartupAdditionRequest[];
  onViewStartup: (id: number) => void;
  onAcceptRequest: (id: number) => void;
  onMakeOffer: (opportunity: NewInvestment, offerAmount: number, equityPercentage: number) => void;
}

const SummaryCard: React.FC<{ title: string; value: string; icon: React.ReactNode }> = ({ title, value, icon }) => (
    <Card className="flex-1">
        <div className="flex items-center justify-between">
            <div>
                <p className="text-sm font-medium text-slate-500">{title}</p>
                <p className="text-2xl font-bold text-slate-800">{value}</p>
            </div>
            <div className="p-3 bg-brand-light rounded-full">
                {icon}
            </div>
        </div>
    </Card>
);

const InvestorView: React.FC<InvestorViewProps> = ({ startups, newInvestments, startupAdditionRequests, onViewStartup, onAcceptRequest, onMakeOffer }) => {
    const formatCurrency = (value: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', notation: 'compact' }).format(value);
    
    const [isOfferModalOpen, setIsOfferModalOpen] = useState(false);
    const [selectedOpportunity, setSelectedOpportunity] = useState<NewInvestment | null>(null);
    const [activeTab, setActiveTab] = useState<'dashboard' | 'reels'>('dashboard');
    const [shuffledPitches, setShuffledPitches] = useState<NewInvestment[]>([]);

    useEffect(() => {
        // Only shuffle when the reels tab is active to get a new order each time it's opened.
        if (activeTab === 'reels') {
            const verified = newInvestments.filter(inv => inv.complianceStatus === ComplianceStatus.Compliant);
            const unverified = newInvestments.filter(inv => inv.complianceStatus !== ComplianceStatus.Compliant);

            const shuffleArray = (array: NewInvestment[]): NewInvestment[] => {
                const shuffled = [...array];
                for (let i = shuffled.length - 1; i > 0; i--) {
                    const j = Math.floor(Math.random() * (i + 1));
                    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
                }
                return shuffled;
            };
            
            const shuffledVerified = shuffleArray(verified);
            const shuffledUnverified = shuffleArray(unverified);

            const result: NewInvestment[] = [];
            let i = 0, j = 0;
            // Interleave with a 2:1 ratio (approx 66%) for verified to unverified
            while (i < shuffledVerified.length || j < shuffledUnverified.length) {
                // Add 2 verified pitches if available
                if (i < shuffledVerified.length) result.push(shuffledVerified[i++]);
                if (i < shuffledVerified.length) result.push(shuffledVerified[i++]);
                
                // Add 1 unverified pitch if available
                if (j < shuffledUnverified.length) result.push(shuffledUnverified[j++]);
            }
            setShuffledPitches(result);
        }
    }, [newInvestments, activeTab]);

    const totalFunding = startups.reduce((acc, s) => acc + s.totalFunding, 0);
    const totalRevenue = startups.reduce((acc, s) => acc + s.totalRevenue, 0);
    const compliantCount = startups.filter(s => s.complianceStatus === ComplianceStatus.Compliant).length;
    const complianceRate = startups.length > 0 ? (compliantCount / startups.length) * 100 : 0;

    const handleMakeOfferClick = (opportunity: NewInvestment) => {
        setSelectedOpportunity(opportunity);
        setIsOfferModalOpen(true);
    };
    
    const handleOfferSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (!selectedOpportunity) return;
        
        const form = e.currentTarget as HTMLFormElement;
        const offerAmountInput = form.elements.namedItem('offer-amount') as HTMLInputElement;
        const offerEquityInput = form.elements.namedItem('offer-equity') as HTMLInputElement;
        
        const offerAmount = Number(offerAmountInput.value);
        const equityPercentage = Number(offerEquityInput.value);

        onMakeOffer(selectedOpportunity, offerAmount, equityPercentage);
        
        setIsOfferModalOpen(false);
        setSelectedOpportunity(null);
    };
    
    const getYoutubeEmbedUrl = (url: string | undefined): string | null => {
        if (!url) return null;
        let videoId = null;
        try {
            const urlObj = new URL(url);
            const hostname = urlObj.hostname;
            const pathname = urlObj.pathname;

            if (hostname.includes('youtube.com')) {
                if (pathname.startsWith('/shorts/')) {
                    videoId = pathname.substring('/shorts/'.length);
                } else if (pathname.startsWith('/watch')) {
                    videoId = urlObj.searchParams.get('v');
                } else if (pathname.startsWith('/embed/')) {
                    videoId = pathname.substring('/embed/'.length);
                }
            } else if (hostname === 'youtu.be') {
                videoId = pathname.substring(1);
            }

            if (videoId) {
                const queryIndex = videoId.indexOf('?');
                if (queryIndex > -1) {
                    videoId = videoId.substring(0, queryIndex);
                }
                const slashIndex = videoId.indexOf('/');
                if (slashIndex > -1) {
                    videoId = videoId.substring(0, slashIndex);
                }
            }
            
            return videoId ? `https://www.youtube.com/embed/${videoId}` : null;
        } catch (e) {
            console.error('Invalid URL for YouTube embed:', url, e);
            return null;
        }
    };
    
  return (
    <div className="space-y-6">
       {/* Tab Navigation */}
        <div className="border-b border-slate-200">
            <nav className="-mb-px flex space-x-6" aria-label="Tabs">
                 <button
                    onClick={() => setActiveTab('dashboard')}
                    className={`${
                        activeTab === 'dashboard'
                        ? 'border-brand-primary text-brand-primary'
                        : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
                    } flex items-center gap-2 whitespace-nowrap py-3 px-1 border-b-2 font-medium text-sm transition-colors focus:outline-none`}
                >
                    <LayoutGrid className="h-5 w-5" />
                    Dashboard
                </button>
                <button
                    onClick={() => setActiveTab('reels')}
                    className={`${
                        activeTab === 'reels'
                        ? 'border-brand-primary text-brand-primary'
                        : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
                    } flex items-center gap-2 whitespace-nowrap py-3 px-1 border-b-2 font-medium text-sm transition-colors focus:outline-none`}
                >
                    <Film className="h-5 w-5" />
                   Discover Pitches
                </button>
            </nav>
        </div>

      {activeTab === 'dashboard' && (
        <div className="space-y-8 animate-fade-in">
          {/* Summary Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <SummaryCard title="Total Funding" value={formatCurrency(totalFunding)} icon={<DollarSign className="h-6 w-6 text-brand-primary" />} />
            <SummaryCard title="Total Revenue" value={formatCurrency(totalRevenue)} icon={<TrendingUp className="h-6 w-6 text-brand-primary" />} />
            <SummaryCard title="Compliance Rate" value={`${complianceRate.toFixed(1)}%`} icon={<CheckSquare className="h-6 w-6 text-brand-primary" />} />
            <SummaryCard title="Active Subscriptions" value={`${startups.length}`} icon={<Users className="h-6 w-6 text-brand-primary" />} />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 space-y-8">
                {/* Add Startup Requests */}
                 <Card>
                    <h3 className="text-lg font-semibold mb-4 text-slate-700">Add Startup Requests</h3>
                    <div className="overflow-x-auto">
                        <table className="min-w-full divide-y divide-slate-200">
                            <thead className="bg-slate-50">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Startup Name</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Value</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Equity</th>
                                    <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="bg-white divide-y divide-slate-200">
                                {startupAdditionRequests.map(req => (
                                    <tr key={req.id}>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900">{req.name}</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">{formatCurrency(req.investmentValue)}</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">{req.equityAllocation}%</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                            <Button size="sm" onClick={() => onAcceptRequest(req.id)}><PlusCircle className="mr-2 h-4 w-4"/> Add to Portfolio</Button>
                                        </td>
                                    </tr>
                                ))}
                                 {startupAdditionRequests.length === 0 && (
                                    <tr>
                                        <td colSpan={4} className="text-center py-8 text-slate-500">No pending startup requests.</td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    </div>
                </Card>

                {/* Old Table for New Investment Opportunities - can be removed or kept */}

                {/* My Startups Table */}
                <Card>
                    <h3 className="text-lg font-semibold mb-4 text-slate-700">My Startups</h3>
                    <div className="overflow-x-auto">
                        <table className="min-w-full divide-y divide-slate-200">
                            <thead className="bg-slate-50">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Startup Name</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Current Valuation</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Compliance Status</th>
                                    <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="bg-white divide-y divide-slate-200">
                                {startups.map(startup => (
                                    <tr key={startup.id}>
                                        <td className="px-6 py-4 whitespace-nowrap">
                                            <div className="text-sm font-medium text-slate-900">{startup.name}</div>
                                            <div className="text-xs text-slate-500">{startup.sector}</div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">{formatCurrency(startup.currentValuation)}</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500"><Badge status={startup.complianceStatus} /></td>
                                        <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                            <Button size="sm" variant="outline" onClick={() => onViewStartup(startup.id)}><Eye className="mr-2 h-4 w-4" /> View</Button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </Card>
            </div>
            <div className="space-y-8">
                <PortfolioDistributionChart data={startups} />
                <Card>
                    <h3 className="text-lg font-semibold mb-4 text-slate-700 flex items-center gap-2"><Activity className="h-5 w-5 text-brand-accent"/> Recent Activity</h3>
                    <div className="space-y-4">
                       <div className="text-sm text-slate-500 text-center py-10">Activity feed coming soon...</div>
                    </div>
                </Card>
            </div>
          </div>
        </div>
      )}

       {activeTab === 'reels' && (
            <div className="animate-fade-in max-w-md mx-auto">
                 <div className="h-[calc(100vh-180px)] md:h-auto overflow-y-auto snap-y snap-mandatory space-y-8 md:space-y-6">
                    {shuffledPitches.length > 0 ? shuffledPitches.map(inv => {
                        const embedUrl = getYoutubeEmbedUrl(inv.pitchVideoUrl);
                        return (
                            <Card key={inv.id} className="!p-0 overflow-hidden snap-center flex flex-col">
                                {embedUrl ? (
                                    <div className="relative w-full aspect-[16/9] bg-slate-800">
                                        <iframe 
                                            src={embedUrl}
                                            title={`Pitch video for ${inv.name}`}
                                            frameBorder="0" 
                                            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
                                            allowFullScreen
                                            className="absolute top-0 left-0 w-full h-full"
                                        ></iframe>
                                    </div>
                                ) : (
                                    <div className="w-full bg-slate-200 flex items-center justify-center text-slate-500 aspect-[16/9]">
                                        <Video className="h-12 w-12" />
                                        <p className="ml-2">Video not available</p>
                                    </div>
                                )}
                                <div className="p-4 flex-grow">
                                    <h3 className="text-xl font-bold text-slate-800">{inv.name}</h3>
                                    <p className="text-sm text-slate-500">{inv.sector}</p>
                                    
                                    <div className="flex items-center justify-between mt-4">
                                        <div className="flex items-center gap-2">
                                            <Button size="sm" variant="secondary" className="!rounded-full !p-2">
                                                <Heart className="h-5 w-5" />
                                            </Button>
                                             <a href={inv.pitchDeckUrl} target="_blank" rel="noopener noreferrer">
                                                <Button size="sm" variant="secondary">
                                                    <FileText className="h-4 w-4 mr-2" /> View Deck
                                                </Button>
                                            </a>
                                            <Button size="sm" variant="primary" onClick={() => handleMakeOfferClick(inv)}>
                                                <DollarSign className="h-4 w-4 mr-2" /> Make Offer
                                            </Button>
                                        </div>
                                    </div>
                                </div>
                                <div className="bg-slate-50 px-4 py-3 flex justify-between items-center border-t">
                                    <div className="text-sm">
                                        <span className="font-semibold text-slate-800">Ask:</span> {formatCurrency(inv.investmentValue)} for <span className="font-semibold">{inv.equityAllocation}%</span> equity
                                    </div>
                                    {inv.complianceStatus === ComplianceStatus.Compliant && (
                                        <div className="flex items-center gap-1 text-status-compliant" title="This startup has been verified by Startup Nation">
                                            <CheckCircle className="h-5 w-5" />
                                            <span className="text-xs font-semibold">Startup Nation Verified</span>
                                        </div>
                                    )}
                                </div>
                            </Card>
                        )
                    }) : (
                        <Card className="text-center py-20">
                            <h3 className="text-xl font-semibold">No New Pitches</h3>
                            <p className="text-slate-500 mt-2">Check back later for new investment opportunities.</p>
                        </Card>
                    )}
                </div>
            </div>
        )}

       <Modal 
            isOpen={isOfferModalOpen} 
            onClose={() => setIsOfferModalOpen(false)} 
            title={`Make an Offer for ${selectedOpportunity?.name}`}
        >
            <form onSubmit={handleOfferSubmit} className="space-y-4">
                <p className="text-sm text-slate-600">
                    You are making an offer for <span className="font-semibold">{selectedOpportunity?.name}</span>. 
                    The current ask is <span className="font-semibold">{formatCurrency(selectedOpportunity?.investmentValue || 0)}</span> for <span className="font-semibold">{selectedOpportunity?.equityAllocation}%</span> equity.
                </p>
                <Input label="Your Investment Offer (USD)" id="offer-amount" name="offer-amount" type="number" required />
                <Input label="Equity Requested (%)" id="offer-equity" name="offer-equity" type="number" step="0.1" required />
                <div className="flex justify-end gap-3 pt-4">
                    <Button type="button" variant="secondary" onClick={() => setIsOfferModalOpen(false)}>Cancel</Button>
                    <Button type="submit">Submit Offer</Button>
                </div>
            </form>
        </Modal>

        <style>{`
            @keyframes fade-in {
                from { opacity: 0; }
                to { opacity: 1; }
            }
            .animate-fade-in {
                animation: fade-in 0.5s ease-in-out forwards;
            }
            /* Custom scrollbar for webkit browsers */
            .snap-y {
                scrollbar-width: none; /* For Firefox */
            }
            .snap-y::-webkit-scrollbar {
                display: none; /* For Chrome, Safari, and Opera */
            }
        `}</style>
    </div>
  );
};

export default InvestorView;
