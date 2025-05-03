import { useQuery } from "@tanstack/react-query";
import { useLocation } from "wouter";
import { Vendor } from "@shared/schema";
import { VendorCard } from "@/components/vendor/vendor-card";
import { Skeleton } from "@/components/ui/skeleton";

export function FeaturedVendors() {
  const [, navigate] = useLocation();
  
  const { data: vendors, isLoading, error } = useQuery<Vendor[]>({
    queryKey: ['/api/vendors'],
  });

  const handleViewAll = () => {
    navigate('/vendors/all');
  };

  const handleViewVendor = (id: number) => {
    navigate(`/vendor/${id}`);
  };

  // Show only the first 2 featured vendors
  const featuredVendors = vendors?.slice(0, 2);

  return (
    <div className="px-5 py-4 bg-white">
      <div className="flex justify-between items-center mb-3">
        <h2 className="font-poppins font-semibold text-lg text-neutral-800">Featured Vendors</h2>
        <button 
          className="text-sm text-secondary font-medium"
          onClick={handleViewAll}
        >
          View all
        </button>
      </div>
      
      <div className="space-y-4">
        {isLoading && (
          <>
            <VendorCardSkeleton />
            <VendorCardSkeleton />
          </>
        )}
        
        {error && (
          <div className="p-4 bg-red-50 rounded-lg text-center">
            <p className="text-red-500">Failed to load vendors</p>
          </div>
        )}
        
        {featuredVendors?.length === 0 && !isLoading && (
          <div className="p-4 bg-neutral-50 rounded-lg text-center">
            <p className="text-neutral-500">No featured vendors available</p>
          </div>
        )}
        
        {featuredVendors?.map((vendor) => (
          <VendorCard 
            key={vendor.id}
            vendor={vendor}
            onClick={() => handleViewVendor(vendor.id)}
          />
        ))}
      </div>
    </div>
  );
}

function VendorCardSkeleton() {
  return (
    <div className="bg-white rounded-xl shadow-sm overflow-hidden border border-neutral-200">
      <Skeleton className="h-40 w-full" />
      <div className="p-4">
        <div className="flex justify-between items-start">
          <div>
            <Skeleton className="h-6 w-40 mb-1" />
            <Skeleton className="h-4 w-32 mb-1" />
            <Skeleton className="h-4 w-24" />
          </div>
          <Skeleton className="h-8 w-16 rounded-lg" />
        </div>
      </div>
    </div>
  );
}
