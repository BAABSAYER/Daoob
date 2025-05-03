import { useLocation } from "wouter";
import { Bell, User, ChevronLeft, Search, SlidersHorizontal } from "lucide-react";
import { useAuth } from "@/hooks/use-auth";
import logoSvg from "@/assets/daoob-logo.svg";

interface HeaderProps {
  title?: string;
  showBack?: boolean;
  showSearch?: boolean;
  showProfile?: boolean;
  onSearchChange?: (value: string) => void;
  searchValue?: string;
}

export function Header({
  title,
  showBack = false,
  showSearch = false,
  showProfile = true,
  onSearchChange,
  searchValue = "",
}: HeaderProps) {
  const [, navigate] = useLocation();
  const { user } = useAuth();

  return (
    <header className="bg-white py-4 px-5 shadow-sm">
      {showBack ? (
        <div className="flex items-center">
          <button onClick={() => window.history.back()} className="mr-3">
            <ChevronLeft className="h-5 w-5 text-neutral-800" />
          </button>
          <h1 className="font-poppins font-semibold text-xl text-neutral-800">{title || ""}</h1>
        </div>
      ) : (
        <div className="flex justify-between items-center">
          <div>
            {title ? (
              <h1 className="font-poppins font-bold text-2xl text-neutral-800">{title}</h1>
            ) : (
              <div className="flex items-center">
                <img src={logoSvg} alt="DAOOB Logo" className="h-10 mr-2" />
              </div>
            )}
            {user && (
              <p className="text-sm text-neutral-600">
                Welcome back, <span>{user.fullName || user.username}</span>!
              </p>
            )}
          </div>
          {showProfile && (
            <div className="flex items-center space-x-4">
              <button className="w-10 h-10 bg-neutral-100 rounded-full flex items-center justify-center">
                <Bell className="h-5 w-5 text-neutral-600" />
              </button>
              <button 
                onClick={() => navigate("/profile")} 
                className="w-10 h-10 bg-secondary/10 rounded-full flex items-center justify-center"
              >
                <User className="h-5 w-5 text-secondary" />
              </button>
            </div>
          )}
        </div>
      )}

      {showSearch && (
        <div className="mt-4 flex space-x-3">
          <div className="relative flex-1">
            <input
              type="text"
              placeholder="Search..."
              className="w-full bg-neutral-100 py-2 pl-9 pr-4 rounded-lg border-none outline-none"
              value={searchValue}
              onChange={(e) => onSearchChange && onSearchChange(e.target.value)}
            />
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-neutral-500 h-4 w-4" />
          </div>
          <button className="bg-neutral-100 px-3 rounded-lg flex items-center justify-center">
            <SlidersHorizontal className="h-4 w-4 text-neutral-700" />
          </button>
        </div>
      )}
    </header>
  );
}
