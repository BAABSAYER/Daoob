import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { useToast } from "@/hooks/use-toast";
import { Loader2, Plus, Edit, Trash2, MessageSquare } from "lucide-react";
import { queryClient } from "@/lib/queryClient";

// Type definitions
type EventType = {
  id: number;
  name: string;
  description: string;
  icon: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
};

type QuestionnaireItem = {
  id: number;
  eventTypeId: number;
  questionText: string;
  questionType: string;
  options: any;
  required: boolean;
  displayOrder: number;
  eventType?: EventType;
};

export default function EventsAdminPage() {
  return (
    <div className="container mx-auto py-8">
      <h1 className="text-3xl font-bold mb-6">Event Types Management</h1>
      <EventTypesTab />
    </div>
  );
}

function EventTypesTab() {
  const { toast } = useToast();
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [questionsDialogOpen, setQuestionsDialogOpen] = useState(false);
  const [addQuestionDialogOpen, setAddQuestionDialogOpen] = useState(false);
  const [currentEventType, setCurrentEventType] = useState<EventType | null>(null);
  const [selectedEventTypeForQuestions, setSelectedEventTypeForQuestions] = useState<number | null>(null);
  
  // Form state
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    icon: "",
    isActive: true
  });

  // Question form state
  const [questionFormData, setQuestionFormData] = useState({
    questionText: "",
    questionType: "text",
    options: [],
    required: false,
    displayOrder: 1
  });

  // Queries
  const { data: eventTypes, isLoading: isLoadingEventTypes } = useQuery<EventType[]>({
    queryKey: ["/api/event-types"],
  });

  const { data: questionnaireItems } = useQuery<QuestionnaireItem[]>({
    queryKey: ["/api/questionnaire-items"],
  });

  // Mutations
  const createEventTypeMutation = useMutation({
    mutationFn: async (eventTypeData: Omit<EventType, 'id' | 'createdAt' | 'updatedAt'>) => {
      const res = await fetch('/api/event-types', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify(eventTypeData),
      });
      if (!res.ok) throw new Error('Failed to create event type');
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/event-types"] });
      setCreateDialogOpen(false);
      resetForm();
      toast({
        title: "Event type created",
        description: "The event type has been created successfully.",
      });
    },
  });

  const updateEventTypeMutation = useMutation({
    mutationFn: async ({ id, ...eventTypeData }: Partial<EventType> & { id: number }) => {
      const res = await fetch(`/api/event-types/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify(eventTypeData),
      });
      if (!res.ok) throw new Error('Failed to update event type');
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/event-types"] });
      setEditDialogOpen(false);
      resetForm();
      toast({
        title: "Event type updated",
        description: "The event type has been updated successfully.",
      });
    },
  });

  const deleteEventTypeMutation = useMutation({
    mutationFn: async (id: number) => {
      const res = await fetch(`/api/event-types/${id}`, {
        method: 'DELETE',
        credentials: 'include',
      });
      if (!res.ok) throw new Error('Failed to delete event type');
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/event-types"] });
      toast({
        title: "Event type deleted",
        description: "The event type has been deleted successfully.",
      });
    },
  });

  const createQuestionMutation = useMutation({
    mutationFn: async (questionData: any) => {
      const res = await fetch('/api/questionnaire-items', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify(questionData),
      });
      if (!res.ok) throw new Error('Failed to create question');
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/questionnaire-items"] });
      setAddQuestionDialogOpen(false);
      resetQuestionForm();
      toast({
        title: "Question created",
        description: "The question has been added successfully.",
      });
    },
  });

  const resetForm = () => {
    setFormData({
      name: "",
      description: "",
      icon: "",
      isActive: true
    });
    setCurrentEventType(null);
  };

  const resetQuestionForm = () => {
    setQuestionFormData({
      questionText: "",
      questionType: "text",
      options: [],
      required: false,
      displayOrder: 1
    });
  };

  const handleCreate = () => {
    setCreateDialogOpen(true);
    resetForm();
  };

  const handleEdit = (eventType: EventType) => {
    setCurrentEventType(eventType);
    setFormData({
      name: eventType.name,
      description: eventType.description || "",
      icon: eventType.icon || "",
      isActive: eventType.isActive
    });
    setEditDialogOpen(true);
  };

  const handleDelete = (eventType: EventType) => {
    if (confirm(`Are you sure you want to delete "${eventType.name}"?`)) {
      deleteEventTypeMutation.mutate(eventType.id);
    }
  };

  const handleViewQuestions = (eventTypeId: number) => {
    setSelectedEventTypeForQuestions(eventTypeId);
    setQuestionsDialogOpen(true);
  };

  const handleAddQuestion = () => {
    setAddQuestionDialogOpen(true);
    resetQuestionForm();
  };

  const handleSubmitQuestion = () => {
    if (!selectedEventTypeForQuestions) return;

    const questionData = {
      eventTypeId: selectedEventTypeForQuestions,
      questionText: questionFormData.questionText,
      questionType: questionFormData.questionType,
      options: questionFormData.options,
      required: questionFormData.required,
      displayOrder: questionFormData.displayOrder
    };

    createQuestionMutation.mutate(questionData);
  };

  const getQuestionsForEventType = (eventTypeId: number) => {
    return questionnaireItems?.filter(item => item.eventTypeId === eventTypeId) || [];
  };

  const handleSubmit = () => {
    if (editDialogOpen && currentEventType) {
      updateEventTypeMutation.mutate({
        id: currentEventType.id,
        ...formData
      });
    } else {
      createEventTypeMutation.mutate(formData);
    }
  };

  if (isLoadingEventTypes) {
    return (
      <div className="flex justify-center items-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-semibold">Event Types</h2>
        <Button onClick={handleCreate}>
          <Plus className="h-4 w-4 mr-2" />
          Add Event Type
        </Button>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {eventTypes?.map((eventType) => (
          <Card key={eventType.id} className="overflow-hidden">
            <CardHeader className="pb-2">
              <div className="flex justify-between items-start">
                <div>
                  <CardTitle className="flex items-center gap-2">
                    {eventType.icon && <span>{eventType.icon}</span>}
                    {eventType.name}
                  </CardTitle>
                  <CardDescription>
                    {eventType.description || "No description"}
                  </CardDescription>
                </div>
                <Badge variant={eventType.isActive ? "default" : "secondary"}>
                  {eventType.isActive ? "Active" : "Inactive"}
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="pb-2">
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="font-medium">Questions:</span>
                  <span>{getQuestionsForEventType(eventType.id).length}</span>
                </div>
                <div className="flex justify-between">
                  <span className="font-medium">Created:</span>
                  <span>{new Date(eventType.createdAt).toLocaleDateString()}</span>
                </div>
              </div>
            </CardContent>
            <CardFooter className="pt-2">
              <div className="flex gap-2 w-full">
                <Button
                  variant="outline"
                  size="sm"
                  className="flex-1"
                  onClick={() => handleViewQuestions(eventType.id)}
                >
                  <MessageSquare className="h-3 w-3 mr-1" />
                  Questions
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleEdit(eventType)}
                >
                  <Edit className="h-3 w-3" />
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleDelete(eventType)}
                  className="text-red-600 hover:text-red-700"
                >
                  <Trash2 className="h-3 w-3" />
                </Button>
              </div>
            </CardFooter>
          </Card>
        ))}
      </div>

      {/* Create/Edit Dialog */}
      <Dialog open={createDialogOpen || editDialogOpen} onOpenChange={(open) => {
        if (!open) {
          setCreateDialogOpen(false);
          setEditDialogOpen(false);
          resetForm();
        }
      }}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>
              {editDialogOpen ? "Edit Event Type" : "Create Event Type"}
            </DialogTitle>
            <DialogDescription>
              {editDialogOpen ? "Update the event type details." : "Add a new event type to the system."}
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Name</label>
              <Input
                value={formData.name}
                onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                placeholder="Enter event type name"
              />
            </div>
            
            <div className="space-y-2">
              <label className="text-sm font-medium">Description</label>
              <Textarea
                value={formData.description}
                onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                placeholder="Enter description"
                rows={3}
              />
            </div>
            
            <div className="space-y-2">
              <label className="text-sm font-medium">Icon (emoji)</label>
              <Input
                value={formData.icon}
                onChange={(e) => setFormData(prev => ({ ...prev, icon: e.target.value }))}
                placeholder="🎉"
              />
            </div>
            
            <div className="flex items-center space-x-2">
              <Switch
                checked={formData.isActive}
                onCheckedChange={(checked) => setFormData(prev => ({ ...prev, isActive: checked }))}
              />
              <label className="text-sm font-medium">Active</label>
            </div>
          </div>
          
          <div className="flex justify-end gap-2 pt-4">
            <Button variant="outline" onClick={() => {
              setCreateDialogOpen(false);
              setEditDialogOpen(false);
              resetForm();
            }}>
              Cancel
            </Button>
            <Button 
              onClick={handleSubmit}
              disabled={createEventTypeMutation.isPending || updateEventTypeMutation.isPending}
            >
              {createEventTypeMutation.isPending || updateEventTypeMutation.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin mr-2" />
              ) : null}
              {editDialogOpen ? "Update" : "Create"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Questions Dialog */}
      <Dialog open={questionsDialogOpen} onOpenChange={setQuestionsDialogOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Questionnaire Items</DialogTitle>
            <DialogDescription>
              {selectedEventTypeForQuestions && eventTypes && (
                <span>
                  Questions for {eventTypes.find(et => et.id === selectedEventTypeForQuestions)?.name}
                </span>
              )}
            </DialogDescription>
          </DialogHeader>
          
          <div className="flex justify-end mb-4">
            <Button onClick={handleAddQuestion}>
              <Plus className="h-4 w-4 mr-2" />
              Add Question
            </Button>
          </div>
          
          <div className="space-y-4 py-4 max-h-96 overflow-y-auto">
            {selectedEventTypeForQuestions && getQuestionsForEventType(selectedEventTypeForQuestions).length > 0 ? (
              getQuestionsForEventType(selectedEventTypeForQuestions).map((question, index) => (
                <div key={question.id} className="border rounded-lg p-4">
                  <div className="flex justify-between items-start mb-2">
                    <h4 className="font-medium">Question {index + 1}</h4>
                    <Badge variant="outline">{question.questionType}</Badge>
                  </div>
                  <p className="text-sm text-muted-foreground mb-2">
                    {question.questionText}
                  </p>
                  {question.options && (
                    <div className="text-xs text-muted-foreground">
                      Options: {JSON.stringify(question.options)}
                    </div>
                  )}
                  <div className="text-xs text-muted-foreground mt-2">
                    Required: {question.required ? "Yes" : "No"}
                  </div>
                </div>
              ))
            ) : (
              <div className="text-center py-8 text-muted-foreground">
                No questions configured for this event type.
              </div>
            )}
          </div>
        </DialogContent>
      </Dialog>

      {/* Add Question Dialog */}
      <Dialog open={addQuestionDialogOpen} onOpenChange={setAddQuestionDialogOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Add Question</DialogTitle>
            <DialogDescription>
              Create a new question for the event type questionnaire
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4 py-4">
            <div>
              <label className="text-sm font-medium mb-2 block">Question Text</label>
              <Textarea
                placeholder="Enter your question..."
                value={questionFormData.questionText}
                onChange={(e) => setQuestionFormData(prev => ({ ...prev, questionText: e.target.value }))}
                rows={3}
              />
            </div>

            <div>
              <label className="text-sm font-medium mb-2 block">Question Type</label>
              <select
                className="w-full p-2 border border-input rounded-md bg-background"
                value={questionFormData.questionType}
                onChange={(e) => setQuestionFormData(prev => ({ ...prev, questionType: e.target.value }))}
              >
                <option value="text">Text Input</option>
                <option value="number">Number Input</option>
                <option value="select">Multiple Choice</option>
                <option value="checkbox">Checkbox</option>
                <option value="textarea">Long Text</option>
                <option value="date">Date</option>
                <option value="time">Time</option>
              </select>
            </div>

            {questionFormData.questionType === 'select' && (
              <div>
                <label className="text-sm font-medium mb-2 block">Options (comma-separated)</label>
                <Input
                  placeholder="Option 1, Option 2, Option 3"
                  onChange={(e) => {
                    const options = e.target.value.split(',').map(opt => opt.trim()).filter(opt => opt);
                    setQuestionFormData(prev => ({ ...prev, options }));
                  }}
                />
              </div>
            )}

            <div className="flex items-center space-x-2">
              <Switch
                checked={questionFormData.required}
                onCheckedChange={(checked) => setQuestionFormData(prev => ({ ...prev, required: checked }))}
              />
              <label className="text-sm font-medium">Required field</label>
            </div>

            <div>
              <label className="text-sm font-medium mb-2 block">Display Order</label>
              <Input
                type="number"
                min="1"
                value={questionFormData.displayOrder}
                onChange={(e) => setQuestionFormData(prev => ({ ...prev, displayOrder: parseInt(e.target.value) || 1 }))}
              />
            </div>
          </div>
          
          <div className="flex justify-end gap-2 pt-4">
            <Button variant="outline" onClick={() => setAddQuestionDialogOpen(false)}>
              Cancel
            </Button>
            <Button 
              onClick={handleSubmitQuestion}
              disabled={createQuestionMutation.isPending || !questionFormData.questionText.trim()}
            >
              {createQuestionMutation.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin mr-2" />
              ) : null}
              Add Question
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}