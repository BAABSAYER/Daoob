import { useEffect } from "react";
import { useLocation } from "wouter";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/hooks/use-auth";
import { 
  LayoutGrid, Store, Calendar, MessageSquare, Settings, 
  Users, Package, TrendingUp, Clock, AlertTriangle, DollarSign 
} from "lucide-react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";

export default function VendorDashboard() {
  const { user } = useAuth();
  const [, navigate] = useLocation();
  
  // Redirect to regular dashboard if not a vendor
  useEffect(() => {
    if (user && user.userType !== 'vendor') {
      navigate("/");
    }
  }, [user, navigate]);
  
  // Fetch vendor details and stats
  const { data: vendorData, isLoading: vendorLoading } = useQuery({
    queryKey: ['/api/vendors/dashboard'],
    enabled: !!user && user.userType === 'vendor',
  });
  
  // Fetch recent bookings
  const { data: recentBookings, isLoading: bookingsLoading } = useQuery({
    queryKey: ['/api/bookings/recent'],
    enabled: !!user && user.userType === 'vendor',
  });
  
  if (vendorLoading) {
    return <VendorDashboardSkeleton />;
  }
  
  const stats = vendorData?.stats || {
    totalBookings: 0,
    pendingBookings: 0,
    confirmedBookings: 0,
    totalEarnings: 0,
    avgRating: 0,
    totalReviews: 0
  };
  
  const recentBookingsList = recentBookings || [];

  return (
    <div className="px-5 py-6 pb-24 max-w-3xl mx-auto">
      {/* Header */}
      <div className="mb-6">
        <h1 className="font-poppins font-bold text-2xl text-neutral-800">Vendor Dashboard</h1>
        <p className="text-neutral-600">Manage your business, bookings, and services</p>
      </div>
      
      {/* Quick Links */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        <QuickLink 
          icon={<Store className="h-5 w-5" />} 
          label="Services" 
          onClick={() => navigate("/vendor-dashboard/services")} 
        />
        <QuickLink 
          icon={<Calendar className="h-5 w-5" />} 
          label="Bookings" 
          onClick={() => navigate("/vendor-dashboard/bookings")} 
        />
        <QuickLink 
          icon={<MessageSquare className="h-5 w-5" />} 
          label="Messages" 
          onClick={() => navigate("/messages")} 
        />
        <QuickLink 
          icon={<Settings className="h-5 w-5" />} 
          label="Settings" 
          onClick={() => navigate("/vendor-dashboard/profile")} 
        />
      </div>
      
      {/* Overview Stats */}
      <div className="bg-white rounded-xl p-5 shadow-sm mb-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="font-poppins font-semibold text-lg text-neutral-800">Overview</h2>
          <Button variant="outline" size="sm" className="text-sm">
            View Reports
          </Button>
        </div>
        
        <div className="grid grid-cols-2 gap-4">
          <StatCard 
            icon={<DollarSign className="h-5 w-5 text-green-500" />}
            label="Total Revenue"
            value={`$${stats.totalEarnings.toLocaleString()}`}
          />
          <StatCard 
            icon={<Calendar className="h-5 w-5 text-blue-500" />}
            label="Total Bookings"
            value={stats.totalBookings.toString()}
          />
          <StatCard 
            icon={<Clock className="h-5 w-5 text-orange-500" />}
            label="Pending Bookings"
            value={stats.pendingBookings.toString()}
          />
          <StatCard 
            icon={<TrendingUp className="h-5 w-5 text-purple-500" />}
            label="Rating"
            value={`${stats.avgRating.toFixed(1)} (${stats.totalReviews})`}
          />
        </div>
      </div>
      
      {/* Recent Bookings */}
      <div className="bg-white rounded-xl p-5 shadow-sm mb-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="font-poppins font-semibold text-lg text-neutral-800">Recent Bookings</h2>
          <Button 
            variant="link" 
            size="sm" 
            className="text-sm text-secondary"
            onClick={() => navigate("/vendor-dashboard/bookings")}
          >
            View All
          </Button>
        </div>
        
        {bookingsLoading ? (
          <div className="space-y-3">
            {[1, 2, 3].map(i => (
              <div key={i} className="flex items-center py-3 border-b border-neutral-100">
                <Skeleton className="h-10 w-10 rounded-full mr-3" />
                <div className="flex-1">
                  <Skeleton className="h-4 w-28 mb-2" />
                  <Skeleton className="h-3 w-36" />
                </div>
                <Skeleton className="h-8 w-20 rounded" />
              </div>
            ))}
          </div>
        ) : recentBookingsList.length > 0 ? (
          <div>
            {recentBookingsList.map((booking: any) => (
              <div key={booking.id} className="flex items-center justify-between py-3 border-b border-neutral-100 last:border-0">
                <div className="flex items-center">
                  <div className="w-10 h-10 bg-neutral-100 rounded-full flex items-center justify-center mr-3">
                    <Users className="h-5 w-5 text-neutral-500" />
                  </div>
                  <div>
                    <p className="font-medium text-neutral-800">{booking.clientName || 'Client'}</p>
                    <p className="text-sm text-neutral-600">
                      {booking.eventType} • {new Date(booking.eventDate).toLocaleDateString()}
                    </p>
                  </div>
                </div>
                <BookingStatusBadge status={booking.status} />
              </div>
            ))}
          </div>
        ) : (
          <div className="py-6 text-center">
            <Package className="h-10 w-10 text-neutral-300 mx-auto mb-2" />
            <p className="text-neutral-600">No bookings yet</p>
          </div>
        )}
        
        {recentBookingsList.length > 0 && (
          <Button 
            className="w-full mt-4 bg-secondary text-white"
            onClick={() => navigate("/vendor-dashboard/bookings")}
          >
            Manage All Bookings
          </Button>
        )}
      </div>
      
      {/* Action Buttons */}
      <div className="grid grid-cols-1 gap-4">
        <Button 
          onClick={() => navigate("/vendor-dashboard/services/new")} 
          className="bg-secondary text-white"
        >
          <Package className="h-5 w-5 mr-2" />
          Add New Service
        </Button>
      </div>
    </div>
  );
}

function QuickLink({ icon, label, onClick }: { icon: React.ReactNode, label: string, onClick: () => void }) {
  return (
    <button 
      onClick={onClick}
      className="flex flex-col items-center justify-center bg-white rounded-xl p-4 shadow-sm hover:bg-neutral-50 transition-colors"
    >
      <div className="text-secondary mb-2">
        {icon}
      </div>
      <span className="text-sm text-neutral-800">{label}</span>
    </button>
  );
}

function StatCard({ icon, label, value }: { icon: React.ReactNode, label: string, value: string }) {
  return (
    <div className="bg-neutral-50 rounded-lg p-4">
      <div className="flex items-center mb-2">
        <div className="mr-2">{icon}</div>
        <span className="text-sm text-neutral-600">{label}</span>
      </div>
      <p className="text-xl font-semibold text-neutral-800">{value}</p>
    </div>
  );
}

function BookingStatusBadge({ status }: { status: string }) {
  let color, textColor, bgColor;
  
  switch (status.toLowerCase()) {
    case 'confirmed':
      color = 'text-green-600';
      textColor = 'text-green-600';
      bgColor = 'bg-green-100';
      break;
    case 'pending':
      color = 'text-yellow-600';
      textColor = 'text-yellow-600';
      bgColor = 'bg-yellow-100';
      break;
    case 'cancelled':
      color = 'text-red-600';
      textColor = 'text-red-600';
      bgColor = 'bg-red-100';
      break;
    case 'completed':
      color = 'text-blue-600';
      textColor = 'text-blue-600';
      bgColor = 'bg-blue-100';
      break;
    default:
      color = 'text-neutral-600';
      textColor = 'text-neutral-600';
      bgColor = 'bg-neutral-100';
  }
  
  return (
    <span className={`${bgColor} ${textColor} text-xs px-2 py-1 rounded-full font-medium capitalize`}>
      {status}
    </span>
  );
}

function VendorDashboardSkeleton() {
  return (
    <div className="px-5 py-6 max-w-3xl mx-auto">
      <div className="mb-6">
        <Skeleton className="h-8 w-48 mb-2" />
        <Skeleton className="h-4 w-64" />
      </div>
      
      <div className="grid grid-cols-4 gap-4 mb-6">
        {[1, 2, 3, 4].map((i) => (
          <Skeleton key={i} className="h-20 rounded-xl" />
        ))}
      </div>
      
      <Skeleton className="h-52 rounded-xl mb-6" />
      <Skeleton className="h-64 rounded-xl mb-6" />
      <Skeleton className="h-12 rounded-xl" />
    </div>
  );
}