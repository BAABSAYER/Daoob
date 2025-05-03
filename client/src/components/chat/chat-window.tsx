import { useState, useEffect, useRef } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { useAuth } from "@/hooks/use-auth";
import { useWebSocket } from "@/hooks/use-websocket";
import { formatRelative } from "date-fns";
import { Loader2, Send } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { apiRequest, queryClient } from "@/lib/queryClient";

interface ChatWindowProps {
  recipientId: number;
}

interface Message {
  id: number;
  senderId: number;
  receiverId: number;
  content: string;
  read: boolean;
  createdAt: string;
}

interface MessageInputProps {
  onSend: (message: string) => void;
  isLoading: boolean;
}

function MessageInput({ onSend, isLoading }: MessageInputProps) {
  const [message, setMessage] = useState("");
  
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (message.trim()) {
      onSend(message);
      setMessage("");
    }
  };
  
  return (
    <form onSubmit={handleSubmit} className="bg-white p-3 shadow-md">
      <div className="flex items-center">
        <Input
          placeholder="Type a message..."
          className="flex-1 mx-2 bg-neutral-100 py-2 px-4 rounded-full"
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          disabled={isLoading}
        />
        <Button 
          type="submit"
          className="w-10 h-10 bg-secondary rounded-full flex items-center justify-center text-white p-0"
          disabled={!message.trim() || isLoading}
        >
          {isLoading ? (
            <Loader2 className="h-5 w-5 animate-spin" />
          ) : (
            <Send className="h-5 w-5" />
          )}
        </Button>
      </div>
    </form>
  );
}

export function ChatWindow({ recipientId }: ChatWindowProps) {
  const { user } = useAuth();
  const { sendMessage, getConversationMessages, status } = useWebSocket();
  const messagesEndRef = useRef<HTMLDivElement>(null);
  
  // Get user details of the recipient
  const { data: recipient, isLoading: isLoadingRecipient } = useQuery({
    queryKey: [`/api/users/${recipientId}`],
  });
  
  // Get messages from the API
  const { data: apiMessages, isLoading: isLoadingMessages } = useQuery<Message[]>({
    queryKey: [`/api/messages/${recipientId}`],
  });
  
  // Combine API messages with WebSocket messages
  const wsMessages = getConversationMessages(recipientId);
  const combinedMessages = [...(apiMessages || [])];
  
  // Deduplicate messages (WebSocket might have some of the same messages)
  const messageMap = new Map();
  combinedMessages.forEach(msg => messageMap.set(msg.id, msg));
  wsMessages.forEach(msg => {
    if (msg.id && !messageMap.has(msg.id)) {
      messageMap.set(msg.id, msg);
    } else if (!msg.id) {
      // Local messages without an ID (not yet saved to server)
      combinedMessages.push(msg as unknown as Message);
    }
  });
  
  // Sort messages by creation time
  const sortedMessages = [...messageMap.values()].sort((a, b) => {
    return new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();
  });
  
  // Mutation for sending messages
  const sendMessageMutation = useMutation({
    mutationFn: async (content: string) => {
      const result = await apiRequest("POST", "/api/messages", {
        receiverId: recipientId,
        content,
      });
      return result;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [`/api/messages/${recipientId}`] });
      queryClient.invalidateQueries({ queryKey: ['/api/conversations'] });
    }
  });
  
  // Handle sending a message
  const handleSendMessage = (content: string) => {
    if (status === 'open') {
      // Send via WebSocket for real-time delivery
      sendMessage(recipientId, content);
    }
    
    // Also send via REST API to ensure persistence
    sendMessageMutation.mutate(content);
  };
  
  // Scroll to bottom when messages change
  useEffect(() => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [sortedMessages]);
  
  const formatMessageTime = (timestamp: string) => {
    try {
      return formatRelative(new Date(timestamp), new Date());
    } catch (error) {
      return 'now';
    }
  };
  
  const isLoading = isLoadingMessages || isLoadingRecipient;
  
  return (
    <div className="flex flex-col h-full">
      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {isLoading ? (
          <div className="flex justify-center items-center h-full">
            <Loader2 className="h-8 w-8 animate-spin text-secondary" />
          </div>
        ) : sortedMessages.length === 0 ? (
          <div className="flex items-center justify-center h-full text-neutral-500">
            <p>No messages yet. Say hello!</p>
          </div>
        ) : (
          sortedMessages.map((message, index) => {
            const isSender = message.senderId === user?.id;
            
            return (
              <div 
                key={message.id || `local-${index}`}
                className={`flex ${isSender ? 'justify-end' : 'justify-start'}`}
              >
                <div 
                  className={`p-3 max-w-[75%] rounded-lg ${
                    isSender 
                      ? 'bg-secondary text-white rounded-tr-none' 
                      : 'bg-white rounded-tl-none shadow-sm'
                  }`}
                >
                  <p className={isSender ? 'text-white' : 'text-neutral-800'}>
                    {message.content}
                  </p>
                  <p className={`text-right text-xs mt-1 ${
                    isSender ? 'text-white/80' : 'text-neutral-500'
                  }`}>
                    {formatMessageTime(message.createdAt)}
                  </p>
                </div>
              </div>
            );
          })
        )}
        <div ref={messagesEndRef} />
      </div>
      
      {/* Message Input */}
      <MessageInput 
        onSend={handleSendMessage}
        isLoading={sendMessageMutation.isPending}
      />
    </div>
  );
}
