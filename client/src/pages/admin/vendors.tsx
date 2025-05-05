import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { AdminLayout } from "@/components/admin-layout";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/hooks/use-toast";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { Star, Plus, Edit, Trash2, Search, Filter } from "lucide-react";
import { SERVICE_CATEGORIES } from "@shared/schema";
import { apiRequest, queryClient } from "@/lib/queryClient";

export default function AdminVendors() {
  const { toast } = useToast();
  const [searchTerm, setSearchTerm] = useState("");
  const [categoryFilter, setCategoryFilter] = useState<string | null>(null);
  const [isAddingVendor, setIsAddingVendor] = useState(false);
  const [isViewingVendor, setIsViewingVendor] = useState(false);
  const [selectedVendor, setSelectedVendor] = useState<any>(null);
  const [activeView, setActiveView] = useState<'vendors' | 'services'>('vendors');
  
  // Fetch vendors
  const { data: vendors = [], isLoading: isLoadingVendors } = useQuery({
    queryKey: ["/api/vendors"],
  });
  
  // Create vendor mutation
  const createVendorMutation = useMutation({
    mutationFn: async (vendorData: any) => {
      const res = await apiRequest("POST", "/api/vendors", vendorData);
      return await res.json();
    },
    onSuccess: () => {
      toast({
        title: "Vendor created",
        description: "The vendor has been created successfully",
      });
      setIsAddingVendor(false);
      queryClient.invalidateQueries({ queryKey: ["/api/vendors"] });
    },
    onError: (error) => {
      toast({
        title: "Failed to create vendor",
        description: error.message,
        variant: "destructive",
      });
    },
  });
  
  // Delete vendor mutation
  const deleteVendorMutation = useMutation({
    mutationFn: async (vendorId: number) => {
      const res = await apiRequest("DELETE", `/api/vendors/${vendorId}`);
      return await res.json();
    },
    onSuccess: () => {
      toast({
        title: "Vendor deleted",
        description: "The vendor has been deleted successfully",
      });
      queryClient.invalidateQueries({ queryKey: ["/api/vendors"] });
    },
    onError: (error) => {
      toast({
        title: "Failed to delete vendor",
        description: error.message,
        variant: "destructive",
      });
    },
  });
  
  const handleAddVendor = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    
    const vendorData = {
      businessName: formData.get("businessName") as string,
      category: formData.get("category") as string,
      description: formData.get("description") as string,
      email: formData.get("email") as string,
      phone: formData.get("phone") as string,
      address: formData.get("address") as string,
      city: formData.get("city") as string,
      priceRange: formData.get("priceRange") as string,
    };
    
    createVendorMutation.mutate(vendorData);
  };
  
  const handleViewVendor = (vendor: any) => {
    setSelectedVendor(vendor);
    setIsViewingVendor(true);
  };
  
  const handleDeleteVendor = (vendorId: number) => {
    if (window.confirm("Are you sure you want to delete this vendor?")) {
      deleteVendorMutation.mutate(vendorId);
    }
  };
  
  const filteredVendors = vendors.filter((vendor: any) => {
    const matchesSearch = !searchTerm || 
      vendor.businessName.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesCategory = !categoryFilter || vendor.category === categoryFilter;
    
    return matchesSearch && matchesCategory;
  });

  return (
    <AdminLayout title="Vendor Management">
      <div className="space-y-6">
        <Tabs value={activeView} onValueChange={(value) => setActiveView(value as 'vendors' | 'services')} className="space-y-4">
          <div className="flex items-center justify-between">
            <TabsList>
              <TabsTrigger value="vendors">Vendors</TabsTrigger>
              <TabsTrigger value="services">Services</TabsTrigger>
            </TabsList>
          </div>
          
          <TabsContent value="vendors" className="space-y-4">
            {/* Search & Filter */}
            <div className="flex flex-col sm:flex-row gap-4 items-center justify-between">
              <div className="relative w-full sm:w-72">
                <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search vendors..."
                  className="pl-8"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>
              
              <div className="flex gap-2 items-center">
                <Select 
                  value={categoryFilter || ""} 
                  onValueChange={(value) => setCategoryFilter(value || null)}
                >
                  <SelectTrigger className="w-[180px]">
                    <SelectValue placeholder="Filter by category" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">All Categories</SelectItem>
                    {Object.entries(SERVICE_CATEGORIES).map(([key, value]) => (
                      <SelectItem key={key} value={key}>{value}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                
                <Dialog open={isAddingVendor} onOpenChange={setIsAddingVendor}>
                  <DialogTrigger asChild>
                    <Button>
                      <Plus className="h-4 w-4 mr-2" />
                      Add Vendor
                    </Button>
                  </DialogTrigger>
                  <DialogContent className="sm:max-w-[550px]">
                    <DialogHeader>
                      <DialogTitle>Add New Vendor</DialogTitle>
                      <DialogDescription>
                        Create a new vendor account in the system
                      </DialogDescription>
                    </DialogHeader>
                    
                    <form onSubmit={handleAddVendor} className="space-y-4 pt-4">
                      <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                          <Label htmlFor="businessName">Business Name</Label>
                          <Input id="businessName" name="businessName" required />
                        </div>
                        
                        <div className="space-y-2">
                          <Label htmlFor="category">Category</Label>
                          <Select name="category" required>
                            <SelectTrigger id="category">
                              <SelectValue placeholder="Select category" />
                            </SelectTrigger>
                            <SelectContent>
                              {Object.entries(SERVICE_CATEGORIES).map(([key, value]) => (
                                <SelectItem key={key} value={key}>{value}</SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                        </div>
                      </div>
                      
                      <div className="space-y-2">
                        <Label htmlFor="description">Description</Label>
                        <Textarea id="description" name="description" />
                      </div>
                      
                      <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                          <Label htmlFor="email">Email</Label>
                          <Input id="email" name="email" type="email" required />
                        </div>
                        
                        <div className="space-y-2">
                          <Label htmlFor="phone">Phone</Label>
                          <Input id="phone" name="phone" />
                        </div>
                      </div>
                      
                      <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                          <Label htmlFor="address">Address</Label>
                          <Input id="address" name="address" />
                        </div>
                        
                        <div className="space-y-2">
                          <Label htmlFor="city">City</Label>
                          <Input id="city" name="city" />
                        </div>
                      </div>
                      
                      <div className="space-y-2">
                        <Label htmlFor="priceRange">Price Range</Label>
                        <Select name="priceRange">
                          <SelectTrigger id="priceRange">
                            <SelectValue placeholder="Select price range" />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="budget">Budget</SelectItem>
                            <SelectItem value="moderate">Moderate</SelectItem>
                            <SelectItem value="premium">Premium</SelectItem>
                            <SelectItem value="luxury">Luxury</SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                      
                      <DialogFooter>
                        <Button 
                          variant="outline" 
                          type="button" 
                          onClick={() => setIsAddingVendor(false)}
                        >
                          Cancel
                        </Button>
                        <Button 
                          type="submit" 
                          disabled={createVendorMutation.isPending}
                        >
                          {createVendorMutation.isPending ? "Creating..." : "Create Vendor"}
                        </Button>
                      </DialogFooter>
                    </form>
                  </DialogContent>
                </Dialog>
              </div>
            </div>
            
            {/* Vendors Table */}
            <Card>
              <CardHeader>
                <CardTitle>Vendors</CardTitle>
                <CardDescription>
                  Manage service providers on the platform
                </CardDescription>
              </CardHeader>
              <CardContent>
                {isLoadingVendors ? (
                  <div className="space-y-4">
                    <Skeleton className="h-4 w-full" />
                    <Skeleton className="h-10 w-full" />
                    <Skeleton className="h-10 w-full" />
                    <Skeleton className="h-10 w-full" />
                  </div>
                ) : filteredVendors.length > 0 ? (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Business Name</TableHead>
                        <TableHead>Category</TableHead>
                        <TableHead>Location</TableHead>
                        <TableHead>Rating</TableHead>
                        <TableHead>Price Range</TableHead>
                        <TableHead className="text-right">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filteredVendors.map((vendor: any) => (
                        <TableRow key={vendor.id}>
                          <TableCell className="font-medium">{vendor.businessName}</TableCell>
                          <TableCell>
                            {SERVICE_CATEGORIES[vendor.category as keyof typeof SERVICE_CATEGORIES] || vendor.category}
                          </TableCell>
                          <TableCell>{vendor.city || "N/A"}</TableCell>
                          <TableCell>
                            <div className="flex items-center">
                              <Star className="h-4 w-4 text-yellow-400 mr-1" />
                              <span>{vendor.rating ? vendor.rating.toFixed(1) : "N/A"}</span>
                            </div>
                          </TableCell>
                          <TableCell>
                            {vendor.priceRange && (
                              <Badge variant="outline" className="capitalize">
                                {vendor.priceRange}
                              </Badge>
                            )}
                          </TableCell>
                          <TableCell className="text-right">
                            <div className="flex justify-end gap-2">
                              <Button 
                                variant="outline" 
                                size="sm" 
                                onClick={() => handleViewVendor(vendor)}
                              >
                                <Edit className="h-4 w-4" />
                              </Button>
                              <Button 
                                variant="outline" 
                                size="sm" 
                                className="text-destructive hover:text-destructive" 
                                onClick={() => handleDeleteVendor(vendor.id)}
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                ) : (
                  <div className="text-center py-6">
                    <p className="text-muted-foreground">No vendors found</p>
                    {searchTerm || categoryFilter ? (
                      <Button 
                        variant="link" 
                        onClick={() => {
                          setSearchTerm("");
                          setCategoryFilter(null);
                        }}
                      >
                        Clear filters
                      </Button>
                    ) : (
                      <Button 
                        variant="outline" 
                        className="mt-2" 
                        onClick={() => setIsAddingVendor(true)}
                      >
                        <Plus className="h-4 w-4 mr-2" />
                        Add Vendor
                      </Button>
                    )}
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>
          
          <TabsContent value="services" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>Services</CardTitle>
                <CardDescription>
                  Manage vendor services and packages
                </CardDescription>
              </CardHeader>
              <CardContent className="pt-6">
                <div className="flex flex-col items-center justify-center py-10 text-center">
                  <div className="rounded-full bg-primary/10 p-3 mb-4">
                    <Filter className="h-6 w-6 text-primary" />
                  </div>
                  <h3 className="text-lg font-medium mb-2">Services Management</h3>
                  <p className="text-muted-foreground text-sm max-w-md mb-4">
                    This feature will allow management of vendor services, packages and pricing.
                    Currently being implemented for the next update.
                  </p>
                  <Button variant="outline">Coming Soon</Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
        
        {/* Vendor Details Dialog */}
        <Dialog open={isViewingVendor} onOpenChange={setIsViewingVendor}>
          <DialogContent className="sm:max-w-[600px]">
            <DialogHeader>
              <DialogTitle>Vendor Details</DialogTitle>
              <DialogDescription>
                {selectedVendor ? selectedVendor.businessName : 'View and manage vendor information'}
              </DialogDescription>
            </DialogHeader>
            
            {selectedVendor && (
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <h4 className="text-sm font-medium mb-1">Business Name</h4>
                    <p>{selectedVendor.businessName}</p>
                  </div>
                  <div>
                    <h4 className="text-sm font-medium mb-1">Category</h4>
                    <p>
                      {SERVICE_CATEGORIES[selectedVendor.category as keyof typeof SERVICE_CATEGORIES] || 
                       selectedVendor.category}
                    </p>
                  </div>
                </div>
                
                <div>
                  <h4 className="text-sm font-medium mb-1">Description</h4>
                  <p className="text-sm">{selectedVendor.description || "No description provided"}</p>
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <h4 className="text-sm font-medium mb-1">Contact Email</h4>
                    <p>{selectedVendor.email || "N/A"}</p>
                  </div>
                  <div>
                    <h4 className="text-sm font-medium mb-1">Phone</h4>
                    <p>{selectedVendor.phone || "N/A"}</p>
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <h4 className="text-sm font-medium mb-1">Address</h4>
                    <p>{selectedVendor.address || "N/A"}</p>
                  </div>
                  <div>
                    <h4 className="text-sm font-medium mb-1">City</h4>
                    <p>{selectedVendor.city || "N/A"}</p>
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <h4 className="text-sm font-medium mb-1">Price Range</h4>
                    <p className="capitalize">{selectedVendor.priceRange || "N/A"}</p>
                  </div>
                  <div>
                    <h4 className="text-sm font-medium mb-1">Rating</h4>
                    <div className="flex items-center">
                      <Star className="h-4 w-4 text-yellow-400 mr-1" />
                      <span>{selectedVendor.rating ? selectedVendor.rating.toFixed(1) : "No ratings yet"}</span>
                    </div>
                  </div>
                </div>
              </div>
            )}
            
            <DialogFooter>
              <Button 
                variant="outline" 
                onClick={() => setIsViewingVendor(false)}
              >
                Close
              </Button>
              <Button onClick={() => {
                toast({
                  title: "Edit functionality coming soon",
                  description: "Vendor editing will be available in the next update"
                });
              }}>
                Edit
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>
    </AdminLayout>
  );
}