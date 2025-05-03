import { useState } from "react";
import { useLocation } from "wouter";
import { useAuth } from "@/hooks/use-auth";
import { Button } from "@/components/ui/button";
import { Header } from "@/components/layout/header";
import { BottomNavigation } from "@/components/layout/bottom-navigation";
import { Loader2, LogOut, Edit, User, Settings, MessageSquare, Calendar } from "lucide-react";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { useToast } from "@/hooks/use-toast";

export default function Profile() {
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [, setLocation] = useLocation();
  const { user, logoutMutation } = useAuth();
  
  const navigate = (path: string) => setLocation(path);
  
  const { toast } = useToast();
  
  const handleLogout = () => {
    logoutMutation.mutate(undefined, {
      onSuccess: () => {
        toast({
          title: "Logged out successfully",
          description: "You have been logged out of your account",
        });
        navigate("/auth");
        setIsConfirmOpen(false);
      },
      onError: (error) => {
        toast({
          variant: "destructive",
          title: "Error",
          description: error.message || "Failed to log out",
        });
      }
    });
  };
  
  if (!user) {
    return (
      <div className="h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }
  
  return (
    <div className="pb-16">
      <Header title="My Profile" />
      
      <div className="p-4">
        {/* Profile Card */}
        <Card className="mb-6">
          <CardContent className="pt-6">
            <div className="flex items-center mb-6">
              <div className="w-16 h-16 bg-secondary/10 rounded-full flex items-center justify-center mr-4">
                {user.avatarUrl ? (
                  <img 
                    src={user.avatarUrl} 
                    alt={user.username} 
                    className="w-16 h-16 rounded-full object-cover"
                  />
                ) : (
                  <User className="h-8 w-8 text-secondary" />
                )}
              </div>
              <div>
                <h2 className="text-xl font-semibold">{user.fullName || user.username}</h2>
                <p className="text-neutral-500">{user.email}</p>
                <p className="text-sm text-secondary capitalize">{user.userType}</p>
              </div>
              <Button variant="ghost" size="icon" className="ml-auto">
                <Edit className="h-5 w-5" />
              </Button>
            </div>
            
            <div className="grid grid-cols-3 gap-4 mb-2">
              <div className="text-center">
                <div className="bg-secondary/10 h-12 w-12 mx-auto rounded-full flex items-center justify-center mb-1">
                  <Calendar className="h-6 w-6 text-secondary" />
                </div>
                <p className="text-xs font-medium">Bookings</p>
              </div>
              <div className="text-center">
                <div className="bg-secondary/10 h-12 w-12 mx-auto rounded-full flex items-center justify-center mb-1">
                  <MessageSquare className="h-6 w-6 text-secondary" />
                </div>
                <p className="text-xs font-medium">Messages</p>
              </div>
              <div className="text-center">
                <div className="bg-secondary/10 h-12 w-12 mx-auto rounded-full flex items-center justify-center mb-1">
                  <Settings className="h-6 w-6 text-secondary" />
                </div>
                <p className="text-xs font-medium">Settings</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        {/* Account Settings */}
        <Tabs defaultValue="account" className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="account">Account</TabsTrigger>
            <TabsTrigger value="preferences">Preferences</TabsTrigger>
          </TabsList>
          <TabsContent value="account">
            <Card>
              <CardHeader>
                <CardTitle>Account Settings</CardTitle>
                <CardDescription>
                  Manage your account settings and preferences.
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex justify-between items-center py-3 border-b">
                  <div>
                    <p className="font-medium">Personal Information</p>
                    <p className="text-sm text-neutral-500">Update your personal details</p>
                  </div>
                  <Button variant="ghost" size="sm">Edit</Button>
                </div>
                <div className="flex justify-between items-center py-3 border-b">
                  <div>
                    <p className="font-medium">Security</p>
                    <p className="text-sm text-neutral-500">Change password and security settings</p>
                  </div>
                  <Button variant="ghost" size="sm">Edit</Button>
                </div>
                <div className="flex justify-between items-center py-3 border-b">
                  <div>
                    <p className="font-medium">Notifications</p>
                    <p className="text-sm text-neutral-500">Configure your notification preferences</p>
                  </div>
                  <Button variant="ghost" size="sm">Edit</Button>
                </div>
              </CardContent>
              <CardFooter>
                <Dialog open={isConfirmOpen} onOpenChange={setIsConfirmOpen}>
                  <DialogTrigger asChild>
                    <Button variant="outline" className="w-full border-red-300 text-red-500 hover:bg-red-50" type="button">
                      <LogOut className="h-4 w-4 mr-2" />
                      Log Out
                    </Button>
                  </DialogTrigger>
                  <DialogContent>
                    <DialogHeader>
                      <DialogTitle>Are you sure you want to log out?</DialogTitle>
                      <DialogDescription>
                        You will need to log back in to access your account.
                      </DialogDescription>
                    </DialogHeader>
                    <DialogFooter>
                      <Button variant="outline" onClick={() => setIsConfirmOpen(false)}>Cancel</Button>
                      <Button 
                        variant="destructive" 
                        onClick={handleLogout}
                        disabled={logoutMutation.isPending}
                      >
                        {logoutMutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Log Out
                      </Button>
                    </DialogFooter>
                  </DialogContent>
                </Dialog>
              </CardFooter>
            </Card>
          </TabsContent>
          <TabsContent value="preferences">
            <Card>
              <CardHeader>
                <CardTitle>Preferences</CardTitle>
                <CardDescription>
                  Customize your app experience.
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex justify-between items-center py-3 border-b">
                  <div>
                    <p className="font-medium">Theme</p>
                    <p className="text-sm text-neutral-500">Choose your preferred theme</p>
                  </div>
                  <Button variant="ghost" size="sm">Edit</Button>
                </div>
                <div className="flex justify-between items-center py-3 border-b">
                  <div>
                    <p className="font-medium">Language</p>
                    <p className="text-sm text-neutral-500">Select your preferred language</p>
                  </div>
                  <Button variant="ghost" size="sm">Edit</Button>
                </div>
                <div className="flex justify-between items-center py-3 border-b">
                  <div>
                    <p className="font-medium">Privacy</p>
                    <p className="text-sm text-neutral-500">Manage your privacy settings</p>
                  </div>
                  <Button variant="ghost" size="sm">Edit</Button>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
      
      <BottomNavigation />
    </div>
  );
}