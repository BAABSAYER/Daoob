import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useLocation } from "wouter";
import { Vendor, SERVICE_CATEGORIES } from "@shared/schema";
import { 
  ArrowLeft, Heart, Share, Star, ParkingMeter, Wifi, Utensils, 
  GlassWater, Music, Accessibility, MapPin
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { BookingForm } from "@/components/vendor/booking-form";

interface VendorDetailsProps {
  vendorId: number;
}

export function VendorDetails({ vendorId }: VendorDetailsProps) {
  const [, navigate] = useLocation();
  const [showBookingForm, setShowBookingForm] = useState(false);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  
  const { data: vendor, isLoading, error } = useQuery<Vendor & { services: any[], reviews: any[] }>({
    queryKey: [`/api/vendors/${vendorId}`],
  });

  const handleBack = () => {
    // Instead of navigate(-1), navigate to the home page or just use history.back()
    window.history.back();
  };

  const handleChat = () => {
    if (vendor) {
      navigate(`/chat/${vendor.userId}`);
    }
  };

  const handleBookNow = () => {
    setShowBookingForm(true);
  };

  const closeBookingForm = () => {
    setShowBookingForm(false);
  };

  const nextImage = () => {
    if (vendor?.photos && Array.isArray(vendor.photos)) {
      setCurrentImageIndex((prevIndex) => (prevIndex + 1) % vendor.photos.length);
    }
  };

  const prevImage = () => {
    if (vendor?.photos && Array.isArray(vendor.photos)) {
      setCurrentImageIndex((prevIndex) => 
        prevIndex === 0 ? vendor.photos.length - 1 : prevIndex - 1
      );
    }
  };

  if (isLoading) {
    return <VendorDetailsSkeleton />;
  }

  if (error || !vendor) {
    return (
      <div className="h-full flex flex-col items-center justify-center p-5 bg-neutral-100">
        <p className="text-lg text-red-500 mb-4">Failed to load vendor details</p>
        <Button onClick={handleBack}>Go Back</Button>
      </div>
    );
  }

  // Get the current image URL to display
  const currentImageUrl = vendor.photos && Array.isArray(vendor.photos) && vendor.photos.length > 0
    ? vendor.photos[currentImageIndex]
    : getCategoryFallbackImage(vendor.category);

  // Format reviews for display
  const formattedReviews = vendor.reviews?.slice(0, 2) || [];

  return (
    <div className="h-full w-full flex flex-col pb-16">
      {/* Image Gallery */}
      <div className="relative">
        <div className="h-64 bg-neutral-200">
          <div 
            className="w-full h-full bg-cover bg-center" 
            style={{ backgroundImage: `url(${currentImageUrl})` }}
          ></div>
        </div>
        <button 
          onClick={handleBack} 
          className="absolute top-4 left-4 bg-white rounded-full w-10 h-10 flex items-center justify-center shadow-md"
        >
          <ArrowLeft className="h-5 w-5 text-neutral-800" />
        </button>
        <div className="absolute top-4 right-4 flex space-x-2">
          <button className="bg-white rounded-full w-10 h-10 flex items-center justify-center shadow-md">
            <Heart className="h-5 w-5 text-neutral-800" />
          </button>
          <button className="bg-white rounded-full w-10 h-10 flex items-center justify-center shadow-md">
            <Share className="h-5 w-5 text-neutral-800" />
          </button>
        </div>
        {vendor.photos && Array.isArray(vendor.photos) && vendor.photos.length > 1 && (
          <div className="absolute bottom-4 right-4 bg-black/60 rounded-full px-3 py-1 text-xs text-white">
            {currentImageIndex + 1}/{vendor.photos.length} Photos
          </div>
        )}
      </div>

      {/* Vendor Info */}
      <div className="bg-white p-5">
        <div className="flex justify-between items-start mb-2">
          <h1 className="font-poppins font-semibold text-xl text-neutral-800">{vendor.businessName}</h1>
          <div className="flex items-center">
            <Star className="h-4 w-4 text-accent mr-1 fill-accent" />
            <span className="font-medium">{vendor.rating ? vendor.rating.toFixed(1) : 'New'}</span>
            <span className="text-neutral-500 text-sm ml-1">({vendor.reviewCount || 0})</span>
          </div>
        </div>
        <p className="text-neutral-600 mb-4">
          {vendor.city && `${vendor.city} • `}
          {getCategoryName(vendor.category)}
        </p>
        
        <div className="border-t border-neutral-200 pt-4 pb-2">
          <div className="flex flex-wrap gap-2 mb-4">
            {vendor.capacity && (
              <span className="bg-neutral-100 text-neutral-700 text-sm px-3 py-1 rounded-full">
                Up to {vendor.capacity} guests
              </span>
            )}
            {vendor.priceRange && (
              <span className="bg-neutral-100 text-neutral-700 text-sm px-3 py-1 rounded-full">
                {vendor.priceRange}
              </span>
            )}
            {vendor.features && Array.isArray(vendor.features) && vendor.features.length > 0 && (
              <span className="bg-neutral-100 text-neutral-700 text-sm px-3 py-1 rounded-full">
                {vendor.features[0]}
              </span>
            )}
          </div>
          
          <p className="text-neutral-700 mb-4">
            {vendor.description || `Professional ${getCategoryName(vendor.category)} service provider.`}
          </p>
          
          <Button variant="link" className="p-0 text-secondary font-medium">Read more</Button>
        </div>
      </div>

      {/* Amenities */}
      {vendor.amenities && Array.isArray(vendor.amenities) && vendor.amenities.length > 0 && (
        <div className="bg-white p-5 mt-4">
          <h2 className="font-poppins font-semibold text-lg text-neutral-800 mb-3">Amenities & Services</h2>
          <div className="grid grid-cols-2 gap-y-4">
            {renderAmenities(vendor.amenities)}
          </div>
          {vendor.amenities.length > 6 && (
            <Button variant="link" className="mt-3 p-0 text-secondary font-medium">Show all amenities</Button>
          )}
        </div>
      )}

      {/* Location */}
      {vendor.address && (
        <div className="bg-neutral-100 p-5">
          <h2 className="font-poppins font-semibold text-lg text-neutral-800 mb-3">Location</h2>
          <div className="bg-white rounded-xl overflow-hidden shadow-sm mb-3">
            <div className="h-40 bg-neutral-300 flex items-center justify-center">
              <MapPin className="h-10 w-10 text-neutral-400" />
            </div>
            <div className="p-4">
              <p className="text-neutral-800 font-medium">{vendor.address}</p>
              {vendor.city && <p className="text-sm text-neutral-600">{vendor.city}</p>}
            </div>
          </div>
        </div>
      )}

      {/* Reviews */}
      {formattedReviews.length > 0 && (
        <div className="bg-white p-5">
          <div className="flex justify-between items-center mb-4">
            <h2 className="font-poppins font-semibold text-lg text-neutral-800">Reviews</h2>
            <div className="flex items-center">
              <Star className="h-4 w-4 text-accent mr-1 fill-accent" />
              <span className="font-medium">{vendor.rating?.toFixed(1)}</span>
              <span className="text-neutral-500 text-sm ml-1">({vendor.reviewCount})</span>
            </div>
          </div>
          
          <div className="space-y-4 mb-4">
            {formattedReviews.map((review, index) => (
              <div key={index} className="border-b border-neutral-200 pb-4">
                <div className="flex justify-between items-start mb-2">
                  <div className="flex items-center">
                    <div className="w-10 h-10 bg-neutral-200 rounded-full flex items-center justify-center mr-3">
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" className="h-5 w-5 text-neutral-400">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                      </svg>
                    </div>
                    <div>
                      <p className="font-medium text-neutral-800">{review.reviewerName || 'Client'}</p>
                      <p className="text-xs text-neutral-500">
                        {new Date(review.createdAt).toLocaleDateString('en-US', { 
                          year: 'numeric', 
                          month: 'long' 
                        })}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center">
                    <Star className="h-4 w-4 text-accent mr-1 fill-accent" />
                    <span className="font-medium">{review.rating.toFixed(1)}</span>
                  </div>
                </div>
                <p className="text-neutral-700 text-sm">{review.comment}</p>
              </div>
            ))}
          </div>
          
          {vendor.reviewCount > 2 && (
            <Button variant="link" className="p-0 text-secondary font-medium">
              Read all {vendor.reviewCount} reviews
            </Button>
          )}
        </div>
      )}

      {/* Booking CTA */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-neutral-200 p-4 flex justify-between items-center max-w-md mx-auto z-50">
        <div>
          <p className="font-medium text-neutral-800">{vendor.priceRange || 'Contact for pricing'}</p>
          <p className="text-xs text-neutral-600">Price varies by service and date</p>
        </div>
        <div className="flex space-x-3">
          <Button 
            variant="outline" 
            className="border-secondary text-secondary font-medium"
            onClick={handleChat}
          >
            Chat with Vendor
          </Button>
          <Button 
            className="bg-secondary text-white font-medium shadow-sm"
            onClick={handleBookNow}
          >
            Book Now
          </Button>
        </div>
      </div>

      {/* Booking Form Modal */}
      {showBookingForm && (
        <BookingForm 
          vendor={vendor} 
          onClose={closeBookingForm} 
        />
      )}
    </div>
  );
}

function renderAmenities(amenities: string[]) {
  const amenityIcons: Record<string, JSX.Element> = {
    'ParkingMeter': <ParkingMeter className="text-neutral-600 mr-3 h-5 w-5" />,
    'WiFi': <Wifi className="text-neutral-600 mr-3 h-5 w-5" />,
    'Catering': <Utensils className="text-neutral-600 mr-3 h-5 w-5" />,
    'Bar': <GlassWater className="text-neutral-600 mr-3 h-5 w-5" />,
    'Sound System': <Music className="text-neutral-600 mr-3 h-5 w-5" />,
    'Accessibility': <Accessibility className="text-neutral-600 mr-3 h-5 w-5" />,
  };

  return amenities.slice(0, 6).map((amenity, index) => (
    <div key={index} className="flex items-center">
      {amenityIcons[amenity] || <div className="w-5 h-5 mr-3"></div>}
      <span className="text-neutral-700">{amenity}</span>
    </div>
  ));
}

function getCategoryName(category: string): string {
  const categoryMap: Record<string, string> = {
    'venue': 'Venue',
    'catering': 'Catering',
    'photography': 'Photography',
    'decoration': 'Decoration',
    'entertainment': 'Entertainment',
    'other': 'Service Provider'
  };
  
  return categoryMap[category] || 'Service Provider';
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

function VendorDetailsSkeleton() {
  return (
    <div className="h-full w-full">
      <Skeleton className="h-64 w-full" />
      
      <div className="bg-white p-5">
        <div className="flex justify-between items-start mb-2">
          <Skeleton className="h-7 w-48" />
          <Skeleton className="h-5 w-16" />
        </div>
        <Skeleton className="h-5 w-32 mb-4" />
        
        <div className="border-t border-neutral-200 pt-4 pb-2">
          <div className="flex space-x-2 mb-4">
            <Skeleton className="h-8 w-32 rounded-full" />
            <Skeleton className="h-8 w-24 rounded-full" />
          </div>
          
          <Skeleton className="h-4 w-full mb-2" />
          <Skeleton className="h-4 w-full mb-2" />
          <Skeleton className="h-4 w-3/4 mb-4" />
        </div>
      </div>
      
      <div className="bg-white p-5 mt-4">
        <Skeleton className="h-6 w-48 mb-4" />
        <div className="grid grid-cols-2 gap-4">
          {Array(6).fill(0).map((_, i) => (
            <div key={i} className="flex items-center">
              <Skeleton className="h-5 w-5 mr-3 rounded-full" />
              <Skeleton className="h-4 w-24" />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
