import { useEffect } from "react";
import { useLocation } from "wouter";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/hooks/use-auth";
import { 
  LayoutGrid, Users, BarChart, Calendar, Settings, 
  Search, TrendingUp, UserCheck, DollarSign, CheckCircle, 
  HelpCircle, AlertTriangle, Clock, ChevronRight
} from "lucide-react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

export default function AdminDashboard() {
  const { user } = useAuth();
  const [, navigate] = useLocation();
  
  // Redirect if not an admin
  useEffect(() => {
    if (user && user.userType !== 'admin') {
      navigate("/");
    }
  }, [user, navigate]);
  
  // Fetch admin dashboard data
  const { data: dashboardData, isLoading } = useQuery({
    queryKey: ['/api/admin/dashboard'],
    enabled: !!user && user.userType === 'admin',
  });
  
  if (isLoading) {
    return <AdminDashboardSkeleton />;
  }
  
  // Use default values if data is not available
  const stats = dashboardData?.stats || {
    totalUsers: 0,
    totalVendors: 0,
    totalClients: 0,
    pendingVendorApprovals: 0,
    totalBookings: 0,
    pendingBookings: 0,
    completedBookings: 0,
    cancelledBookings: 0,
    recentBookings: [],
    recentUsers: []
  };
  
  return (
    <div className="bg-gray-50 min-h-screen pb-20">
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Admin Dashboard</h1>
              <p className="text-gray-600">Manage platform users, vendors, and bookings</p>
            </div>
            <div className="flex items-center space-x-4">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                <Input 
                  className="pl-10 w-64" 
                  placeholder="Search users, vendors..." 
                />
              </div>
              <Select defaultValue="today">
                <SelectTrigger className="w-40">
                  <SelectValue placeholder="Select timeframe" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="today">Today</SelectItem>
                  <SelectItem value="week">This Week</SelectItem>
                  <SelectItem value="month">This Month</SelectItem>
                  <SelectItem value="year">This Year</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Quick Navigation */}
        <div className="grid grid-cols-4 gap-6 mb-8">
          <NavCard 
            icon={<Users className="h-5 w-5" />}
            title="Users"
            description={`${stats.totalUsers} total users`}
            onClick={() => navigate("/admin/users")}
          />
          <NavCard 
            icon={<UserCheck className="h-5 w-5" />}
            title="Vendors"
            description={`${stats.pendingVendorApprovals} pending approvals`}
            onClick={() => navigate("/admin/vendors")}
            alert={stats.pendingVendorApprovals > 0}
          />
          <NavCard 
            icon={<Calendar className="h-5 w-5" />}
            title="Bookings"
            description={`${stats.pendingBookings} pending bookings`}
            onClick={() => navigate("/admin/bookings")}
          />
          <NavCard 
            icon={<Settings className="h-5 w-5" />}
            title="Settings"
            description="Platform configuration"
            onClick={() => navigate("/admin/settings")}
          />
        </div>
        
        {/* Overview Stats */}
        <h2 className="text-xl font-semibold text-gray-800 mb-4">Platform Overview</h2>
        <div className="grid grid-cols-4 gap-6 mb-8">
          <StatCard 
            icon={<Users className="h-6 w-6 text-blue-500" />}
            label="Total Users"
            value={stats.totalUsers}
            change="+5%"
            positive={true}
          />
          <StatCard 
            icon={<Calendar className="h-6 w-6 text-green-500" />}
            label="Total Bookings"
            value={stats.totalBookings}
            change="+12%"
            positive={true}
          />
          <StatCard 
            icon={<DollarSign className="h-6 w-6 text-purple-500" />}
            label="Platform Revenue"
            value="$12,450"
            change="+8%"
            positive={true}
          />
          <StatCard 
            icon={<TrendingUp className="h-6 w-6 text-orange-500" />}
            label="Active Vendors"
            value={stats.totalVendors}
            change="+3%"
            positive={true}
          />
        </div>
        
        {/* Recent Activity and Pending Tasks */}
        <div className="grid grid-cols-2 gap-6">
          <Card className="p-6">
            <h3 className="text-lg font-semibold mb-4">Recent Users</h3>
            {stats.recentUsers && stats.recentUsers.length > 0 ? (
              <div className="space-y-4">
                {stats.recentUsers.map((user: any, index: number) => (
                  <div key={index} className="flex items-center justify-between border-b border-gray-100 pb-3 last:border-0 last:pb-0">
                    <div className="flex items-center">
                      <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center mr-3">
                        {user.userType === 'vendor' ? (
                          <UserCheck className="h-5 w-5 text-gray-500" />
                        ) : (
                          <Users className="h-5 w-5 text-gray-500" />
                        )}
                      </div>
                      <div>
                        <p className="font-medium">{user.fullName || user.username}</p>
                        <p className="text-sm text-gray-500 capitalize">{user.userType}</p>
                      </div>
                    </div>
                    <div className="text-sm text-gray-500">
                      {new Date(user.createdAt).toLocaleDateString()}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8 text-gray-500">
                No recent users to display
              </div>
            )}
            <Button 
              variant="outline" 
              className="w-full mt-4"
              onClick={() => navigate("/admin/users")}
            >
              View All Users
            </Button>
          </Card>
          
          <Card className="p-6">
            <h3 className="text-lg font-semibold mb-4">Pending Tasks</h3>
            <div className="space-y-4">
              <TaskItem 
                icon={<UserCheck className="h-5 w-5 text-blue-500" />}
                title="Vendor Approvals"
                count={stats.pendingVendorApprovals}
                onClick={() => navigate("/admin/vendors")}
              />
              <TaskItem 
                icon={<HelpCircle className="h-5 w-5 text-yellow-500" />}
                title="Pending Bookings"
                count={stats.pendingBookings}
                onClick={() => navigate("/admin/bookings")}
              />
              <TaskItem 
                icon={<AlertTriangle className="h-5 w-5 text-red-500" />}
                title="Reported Issues"
                count={3}
                onClick={() => {}}
              />
              <TaskItem 
                icon={<Clock className="h-5 w-5 text-purple-500" />}
                title="System Notifications"
                count={2}
                onClick={() => {}}
              />
            </div>
            <Separator className="my-4" />
            <div className="text-center">
              <p className="text-sm text-gray-500 mb-2">
                {stats.pendingVendorApprovals + stats.pendingBookings + 5} total pending tasks
              </p>
              <Button 
                className="bg-blue-600 hover:bg-blue-700 text-white"
                onClick={() => navigate("/admin/tasks")}
              >
                Review All Tasks
              </Button>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}

function NavCard({ 
  icon,
  title,
  description,
  onClick,
  alert = false
}: { 
  icon: React.ReactNode;
  title: string;
  description: string;
  onClick: () => void;
  alert?: boolean;
}) {
  return (
    <div
      className="bg-white rounded-lg p-6 border border-gray-200 shadow-sm hover:shadow transition-shadow cursor-pointer relative"
      onClick={onClick}
    >
      {alert && (
        <div className="absolute top-4 right-4 w-3 h-3 bg-red-500 rounded-full" />
      )}
      <div className="text-blue-600 mb-3">{icon}</div>
      <h3 className="font-semibold text-gray-900 mb-1">{title}</h3>
      <p className="text-sm text-gray-500">{description}</p>
    </div>
  );
}

function StatCard({ 
  icon,
  label,
  value,
  change,
  positive
}: { 
  icon: React.ReactNode;
  label: string;
  value: number | string;
  change: string;
  positive: boolean;
}) {
  return (
    <div className="bg-white rounded-lg p-6 border border-gray-200 shadow-sm">
      <div className="flex justify-between items-start mb-3">
        <div>{icon}</div>
        <div className={`text-sm ${positive ? 'text-green-500' : 'text-red-500'} font-medium`}>
          {change}
        </div>
      </div>
      <p className="text-2xl font-bold text-gray-900 mb-1">{value}</p>
      <p className="text-sm text-gray-500">{label}</p>
    </div>
  );
}

function TaskItem({ 
  icon,
  title,
  count,
  onClick
}: { 
  icon: React.ReactNode;
  title: string;
  count: number;
  onClick: () => void;
}) {
  return (
    <div 
      className="flex items-center justify-between p-3 bg-gray-50 rounded-md cursor-pointer hover:bg-gray-100"
      onClick={onClick}
    >
      <div className="flex items-center">
        {icon}
        <span className="ml-3 font-medium">{title}</span>
      </div>
      <div className="flex items-center">
        <span className="bg-blue-100 text-blue-800 py-1 px-2 rounded text-xs font-medium">
          {count}
        </span>
        <Button variant="ghost" size="icon" className="ml-1 h-7 w-7">
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}

function AdminDashboardSkeleton() {
  return (
    <div className="bg-gray-50 min-h-screen">
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <Skeleton className="h-8 w-64 mb-2" />
          <Skeleton className="h-4 w-96" />
        </div>
      </div>
      
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="grid grid-cols-4 gap-6 mb-8">
          {[1, 2, 3, 4].map(i => (
            <Skeleton key={i} className="h-32 rounded-lg" />
          ))}
        </div>
        
        <Skeleton className="h-8 w-48 mb-4" />
        <div className="grid grid-cols-4 gap-6 mb-8">
          {[1, 2, 3, 4].map(i => (
            <Skeleton key={i} className="h-32 rounded-lg" />
          ))}
        </div>
        
        <div className="grid grid-cols-2 gap-6">
          <Skeleton className="h-96 rounded-lg" />
          <Skeleton className="h-96 rounded-lg" />
        </div>
      </div>
    </div>
  );
}