import { ChatList } from "@/components/chat/chat-list";
import { Header } from "@/components/layout/header";
import { BottomNavigation } from "@/components/layout/bottom-navigation";

export default function Messages() {
  
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
