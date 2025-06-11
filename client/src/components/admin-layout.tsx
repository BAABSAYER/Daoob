import { ReactNode } from "react";
import { Link, useLocation } from "wouter";
import { useTranslation } from "react-i18next";
import { 
  Home, 
  Users, 
  Calendar, 
  CalendarDays,
  MessageSquare, 
  LogOut, 
  UserCircle,
  Menu,
  UserCog,
  X
} from "lucide-react";
import appIcon from '@/assets/images/app_icon.svg';
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { LanguageSwitcher } from "@/components/ui/language-switcher";
import { useAuth } from "@/hooks/use-auth";
import { useState } from "react";
import { cn } from "@/lib/utils";

interface AdminLayoutProps {
  children: ReactNode;
  title: string;
}

export function AdminLayout({ children, title }: AdminLayoutProps) {
  const { logoutMutation, user } = useAuth();
  const { t } = useTranslation();
  const [location] = useLocation();
  const [isOpen, setIsOpen] = useState(false);

  const menuItems = [
    { name: t('navigation.dashboard'), path: "/admin", icon: <Home className="h-5 w-5" /> },
    { name: t('navigation.eventManagement'), path: "/admin/events", icon: <CalendarDays className="h-5 w-5" /> },
    { name: t('navigation.bookings'), path: "/admin/bookings", icon: <Calendar className="h-5 w-5" /> },
    { name: t('navigation.users'), path: "/admin/users-list", icon: <Users className="h-5 w-5" /> },
    { name: t('navigation.messages'), path: "/admin/messages", icon: <MessageSquare className="h-5 w-5" /> },
    { name: "Admin Settings", path: "/admin/users", icon: <UserCog className="h-5 w-5" /> },
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
            src={appIcon} 
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
            {t('navigation.logout')}
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
              src={appIcon} 
              alt="DAOOB" 
              className="h-8" 
            />
            <span className="ml-2 text-xl font-bold text-primary">دؤوب</span>
          </div>

          <nav className="flex flex-col flex-1 p-4 space-y-1">
            {menuItems.map((item) => (
              <Link key={item.path} href={item.path}>
                <div 
                  className={cn(
                    "flex items-center px-4 py-3 rounded-md transition-colors cursor-pointer",
                    location === item.path
                      ? "bg-primary text-primary-foreground"
                      : "hover:bg-muted"
                  )}
                  onClick={() => setIsOpen(false)}
                >
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
              {t('navigation.logout')}
            </Button>
          </div>
        </SheetContent>
      </Sheet>

      {/* Main content */}
      <div className="flex-1 flex flex-col">
        <header className="h-16 border-b border-border bg-card flex items-center justify-between px-6">
          <h1 className="text-xl font-bold">{title}</h1>
          <div className="flex items-center gap-4">
            <LanguageSwitcher />
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