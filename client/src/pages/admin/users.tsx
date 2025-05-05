import { useEffect, useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { AdminLayout } from "@/components/admin-layout";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { useToast } from "@/hooks/use-toast";
import { Loader2, PlusCircle, UserCog, Trash2, Save } from "lucide-react";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { ADMIN_PERMISSIONS } from "@shared/schema";
import { useAuth } from "@/hooks/use-auth";

type AdminUserWithPermissions = {
  id: number;
  username: string;
  email: string;
  fullName?: string;
  phone?: string;
  userType: string;
  permissions: string[];
};

type AdminPermission = {
  id: string;
  label: string;
};

const permissionsList: AdminPermission[] = Object.entries(ADMIN_PERMISSIONS).map(([id, label]) => ({
  id,
  label
}));

export default function AdminUsersPage() {
  const { toast } = useToast();
  const { user } = useAuth();
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [isPermissionsDialogOpen, setIsPermissionsDialogOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<AdminUserWithPermissions | null>(null);
  const [newUserData, setNewUserData] = useState({
    username: "",
    password: "",
    email: "",
    fullName: "",
    phone: "",
    permissions: [] as string[]
  });

  // Fetch admin users
  const { data: adminUsers, isLoading, error, refetch } = useQuery<AdminUserWithPermissions[]>({
    queryKey: ["/api/admin/users"],
    enabled: !!user
  });

  // Check admin permission
  const { data: hasAdminPermission } = useQuery<boolean>({
    queryKey: ["/api/admin/check-permission", "manage_admins"],
    queryFn: async () => {
      const res = await apiRequest("GET", "/api/admin/check-permission?permission=manage_admins");
      return await res.json();
    },
    enabled: !!user
  });

  // Create admin mutation
  const createAdminMutation = useMutation({
    mutationFn: async (data: typeof newUserData) => {
      const res = await apiRequest("POST", "/api/admin/users", data);
      if (!res.ok) {
        const error = await res.json();
        throw new Error(error.message || "Failed to create admin user");
      }
      return await res.json();
    },
    onSuccess: () => {
      toast({
        title: "Success",
        description: "Admin user created successfully",
      });
      setIsCreateDialogOpen(false);
      setNewUserData({
        username: "",
        password: "",
        email: "",
        fullName: "",
        phone: "",
        permissions: []
      });
      queryClient.invalidateQueries({ queryKey: ["/api/admin/users"] });
    },
    onError: (error: Error) => {
      toast({
        title: "Error",
        description: error.message,
        variant: "destructive"
      });
    }
  });

  // Update permissions mutation
  const updatePermissionsMutation = useMutation({
    mutationFn: async ({ userId, permissions }: { userId: number, permissions: string[] }) => {
      const res = await apiRequest("PUT", `/api/admin/users/${userId}/permissions`, { permissions });
      if (!res.ok) {
        const error = await res.json();
        throw new Error(error.message || "Failed to update permissions");
      }
      return await res.json();
    },
    onSuccess: () => {
      toast({
        title: "Success",
        description: "Admin permissions updated successfully",
      });
      setIsPermissionsDialogOpen(false);
      setSelectedUser(null);
      queryClient.invalidateQueries({ queryKey: ["/api/admin/users"] });
    },
    onError: (error: Error) => {
      toast({
        title: "Error",
        description: error.message,
        variant: "destructive"
      });
    }
  });

  // Delete admin mutation
  const deleteAdminMutation = useMutation({
    mutationFn: async (userId: number) => {
      const res = await apiRequest("DELETE", `/api/admin/users/${userId}`);
      if (!res.ok) {
        const error = await res.json();
        throw new Error(error.message || "Failed to delete admin user");
      }
      return true;
    },
    onSuccess: () => {
      toast({
        title: "Success",
        description: "Admin user deleted successfully",
      });
      queryClient.invalidateQueries({ queryKey: ["/api/admin/users"] });
    },
    onError: (error: Error) => {
      toast({
        title: "Error",
        description: error.message,
        variant: "destructive"
      });
    }
  });

  const handleCreateAdmin = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newUserData.username || !newUserData.password || !newUserData.email) {
      toast({
        title: "Validation Error",
        description: "Username, password, and email are required",
        variant: "destructive"
      });
      return;
    }
    createAdminMutation.mutate(newUserData);
  };

  const handleUpdatePermissions = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUser) return;

    updatePermissionsMutation.mutate({
      userId: selectedUser.id,
      permissions: selectedUser.permissions
    });
  };

  const handleDeleteAdmin = (userId: number) => {
    if (confirm("Are you sure you want to delete this admin user? This action cannot be undone.")) {
      deleteAdminMutation.mutate(userId);
    }
  };

  const togglePermission = (permission: string) => {
    if (!selectedUser) return;

    const updatedPermissions = selectedUser.permissions.includes(permission)
      ? selectedUser.permissions.filter(p => p !== permission)
      : [...selectedUser.permissions, permission];

    setSelectedUser({
      ...selectedUser,
      permissions: updatedPermissions
    });
  };

  const toggleNewUserPermission = (permission: string) => {
    const updatedPermissions = newUserData.permissions.includes(permission)
      ? newUserData.permissions.filter(p => p !== permission)
      : [...newUserData.permissions, permission];

    setNewUserData({
      ...newUserData,
      permissions: updatedPermissions
    });
  };

  if (!hasAdminPermission) {
    return (
      <AdminLayout title="Admin Users Management">
        <div className="flex flex-col items-center justify-center h-[50vh]">
          <UserCog className="h-16 w-16 text-muted-foreground mb-4" />
          <h2 className="text-2xl font-bold mb-2">Permission Denied</h2>
          <p className="text-muted-foreground">
            You do not have permission to manage admin users.
          </p>
        </div>
      </AdminLayout>
    );
  }

  return (
    <AdminLayout title="Admin Users Management">
      <div className="mb-6 flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold">Admin Team Management</h2>
          <p className="text-muted-foreground">
            Manage your admin team members and their permissions
          </p>
        </div>
        <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
          <DialogTrigger asChild>
            <Button>
              <PlusCircle className="h-4 w-4 mr-2" />
              Add Admin User
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-[525px]">
            <DialogHeader>
              <DialogTitle>Create New Admin User</DialogTitle>
              <DialogDescription>
                Add a new member to your admin team. All new admins will need to be assigned permissions.
              </DialogDescription>
            </DialogHeader>
            <form onSubmit={handleCreateAdmin}>
              <div className="grid gap-4 py-4">
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="username" className="text-right">
                    Username
                  </Label>
                  <Input
                    id="username"
                    value={newUserData.username}
                    onChange={(e) => setNewUserData({ ...newUserData, username: e.target.value })}
                    className="col-span-3"
                    required
                  />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="password" className="text-right">
                    Password
                  </Label>
                  <Input
                    id="password"
                    type="password"
                    value={newUserData.password}
                    onChange={(e) => setNewUserData({ ...newUserData, password: e.target.value })}
                    className="col-span-3"
                    required
                  />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="email" className="text-right">
                    Email
                  </Label>
                  <Input
                    id="email"
                    type="email"
                    value={newUserData.email}
                    onChange={(e) => setNewUserData({ ...newUserData, email: e.target.value })}
                    className="col-span-3"
                    required
                  />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="fullName" className="text-right">
                    Full Name
                  </Label>
                  <Input
                    id="fullName"
                    value={newUserData.fullName}
                    onChange={(e) => setNewUserData({ ...newUserData, fullName: e.target.value })}
                    className="col-span-3"
                  />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="phone" className="text-right">
                    Phone
                  </Label>
                  <Input
                    id="phone"
                    value={newUserData.phone}
                    onChange={(e) => setNewUserData({ ...newUserData, phone: e.target.value })}
                    className="col-span-3"
                  />
                </div>
                <div className="mt-4">
                  <Label className="mb-2 block">Permissions</Label>
                  <div className="grid grid-cols-2 gap-2 mt-1">
                    {permissionsList.map((permission) => (
                      <div key={permission.id} className="flex items-center space-x-2">
                        <Checkbox
                          id={`new-permission-${permission.id}`}
                          checked={newUserData.permissions.includes(permission.id)}
                          onCheckedChange={() => toggleNewUserPermission(permission.id)}
                        />
                        <Label htmlFor={`new-permission-${permission.id}`} className="text-sm">
                          {permission.label}
                        </Label>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
              <DialogFooter>
                <Button 
                  type="submit" 
                  disabled={createAdminMutation.isPending}
                >
                  {createAdminMutation.isPending && (
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  )}
                  Create Admin User
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      {isLoading ? (
        <div className="flex justify-center my-12">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      ) : error ? (
        <div className="bg-destructive/10 text-destructive p-4 rounded-md mb-4">
          <p>Error loading admin users: {(error as Error).message}</p>
          <Button variant="outline" onClick={() => refetch()} className="mt-2">
            Retry
          </Button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {adminUsers?.map((adminUser) => (
            <Card key={adminUser.id}>
              <CardHeader className="pb-2">
                <CardTitle className="flex justify-between items-center">
                  <span>{adminUser.fullName || adminUser.username}</span>
                  {adminUser.id !== user?.id && (
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleDeleteAdmin(adminUser.id)}
                    >
                      <Trash2 className="h-4 w-4 text-destructive" />
                    </Button>
                  )}
                </CardTitle>
                <CardDescription>@{adminUser.username}</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="text-sm space-y-1 mb-4">
                  <div>
                    <span className="text-muted-foreground">Email:</span> {adminUser.email}
                  </div>
                  {adminUser.phone && (
                    <div>
                      <span className="text-muted-foreground">Phone:</span> {adminUser.phone}
                    </div>
                  )}
                </div>
                
                <div className="border-t pt-3">
                  <div className="text-sm font-medium mb-2">Permissions:</div>
                  <div className="flex flex-wrap gap-2 mb-3">
                    {adminUser.permissions.length > 0 ? (
                      adminUser.permissions.map((permission) => (
                        <div
                          key={permission}
                          className="bg-primary/10 text-primary px-2 py-1 rounded-full text-xs"
                        >
                          {permissionsList.find(p => p.id === permission)?.label || permission}
                        </div>
                      ))
                    ) : (
                      <div className="text-xs text-muted-foreground">No permissions assigned</div>
                    )}
                  </div>
                  
                  <Dialog open={isPermissionsDialogOpen && selectedUser?.id === adminUser.id} onOpenChange={(open) => {
                    setIsPermissionsDialogOpen(open);
                    if (!open) setSelectedUser(null);
                  }}>
                    <DialogTrigger asChild>
                      <Button
                        size="sm"
                        variant="outline"
                        className="w-full"
                        onClick={() => {
                          setSelectedUser(adminUser);
                          setIsPermissionsDialogOpen(true);
                        }}
                      >
                        <UserCog className="h-4 w-4 mr-2" />
                        Manage Permissions
                      </Button>
                    </DialogTrigger>
                    <DialogContent>
                      <DialogHeader>
                        <DialogTitle>Manage Permissions</DialogTitle>
                        <DialogDescription>
                          Update permissions for {adminUser.fullName || adminUser.username}
                        </DialogDescription>
                      </DialogHeader>
                      {selectedUser && (
                        <form onSubmit={handleUpdatePermissions}>
                          <div className="grid grid-cols-2 gap-4 py-4">
                            {permissionsList.map((permission) => (
                              <div key={permission.id} className="flex items-center space-x-2">
                                <Checkbox
                                  id={`permission-${permission.id}`}
                                  checked={selectedUser.permissions.includes(permission.id)}
                                  onCheckedChange={() => togglePermission(permission.id)}
                                />
                                <Label htmlFor={`permission-${permission.id}`}>
                                  {permission.label}
                                </Label>
                              </div>
                            ))}
                          </div>
                          <DialogFooter>
                            <Button 
                              type="submit" 
                              disabled={updatePermissionsMutation.isPending}
                            >
                              {updatePermissionsMutation.isPending && (
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                              )}
                              Save Permissions
                            </Button>
                          </DialogFooter>
                        </form>
                      )}
                    </DialogContent>
                  </Dialog>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </AdminLayout>
  );
}