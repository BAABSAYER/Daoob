import { useLocation } from "wouter";
import { SERVICE_CATEGORIES } from "@shared/schema";

// Service category card with image background
interface ServiceCategoryCardProps {
  title: string;
  imageUrl: string;
  category: string;
  onClick: (category: string) => void;
}

function ServiceCategoryCard({ title, imageUrl, category, onClick }: ServiceCategoryCardProps) {
  return (
    <button 
      className="bg-white rounded-xl shadow-sm overflow-hidden"
      onClick={() => onClick(category)}
    >
      <div className="h-24 relative">
        <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent flex items-end p-3">
          <span className="text-white font-medium">{title}</span>
        </div>
        {/* Use CSS background image instead of img for better control */}
        <div 
          className="w-full h-full bg-cover bg-center" 
          style={{ backgroundImage: `url(${imageUrl})` }}
        ></div>
      </div>
    </button>
  );
}

export function ServiceCategories() {
  const [, navigate] = useLocation();
  
  const categories = [
    {
      title: "Venues",
      category: SERVICE_CATEGORIES.VENUE,
      imageUrl: "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60"
    },
    {
      title: "Catering",
      category: SERVICE_CATEGORIES.CATERING,
      imageUrl: "https://images.unsplash.com/photo-1555244162-803834f70033?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60"
    },
    {
      title: "Photography",
      category: SERVICE_CATEGORIES.PHOTOGRAPHY,
      imageUrl: "https://images.unsplash.com/photo-1478146059778-26028b07395a?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60"
    },
    {
      title: "Decorations",
      category: SERVICE_CATEGORIES.DECORATION,
      imageUrl: "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60"
    }
  ];

  const handleCategoryClick = (category: string) => {
    navigate(`/vendors/${category}`);
  };

  return (
    <div className="bg-neutral-100 px-5 py-4">
      <div className="flex justify-between items-center mb-3">
        <h2 className="font-poppins font-semibold text-lg text-neutral-800">Services</h2>
        <button 
          className="text-sm text-secondary font-medium"
          onClick={() => navigate('/vendors/all')}
        >
          View all
        </button>
      </div>
      <div className="grid grid-cols-2 gap-3">
        {categories.map((category, index) => (
          <ServiceCategoryCard
            key={index}
            title={category.title}
            imageUrl={category.imageUrl}
            category={category.category}
            onClick={handleCategoryClick}
          />
        ))}
      </div>
    </div>
  );
}
