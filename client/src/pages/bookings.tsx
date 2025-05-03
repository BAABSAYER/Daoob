import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/hooks/use-auth";
import { Booking, BOOKING_STATUS } from "@shared/schema";
import { BookingCard } from "@/components/bookings/booking-card";
import { Header } from "@/components/layout/header";
import { BottomNavigation } from "@/components/layout/bottom-navigation";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Skeleton } from "@/components/ui/skeleton";

type BookingWithVendorInfo = Booking & {
  vendorName?: string;
  clientName?: string;
};

type FilterTab = "upcoming" | "past" | "pending";

export default function Bookings() {
  const { user } = useAuth();
  const [activeFilter, setActiveFilter] = useState<FilterTab>("upcoming");
  
  const { data: bookings, isLoading } = useQuery<BookingWithVendorInfo[]>({
    queryKey: ['/api/bookings']
  });
  
  // Filter bookings based on the active tab
  const filteredBookings = bookings?.filter(booking => {
    const today = new Date();
    const eventDate = new Date(booking.eventDate);
    const isPast = eventDate < today;
    
    switch (activeFilter) {
      case "upcoming":
        return !isPast && 
          (booking.status === BOOKING_STATUS.CONFIRMED);
      case "past":
        return isPast || 
          (booking.status === BOOKING_STATUS.COMPLETED);
      case "pending":
        return booking.status === BOOKING_STATUS.PENDING;
      default:
        return true;
    }
  });
  
  const isVendor = user?.userType === "vendor";
  
  return (
    <div className="h-full w-full flex flex-col pb-16">
      {/* Header */}
      <Header title="My Bookings" showBack={false} showSearch={false} />

      {/* Tabs */}
      <Tabs defaultValue="upcoming" onValueChange={(value) => setActiveFilter(value as FilterTab)} className="w-full">
        <TabsList className="w-full grid grid-cols-3 border-b border-neutral-200 rounded-none bg-white h-auto">
          <TabsTrigger 
            value="upcoming"
            className="py-3 data-[state=active]:border-b-2 data-[state=active]:border-secondary data-[state=active]:text-secondary data-[state=active]:shadow-none font-medium rounded-none"
          >
            Upcoming
          </TabsTrigger>
          <TabsTrigger 
            value="past"
            className="py-3 data-[state=active]:border-b-2 data-[state=active]:border-secondary data-[state=active]:text-secondary data-[state=active]:shadow-none font-medium rounded-none"
          >
            Past
          </TabsTrigger>
          <TabsTrigger 
            value="pending"
            className="py-3 data-[state=active]:border-b-2 data-[state=active]:border-secondary data-[state=active]:text-secondary data-[state=active]:shadow-none font-medium rounded-none"
          >
            Pending
          </TabsTrigger>
        </TabsList>
        
        <TabsContent value="upcoming" className="m-0 pt-0">
          <BookingsList 
            bookings={filteredBookings} 
            isLoading={isLoading} 
            emptyMessage="No upcoming bookings"
            isVendor={isVendor}
          />
        </TabsContent>
        
        <TabsContent value="past" className="m-0 pt-0">
          <BookingsList 
            bookings={filteredBookings} 
            isLoading={isLoading} 
            emptyMessage="No past bookings"
            isVendor={isVendor}
          />
        </TabsContent>
        
        <TabsContent value="pending" className="m-0 pt-0">
          <BookingsList 
            bookings={filteredBookings} 
            isLoading={isLoading} 
            emptyMessage="No pending bookings"
            isVendor={isVendor}
          />
        </TabsContent>
      </Tabs>

      {/* Bottom Navigation */}
      <BottomNavigation />
    </div>
  );
}

interface BookingsListProps {
  bookings?: BookingWithVendorInfo[];
  isLoading: boolean;
  emptyMessage: string;
  isVendor: boolean;
}

function BookingsList({ bookings, isLoading, emptyMessage, isVendor }: BookingsListProps) {
  return (
    <div className="bg-neutral-100 p-4 pb-24 min-h-[calc(100vh-13rem)]">
      {isLoading && (
        <div className="space-y-4">
          <Skeleton className="h-48 w-full rounded-xl" />
          <Skeleton className="h-48 w-full rounded-xl" />
        </div>
      )}
      
      {!isLoading && (!bookings || bookings.length === 0) && (
        <div className="flex flex-col items-center justify-center h-48 text-center">
          <p className="text-neutral-500">{emptyMessage}</p>
        </div>
      )}
      
      <div className="space-y-4">
        {bookings?.map((booking) => (
          <BookingCard 
            key={booking.id} 
            booking={booking}
            isVendor={isVendor}
          />
        ))}
      </div>
    </div>
  );
}
