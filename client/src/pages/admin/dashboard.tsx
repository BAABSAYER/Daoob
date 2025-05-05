import { useQuery } from "@tanstack/react-query";
import { AdminLayout } from "@/components/admin-layout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Calendar, Calendar as CalendarIcon, User, Users } from "lucide-react";
import { BOOKING_STATUS } from "@shared/schema";
import { Skeleton } from "@/components/ui/skeleton";

export default function AdminDashboard() {
  const { data: bookings, isLoading: isLoadingBookings } = useQuery({
    queryKey: ["/api/bookings"],
    enabled: true,
  });

  const { data: vendors, isLoading: isLoadingVendors } = useQuery({
    queryKey: ["/api/vendors"],
    enabled: true,
  });

  const pendingBookingsCount = bookings?.filter(
    (booking: any) => booking.status === BOOKING_STATUS.PENDING
  ).length || 0;

  const vendorsCount = vendors?.length || 0;

  return (
    <AdminLayout title="Admin Dashboard">
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Pending Bookings</CardTitle>
            <Calendar className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            {isLoadingBookings ? (
              <Skeleton className="h-8 w-24" />
            ) : (
              <div className="text-2xl font-bold">{pendingBookingsCount}</div>
            )}
            <p className="text-xs text-muted-foreground">
              Bookings awaiting your approval
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Total Vendors</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            {isLoadingVendors ? (
              <Skeleton className="h-8 w-24" />
            ) : (
              <div className="text-2xl font-bold">{vendorsCount}</div>
            )}
            <p className="text-xs text-muted-foreground">
              Vendors in the platform
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Recent Activity</CardTitle>
            <CalendarIcon className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {isLoadingBookings ? (
                <>
                  <Skeleton className="h-5 w-full" />
                  <Skeleton className="h-5 w-full" />
                  <Skeleton className="h-5 w-full" />
                </>
              ) : bookings && bookings.length > 0 ? (
                bookings
                  .slice(0, 3)
                  .map((booking: any) => (
                    <div key={booking.id} className="flex items-center">
                      <div className="ml-4 space-y-1">
                        <p className="text-sm font-medium">
                          New {booking.eventType} booking
                        </p>
                        <p className="text-xs text-muted-foreground">
                          Status: {booking.status}
                        </p>
                      </div>
                    </div>
                  ))
              ) : (
                <p className="text-sm text-muted-foreground">No recent activity</p>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="mt-6">
        <h2 className="text-xl font-bold mb-4">Pending Requests</h2>
        <div className="rounded-md border">
          {isLoadingBookings ? (
            <div className="p-4">
              <Skeleton className="h-12 w-full mb-4" />
              <Skeleton className="h-12 w-full mb-4" />
              <Skeleton className="h-12 w-full" />
            </div>
          ) : bookings && bookings.filter((b: any) => b.status === BOOKING_STATUS.PENDING).length > 0 ? (
            <div className="divide-y">
              {bookings
                .filter((booking: any) => booking.status === BOOKING_STATUS.PENDING)
                .map((booking: any) => (
                  <div key={booking.id} className="p-4 flex justify-between items-center">
                    <div>
                      <h3 className="font-medium">{booking.eventType} Event</h3>
                      <p className="text-sm text-muted-foreground">
                        Date: {new Date(booking.eventDate).toLocaleDateString()}
                      </p>
                      <p className="text-sm text-muted-foreground">
                        Guests: {booking.guestCount}
                      </p>
                    </div>
                    <div className="flex gap-2">
                      <a 
                        href={`/admin/bookings#${booking.id}`} 
                        className="px-3 py-1 bg-primary text-white rounded-md text-sm"
                      >
                        View Details
                      </a>
                    </div>
                  </div>
                ))}
            </div>
          ) : (
            <div className="p-8 text-center">
              <h3 className="text-lg font-medium">No pending requests</h3>
              <p className="text-muted-foreground mt-1">
                All booking requests have been handled
              </p>
            </div>
          )}
        </div>
      </div>
    </AdminLayout>
  );
}