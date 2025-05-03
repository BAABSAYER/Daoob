import { useState, useEffect } from "react";
import { useLocation } from "wouter";
import { useAuth } from "@/hooks/use-auth";
import { LoginForm, ClientRegistrationForm, VendorRegistrationForm, AccountTypeSelection } from "@/components/auth/auth-forms";
import { GlassWater, Star, CalendarCheck, UserPlus } from "lucide-react";

enum AuthView {
  LANDING,
  ACCOUNT_TYPE,
  CLIENT_SIGNUP,
  VENDOR_SIGNUP,
  LOGIN
}

export default function AuthPage() {
  const [currentView, setCurrentView] = useState<AuthView>(AuthView.LANDING);
  const { user } = useAuth();
  const [, navigate] = useLocation();
  
  // Redirect to home if already logged in
  useEffect(() => {
    if (user) {
      navigate('/');
    }
  }, [user, navigate]);
  
  // Handle showing the account type selection
  const showAccountTypeSelection = () => {
    setCurrentView(AuthView.ACCOUNT_TYPE);
  };
  
  // Handle showing the login form
  const showLoginForm = () => {
    setCurrentView(AuthView.LOGIN);
  };
  
  // Handle showing the client signup form
  const showClientSignup = () => {
    setCurrentView(AuthView.CLIENT_SIGNUP);
  };
  
  // Handle showing the vendor signup form
  const showVendorSignup = () => {
    setCurrentView(AuthView.VENDOR_SIGNUP);
  };
  
  return (
    <div className="h-full w-full flex flex-col">
      {/* Landing Screen */}
      <div className="relative h-[60vh] bg-gradient-to-b from-secondary/80 to-primary/90 flex items-center justify-center">
        <div 
          className="absolute inset-0 w-full h-full object-cover mix-blend-overlay opacity-60 bg-cover bg-center"
          style={{ backgroundImage: "url('https://images.unsplash.com/photo-1511795409834-ef04bbd61622?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80')" }}
        ></div>
        <div className="relative z-10 text-center px-6">
          <h1 className="font-poppins font-bold text-4xl text-white mb-2">DAOOB</h1>
          <p className="font-inter text-white/90 text-lg mb-8">Your smart event planning partner</p>
          <div className="flex flex-col space-y-3 w-64 mx-auto">
            <button 
              className="bg-white text-secondary font-semibold py-3 px-6 rounded-lg shadow-lg transform hover:scale-105 transition duration-200"
              onClick={showAccountTypeSelection}
            >
              Get Started
            </button>
            <button 
              className="bg-transparent border border-white text-white font-medium py-3 px-6 rounded-lg hover:bg-white/10 transition duration-200"
              onClick={showLoginForm}
            >
              I Already Have an Account
            </button>
          </div>
        </div>
      </div>
      
      <div className="py-8 px-6 flex-1 bg-white">
        <h2 className="font-poppins font-semibold text-2xl text-neutral-800 mb-6">How DAOOB Works</h2>
        
        <div className="grid grid-cols-3 gap-4 mb-10">
          <div className="text-center">
            <div className="w-16 h-16 bg-secondary/10 rounded-full flex items-center justify-center mx-auto mb-3">
              <UserPlus className="text-secondary text-xl" />
            </div>
            <p className="text-sm text-neutral-700">Discover Vendors</p>
          </div>
          <div className="text-center">
            <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-3">
              <CalendarCheck className="text-primary text-xl" />
            </div>
            <p className="text-sm text-neutral-700">Book Services</p>
          </div>
          <div className="text-center">
            <div className="w-16 h-16 bg-accent/10 rounded-full flex items-center justify-center mx-auto mb-3">
              <GlassWater className="text-accent text-xl" />
            </div>
            <p className="text-sm text-neutral-700">Amazing Events</p>
          </div>
        </div>
        
        <div className="border-t border-neutral-300 pt-6">
          <h3 className="font-poppins font-medium text-lg text-neutral-800 mb-3">Trusted by Thousands</h3>
          <div className="flex items-center space-x-2 mb-1">
            <div className="flex">
              <Star className="text-accent fill-accent" />
              <Star className="text-accent fill-accent" />
              <Star className="text-accent fill-accent" />
              <Star className="text-accent fill-accent" />
              <Star className="text-accent fill-accent" />
            </div>
            <span className="text-sm text-neutral-600">4.8/5 (2,400+ reviews)</span>
          </div>
          <p className="text-sm text-neutral-600">Join over 10,000 clients and 2,000 vendors on our platform</p>
        </div>
      </div>
      
      {/* Account Type Selection Modal */}
      {currentView === AuthView.ACCOUNT_TYPE && (
        <div className="fixed inset-0 bg-neutral-900/50 z-50 flex items-end justify-center">
          <div className="bg-white w-full max-w-md rounded-t-2xl slide-in">
            <AccountTypeSelection 
              onClientSelect={showClientSignup} 
              onVendorSelect={showVendorSignup} 
              onClose={() => setCurrentView(AuthView.LANDING)}
            />
          </div>
        </div>
      )}
      
      {/* Login Form Modal */}
      {currentView === AuthView.LOGIN && (
        <div className="fixed inset-0 bg-neutral-900/50 z-50 flex items-end justify-center">
          <div className="bg-white w-full max-w-md rounded-t-2xl slide-in">
            <LoginForm />
            <p className="text-center text-sm text-neutral-600 p-4 border-t border-neutral-200">
              New to DAOOB? 
              <button onClick={showAccountTypeSelection} className="text-secondary font-medium ml-1">
                Sign up
              </button>
            </p>
          </div>
        </div>
      )}
      
      {/* Client Signup Form Modal */}
      {currentView === AuthView.CLIENT_SIGNUP && (
        <div className="fixed inset-0 bg-neutral-900/50 z-50 flex items-end justify-center">
          <div className="bg-white w-full max-w-md rounded-t-2xl slide-in">
            <ClientRegistrationForm onSwitch={() => setCurrentView(AuthView.ACCOUNT_TYPE)} />
          </div>
        </div>
      )}
      
      {/* Vendor Signup Form Modal */}
      {currentView === AuthView.VENDOR_SIGNUP && (
        <div className="fixed inset-0 bg-neutral-900/50 z-50 flex items-end justify-center">
          <div className="bg-white w-full max-w-md rounded-t-2xl slide-in">
            <VendorRegistrationForm onSwitch={() => setCurrentView(AuthView.ACCOUNT_TYPE)} />
          </div>
        </div>
      )}
    </div>
  );
}
