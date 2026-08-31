import { Alert, Stack, Typography } from "@mui/material";
import { CippWizardStepButtons } from "./CippWizardStepButtons";
import CippFormComponent from "../CippComponents/CippFormComponent";
import { useWatch } from "react-hook-form";

export const CippAuthMethodStep = (props) => {
  const { formControl, onPreviousStep, onNextStep, currentStep } = props;

  const authMethod = useWatch({ control: formControl.control, name: "authMethod" });

  return (
    <Stack spacing={3}>
      <Stack spacing={2}>
        <Typography variant="h6" id="auth-method-heading">
          Authentication method
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Choose how CIPP authenticates its application registration to Microsoft. This determines
          whether a client secret is created during setup.
        </Typography>
        <CippFormComponent
          type="radio"
          name="authMethod"
          formControl={formControl}
          defaultValue="certificate"
          aria-labelledby="auth-method-heading"
          options={[
            {
              value: "certificate",
              label: "Certificate (recommended) - no client secret; CIPP generates and auto-rotates it.",
            },
            {
              value: "secret",
              label: "Client secret - a shared secret; newer Entra tenants may block creating one.",
            },
          ]}
        />
        {authMethod !== "secret" && (
          <Alert severity="info">
            CIPP generates a SAM certificate, registers it on the application, and uses it for every
            Graph and Exchange Online call. It rotates the certificate automatically before it expires,
            and no client secret is created - so there is no shared secret to leak. You can still add a
            client secret later from the setup wizard if you ever need to fall back.
          </Alert>
        )}
      </Stack>

      <CippWizardStepButtons
        currentStep={currentStep}
        onPreviousStep={onPreviousStep}
        onNextStep={onNextStep}
        formControl={formControl}
        noSubmitButton={true}
      />
    </Stack>
  );
};

export default CippAuthMethodStep;
