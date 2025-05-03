import { useState, useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { useLocation } from "wouter";
import { useAuth } from "@/hooks/use-auth";
import { formatDistanceToNow } from "date-fns";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { Search, Building, User, Camera, Utensils, Gift } from "lucide-react";

interface Conversation {
  userId: number;
  username: string;
  fullName?: string;
  userType: string;
  lastMessage?: {
    content: string;
    createdAt: string;
    senderId: number;
  };
  unreadCount: number;
}

export function ChatList() {
  const [searchTerm, setSearchTerm] = useState("");
  const [, navigate] = useLocation();
  const { user } = useAuth();
  
  const { data: conversations, isLoading } = useQuery<Conversation[]>({
    queryKey: ['/api/conversations'],
  });
  
  const filteredConversations = conversations?.filter(conv => {
    const fullName = conv.fullName?.toLowerCase() || "";
    const username = conv.username.toLowerCase();
    const search = searchTerm.toLowerCase();
    
    return fullName.includes(search) || username.includes(search);
  });

  const handleUserSelect = (userId: number) => {
    navigate(`/chat/${userId}`);
  };

  const getTimeAgo = (dateString: string) => {
    try {
      const date = new Date(dateString);
      return formatDistanceToNow(date, { addSuffix: true });
    } catch (error) {
      return "recently";
    }
  };

  // Helper to get appropriate icon based on user type
  const getUserIcon = (userType: string) => {
    switch (userType) {
      case 'vendor':
        return <Building className="text-primary" />;
      case 'client':
        return <User className="text-secondary" />;
      case 'photography':
        return <Camera className="text-accent" />;
      case 'catering':
        return <Utensils className="text-green-600" />;
      case 'decoration':
        return <Gift className="text-purple-600" />;
      default:
        return <User className="text-neutral-500" />;
    }
  };
  
  return (
    <div className="bg-neutral-100 min-h-screen pb-20">
      <div className="bg-white px-5 py-3 shadow-sm">
        <div className="relative">
          <Input 
            placeholder="Search conversations..." 
            className="pl-9"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-neutral-500 h-4 w-4" />
        </div>
      </div>

      <div className="divide-y divide-neutral-200">
        {isLoading && (
          <>
            <ConversationSkeleton />
            <ConversationSkeleton />
            <ConversationSkeleton />
          </>
        )}

        {!isLoading && filteredConversations?.length === 0 && (
          <div className="p-10 text-center">
            <p className="text-neutral-500">No conversations found</p>
          </div>
        )}

        {filteredConversations?.map((conversation) => (
          <button 
            key={conversation.userId}
            className="block w-full bg-white p-4 text-left hover:bg-neutral-50"
            onClick={() => handleUserSelect(conversation.userId)}
          >
            <div className="flex items-center">
              <div className="relative">
                <div className={`w-12 h-12 ${conversation.userType === 'vendor' ? 'bg-primary/10' : 'bg-secondary/10'} rounded-full flex items-center justify-center mr-3`}>
                  {getUserIcon(conversation.userType)}
                </div>
                <div className={`absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-white ${conversation.unreadCount > 0 ? 'bg-green-500' : 'bg-neutral-300'}`}></div>
              </div>
              <div className="flex-1">
                <div className="flex justify-between items-center mb-1">
                  <p className="font-medium text-neutral-800">
                    {conversation.fullName || conversation.username}
                  </p>
                  {conversation.lastMessage && (
                    <p className="text-xs text-neutral-500">
                      {getTimeAgo(conversation.lastMessage.createdAt)}
                    </p>
                  )}
                </div>
                <p className="text-sm text-neutral-600 truncate">
                  {conversation.lastMessage 
                    ? (conversation.lastMessage.senderId === user?.id 
                        ? "You: " 
                        : "") + conversation.lastMessage.content
                    : "Start a conversation"}
                </p>
              </div>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

function ConversationSkeleton() {
  return (
    <div className="block w-full bg-white p-4 text-left">
      <div className="flex items-center">
        <Skeleton className="w-12 h-12 rounded-full mr-3" />
        <div className="flex-1">
          <div className="flex justify-between items-center mb-1">
            <Skeleton className="h-5 w-32" />
            <Skeleton className="h-4 w-16" />
          </div>
          <Skeleton className="h-4 w-48" />
        </div>
      </div>
    </div>
  );
}
