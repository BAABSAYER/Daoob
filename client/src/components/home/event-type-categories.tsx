import { useLocation } from "wouter";
import { GlassWater, Cake, Briefcase, GraduationCap, Users } from "lucide-react";

export function EventTypeCategories() {
  const [, navigate] = useLocation();
  
  const eventTypes = [
    {
      name: "Wedding",
      icon: <GlassWater className="text-primary text-xl" />,
      bgColor: "bg-primary/10",
      queryParam: "wedding"
    },
    {
      name: "Birthday",
      icon: <Cake className="text-secondary text-xl" />,
      bgColor: "bg-secondary/10",
      queryParam: "birthday"
    },
    {
      name: "Corporate",
      icon: <Briefcase className="text-accent text-xl" />,
      bgColor: "bg-accent/10",
      queryParam: "corporate"
    },
    {
      name: "Graduation",
      icon: <GraduationCap className="text-green-600 text-xl" />,
      bgColor: "bg-green-100",
      queryParam: "graduation"
    },
    {
      name: "Social",
      icon: <Users className="text-blue-600 text-xl" />,
      bgColor: "bg-blue-100",
      queryParam: "social"
    }
  ];

  const handleCategoryClick = (eventType: string) => {
    navigate(`/vendors/all?eventType=${eventType}`);
  };

  return (
    <div className="px-5 py-4 bg-white">
      <h2 className="font-poppins font-semibold text-lg text-neutral-800 mb-3">Planning an event?</h2>
      <div className="flex overflow-x-auto scrollbar-hide space-x-4 pb-2">
        {eventTypes.map((type, index) => (
          <button 
            key={index}
            onClick={() => handleCategoryClick(type.queryParam)}
            className="flex-shrink-0 flex flex-col items-center"
          >
            <div className={`w-16 h-16 ${type.bgColor} rounded-full flex items-center justify-center mb-1`}>
              {type.icon}
            </div>
            <span className="text-xs text-neutral-700">{type.name}</span>
          </button>
        ))}
      </div>
    </div>
  );
}
