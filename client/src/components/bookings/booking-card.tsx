import { format } from "date-fns";
import { useLocation } from "wouter";
import { Booking, BOOKING_STATUS, EVENT_TYPES } from "@shared/schema";
import { useMutation } from "@tanstack/react-query";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Star, Clock, Calendar, Users, DollarSign, MessageSquare, X, Info, MapPin, Tag, Package, FileText } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { useState } from "react";
import { Separator } from "@/components/ui/separator";

interface BookingCardProps {
  booking: Booking & {
    vendorName?: string;
    clientName?: string;
  };
  isVendor?: boolean;
}

export function BookingCard({ booking, isVendor = false }: BookingCardProps) {
  const [, navigate] = useLocation();
  
  // Function to format status styles
  const getStatusStyles = (status: string) => {
    switch (status) {
      case BOOKING_STATUS.CONFIRMED:
        return { bg: "bg-green-500", text: "text-white" };
      case BOOKING_STATUS.PENDING:
        return { bg: "bg-yellow-500", text: "text-white" };
      case BOOKING_STATUS.CANCELLED:
        return { bg: "bg-red-500", text: "text-white" };
      case BOOKING_STATUS.COMPLETED:
        return { bg: "bg-blue-500", text: "text-white" };
      default:
        return { bg: "bg-neutral-500", text: "text-white" };
    }
  };
  
  // Get the booking image based on vendor type
  const getBookingImage = () => {
    return "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60";
  };
  
  // Format date
  const formattedDate = booking.eventDate 
    ? format(new Date(booking.eventDate), "MMM d, yyyy")
    : "Date not set";
  
  // Format booking status for display
  const formatStatus = (status: string) => {
    return status.charAt(0).toUpperCase() + status.slice(1);
  };
  
  // Handle messaging the other party
  const handleMessage = () => {
    // Navigate to the chat with the vendor or client
    const chatUserId = isVendor ? booking.clientId : booking.vendorId;
    navigate(`/chat/${chatUserId}`);
  };
  
  // State for booking details modal
  const [showDetails, setShowDetails] = useState(false);
  
  // Handle viewing booking details
  const handleViewDetails = () => {
    setShowDetails(true);
  };
  
  // Update booking status mutation
  const updateStatusMutation = useMutation({
    mutationFn: async (newStatus: string) => {
      await apiRequest("PUT", `/api/bookings/${booking.id}`, {
        status: newStatus
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/bookings'] });
    }
  });
  
  // Functions to accept or cancel booking
  const acceptBooking = () => {
    updateStatusMutation.mutate(BOOKING_STATUS.CONFIRMED);
  };
  
  const cancelBooking = () => {
    updateStatusMutation.mutate(BOOKING_STATUS.CANCELLED);
  };
  
  const { bg, text } = getStatusStyles(booking.status);
  
  // Format time
  const formatTime = (dateString: string) => {
    return format(new Date(dateString), "h:mm a");
  };
  
  // Format event type for display
  const formatEventType = (type: string) => {
    const eventTypeMap: Record<string, string> = {
      [EVENT_TYPES.WEDDING]: "Wedding",
      [EVENT_TYPES.CORPORATE]: "Corporate Event",
      [EVENT_TYPES.BIRTHDAY]: "Birthday Party",
      [EVENT_TYPES.GRADUATION]: "Graduation",
      [EVENT_TYPES.SOCIAL]: "Social Gathering",
      [EVENT_TYPES.OTHER]: "Other Event"
    };
    
    return eventTypeMap[type] || type;
  };
  
  // Format package name
  const getPackageName = (id: string | null) => {
    if (!id) return "Not specified";
    
    switch(id) {
      case "basic":
        return "Basic Package";
      case "standard":
        return "Standard Package";
      case "premium":
        return "Premium Package";
      default:
        return id;
    }
  };
  
  return (
    <>
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <div className="h-24 relative">
          <div 
            className="w-full h-full bg-cover bg-center"
            style={{ backgroundImage: `url(${getBookingImage()})` }}
          ></div>
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent flex items-end p-3">
            <div>
              <p className="text-white font-medium">{booking.vendorName}</p>
              <p className="text-white/80 text-sm">
                {booking.eventType} • {formattedDate}
              </p>
            </div>
          </div>
          <div className={`absolute top-3 right-3 ${bg} ${text} text-xs px-2 py-1 rounded-full`}>
            {formatStatus(booking.status)}
          </div>
        </div>
        <div className="p-4">
          <div className="flex justify-between items-center mb-3">
            <div className="space-y-1">
              <div className="flex items-center text-sm text-neutral-600">
                <Calendar className="h-3.5 w-3.5 mr-1" />
                <span>{formattedDate}</span>
              </div>
              {booking.guestCount && (
                <div className="flex items-center text-sm text-neutral-600">
                  <Users className="h-3.5 w-3.5 mr-1" />
                  <span>{booking.guestCount} Guests</span>
                </div>
              )}
              {booking.totalPrice && (
                <div className="flex items-center text-sm text-neutral-600">
                  <DollarSign className="h-3.5 w-3.5 mr-1" />
                  <span>${booking.totalPrice.toLocaleString()}</span>
                </div>
              )}
            </div>
            {isVendor && booking.status === BOOKING_STATUS.PENDING && (
              <Badge className="bg-yellow-500">Action Required</Badge>
            )}
          </div>
          
          {/* Different buttons based on status and user type */}
          <div className="flex space-x-2">
            {/* Message button is always available */}
            <Button 
              variant="outline" 
              className="flex-1 border-secondary text-secondary text-sm font-medium"
              onClick={handleMessage}
            >
              <MessageSquare className="mr-1 h-4 w-4" />
              Message
            </Button>
            
            {/* For clients with pending bookings */}
            {!isVendor && booking.status === BOOKING_STATUS.PENDING && (
              <Button 
                variant="outline" 
                className="flex-1 border-red-500 text-red-500 text-sm font-medium"
                onClick={cancelBooking}
                disabled={updateStatusMutation.isPending}
              >
                Cancel
              </Button>
            )}
            
            {/* For vendors with pending bookings */}
            {isVendor && booking.status === BOOKING_STATUS.PENDING && (
              <>
                <Button 
                  variant="outline" 
                  className="flex-1 border-red-500 text-red-500 text-sm font-medium"
                  onClick={cancelBooking}
                  disabled={updateStatusMutation.isPending}
                >
                  Decline
                </Button>
                <Button 
                  className="flex-1 bg-green-500 text-white text-sm font-medium"
                  onClick={acceptBooking}
                  disabled={updateStatusMutation.isPending}
                >
                  Accept
                </Button>
              </>
            )}
            
            {/* For confirmed bookings */}
            {(booking.status === BOOKING_STATUS.CONFIRMED || booking.status === BOOKING_STATUS.COMPLETED) && (
              <Button 
                className="flex-1 bg-secondary text-white text-sm font-medium"
                onClick={handleViewDetails}
              >
                View Details
              </Button>
            )}
            
            {/* For cancelled bookings */}
            {booking.status === BOOKING_STATUS.CANCELLED && (
              <Button 
                className="flex-1 bg-neutral-500 text-white text-sm font-medium"
                disabled
              >
                Cancelled
              </Button>
            )}
          </div>
        </div>
      </div>
      
      {/* Booking Details Modal */}
      {showDetails && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-md max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-xl font-semibold text-neutral-800">Booking Details</h2>
                <button 
                  onClick={() => setShowDetails(false)}
                  className="text-neutral-500 hover:text-neutral-700"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
              
              {/* Status Badge */}
              <div className="mb-6">
                <div className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${bg} ${text}`}>
                  <div className="w-2 h-2 rounded-full bg-current mr-2"></div>
                  {formatStatus(booking.status)}
                </div>
              </div>
              
              {/* Event Details */}
              <div className="mb-6">
                <h3 className="text-sm font-medium text-neutral-500 mb-3">EVENT DETAILS</h3>
                
                <div className="space-y-4">
                  <div className="flex">
                    <Tag className="h-5 w-5 text-neutral-500 mr-3 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-neutral-700">Event Type</p>
                      <p className="text-sm text-neutral-600">{formatEventType(booking.eventType)}</p>
                    </div>
                  </div>
                  
                  <div className="flex">
                    <Calendar className="h-5 w-5 text-neutral-500 mr-3 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-neutral-700">Date & Time</p>
                      <p className="text-sm text-neutral-600">
                        {format(new Date(booking.eventDate), "EEEE, MMMM d, yyyy")}
                      </p>
                    </div>
                  </div>
                  
                  <div className="flex">
                    <Users className="h-5 w-5 text-neutral-500 mr-3 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-neutral-700">Guest Count</p>
                      <p className="text-sm text-neutral-600">{booking.guestCount} guests</p>
                    </div>
                  </div>
                  
                  <div className="flex">
                    <Package className="h-5 w-5 text-neutral-500 mr-3 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-neutral-700">Package</p>
                      <p className="text-sm text-neutral-600">{getPackageName((booking as any).packageId)}</p>
                    </div>
                  </div>
                </div>
              </div>
              
              <Separator className="my-4" />
              
              {/* Vendor/Client Info */}
              <div className="mb-6">
                <h3 className="text-sm font-medium text-neutral-500 mb-3">
                  {isVendor ? "CLIENT INFORMATION" : "VENDOR INFORMATION"}
                </h3>
                
                <div className="space-y-4">
                  <div className="flex">
                    <Info className="h-5 w-5 text-neutral-500 mr-3 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-neutral-700">Name</p>
                      <p className="text-sm text-neutral-600">
                        {isVendor ? booking.clientName || "Client" : booking.vendorName || "Vendor"}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              
              <Separator className="my-4" />
              
              {/* Price Breakdown */}
              <div className="mb-6">
                <h3 className="text-sm font-medium text-neutral-500 mb-3">PRICE DETAILS</h3>
                
                <div className="rounded-lg bg-neutral-50 p-4">
                  <div className="flex justify-between mb-2">
                    <span className="text-sm text-neutral-600">Package Price</span>
                    <span className="text-sm font-medium text-neutral-800">
                      ${((booking.totalPrice || 0) * 0.8).toFixed(2)}
                    </span>
                  </div>
                  
                  <div className="flex justify-between mb-2">
                    <span className="text-sm text-neutral-600">Service Fee</span>
                    <span className="text-sm font-medium text-neutral-800">
                      ${((booking.totalPrice || 0) * 0.05).toFixed(2)}
                    </span>
                  </div>
                  
                  <div className="flex justify-between mb-3">
                    <span className="text-sm text-neutral-600">Tax</span>
                    <span className="text-sm font-medium text-neutral-800">
                      ${((booking.totalPrice || 0) * 0.15).toFixed(2)}
                    </span>
                  </div>
                  
                  <div className="border-t border-neutral-200 pt-3 flex justify-between items-center">
                    <span className="text-sm font-medium text-neutral-700">Total</span>
                    <span className="text-base font-semibold text-neutral-800">
                      ${(booking.totalPrice || 0).toLocaleString()}
                    </span>
                  </div>
                </div>
              </div>
              
              {/* Special Requests */}
              {booking.specialRequests && (
                <div className="mb-6">
                  <h3 className="text-sm font-medium text-neutral-500 mb-3">SPECIAL REQUESTS</h3>
                  
                  <div className="rounded-lg bg-neutral-50 p-4">
                    <div className="flex">
                      <FileText className="h-5 w-5 text-neutral-500 mr-3 mt-0.5 flex-shrink-0" />
                      <p className="text-sm text-neutral-600">{booking.specialRequests}</p>
                    </div>
                  </div>
                </div>
              )}
              
              {/* Action Buttons */}
              <div className="flex space-x-3 mt-6">
                <Button
                  variant="outline"
                  className="flex-1 border-secondary text-secondary"
                  onClick={handleMessage}
                >
                  <MessageSquare className="mr-2 h-4 w-4" />
                  Message
                </Button>
                
                <Button
                  className="flex-1 bg-secondary text-white"
                  onClick={() => setShowDetails(false)}
                >
                  Close
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
