import { AdminLayout } from "@/components/admin-layout";
import { ChatList } from "@/components/chat/chat-list";

export default function AdminMessages() {
  return (
    <AdminLayout title="Messages">
      <div className="h-full">
        <ChatList />
      </div>
    </AdminLayout>
  );
}