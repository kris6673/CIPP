import { useEffect } from "react";
import { useRouter } from "next/router";
import { useForm, useWatch } from "react-hook-form";
import { Box, Button, Container, IconButton, Stack, Tooltip, Typography } from "@mui/material";
import { Grid } from "@mui/system";
import { ArrowBack, InfoOutlined, Save } from "@mui/icons-material";
import { Layout as DashboardLayout } from "../../../layouts/index.js";
import { ApiGetCall, ApiPostCall } from "../../../api/ApiCall";
import { CippHead } from "../../../components/CippComponents/CippHead";
import CippFormComponent from "../../../components/CippComponents/CippFormComponent";
import { CippApiResults } from "../../../components/CippComponents/CippApiResults";
import CippButtonCard from "../../../components/CippCards/CippButtonCard";
import {
  CippSharePointTemplateBuilder,
  CippSharePointTemplateBuilderSkeleton,
  CippSharePointTemplateQuickStats,
  CippSharePointTemplateQuickStatsSkeleton,
  getSiteTemplateSaveIssues,
  getSiteLanguageOption,
  siteTemplateBlocksSave,
} from "../../../components/CippComponents/CippSharePointTemplateBuilder";

const emptyTemplate = {
  templateName: "",
  siteType: "sharePoint",
  overrideSiteType: false,
  createMissingGroups: false,
  skipIfExists: false,
  siteTemplates: [],
};

const Page = () => {
  const router = useRouter();
  const { template, copy } = router.query;
  const isEdit = !!template && !copy;
  const pageTitle = copy
    ? "Copy SharePoint Template"
    : isEdit
    ? "Edit SharePoint Template"
    : "Create SharePoint Template";

  const formControl = useForm({ mode: "onChange", defaultValues: emptyTemplate });

  const templateQuery = ApiGetCall({
    url: template ? `/api/ExecSharePointTemplate?Action=Get&TemplateId=${template}` : null,
    queryKey: template ? `ExecSharePointTemplate-${template}` : null,
    waiting: !!template,
    // Always reload the current template when opening the editor so a save made moments ago
    // isn't masked by a stale cache.
    staleTime: 0,
  });
  const templateData = templateQuery.data;
  // Show a skeleton on the first load of an existing template (no cached data yet).
  const isLoadingTemplate = !!template && templateQuery.isLoading;

  // Site-template fields that block Save (name, root perms, library names). Cards outline offenders in red.
  const siteTemplatesValue = useWatch({ control: formControl.control, name: "siteTemplates" });
  const siteTemplatesBlockSave = (siteTemplatesValue || []).some(siteTemplateBlocksSave);
  const siteTemplateSaveIssues = getSiteTemplateSaveIssues(siteTemplatesValue || []);

  const saveTemplate = ApiPostCall({
    relatedQueryKeys: ["ListSharePointTemplates", "ExecSharePointTemplate"],
  });

  // Hydrate the form when editing or copying an existing template. The Get action returns an
  // array of matching templates, so take the first entry. reset() alone doesn't re-run
  // validation, so trigger it afterwards to enable the Save button on a freshly-loaded edit.
  useEffect(() => {
    const result = Array.isArray(templateData) ? templateData[0] : templateData?.Results;
    if (!result) return;
    const normalizeSiteType = (value) =>
      value === "teams" || value?.value === "teams" ? "teams" : "sharePoint";
    formControl.reset({
      templateName: copy ? `${result.templateName || ""} (Copy)` : result.templateName || "",
      siteType: normalizeSiteType(result.siteType),
      overrideSiteType: !!result.overrideSiteType,
      createMissingGroups: !!result.createMissingGroups,
      skipIfExists: !!result.skipIfExists,
      siteTemplates: (result.siteTemplates || []).map((site) => ({
        ...site,
        siteType: normalizeSiteType(site.siteType),
        language: getSiteLanguageOption(site.language),
      })),
    });
    formControl.trigger();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [templateData, copy]);

  const handleSubmit = (payload) => {
    if (isEdit) payload.TemplateId = template;
    saveTemplate.mutate(
      {
        url: "/api/ExecSharePointTemplate?Action=Save",
        data: payload,
        queryKey: "ExecSharePointTemplate",
      },
      {
        onSuccess: () => {
          router.push("/teams-share/sharepoint-templates");
        },
      }
    );
  };

  return (
    <>
      <CippHead title={pageTitle} />
      <Box sx={{ flexGrow: 1, py: 3 }}>
        <Container maxWidth={false}>
          <Stack spacing={2}>
            <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
              <Button
                color="inherit"
                startIcon={<ArrowBack />}
                onClick={() => router.push("/teams-share/sharepoint-templates")}
              >
                Back
              </Button>
              <Typography variant="h4" sx={{ flexGrow: 1 }}>
                {pageTitle}
              </Typography>
            </Box>

            <Grid container spacing={2} alignItems="stretch">
              <Grid size={{ xs: 12, md: 8, lg: 9 }}>
                <CippButtonCard
                  title="Template Settings"
                  isFetching={isLoadingTemplate}
                  CardButton={
                    <Stack direction="row" spacing={2} alignItems="center">
                      <Button
                        variant="contained"
                        startIcon={<Save />}
                        onClick={formControl.handleSubmit(handleSubmit)}
                        disabled={
                          isLoadingTemplate ||
                          saveTemplate.isPending ||
                          siteTemplatesBlockSave ||
                          !formControl.formState.isValid
                        }
                      >
                        {saveTemplate.isPending ? "Saving..." : "Save Template"}
                      </Button>
                      {siteTemplatesBlockSave && (
                        <Tooltip
                          title={
                            <Box component="ul" sx={{ m: 0, pl: 2 }}>
                              {siteTemplateSaveIssues.map((issue) => (
                                <li key={issue}>{issue}</li>
                              ))}
                            </Box>
                          }
                        >
                          <IconButton
                            size="small"
                            aria-label="What needs fixing before save"
                            sx={{ color: "error.main" }}
                          >
                            <InfoOutlined fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      )}
                    </Stack>
                  }
                >
                  <Stack spacing={1}>
                    <CippFormComponent
                      type="textField"
                      label="Template Name"
                      name="templateName"
                      formControl={formControl}
                      validators={{ required: "A template name is required" }}
                    />
                    <CippFormComponent
                      type="switch"
                      label="Create groups if they do not exist"
                      name="createMissingGroups"
                      formControl={formControl}
                      helperText="Missing groups are created as security groups during deployment."
                    />
                    <CippFormComponent
                      type="switch"
                      label="Skip if exists"
                      name="skipIfExists"
                      formControl={formControl}
                      helperText="If a site or team with the same name already exists in the tenant, leave it untouched: no libraries or permissions are applied to it."
                    />
                  </Stack>
                </CippButtonCard>
              </Grid>
              <Grid size={{ xs: 12, md: 4, lg: 3 }}>
                {isLoadingTemplate ? (
                  <CippSharePointTemplateQuickStatsSkeleton />
                ) : (
                  <CippSharePointTemplateQuickStats formControl={formControl} />
                )}
              </Grid>
            </Grid>

            <CippApiResults apiObject={saveTemplate} />

            {isLoadingTemplate ? (
              <CippSharePointTemplateBuilderSkeleton />
            ) : (
              <CippSharePointTemplateBuilder formControl={formControl} />
            )}
          </Stack>
        </Container>
      </Box>
    </>
  );
};

Page.getLayout = (page) => <DashboardLayout>{page}</DashboardLayout>;

export default Page;
