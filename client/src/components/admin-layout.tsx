import { ReactNode } from "react";
import { Link, useLocation } from "wouter";
import { 
  Home, 
  Users, 
  Calendar, 
  MessageSquare, 
  LogOut, 
  UserCircle,
  Menu,
  X
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { useAuth } from "@/hooks/use-auth";
import { useState } from "react";
import { cn } from "@/lib/utils";

interface AdminLayoutProps {
  children: ReactNode;
  title: string;
}

export function AdminLayout({ children, title }: AdminLayoutProps) {
  const { logoutMutation, user } = useAuth();
  const [location] = useLocation();
  const [isOpen, setIsOpen] = useState(false);

  const menuItems = [
    { name: "Dashboard", path: "/admin", icon: <Home className="h-5 w-5" /> },
    { name: "Vendors", path: "/admin/vendors", icon: <Users className="h-5 w-5" /> },
    { name: "Bookings", path: "/admin/bookings", icon: <Calendar className="h-5 w-5" /> },
    { name: "Messages", path: "/admin/chat", icon: <MessageSquare className="h-5 w-5" /> },
    { name: "Profile", path: "/admin/profile", icon: <UserCircle className="h-5 w-5" /> },
  ];

  const handleLogout = () => {
    logoutMutation.mutate();
  };

  return (
    <div className="flex min-h-screen bg-background">
      {/* Desktop sidebar */}
      <aside className="hidden md:flex flex-col w-64 border-r border-border bg-card">
        <div className="flex items-center justify-center h-16 border-b border-border p-4">
          <img 
            src="/src/assets/images/app_icon.png" 
            alt="DAOOB" 
            className="h-8"
          />
          <span className="ml-2 text-xl font-bold text-primary">دؤوب</span>
        </div>

        <nav className="flex flex-col flex-1 p-4 space-y-1">
          {menuItems.map((item) => (
            <Link key={item.path} href={item.path}>
              <div className={cn(
                "flex items-center px-4 py-3 rounded-md transition-colors cursor-pointer",
                location === item.path
                  ? "bg-primary text-primary-foreground"
                  : "hover:bg-muted"
              )}>
                {item.icon}
                <span className="ml-3">{item.name}</span>
              </div>
            </Link>
          ))}
        </nav>

        <div className="p-4 border-t border-border">
          <Button 
            variant="outline" 
            className="w-full justify-start" 
            onClick={handleLogout}
          >
            <LogOut className="mr-2 h-5 w-5" />
            Logout
          </Button>
        </div>
      </aside>

      {/* Mobile sidebar */}
      <Sheet open={isOpen} onOpenChange={setIsOpen}>
        <SheetTrigger asChild>
          <Button 
            variant="outline" 
            size="icon" 
            className="md:hidden absolute top-4 left-4 z-50"
          >
            <Menu className="h-5 w-5" />
          </Button>
        </SheetTrigger>
        <SheetContent side="left" className="p-0 w-64">
          <div className="flex items-center justify-center h-16 border-b border-border p-4">
            <img 
              src="/src/assets/images/app_icon.png" 
              alt="DAOOB" 
              className="h-8" 
            />
            <span className="ml-2 text-xl font-bold text-primary">دؤوب</span>
          </div>

          <nav className="flex flex-col flex-1 p-4 space-y-1">
            {menuItems.map((item) => (
              <Link key={item.path} href={item.path}>
                <a 
                  className={cn(
                    "flex items-center px-4 py-3 rounded-md transition-colors",
                    location === item.path
                      ? "bg-primary text-primary-foreground"
                      : "hover:bg-muted"
                  )}
                  onClick={() => setIsOpen(false)}
                >
                  {item.icon}
                  <span className="ml-3">{item.name}</span>
                </a>
              </Link>
            ))}
          </nav>

          <div className="p-4 border-t border-border">
            <Button 
              variant="outline" 
              className="w-full justify-start" 
              onClick={handleLogout}
            >
              <LogOut className="mr-2 h-5 w-5" />
              Logout
            </Button>
          </div>
        </SheetContent>
      </Sheet>

      {/* Main content */}
      <div className="flex-1 flex flex-col">
        <header className="h-16 border-b border-border bg-card flex items-center justify-between px-6">
          <h1 className="text-xl font-bold">{title}</h1>
          <div className="flex items-center gap-4">
            {user && (
              <div className="hidden md:flex items-center gap-2">
                <span className="text-sm text-muted-foreground">
                  {user.fullName || user.username}
                </span>
              </div>
            )}
          </div>
        </header>
        <main className="flex-1 p-6 overflow-auto">{children}</main>
      </div>
    </div>
  );
}