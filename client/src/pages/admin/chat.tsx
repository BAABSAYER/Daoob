import { useEffect, useRef, useState } from "react";
import { useParams } from "wouter";
import { useQuery, useMutation } from "@tanstack/react-query";
import { AdminLayout } from "@/components/admin-layout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Send } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { useAuth } from "@/hooks/use-auth";
import { Message } from "@shared/schema";

export default function AdminChat() {
  const { userId } = useParams<{ userId: string }>();
  const { user } = useAuth();
  const [message, setMessage] = useState("");
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Get chat user details
  const { data: chatUser, isLoading: isLoadingUser } = useQuery({
    queryKey: ["/api/users", userId],
    enabled: !!userId,
  });

  // Get messages between admin and this user
  const { data: messages, isLoading: isLoadingMessages } = useQuery({
    queryKey: ["/api/messages", userId],
    enabled: !!userId && !!user,
    refetchInterval: 5000, // Poll for new messages every 5 seconds
  });

  // Send message mutation
  const sendMessageMutation = useMutation({
    mutationFn: async (content: string) => {
      const payload = {
        senderId: user?.id,
        receiverId: parseInt(userId),
        content,
      };
      const res = await apiRequest("POST", "/api/messages", payload);
      return await res.json();
    },
    onSuccess: () => {
      // Invalidate the messages query to refetch
      queryClient.invalidateQueries({ queryKey: ["/api/messages", userId] });
      setMessage("");
    },
  });

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (message.trim()) {
      sendMessageMutation.mutate(message);
    }
  };

  // Scroll to bottom of messages when they change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  return (
    <AdminLayout title={isLoadingUser ? "Loading..." : `Chat with ${chatUser?.fullName || chatUser?.username}`}>
      <div className="flex flex-col h-[calc(100vh-10rem)]">
        {/* Messages area */}
        <div className="flex-1 overflow-y-auto mb-4 p-4 border rounded-md bg-card">
          {isLoadingMessages ? (
            <div className="space-y-4">
              <Skeleton className="h-12 w-3/4" />
              <Skeleton className="h-12 w-3/4 ml-auto" />
              <Skeleton className="h-12 w-2/4" />
            </div>
          ) : messages && messages.length > 0 ? (
            <div className="space-y-4">
              {messages.map((msg: Message) => (
                <div
                  key={msg.id}
                  className={`flex ${
                    msg.senderId === user?.id ? "justify-end" : "justify-start"
                  }`}
                >
                  <div
                    className={`max-w-[70%] p-3 rounded-lg ${
                      msg.senderId === user?.id
                        ? "bg-primary text-primary-foreground"
                        : "bg-muted"
                    }`}
                  >
                    <p>{msg.content}</p>
                    <p className="text-xs opacity-70 mt-1">
                      {new Date(msg.createdAt).toLocaleTimeString([], {
                        hour: "2-digit",
                        minute: "2-digit",
                      })}
                    </p>
                  </div>
                </div>
              ))}
              <div ref={messagesEndRef} />
            </div>
          ) : (
            <div className="h-full flex items-center justify-center">
              <p className="text-muted-foreground">
                No messages yet. Start the conversation!
              </p>
            </div>
          )}
        </div>

        {/* Message input */}
        <form onSubmit={handleSendMessage} className="flex gap-2">
          <Input
            placeholder="Type your message..."
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            className="flex-1"
          />
          <Button type="submit" disabled={!message.trim() || sendMessageMutation.isPending}>
            <Send className="h-4 w-4" />
            <span className="ml-2">Send</span>
          </Button>
        </form>
      </div>
    </AdminLayout>
  );
}