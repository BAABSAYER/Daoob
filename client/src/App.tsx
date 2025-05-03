import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { Switch, Route } from "wouter";
import { queryClient } from "./lib/queryClient";
import { AuthProvider } from "@/hooks/use-auth";
import NotFound from "@/pages/not-found";
import AuthPage from "@/pages/auth-page";

// Client/User Pages
import ClientHome from "@/pages/client-home";
import VendorListing from "@/pages/vendor-listing";
import VendorDetail from "@/pages/vendor-detail";
import Bookings from "@/pages/bookings";
import Messages from "@/pages/messages";
import Chat from "@/pages/chat";
import Profile from "@/pages/profile";

// Vendor Dashboard Pages
import VendorDashboard from "@/pages/vendor/dashboard";
import VendorServices from "@/pages/vendor/services";
import VendorServiceForm from "@/pages/vendor/service-form";
import VendorBookings from "@/pages/vendor/bookings";
import VendorProfile from "@/pages/vendor/profile";

// Admin Dashboard Pages - temporarily commented out
// import AdminDashboard from "@/pages/admin/dashboard";
// import AdminUsers from "@/pages/admin/users";
// import AdminVendors from "@/pages/admin/vendors";
// import AdminBookings from "@/pages/admin/bookings";

import { ProtectedRoute } from "@/lib/protected-route";
import "./app.css";

function Router() {
  return (
    <Switch>
      {/* Auth Route */}
      <Route path="/auth" component={AuthPage} />
      
      {/* Client/User Routes */}
      <ProtectedRoute path="/" component={ClientHome} />
      <ProtectedRoute path="/vendors/:category" component={VendorListing} />
      <ProtectedRoute path="/vendor/:id" component={VendorDetail} />
      <ProtectedRoute path="/bookings" component={Bookings} />
      <ProtectedRoute path="/messages" component={Messages} />
      <ProtectedRoute path="/chat/:userId" component={Chat} />
      <ProtectedRoute path="/profile" component={Profile} />
      
      {/* Vendor Dashboard Routes */}
      <ProtectedRoute path="/vendor-dashboard" component={VendorDashboard} />
      <ProtectedRoute path="/vendor-dashboard/services" component={VendorServices} />
      <ProtectedRoute path="/vendor-dashboard/services/new" component={VendorServiceForm} />
      <ProtectedRoute path="/vendor-dashboard/services/edit/:id" component={VendorServiceForm} />
      <ProtectedRoute path="/vendor-dashboard/bookings" component={VendorBookings} />
      <ProtectedRoute path="/vendor-dashboard/profile" component={VendorProfile} />
      
      {/* Admin Dashboard Routes - temporarily commented out */}
      {/* <ProtectedRoute path="/admin" component={AdminDashboard} /> */}
      {/* <ProtectedRoute path="/admin/users" component={AdminUsers} /> */}
      {/* <ProtectedRoute path="/admin/vendors" component={AdminVendors} /> */}
      {/* <ProtectedRoute path="/admin/bookings" component={AdminBookings} /> */}
      
      {/* 404 Route */}
      <Route component={NotFound} />
    </Switch>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <TooltipProvider>
          <Toaster />
          <div className="app-container">
            <Router />
          </div>
        </TooltipProvider>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;
