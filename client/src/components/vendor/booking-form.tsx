import { useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { useLocation } from "wouter";
import { Vendor, EVENT_TYPES, BOOKING_STATUS } from "@shared/schema";
import { useToast } from "@/hooks/use-toast";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { X, Calendar as CalendarIcon } from "lucide-react";
import { format } from "date-fns";
import { cn } from "@/lib/utils";

interface BookingFormProps {
  vendor: Vendor;
  onClose: () => void;
}

// Define the package types
interface PackageOption {
  id: string;
  name: string;
  description: string;
  price: number;
}

// Generate packages based on vendor category
const getPackagesForVendor = (vendor: Vendor): PackageOption[] => {
  const basePrice = vendor.category === 'venue' ? 2000 : 
                   vendor.category === 'catering' ? 1000 :
                   vendor.category === 'photography' ? 1500 : 800;
  
  return [
    {
      id: 'basic',
      name: 'Basic Package',
      description: vendor.category === 'venue' 
        ? 'Venue rental only (8 hours)'
        : `Basic ${vendor.category} service`,
      price: basePrice
    },
    {
      id: 'standard',
      name: 'Standard Package',
      description: vendor.category === 'venue' 
        ? 'Venue rental + basic decor + sound system (10 hours)'
        : `Standard ${vendor.category} service with additional options`,
      price: basePrice * 1.75
    },
    {
      id: 'premium',
      name: 'Premium Package',
      description: vendor.category === 'venue' 
        ? 'All inclusive: venue, decor, catering, bar (12 hours)'
        : `Premium ${vendor.category} service with all features`,
      price: basePrice * 2.5
    }
  ];
};

// Booking form validation schema
const bookingSchema = z.object({
  eventType: z.string().min(1, "Event type is required"),
  eventDate: z.date({
    required_error: "Event date is required",
    invalid_type_error: "Event date must be a valid date"
  }),
  guestCount: z.coerce.number().min(1, "Number of guests is required"),
  packageId: z.string().min(1, "Package selection is required"),
  specialRequests: z.string().optional(),
});

type BookingFormValues = z.infer<typeof bookingSchema>;

export function BookingForm({ vendor, onClose }: BookingFormProps) {
  const { toast } = useToast();
  const [, navigate] = useLocation();
  const [showConfirmation, setShowConfirmation] = useState(false);
  const [selectedPackage, setSelectedPackage] = useState<PackageOption | null>(null);
  
  const packageOptions = getPackagesForVendor(vendor);
  
  // Set default date to tomorrow
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  
  const {
    register,
    handleSubmit,
    setValue,
    watch,
    formState: { errors },
  } = useForm<BookingFormValues>({
    resolver: zodResolver(bookingSchema),
    defaultValues: {
      packageId: '',
      guestCount: 0,
      specialRequests: '',
      eventDate: tomorrow
    }
  });
  
  // Watch fields for calculations
  const packageId = watch('packageId');
  const guestCount = watch('guestCount');
  
  // Automatically set the selectedPackage when packageId changes
  // Using useEffect instead of useState for side effects
  useEffect(() => {
    if (packageId) {
      const found = packageOptions.find(p => p.id === packageId);
      if (found) setSelectedPackage(found);
    }
  }, [packageId, packageOptions]);
  
  // Calculate total price
  const calculateTotal = () => {
    if (!selectedPackage) {
      return {
        subtotal: 0,
        serviceFee: 0,
        tax: 0,
        total: 0
      };
    }
    
    const basePrice = selectedPackage.price;
    const guestPriceMultiplier = guestCount > 200 ? 1.2 : 
                               guestCount > 100 ? 1.1 : 
                               guestCount > 50 ? 1.05 : 1;
    
    const subtotal = basePrice * guestPriceMultiplier;
    const serviceFee = subtotal * 0.05;
    const tax = subtotal * 0.09;
    
    return {
      subtotal,
      serviceFee,
      tax,
      total: subtotal + serviceFee + tax
    };
  };
  
  const priceBreakdown = calculateTotal();
  
  const bookingMutation = useMutation({
    mutationFn: async (data: BookingFormValues) => {
      return await apiRequest("POST", "/api/bookings", {
        vendorId: vendor.id,
        eventType: data.eventType,
        eventDate: data.eventDate,
        guestCount: data.guestCount,
        serviceId: null, // We're not using actual service IDs from the DB for this MVP
        specialRequests: data.specialRequests,
        totalPrice: priceBreakdown.total,
        status: BOOKING_STATUS.PENDING
      });
    },
    onSuccess: () => {
      setShowConfirmation(true);
      queryClient.invalidateQueries({ queryKey: ['/api/bookings'] });
    },
    onError: (error: Error) => {
      toast({
        title: "Booking Failed",
        description: error.message,
        variant: "destructive",
      });
    },
  });
  
  const onSubmit = (data: BookingFormValues) => {
    bookingMutation.mutate(data);
  };
  
  const viewBookings = () => {
    onClose();
    navigate('/bookings');
  };
  
  const closeConfirmation = () => {
    onClose();
  };
  
  if (showConfirmation) {
    return (
      <div className="fixed inset-0 bg-neutral-900/50 z-50 flex items-center justify-center">
        <div className="bg-white w-[90%] max-w-sm rounded-2xl p-6 text-center">
          <div className="w-20 h-20 bg-secondary/20 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" className="h-10 w-10 text-secondary">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h2 className="font-poppins font-semibold text-xl text-neutral-800 mb-2">Booking Requested!</h2>
          <p className="text-neutral-600 mb-6">
            Your booking request has been sent to {vendor.businessName}. You'll receive a confirmation once they accept.
          </p>
          <div className="space-y-3">
            <Button onClick={viewBookings} className="w-full bg-secondary text-white font-semibold">
              View My Bookings
            </Button>
            <Button onClick={closeConfirmation} variant="outline" className="w-full border border-neutral-300 text-neutral-700 font-medium">
              Return to Home
            </Button>
          </div>
        </div>
      </div>
    );
  }
  
  return (
    <div className="fixed inset-0 bg-neutral-900/50 z-50 flex items-end justify-center">
      <div className="bg-white w-full max-w-md rounded-t-2xl p-6 slide-in overflow-y-auto max-h-[90vh]">
        <div className="flex justify-between items-center mb-6">
          <h2 className="font-poppins font-semibold text-xl text-neutral-800">Book {vendor.category === 'venue' ? 'Venue' : 'Service'}</h2>
          <button onClick={onClose} className="text-neutral-500">
            <X className="h-5 w-5" />
          </button>
        </div>
        
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
          <div>
            <Label htmlFor="eventType">Event Type</Label>
            <Select 
              onValueChange={(value) => setValue("eventType", value)}
              defaultValue=""
            >
              <SelectTrigger id="eventType" className={errors.eventType ? "border-red-500" : ""}>
                <SelectValue placeholder="Select event type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={EVENT_TYPES.WEDDING}>Wedding</SelectItem>
                <SelectItem value={EVENT_TYPES.CORPORATE}>Corporate Event</SelectItem>
                <SelectItem value={EVENT_TYPES.BIRTHDAY}>Birthday Party</SelectItem>
                <SelectItem value={EVENT_TYPES.GRADUATION}>Graduation</SelectItem>
                <SelectItem value={EVENT_TYPES.SOCIAL}>Social Gathering</SelectItem>
                <SelectItem value={EVENT_TYPES.OTHER}>Other</SelectItem>
              </SelectContent>
            </Select>
            {errors.eventType && (
              <p className="text-red-500 text-xs mt-1">{errors.eventType.message}</p>
            )}
          </div>
          
          <div>
            <Label htmlFor="eventDate">Event Date</Label>
            <Popover>
              <PopoverTrigger asChild>
                <Button
                  variant={"outline"}
                  className={cn(
                    "w-full justify-start text-left font-normal",
                    !watch("eventDate") && "text-muted-foreground",
                    errors.eventDate && "border-red-500"
                  )}
                >
                  <CalendarIcon className="mr-2 h-4 w-4" />
                  {watch("eventDate") ? format(watch("eventDate"), "PPP") : <span>Pick a date</span>}
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-0">
                <Calendar
                  mode="single"
                  selected={watch("eventDate")}
                  onSelect={(date) => setValue("eventDate", date as Date)}
                  initialFocus
                  disabled={(date) => date < new Date()}
                />
              </PopoverContent>
            </Popover>
            {errors.eventDate && (
              <p className="text-red-500 text-xs mt-1">{errors.eventDate.message}</p>
            )}
          </div>
          
          <div>
            <Label htmlFor="guestCount">Number of Guests</Label>
            <Input
              id="guestCount"
              type="number"
              placeholder="Estimated guest count"
              {...register("guestCount")}
              className={errors.guestCount ? "border-red-500" : ""}
            />
            {errors.guestCount && (
              <p className="text-red-500 text-xs mt-1">{errors.guestCount.message}</p>
            )}
          </div>
          
          <div>
            <Label htmlFor="package">Package</Label>
            <div className="space-y-3">
              {packageOptions.map((pkg) => (
                <div 
                  key={pkg.id}
                  className={cn(
                    "border rounded-lg p-4 cursor-pointer",
                    packageId === pkg.id 
                      ? "border-secondary bg-secondary/5" 
                      : "border-neutral-300 hover:border-secondary hover:bg-secondary/5"
                  )}
                  onClick={() => {
                    setValue("packageId", pkg.id);
                    setSelectedPackage(pkg);
                  }}
                >
                  <div className="flex justify-between items-start">
                    <div>
                      <h3 className="font-medium text-neutral-800">{pkg.name}</h3>
                      <p className="text-sm text-neutral-600 mt-1">{pkg.description}</p>
                    </div>
                    <div className="font-medium text-neutral-800">${pkg.price.toLocaleString()}</div>
                  </div>
                </div>
              ))}
            </div>
            {errors.packageId && (
              <p className="text-red-500 text-xs mt-1">{errors.packageId.message}</p>
            )}
          </div>
          
          <div>
            <Label htmlFor="specialRequests">Special Requests</Label>
            <Textarea
              id="specialRequests"
              rows={3}
              placeholder="Any special requirements or questions..."
              {...register("specialRequests")}
            />
          </div>
          
          <div className="border-t border-neutral-200 pt-4">
            {/* Guest count multiplier explanation if applicable */}
            {selectedPackage && guestCount > 50 && (
              <div className="flex justify-between mb-2 text-sm text-neutral-600 italic">
                <span>Guest count pricing adjustment applied</span>
                <span>
                  {guestCount > 200 ? "+20%" : 
                   guestCount > 100 ? "+10%" :
                   guestCount > 50 ? "+5%" : ""}
                </span>
              </div>
            )}
            
            <div className="flex justify-between mb-2">
              <span className="text-neutral-700">Package Price</span>
              <span className="font-medium text-neutral-800">
                ${priceBreakdown.subtotal.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </span>
            </div>
            <div className="flex justify-between mb-2">
              <span className="text-neutral-700">Service Fee</span>
              <span className="font-medium text-neutral-800">
                ${priceBreakdown.serviceFee.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </span>
            </div>
            <div className="flex justify-between mb-2">
              <span className="text-neutral-700">Tax</span>
              <span className="font-medium text-neutral-800">
                ${priceBreakdown.tax.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </span>
            </div>
            <div className="flex justify-between pt-2 border-t border-neutral-200">
              <span className="font-medium text-neutral-800">Total</span>
              <span className="font-semibold text-neutral-800">
                ${priceBreakdown.total.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </span>
            </div>
          </div>
          
          <div className="pt-2">
            <Button 
              type="submit" 
              className="w-full bg-secondary text-white font-semibold"
              disabled={bookingMutation.isPending}
            >
              {bookingMutation.isPending ? "Processing..." : "Request Booking"}
            </Button>
            <p className="text-center text-xs text-neutral-600 mt-2">
              You won't be charged until the vendor confirms your booking
            </p>
          </div>
        </form>
      </div>
    </div>
  );
}
