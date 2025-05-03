import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { Switch, Route } from "wouter";
import { queryClient } from "./lib/queryClient";
import { AuthProvider } from "@/hooks/use-auth";
import NotFound from "@/pages/not-found";
import AuthPage from "@/pages/auth-page";
import ClientHome from "@/pages/client-home";
import VendorListing from "@/pages/vendor-listing";
import VendorDetail from "@/pages/vendor-detail";
import Bookings from "@/pages/bookings";
import Messages from "@/pages/messages";
import Chat from "@/pages/chat";
import Profile from "@/pages/profile";
import { ProtectedRoute } from "@/lib/protected-route";
import "./app.css";

function Router() {
  return (
    <Switch>
      <Route path="/auth" component={AuthPage} />
      <ProtectedRoute path="/" component={ClientHome} />
      <ProtectedRoute path="/vendors/:category" component={VendorListing} />
      <ProtectedRoute path="/vendor/:id" component={VendorDetail} />
      <ProtectedRoute path="/bookings" component={Bookings} />
      <ProtectedRoute path="/messages" component={Messages} />
      <ProtectedRoute path="/chat/:userId" component={Chat} />
      <ProtectedRoute path="/profile" component={Profile} />
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
