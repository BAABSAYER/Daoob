import { useState } from "react";
import { Search } from "lucide-react";
import { Header } from "@/components/layout/header";
import { BottomNavigation } from "@/components/layout/bottom-navigation";
import { EventTypeCategories } from "@/components/home/event-type-categories";
import { ServiceCategories } from "@/components/home/service-categories";
import { FeaturedVendors } from "@/components/home/featured-vendors";
import { Input } from "@/components/ui/input";

export default function ClientHome() {
  const [searchQuery, setSearchQuery] = useState("");
  
  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSearchQuery(event.target.value);
  };
  
  return (
    <div className="h-full w-full flex flex-col pb-16">
      {/* Header */}
      <Header />

      {/* Search Bar */}
      <div className="sticky top-0 z-40 bg-white px-5 py-3 shadow-sm">
        <div className="relative">
          <Input 
            type="text" 
            placeholder="Search vendors, services..." 
            className="w-full bg-neutral-100 py-3 pl-10 pr-4 rounded-xl"
            value={searchQuery}
            onChange={handleSearchChange}
          />
          <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-neutral-500 h-4 w-4" />
        </div>
      </div>

      {/* Event Type Categories */}
      <EventTypeCategories />

      {/* Service Categories */}
      <ServiceCategories />

      {/* Featured Vendors */}
      <FeaturedVendors />

      {/* Bottom Navigation */}
      <BottomNavigation />
    </div>
  );
}
