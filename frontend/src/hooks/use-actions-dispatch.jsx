import { useState } from "react";
import { CippApiDialog } from "../components/CippComponents/CippApiDialog";
import { useDialog } from "./use-dialog";

/**
 * Shared dispatch for a page-level `actions` array.
 *
 * The desktop ActionsMenu and the mobile page-actions sheet present the same actions two
 * ways; keeping the confirm-vs-run decision and the dialog wiring here is what stops the
 * two presentations from drifting apart.
 */
export const useActionsDispatch = ({ actions = [], data, queryKeys }) => {
  const [actionData, setActionData] = useState({ data: {}, action: {}, ready: false });
  const createDialog = useDialog();

  // Nullsafety for data: it can be undefined (still loading) or null (no data)
  const isDisabled = (action) => {
    if (!data) return true;
    if (action?.condition) return !action.condition(data);
    return false;
  };

  const visibleActions = actions?.filter((action) => !action.link || action.showInActionsMenu) ?? [];

  const dispatch = (action) => {
    setActionData({ data, action, ready: true });
    if (action?.noConfirm && action.customFunction) {
      action.customFunction(data, action, {});
    } else {
      createDialog.handleOpen();
    }
  };

  const dialog = actionData.ready ? (
    <CippApiDialog
      createDialog={createDialog}
      title="Confirmation"
      fields={actionData.action?.fields}
      api={actionData.action}
      row={actionData.data}
      relatedQueryKeys={queryKeys}
      {...actionData.action}
    />
  ) : null;

  return { visibleActions, isDisabled, dispatch, dialog };
};
