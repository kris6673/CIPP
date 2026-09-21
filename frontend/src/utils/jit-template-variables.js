import { applyReportVariables } from '../components/CippPdf/reportTheme'

// Technician tokens for JIT Admin templates (#298). Resolved in the browser when a template is
// applied, so the requester sees the final username before submitting. Unknown %tokens% stay as
// written, same as applyReportVariables and Get-CIPPTextReplacement.
export const resolveJitTemplateVariables = (text, upn) => {
  if (!text) return text
  return applyReportVariables(text, {
    cipptechnician: upn?.split('@')[0] ?? '',
    cipptechnicianupn: upn ?? '',
  })
}
