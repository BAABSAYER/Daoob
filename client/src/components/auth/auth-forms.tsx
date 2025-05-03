import { useState } from "react";
import { useLocation } from "wouter";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { USER_TYPES, SERVICE_CATEGORIES } from "@shared/schema";
import { useAuth } from "@/hooks/use-auth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { AlertCircle, User, X } from "lucide-react";

// Login form validation schema
const loginSchema = z.object({
  username: z.string().min(1, "Username or email is required"),
  password: z.string().min(1, "Password is required"),
});

type LoginFormValues = z.infer<typeof loginSchema>;

// Client registration schema
const clientRegistrationSchema = z.object({
  fullName: z.string().min(1, "Full name is required"),
  email: z.string().email("Please enter a valid email"),
  username: z.string().min(3, "Username must be at least 3 characters"),
  password: z.string().min(8, "Password must be at least 8 characters"),
  phone: z.string().optional(),
  userType: z.literal(USER_TYPES.CLIENT),
});

type ClientRegistrationValues = z.infer<typeof clientRegistrationSchema>;

// Vendor registration schema
const vendorRegistrationSchema = z.object({
  email: z.string().email("Please enter a valid email"),
  username: z.string().min(3, "Username must be at least 3 characters"),
  password: z.string().min(8, "Password must be at least 8 characters"),
  businessName: z.string().min(1, "Business name is required"),
  phone: z.string().optional(),
  category: z.string().min(1, "Service category is required"),
  userType: z.literal(USER_TYPES.VENDOR),
});

type VendorRegistrationValues = z.infer<typeof vendorRegistrationSchema>;

export function LoginForm() {
  const { loginMutation } = useAuth();
  const [, navigate] = useLocation();
  
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = async (data: LoginFormValues) => {
    loginMutation.mutate(data, {
      onSuccess: () => {
        navigate("/");
      }
    });
  };

  return (
    <div className="p-6 bg-white rounded-lg shadow-sm">
      <h2 className="font-poppins font-semibold text-xl text-neutral-800 mb-6">Log in</h2>
      
      {loginMutation.isError && (
        <Alert variant="destructive" className="mb-4">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>
            {loginMutation.error?.message || "Login failed. Please check your credentials."}
          </AlertDescription>
        </Alert>
      )}
      
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <div>
          <Label htmlFor="username">Email or Username</Label>
          <Input
            id="username"
            placeholder="your@email.com or username"
            {...register("username")}
            className={errors.username ? "border-red-500" : ""}
          />
          {errors.username && (
            <p className="text-red-500 text-xs mt-1">{errors.username.message}</p>
          )}
        </div>
        
        <div>
          <div className="flex justify-between items-center">
            <Label htmlFor="password">Password</Label>
            <button type="button" className="text-sm text-secondary font-medium">
              Forgot password?
            </button>
          </div>
          <Input
            id="password"
            type="password"
            placeholder="••••••••"
            {...register("password")}
            className={errors.password ? "border-red-500" : ""}
          />
          {errors.password && (
            <p className="text-red-500 text-xs mt-1">{errors.password.message}</p>
          )}
        </div>
        
        <Button 
          type="submit" 
          className="w-full btn-primary"
          disabled={loginMutation.isPending}
        >
          {loginMutation.isPending ? "Logging in..." : "Log in"}
        </Button>
      </form>
    </div>
  );
}

export function ClientRegistrationForm({ onSwitch }: { onSwitch: () => void }) {
  const { registerMutation } = useAuth();
  const [, navigate] = useLocation();
  
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ClientRegistrationValues>({
    resolver: zodResolver(clientRegistrationSchema),
    defaultValues: {
      userType: USER_TYPES.CLIENT,
    },
  });

  const onSubmit = async (data: ClientRegistrationValues) => {
    registerMutation.mutate(data, {
      onSuccess: () => {
        navigate("/");
      }
    });
  };

  return (
    <div className="p-6 bg-white rounded-lg shadow-sm">
      <div className="flex justify-between items-center mb-6">
        <h2 className="font-poppins font-semibold text-xl text-neutral-800">Sign up as Client</h2>
        <button onClick={onSwitch} className="text-neutral-500">
          <X className="h-5 w-5" />
        </button>
      </div>
      
      {registerMutation.isError && (
        <Alert variant="destructive" className="mb-4">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>
            {registerMutation.error?.message || "Registration failed. Please try again."}
          </AlertDescription>
        </Alert>
      )}
      
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <div>
          <Label htmlFor="fullName">Full Name</Label>
          <Input
            id="fullName"
            placeholder="John Doe"
            {...register("fullName")}
            className={errors.fullName ? "border-red-500" : ""}
          />
          {errors.fullName && (
            <p className="text-red-500 text-xs mt-1">{errors.fullName.message}</p>
          )}
        </div>
        
        <div>
          <Label htmlFor="email">Email</Label>
          <Input
            id="email"
            type="email"
            placeholder="your@email.com"
            {...register("email")}
            className={errors.email ? "border-red-500" : ""}
          />
          {errors.email && (
            <p className="text-red-500 text-xs mt-1">{errors.email.message}</p>
          )}
        </div>
        
        <div>
          <Label htmlFor="username">Username</Label>
          <Input
            id="username"
            placeholder="johndoe"
            {...register("username")}
            className={errors.username ? "border-red-500" : ""}
          />
          {errors.username && (
            <p className="text-red-500 text-xs mt-1">{errors.username.message}</p>
          )}
        </div>
        
        <div>
          <Label htmlFor="password">Password</Label>
          <Input
            id="password"
            type="password"
            placeholder="At least 8 characters"
            {...register("password")}
            className={errors.password ? "border-red-500" : ""}
          />
          {errors.password && (
            <p className="text-red-500 text-xs mt-1">{errors.password.message}</p>
          )}
        </div>
        
        <div>
          <Label htmlFor="phone">Phone Number (Optional)</Label>
          <Input
            id="phone"
            placeholder="+1 (555) 000-0000"
            {...register("phone")}
            className={errors.phone ? "border-red-500" : ""}
          />
          {errors.phone && (
            <p className="text-red-500 text-xs mt-1">{errors.phone.message}</p>
          )}
        </div>
        
        <input type="hidden" {...register("userType")} />
        
        <Button 
          type="submit" 
          className="w-full btn-primary"
          disabled={registerMutation.isPending}
        >
          {registerMutation.isPending ? "Creating Account..." : "Create Account"}
        </Button>
        
        <p className="text-center text-xs text-neutral-600 mt-4">
          By signing up, you agree to our 
          <a href="#" className="text-secondary font-medium"> Terms of Service </a> 
          and 
          <a href="#" className="text-secondary font-medium"> Privacy Policy</a>.
        </p>
      </form>
    </div>
  );
}

export function VendorRegistrationForm({ onSwitch }: { onSwitch: () => void }) {
  const { registerMutation } = useAuth();
  const [, navigate] = useLocation();
  
  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<VendorRegistrationValues>({
    resolver: zodResolver(vendorRegistrationSchema),
    defaultValues: {
      userType: USER_TYPES.VENDOR,
    },
  });

  const onSubmit = async (data: VendorRegistrationValues) => {
    registerMutation.mutate(data, {
      onSuccess: () => {
        navigate("/");
      }
    });
  };

  return (
    <div className="p-6 bg-white rounded-lg shadow-sm">
      <div className="flex justify-between items-center mb-6">
        <h2 className="font-poppins font-semibold text-xl text-neutral-800">Sign up as Vendor</h2>
        <button onClick={onSwitch} className="text-neutral-500">
          <X className="h-5 w-5" />
        </button>
      </div>
      
      {registerMutation.isError && (
        <Alert variant="destructive" className="mb-4">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>
            {registerMutation.error?.message || "Registration failed. Please try again."}
          </AlertDescription>
        </Alert>
      )}
      
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <div>
          <Label htmlFor="businessName">Business Name</Label>
          <Input
            id="businessName"
            placeholder="Your Business LLC"
            {...register("businessName")}
            className={errors.businessName ? "border-red-500" : ""}
          />
          {errors.businessName && (
            <p className="text-red-500 text-xs mt-1">{errors.businessName.message}</p>
          )}
        </div>
        
        <div>
          <Label htmlFor="email">Business Email</Label>
          <Input
            id="email"
            type="email"
            placeholder="business@email.com"
            {...register("email")}
            className={errors.email ? "border-red-500" : ""}
          />
          {errors.email && (
            <p className="text-red-500 text-xs mt-1">{errors.email.message}</p>
          )}
        </div>
        
        <div>
          <Label htmlFor="username">Username</Label>
          <Input
            id="username"
            placeholder="businessname"
            {...register("username")}
            className={errors.username ? "border-red-500" : ""}
          />
          {errors.username && (
            <p className="text-red-500 text-xs mt-1">{errors.username.message}</p>
          )}
        </div>
        
        <div>
          <Label htmlFor="password">Password</Label>
          <Input
            id="password"
            type="password"
            placeholder="At least 8 characters"
            {...register("password")}
            className={errors.password ? "border-red-500" : ""}
          />
          {errors.password && (
            <p className="text-red-500 text-xs mt-1">{errors.password.message}</p>
          )}
        </div>
        
        <div>
          <Label htmlFor="phone">Business Phone (Optional)</Label>
          <Input
            id="phone"
            placeholder="+1 (555) 000-0000"
            {...register("phone")}
            className={errors.phone ? "border-red-500" : ""}
          />
          {errors.phone && (
            <p className="text-red-500 text-xs mt-1">{errors.phone.message}</p>
          )}
        </div>
        
        <div>
          <Label htmlFor="category">Service Category</Label>
          <Select 
            onValueChange={(value) => setValue("category", value)}
            defaultValue=""
          >
            <SelectTrigger 
              id="category"
              className={errors.category ? "border-red-500" : ""}
            >
              <SelectValue placeholder="Select service type" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={SERVICE_CATEGORIES.VENUE}>Venue</SelectItem>
              <SelectItem value={SERVICE_CATEGORIES.CATERING}>Catering</SelectItem>
              <SelectItem value={SERVICE_CATEGORIES.PHOTOGRAPHY}>Photography</SelectItem>
              <SelectItem value={SERVICE_CATEGORIES.DECORATION}>Decoration</SelectItem>
              <SelectItem value={SERVICE_CATEGORIES.ENTERTAINMENT}>Entertainment</SelectItem>
              <SelectItem value={SERVICE_CATEGORIES.OTHER}>Other</SelectItem>
            </SelectContent>
          </Select>
          {errors.category && (
            <p className="text-red-500 text-xs mt-1">{errors.category.message}</p>
          )}
        </div>
        
        <input type="hidden" {...register("userType")} />
        
        <Button 
          type="submit" 
          className="w-full bg-primary text-white font-semibold py-3 px-6 rounded-lg shadow hover:bg-primary/90 transition duration-200"
          disabled={registerMutation.isPending}
        >
          {registerMutation.isPending ? "Creating Account..." : "Create Vendor Account"}
        </Button>
        
        <p className="text-center text-xs text-neutral-600 mt-4">
          By signing up, you agree to our 
          <a href="#" className="text-primary font-medium"> Terms of Service </a> 
          and 
          <a href="#" className="text-primary font-medium"> Privacy Policy</a>.
        </p>
      </form>
    </div>
  );
}

export function AccountTypeSelection({ 
  onClientSelect, 
  onVendorSelect, 
  onClose 
}: { 
  onClientSelect: () => void, 
  onVendorSelect: () => void, 
  onClose: () => void 
}) {
  return (
    <div className="p-6 bg-white rounded-lg shadow-sm">
      <div className="flex justify-between items-center mb-6">
        <h2 className="font-poppins font-semibold text-xl text-neutral-800">Join as</h2>
        <button onClick={onClose} className="text-neutral-500">
          <X className="h-5 w-5" />
        </button>
      </div>
      
      <div className="grid grid-cols-1 gap-4 mb-6">
        <button 
          onClick={onClientSelect} 
          className="border border-neutral-300 rounded-xl p-4 text-left hover:border-secondary hover:bg-secondary/5 transition duration-200"
        >
          <div className="flex items-center">
            <div className="w-12 h-12 bg-secondary/10 rounded-full flex items-center justify-center mr-4">
              <User className="h-5 w-5 text-secondary" />
            </div>
            <div>
              <h3 className="font-poppins font-medium text-neutral-800">Client</h3>
              <p className="text-sm text-neutral-600">Looking to plan an event</p>
            </div>
          </div>
        </button>
        
        <button 
          onClick={onVendorSelect} 
          className="border border-neutral-300 rounded-xl p-4 text-left hover:border-primary hover:bg-primary/5 transition duration-200"
        >
          <div className="flex items-center">
            <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center mr-4">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" className="h-5 w-5 text-primary" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                <polyline points="9 22 9 12 15 12 15 22"></polyline>
              </svg>
            </div>
            <div>
              <h3 className="font-poppins font-medium text-neutral-800">Vendor</h3>
              <p className="text-sm text-neutral-600">Offer services to clients</p>
            </div>
          </div>
        </button>
      </div>
    </div>
  );
}
