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

    // Get the server host and port either from environment or window location
    const host = import.meta.env.VITE_SERVER_HOST || window.location.hostname;
    const port = import.meta.env.VITE_SERVER_PORT || '5000';
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    
    // Use environment variables with fallbacks for local development
    const wsUrl = `${protocol}//${host}:${port}/ws`;
    console.log('Connecting to WebSocket at:', wsUrl);

    const ws = new WebSocket(wsUrl);
    wsRef.current = ws;

    ws.onopen = () => {
      setStatus('open');
      // Authenticate the WebSocket connection
      ws.send(JSON.stringify({
        type: 'auth',
        sender: user.id,
        receiver: 0,
        content: user.id.toString(),
        timestamp: new Date()
      }));
    };

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        
        if (data.type === 'message') {
          // Parse timestamp as Date object
          const message: Message = {
            id: data.id,
            senderId: data.sender,
            receiverId: data.receiver,
            content: data.content,
            timestamp: new Date(data.timestamp),
            read: data.read || false
          };
          
          // Store message in the appropriate conversation
          const conversationId = message.senderId === user.id 
            ? message.receiverId 
            : message.senderId;
            
          const existingConversation = conversationsRef.current.get(conversationId) || [];
          conversationsRef.current.set(conversationId, [...existingConversation, message]);
          
          setMessages(prev => [...prev, message]);
        } else if (data.type === 'history') {
          // Parse timestamps in message history
          const history = data.messages.map((msg: any) => ({
            ...msg,
            senderId: msg.senderId || msg.sender_id,
            receiverId: msg.receiverId || msg.receiver_id,
            timestamp: new Date(msg.timestamp || msg.createdAt || msg.created_at)
          }));
          
          // Group messages by conversation
          history.forEach((message: Message) => {
            const conversationId = message.senderId === user.id 
              ? message.receiverId 
              : message.senderId;
              
            const existingConversation = conversationsRef.current.get(conversationId) || [];
            conversationsRef.current.set(conversationId, [...existingConversation, message]);
          });
          
          setMessages(history);
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
        title: 'Connection Error',
        description: 'Failed to connect to chat server. Messages will be sent via REST API.',
        variant: 'destructive',
      });
    };

    // Cleanup function
    return () => {
      if (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING) {
        ws.close();
      }
    };
  }, [user, toast]);

  // Get conversation messages for a specific user
  const getConversationMessages = useCallback((recipientId: number) => {
    if (!user) return [];
    
    return messages.filter(msg => 
      (msg.senderId === user.id && msg.receiverId === recipientId) || 
      (msg.senderId === recipientId && msg.receiverId === user.id)
    ).sort((a, b) => {
      const dateA = a.timestamp ? a.timestamp.getTime() : a.createdAt ? new Date(a.createdAt).getTime() : 0;
      const dateB = b.timestamp ? b.timestamp.getTime() : b.createdAt ? new Date(b.createdAt).getTime() : 0;
      return dateA - dateB;
    });
  }, [user, messages]);

  // Send message handler
  const sendMessage = useCallback((recipientId: number, content: string) => {
    if (!user) return;
    
    const message: Message = {
      senderId: user.id,
      receiverId: recipientId,
      content,
      timestamp: new Date(),
      type: 'message'
    };
    
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(message));
      
      // Optimistically add the message to the UI
      const conversationId = recipientId;
      const existingConversation = conversationsRef.current.get(conversationId) || [];
      conversationsRef.current.set(conversationId, [...existingConversation, message]);
      
      setMessages(prev => [...prev, message]);
    } else {
      toast({
        title: 'Connection Error',
        description: 'Not connected to chat server. Message will be sent via REST API only.',
        variant: 'destructive',
      });
    }
  }, [user, toast]);

  return {
    status,
    messages,
    sendMessage,
    getConversationMessages,
  };
}