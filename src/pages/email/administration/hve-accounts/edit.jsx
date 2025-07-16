import { useForm } from "react-hook-form";
import { Layout as DashboardLayout } from "/src/layouts/index.js";
import CippFormPage from "/src/components/CippFormPages/CippFormPage";
import { useSettings } from "../../../../hooks/use-settings";
import { Alert, AlertTitle, Divider, Typography } from "@mui/material";
import { Grid } from "@mui/system";
import CippFormComponent from "/src/components/CippComponents/CippFormComponent";
import { useRouter } from "next/router";
import { ApiGetCall } from "/src/api/ApiCall";

const EditHVEAccount = () => {
  const tenantDomain = useSettings().currentTenant;
  const router = useRouter();
  const { id } = router.query;

  // Fetch existing HVE account data
  const { data: hveAccount, isLoading } = ApiGetCall({
    url: `/api/ListMailUsers`,
    queryKey: `HVEAccount-${id}`,
    queryData: {
      HVEOnly: true,
      GUID: id,
    },
    enabled: !!id,
  });

  const formControl = useForm({
    mode: "onChange",
    defaultValues: {
      displayName: "",
      firstName: "",
      lastName: "",
      hideFromGAL: false,
    },
  });

  // Update form values when data is loaded
  if (hveAccount && !isLoading) {
    const accountData = Array.isArray(hveAccount) ? hveAccount[0] : hveAccount;
    if (accountData) {
      formControl.reset({
        displayName: accountData.DisplayName || "",
        firstName: accountData.FirstName || "",
        lastName: accountData.LastName || "",
        hideFromGAL: accountData.HiddenFromAddressListsEnabled || false,
      });
    }
  }

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return (
    <CippFormPage
      formControl={formControl}
      queryKey="EditHVEAccount"
      title="Edit HVE Account"
      backButtonTitle="HVE Accounts Overview"
      postUrl="/api/EditMailUser"
      resetForm={false}
      customDataformatter={(values) => {
        return {
          tenantID: tenantDomain,
          GUID: id,
          DisplayName: values.displayName,
          FirstName: values.firstName,
          LastName: values.lastName,
          HideFromGAL: values.hideFromGAL,
        };
      }}
    >
      {/* HVE Configuration Information */}
      <Alert severity="info" sx={{ mb: 3 }}>
        <AlertTitle>HVE Configuration Information</AlertTitle>
        <Typography variant="body2" component="div">
          <strong>Server/Endpoint:</strong> smtp-hve.office365.com<br />
          <strong>Port:</strong> 587<br />
          <strong>TLS:</strong> STARTTLS<br />
          <strong>TLS Support:</strong> TLS 1.2 and TLS 1.3 are supported
        </Typography>
      </Alert>

      <Grid container spacing={2}>
        {/* Basic Information */}
        <Grid xs={12}>
          <Typography variant="h6" gutterBottom>
            Editable Information
          </Typography>
        </Grid>
        
        <Grid xs={12} md={6}>
          <CippFormComponent
            type="textField"
            label="Display Name"
            name="displayName"
            formControl={formControl}
            validators={{ required: "Display Name is required" }}
          />
        </Grid>

        <Grid xs={12} md={6}>
          <CippFormComponent
            type="textField"
            label="First Name"
            name="firstName"
            formControl={formControl}
          />
        </Grid>

        <Grid xs={12} md={6}>
          <CippFormComponent
            type="textField"
            label="Last Name"
            name="lastName"
            formControl={formControl}
          />
        </Grid>

        <Grid xs={12} md={6}>
          <CippFormComponent
            type="switch"
            label="Hide from Global Address List"
            name="hideFromGAL"
            formControl={formControl}
          />
        </Grid>
      </Grid>
    </CippFormPage>
  );
};

EditHVEAccount.getLayout = (page) => <DashboardLayout>{page}</DashboardLayout>;

export default EditHVEAccount;