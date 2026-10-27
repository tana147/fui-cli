<template>
	<div class="wf-report-table-card">
    <div v-if="isPreviewSupported">
      <div class="wf-tcard-toolbar">
        <h3>Table preview</h3>
        <div class="wf-audit-sub">Table mode đang dùng row-level data, cột hiển thị, sort, filter riêng theo từng cột và footer summary.</div>
      </div>
      <div class="wf-report-matrix-wrap">
        <table class="wf-report-matrix-table" :class="{ 'wf-report-matrix-table--freeze-first': freezeFirstColumn }">
          <thead>
            <tr>
              <th
                v-for="(column, columnIndex) in previewColumns"
                :key="column.key"
                :style="columnStyle(column)"
                :class="{ 'wf-report-matrix-table__sticky': freezeFirstColumn && columnIndex === 0 }"
              >{{ column.label }}</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="(row, rowIndex) in previewRows"
              :key="resolveRowKey(row, rowIndex)"
              @click="$emit('row-click', row)"
            >
              <td
                v-for="(column, columnIndex) in previewColumns"
                :key="column.key"
                :class="cellClass(column, row)"
                :style="columnStyle(column)"
                :data-sticky="freezeFirstColumn && columnIndex === 0 ? '1' : '0'"
              >
                {{ formatValue(row[column.key], column.type) }}
              </td>
            </tr>
          </tbody>
          <tfoot v-if="footerRow">
            <tr class="wf-report-table-footer">
              <td
                v-for="(column, columnIndex) in previewColumns"
                :key="'footer-' + column.key"
                class="wf-report-matrix-cell wf-report-matrix-cell--formula"
                :style="columnStyle(column)"
                :data-sticky="freezeFirstColumn && columnIndex === 0 ? '1' : '0'"
              >
                {{ formatFooterValue(column) }}
              </td>
            </tr>
          </tfoot>
        </table>
      </div>
    </div>
    <div v-else class="wf-report-empty-state">
      <v-icon size="24">mdi-table-large</v-icon>
      <strong>Chưa có dữ liệu để dựng data table</strong>
      <span>{{ previewDisabledMessage }}</span>
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-report-table-preview",
  props: {
    isPreviewSupported: { type: Boolean, default: false },
    previewColumns: { type: Array, default: function () { return []; } },
    previewRows: { type: Array, default: function () { return []; } },
    footerRow: { type: Object, default: null },
    freezeFirstColumn: { type: Boolean, default: true },
    previewDisabledMessage: { type: String, default: "" },
    formatValue: { type: Function, required: true },
    cellClass: { type: Function, required: true }
  },
  emits: ["row-click"],
  methods: {
    resolveRowKey: function (row, rowIndex) {
      if (row && row.sourceIndex !== undefined) {
        return String(row.sourceIndex) + "-" + String(rowIndex);
      }
      return String(rowIndex);
    },
    formatFooterValue: function (column) {
      if (!this.footerRow) {
        return "-";
      }
      return this.formatValue(this.footerRow[column.key], column.type);
    },
    columnStyle: function (column) {
      var width = column && column.width ? Number(column.width) : 0;
      if (!width) {
        return {};
      }
      return {
        minWidth: String(width) + "px",
        width: String(width) + "px"
      };
    }
  }
	}
</script>