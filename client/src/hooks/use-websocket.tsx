import { useState, useEffect, useRef, useCallback } from 'react';
import { useAuth } from './use-auth';

type WebSocketStatus = 'connecting' | 'open' | 'closed' | 'error';

interface Message {
  id?: number;
  type: string;
  sender: number;
  receiver: number;
  content: string;
  timestamp: Date;
}

export function useWebSocket() {
  const { user } = useAuth();
  const [status, setStatus] = useState<WebSocketStatus>('closed');
  const [messages, setMessages] = useState<Message[]>([]);
  const socketRef = useRef<WebSocket | null>(null);

  // Connect to the WebSocket server
  const connect = useCallback(() => {
    if (!user) return;

    const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
    const wsUrl = `${protocol}//${window.location.host}/ws`;
    
    const socket = new WebSocket(wsUrl);
    socketRef.current = socket;
    setStatus('connecting');

    socket.onopen = () => {
      setStatus('open');
      // Send authentication message
      socket.send(JSON.stringify({
        type: 'auth',
        sender: user.id,
        receiver: 0,
        content: String(user.id),
        timestamp: new Date()
      }));
    };

    socket.onclose = () => {
      setStatus('closed');
    };

    socket.onerror = () => {
      setStatus('error');
    };

    socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data) as Message;
        setMessages((prev) => [...prev, data]);
      } catch (error) {
        console.error('Error parsing WebSocket message:', error);
      }
    };

    return () => {
      if (socket.readyState === WebSocket.OPEN) {
        socket.close();
      }
    };
  }, [user]);

  // Reconnect if the connection is closed
  useEffect(() => {
    if (status === 'closed' && user) {
      const timeoutId = setTimeout(() => {
        connect();
      }, 3000);
      return () => clearTimeout(timeoutId);
    }
  }, [status, connect, user]);

  // Initial connection
  useEffect(() => {
    connect();
    return () => {
      if (socketRef.current && socketRef.current.readyState === WebSocket.OPEN) {
        socketRef.current.close();
      }
    };
  }, [connect]);

  // Send a message
  const sendMessage = useCallback((receiverId: number, content: string) => {
    if (!user || !socketRef.current || socketRef.current.readyState !== WebSocket.OPEN) {
      return false;
    }

    const message: Message = {
      type: 'message',
      sender: user.id,
      receiver: receiverId,
      content,
      timestamp: new Date()
    };

    socketRef.current.send(JSON.stringify(message));
    setMessages((prev) => [...prev, message]);
    return true;
  }, [user]);

  // Get messages for a specific conversation
  const getConversationMessages = useCallback((userId: number) => {
    return messages.filter((msg) => 
      (msg.sender === user?.id && msg.receiver === userId) || 
      (msg.sender === userId && msg.receiver === user?.id)
    );
  }, [messages, user]);

  return {
    status,
    sendMessage,
    messages,
    getConversationMessages
  };
}
