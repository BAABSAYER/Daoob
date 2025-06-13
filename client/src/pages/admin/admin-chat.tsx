import { useParams } from "wouter";
import { AdminLayout } from "@/components/admin-layout";
import { ChatWindow } from "@/components/chat/chat-window";

export default function AdminChat() {
  const { userId } = useParams<{ userId: string }>();
  const userIdNumber = userId ? parseInt(userId, 10) : null;

  if (!userIdNumber) {
    return (
      <AdminLayout title="Chat">
        <div className="flex items-center justify-center h-64">
          <p className="text-muted-foreground">Invalid user ID</p>
        </div>
      </AdminLayout>
    );
  }

  return (
    <AdminLayout title="Chat">
      <div className="h-full">
        <ChatWindow recipientId={userIdNumber} />
      </div>
    </AdminLayout>
  );
}