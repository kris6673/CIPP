import { Layout as DashboardLayout } from "/src/layouts/index.js";
import { CippTablePage } from "/src/components/CippComponents/CippTablePage.jsx";
import { Button } from "@mui/material";
import Link from "next/link";

const Page = () => {
  const pageTitle = "Rooms";

  return (
    <CippTablePage
      title={pageTitle}
      apiUrl="/api/ListRooms"
      apiData={{
        TenantFilter: "TenantFilter", // Ensures tenant-specific filtering
      }}
      apiDataKey="Results"
      queryKey="RoomsReport"
      simpleColumns={[
        "displayName",
        "building",
        "floorNumber",
        "capacity",
        "bookingType",
      ]}
      cardButton={
        <Button component={Link} href="/resources/management/add-room">
          Add Room
        </Button>
      }
    />
  );
};

Page.getLayout = (page) => <DashboardLayout>{page}</DashboardLayout>;

export default Page;