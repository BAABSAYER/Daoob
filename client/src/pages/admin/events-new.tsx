import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { useToast } from "@/hooks/use-toast";
import { Loader2, Plus, Trash, PenLine, X, Check, Eye, EyeOff, ListPlus } from "lucide-react";
import { AdminLayout } from "@/components/admin-layout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { 
  Select, 
  SelectContent, 
  SelectItem, 
  SelectTrigger, 
  SelectValue 
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";

// Types from shared schema
type EventType = {
  id: number;
  name: string;
  description: string | null;
  icon: string | null;
  isActive: boolean;
  createdAt: string;
};

type QuestionnaireItem = {
  id: number;
  eventTypeId: number;
  questionText: string;
  questionType: string;
  options: string[] | null;
  required: boolean;
  displayOrder: number | null;
  createdAt: string;
};

type EventRequest = {
  id: number;
  clientId: number;
  eventTypeId: number;
  status: string;
  responses: Record<string, any>;
  eventDate: string | null;
  budget: number | null;
  specialRequests: string | null;
  createdAt: string;
};

type EventResponse = {
  id: number;
  requestId: number;
  adminId: number;
  message: string;
  createdAt: string;
};

type Quotation = {
  id: number;
  eventRequestId: number;
  adminId: number;
  totalPrice: number;
  details: {
    description: string;
    items: any[];
  };
  status: string;
  expiryDate: string | null;
  createdAt: string;
};

// Define the page component
export default function EventsAdminPage() {
  const [activeTab, setActiveTab] = useState("event-types");
  
  return (
    <AdminLayout title="Event Management">
      <Tabs
        defaultValue="event-types"
        value={activeTab}
        onValueChange={setActiveTab}
        className="space-y-4"
      >
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="event-types">Event Types</TabsTrigger>
          <TabsTrigger value="requests">Event Requests</TabsTrigger>
        </TabsList>
        
        <TabsContent value="event-types" className="space-y-4">
          <EventTypesTab />
        </TabsContent>
        
        <TabsContent value="requests" className="space-y-4">
          <RequestsTab />
        </TabsContent>
      </Tabs>
    </AdminLayout>
  );
}

// Event Types Tab
function EventTypesTab() {
  const { toast } = useToast();
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [isQuestionsDialogOpen, setIsQuestionsDialogOpen] = useState(false);
  const [currentEventType, setCurrentEventType] = useState<EventType | null>(null);
  const [selectedEventTypeForQuestions, setSelectedEventTypeForQuestions] = useState<number | null>(null);
  
  // Form state
  const [eventTypeName, setEventTypeName] = useState("");
  const [eventTypeDescription, setEventTypeDescription] = useState("");
  const [eventTypeIcon, setEventTypeIcon] = useState("");
  const [eventTypeIsActive, setEventTypeIsActive] = useState(true);
  
  // Event types query
  const {
    data: eventTypes,
    isLoading,
    error,
  } = useQuery<EventType[]>({
    queryKey: ["/api/event-types"],
  });
  
  // Create mutation
  const createEventTypeMutation = useMutation({
    mutationFn: async (newEventType: Omit<EventType, "id" | "createdAt">) => {
      const res = await apiRequest("POST", "/api/event-types", newEventType);
      return await res.json();
    },
    onSuccess: () => {
      toast({
        title: "Event type created",
        description: "The event type has been created successfully.",
      });
      queryClient.invalidateQueries({ queryKey: ["/api/event-types"] });
      resetForm();
      setIsCreateDialogOpen(false);
    },
    onError: (error: Error) => {
      toast({
        title: "Failed to create event type",
        description: error.message,
        variant: "destructive",
      });
    },
  });
  
  // Update mutation
  const updateEventTypeMutation = useMutation({
    mutationFn: async (eventType: Partial<EventType> & { id: number }) => {
      const { id, ...data } = eventType;
      const res = await apiRequest("PATCH", `/api/event-types/${id}`, data);
      return await res.json();
    },
    onSuccess: () => {
      toast({
        title: "Event type updated",
        description: "The event type has been updated successfully.",
      });
      queryClient.invalidateQueries({ queryKey: ["/api/event-types"] });
      resetForm();
      setIsEditDialogOpen(false);
    },
    onError: (error: Error) => {
      toast({
        title: "Failed to update event type",
        description: error.message,
        variant: "destructive",
      });
    },
  });
  
  // Toggle active status mutation
  const toggleEventTypeStatusMutation = useMutation({
    mutationFn: async ({ id, isActive }: { id: number; isActive: boolean }) => {
      const res = await apiRequest("PATCH", `/api/event-types/${id}`, { isActive });
      return await res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/event-types"] });
    },
    onError: (error: Error) => {
      toast({
        title: "Failed to update status",
        description: error.message,
        variant: "destructive",
      });
    },
  });
  
  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    createEventTypeMutation.mutate({
      name: eventTypeName,
      description: eventTypeDescription || null,
      icon: eventTypeIcon || null,
      isActive: eventTypeIsActive,
    });
  };
  
  const handleEditSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentEventType) return;
    
    updateEventTypeMutation.mutate({
      id: currentEventType.id,
      name: eventTypeName,
      description: eventTypeDescription || null,
      icon: eventTypeIcon || null,
      isActive: eventTypeIsActive,
    });
  };
  
  const handleToggleStatus = (id: number, currentStatus: boolean) => {
    toggleEventTypeStatusMutation.mutate({
      id,
      isActive: !currentStatus,
    });
  };
  
  const handleEdit = (eventType: EventType) => {
    setCurrentEventType(eventType);
    setEventTypeName(eventType.name);
    setEventTypeDescription(eventType.description || "");
    setEventTypeIcon(eventType.icon || "");
    setEventTypeIsActive(eventType.isActive);
    setIsEditDialogOpen(true);
  };
  
  const handleManageQuestions = (eventTypeId: number) => {
    setSelectedEventTypeForQuestions(eventTypeId);
    setIsQuestionsDialogOpen(true);
  };
  
  const resetForm = () => {
    setEventTypeName("");
    setEventTypeDescription("");
    setEventTypeIcon("");
    setEventTypeIsActive(true);
    setCurrentEventType(null);
  };
  
  const handleCreateDialogClose = () => {
    resetForm();
    setIsCreateDialogOpen(false);
  };
  
  const handleEditDialogClose = () => {
    resetForm();
    setIsEditDialogOpen(false);
  };
  
  if (isLoading) {
    return (
      <div className="flex justify-center items-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }
  
  if (error) {
    return (
      <div className="text-center text-red-500">
        Error loading event types: {(error as Error).message}
      </div>
    );
  }
  
  return (
    <div>
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-2xl font-semibold">Event Types</h2>
        <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={() => setIsCreateDialogOpen(true)}>
              <Plus className="mr-2 h-4 w-4" /> Add Event Type
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Create New Event Type</DialogTitle>
              <DialogDescription>
                Add a new event type for clients to select from.
              </DialogDescription>
            </DialogHeader>
            <form onSubmit={handleCreateSubmit}>
              <div className="grid gap-4 py-4">
                <div className="grid gap-2">
                  <Label htmlFor="name">Name</Label>
                  <Input
                    id="name"
                    value={eventTypeName}
                    onChange={(e) => setEventTypeName(e.target.value)}
                    required
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="description">Description</Label>
                  <Textarea
                    id="description"
                    value={eventTypeDescription}
                    onChange={(e) => setEventTypeDescription(e.target.value)}
                    rows={3}
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="icon">Icon (emoji or symbol)</Label>
                  <Input
                    id="icon"
                    value={eventTypeIcon}
                    onChange={(e) => setEventTypeIcon(e.target.value)}
                    placeholder="Example: 🎂, 💍, 🎓"
                  />
                </div>
                <div className="flex items-center space-x-2">
                  <Switch
                    id="isActive"
                    checked={eventTypeIsActive}
                    onCheckedChange={setEventTypeIsActive}
                  />
                  <Label htmlFor="isActive">Active</Label>
                </div>
              </div>
              <DialogFooter>
                <Button 
                  type="button" 
                  variant="outline" 
                  onClick={handleCreateDialogClose}
                >
                  Cancel
                </Button>
                <Button 
                  type="submit" 
                  disabled={createEventTypeMutation.isPending}
                >
                  {createEventTypeMutation.isPending && (
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  )}
                  Create
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>
      
      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Icon</TableHead>
                <TableHead>Name</TableHead>
                <TableHead className="hidden md:table-cell">Description</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {eventTypes && eventTypes.length > 0 ? (
                eventTypes.map((eventType) => (
                  <TableRow key={eventType.id}>
                    <TableCell className="font-medium text-center text-xl">
                      {eventType.icon || "📄"}
                    </TableCell>
                    <TableCell className="font-medium">
                      {eventType.name}
                    </TableCell>
                    <TableCell className="hidden md:table-cell">
                      {eventType.description || "-"}
                    </TableCell>
                    <TableCell>
                      <Badge 
                        variant={eventType.isActive ? "default" : "secondary"}
                      >
                        {eventType.isActive ? "Active" : "Inactive"}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleToggleStatus(eventType.id, eventType.isActive)}
                          title={eventType.isActive ? "Deactivate" : "Activate"}
                        >
                          {eventType.isActive ? (
                            <EyeOff className="h-4 w-4" />
                          ) : (
                            <Eye className="h-4 w-4" />
                          )}
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleEdit(eventType)}
                          title="Edit event type"
                        >
                          <PenLine className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleManageQuestions(eventType.id)}
                          title="Manage questions"
                        >
                          <ListPlus className="h-4 w-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell colSpan={5} className="text-center h-24">
                    No event types found. Create your first event type to get started.
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
      
      {/* Edit Dialog */}
      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Event Type</DialogTitle>
            <DialogDescription>
              Update the details of this event type.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleEditSubmit}>
            <div className="grid gap-4 py-4">
              <div className="grid gap-2">
                <Label htmlFor="edit-name">Name</Label>
                <Input
                  id="edit-name"
                  value={eventTypeName}
                  onChange={(e) => setEventTypeName(e.target.value)}
                  required
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="edit-description">Description</Label>
                <Textarea
                  id="edit-description"
                  value={eventTypeDescription}
                  onChange={(e) => setEventTypeDescription(e.target.value)}
                  rows={3}
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="edit-icon">Icon (emoji or symbol)</Label>
                <Input
                  id="edit-icon"
                  value={eventTypeIcon}
                  onChange={(e) => setEventTypeIcon(e.target.value)}
                  placeholder="Example: 🎂, 💍, 🎓"
                />
              </div>
              <div className="flex items-center space-x-2">
                <Switch
                  id="edit-isActive"
                  checked={eventTypeIsActive}
                  onCheckedChange={setEventTypeIsActive}
                />
                <Label htmlFor="edit-isActive">Active</Label>
              </div>
            </div>
            <DialogFooter>
              <Button 
                type="button" 
                variant="outline" 
                onClick={handleEditDialogClose}
              >
                Cancel
              </Button>
              <Button 
                type="submit" 
                disabled={updateEventTypeMutation.isPending}
              >
                {updateEventTypeMutation.isPending && (
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                )}
                Save Changes
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
      
      {/* Questions Dialog */}
      <Dialog open={isQuestionsDialogOpen} onOpenChange={setIsQuestionsDialogOpen}>
        <DialogContent className="max-w-4xl">
          <DialogHeader>
            <DialogTitle>
              {eventTypes?.find(et => et.id === selectedEventTypeForQuestions)?.name || "Event"} Questions
            </DialogTitle>
            <DialogDescription>
              Manage questionnaire items for this event type
            </DialogDescription>
          </DialogHeader>
          
          <div className="py-4">
            <EventTypeQuestions 
              eventTypeId={selectedEventTypeForQuestions}
              onClose={() => setIsQuestionsDialogOpen(false)}
            />
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}

// Component to manage questions for a specific event type
function EventTypeQuestions({ eventTypeId, onClose }: { eventTypeId: number | null, onClose: () => void }) {
  const { toast } = useToast();
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [currentQuestion, setCurrentQuestion] = useState<QuestionnaireItem | null>(null);
  
  // Form state
  const [questionText, setQuestionText] = useState("");
  const [questionType, setQuestionType] = useState("text");
  const [questionOptions, setQuestionOptions] = useState("");
  const [questionRequired, setQuestionRequired] = useState(false);
  const [questionDisplayOrder, setQuestionDisplayOrder] = useState("");
  
  // Fetch questions for this event type
  const {
    data: questions,
    isLoading,
    error,
    refetch
  } = useQuery<QuestionnaireItem[]>({
    queryKey: ["/api/event-types", eventTypeId, "questions"],
    queryFn: async () => {
      if (!eventTypeId) return [];
      const res = await fetch(`/api/event-types/${eventTypeId}/questions`);
      if (!res.ok) throw new Error('Failed to fetch questions');
      return await res.json();
    },
    enabled: eventTypeId !== null,
  });
  
  // Create question mutation
  const createQuestionMutation = useMutation({
    mutationFn: async (newQuestion: Omit<QuestionnaireItem, "id" | "createdAt">) => {
      const res = await apiRequest("POST", "/api/questionnaire-items", newQuestion);
      return await res.json();
    },
    onSuccess: () => {
      toast({
        title: "Question created",
        description: "The questionnaire item has been created successfully.",
      });
      refetch();
      resetForm();
      setIsCreateDialogOpen(false);
    },
    onError: (error: Error) => {
      toast({
        title: "Failed to create question",
        description: error.message,
        variant: "destructive",
      });
    },
  });
  
  // Update question mutation
  const updateQuestionMutation = useMutation({
    mutationFn: async (question: Partial<QuestionnaireItem> & { id: number }) => {
      const { id, ...data } = question;
      const res = await apiRequest("PATCH", `/api/questionnaire-items/${id}`, data);
      return await res.json();
    },
    onSuccess: () => {
      toast({
        title: "Question updated",
        description: "The questionnaire item has been updated successfully.",
      });
      refetch();
      resetForm();
      setIsEditDialogOpen(false);
    },
    onError: (error: Error) => {
      toast({
        title: "Failed to update question",
        description: error.message,
        variant: "destructive",
      });
    },
  });
  
  // Delete question mutation
  const deleteQuestionMutation = useMutation({
    mutationFn: async (id: number) => {
      await apiRequest("DELETE", `/api/questionnaire-items/${id}`);
    },
    onSuccess: () => {
      toast({
        title: "Question deleted",
        description: "The questionnaire item has been deleted successfully.",
      });
      refetch();
    },
    onError: (error: Error) => {
      toast({
        title: "Failed to delete question",
        description: error.message,
        variant: "destructive",
      });
    },
  });
  
  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!eventTypeId) return;
    
    createQuestionMutation.mutate({
      eventTypeId,
      questionText,
      questionType,
      options: questionType === "text" || questionType === "number" || questionType === "date" 
        ? null 
        : questionOptions.split("\n").filter(option => option.trim() !== ""),
      required: questionRequired,
      displayOrder: questionDisplayOrder ? parseInt(questionDisplayOrder) : null,
    });
  };
  
  const handleEditSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentQuestion) return;
    
    updateQuestionMutation.mutate({
      id: currentQuestion.id,
      eventTypeId: currentQuestion.eventTypeId,
      questionText,
      questionType,
      options: questionType === "text" || questionType === "number" || questionType === "date" 
        ? null 
        : questionOptions.split("\n").filter(option => option.trim() !== ""),
      required: questionRequired,
      displayOrder: questionDisplayOrder ? parseInt(questionDisplayOrder) : null,
    });
  };
  
  const handleDelete = (id: number) => {
    if (window.confirm("Are you sure you want to delete this question? This action cannot be undone.")) {
      deleteQuestionMutation.mutate(id);
    }
  };
  
  const handleEdit = (question: QuestionnaireItem) => {
    setCurrentQuestion(question);
    setQuestionText(question.questionText);
    setQuestionType(question.questionType);
    setQuestionOptions(question.options ? question.options.join("\n") : "");
    setQuestionRequired(question.required);
    setQuestionDisplayOrder(question.displayOrder?.toString() || "");
    setIsEditDialogOpen(true);
  };
  
  const resetForm = () => {
    setQuestionText("");
    setQuestionType("text");
    setQuestionOptions("");
    setQuestionRequired(false);
    setQuestionDisplayOrder("");
    setCurrentQuestion(null);
  };
  
  if (isLoading) {
    return (
      <div className="flex justify-center items-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }
  
  if (error) {
    return (
      <div className="text-center text-red-500">
        Error loading questionnaire items: {(error as Error).message}
      </div>
    );
  }
  
  return (
    <div>
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-semibold">Questions</h2>
        <Button onClick={() => setIsCreateDialogOpen(true)}>
          <Plus className="mr-2 h-4 w-4" /> Add Question
        </Button>
      </div>
      
      <div className="relative overflow-x-auto rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Question</TableHead>
              <TableHead>Type</TableHead>
              <TableHead className="hidden md:table-cell">Required</TableHead>
              <TableHead>Order</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {questions && questions.length > 0 ? (
              questions.map((question) => (
                <TableRow key={question.id}>
                  <TableCell className="font-medium max-w-[250px] truncate">
                    {question.questionText}
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline">
                      {question.questionType.replace("_", " ")}
                    </Badge>
                  </TableCell>
                  <TableCell className="hidden md:table-cell">
                    {question.required ? (
                      <Check className="h-4 w-4 text-green-500" />
                    ) : (
                      <X className="h-4 w-4 text-gray-300" />
                    )}
                  </TableCell>
                  <TableCell>{question.displayOrder || "-"}</TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-2">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleEdit(question)}
                      >
                        <PenLine className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleDelete(question.id)}
                      >
                        <Trash className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={5} className="text-center h-24">
                  No questions found for this event type. Add your first question.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
      
      {/* Create Question Dialog */}
      <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Create New Question</DialogTitle>
            <DialogDescription>
              Add a question for clients to answer when selecting this event type.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleCreateSubmit}>
            <div className="grid gap-4 py-4">
              <div className="grid gap-2">
                <Label htmlFor="questionText">Question</Label>
                <Input
                  id="questionText"
                  value={questionText}
                  onChange={(e) => setQuestionText(e.target.value)}
                  required
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="questionType">Question Type</Label>
                <Select
                  value={questionType}
                  onValueChange={setQuestionType}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="text">Text</SelectItem>
                    <SelectItem value="single_choice">Single Choice</SelectItem>
                    <SelectItem value="multiple_choice">Multiple Choice</SelectItem>
                    <SelectItem value="number">Number</SelectItem>
                    <SelectItem value="date">Date</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              {(questionType === "single_choice" || questionType === "multiple_choice") && (
                <div className="grid gap-2">
                  <Label htmlFor="options">
                    Options (one per line)
                  </Label>
                  <Textarea
                    id="options"
                    value={questionOptions}
                    onChange={(e) => setQuestionOptions(e.target.value)}
                    rows={4}
                    required
                    placeholder="Enter each option on a new line"
                  />
                </div>
              )}
              <div className="grid gap-2">
                <Label htmlFor="displayOrder">Display Order (optional)</Label>
                <Input
                  id="displayOrder"
                  type="number"
                  min="1"
                  value={questionDisplayOrder}
                  onChange={(e) => setQuestionDisplayOrder(e.target.value)}
                  placeholder="Leave blank for default ordering"
                />
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="required"
                  checked={questionRequired}
                  onCheckedChange={(checked) => 
                    setQuestionRequired(checked === true)
                  }
                />
                <Label htmlFor="required">Required question</Label>
              </div>
            </div>
            <DialogFooter>
              <Button 
                type="button" 
                variant="outline" 
                onClick={() => setIsCreateDialogOpen(false)}
              >
                Cancel
              </Button>
              <Button 
                type="submit" 
                disabled={createQuestionMutation.isPending}
              >
                {createQuestionMutation.isPending && (
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                )}
                Create
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
      
      {/* Edit Question Dialog */}
      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Edit Question</DialogTitle>
            <DialogDescription>
              Update the details of this questionnaire item.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleEditSubmit}>
            <div className="grid gap-4 py-4">
              <div className="grid gap-2">
                <Label htmlFor="edit-questionText">Question</Label>
                <Input
                  id="edit-questionText"
                  value={questionText}
                  onChange={(e) => setQuestionText(e.target.value)}
                  required
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="edit-questionType">Question Type</Label>
                <Select
                  value={questionType}
                  onValueChange={setQuestionType}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="text">Text</SelectItem>
                    <SelectItem value="single_choice">Single Choice</SelectItem>
                    <SelectItem value="multiple_choice">Multiple Choice</SelectItem>
                    <SelectItem value="number">Number</SelectItem>
                    <SelectItem value="date">Date</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              {(questionType === "single_choice" || questionType === "multiple_choice") && (
                <div className="grid gap-2">
                  <Label htmlFor="edit-options">
                    Options (one per line)
                  </Label>
                  <Textarea
                    id="edit-options"
                    value={questionOptions}
                    onChange={(e) => setQuestionOptions(e.target.value)}
                    rows={4}
                    required
                    placeholder="Enter each option on a new line"
                  />
                </div>
              )}
              <div className="grid gap-2">
                <Label htmlFor="edit-displayOrder">Display Order (optional)</Label>
                <Input
                  id="edit-displayOrder"
                  type="number"
                  min="1"
                  value={questionDisplayOrder}
                  onChange={(e) => setQuestionDisplayOrder(e.target.value)}
                  placeholder="Leave blank for default ordering"
                />
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="edit-required"
                  checked={questionRequired}
                  onCheckedChange={(checked) => 
                    setQuestionRequired(checked === true)
                  }
                />
                <Label htmlFor="edit-required">Required question</Label>
              </div>
            </div>
            <DialogFooter>
              <Button 
                type="button" 
                variant="outline" 
                onClick={() => setIsEditDialogOpen(false)}
              >
                Cancel
              </Button>
              <Button 
                type="submit" 
                disabled={updateQuestionMutation.isPending}
              >
                {updateQuestionMutation.isPending && (
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                )}
                Save Changes
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}

// Requests Tab
function RequestsTab() {
  const { toast } = useToast();
  const [selectedStatus, setSelectedStatus] = useState<string>("");
  const [createQuotationDialogOpen, setCreateQuotationDialogOpen] = useState(false);
  const [currentRequest, setCurrentRequest] = useState<EventRequest | null>(null);
  
  // Form state for quotation
  const [quotationAmount, setQuotationAmount] = useState("");
  const [quotationDescription, setQuotationDescription] = useState("");
  const [quotationExpiryDate, setQuotationExpiryDate] = useState("");
  
  // Queries
  const {
    data: eventRequests,
    isLoading: isLoadingRequests,
    error: requestsError,
  } = useQuery<EventRequest[]>({
    queryKey: ["/api/event-requests", selectedStatus],
    queryFn: async () => {
      const url = selectedStatus 
        ? `/api/event-requests?status=${selectedStatus}`
        : '/api/event-requests';
      const res = await fetch(`/api${url}`);
      if (!res.ok) throw new Error('Failed to fetch event requests');
      return await res.json();
    },
  });
  
  const {
    data: eventTypes,
  } = useQuery<EventType[]>({
    queryKey: ["/api/event-types"],
  });
  
  const {
    data: userMap,
  } = useQuery<Record<number, { username: string; email: string }>>({
    queryKey: ["/api/users/map"],
    queryFn: async () => {
      const res = await fetch('/api/users/map');
      if (!res.ok) throw new Error('Failed to fetch user map');
      return await res.json();
    },
  });
  
  // Create quotation mutation
  const createQuotationMutation = useMutation({
    mutationFn: async (newQuotation: { 
      eventRequestId: number;
      totalAmount: number;
      description: string;
      expiryDate: string | null;
    }) => {
      const res = await apiRequest("POST", "/api/quotations", newQuotation);
      return await res.json();
    },
    onSuccess: () => {
      toast({
        title: "Quotation created",
        description: "The quotation has been created and sent to the client.",
      });
      queryClient.invalidateQueries({ queryKey: ["/api/event-requests"] });
      resetQuotationForm();
      setCreateQuotationDialogOpen(false);
    },
    onError: (error: Error) => {
      toast({
        title: "Failed to create quotation",
        description: error.message,
        variant: "destructive",
      });
    },
  });
  
  const resetQuotationForm = () => {
    setQuotationAmount("");
    setQuotationDescription("");
    setQuotationExpiryDate("");
    setCurrentRequest(null);
  };
  
  const handleQuotationDialogClose = () => {
    resetQuotationForm();
    setCreateQuotationDialogOpen(false);
  };
  
  const handleCreateQuotation = (request: EventRequest) => {
    setCurrentRequest(request);
    setCreateQuotationDialogOpen(true);
  };
  
  const handleQuotationSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentRequest) return;
    
    const amount = parseFloat(quotationAmount);
    if (isNaN(amount) || amount <= 0) {
      toast({
        title: "Invalid amount",
        description: "Please enter a valid amount greater than zero.",
        variant: "destructive",
      });
      return;
    }
    
    createQuotationMutation.mutate({
      eventRequestId: currentRequest.id,
      totalAmount: amount, // This will be converted to totalPrice on the server
      description: quotationDescription,
      expiryDate: quotationExpiryDate || null,
    });
  };
  
  const getEventTypeName = (id: number) => {
    if (!eventTypes) return "Unknown";
    const eventType = eventTypes.find(et => et.id === id);
    return eventType ? eventType.name : "Unknown";
  };
  
  const getClientName = (id: number) => {
    if (!userMap) return "Unknown";
    return userMap[id]?.username || "Unknown";
  };
  
  const formatDate = (dateString: string | null) => {
    if (!dateString) return "Not specified";
    return new Date(dateString).toLocaleDateString();
  };
  
  const formatCurrency = (amount: number | null) => {
    if (amount === null) return "Not specified";
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };
  
  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge variant="outline" className="bg-yellow-50 text-yellow-700 border-yellow-200">Pending</Badge>;
      case 'quoted':
        return <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">Quoted</Badge>;
      case 'accepted':
        return <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">Accepted</Badge>;
      case 'declined':
        return <Badge variant="outline" className="bg-red-50 text-red-700 border-red-200">Declined</Badge>;
      case 'completed':
        return <Badge variant="outline" className="bg-purple-50 text-purple-700 border-purple-200">Completed</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };
  
  return (
    <div>
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-2xl font-semibold">Event Requests</h2>
        <div className="flex gap-2">
          <Select
            value={selectedStatus}
            onValueChange={setSelectedStatus}
          >
            <SelectTrigger className="w-[180px]">
              <SelectValue placeholder="All Statuses" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Statuses</SelectItem>
              <SelectItem value="pending">Pending</SelectItem>
              <SelectItem value="quoted">Quoted</SelectItem>
              <SelectItem value="accepted">Accepted</SelectItem>
              <SelectItem value="declined">Declined</SelectItem>
              <SelectItem value="completed">Completed</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>
      
      {isLoadingRequests ? (
        <div className="flex justify-center items-center h-64">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </div>
      ) : requestsError ? (
        <div className="text-center text-red-500">
          Error loading event requests: {(requestsError as Error).message}
        </div>
      ) : eventRequests && eventRequests.length > 0 ? (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {eventRequests.map((request) => (
            <Card key={request.id} className="overflow-hidden">
              <CardHeader className="pb-2">
                <div className="flex justify-between items-start">
                  <div>
                    <CardTitle>
                      {getEventTypeName(request.eventTypeId)}
                    </CardTitle>
                    <CardDescription>
                      Request #{request.id} from {getClientName(request.clientId)}
                    </CardDescription>
                  </div>
                  {getStatusBadge(request.status)}
                </div>
              </CardHeader>
              <CardContent className="pb-2">
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="font-medium">Event Date:</span>
                    <span>{formatDate(request.eventDate)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="font-medium">Budget:</span>
                    <span>{formatCurrency(request.budget)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="font-medium">Submitted:</span>
                    <span>{formatDate(request.createdAt)}</span>
                  </div>
                  
                  {request.specialRequests && (
                    <div className="mt-2">
                      <p className="font-medium">Special Requests:</p>
                      <p className="text-sm mt-1">{request.specialRequests}</p>
                    </div>
                  )}
                </div>
              </CardContent>
              <div className="px-6 py-4 bg-muted/50">
                <div className="flex justify-between items-center">
                  <Button 
                    variant="outline" 
                    size="sm"
                    onClick={() => console.log("View detail")}
                  >
                    View Details
                  </Button>
                  
                  {request.status === 'pending' && (
                    <Button 
                      size="sm"
                      onClick={() => handleCreateQuotation(request)}
                    >
                      Create Quotation
                    </Button>
                  )}
                </div>
              </div>
            </Card>
          ))}
        </div>
      ) : (
        <div className="text-center py-12 bg-muted/20 rounded-lg">
          <h3 className="text-lg font-medium mb-2">No event requests found</h3>
          <p className="text-muted-foreground">
            When clients submit event requests, they will appear here.
          </p>
        </div>
      )}
      
      {/* Create Quotation Dialog */}
      <Dialog open={createQuotationDialogOpen} onOpenChange={setCreateQuotationDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create Quotation</DialogTitle>
            <DialogDescription>
              {currentRequest && (
                <span>
                  Create a quotation for {getEventTypeName(currentRequest.eventTypeId)} request
                  from {getClientName(currentRequest.clientId)}.
                </span>
              )}
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleQuotationSubmit}>
            <div className="grid gap-4 py-4">
              <div className="grid gap-2">
                <Label htmlFor="amount">Total Amount ($)</Label>
                <Input
                  id="amount"
                  type="number"
                  step="0.01"
                  min="0"
                  value={quotationAmount}
                  onChange={(e) => setQuotationAmount(e.target.value)}
                  required
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="description">Description</Label>
                <Textarea
                  id="description"
                  value={quotationDescription}
                  onChange={(e) => setQuotationDescription(e.target.value)}
                  rows={4}
                  required
                  placeholder="Describe what is included in this quotation..."
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="expiryDate">Expiry Date (Optional)</Label>
                <Input
                  id="expiryDate"
                  type="date"
                  value={quotationExpiryDate}
                  onChange={(e) => setQuotationExpiryDate(e.target.value)}
                  min={new Date().toISOString().split('T')[0]}
                />
              </div>
            </div>
            <DialogFooter>
              <Button 
                type="button" 
                variant="outline" 
                onClick={handleQuotationDialogClose}
              >
                Cancel
              </Button>
              <Button 
                type="submit" 
                disabled={createQuotationMutation.isPending}
              >
                {createQuotationMutation.isPending && (
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                )}
                Create Quotation
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}