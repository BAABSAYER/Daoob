import { useEffect } from "react";
import { useLocation } from "wouter";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/hooks/use-auth";
import { 
  Package, Plus, Pencil, MoreVertical, ChevronLeft, 
  Star, DollarSign, Users, Calendar
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { 
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Skeleton } from "@/components/ui/skeleton";
import { Header } from "@/components/layout/header";

export default function VendorServices() {
  const { user } = useAuth();
  const [, navigate] = useLocation();
  
  // Redirect to regular dashboard if not a vendor
  useEffect(() => {
    if (user && user.userType !== 'vendor') {
      navigate("/");
    }
  }, [user, navigate]);
  
  // Fetch vendor's services
  const { data: services, isLoading } = useQuery({
    queryKey: ['/api/services'],
    enabled: !!user && user.userType === 'vendor',
  });
  
  const handleAddService = () => {
    navigate("/vendor-dashboard/services/new");
  };
  
  const handleEditService = (id: number) => {
    navigate(`/vendor-dashboard/services/edit/${id}`);
  };
  
  return (
    <div className="pb-20">
      <Header title="My Services" showBack={true} showSearch={false} />
      
      <div className="px-5 pt-4">
        <div className="flex justify-between items-center mb-4">
          <h2 className="font-poppins font-semibold text-lg text-neutral-800">Services & Packages</h2>
          <Button 
            onClick={handleAddService}
            className="bg-secondary text-white"
            size="sm"
          >
            <Plus className="h-4 w-4 mr-1" />
            Add New
          </Button>
        </div>
        
        {isLoading ? (
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <Skeleton key={i} className="h-40 rounded-xl" />
            ))}
          </div>
        ) : services && services.length > 0 ? (
          <div className="space-y-4">
            {services.map((service: any) => (
              <ServiceCard 
                key={service.id}
                service={service}
                onEdit={() => handleEditService(service.id)}
              />
            ))}
          </div>
        ) : (
          <div className="bg-white rounded-xl p-6 text-center shadow-sm">
            <Package className="h-12 w-12 text-neutral-300 mx-auto mb-3" />
            <h3 className="font-medium text-lg text-neutral-800 mb-2">No Services Yet</h3>
            <p className="text-neutral-600 mb-4">
              Add services or packages that you offer to attract more clients.
            </p>
            <Button 
              onClick={handleAddService}
              className="bg-secondary text-white"
            >
              <Plus className="h-4 w-4 mr-1" />
              Add Your First Service
            </Button>
          </div>
        )}
        
        <div className="mt-8">
          <h3 className="font-poppins font-semibold text-lg text-neutral-800 mb-3">Tips for creating great services</h3>
          <Card className="bg-blue-50 border-blue-100">
            <CardContent className="p-4">
              <ul className="space-y-2 text-sm text-blue-800">
                <li>• Be specific about what's included in each package</li>
                <li>• Differentiate your basic, standard, and premium offerings</li>
                <li>• Include high-quality photos of your work</li>
                <li>• Mention any special skills or equipment you use</li>
                <li>• Be transparent about pricing and any additional costs</li>
              </ul>
            </CardContent>
          </Card>
        </div>
        
        <div className="mt-8 flex">
          <Button
            variant="outline"
            className="flex-1 mr-2"
            onClick={() => navigate("/vendor-dashboard")}
          >
            <ChevronLeft className="h-4 w-4 mr-1" />
            Dashboard
          </Button>
          <Button
            className="flex-1 bg-secondary text-white ml-2"
            onClick={handleAddService}
          >
            <Plus className="h-4 w-4 mr-1" />
            Add Service
          </Button>
        </div>
      </div>
    </div>
  );
}

function ServiceCard({ service, onEdit }: { service: any, onEdit: () => void }) {
  return (
    <div className="bg-white rounded-xl overflow-hidden shadow-sm">
      <div className="h-40 bg-neutral-200 relative">
        {service.images && service.images[0] ? (
          <div 
            className="w-full h-full bg-cover bg-center" 
            style={{ backgroundImage: `url(${service.images[0]})` }}
          />
        ) : (
          <div className="w-full h-full bg-neutral-200 flex items-center justify-center">
            <Package className="h-10 w-10 text-neutral-400" />
          </div>
        )}
        <div className="absolute top-3 right-3">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" className="h-8 w-8 bg-white/80 rounded-full">
                <MoreVertical className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem onClick={onEdit}>
                <Pencil className="h-4 w-4 mr-2" />
                Edit
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>
      <div className="p-4">
        <div className="flex justify-between items-start mb-2">
          <h3 className="font-medium text-neutral-800">{service.name}</h3>
          <div className="flex items-center">
            <Star className="h-4 w-4 text-yellow-500 fill-yellow-500 mr-1" />
            <span className="text-sm">{service.rating ? service.rating.toFixed(1) : 'New'}</span>
          </div>
        </div>
        <p className="text-sm text-neutral-600 mb-3 line-clamp-2">{service.description}</p>
        <div className="flex flex-wrap gap-2 mb-3">
          <span className="bg-neutral-100 text-neutral-700 text-xs px-2 py-1 rounded-full flex items-center">
            <DollarSign className="h-3 w-3 mr-1" />
            From ${service.basePrice}
          </span>
          {service.maxGuests && (
            <span className="bg-neutral-100 text-neutral-700 text-xs px-2 py-1 rounded-full flex items-center">
              <Users className="h-3 w-3 mr-1" />
              Up to {service.maxGuests} guests
            </span>
          )}
          {service.bookingCount > 0 && (
            <span className="bg-neutral-100 text-neutral-700 text-xs px-2 py-1 rounded-full flex items-center">
              <Calendar className="h-3 w-3 mr-1" />
              {service.bookingCount} bookings
            </span>
          )}
        </div>
        <Button 
          variant="outline" 
          size="sm" 
          className="w-full border-secondary text-secondary"
          onClick={onEdit}
        >
          <Pencil className="h-3 w-3 mr-1" />
          Edit Service
        </Button>
      </div>
    </div>
  );
}