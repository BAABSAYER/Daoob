import { useEffect, useState } from "react";
import { useLocation } from "wouter";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/hooks/use-auth";
import { 
  ChevronLeft, Search, Filter, Users, UserCheck, 
  Calendar, MoreHorizontal, Download, Trash2, 
  ArrowUpDown, CheckCircle2, XCircle, AlertCircle
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

// User types for typesafety
interface User {
  id: number;
  username: string;
  fullName?: string;
  email: string;
  userType: string;
  status: string;
  createdAt: string;
  phone?: string;
}

export default function AdminUsers() {
  const { user } = useAuth();
  const [, navigate] = useLocation();
  const [searchQuery, setSearchQuery] = useState("");
  const [userTypeFilter, setUserTypeFilter] = useState("all");
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  
  // Redirect if not an admin
  useEffect(() => {
    if (user && user.userType !== 'admin') {
      navigate("/");
    }
  }, [user, navigate]);
  
  // Fetch users data
  const { data: usersData, isLoading } = useQuery({
    queryKey: ['/api/admin/users', searchQuery, userTypeFilter],
    enabled: !!user && user.userType === 'admin',
  });
  
  const users = usersData || [];
  
  // Filter users based on search and type filter
  const filteredUsers = users.filter((user: User) => {
    const matchesSearch = 
      searchQuery === "" || 
      user.username.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (user.fullName && user.fullName.toLowerCase().includes(searchQuery.toLowerCase())) ||
      user.email.toLowerCase().includes(searchQuery.toLowerCase());
      
    const matchesType = userTypeFilter === "all" || user.userType === userTypeFilter;
    
    return matchesSearch && matchesType;
  });
  
  const handleUserAction = (action: string, selectedUser: User) => {
    if (action === "view") {
      setSelectedUser(selectedUser);
    } else if (action === "delete") {
      setSelectedUser(selectedUser);
      setShowDeleteDialog(true);
    }
  };
  
  const handleConfirmDelete = () => {
    // In a real app, this would call an API endpoint to delete the user
    console.log("Deleting user:", selectedUser?.id);
    setShowDeleteDialog(false);
    setSelectedUser(null);
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
                <h1 className="text-2xl font-bold text-gray-900">User Management</h1>
                <p className="text-gray-600">View and manage all platform users</p>
              </div>
            </div>
            
            <div className="flex flex-wrap items-center justify-between gap-4 mt-6">
              <div className="flex items-center gap-2">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                  <Input 
                    className="pl-10 w-64" 
                    placeholder="Search users..." 
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                  />
                </div>
                
                <Select value={userTypeFilter} onValueChange={setUserTypeFilter}>
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="Filter by type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Types</SelectItem>
                    <SelectItem value="admin">Admins</SelectItem>
                    <SelectItem value="vendor">Vendors</SelectItem>
                    <SelectItem value="client">Clients</SelectItem>
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
                <Button className="gap-2 bg-blue-600 hover:bg-blue-700 text-white">
                  <Users className="h-4 w-4" />
                  Add User
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
                <TabsTrigger value="all">All Users</TabsTrigger>
                <TabsTrigger value="active">Active</TabsTrigger>
                <TabsTrigger value="pending">Pending</TabsTrigger>
                <TabsTrigger value="blocked">Blocked</TabsTrigger>
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
          ) : filteredUsers.length > 0 ? (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-12">#</TableHead>
                    <TableHead>
                      <div className="flex items-center gap-1">
                        User
                        <ArrowUpDown className="h-3 w-3" />
                      </div>
                    </TableHead>
                    <TableHead>Email</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Joined</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredUsers.map((user: User, index: number) => (
                    <TableRow key={user.id}>
                      <TableCell className="font-medium">{index + 1}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center">
                            {user.userType === 'vendor' ? (
                              <UserCheck className="h-4 w-4 text-gray-500" />
                            ) : (
                              <Users className="h-4 w-4 text-gray-500" />
                            )}
                          </div>
                          <div>
                            <div className="font-medium">{user.fullName || user.username}</div>
                            <div className="text-xs text-gray-500">@{user.username}</div>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>{user.email}</TableCell>
                      <TableCell>
                        <UserTypeBadge type={user.userType} />
                      </TableCell>
                      <TableCell>
                        <UserStatusBadge status={user.status} />
                      </TableCell>
                      <TableCell>
                        {new Date(user.createdAt).toLocaleDateString()}
                      </TableCell>
                      <TableCell className="text-right">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                              <MoreHorizontal className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => handleUserAction("view", user)}>
                              View Details
                            </DropdownMenuItem>
                            <DropdownMenuItem>Edit User</DropdownMenuItem>
                            {user.status === 'active' ? (
                              <DropdownMenuItem>Block User</DropdownMenuItem>
                            ) : (
                              <DropdownMenuItem>Activate User</DropdownMenuItem>
                            )}
                            <DropdownMenuSeparator />
                            <DropdownMenuItem 
                              className="text-red-600"
                              onClick={() => handleUserAction("delete", user)}
                            >
                              Delete User
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
              <Users className="h-12 w-12 mx-auto text-gray-300 mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-1">No users found</h3>
              <p className="text-gray-500">Try adjusting your search or filter parameters</p>
            </div>
          )}
          
          {filteredUsers.length > 0 && (
            <div className="flex items-center justify-between px-4 py-3 border-t border-gray-200">
              <div className="text-sm text-gray-500">
                Showing <span className="font-medium">{filteredUsers.length}</span> of{" "}
                <span className="font-medium">{users.length}</span> users
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
      
      {/* User details dialog */}
      {selectedUser && (
        <Dialog open={!!selectedUser && !showDeleteDialog} onOpenChange={() => setSelectedUser(null)}>
          <DialogContent className="max-w-md">
            <DialogHeader>
              <DialogTitle>User Details</DialogTitle>
            </DialogHeader>
            
            <div className="py-4">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-16 h-16 rounded-full bg-gray-200 flex items-center justify-center">
                  {selectedUser.userType === 'vendor' ? (
                    <UserCheck className="h-8 w-8 text-gray-500" />
                  ) : (
                    <Users className="h-8 w-8 text-gray-500" />
                  )}
                </div>
                <div>
                  <h3 className="font-semibold text-lg">{selectedUser.fullName || selectedUser.username}</h3>
                  <div className="flex items-center gap-2">
                    <UserTypeBadge type={selectedUser.userType} />
                    <UserStatusBadge status={selectedUser.status} />
                  </div>
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <div className="text-sm text-gray-500 mb-1">Username</div>
                  <div className="font-medium">@{selectedUser.username}</div>
                </div>
                <div>
                  <div className="text-sm text-gray-500 mb-1">User ID</div>
                  <div className="font-medium">{selectedUser.id}</div>
                </div>
                <div className="col-span-2">
                  <div className="text-sm text-gray-500 mb-1">Email</div>
                  <div className="font-medium">{selectedUser.email}</div>
                </div>
                <div className="col-span-2">
                  <div className="text-sm text-gray-500 mb-1">Phone</div>
                  <div className="font-medium">{selectedUser.phone || "Not provided"}</div>
                </div>
                <div className="col-span-2">
                  <div className="text-sm text-gray-500 mb-1">Registered on</div>
                  <div className="font-medium">{new Date(selectedUser.createdAt).toLocaleString()}</div>
                </div>
              </div>
            </div>
            
            <DialogFooter className="flex flex-col sm:flex-row gap-2">
              <Button 
                variant="outline" 
                className="sm:flex-1"
                onClick={() => setSelectedUser(null)}
              >
                Close
              </Button>
              <Button 
                variant="default" 
                className="sm:flex-1 bg-blue-600 hover:bg-blue-700"
              >
                Edit User
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}
      
      {/* Delete confirmation dialog */}
      <Dialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Delete User</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete this user? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          
          {selectedUser && (
            <div className="py-4">
              <div className="flex items-center p-3 border border-gray-200 rounded-md mb-3">
                <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center mr-3">
                  <Users className="h-5 w-5 text-gray-500" />
                </div>
                <div>
                  <div className="font-medium">{selectedUser.fullName || selectedUser.username}</div>
                  <div className="text-xs text-gray-500">{selectedUser.email}</div>
                </div>
              </div>
              
              <div className="px-3 py-2 bg-red-50 border border-red-100 rounded-md text-sm text-red-800">
                <AlertCircle className="h-4 w-4 inline-block mr-1" />
                Deleting this user will remove all their data, including bookings, messages, and reviews.
              </div>
            </div>
          )}
          
          <DialogFooter className="flex flex-col sm:flex-row gap-2">
            <Button 
              variant="outline" 
              className="sm:flex-1"
              onClick={() => setShowDeleteDialog(false)}
            >
              Cancel
            </Button>
            <Button 
              variant="destructive" 
              className="sm:flex-1"
              onClick={handleConfirmDelete}
            >
              <Trash2 className="h-4 w-4 mr-1" />
              Delete User
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function UserTypeBadge({ type }: { type: string }) {
  switch (type) {
    case 'admin':
      return (
        <Badge className="bg-purple-100 text-purple-800 hover:bg-purple-100 border-purple-200 capitalize">
          Admin
        </Badge>
      );
    case 'vendor':
      return (
        <Badge className="bg-blue-100 text-blue-800 hover:bg-blue-100 border-blue-200 capitalize">
          Vendor
        </Badge>
      );
    case 'client':
      return (
        <Badge className="bg-green-100 text-green-800 hover:bg-green-100 border-green-200 capitalize">
          Client
        </Badge>
      );
    default:
      return (
        <Badge className="bg-gray-100 text-gray-800 hover:bg-gray-100 border-gray-200 capitalize">
          {type}
        </Badge>
      );
  }
}

function UserStatusBadge({ status }: { status: string }) {
  switch (status) {
    case 'active':
      return (
        <div className="flex items-center">
          <CheckCircle2 className="h-3 w-3 text-green-500 mr-1" />
          <span className="text-xs text-green-600 capitalize">Active</span>
        </div>
      );
    case 'pending':
      return (
        <div className="flex items-center">
          <AlertCircle className="h-3 w-3 text-yellow-500 mr-1" />
          <span className="text-xs text-yellow-600 capitalize">Pending</span>
        </div>
      );
    case 'blocked':
      return (
        <div className="flex items-center">
          <XCircle className="h-3 w-3 text-red-500 mr-1" />
          <span className="text-xs text-red-600 capitalize">Blocked</span>
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