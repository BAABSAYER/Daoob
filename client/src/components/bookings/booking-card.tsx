import { format } from "date-fns";
import { useLocation } from "wouter";
import { Booking, BOOKING_STATUS } from "@shared/schema";
import { useMutation } from "@tanstack/react-query";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Star, Clock, Calendar, Users, DollarSign, MessageSquare } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

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
  
  // Handle viewing booking details
  const handleViewDetails = () => {
    // In a real app, navigate to a detailed booking page
    // For now, just show basic info in an alert
    alert(`Booking details for ${booking.id}`);
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
  
  return (
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
  );
}
