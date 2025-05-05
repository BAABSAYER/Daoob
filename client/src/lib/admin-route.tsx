import { ReactElement } from "react";
import { useAuth } from "@/hooks/use-auth";
import { Loader2 } from "lucide-react";
import { Redirect, Route } from "wouter";

interface AdminRouteProps {
  path: string;
  component: () => ReactElement;
}

export function AdminRoute({ path, component: Component }: AdminRouteProps) {
  const { user, isLoading } = useAuth();

  return (
    <Route path={path}>
      {() => {
        if (isLoading) {
          return (
            <div className="flex items-center justify-center min-h-screen">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
          );
        }

        if (!user) {
          return <Redirect to="/auth" />;
        }

        if (user.userType !== 'admin') {
          return (
            <div className="flex flex-col items-center justify-center min-h-screen p-4">
              <h1 className="text-2xl font-bold text-destructive mb-2">Access Denied</h1>
              <p className="text-muted-foreground text-center mb-6">
                You do not have permission to access the admin dashboard.
              </p>
              <Redirect to="/auth" />
            </div>
          );
        }

        return <Component />;
      }}
    </Route>
  );
}