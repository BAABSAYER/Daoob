import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '@/hooks/use-auth';
import { useToast } from '@/hooks/use-toast';

export type WebSocketStatus = 'connecting' | 'open' | 'closed' | 'error';

export interface Message {
  id?: number;
  type: string;
  sender: number;
  receiver: number;
  content: string;
  timestamp: Date;
}

export function useWebSocket() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [status, setStatus] = useState<WebSocketStatus>('connecting');
  const { user } = useAuth();
  const { toast } = useToast();
  const wsRef = useRef<WebSocket | null>(null);

  // Initialize WebSocket connection
  useEffect(() => {
    if (!user) return;

    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${window.location.host}/ws`;

    const ws = new WebSocket(wsUrl);
    wsRef.current = ws;

    ws.onopen = () => {
      setStatus('open');
      // Authenticate the WebSocket connection
      ws.send(JSON.stringify({
        type: 'auth',
        userId: user.id,
      }));
    };

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        
        if (data.type === 'chat') {
          // Parse timestamp as Date object
          const message: Message = {
            ...data,
            timestamp: new Date(data.timestamp)
          };
          
          setMessages(prev => [...prev, message]);
        } else if (data.type === 'history') {
          // Parse timestamps in message history
          const history = data.messages.map((msg: any) => ({
            ...msg,
            timestamp: new Date(msg.timestamp)
          }));
          
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

  // Send message handler
  const sendMessage = useCallback((message: Message) => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(message));
      
      // Optimistically add the message to the UI
      setMessages(prev => [...prev, { ...message }]);
    } else {
      toast({
        title: 'Connection Error',
        description: 'Not connected to chat server. Please try again later.',
        variant: 'destructive',
      });
    }
  }, [toast]);

  return {
    status,
    messages,
    sendMessage,
  };
}