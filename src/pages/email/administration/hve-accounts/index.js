import { useMemo } from "react";
import { Layout as DashboardLayout } from "/src/layouts/index.js";
import { CippTablePage } from "/src/components/CippComponents/CippTablePage.jsx";
import { Edit, Add } from "@mui/icons-material";
import { Button } from "@mui/material";
import Link from "next/link";
import TrashIcon from "@heroicons/react/24/outline/TrashIcon";

const Page = () => {
  const pageTitle = "HVE Accounts";
  
  const actions = useMemo(() => [
    {
      label: "Edit HVE Account",
      link: "/email/administration/hve-accounts/edit?id=[Guid]",
      multiPost: false,
      postEntireRow: true,
      icon: <Edit />,
      color: "warning",
      condition: (row) => !row.IsDirSynced,
    },
    {
      label: "Remove HVE Account",
      type: "POST",
      url: "/api/RemoveMailUser",
      data: {
        GUID: "Guid",
        mail: "PrimarySmtpAddress",
      },
      confirmText:
        "Are you sure you want to delete this HVE account? This action cannot be undone.",
      color: "danger",
      icon: <TrashIcon />,
      condition: (row) => !row.IsDirSynced,
    },
  ], []);

  const simpleColumns = useMemo(() => [
    "DisplayName", 
    "PrimarySmtpAddress", 
    "RecipientTypeDetails",
    "ExternalDirectoryObjectId",
    "IsDirSynced"
  ], []);

  const cardButton = useMemo(() => (
    <Button
      component={Link}
      href="/email/administration/hve-accounts/add"
      startIcon={<Add />}
    >
      Add HVE Account
    </Button>
  ), []);

  return (
    <CippTablePage
      title={pageTitle}
      apiUrl="/api/ListMailUsers"
      apiData={{
        HVEOnly: true,
      }}
      actions={actions}
      simpleColumns={simpleColumns}
      cardButton={cardButton}
    />
  );
};

Page.getLayout = (page) => <DashboardLayout>{page}</DashboardLayout>;
export default Page;