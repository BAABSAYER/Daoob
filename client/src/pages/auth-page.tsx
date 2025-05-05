import { useEffect } from "react";
import { useLocation } from "wouter";
import { useAuth } from "@/hooks/use-auth";
import { LoginForm } from "@/components/auth/auth-forms";
import logoSvg from "@/assets/daoob-logo-simple.svg";

export default function AuthPage() {
  const { user } = useAuth();
  const [, navigate] = useLocation();
  
  // Redirect to home if already logged in
  useEffect(() => {
    if (user) {
      navigate('/');
    }
  }, [user, navigate]);
  
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <img src={logoSvg} alt="DAOOB Logo" className="h-16 mx-auto mb-2" />
          <h2 className="mt-6 text-center text-3xl font-bold text-gray-900">Admin Login</h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Enter your credentials to access the admin dashboard
          </p>
        </div>
        
        <div className="mt-8 bg-white py-8 px-4 shadow rounded-lg sm:px-10">
          <LoginForm />
          
          <div className="mt-6">
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-300"></div>
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-2 bg-white text-gray-500">
                  Admin dashboard access only
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
