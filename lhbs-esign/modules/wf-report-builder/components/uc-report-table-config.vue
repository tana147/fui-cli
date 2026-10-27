<template>
	<div class="wf-report-section">
    <div class="wf-report-section__title">Table columns</div>
    <div class="wf-report-section__desc">Data table đọc row-level data của dataset. Bạn có thể chọn cột, đổi thứ tự, đặt tên hiển thị và lọc theo từng cột.</div>

    <div class="wf-report-chip-list">
      <div
        v-for="column in availableColumns"
        :key="column.key"
        class="wf-report-chip"
        :class="{ active: isVisible(column.key) }"
        @click="$emit('toggle-column', column.key)"
      >
        <v-icon size="14">{{ isVisible(column.key) ? 'mdi-table-column-plus-after' : 'mdi-table-column-remove' }}</v-icon>
        <span>{{ column.label }}</span>
      </div>
    </div>

    <div class="wf-report-form-grid mt-3">
      <v-text-field
        :model-value="tableFilters.keyword"
        label="Lọc row theo từ khóa"
        variant="outlined"
        density="compact"
        hide-details="auto"
        @update:model-value="$emit('update:table-filters', mergeTableFilters('keyword', $event))"
      />
      <v-text-field
        :model-value="tableFilters.minValue"
        label="Giá trị tối thiểu"
        variant="outlined"
        density="compact"
        hide-details="auto"
        type="number"
        @update:model-value="$emit('update:table-filters', mergeTableFilters('minValue', $event))"
      />
      <v-select
        :model-value="tableFilters.deltaMode"
        :items="tableDeltaModeOptions"
        label="Lọc biến động"
        variant="outlined"
        density="compact"
        hide-details="auto"
        @update:model-value="$emit('update:table-filters', mergeTableFilters('deltaMode', $event))"
      />
      <v-select
        :model-value="tableSortBy"
        :items="tableSortOptions"
        label="Sort theo cột"
        variant="outlined"
        density="compact"
        hide-details="auto"
        @update:model-value="$emit('update:table-sort-by', $event)"
      />
      <v-select
        :model-value="tableSortDir"
        :items="tableSortDirectionOptions"
        label="Chiều sort"
        variant="outlined"
        density="compact"
        hide-details="auto"
        @update:model-value="$emit('update:table-sort-dir', $event)"
      />
      <v-text-field
        :model-value="tableTopN"
        label="Top N / Số dòng"
        variant="outlined"
        density="compact"
        hide-details="auto"
        type="number"
        @update:model-value="$emit('update:table-top-n', $event)"
      />
      <v-switch
        :model-value="freezeFirstColumn"
        inset
        color="primary"
        label="Freeze cột đầu"
        hide-details="auto"
        @update:model-value="$emit('update:freeze-first-column', $event)"
      />
    </div>

    <div class="wf-report-table-config-list" v-if="configuredColumns.length > 0">
      <div v-for="(column, index) in configuredColumns" :key="column.key" class="wf-report-table-config-row">
        <div class="wf-report-table-config__meta">
          <div class="wf-report-table-config__name">{{ column.rawLabel || column.label }}</div>
          <div class="wf-report-table-config__sub">{{ column.key }}</div>
        </div>
        <div class="wf-report-table-config__inputs">
          <v-text-field
            :model-value="columnLabels[column.key]"
            :label="'Tên hiển thị / alias'"
            variant="outlined"
            density="compact"
            hide-details="auto"
            :placeholder="column.label"
            @update:model-value="$emit('update:column-label', { key: column.key, value: $event })"
          />
          <div class="wf-report-table-config__filter">
            <v-text-field
              v-if="column.filterKind === 'text'"
              :model-value="columnFilters[column.key] || ''"
              :label="'Lọc riêng'"
              variant="outlined"
              density="compact"
              hide-details="auto"
              @update:model-value="$emit('update:column-filter', { key: column.key, value: $event })"
            />
            <div v-else-if="column.filterKind === 'number'" class="wf-report-table-config__range">
              <v-text-field
                :model-value="getFilterValue(column.key, 'min')"
                label="Từ số"
                variant="outlined"
                density="compact"
                hide-details="auto"
                type="number"
                @update:model-value="$emit('update:column-filter', { key: column.key, value: mergeRangeFilter(column.key, 'min', $event) })"
              />
              <v-text-field
                :model-value="getFilterValue(column.key, 'max')"
                label="Đến số"
                variant="outlined"
                density="compact"
                hide-details="auto"
                type="number"
                @update:model-value="$emit('update:column-filter', { key: column.key, value: mergeRangeFilter(column.key, 'max', $event) })"
              />
            </div>
            <div v-else-if="column.filterKind === 'date'" class="wf-report-table-config__range">
              <v-text-field
                :model-value="getFilterValue(column.key, 'from')"
                label="Từ ngày"
                variant="outlined"
                density="compact"
                hide-details="auto"
                type="date"
                @update:model-value="$emit('update:column-filter', { key: column.key, value: mergeRangeFilter(column.key, 'from', $event) })"
              />
              <v-text-field
                :model-value="getFilterValue(column.key, 'to')"
                label="Đến ngày"
                variant="outlined"
                density="compact"
                hide-details="auto"
                type="date"
                @update:model-value="$emit('update:column-filter', { key: column.key, value: mergeRangeFilter(column.key, 'to', $event) })"
              />
            </div>
            <div v-else-if="column.filterKind === 'status'" class="wf-report-table-config__status">
              <div
                v-for="option in column.options"
                :key="column.key + '-' + option"
                class="wf-report-chip"
                :class="{ active: isStatusSelected(column.key, option) }"
                @click="$emit('update:column-filter', { key: column.key, value: toggleStatusFilter(column.key, option) })"
              >
                <v-icon size="14">{{ isStatusSelected(column.key, option) ? 'mdi-checkbox-marked-circle-outline' : 'mdi-checkbox-blank-circle-outline' }}</v-icon>
                <span>{{ option }}</span>
              </div>
            </div>
          </div>
          <div class="wf-report-table-config__footer">
            <v-text-field
              :model-value="columnWidths[column.key] || ''"
              label="Width (px)"
              variant="outlined"
              density="compact"
              hide-details="auto"
              type="number"
              @update:model-value="$emit('update:column-width', { key: column.key, value: $event })"
            />
            <div class="wf-report-table-config__actions">
              <v-btn class="wf-btn wf-btn--icon-tool" size="small" variant="outlined" color="primary" :disabled="index === 0" @click="$emit('move-column-up', column.key)">
                <v-icon size="16">mdi-arrow-up</v-icon>
              </v-btn>
              <v-btn class="wf-btn wf-btn--icon-tool" size="small" variant="outlined" color="primary" :disabled="index === configuredColumns.length - 1" @click="$emit('move-column-down', column.key)">
                <v-icon size="16">mdi-arrow-down</v-icon>
              </v-btn>
              <div class="wf-report-table-config__order-text">{{ index + 1 }}/{{ configuredColumns.length }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-report-table-config",
  props: {
    availableColumns: { type: Array, default: function () { return []; } },
    configuredColumns: { type: Array, default: function () { return []; } },
    columnLabels: { type: Object, default: function () { return {}; } },
    columnFilters: { type: Object, default: function () { return {}; } },
    columnWidths: { type: Object, default: function () { return {}; } },
    tableFilters: { type: Object, default: function () { return {}; } },
    tableSortBy: { type: String, default: "" },
    tableSortDir: { type: String, default: "desc" },
    tableTopN: { type: [String, Number], default: 20 },
    freezeFirstColumn: { type: Boolean, default: true },
    tableSortOptions: { type: Array, default: function () { return []; } },
    tableSortDirectionOptions: { type: Array, default: function () { return []; } },
    tableDeltaModeOptions: { type: Array, default: function () { return []; } },
    visibleColumnKeys: { type: Array, default: function () { return []; } }
  },
  emits: [
    "toggle-column",
    "move-column-up",
    "move-column-down",
    "update:freeze-first-column",
    "update:table-filters",
    "update:table-sort-by",
    "update:table-sort-dir",
    "update:table-top-n",
    "update:column-label",
    "update:column-filter",
    "update:column-width"
  ],
  methods: {
    isVisible: function (key) {
      return (this.visibleColumnKeys || []).indexOf(key) >= 0;
    },
    mergeTableFilters: function (key, value) {
      var next = {};
      var source = this.tableFilters || {};
      Object.keys(source).forEach(function (sourceKey) {
        next[sourceKey] = source[sourceKey];
      });
      next[key] = value;
      return next;
    },
    getFilterValue: function (key, childKey) {
      var current = this.columnFilters && this.columnFilters[key] ? this.columnFilters[key] : {};
      return current && current[childKey] !== undefined ? current[childKey] : "";
    },
    mergeRangeFilter: function (key, childKey, value) {
      var current = this.columnFilters && this.columnFilters[key] ? this.columnFilters[key] : {};
      var next = {};
      Object.keys(current).forEach(function (currentKey) {
        next[currentKey] = current[currentKey];
      });
      next[childKey] = value;
      return next;
    },
    isStatusSelected: function (key, option) {
      var current = this.columnFilters && this.columnFilters[key] ? this.columnFilters[key] : {};
      var selected = Array.isArray(current.selected) ? current.selected : [];
      return selected.indexOf(option) >= 0;
    },
    toggleStatusFilter: function (key, option) {
      var current = this.columnFilters && this.columnFilters[key] ? this.columnFilters[key] : {};
      var selected = Array.isArray(current.selected) ? current.selected.slice() : [];
      var idx = selected.indexOf(option);
      if (idx >= 0) {
        selected.splice(idx, 1);
      } else {
        selected.push(option);
      }
      return { selected: selected };
    }
  }
	}
</script>