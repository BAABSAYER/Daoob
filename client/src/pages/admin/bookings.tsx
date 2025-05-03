import { useEffect, useState } from "react";
import { useLocation } from "wouter";
import { useQuery, useMutation } from "@tanstack/react-query";
import { useAuth } from "@/hooks/use-auth";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { 
  ChevronLeft, Search, Filter, Calendar, Store, User,
  MoreHorizontal, Download, ChevronRight, Info, ArrowUpDown,
  Clock, CheckCircle2, XCircle, Calendar as CalendarIcon,
  Users, DollarSign, MessageSquare, ClipboardCheck, Trash
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { 
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { 
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { 
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { 
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { BOOKING_STATUS } from "@shared/schema";

// Booking types for typesafety
interface Booking {
  id: number;
  clientId: number;
  vendorId: number;
  serviceId: number | null;
  status: string;
  eventType: string;
  eventDate: string;
  guestCount: number | null;
  totalPrice: number | null;
  specialRequests: string | null;
  createdAt: string;
  vendorName?: string;
  clientName?: string;
  serviceName?: string;
  packageType?: string;
}

export default function AdminBookings() {
  const { user } = useAuth();
  const [, navigate] = useLocation();
  const { toast } = useToast();
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [selectedBooking, setSelectedBooking] = useState<Booking | null>(null);
  const [showActionDialog, setShowActionDialog] = useState(false);
  const [bookingAction, setBookingAction] = useState<"confirm" | "cancel">("confirm");
  
  // Redirect if not an admin
  useEffect(() => {
    if (user && user.userType !== 'admin') {
      navigate("/");
    }
  }, [user, navigate]);
  
  // Fetch bookings data
  const { data: bookingsData, isLoading } = useQuery({
    queryKey: ['/api/admin/bookings', searchQuery, statusFilter],
    enabled: !!user && user.userType === 'admin',
  });
  
  // Booking status mutation
  const statusMutation = useMutation({
    mutationFn: async ({ bookingId, status }: { bookingId: number, status: string }) => {
      return await apiRequest("PUT", `/api/admin/bookings/${bookingId}/status`, { status });
    },
    onSuccess: () => {
      toast({
        title: bookingAction === "confirm" ? "Booking Confirmed" : "Booking Cancelled",
        description: bookingAction === "confirm" 
          ? "The booking has been confirmed." 
          : "The booking has been cancelled.",
      });
      queryClient.invalidateQueries({ queryKey: ['/api/admin/bookings'] });
      setShowActionDialog(false);
      setSelectedBooking(null);
    },
    onError: (error: Error) => {
      toast({
        title: "Error",
        description: error.message,
        variant: "destructive",
      });
    }
  });
  
  const bookings = bookingsData || [];
  
  // Filter bookings based on search and status filter
  const filteredBookings = bookings.filter((booking: Booking) => {
    const matchesSearch = 
      searchQuery === "" || 
      booking.eventType.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (booking.vendorName && booking.vendorName.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (booking.clientName && booking.clientName.toLowerCase().includes(searchQuery.toLowerCase()));
      
    const matchesStatus = statusFilter === "all" || booking.status === statusFilter;
    
    return matchesSearch && matchesStatus;
  });
  
  const handleBookingAction = (action: string, booking: Booking) => {
    setSelectedBooking(booking);
    
    if (action === "confirm" || action === "cancel") {
      setBookingAction(action as "confirm" | "cancel");
      setShowActionDialog(true);
    }
  };
  
  const handleConfirmAction = () => {
    if (selectedBooking) {
      statusMutation.mutate({ 
        bookingId: selectedBooking.id, 
        status: bookingAction === "confirm" ? BOOKING_STATUS.CONFIRMED : BOOKING_STATUS.CANCELLED
      });
    }
  };
  
  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      year: 'numeric', 
      month: 'short', 
      day: 'numeric' 
    });
  };
  
  const formatCurrency = (amount: number | null) => {
    if (amount === null) return "N/A";
    return `$${amount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  };
  
  return (
    <div className="bg-gray-50 min-h-screen pb-20">
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="py-6">
            <div className="flex items-center mb-4">
              <Button 
                variant="ghost" 
                className="mr-2"
                onClick={() => navigate("/admin")}
              >
                <ChevronLeft className="h-4 w-4 mr-1" />
                Back
              </Button>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">Booking Management</h1>
                <p className="text-gray-600">View and manage all platform bookings</p>
              </div>
            </div>
            
            <div className="flex flex-wrap items-center justify-between gap-4 mt-6">
              <div className="flex items-center gap-2">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                  <Input 
                    className="pl-10 w-64" 
                    placeholder="Search bookings..." 
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                  />
                </div>
                
                <Select value={statusFilter} onValueChange={setStatusFilter}>
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="Filter by status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Statuses</SelectItem>
                    <SelectItem value={BOOKING_STATUS.PENDING}>Pending</SelectItem>
                    <SelectItem value={BOOKING_STATUS.CONFIRMED}>Confirmed</SelectItem>
                    <SelectItem value={BOOKING_STATUS.COMPLETED}>Completed</SelectItem>
                    <SelectItem value={BOOKING_STATUS.CANCELLED}>Cancelled</SelectItem>
                  </SelectContent>
                </Select>
                
                <Button variant="outline" className="gap-2">
                  <Filter className="h-4 w-4" />
                  More Filters
                </Button>
              </div>
              
              <div className="flex items-center gap-2">
                <Button variant="outline" className="gap-2">
                  <Download className="h-4 w-4" />
                  Export
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white rounded-lg border border-gray-200 shadow-sm overflow-hidden">
          <div className="p-4 border-b border-gray-200">
            <Tabs defaultValue="all" className="w-full">
              <TabsList className="grid w-full max-w-lg grid-cols-5">
                <TabsTrigger value="all">All</TabsTrigger>
                <TabsTrigger value={BOOKING_STATUS.PENDING}>Pending</TabsTrigger>
                <TabsTrigger value={BOOKING_STATUS.CONFIRMED}>Confirmed</TabsTrigger>
                <TabsTrigger value={BOOKING_STATUS.COMPLETED}>Completed</TabsTrigger>
                <TabsTrigger value={BOOKING_STATUS.CANCELLED}>Cancelled</TabsTrigger>
              </TabsList>
            </Tabs>
          </div>
          
          {isLoading ? (
            <div className="p-8">
              <div className="space-y-4">
                {[1, 2, 3, 4, 5].map(i => (
                  <Skeleton key={i} className="h-12 w-full" />
                ))}
              </div>
            </div>
          ) : filteredBookings.length > 0 ? (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-12">#</TableHead>
                    <TableHead>
                      <div className="flex items-center gap-1">
                        Event Info
                        <ArrowUpDown className="h-3 w-3" />
                      </div>
                    </TableHead>
                    <TableHead>Client</TableHead>
                    <TableHead>Vendor</TableHead>
                    <TableHead>Price</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>
                      <div className="flex items-center gap-1">
                        Created
                        <ArrowUpDown className="h-3 w-3" />
                      </div>
                    </TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredBookings.map((booking: Booking, index: number) => (
                    <TableRow key={booking.id}>
                      <TableCell className="font-medium">{index + 1}</TableCell>
                      <TableCell>
                        <div>
                          <div className="font-medium capitalize">{booking.eventType}</div>
                          <div className="text-xs text-gray-500 flex items-center">
                            <CalendarIcon className="h-3 w-3 mr-1" />
                            {formatDate(booking.eventDate)}
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center">
                          <Avatar className="h-6 w-6 mr-2">
                            <AvatarFallback>
                              <User className="h-3 w-3" />
                            </AvatarFallback>
                          </Avatar>
                          <span>{booking.clientName || `Client #${booking.clientId}`}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center">
                          <Avatar className="h-6 w-6 mr-2">
                            <AvatarFallback>
                              <Store className="h-3 w-3" />
                            </AvatarFallback>
                          </Avatar>
                          <span>{booking.vendorName || `Vendor #${booking.vendorId}`}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        {formatCurrency(booking.totalPrice)}
                      </TableCell>
                      <TableCell>
                        <BookingStatusBadge status={booking.status} />
                      </TableCell>
                      <TableCell>
                        {formatDate(booking.createdAt)}
                      </TableCell>
                      <TableCell className="text-right">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                              <MoreHorizontal className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => setSelectedBooking(booking)}>
                              View Details
                            </DropdownMenuItem>
                            
                            {booking.status === BOOKING_STATUS.PENDING && (
                              <>
                                <DropdownMenuItem onClick={() => handleBookingAction("confirm", booking)}>
                                  <CheckCircle2 className="h-4 w-4 mr-2 text-green-500" />
                                  Confirm Booking
                                </DropdownMenuItem>
                                <DropdownMenuItem onClick={() => handleBookingAction("cancel", booking)}>
                                  <XCircle2 className="h-4 w-4 mr-2 text-red-500" />
                                  Cancel Booking
                                </DropdownMenuItem>
                              </>
                            )}
                            
                            {booking.status === BOOKING_STATUS.CONFIRMED && (
                              <DropdownMenuItem onClick={() => handleBookingAction("cancel", booking)}>
                                <XCircle2 className="h-4 w-4 mr-2 text-red-500" />
                                Cancel Booking
                              </DropdownMenuItem>
                            )}
                            
                            <DropdownMenuSeparator />
                            <DropdownMenuItem>
                              Contact Client
                            </DropdownMenuItem>
                            <DropdownMenuItem>
                              Contact Vendor
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          ) : (
            <div className="py-12 text-center">
              <Calendar className="h-12 w-12 mx-auto text-gray-300 mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-1">No bookings found</h3>
              <p className="text-gray-500">Try adjusting your search or filter parameters</p>
            </div>
          )}
          
          {filteredBookings.length > 0 && (
            <div className="flex items-center justify-between px-4 py-3 border-t border-gray-200">
              <div className="text-sm text-gray-500">
                Showing <span className="font-medium">{filteredBookings.length}</span> of{" "}
                <span className="font-medium">{bookings.length}</span> bookings
              </div>
              <div className="flex items-center space-x-2">
                <Button variant="outline" size="sm" disabled>
                  Previous
                </Button>
                <Button variant="outline" size="sm" disabled>
                  Next
                </Button>
              </div>
            </div>
          )}
        </div>
      </div>
      
      {/* Booking details dialog */}
      {selectedBooking && (
        <Dialog open={!!selectedBooking && !showActionDialog} onOpenChange={() => setSelectedBooking(null)}>
          <DialogContent className="max-w-3xl">
            <DialogHeader>
              <DialogTitle>Booking Details</DialogTitle>
            </DialogHeader>
            
            <div className="grid grid-cols-3 gap-6">
              <div className="col-span-1">
                <Card>
                  <CardHeader className="pb-3">
                    <CardTitle className="text-lg">Booking Summary</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div>
                      <div className="text-sm text-gray-500 mb-1">Booking ID</div>
                      <div className="font-medium">#{selectedBooking.id}</div>
                    </div>
                    <div>
                      <div className="text-sm text-gray-500 mb-1">Status</div>
                      <BookingStatusBadge status={selectedBooking.status} size="large" />
                    </div>
                    <div>
                      <div className="text-sm text-gray-500 mb-1">Created On</div>
                      <div className="font-medium">{formatDate(selectedBooking.createdAt)}</div>
                    </div>
                    <div>
                      <div className="text-sm text-gray-500 mb-1">Total Price</div>
                      <div className="font-medium text-lg text-green-600">
                        {formatCurrency(selectedBooking.totalPrice)}
                      </div>
                    </div>
                    
                    <Separator />
                    
                    {selectedBooking.status === BOOKING_STATUS.PENDING && (
                      <div className="flex gap-2 pt-2">
                        <Button 
                          className="flex-1 bg-green-600 hover:bg-green-700"
                          onClick={() => handleBookingAction("confirm", selectedBooking)}
                        >
                          <CheckCircle2 className="h-4 w-4 mr-1" />
                          Confirm
                        </Button>
                        <Button 
                          variant="outline"
                          className="flex-1 border-red-200 text-red-600 hover:bg-red-50"
                          onClick={() => handleBookingAction("cancel", selectedBooking)}
                        >
                          <XCircle2 className="h-4 w-4 mr-1" />
                          Cancel
                        </Button>
                      </div>
                    )}
                    
                    {selectedBooking.status === BOOKING_STATUS.CONFIRMED && (
                      <Button 
                        variant="outline"
                        className="w-full border-red-200 text-red-600 hover:bg-red-50"
                        onClick={() => handleBookingAction("cancel", selectedBooking)}
                      >
                        <XCircle2 className="h-4 w-4 mr-1" />
                        Cancel Booking
                      </Button>
                    )}
                  </CardContent>
                </Card>
              </div>
              
              <div className="col-span-2 space-y-4">
                <Card>
                  <CardHeader className="pb-2">
                    <CardTitle className="text-lg">Event Details</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <div className="text-sm text-gray-500 mb-1">Event Type</div>
                        <div className="font-medium capitalize">{selectedBooking.eventType}</div>
                      </div>
                      <div>
                        <div className="text-sm text-gray-500 mb-1">Event Date</div>
                        <div className="font-medium">{formatDate(selectedBooking.eventDate)}</div>
                      </div>
                    </div>
                    
                    <div>
                      <div className="text-sm text-gray-500 mb-1">Guest Count</div>
                      <div className="font-medium flex items-center">
                        <Users className="h-4 w-4 mr-1 text-gray-500" />
                        {selectedBooking.guestCount || "Not specified"}
                      </div>
                    </div>
                    
                    <div>
                      <div className="text-sm text-gray-500 mb-1">Service</div>
                      <div className="font-medium">
                        {selectedBooking.serviceName || "Custom Service"}
                        {selectedBooking.packageType && (
                          <Badge className="ml-2 bg-blue-100 text-blue-800 hover:bg-blue-100">
                            {selectedBooking.packageType} Package
                          </Badge>
                        )}
                      </div>
                    </div>
                    
                    {selectedBooking.specialRequests && (
                      <div>
                        <div className="text-sm text-gray-500 mb-1">Special Requests</div>
                        <div className="p-3 bg-gray-50 rounded-md text-gray-700 text-sm">
                          {selectedBooking.specialRequests}
                        </div>
                      </div>
                    )}
                  </CardContent>
                </Card>
                
                <div className="grid grid-cols-2 gap-4">
                  <Card>
                    <CardHeader className="pb-2">
                      <CardTitle className="text-lg">Client Information</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="flex items-center mb-4">
                        <Avatar className="h-10 w-10 mr-3">
                          <AvatarFallback>
                            <User className="h-4 w-4" />
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <div className="font-medium">
                            {selectedBooking.clientName || `Client #${selectedBooking.clientId}`}
                          </div>
                          <div className="text-xs text-gray-500">Client</div>
                        </div>
                      </div>
                      <Button 
                        variant="outline" 
                        size="sm" 
                        className="w-full"
                      >
                        <MessageSquare className="h-4 w-4 mr-1" />
                        Contact Client
                      </Button>
                    </CardContent>
                  </Card>
                  
                  <Card>
                    <CardHeader className="pb-2">
                      <CardTitle className="text-lg">Vendor Information</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="flex items-center mb-4">
                        <Avatar className="h-10 w-10 mr-3">
                          <AvatarFallback>
                            <Store className="h-4 w-4" />
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <div className="font-medium">
                            {selectedBooking.vendorName || `Vendor #${selectedBooking.vendorId}`}
                          </div>
                          <div className="text-xs text-gray-500">Vendor</div>
                        </div>
                      </div>
                      <Button 
                        variant="outline" 
                        size="sm" 
                        className="w-full"
                      >
                        <MessageSquare className="h-4 w-4 mr-1" />
                        Contact Vendor
                      </Button>
                    </CardContent>
                  </Card>
                </div>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      )}
      
      {/* Booking action confirmation dialog */}
      <Dialog open={showActionDialog} onOpenChange={setShowActionDialog}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>
              {bookingAction === "confirm" ? "Confirm Booking" : "Cancel Booking"}
            </DialogTitle>
            <DialogDescription>
              {bookingAction === "confirm" 
                ? "Are you sure you want to confirm this booking? The vendor will be notified."
                : "Are you sure you want to cancel this booking? Both the client and vendor will be notified."
              }
            </DialogDescription>
          </DialogHeader>
          
          {selectedBooking && (
            <div className="py-4">
              <div className="flex items-center justify-between p-3 border border-gray-200 rounded-md mb-3">
                <div className="flex items-center">
                  <Calendar className="h-8 w-8 text-gray-500 mr-3" />
                  <div>
                    <div className="font-medium capitalize">{selectedBooking.eventType}</div>
                    <div className="text-xs text-gray-500">{formatDate(selectedBooking.eventDate)}</div>
                  </div>
                </div>
                <div className="text-right">
                  <div className="font-medium text-green-600">
                    {formatCurrency(selectedBooking.totalPrice)}
                  </div>
                  <div className="text-xs text-gray-500">
                    {selectedBooking.vendorName}
                  </div>
                </div>
              </div>
              
              {bookingAction === "confirm" ? (
                <div className="px-3 py-2 bg-green-50 border border-green-100 rounded-md text-sm text-green-700">
                  <Info className="h-4 w-4 inline-block mr-1" />
                  The vendor will be notified to prepare for this event.
                </div>
              ) : (
                <div className="px-3 py-2 bg-red-50 border border-red-100 rounded-md text-sm text-red-700">
                  <Info className="h-4 w-4 inline-block mr-1" />
                  Both the client and vendor will be notified about this cancellation.
                </div>
              )}
            </div>
          )}
          
          <DialogFooter className="flex flex-col sm:flex-row gap-2">
            <Button 
              variant="outline" 
              className="sm:flex-1"
              onClick={() => setShowActionDialog(false)}
            >
              Go Back
            </Button>
            <Button 
              variant={bookingAction === "confirm" ? "default" : "destructive"}
              className={`sm:flex-1 ${bookingAction === "confirm" ? "bg-green-600 hover:bg-green-700" : ""}`}
              onClick={handleConfirmAction}
              disabled={statusMutation.isPending}
            >
              {statusMutation.isPending ? (
                <span>Processing...</span>
              ) : bookingAction === "confirm" ? (
                <>
                  <ClipboardCheck className="h-4 w-4 mr-1" />
                  Confirm Booking
                </>
              ) : (
                <>
                  <Trash className="h-4 w-4 mr-1" />
                  Cancel Booking
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function BookingStatusBadge({ status, size = "default" }: { status: string, size?: "default" | "large" }) {
  const getStatusConfig = () => {
    switch (status) {
      case BOOKING_STATUS.CONFIRMED:
        return {
          icon: <CheckCircle2 className={`${size === "large" ? "h-4 w-4" : "h-3 w-3"} text-green-500 mr-1`} />,
          textColor: "text-green-600",
          text: "Confirmed"
        };
      case BOOKING_STATUS.PENDING:
        return {
          icon: <Clock className={`${size === "large" ? "h-4 w-4" : "h-3 w-3"} text-yellow-500 mr-1`} />,
          textColor: "text-yellow-600",
          text: "Pending"
        };
      case BOOKING_STATUS.CANCELLED:
        return {
          icon: <XCircle2 className={`${size === "large" ? "h-4 w-4" : "h-3 w-3"} text-red-500 mr-1`} />,
          textColor: "text-red-600",
          text: "Cancelled"
        };
      case BOOKING_STATUS.COMPLETED:
        return {
          icon: <CheckCircle2 className={`${size === "large" ? "h-4 w-4" : "h-3 w-3"} text-blue-500 mr-1`} />,
          textColor: "text-blue-600",
          text: "Completed"
        };
      default:
        return {
          icon: <div className={`${size === "large" ? "h-3 w-3" : "h-2 w-2"} rounded-full bg-gray-400 mr-1`} />,
          textColor: "text-gray-600",
          text: status
        };
    }
  };
  
  const { icon, textColor, text } = getStatusConfig();
  
  return (
    <div className="flex items-center">
      {icon}
      <span className={`${size === "large" ? "text-sm" : "text-xs"} ${textColor} capitalize`}>
        {text}
      </span>
    </div>
  );
}