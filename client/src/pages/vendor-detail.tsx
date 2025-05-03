import { useParams } from "wouter";
import { VendorDetails } from "@/components/vendor/vendor-details";
import { BottomNavigation } from "@/components/layout/bottom-navigation";

export default function VendorDetail() {
  const params = useParams();
  const vendorId = parseInt(params.id);
  
  return (
    <div className="pb-16">
      <VendorDetails vendorId={vendorId} />
      <BottomNavigation />
    </div>
  );
}
