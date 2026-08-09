import { useState } from "react";
import {
  Badge,
  Box,
  Button,
  Checkbox,
  Chip,
  Divider,
  IconButton,
  InputAdornment,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  ListSubheader,
  OutlinedInput,
  Stack,
  SvgIcon,
  Typography,
} from "@mui/material";
import {
  ArrowDownward,
  ArrowUpward,
  Check,
  FilterList,
  RestartAlt,
  Search,
  SwapVert,
  Sync,
  DataObject,
  FileDownload,
  PictureAsPdf,
} from "@mui/icons-material";
import { getCippTranslation } from "../../utils/get-cipp-translation";
import { CippBottomSheet } from "../CippComponents/CippBottomSheet";
import { useSheetHandoff } from "../../hooks/use-sheet-handoff";

// Presentational mobile controls for the card list. All filter/sort/visibility state and
// handlers are owned by CIPPTableToptoolbar (the same instance the desktop toolbar uses),
// so persistence, presets, and graph filters flow through exactly one code path.
export const CippMobileTableControls = (props) => {
  const {
    table,
    searchValue,
    onSearchChange,
    onRefresh,
    isRefreshing = false,
    selectionEnabled = false,
    selectMode = false,
    onSelectModeChange,
    selectModeLocked = false,
    customBulkActions = [],
    onBulkAction,
    graphPresetItems = [],
    tablePresetItems = [],
    activeFilters = { graph: null, table: null },
    activeSlotCount = 0,
    presetKey,
    onPresetClick,
    onResetFilters,
    onEditGraphFilters,
    columnItems = [],
    onToggleColumn,
    exportEnabled = false,
    onExportCsv,
    onExportPdf,
    onViewApiResponse,
    fixedChrome = true,
    queueTracker,
  } = props;

  const [sortOpen, setSortOpen] = useState(false);
  const [filterOpen, setFilterOpen] = useState(false);
  const [bulkOpen, setBulkOpen] = useState(false);
  // Graph filters, the API-response drawer and bulk dialogs are all Modals; let the sheet
  // finish closing before they mount (see useSheetHandoff).
  const filterSheet = useSheetHandoff(() => setFilterOpen(false));
  const bulkSheet = useSheetHandoff(() => setBulkOpen(false));

  const sorting = table.getState().sorting ?? [];
  const sortableColumns = table
    .getAllColumns()
    .filter((column) => !column.id.startsWith("mrt-") && column.getCanSort());

  // Tap cycles: none -> asc -> desc -> none. Single-column sort — replaces, not appends.
  const cycleSort = (columnId) => {
    const current = sorting.find((s) => s.id === columnId);
    if (!current) {
      table.setSorting([{ id: columnId, desc: false }]);
    } else if (!current.desc) {
      table.setSorting([{ id: columnId, desc: true }]);
    } else {
      table.setSorting([]);
    }
  };

  const selectedCount = table.getSelectedRowModel().rows.length;
  const totalCount = table.getFilteredRowModel().rows.length;
  const enabledBulkActions = customBulkActions.filter((action) => !action.disabled);

  const renderPresetChips = (items, layer) => (
    <Stack direction="row" useFlexGap flexWrap="wrap" spacing={1} sx={{ px: 2.25, py: 1 }}>
      {items.map((filter) => {
        const key = presetKey(filter);
        const active = activeFilters[layer]?.id === key;
        return (
          <Chip
            key={key}
            label={filter.filterName}
            color={active ? "primary" : "default"}
            variant={active ? "filled" : "outlined"}
            icon={active ? <Check /> : undefined}
            onClick={() => onPresetClick(filter)}
            sx={{ height: 36, borderRadius: 999 }}
          />
        );
      })}
    </Stack>
  );

  return (
    <>
      <Box
        sx={{
          position: "sticky",
          top: 0,
          zIndex: 10,
          display: "flex",
          gap: 1,
          px: 1,
          py: 1,
          bgcolor: "background.default",
          borderBottom: 1,
          borderColor: "divider",
        }}
      >
        <OutlinedInput
          fullWidth
          type="search"
          placeholder="Search…"
          value={searchValue}
          onChange={onSearchChange}
          inputProps={{ enterKeyHint: "search", "aria-label": "Search" }}
          startAdornment={
            <InputAdornment position="start">
              <Search fontSize="small" />
            </InputAdornment>
          }
          sx={{ minHeight: 44, flex: 1, minWidth: 0 }}
        />
        {selectionEnabled && !selectModeLocked && (
          <Button
            variant="outlined"
            color="inherit"
            onClick={() => onSelectModeChange?.(!selectMode)}
            sx={{ minHeight: 44, flexShrink: 0, px: 1.5, borderColor: "divider" }}
          >
            {selectMode ? "Cancel" : "Select"}
          </Button>
        )}
        <IconButton
          aria-label="Sort"
          onClick={() => setSortOpen(true)}
          sx={{
            minWidth: 44,
            minHeight: 44,
            border: 1,
            borderColor: sorting.length ? "primary.main" : "divider",
            borderRadius: 1,
            color: sorting.length ? "primary.main" : "inherit",
            flexShrink: 0,
          }}
        >
          <SwapVert fontSize="small" />
        </IconButton>
        <IconButton
          aria-label="Filters"
          onClick={() => setFilterOpen(true)}
          sx={{
            minWidth: 44,
            minHeight: 44,
            border: 1,
            borderColor: activeSlotCount > 0 ? "primary.main" : "divider",
            borderRadius: 1,
            color: activeSlotCount > 0 ? "primary.main" : "inherit",
            flexShrink: 0,
          }}
        >
          <Badge badgeContent={activeSlotCount} color="primary">
            <FilterList fontSize="small" />
          </Badge>
        </IconButton>
      </Box>
      {queueTracker && <Box sx={{ px: 1.5, py: 0.5 }}>{queueTracker}</Box>}

      {/* Sort sheet — net-new on mobile: cards have no column headers to click */}
      <CippBottomSheet
        open={sortOpen}
        onClose={() => setSortOpen(false)}
        title="Sort by"
        footer={
          <Button fullWidth variant="contained" sx={{ minHeight: 44 }} onClick={() => setSortOpen(false)}>
            Done
          </Button>
        }
      >
        {sortableColumns.map((column) => {
          const current = sorting.find((s) => s.id === column.id);
          return (
            <ListItemButton
              key={column.id}
              onClick={() => cycleSort(column.id)}
              sx={{ minHeight: 48, color: current ? "primary.main" : "inherit" }}
            >
              <ListItemText
                primary={getCippTranslation(column.id)}
                primaryTypographyProps={{ fontWeight: current ? 600 : 400 }}
              />
              {current && (
                <SvgIcon fontSize="small" color="primary">
                  {current.desc ? <ArrowDownward /> : <ArrowUpward />}
                </SvgIcon>
              )}
            </ListItemButton>
          );
        })}
        {sorting.length > 0 && (
          <>
            <Divider />
            <ListItemButton onClick={() => table.setSorting([])} sx={{ minHeight: 48 }}>
              <ListItemIcon sx={{ minWidth: 40 }}>
                <RestartAlt fontSize="small" />
              </ListItemIcon>
              <ListItemText primary="Clear sorting" />
            </ListItemButton>
          </>
        )}
      </CippBottomSheet>

      {/* Filter sheet — presets first, then card fields, then table utilities */}
      <CippBottomSheet
        open={filterOpen}
        onClose={filterSheet.cancel}
        onExited={filterSheet.handleExited}
        title="Filters"
        footer={
          <Button fullWidth variant="contained" sx={{ minHeight: 44 }} onClick={() => setFilterOpen(false)}>
            Done
          </Button>
        }
      >
        {tablePresetItems.length > 0 && (
          <>
            <ListSubheader disableSticky sx={{ bgcolor: "transparent" }}>
              Presets
            </ListSubheader>
            {renderPresetChips(tablePresetItems, "table")}
          </>
        )}
        {graphPresetItems.length > 0 && (
          <>
            <ListSubheader disableSticky sx={{ bgcolor: "transparent" }}>
              Graph filters
            </ListSubheader>
            {renderPresetChips(graphPresetItems, "graph")}
          </>
        )}
        {columnItems.length > 0 && (
          <>
            <ListSubheader disableSticky sx={{ bgcolor: "transparent" }}>
              Fields shown
            </ListSubheader>
            {columnItems.map((column) => (
              <ListItemButton
                key={column.id}
                dense
                onClick={() => onToggleColumn(column.id, column.visible)}
                sx={{ minHeight: 44, py: 0 }}
              >
                <Checkbox checked={column.visible} size="small" sx={{ mr: 1 }} tabIndex={-1} />
                <ListItemText primary={getCippTranslation(column.id)} />
              </ListItemButton>
            ))}
          </>
        )}
        <Divider sx={{ my: 1 }} />
        <ListItemButton
          onClick={() => {
            onResetFilters();
            setFilterOpen(false);
          }}
          sx={{ minHeight: 48 }}
        >
          <ListItemIcon sx={{ minWidth: 40 }}>
            <RestartAlt fontSize="small" />
          </ListItemIcon>
          <ListItemText primary="Reset all filters" />
        </ListItemButton>
        {onEditGraphFilters && (
          <ListItemButton
            onClick={() => filterSheet.run(onEditGraphFilters)}
            sx={{ minHeight: 48 }}
          >
            <ListItemIcon sx={{ minWidth: 40 }}>
              <FilterList fontSize="small" />
            </ListItemIcon>
            <ListItemText primary="Edit graph filters" />
          </ListItemButton>
        )}
        {exportEnabled && (
          <>
            <ListItemButton onClick={onExportCsv} sx={{ minHeight: 48 }}>
              <ListItemIcon sx={{ minWidth: 40 }}>
                <FileDownload fontSize="small" />
              </ListItemIcon>
              <ListItemText primary="Export to CSV" />
            </ListItemButton>
            <ListItemButton onClick={onExportPdf} sx={{ minHeight: 48 }}>
              <ListItemIcon sx={{ minWidth: 40 }}>
                <PictureAsPdf fontSize="small" />
              </ListItemIcon>
              <ListItemText primary="Export to PDF" />
            </ListItemButton>
          </>
        )}
        <ListItemButton
          onClick={() => filterSheet.run(onViewApiResponse)}
          sx={{ minHeight: 48 }}
        >
          <ListItemIcon sx={{ minWidth: 40 }}>
            <DataObject fontSize="small" />
          </ListItemIcon>
          <ListItemText primary="View API response" />
        </ListItemButton>
        <ListItemButton
          disabled={isRefreshing}
          onClick={() => {
            onRefresh();
            setFilterOpen(false);
          }}
          sx={{ minHeight: 48 }}
        >
          <ListItemIcon sx={{ minWidth: 40 }}>
            <Sync fontSize="small" />
          </ListItemIcon>
          <ListItemText primary={isRefreshing ? "Refreshing…" : "Refresh data"} />
        </ListItemButton>
      </CippBottomSheet>

      {/* Bulk action bar — bottom, in thumb reach, instead of the desktop top-toolbar strip */}
      {selectMode && selectionEnabled && (
        <Box
          sx={{
            position: fixedChrome ? "fixed" : "sticky",
            left: 0,
            right: 0,
            bottom: 0,
            zIndex: (theme) => theme.zIndex.speedDial,
            display: "flex",
            alignItems: "center",
            gap: 1,
            px: 1.5,
            pt: 1.25,
            pb: "calc(env(safe-area-inset-bottom) + 12px)",
            bgcolor: "background.paper",
            borderTop: 1,
            borderColor: "divider",
          }}
        >
          <Typography variant="subtitle2" aria-live="polite" sx={{ flexShrink: 0 }}>
            {selectedCount} selected
          </Typography>
          <Button
            size="small"
            onClick={() => table.toggleAllRowsSelected(true)}
            sx={{ mr: "auto", flexShrink: 0 }}
          >
            Select all ({totalCount})
          </Button>
          {customBulkActions.length > 0 && (
            <Button
              variant="contained"
              disabled={selectedCount === 0 || enabledBulkActions.length === 0}
              onClick={() => setBulkOpen(true)}
              sx={{ minHeight: 40 }}
            >
              Actions
            </Button>
          )}
          {!selectModeLocked && (
            <Button
              variant="outlined"
              color="inherit"
              onClick={() => onSelectModeChange?.(false)}
              sx={{ minHeight: 40, borderColor: "divider" }}
            >
              Done
            </Button>
          )}
        </Box>
      )}

      {/* Bulk actions sheet — the same customBulkActions + dispatch as the desktop menu */}
      <CippBottomSheet
        open={bulkOpen}
        onClose={bulkSheet.cancel}
        onExited={bulkSheet.handleExited}
        title={`${selectedCount} selected · Bulk actions`}
      >
        {customBulkActions.map((action, index) => (
          <ListItemButton
            key={`mobile-bulk-${index}`}
            disabled={action.disabled}
            onClick={() => bulkSheet.run(() => onBulkAction(action))}
            sx={{ minHeight: 48 }}
          >
            <ListItemIcon sx={{ minWidth: 40 }}>
              <SvgIcon fontSize="small">{action.icon}</SvgIcon>
            </ListItemIcon>
            <ListItemText primary={action.label} />
          </ListItemButton>
        ))}
      </CippBottomSheet>
    </>
  );
};
