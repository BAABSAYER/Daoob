import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { AdminLayout } from "@/components/admin-layout";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { 
  Dialog, 
  DialogContent, 
  DialogDescription, 
  DialogFooter, 
  DialogHeader, 
  DialogTitle 
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Booking, Vendor, BOOKING_STATUS, EVENT_TYPES } from "@shared/schema";
import { useToast } from "@/hooks/use-toast";
import { Link } from "wouter";
import { DollarSign, Calendar, FileText } from "lucide-react";

// Extend Booking type to include vendor info
type BookingWithDetails = Booking & {
  vendor?: Vendor;
  clientName?: string;
};

export default function AdminBookings() {
  const { toast } = useToast();
  const [selectedBooking, setSelectedBooking] = useState<BookingWithDetails | null>(null);
  const [isViewingDetails, setIsViewingDetails] = useState(false);
  const [isCreatingQuotation, setIsCreatingQuotation] = useState(false);
  const [statusFilter, setStatusFilter] = useState<string | null>(null);
  
  // Quotation form state
  const [quotationForm, setQuotationForm] = useState({
    totalPrice: "",
    quotationNotes: "",
    quotationValidUntil: "",
    quotationDetails: {
      items: [{ service: "", price: "", description: "" }],
      breakdown: ""
    }
  });

  // Fetch all bookings
  const { data: bookings = [], isLoading: isLoadingBookings } = useQuery<BookingWithDetails[]>({
    queryKey: ["/api/admin/bookings"],
    enabled: true,
  });

  // Update booking status mutation
  const updateBookingStatusMutation = useMutation({
    mutationFn: async ({ id, status }: { id: number; status: string }) => {
      const res = await apiRequest("PATCH", `/api/bookings/${id}`, { status });
      return await res.json();
    },
    onSuccess: () => {
      toast({
        title: "Booking updated",
        description: "The booking status has been successfully updated",
      });
      setIsViewingDetails(false);
      queryClient.invalidateQueries({ queryKey: ["/api/admin/bookings"] });
    },
    onError: (error) => {
      toast({
        title: "Failed to update booking",
        description: error.message,
        variant: "destructive",
      });
    },
  });

  // Create quotation mutation
  const createQuotationMutation = useMutation({
    mutationFn: async ({ id, quotationData }: { id: number; quotationData: any }) => {
      const res = await apiRequest("PATCH", `/api/bookings/${id}`, {
        ...quotationData,
        status: BOOKING_STATUS.QUOTATION_SENT
      });
      return await res.json();
    },
    onSuccess: () => {
      toast({
        title: "Quotation created",
        description: "The quotation has been sent to the client",
      });
      setIsCreatingQuotation(false);
      setSelectedBooking(null);
      resetQuotationForm();
      queryClient.invalidateQueries({ queryKey: ["/api/admin/bookings"] });
    },
    onError: (error) => {
      toast({
        title: "Failed to create quotation",
        description: error.message,
        variant: "destructive",
      });
    },
  });

  const getPendingCount = () => {
    return bookings.filter(b => b.status === BOOKING_STATUS.PENDING).length;
  };

  const getConfirmedCount = () => {
    return bookings.filter(b => b.status === BOOKING_STATUS.CONFIRMED).length;
  };

  const getCanceledCount = () => {
    return bookings.filter(b => b.status === BOOKING_STATUS.CANCELLED).length;
  };

  const resetQuotationForm = () => {
    setQuotationForm({
      totalPrice: "",
      quotationNotes: "",
      quotationValidUntil: "",
      quotationDetails: {
        items: [{ service: "", price: "", description: "" }],
        breakdown: ""
      }
    });
  };

  const handleStatusChange = (status: string) => {
    if (selectedBooking) {
      updateBookingStatusMutation.mutate({
        id: selectedBooking.id,
        status,
      });
    }
  };

  const handleCreateQuotation = (booking: BookingWithDetails) => {
    setSelectedBooking(booking);
    setIsCreatingQuotation(true);
    resetQuotationForm();
  };

  const handleSubmitQuotation = () => {
    if (!selectedBooking) return;

    const quotationData = {
      totalPrice: parseFloat(quotationForm.totalPrice),
      quotationNotes: quotationForm.quotationNotes,
      quotationValidUntil: quotationForm.quotationValidUntil ? new Date(quotationForm.quotationValidUntil) : null,
      quotationDetails: quotationForm.quotationDetails
    };

    createQuotationMutation.mutate({
      id: selectedBooking.id,
      quotationData
    });
  };

  const addQuotationItem = () => {
    setQuotationForm(prev => ({
      ...prev,
      quotationDetails: {
        ...prev.quotationDetails,
        items: [...prev.quotationDetails.items, { service: "", price: "", description: "" }]
      }
    }));
  };

  const removeQuotationItem = (index: number) => {
    setQuotationForm(prev => ({
      ...prev,
      quotationDetails: {
        ...prev.quotationDetails,
        items: prev.quotationDetails.items.filter((_, i) => i !== index)
      }
    }));
  };

  const updateQuotationItem = (index: number, field: string, value: string) => {
    setQuotationForm(prev => ({
      ...prev,
      quotationDetails: {
        ...prev.quotationDetails,
        items: prev.quotationDetails.items.map((item, i) => 
          i === index ? { ...item, [field]: value } : item
        )
      }
    }));
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case BOOKING_STATUS.PENDING:
        return <Badge variant="outline" className="bg-yellow-100 text-yellow-800 border-yellow-300">Pending</Badge>;
      case BOOKING_STATUS.CONFIRMED:
        return <Badge variant="outline" className="bg-green-100 text-green-800 border-green-300">Confirmed</Badge>;
      case BOOKING_STATUS.CANCELLED:
        return <Badge variant="outline" className="bg-red-100 text-red-800 border-red-300">Canceled</Badge>;
      case BOOKING_STATUS.COMPLETED:
        return <Badge variant="outline" className="bg-blue-100 text-blue-800 border-blue-300">Completed</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  const filteredBookings = statusFilter 
    ? bookings.filter(booking => booking.status === statusFilter) 
    : bookings;

  return (
    <AdminLayout title="Booking Management">
      <div className="space-y-6">
        {/* Stats Cards */}
        <div className="grid gap-4 md:grid-cols-3">
          <Card onClick={() => setStatusFilter(BOOKING_STATUS.PENDING)} 
                className={`cursor-pointer ${statusFilter === BOOKING_STATUS.PENDING ? 'border-primary' : ''}`}>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">Pending Bookings</CardTitle>
            </CardHeader>
            <CardContent>
              {isLoadingBookings ? (
                <Skeleton className="h-8 w-12" />
              ) : (
                <div className="text-2xl font-bold">{getPendingCount()}</div>
              )}
            </CardContent>
          </Card>
          
          <Card onClick={() => setStatusFilter(BOOKING_STATUS.CONFIRMED)} 
                className={`cursor-pointer ${statusFilter === BOOKING_STATUS.CONFIRMED ? 'border-primary' : ''}`}>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">Confirmed Bookings</CardTitle>
            </CardHeader>
            <CardContent>
              {isLoadingBookings ? (
                <Skeleton className="h-8 w-12" />
              ) : (
                <div className="text-2xl font-bold">{getConfirmedCount()}</div>
              )}
            </CardContent>
          </Card>
          
          <Card onClick={() => setStatusFilter(BOOKING_STATUS.CANCELLED)} 
                className={`cursor-pointer ${statusFilter === BOOKING_STATUS.CANCELLED ? 'border-primary' : ''}`}>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">Canceled Bookings</CardTitle>
            </CardHeader>
            <CardContent>
              {isLoadingBookings ? (
                <Skeleton className="h-8 w-12" />
              ) : (
                <div className="text-2xl font-bold">{getCanceledCount()}</div>
              )}
            </CardContent>
          </Card>
        </div>

        {statusFilter && (
          <div className="flex items-center">
            <Button variant="outline" size="sm" onClick={() => setStatusFilter(null)}>
              Clear Filter
            </Button>
            <span className="ml-2 text-sm text-muted-foreground">
              Showing {statusFilter.toLowerCase()} bookings
            </span>
          </div>
        )}

        {/* Bookings Table */}
        <div className="rounded-md border">
          {isLoadingBookings ? (
            <div className="p-4 space-y-4">
              <Skeleton className="h-4 w-full" />
              <Skeleton className="h-10 w-full" />
              <Skeleton className="h-10 w-full" />
              <Skeleton className="h-10 w-full" />
            </div>
          ) : filteredBookings.length > 0 ? (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>ID</TableHead>
                  <TableHead>Client</TableHead>
                  <TableHead>Vendor</TableHead>
                  <TableHead>Event Type</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredBookings.map((booking) => (
                  <TableRow key={booking.id} id={`booking-${booking.id}`}>
                    <TableCell>#{booking.id}</TableCell>
                    <TableCell>{booking.clientName || `Client #${booking.clientId}`}</TableCell>
                    <TableCell>{booking.vendor?.businessName || `Vendor #${booking.vendorId}`}</TableCell>
                    <TableCell>{EVENT_TYPES[booking.eventTypeId as keyof typeof EVENT_TYPES] || `Event Type #${booking.eventTypeId}`}</TableCell>
                    <TableCell>{new Date(booking.eventDate).toLocaleDateString()}</TableCell>
                    <TableCell>{getStatusBadge(booking.status)}</TableCell>
                    <TableCell>
                      <div className="flex gap-2">
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={() => {
                            setSelectedBooking(booking);
                            setIsViewingDetails(true);
                          }}
                        >
                          View Details
                        </Button>
                        {booking.status === BOOKING_STATUS.PENDING && (
                          <Button 
                            variant="default" 
                            size="sm"
                            onClick={() => handleCreateQuotation(booking)}
                            className="bg-blue-600 hover:bg-blue-700"
                          >
                            <DollarSign className="h-3 w-3 mr-1" />
                            Create Quote
                          </Button>
                        )}
                        {booking.status === BOOKING_STATUS.QUOTATION_SENT && booking.totalPrice && (
                          <Button 
                            variant="secondary" 
                            size="sm"
                            onClick={() => {
                              setSelectedBooking(booking);
                              setIsViewingDetails(true);
                            }}
                          >
                            <FileText className="h-3 w-3 mr-1" />
                            View Quote
                          </Button>
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          ) : (
            <div className="p-8 text-center">
              <h3 className="text-lg font-medium">No bookings found</h3>
              <p className="text-muted-foreground mt-1">
                {statusFilter 
                  ? `There are no ${statusFilter.toLowerCase()} bookings` 
                  : "No bookings have been made yet"}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Booking Details Dialog */}
      <Dialog open={isViewingDetails} onOpenChange={setIsViewingDetails}>
        <DialogContent className="sm:max-w-[600px]">
          <DialogHeader>
            <DialogTitle>Booking Details</DialogTitle>
            <DialogDescription>
              {selectedBooking ? `Booking #${selectedBooking.id} - ${EVENT_TYPES[selectedBooking.eventTypeId as keyof typeof EVENT_TYPES] || `Event Type #${selectedBooking.eventTypeId}`} Event` : 'View and manage booking details'}
            </DialogDescription>
          </DialogHeader>
          
          {selectedBooking && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <h4 className="text-sm font-medium mb-1">Client</h4>
                  <p>{selectedBooking.clientName || `Client #${selectedBooking.clientId}`}</p>
                  <Link href={`/admin/chat/${selectedBooking.clientId}`}>
                    <a className="text-primary text-sm hover:underline">
                      Chat with client
                    </a>
                  </Link>
                </div>
                <div>
                  <h4 className="text-sm font-medium mb-1">Vendor</h4>
                  <p>{selectedBooking.vendor?.businessName || `Vendor #${selectedBooking.vendorId}`}</p>
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <h4 className="text-sm font-medium mb-1">Event Date</h4>
                  <p>{new Date(selectedBooking.eventDate).toLocaleDateString()}</p>
                </div>
                <div>
                  <h4 className="text-sm font-medium mb-1">Guest Count</h4>
                  <p>{selectedBooking.guestCount}</p>
                </div>
              </div>
              
              {selectedBooking.specialRequests && (
                <div>
                  <h4 className="text-sm font-medium mb-1">Special Requests</h4>
                  <p className="text-sm">{selectedBooking.specialRequests}</p>
                </div>
              )}
              
              <div>
                <h4 className="text-sm font-medium mb-1">Status</h4>
                <Select
                  value={selectedBooking.status}
                  onValueChange={handleStatusChange}
                  disabled={updateBookingStatusMutation.isPending}
                >
                  <SelectTrigger className="w-full">
                    <SelectValue placeholder="Select status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value={BOOKING_STATUS.PENDING}>Pending</SelectItem>
                    <SelectItem value={BOOKING_STATUS.CONFIRMED}>Confirm</SelectItem>
                    <SelectItem value={BOOKING_STATUS.CANCELLED}>Cancel</SelectItem>
                    <SelectItem value={BOOKING_STATUS.COMPLETED}>Complete</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          )}
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsViewingDetails(false)}>
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Quotation Creation Dialog */}
      <Dialog open={isCreatingQuotation} onOpenChange={setIsCreatingQuotation}>
        <DialogContent className="sm:max-w-[700px] max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Create Quotation</DialogTitle>
            <DialogDescription>
              {selectedBooking ? `Creating quote for Booking #${selectedBooking.id}` : 'Create a detailed quotation for the booking'}
            </DialogDescription>
          </DialogHeader>
          
          {selectedBooking && (
            <div className="space-y-6">
              {/* Booking Summary */}
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Booking Summary</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <strong>Client:</strong> {selectedBooking.clientName || `Client #${selectedBooking.clientId}`}
                    </div>
                    <div>
                      <strong>Event Date:</strong> {new Date(selectedBooking.eventDate).toLocaleDateString()}
                    </div>
                    <div>
                      <strong>Guest Count:</strong> {selectedBooking.guestCount}
                    </div>
                    <div>
                      <strong>Event Type:</strong> {EVENT_TYPES[selectedBooking.eventTypeId as keyof typeof EVENT_TYPES] || `Event Type #${selectedBooking.eventTypeId}`}
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Quotation Items */}
              <div>
                <div className="flex items-center justify-between mb-4">
                  <Label className="text-base font-medium">Quotation Items</Label>
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={addQuotationItem}
                  >
                    Add Item
                  </Button>
                </div>
                
                <div className="space-y-3">
                  {quotationForm.quotationDetails.items.map((item, index) => (
                    <Card key={index}>
                      <CardContent className="p-4">
                        <div className="grid grid-cols-12 gap-3 items-end">
                          <div className="col-span-4">
                            <Label htmlFor={`service-${index}`}>Service</Label>
                            <Input
                              id={`service-${index}`}
                              placeholder="Service name"
                              value={item.service}
                              onChange={(e) => updateQuotationItem(index, 'service', e.target.value)}
                            />
                          </div>
                          <div className="col-span-2">
                            <Label htmlFor={`price-${index}`}>Price ($)</Label>
                            <Input
                              id={`price-${index}`}
                              type="number"
                              placeholder="0.00"
                              value={item.price}
                              onChange={(e) => updateQuotationItem(index, 'price', e.target.value)}
                            />
                          </div>
                          <div className="col-span-5">
                            <Label htmlFor={`description-${index}`}>Description</Label>
                            <Input
                              id={`description-${index}`}
                              placeholder="Service description"
                              value={item.description}
                              onChange={(e) => updateQuotationItem(index, 'description', e.target.value)}
                            />
                          </div>
                          <div className="col-span-1">
                            {quotationForm.quotationDetails.items.length > 1 && (
                              <Button
                                type="button"
                                variant="outline"
                                size="sm"
                                onClick={() => removeQuotationItem(index)}
                              >
                                ×
                              </Button>
                            )}
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              </div>

              {/* Total Price */}
              <div>
                <Label htmlFor="totalPrice">Total Price ($)</Label>
                <Input
                  id="totalPrice"
                  type="number"
                  placeholder="0.00"
                  value={quotationForm.totalPrice}
                  onChange={(e) => setQuotationForm(prev => ({ ...prev, totalPrice: e.target.value }))}
                  className="text-lg font-semibold"
                />
              </div>

              {/* Quotation Notes */}
              <div>
                <Label htmlFor="quotationNotes">Additional Notes</Label>
                <Textarea
                  id="quotationNotes"
                  placeholder="Any additional terms, conditions, or notes for the client..."
                  value={quotationForm.quotationNotes}
                  onChange={(e) => setQuotationForm(prev => ({ ...prev, quotationNotes: e.target.value }))}
                  rows={4}
                />
              </div>

              {/* Valid Until */}
              <div>
                <Label htmlFor="quotationValidUntil">Quote Valid Until</Label>
                <Input
                  id="quotationValidUntil"
                  type="date"
                  value={quotationForm.quotationValidUntil}
                  onChange={(e) => setQuotationForm(prev => ({ ...prev, quotationValidUntil: e.target.value }))}
                />
              </div>
            </div>
          )}
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsCreatingQuotation(false)}>
              Cancel
            </Button>
            <Button 
              onClick={handleSubmitQuotation}
              disabled={createQuotationMutation.isPending || !quotationForm.totalPrice}
            >
              {createQuotationMutation.isPending ? 'Creating...' : 'Send Quotation'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </AdminLayout>
  );
}