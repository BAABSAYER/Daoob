import { Star } from "lucide-react";
import { Vendor } from "@shared/schema";

interface VendorCardProps {
  vendor: Vendor;
  onClick: () => void;
}

export function VendorCard({ vendor, onClick }: VendorCardProps) {
  // Use first image from vendor's photos array, or a fallback
  const coverImage = vendor.photos && Array.isArray(vendor.photos) && vendor.photos.length > 0
    ? vendor.photos[0]
    : getCategoryFallbackImage(vendor.category);
  
  return (
    <div 
      className="bg-white rounded-xl shadow-sm overflow-hidden border border-neutral-200 cursor-pointer hover:shadow-md transition-shadow"
      onClick={onClick}
    >
      <div className="h-40 relative">
        <div 
          className="w-full h-full bg-cover bg-center" 
          style={{ backgroundImage: `url(${coverImage})` }}
        ></div>
        <div className="absolute top-3 right-3 bg-white rounded-full px-2 py-1 text-xs font-medium text-primary flex items-center">
          <Star className="h-3 w-3 text-accent mr-1 fill-accent" />
          <span>
            {vendor.rating ? vendor.rating.toFixed(1) : 'New'}
          </span>
        </div>
      </div>
      <div className="p-4">
        <div className="flex justify-between items-start">
          <div>
            <h3 className="font-poppins font-medium text-neutral-800">{vendor.businessName}</h3>
            <p className="text-sm text-neutral-600 mb-1">
              {getCategoryName(vendor.category)}
              {vendor.city && ` • ${vendor.city}`}
            </p>
            <div className="flex items-center text-sm text-neutral-500">
              {vendor.priceRange && <span className="mr-2">{vendor.priceRange}</span>}
              {vendor.capacity && <span>Up to {vendor.capacity} guests</span>}
            </div>
          </div>
          <button className="bg-secondary text-white text-sm font-medium px-3 py-1 rounded-lg">
            View
          </button>
        </div>
      </div>
    </div>
  );
}

// Helper functions
function getCategoryName(category: string): string {
  const categoryMap: Record<string, string> = {
    'venue': 'Venues',
    'catering': 'Catering',
    'photography': 'Photography',
    'decoration': 'Decorations',
    'entertainment': 'Entertainment',
    'other': 'Services'
  };
  
  return categoryMap[category] || 'Services';
}

function getCategoryFallbackImage(category: string): string {
  const imageMap: Record<string, string> = {
    'venue': 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    'catering': 'https://images.unsplash.com/photo-1555244162-803834f70033?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    'photography': 'https://images.unsplash.com/photo-1478146059778-26028b07395a?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    'decoration': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    'entertainment': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60'
  };
  
  return imageMap[category] || 'https://images.unsplash.com/photo-1505236858219-8359eb29e329?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60';
}
