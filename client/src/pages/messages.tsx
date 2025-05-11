import { useEffect } from "react";
import { useLocation } from "wouter";
import { ChatList } from "@/components/chat/chat-list";
import { Header } from "@/components/layout/header";
import { BottomNavigation } from "@/components/layout/bottom-navigation";
import { useAuth } from "@/hooks/use-auth";
import { Loader2 } from "lucide-react";

export default function Messages() {
  const { user, isLoading } = useAuth();
  const [, navigate] = useLocation();
  
  // Redirect to login if not authenticated
  useEffect(() => {
    if (!isLoading && !user) {
      navigate("/auth");
    }
  }, [user, isLoading, navigate]);
  
  // Show loading state while checking authentication
  if (isLoading) {
    return (
      <div className="h-full w-full flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }
  
  // Don't render anything if not authenticated (will redirect)
  if (!user) {
    return null;
  }
  
  return (
    <div className="h-full w-full flex flex-col pb-16">
      {/* Header */}
      <Header title="Messages" showBack={false} showSearch={false} />
      
      {/* Chat List */}
      <ChatList />
      
      {/* Bottom Navigation */}
      <BottomNavigation />
    </div>
  );
}
