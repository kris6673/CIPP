import { useForm } from "react-hook-form";
import { Layout as DashboardLayout } from "/src/layouts/index.js";
import CippFormPage from "/src/components/CippFormPages/CippFormPage";
import { useSettings } from "../../../../hooks/use-settings";
import { Alert, AlertTitle, Divider, Typography } from "@mui/material";
import { Grid } from "@mui/system";
import CippFormComponent from "/src/components/CippComponents/CippFormComponent";

const AddHVEAccount = () => {
  const tenantDomain = useSettings().currentTenant;

  const formControl = useForm({
    mode: "onChange",
    defaultValues: {
      displayName: "",
      name: "",
      primarySmtpAddress: "",
      password: "",
      hideFromGAL: false,
      firstName: "",
      lastName: "",
      alias: "",
    },
  });

  return (
    <CippFormPage
      formControl={formControl}
      queryKey="AddHVEAccount"
      title="Add HVE Account"
      backButtonTitle="HVE Accounts Overview"
      postUrl="/api/AddMailUser"
      resetForm={true}
      customDataformatter={(values) => {
        return {
          tenantID: tenantDomain,
          HVEAccount: true,
          DisplayName: values.displayName,
          Name: values.name || values.displayName,
          PrimarySmtpAddress: values.primarySmtpAddress,
          Password: values.password,
          HideFromGAL: values.hideFromGAL,
          FirstName: values.firstName,
          LastName: values.lastName,
          Alias: values.alias || values.name || values.displayName.replace(/\s+/g, ''),
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

      {/* Security Warning */}
      <Alert severity="warning" sx={{ mb: 3 }}>
        <AlertTitle>Important Security Notice</AlertTitle>
        <Typography variant="body2">
          Please ensure to check if the organization has Security Defaults enabled and manually exclude 
          this HVE account from Conditional Access policies after creation if necessary.
        </Typography>
      </Alert>

      <Grid container spacing={2}>
        {/* Basic Information */}
        <Grid xs={12}>
          <Typography variant="h6" gutterBottom>
            Basic Information
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
            label="Name"
            name="name"
            formControl={formControl}
            validators={{ required: "Name is required" }}
          />
        </Grid>

        <Grid xs={12} md={6}>
          <CippFormComponent
            type="textField"
            label="Primary SMTP Address"
            name="primarySmtpAddress"
            formControl={formControl}
            validators={{ 
              required: "Primary SMTP Address is required",
              pattern: {
                value: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
                message: "Please enter a valid email address"
              }
            }}
          />
        </Grid>

        <Grid xs={12} md={6}>
          <CippFormComponent
            type="password"
            label="Password"
            name="password"
            formControl={formControl}
            validators={{ 
              required: "Password is required",
              minLength: {
                value: 8,
                message: "Password must be at least 8 characters long"
              }
            }}
          />
        </Grid>

        <Divider sx={{ width: '100%', my: 2 }} />

        {/* Optional Information */}
        <Grid xs={12}>
          <Typography variant="h6" gutterBottom>
            Optional Information
          </Typography>
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
            type="textField"
            label="Alias"
            name="alias"
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

AddHVEAccount.getLayout = (page) => <DashboardLayout>{page}</DashboardLayout>;

export default AddHVEAccount;