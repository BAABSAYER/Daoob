import { useState, useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { useLocation } from "wouter";
import { Vendor, SERVICE_CATEGORIES } from "@shared/schema";
import { VendorCard } from "@/components/vendor/vendor-card";
import { Header } from "@/components/layout/header";
import { BottomNavigation } from "@/components/layout/bottom-navigation";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";

// Helper to get friendly category names
const getCategoryTitle = (category: string): string => {
  const categoryMap: Record<string, string> = {
    'venue': 'Venues',
    'catering': 'Catering',
    'photography': 'Photography',
    'decoration': 'Decorations',
    'entertainment': 'Entertainment',
    'all': 'All Services'
  };
  
  return categoryMap[category] || 'Services';
};

export default function VendorListing() {
  const [, params] = useLocation();
  const [, navigate] = useLocation();
  const [searchTerm, setSearchTerm] = useState("");
  const [activeFilter, setActiveFilter] = useState("all");
  const category = params.category || "all";
  
  // Reset search when category changes
  useEffect(() => {
    setSearchTerm("");
    setActiveFilter("all");
  }, [category]);
  
  // Fetch vendors from the API
  const { data: vendors, isLoading, error } = useQuery<Vendor[]>({
    queryKey: [`/api/vendors${category !== 'all' ? `?category=${category}` : ''}`],
  });
  
  // Filter vendors based on search and subcategory
  const filteredVendors = vendors?.filter(vendor => {
    const matchesSearch = !searchTerm || 
      vendor.businessName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (vendor.description && vendor.description.toLowerCase().includes(searchTerm.toLowerCase()));
    
    const matchesFilter = activeFilter === "all" || 
      (vendor.features && Array.isArray(vendor.features) && vendor.features.includes(activeFilter));
    
    return matchesSearch && matchesFilter;
  });
  
  // Handle clicking on a vendor
  const handleVendorClick = (id: number) => {
    navigate(`/vendor/${id}`);
  };
  
  // Generate filter options based on the category
  const getFiltersForCategory = (category: string) => {
    switch (category) {
      case 'venue':
        return [
          { id: "all", name: "All Venues" },
          { id: "banquet", name: "Banquet Halls" },
          { id: "outdoor", name: "Outdoor" },
          { id: "hotel", name: "Hotels" },
          { id: "restaurant", name: "Restaurants" }
        ];
      case 'catering':
        return [
          { id: "all", name: "All Catering" },
          { id: "buffet", name: "Buffet" },
          { id: "plated", name: "Plated Service" },
          { id: "cocktail", name: "Cocktail" },
          { id: "dessert", name: "Dessert" }
        ];
      case 'photography':
        return [
          { id: "all", name: "All Photography" },
          { id: "wedding", name: "Wedding" },
          { id: "portrait", name: "Portrait" },
          { id: "event", name: "Event" },
          { id: "commercial", name: "Commercial" }
        ];
      case 'decoration':
        return [
          { id: "all", name: "All Decorations" },
          { id: "floral", name: "Floral" },
          { id: "lighting", name: "Lighting" },
          { id: "stage", name: "Stage" },
          { id: "themed", name: "Themed" }
        ];
      default:
        return [
          { id: "all", name: "All Services" }
        ];
    }
  };
  
  const filters = getFiltersForCategory(category);
  
  return (
    <div className="h-full w-full flex flex-col pb-16">
      {/* Header */}
      <header className="bg-white pt-4 pb-2 px-5">
        <div className="flex items-center mb-4">
          <button onClick={() => navigate("/")} className="mr-3">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-neutral-800">
              <path d="M19 12H5M12 19l-7-7 7-7" />
            </svg>
          </button>
          <h1 className="font-poppins font-semibold text-xl text-neutral-800">
            {getCategoryTitle(category)}
          </h1>
        </div>
        
        {/* Filters */}
        <div className="flex overflow-x-auto scrollbar-hide space-x-2 pb-2">
          {filters.map((filter) => (
            <Button
              key={filter.id}
              variant={activeFilter === filter.id ? "default" : "outline"}
              className={`rounded-full text-sm flex-shrink-0 ${
                activeFilter === filter.id 
                  ? "bg-secondary text-white" 
                  : "bg-neutral-100 text-neutral-700 hover:text-secondary hover:bg-neutral-200"
              }`}
              onClick={() => setActiveFilter(filter.id)}
            >
              {filter.name}
            </Button>
          ))}
        </div>
      </header>

      {/* Search and Sort */}
      <div className="sticky top-0 z-30 bg-white px-5 py-3 shadow-sm">
        <div className="flex space-x-3">
          <div className="relative flex-1">
            <input 
              type="text" 
              placeholder={`Search ${getCategoryTitle(category).toLowerCase()}...`} 
              className="w-full bg-neutral-100 py-2 pl-9 pr-4 rounded-lg border-none outline-none"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="absolute left-3 top-1/2 transform -translate-y-1/2 text-neutral-500">
              <circle cx="11" cy="11" r="8" />
              <path d="m21 21-4.3-4.3" />
            </svg>
          </div>
          <button className="bg-neutral-100 px-3 rounded-lg flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-neutral-700">
              <path d="M3 6h18M7 12h10m-10 6h10" />
            </svg>
          </button>
        </div>
      </div>

      {/* Vendor List */}
      <div className="bg-neutral-100 p-4 pb-20 flex-1">
        {isLoading && (
          <div className="grid grid-cols-1 gap-4">
            <Skeleton className="h-48 w-full rounded-xl" />
            <Skeleton className="h-48 w-full rounded-xl" />
            <Skeleton className="h-48 w-full rounded-xl" />
          </div>
        )}
        
        {error && (
          <div className="flex flex-col items-center justify-center p-8 text-center">
            <p className="text-red-500 mb-4">Failed to load vendors</p>
            <Button onClick={() => navigate("/")}>Go Back Home</Button>
          </div>
        )}
        
        {!isLoading && !error && filteredVendors?.length === 0 && (
          <div className="flex flex-col items-center justify-center p-8 text-center">
            <p className="text-neutral-600 mb-4">No vendors found matching your criteria</p>
            <Button onClick={() => {
              setSearchTerm("");
              setActiveFilter("all");
            }}>
              Clear Filters
            </Button>
          </div>
        )}
        
        <div className="grid grid-cols-1 gap-4">
          {filteredVendors?.map((vendor) => (
            <VendorCard 
              key={vendor.id}
              vendor={vendor}
              onClick={() => handleVendorClick(vendor.id)}
            />
          ))}
        </div>
      </div>

      {/* Bottom Navigation */}
      <BottomNavigation />
    </div>
  );
}
