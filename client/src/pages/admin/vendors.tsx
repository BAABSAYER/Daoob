import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { AdminLayout } from "@/components/admin-layout";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { 
  Dialog, 
  DialogContent, 
  DialogHeader, 
  DialogTitle, 
  DialogTrigger,
  DialogFooter 
} from "@/components/ui/dialog";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Textarea } from "@/components/ui/textarea";
import { 
  Select, 
  SelectContent, 
  SelectItem, 
  SelectTrigger, 
  SelectValue 
} from "@/components/ui/select";
import { SERVICE_CATEGORIES } from "@shared/schema";
import { useToast } from "@/hooks/use-toast";
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from "@/components/ui/table";
import { Vendor, Service } from "@shared/schema";

export default function AdminVendors() {
  const { toast } = useToast();
  const [isAddingVendor, setIsAddingVendor] = useState(false);
  const [selectedVendor, setSelectedVendor] = useState<Vendor | null>(null);
  const [newVendor, setNewVendor] = useState({
    name: "",
    description: "",
    category: "",
    email: "",
    phone: "",
    location: ""
  });

  // Fetch vendors
  const { data: vendors = [], isLoading: isLoadingVendors } = useQuery<Vendor[]>({
    queryKey: ["/api/vendors"],
    enabled: true,
  });

  // Fetch services for selected vendor
  const { data: services = [], isLoading: isLoadingServices } = useQuery<Service[]>({
    queryKey: ["/api/services", selectedVendor?.id],
    enabled: !!selectedVendor,
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
        description: "New vendor has been added successfully",
      });
      setIsAddingVendor(false);
      setNewVendor({
        name: "",
        description: "",
        category: "",
        email: "",
        phone: "",
        location: ""
      });
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

  const handleCreateVendor = () => {
    // Simple validation
    if (!newVendor.name || !newVendor.category || !newVendor.email) {
      toast({
        title: "Missing required fields",
        description: "Please fill in all required fields",
        variant: "destructive",
      });
      return;
    }

    createVendorMutation.mutate(newVendor);
  };

  const categoryOptions = Object.entries(SERVICE_CATEGORIES).map(([key, value]) => ({
    value: key,
    label: value,
  }));

  return (
    <AdminLayout title="Vendor Management">
      <div className="mb-4 flex justify-between items-center">
        <h1 className="text-2xl font-bold">Vendors</h1>
        <Dialog open={isAddingVendor} onOpenChange={setIsAddingVendor}>
          <DialogTrigger asChild>
            <Button>Add New Vendor</Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-[550px]">
            <DialogHeader>
              <DialogTitle>Add New Vendor</DialogTitle>
            </DialogHeader>
            <div className="grid gap-4 py-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="name">Vendor Name *</Label>
                  <Input
                    id="name"
                    value={newVendor.name}
                    onChange={(e) => setNewVendor({ ...newVendor, name: e.target.value })}
                    placeholder="Enter vendor name"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="category">Category *</Label>
                  <Select
                    value={newVendor.category}
                    onValueChange={(value) => setNewVendor({ ...newVendor, category: value })}
                  >
                    <SelectTrigger id="category">
                      <SelectValue placeholder="Select category" />
                    </SelectTrigger>
                    <SelectContent>
                      {categoryOptions.map((option) => (
                        <SelectItem key={option.value} value={option.value}>
                          {option.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <div className="space-y-2">
                <Label htmlFor="description">Description</Label>
                <Textarea
                  id="description"
                  value={newVendor.description}
                  onChange={(e) => setNewVendor({ ...newVendor, description: e.target.value })}
                  placeholder="Enter vendor description"
                  rows={3}
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="email">Email *</Label>
                  <Input
                    id="email"
                    value={newVendor.email}
                    onChange={(e) => setNewVendor({ ...newVendor, email: e.target.value })}
                    placeholder="Enter email address"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="phone">Phone</Label>
                  <Input
                    id="phone"
                    value={newVendor.phone}
                    onChange={(e) => setNewVendor({ ...newVendor, phone: e.target.value })}
                    placeholder="Enter phone number"
                  />
                </div>
              </div>
              <div className="space-y-2">
                <Label htmlFor="location">Location</Label>
                <Input
                  id="location"
                  value={newVendor.location}
                  onChange={(e) => setNewVendor({ ...newVendor, location: e.target.value })}
                  placeholder="Enter location"
                />
              </div>
            </div>
            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                onClick={() => setIsAddingVendor(false)}
              >
                Cancel
              </Button>
              <Button 
                type="button"
                onClick={handleCreateVendor}
                disabled={createVendorMutation.isPending}
              >
                {createVendorMutation.isPending ? "Creating..." : "Create Vendor"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      {isLoadingVendors ? (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3].map((i) => (
            <Card key={i}>
              <CardContent className="p-4">
                <Skeleton className="h-6 w-2/3 mb-2" />
                <Skeleton className="h-4 w-full mb-1" />
                <Skeleton className="h-4 w-3/4" />
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <div>
          {selectedVendor ? (
            <div>
              <Button 
                variant="outline" 
                className="mb-4"
                onClick={() => setSelectedVendor(null)}
              >
                Back to Vendors
              </Button>
              <div className="mb-4">
                <h2 className="text-xl font-bold">{selectedVendor.name}</h2>
                <p className="text-muted-foreground">
                  {SERVICE_CATEGORIES[selectedVendor.category as keyof typeof SERVICE_CATEGORIES] || selectedVendor.category}
                </p>
              </div>

              <Tabs defaultValue="details">
                <TabsList>
                  <TabsTrigger value="details">Details</TabsTrigger>
                  <TabsTrigger value="services">Services</TabsTrigger>
                </TabsList>
                <TabsContent value="details" className="p-4 border rounded-md mt-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <h3 className="text-sm font-medium text-muted-foreground mb-1">Description</h3>
                      <p>{selectedVendor.description || "No description provided."}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-muted-foreground mb-1">Contact Information</h3>
                      <p>Email: {selectedVendor.email}</p>
                      <p>Phone: {selectedVendor.phone || "N/A"}</p>
                      <p>Location: {selectedVendor.location || "N/A"}</p>
                    </div>
                  </div>
                </TabsContent>
                <TabsContent value="services" className="p-4 border rounded-md mt-4">
                  {isLoadingServices ? (
                    <Skeleton className="h-32 w-full" />
                  ) : services && services.length > 0 ? (
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Service Name</TableHead>
                          <TableHead>Description</TableHead>
                          <TableHead>Base Price</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {services.map((service) => (
                          <TableRow key={service.id}>
                            <TableCell>{service.name}</TableCell>
                            <TableCell>{service.description || "N/A"}</TableCell>
                            <TableCell>${service.basePrice}</TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  ) : (
                    <div className="text-center py-8">
                      <p className="text-muted-foreground">No services defined for this vendor.</p>
                    </div>
                  )}
                </TabsContent>
              </Tabs>
            </div>
          ) : (
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              {vendors && vendors.length > 0 ? vendors.map((vendor) => (
                <Card 
                  key={vendor.id} 
                  className="cursor-pointer hover:border-primary transition-colors"
                  onClick={() => setSelectedVendor(vendor)}
                >
                  <CardContent className="p-4">
                    <h3 className="font-bold text-lg">{vendor.name}</h3>
                    <p className="text-sm text-muted-foreground mb-2">
                      {SERVICE_CATEGORIES[vendor.category as keyof typeof SERVICE_CATEGORIES] || vendor.category}
                    </p>
                    <p className="text-sm line-clamp-2">
                      {vendor.description || "No description provided."}
                    </p>
                  </CardContent>
                </Card>
              )) : (
                <div className="col-span-full text-center py-12">
                  <h3 className="font-medium text-lg">No vendors found</h3>
                  <p className="text-muted-foreground mt-1">
                    Click "Add New Vendor" to create your first vendor
                  </p>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </AdminLayout>
  );
}