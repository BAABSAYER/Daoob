import { useAuth } from "@/hooks/use-auth";
import { Redirect } from "wouter";

// Role-based dashboard router
export default function Dashboard() {
  const { user, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
      </div>
    );
  }

  if (!user) {
    return <Redirect to="/auth" />;
  }

  // Route based on user type
  switch (user.userType) {
    case 'admin':
      return <Redirect to="/admin" />;
    case 'vendor':
      return <Redirect to="/vendor/dashboard" />;
    case 'client':
    default:
      return <Redirect to="/client/home" />;
  }
}