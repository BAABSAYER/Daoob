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
import AdminVendors from "./pages/admin/vendors";
import AdminBookings from "./pages/admin/bookings";
import AdminChat from "./pages/admin/chat";
import AdminUsers from "./pages/admin/users";
import AdminEvents from "./pages/admin/events";

// Shared Pages
import Profile from "./pages/profile";

import { ProtectedRoute } from "./lib/protected-route";
import { AdminRoute } from "./lib/admin-route";
import "./app.css";

function Router() {
  return (
    <Switch>
      {/* Auth Route */}
      <Route path="/auth" component={AuthPage} />
      
      {/* Admin Dashboard Routes */}
      <Route path="/">
        <Redirect to="/admin" />
      </Route>
      <AdminRoute path="/admin" component={AdminDashboard} />
      <AdminRoute path="/admin/vendors" component={AdminVendors} />
      <AdminRoute path="/admin/bookings" component={AdminBookings} />
      <AdminRoute path="/admin/events" component={AdminEvents} />
      <AdminRoute path="/admin/users" component={AdminUsers} />
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
