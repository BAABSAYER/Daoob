import { useParams } from "wouter";
import { useQuery } from "@tanstack/react-query";
import { useState, useEffect } from "react";
import { ArrowLeft, Phone, Video } from "lucide-react";
import { useLocation } from "wouter";
import { ChatWindow } from "@/components/chat/chat-window";

export default function Chat() {
  const params = useParams();
  const [, navigate] = useLocation();
  const userId = parseInt(params.userId);
  
  const { data: recipient, isLoading } = useQuery({
    queryKey: [`/api/users/${userId}`],
  });
  
  const handleBack = () => {
    navigate('/messages');
  };
  
  const [isOnline, setIsOnline] = useState(false);
  
  // Simulate online status for demo
  useEffect(() => {
    setIsOnline(Math.random() > 0.5);
  }, [userId]);
  
  // Get appropriate icon based on user type
  const getUserAvatar = () => {
    if (!recipient) return null;
    
    const iconColor = recipient.userType === 'vendor' ? 'text-primary' : 'text-secondary';
    const iconBg = recipient.userType === 'vendor' ? 'bg-primary/10' : 'bg-secondary/10';
    
    let icon;
    switch (recipient.userType) {
      case 'vendor':
        icon = (
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" className={iconColor} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <rect x="4" y="5" width="16" height="16" rx="2" />
            <path d="m9 10 2 2-2 2" />
            <path d="m13 10-2 2 2 2" />
          </svg>
        );
        break;
      default:
        icon = (
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" className={iconColor} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" />
            <circle cx="12" cy="7" r="4" />
          </svg>
        );
    }
    
    return (
      <div className={`w-10 h-10 ${iconBg} rounded-full flex items-center justify-center mr-3`}>
        {icon}
      </div>
    );
  };
  
  return (
    <div className="h-full w-full bg-neutral-100 flex flex-col">
      {/* Header */}
      <header className="bg-white py-3 px-4 shadow-sm flex items-center">
        <button onClick={handleBack} className="mr-3">
          <ArrowLeft className="h-5 w-5 text-neutral-800" />
        </button>
        <div className="flex items-center">
          {getUserAvatar()}
          <div>
            <p className="font-medium text-neutral-800">
              {isLoading ? "Loading..." : recipient?.fullName || recipient?.username || "User"}
            </p>
            <p className={`text-xs ${isOnline ? 'text-green-500' : 'text-neutral-500'}`}>
              {isOnline ? 'Online' : 'Offline'}
            </p>
          </div>
        </div>
        <div className="ml-auto flex space-x-3">
          <button className="w-8 h-8 bg-neutral-100 rounded-full flex items-center justify-center">
            <Phone className="h-4 w-4 text-neutral-600" />
          </button>
          <button className="w-8 h-8 bg-neutral-100 rounded-full flex items-center justify-center">
            <Video className="h-4 w-4 text-neutral-600" />
          </button>
        </div>
      </header>

      {/* Chat Content */}
      <ChatWindow recipientId={userId} />
    </div>
  );
}
