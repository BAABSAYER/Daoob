import { useLocation } from "wouter";
import { Home, Search, Calendar, MessageSquare } from "lucide-react";

export function BottomNavigation() {
  const [location, navigate] = useLocation();

  const isActive = (path: string) => {
    if (path === "/" && location === "/") return true;
    if (path === "/vendors" && location.startsWith("/vendors")) return true;
    if (path === "/vendor" && location.startsWith("/vendor")) return true;
    if (path === "/bookings" && location === "/bookings") return true;
    if (path === "/messages" && (location === "/messages" || location.startsWith("/chat"))) return true;
    return false;
  };

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-neutral-200 z-40 flex justify-around max-w-md mx-auto">
      <button 
        onClick={() => navigate("/")} 
        className={`py-3 px-5 flex flex-col items-center ${isActive("/") ? "text-secondary" : "text-neutral-500"}`}
      >
        <Home className="h-5 w-5" />
        <span className={`text-xs mt-1 ${isActive("/") ? "font-medium" : ""}`}>Home</span>
      </button>
      
      <button 
        onClick={() => navigate("/vendors/all")} 
        className={`py-3 px-5 flex flex-col items-center ${isActive("/vendors") ? "text-secondary" : "text-neutral-500"}`}
      >
        <Search className="h-5 w-5" />
        <span className={`text-xs mt-1 ${isActive("/vendors") ? "font-medium" : ""}`}>Explore</span>
      </button>
      
      <button 
        onClick={() => navigate("/bookings")} 
        className={`py-3 px-5 flex flex-col items-center ${isActive("/bookings") ? "text-secondary" : "text-neutral-500"}`}
      >
        <Calendar className="h-5 w-5" />
        <span className={`text-xs mt-1 ${isActive("/bookings") ? "font-medium" : ""}`}>Bookings</span>
      </button>
      
      <button 
        onClick={() => navigate("/messages")} 
        className={`py-3 px-5 flex flex-col items-center ${isActive("/messages") ? "text-secondary" : "text-neutral-500"}`}
      >
        <MessageSquare className="h-5 w-5" />
        <span className={`text-xs mt-1 ${isActive("/messages") ? "font-medium" : ""}`}>Messages</span>
      </button>
    </nav>
  );
}
