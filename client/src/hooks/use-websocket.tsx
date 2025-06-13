import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '@/hooks/use-auth';
import { useToast } from '@/hooks/use-toast';

export type WebSocketStatus = 'connecting' | 'open' | 'closed' | 'error';

export interface Message {
  id?: number;
  senderId: number;
  receiverId: number;
  content: string;
  timestamp?: Date;
  createdAt?: string;
  read?: boolean;
  type?: string;
}

export function useWebSocket() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [status, setStatus] = useState<WebSocketStatus>('connecting');
  const { user } = useAuth();
  const { toast } = useToast();
  const wsRef = useRef<WebSocket | null>(null);
  const conversationsRef = useRef<Map<number, Message[]>>(new Map());

  // Initialize WebSocket connection
  useEffect(() => {
    if (!user) return;

    // Dynamic WebSocket URL based on current window location
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = window.location.hostname;
    
    // In production/Replit, we don't need to specify the port as it's handled by the proxy
    // For local development, use the port if it's not standard (80/443)
    const usePort = window.location.port && !['80', '443', ''].includes(window.location.port);
    const portSuffix = usePort ? `:${window.location.port}` : '';
    
    const wsUrl = `${protocol}//${host}${portSuffix}/ws`;
    console.log('Connecting to WebSocket at:', wsUrl);

    const ws = new WebSocket(wsUrl);
    wsRef.current = ws;

    ws.onopen = () => {
      setStatus('open');
      // Authenticate the WebSocket connection
      ws.send(JSON.stringify({
        type: 'auth',
        senderId: user.id,
        receiverId: 0,
        content: user.id.toString(),
        timestamp: new Date()
      }));
    };

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        
        if (data.type === 'message') {
          const newMessage: Message = {
            id: data.id,
            senderId: data.senderId,
            receiverId: data.receiverId,
            content: data.content,
            timestamp: new Date(data.timestamp),
            read: data.read || false
          };

          // Store in conversation map
          const otherUserId = data.senderId === user.id ? data.receiverId : data.senderId;
          const currentConversation = conversationsRef.current.get(otherUserId) || [];
          conversationsRef.current.set(otherUserId, [...currentConversation, newMessage]);

          setMessages(prev => [...prev, newMessage]);
        } else if (data.type === 'auth_success') {
          console.log('WebSocket authenticated successfully');
        } else if (data.type === 'error') {
          console.error('WebSocket error:', data.message);
          toast({
            title: "Connection Error",
            description: data.message,
            variant: "destructive",
          });
        }
      } catch (error) {
        console.error('Error parsing WebSocket message:', error);
      }
    };

    ws.onclose = () => {
      setStatus('closed');
    };

    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
      setStatus('error');
      toast({
        title: "Connection Error",
        description: "Failed to connect to chat server",
        variant: "destructive",
      });
    };

    return () => {
      ws.close();
    };
  }, [user, toast]);

  // Get messages for a specific conversation
  const getConversationMessages = useCallback((userId: number) => {
    if (!user) return [];
    
    return messages.filter(msg => 
      (msg.senderId === user.id && msg.receiverId === userId) ||
      (msg.senderId === userId && msg.receiverId === user.id)
    ).sort((a, b) => 
      new Date(a.timestamp || 0).getTime() - new Date(b.timestamp || 0).getTime()
    );
  }, [user, messages]);

  // Get all conversations (unique user pairs)
  const getConversations = useCallback(() => {
    if (!user) return [];
    
    const conversations = messages.reduce((acc, msg) => {
      const otherUserId = msg.senderId === user.id ? msg.receiverId : msg.senderId;
      if (!acc.some(conv => conv.userId === otherUserId)) {
        acc.push({ userId: otherUserId, lastMessage: msg });
      }
      return acc;
    }, [] as { userId: number; lastMessage: Message }[]);

    return conversations;
  }, [user, messages]);

  // Send a message
  const sendMessage = useCallback((receiverId: number, content: string) => {
    if (!user || !wsRef.current || wsRef.current.readyState !== WebSocket.OPEN) {
      toast({
        title: "Connection Error",
        description: "Cannot send message - not connected",
        variant: "destructive",
      });
      return;
    }

    const message = {
      type: 'message',
      senderId: user.id,
      receiverId,
      content,
      timestamp: new Date()
    };

    wsRef.current.send(JSON.stringify(message));

    // Add to local state immediately for better UX
    const newMessage: Message = {
      senderId: user.id,
      receiverId,
      content,
      timestamp: new Date()
    };

    // Store in conversation map
    const currentConversation = conversationsRef.current.get(receiverId) || [];
    conversationsRef.current.set(receiverId, [...currentConversation, newMessage]);

    setMessages(prev => [...prev, newMessage]);
  }, [user, toast]);

  return {
    messages,
    status,
    sendMessage,
    getConversationMessages,
    getConversations
  };
}