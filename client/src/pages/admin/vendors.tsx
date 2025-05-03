import { useEffect, useState } from "react";
import { useLocation } from "wouter";
import { useQuery, useMutation } from "@tanstack/react-query";
import { useAuth } from "@/hooks/use-auth";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { 
  ChevronLeft, Search, Filter, Store, Briefcase, Star, 
  MoreHorizontal, Download, CheckCircle, XCircle, Info,
  MapPin, Phone, Mail, Calendar, ThumbsUp, ThumbsDown,
  ArrowUpDown, Clock, CheckCircle2, Eye
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
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";

// Vendor types for typesafety
interface Vendor {
  id: number;
  userId: number;
  businessName: string;
  description: string;
  categories: string[];
  profileImage?: string;
  city?: string;
  address?: string;
  verified: boolean;
  status: string;
  createdAt: string;
  email?: string;
  phone?: string;
  reviewCount?: number;
  averageRating?: number;
}

export default function AdminVendors() {
  const { user } = useAuth();
  const [, navigate] = useLocation();
  const { toast } = useToast();
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [selectedVendor, setSelectedVendor] = useState<Vendor | null>(null);
  const [showApprovalDialog, setShowApprovalDialog] = useState(false);
  const [approvalAction, setApprovalAction] = useState<"approve" | "reject">("approve");
  
  // Redirect if not an admin
  useEffect(() => {
    if (user && user.userType !== 'admin') {
      navigate("/");
    }
  }, [user, navigate]);
  
  // Fetch vendors data
  const { data: vendorsData, isLoading } = useQuery({
    queryKey: ['/api/admin/vendors', searchQuery, statusFilter],
    enabled: !!user && user.userType === 'admin',
  });
  
  // Vendor approval mutation
  const approvalMutation = useMutation({
    mutationFn: async ({ vendorId, action }: { vendorId: number, action: string }) => {
      return await apiRequest("PUT", `/api/admin/vendors/${vendorId}/status`, { 
        status: action === "approve" ? "approved" : "rejected" 
      });
    },
    onSuccess: () => {
      toast({
        title: approvalAction === "approve" ? "Vendor Approved" : "Vendor Rejected",
        description: approvalAction === "approve" 
          ? "The vendor has been approved and can now offer services." 
          : "The vendor has been rejected and will be notified.",
      });
      queryClient.invalidateQueries({ queryKey: ['/api/admin/vendors'] });
      setShowApprovalDialog(false);
      setSelectedVendor(null);
    },
    onError: (error: Error) => {
      toast({
        title: "Error",
        description: error.message,
        variant: "destructive",
      });
    }
  });
  
  const vendors = vendorsData || [];
  
  // Filter vendors based on search and status filter
  const filteredVendors = vendors.filter((vendor: Vendor) => {
    const matchesSearch = 
      searchQuery === "" || 
      vendor.businessName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (vendor.categories && vendor.categories.some(cat => 
        cat.toLowerCase().includes(searchQuery.toLowerCase())
      ));
      
    const matchesStatus = statusFilter === "all" || vendor.status === statusFilter;
    
    return matchesSearch && matchesStatus;
  });
  
  const handleVendorAction = (action: string, vendor: Vendor) => {
    setSelectedVendor(vendor);
    
    if (action === "approve" || action === "reject") {
      setApprovalAction(action as "approve" | "reject");
      setShowApprovalDialog(true);
    }
  };
  
  const handleConfirmApproval = () => {
    if (selectedVendor) {
      approvalMutation.mutate({ 
        vendorId: selectedVendor.id, 
        action: approvalAction 
      });
    }
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
                <h1 className="text-2xl font-bold text-gray-900">Vendor Management</h1>
                <p className="text-gray-600">View and manage all platform vendors</p>
              </div>
            </div>
            
            <div className="flex flex-wrap items-center justify-between gap-4 mt-6">
              <div className="flex items-center gap-2">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                  <Input 
                    className="pl-10 w-64" 
                    placeholder="Search vendors..." 
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
                    <SelectItem value="pending">Pending</SelectItem>
                    <SelectItem value="approved">Approved</SelectItem>
                    <SelectItem value="rejected">Rejected</SelectItem>
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
              <TabsList className="grid w-full max-w-md grid-cols-4">
                <TabsTrigger value="all">All Vendors</TabsTrigger>
                <TabsTrigger value="pending">Pending</TabsTrigger>
                <TabsTrigger value="approved">Approved</TabsTrigger>
                <TabsTrigger value="rejected">Rejected</TabsTrigger>
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
          ) : filteredVendors.length > 0 ? (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-12">#</TableHead>
                    <TableHead>
                      <div className="flex items-center gap-1">
                        Business
                        <ArrowUpDown className="h-3 w-3" />
                      </div>
                    </TableHead>
                    <TableHead>Categories</TableHead>
                    <TableHead>Rating</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Joined</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredVendors.map((vendor: Vendor, index: number) => (
                    <TableRow key={vendor.id}>
                      <TableCell className="font-medium">{index + 1}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-3">
                          <Avatar className="h-8 w-8">
                            <AvatarImage src={vendor.profileImage} />
                            <AvatarFallback>
                              <Store className="h-4 w-4 text-gray-500" />
                            </AvatarFallback>
                          </Avatar>
                          <div>
                            <div className="font-medium">{vendor.businessName}</div>
                            <div className="text-xs text-gray-500">{vendor.city || "No location"}</div>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-wrap gap-1">
                          {vendor.categories && vendor.categories.map((category, i) => (
                            <Badge 
                              key={i} 
                              variant="secondary" 
                              className="bg-gray-100 text-gray-800 text-xs"
                            >
                              {category}
                            </Badge>
                          ))}
                        </div>
                      </TableCell>
                      <TableCell>
                        {vendor.averageRating ? (
                          <div className="flex items-center">
                            <Star className="h-4 w-4 text-yellow-500 fill-yellow-500 mr-1" />
                            <span>{vendor.averageRating.toFixed(1)}</span>
                            <span className="text-gray-500 text-xs ml-1">
                              ({vendor.reviewCount})
                            </span>
                          </div>
                        ) : (
                          <span className="text-gray-500 text-sm">No ratings</span>
                        )}
                      </TableCell>
                      <TableCell>
                        <VendorStatusBadge status={vendor.status} />
                      </TableCell>
                      <TableCell>
                        {new Date(vendor.createdAt).toLocaleDateString()}
                      </TableCell>
                      <TableCell className="text-right">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                              <MoreHorizontal className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => setSelectedVendor(vendor)}>
                              <Eye className="h-4 w-4 mr-2" />
                              View Details
                            </DropdownMenuItem>
                            
                            {vendor.status === 'pending' && (
                              <>
                                <DropdownMenuItem onClick={() => handleVendorAction("approve", vendor)}>
                                  <CheckCircle className="h-4 w-4 mr-2 text-green-500" />
                                  Approve Vendor
                                </DropdownMenuItem>
                                <DropdownMenuItem onClick={() => handleVendorAction("reject", vendor)}>
                                  <XCircle className="h-4 w-4 mr-2 text-red-500" />
                                  Reject Vendor
                                </DropdownMenuItem>
                              </>
                            )}
                            
                            {vendor.status === 'approved' && (
                              <DropdownMenuItem>
                                <XCircle className="h-4 w-4 mr-2 text-yellow-500" />
                                Suspend Vendor
                              </DropdownMenuItem>
                            )}
                            
                            {vendor.status === 'rejected' && (
                              <DropdownMenuItem onClick={() => handleVendorAction("approve", vendor)}>
                                <CheckCircle className="h-4 w-4 mr-2 text-green-500" />
                                Approve Vendor
                              </DropdownMenuItem>
                            )}
                            
                            <DropdownMenuSeparator />
                            <DropdownMenuItem>
                              Edit Vendor
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
              <Store className="h-12 w-12 mx-auto text-gray-300 mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-1">No vendors found</h3>
              <p className="text-gray-500">Try adjusting your search or filter parameters</p>
            </div>
          )}
          
          {filteredVendors.length > 0 && (
            <div className="flex items-center justify-between px-4 py-3 border-t border-gray-200">
              <div className="text-sm text-gray-500">
                Showing <span className="font-medium">{filteredVendors.length}</span> of{" "}
                <span className="font-medium">{vendors.length}</span> vendors
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
      
      {/* Vendor details dialog */}
      {selectedVendor && (
        <Dialog open={!!selectedVendor && !showApprovalDialog} onOpenChange={() => setSelectedVendor(null)}>
          <DialogContent className="max-w-3xl">
            <DialogHeader>
              <DialogTitle>Vendor Details</DialogTitle>
            </DialogHeader>
            
            <div className="grid grid-cols-3 gap-6">
              <div className="col-span-1">
                <Card>
                  <CardHeader className="pb-3">
                    <div className="flex justify-center mb-2">
                      <Avatar className="h-20 w-20">
                        <AvatarImage src={selectedVendor.profileImage} />
                        <AvatarFallback className="text-2xl">
                          <Store className="h-8 w-8 text-gray-500" />
                        </AvatarFallback>
                      </Avatar>
                    </div>
                    <CardTitle className="text-center">{selectedVendor.businessName}</CardTitle>
                    <div className="flex justify-center">
                      <VendorStatusBadge status={selectedVendor.status} />
                    </div>
                  </CardHeader>
                  <CardContent className="pb-2">
                    <div className="space-y-3">
                      <div className="flex items-center">
                        <MapPin className="h-4 w-4 text-gray-500 mr-2" />
                        <span className="text-sm">
                          {selectedVendor.address && selectedVendor.city 
                            ? `${selectedVendor.address}, ${selectedVendor.city}`
                            : "No address provided"}
                        </span>
                      </div>
                      <div className="flex items-center">
                        <Mail className="h-4 w-4 text-gray-500 mr-2" />
                        <span className="text-sm">{selectedVendor.email || "No email provided"}</span>
                      </div>
                      <div className="flex items-center">
                        <Phone className="h-4 w-4 text-gray-500 mr-2" />
                        <span className="text-sm">{selectedVendor.phone || "No phone provided"}</span>
                      </div>
                      <div className="flex items-center">
                        <Calendar className="h-4 w-4 text-gray-500 mr-2" />
                        <span className="text-sm">
                          Joined {new Date(selectedVendor.createdAt).toLocaleDateString()}
                        </span>
                      </div>
                    </div>
                  </CardContent>
                  <Separator />
                  <CardFooter className="pt-4">
                    {selectedVendor.status === 'pending' && (
                      <div className="w-full space-y-2">
                        <Button 
                          className="w-full bg-green-600 hover:bg-green-700"
                          onClick={() => handleVendorAction("approve", selectedVendor)}
                        >
                          <CheckCircle className="h-4 w-4 mr-2" />
                          Approve Vendor
                        </Button>
                        <Button 
                          variant="outline" 
                          className="w-full border-red-300 text-red-600 hover:bg-red-50"
                          onClick={() => handleVendorAction("reject", selectedVendor)}
                        >
                          <XCircle className="h-4 w-4 mr-2" />
                          Reject Vendor
                        </Button>
                      </div>
                    )}
                    
                    {selectedVendor.status === 'approved' && (
                      <Button 
                        variant="outline" 
                        className="w-full border-yellow-300 text-yellow-600 hover:bg-yellow-50"
                      >
                        <XCircle className="h-4 w-4 mr-2" />
                        Suspend Vendor
                      </Button>
                    )}
                    
                    {selectedVendor.status === 'rejected' && (
                      <Button 
                        className="w-full bg-green-600 hover:bg-green-700"
                        onClick={() => handleVendorAction("approve", selectedVendor)}
                      >
                        <CheckCircle className="h-4 w-4 mr-2" />
                        Approve Vendor
                      </Button>
                    )}
                  </CardFooter>
                </Card>
              </div>
              
              <div className="col-span-2 space-y-4">
                <Card>
                  <CardHeader className="pb-2">
                    <CardTitle className="text-lg">Business Description</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <p className="text-gray-700">
                      {selectedVendor.description || "No description provided."}
                    </p>
                  </CardContent>
                </Card>
                
                <Card>
                  <CardHeader className="pb-2">
                    <CardTitle className="text-lg">Categories</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="flex flex-wrap gap-2">
                      {selectedVendor.categories && selectedVendor.categories.length > 0 ? (
                        selectedVendor.categories.map((category, i) => (
                          <Badge 
                            key={i} 
                            className="bg-blue-100 hover:bg-blue-100 text-blue-800 border-blue-200"
                          >
                            {category}
                          </Badge>
                        ))
                      ) : (
                        <p className="text-gray-500">No categories specified</p>
                      )}
                    </div>
                  </CardContent>
                </Card>
                
                <Card>
                  <CardHeader className="pb-2">
                    <CardTitle className="text-lg">Statistics</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="grid grid-cols-3 gap-4">
                      <div className="bg-gray-50 p-3 rounded-lg">
                        <div className="text-sm text-gray-500 mb-1">Total Bookings</div>
                        <div className="text-xl font-bold">25</div>
                      </div>
                      <div className="bg-gray-50 p-3 rounded-lg">
                        <div className="text-sm text-gray-500 mb-1">Rating</div>
                        <div className="text-xl font-bold flex items-center">
                          {selectedVendor.averageRating ? (
                            <>
                              <Star className="h-5 w-5 text-yellow-500 fill-yellow-500 mr-1" />
                              {selectedVendor.averageRating.toFixed(1)}
                              <span className="text-sm text-gray-500 ml-1">
                                ({selectedVendor.reviewCount})
                              </span>
                            </>
                          ) : (
                            "N/A"
                          )}
                        </div>
                      </div>
                      <div className="bg-gray-50 p-3 rounded-lg">
                        <div className="text-sm text-gray-500 mb-1">Services</div>
                        <div className="text-xl font-bold">8</div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      )}
      
      {/* Approval confirmation dialog */}
      <Dialog open={showApprovalDialog} onOpenChange={setShowApprovalDialog}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>
              {approvalAction === "approve" ? "Approve Vendor" : "Reject Vendor"}
            </DialogTitle>
            <DialogDescription>
              {approvalAction === "approve" 
                ? "Are you sure you want to approve this vendor? They will be able to offer services on the platform."
                : "Are you sure you want to reject this vendor? They will not be able to offer services on the platform."
              }
            </DialogDescription>
          </DialogHeader>
          
          {selectedVendor && (
            <div className="py-4">
              <div className="flex items-center p-3 border border-gray-200 rounded-md mb-3">
                <Avatar className="h-10 w-10 mr-3">
                  <AvatarImage src={selectedVendor.profileImage} />
                  <AvatarFallback>
                    <Store className="h-4 w-4 text-gray-500" />
                  </AvatarFallback>
                </Avatar>
                <div>
                  <div className="font-medium">{selectedVendor.businessName}</div>
                  <div className="text-xs text-gray-500">
                    {selectedVendor.categories?.join(", ")}
                  </div>
                </div>
              </div>
              
              {approvalAction === "approve" ? (
                <div className="px-3 py-2 bg-green-50 border border-green-100 rounded-md text-sm text-green-700">
                  <Info className="h-4 w-4 inline-block mr-1" />
                  This vendor will be notified that they've been approved and can start offering services.
                </div>
              ) : (
                <div className="px-3 py-2 bg-red-50 border border-red-100 rounded-md text-sm text-red-700">
                  <Info className="h-4 w-4 inline-block mr-1" />
                  This vendor will be notified that they've been rejected and cannot offer services at this time.
                </div>
              )}
            </div>
          )}
          
          <DialogFooter className="flex flex-col sm:flex-row gap-2">
            <Button 
              variant="outline" 
              className="sm:flex-1"
              onClick={() => setShowApprovalDialog(false)}
            >
              Cancel
            </Button>
            <Button 
              variant={approvalAction === "approve" ? "default" : "destructive"}
              className={`sm:flex-1 ${approvalAction === "approve" ? "bg-green-600 hover:bg-green-700" : ""}`}
              onClick={handleConfirmApproval}
              disabled={approvalMutation.isPending}
            >
              {approvalMutation.isPending ? (
                <span>Processing...</span>
              ) : approvalAction === "approve" ? (
                <>
                  <ThumbsUp className="h-4 w-4 mr-1" />
                  Approve Vendor
                </>
              ) : (
                <>
                  <ThumbsDown className="h-4 w-4 mr-1" />
                  Reject Vendor
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function VendorStatusBadge({ status }: { status: string }) {
  switch (status) {
    case 'approved':
      return (
        <div className="flex items-center">
          <CheckCircle2 className="h-3 w-3 text-green-500 mr-1" />
          <span className="text-xs text-green-600 capitalize">Approved</span>
        </div>
      );
    case 'pending':
      return (
        <div className="flex items-center">
          <Clock className="h-3 w-3 text-yellow-500 mr-1" />
          <span className="text-xs text-yellow-600 capitalize">Pending</span>
        </div>
      );
    case 'rejected':
      return (
        <div className="flex items-center">
          <XCircle className="h-3 w-3 text-red-500 mr-1" />
          <span className="text-xs text-red-600 capitalize">Rejected</span>
        </div>
      );
    default:
      return (
        <div className="flex items-center">
          <div className="h-2 w-2 rounded-full bg-gray-400 mr-1" />
          <span className="text-xs text-gray-600 capitalize">{status}</span>
        </div>
      );
  }
}