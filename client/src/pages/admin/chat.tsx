import { useState, useEffect, useRef } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { useParams, Link } from "wouter";
import { AdminLayout } from "@/components/admin-layout";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import { 
  MoreVertical, 
  Send, 
  ArrowLeft,
  Loader2
} from "lucide-react";
import { useAuth } from "@/hooks/use-auth";
import { useWebSocket } from "@/hooks/use-websocket";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { format } from "date-fns";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";

export default function AdminChat() {
  const { userId } = useParams();
  const { user } = useAuth();
  const { toast } = useToast();
  const { sendMessage, messages, status } = useWebSocket();
  const [messageText, setMessageText] = useState("");
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const [selectedUser, setSelectedUser] = useState<number | null>(userId ? parseInt(userId) : null);
  
  // Get all user/client chats for the admin
  const { data: clients = [], isLoading: isLoadingClients } = useQuery({
    queryKey: ["/api/admin/clients"],
    enabled: !!user,
    // Placeholder until the endpoint is implemented
    queryFn: async () => {
      // Demo placeholder data
      return [
        { id: 1, username: 'client1', fullName: 'Demo Client 1', unreadCount: 2, lastMessage: 'Hello, I need help with my event.' },
        { id: 2, username: 'client2', fullName: 'Demo Client 2', unreadCount: 0, lastMessage: 'Thank you for your assistance.' },
      ];
    }
  });
  
  // Get the selected user's details
  const { data: selectedUserDetails, isLoading: isLoadingUserDetails } = useQuery({
    queryKey: ["/api/users", selectedUser],
    enabled: !!selectedUser,
    // Placeholder until the endpoint is implemented
    queryFn: async () => {
      // Return demo placeholder data for the selected user
      if (selectedUser === 1) {
        return { id: 1, username: 'client1', fullName: 'Demo Client 1' };
      } else if (selectedUser === 2) {
        return { id: 2, username: 'client2', fullName: 'Demo Client 2' };
      }
      return { id: selectedUser, username: `client${selectedUser}`, fullName: `Demo Client ${selectedUser}` };
    }
  });
  
  // Send a message
  const sendMessageMutation = useMutation({
    mutationFn: async (messageData: any) => {
      const res = await apiRequest("POST", "/api/messages", messageData);
      return await res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/messages"] });
      setMessageText("");
    },
    onError: (error) => {
      toast({
        title: "Failed to send message",
        description: error.message,
        variant: "destructive",
      });
    },
  });
  
  // Scroll to bottom of messages when new messages come in
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);
  
  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!messageText.trim() || !selectedUser || !user) return;
    
    if (status === 'open') {
      sendMessage({
        type: "chat",
        sender: user.id,
        receiver: selectedUser,
        content: messageText,
        timestamp: new Date()
      });
    } else {
      // Fallback to REST API if WebSocket is not available
      sendMessageMutation.mutate({
        senderId: user.id,
        receiverId: selectedUser,
        content: messageText
      });
    }
  };
  
  const getInitials = (name: string) => {
    return name
      .split(" ")
      .map(part => part[0])
      .join("")
      .toUpperCase()
      .substring(0, 2);
  };
  
  const formatMessageDate = (date: Date | null) => {
    if (!date) return "";
    return format(new Date(date), "MMM d, h:mm a");
  };
  
  const filteredMessages = messages.filter(
    msg => 
      (msg.sender === user?.id && msg.receiver === selectedUser) || 
      (msg.sender === selectedUser && msg.receiver === user?.id)
  );
  
  return (
    <AdminLayout title="Messages">
      <div className="flex h-[calc(100vh-10rem)] rounded-md border overflow-hidden">
        {/* Client list sidebar */}
        <div className="w-64 border-r flex flex-col bg-card">
          <div className="p-4 border-b">
            <h3 className="font-medium">Client Conversations</h3>
          </div>
          
          <div className="flex-1 overflow-auto">
            {isLoadingClients ? (
              <div className="p-4 space-y-3">
                <Skeleton className="h-12 w-full" />
                <Skeleton className="h-12 w-full" />
                <Skeleton className="h-12 w-full" />
              </div>
            ) : clients && clients.length > 0 ? (
              clients.map((client: any) => (
                <div 
                  key={client.id}
                  className={`p-3 border-b cursor-pointer hover:bg-accent ${
                    selectedUser === client.id ? "bg-accent" : ""
                  }`}
                  onClick={() => setSelectedUser(client.id)}
                >
                  <div className="flex items-center gap-3">
                    <Avatar>
                      <AvatarFallback>
                        {getInitials(client.fullName || client.username)}
                      </AvatarFallback>
                      {/* Avatar image would go here if available */}
                    </Avatar>
                    <div className="flex-1 min-w-0">
                      <div className="flex justify-between items-center">
                        <span className="font-medium truncate">
                          {client.fullName || client.username}
                        </span>
                        {client.unreadCount > 0 && (
                          <Badge variant="destructive" className="text-xs">
                            {client.unreadCount}
                          </Badge>
                        )}
                      </div>
                      <div className="text-sm text-muted-foreground truncate">
                        {client.lastMessage ? client.lastMessage.substring(0, 20) : "No messages yet"}
                      </div>
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <div className="p-4 text-center text-muted-foreground">
                No conversations yet
              </div>
            )}
          </div>
        </div>
        
        {/* Chat area */}
        <div className="flex-1 flex flex-col">
          {selectedUser ? (
            <>
              {/* Chat header */}
              <div className="p-4 border-b flex items-center justify-between bg-card">
                <div className="flex items-center gap-3">
                  <Button 
                    variant="ghost" 
                    size="icon" 
                    className="md:hidden"
                    onClick={() => setSelectedUser(null)}
                  >
                    <ArrowLeft className="h-5 w-5" />
                  </Button>
                  
                  <Avatar>
                    <AvatarFallback>
                      {getInitials(
                        selectedUserDetails?.fullName || selectedUserDetails?.username || "User"
                      )}
                    </AvatarFallback>
                    {/* Avatar image would go here if available */}
                  </Avatar>
                  
                  <div>
                    {isLoadingUserDetails ? (
                      <Skeleton className="h-5 w-24" />
                    ) : (
                      <div className="font-medium">
                        {selectedUserDetails?.fullName || selectedUserDetails?.username || "User"}
                      </div>
                    )}
                    <div className="text-xs text-muted-foreground">
                      {status === 'open' ? (
                        <span className="text-green-500">Online</span>
                      ) : (
                        "Offline"
                      )}
                    </div>
                  </div>
                </div>
                
                <Button variant="ghost" size="icon">
                  <MoreVertical className="h-5 w-5" />
                </Button>
              </div>
              
              {/* Messages */}
              <div className="flex-1 p-4 overflow-auto bg-accent/10">
                {filteredMessages.length === 0 ? (
                  <div className="h-full flex flex-col items-center justify-center text-center p-4">
                    <p className="text-muted-foreground mb-2">
                      No messages yet with this user
                    </p>
                    <p className="text-sm">
                      Send a message to start the conversation
                    </p>
                  </div>
                ) : (
                  filteredMessages.map((msg, index) => (
                    <div
                      key={index}
                      className={`flex items-end gap-2 mb-4 ${
                        msg.sender === user?.id ? "justify-end" : ""
                      }`}
                    >
                      {msg.sender !== user?.id && (
                        <Avatar className="h-8 w-8">
                          <AvatarFallback className="text-xs">
                            {getInitials(
                              selectedUserDetails?.fullName || 
                              selectedUserDetails?.username || 
                              "User"
                            )}
                          </AvatarFallback>
                        </Avatar>
                      )}
                      
                      <div
                        className={`max-w-[80%] rounded-lg p-3 ${
                          msg.sender === user?.id
                            ? "bg-primary text-primary-foreground"
                            : "bg-secondary text-secondary-foreground"
                        }`}
                      >
                        <div>{msg.content}</div>
                        <div className={`text-xs mt-1 ${
                          msg.sender === user?.id
                            ? "text-primary-foreground/70"
                            : "text-secondary-foreground/70"
                        }`}>
                          {formatMessageDate(msg.timestamp)}
                        </div>
                      </div>
                    </div>
                  ))
                )}
                <div ref={messagesEndRef} />
              </div>
              
              {/* Message input */}
              <form onSubmit={handleSendMessage} className="p-3 border-t bg-card flex items-center gap-2">
                <Input
                  placeholder="Type a message..."
                  value={messageText}
                  onChange={(e) => setMessageText(e.target.value)}
                  className="flex-1"
                />
                <Button 
                  type="submit" 
                  size="icon" 
                  disabled={!messageText.trim() || status !== 'open'}
                >
                  {sendMessageMutation.isPending ? (
                    <Loader2 className="h-5 w-5 animate-spin" />
                  ) : (
                    <Send className="h-5 w-5" />
                  )}
                </Button>
              </form>
            </>
          ) : (
            <div className="h-full flex flex-col items-center justify-center p-4 text-center">
              <h3 className="text-lg font-medium mb-2">Select a conversation</h3>
              <p className="text-muted-foreground mb-4">
                Choose a client from the list to view your conversation
              </p>
            </div>
          )}
        </div>
      </div>
    </AdminLayout>
  );
}