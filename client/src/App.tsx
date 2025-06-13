import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { Switch, Route, Redirect } from "wouter";
import { queryClient } from "./lib/queryClient";
import { AuthProvider } from "@/hooks/use-auth";
import NotFound from "@/pages/not-found";
import AuthPage from "@/pages/auth-page";

// Admin Dashboard Pages
import AdminDashboard from "./pages/admin/dashboard";
import AdminBookings from "./pages/admin/bookings";
import AdminMessages from "./pages/admin/admin-messages";
import AdminChat from "./pages/admin/admin-chat";
import AdminUsers from "./pages/admin/users";
import AdminUsersList from "./pages/admin/users-list";
import AdminEvents from "./pages/admin/events";

// Client Pages
import ClientHome from "./pages/client-home";
import Messages from "./pages/messages";
import Chat from "./pages/chat";
import Bookings from "./pages/bookings";
import Dashboard from "./pages/dashboard";

// Vendor Pages
import VendorDashboard from "./pages/vendor/dashboard";
import VendorBookings from "./pages/vendor/bookings";
import VendorServices from "./pages/vendor/services";
import VendorProfile from "./pages/vendor/profile";

// Shared Pages
import Profile from "./pages/profile";

import { ProtectedRoute } from "./lib/protected-route";
import { AdminRoute } from "./lib/admin-route";
import { VendorRoute } from "./lib/vendor-route";
import "./app.css";

function Router() {
  return (
    <Switch>
      {/* Auth Route */}
      <Route path="/auth" component={AuthPage} />
      
      {/* Client Routes */}
      <ProtectedRoute path="/messages" component={Messages} />
      <ProtectedRoute path="/chat/:userId" component={Chat} />
      
      {/* Default Route - Role-based redirect */}
      <ProtectedRoute path="/" component={Dashboard} />
      
      {/* Client Routes */}
      <ProtectedRoute path="/client/home" component={ClientHome} />
      <ProtectedRoute path="/bookings" component={Bookings} />
      <ProtectedRoute path="/profile" component={Profile} />
      
      {/* Vendor Routes */}
      <VendorRoute path="/vendor/dashboard" component={VendorDashboard} />
      <VendorRoute path="/vendor/bookings" component={VendorBookings} />
      <VendorRoute path="/vendor/services" component={VendorServices} />
      <VendorRoute path="/vendor/profile" component={VendorProfile} />
      
      {/* Admin Dashboard Routes */}
      <AdminRoute path="/admin" component={AdminDashboard} />
      <AdminRoute path="/admin/bookings" component={AdminBookings} />
      <AdminRoute path="/admin/events" component={AdminEvents} />
      <AdminRoute path="/admin/users" component={AdminUsers} />
      <AdminRoute path="/admin/users-list" component={AdminUsersList} />
      <AdminRoute path="/admin/messages" component={AdminMessages} />
      <AdminRoute path="/admin/chat/:userId" component={AdminChat} />
      <AdminRoute path="/admin/profile" component={Profile} />
      
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
          <div className="min-h-screen font-arabic bg-background">
            <Router />
          </div>
        </TooltipProvider>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;
