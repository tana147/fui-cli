<template>
    <v-dialog v-model="dialog" max-width="900" content-class="assignment-dialog">
        <v-card class="dialog-card dialog-card--assignment">
            <template v-slot:title>
                {{ title }}
            </template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="onClose" />
            </template>

            <v-card-text class="dialog-card__content dialog-card__content--assignment">
                <div class="dialog-head">
                    <div>
                        <div class="dialog-head__title">{{ headline }}</div>
                        <div class="dialog-head__subtitle">{{ subtitle }}</div>
                    </div>
                </div>

                <div v-if="impactText" class="impact-banner mb-4">
                    <v-icon size="18" :color="summaryColor">{{ impactIcon }}</v-icon>
                    <span>{{ impactText }}</span>
                </div>

                <div class="transfer-toolbar mb-4">
                    <div class="transfer-toolbar__hint">
                        <v-icon size="18" color="medium-emphasis">mdi-cursor-move</v-icon>
                        <span>Kéo thả giữa 2 cột hoặc bấm trực tiếp để gán nhanh.</span>
                    </div>
                    <v-chip v-if="changeCount > 0" size="small" color="warning" variant="tonal"
                        prepend-icon="mdi-pencil-outline">
                        {{ changeCount }} thay đổi chưa lưu
                    </v-chip>
                </div>

                <div class="transfer-list">
                    <div class="transfer-list__grid">
                        <div class="transfer-column" :class="{ 'is-drop-active': dropZone === 'unselected' }"
                            @dragenter.prevent="setDropZone('unselected')" @dragover.prevent="setDropZone('unselected')"
                            @dragleave="clearDropZone('unselected', $event)" @drop.prevent="handleDrop(false)">
                            <div class="transfer-header">
                                <div class="transfer-title">Danh sách chờ gán</div>
                                <v-chip size="small" variant="tonal">{{ unselectedItems.length }} mục</v-chip>
                            </div>
                            <div class="transfer-search">
                                <v-text-field v-model="searchKeyword" :label="searchLabel"
                                    prepend-inner-icon="mdi-magnify" variant="outlined" density="compact" clearable
                                    hide-details />
                            </div>
                            <div class="transfer-body">
                                <div v-if="filteredUnselectedItems.length" class="option-grid">
                                    <v-card v-for="item in filteredUnselectedItems" :key="getItemValue(item)"
                                        :elevation="0" class="option-card option-card--transfer"
                                        :class="{ 'is-dragging': dragItemValue === getItemValue(item) }"
                                        draggable="true" @dragstart="handleDragStart(getItemValue(item), false)"
                                        @dragend="handleDragEnd" @dblclick.stop="toggle(getItemValue(item), true)"
                                        @click="toggle(getItemValue(item), true)">
                                        <v-card-text class="option-card__body py-2 px-3">
                                            <div>
                                                <div class="option-card__title">{{ getItemTitle(item) }}</div>
                                                <div class="option-card__meta text-caption">{{ getItemDescription(item)
                                                    }}</div>
                                            </div>
                                            <v-btn size="small" variant="text" icon="mdi-chevron-right"
                                                color="primary" />
                                        </v-card-text>
                                    </v-card>
                                </div>
                                <div v-else class="empty-wrap pa-4 text-center">
                                    <span class="text-caption text-medium-emphasis">Không có mục nào phù hợp</span>
                                </div>
                            </div>
                            <div class="transfer-footer text-right pa-2">
                                <v-btn size="small" variant="text" color="primary" @click="selectAll">Chọn tất cả hiện
                                    có</v-btn>
                            </div>
                        </div>

                        <div class="transfer-column transfer-column--selected"
                            :class="{ 'is-drop-active': dropZone === 'selected' }"
                            @dragenter.prevent="setDropZone('selected')" @dragover.prevent="setDropZone('selected')"
                            @dragleave="clearDropZone('selected', $event)" @drop.prevent="handleDrop(true)">
                            <div class="transfer-header bg-primary-lighten-4">
                                <div>
                                    <div class="transfer-title text-primary">{{ previewTitle }}</div>
                                    <div class="transfer-subtitle">{{ selectionSummaryText }}</div>
                                </div>
                                <v-chip :color="summaryColor" size="small" variant="flat">{{ selectedIds.length }} {{
                                    summaryLabel }}</v-chip>
                            </div>
                            <div class="transfer-body pt-2">
                                <div v-if="selectedItems.length" class="option-grid">
                                    <v-card v-for="item in selectedItems" :key="getItemValue(item)" :elevation="0"
                                        class="option-card option-card--transfer is-selected"
                                        :class="{ 'is-dragging': dragItemValue === getItemValue(item) }"
                                        draggable="true" @dragstart="handleDragStart(getItemValue(item), true)"
                                        @dragend="handleDragEnd" @dblclick.stop="toggle(getItemValue(item), false)"
                                        @click="toggle(getItemValue(item), false)">
                                        <v-card-text class="option-card__body py-2 px-3">
                                            <v-btn size="small" variant="text" icon="mdi-chevron-left"
                                                :color="summaryColor" />
                                            <div class="text-right flex-grow-1">
                                                <div class="option-card__title text-primary">{{ getItemTitle(item) }}
                                                </div>
                                                <div class="option-card__meta text-caption">{{ getItemDescription(item)
                                                    }}</div>
                                            </div>
                                        </v-card-text>
                                    </v-card>
                                </div>
                                <div v-else class="empty-wrap pa-4 text-center">
                                    <span class="text-caption text-medium-emphasis">{{ emptySelectionText }}</span>
                                </div>
                            </div>
                            <div class="transfer-footer text-left pa-2">
                                <v-btn size="small" variant="text" color="error" :disabled="selectedIds.length === 0"
                                    @click="clearSelection">Bỏ chọn tất cả</v-btn>
                            </div>
                        </div>
                    </div>
                </div>
            </v-card-text>

            <v-card-actions>
                <v-spacer />
                <v-btn color="default" variant="text" @click="onClose">Hủy</v-btn>
                <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save-outline" @click="onSave">
                    Lưu cấu hình
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
    export default {
    name: 'uc-modal-assignment',
    props: {
        modelValue: { type: Boolean, required: true },
        title: { type: String, required: true },
        headline: { type: String, required: true },
        subtitle: { type: String, required: true },
        searchLabel: { type: String, required: true },
        previewTitle: { type: String, required: true },
        emptySelectionText: { type: String, required: true },
        emptyText: { type: String, required: true },
        summaryLabel: { type: String, required: true },
        summaryColor: { type: String, default: 'primary' },
        impactText: { type: String, default: '' },
        impactIcon: { type: String, default: 'mdi-information-outline' },
        items: { type: Array, required: true },
        selectedValues: { type: Array, required: true },
        itemTitleKey: { type: String, required: true },
        itemValueKey: { type: String, required: true },
        itemDescription: { type: Function, default: null },
        searchFields: {
            type: Array,
            default: function () {
                return []
            },
        },
    },
    emits: ['update:modelValue', 'save'],
    data() {
        return {
            searchKeyword: '',
            selectedIds: [],
            originalSelectedIds: [],
            dragItemValue: null,
            dragItemSelected: false,
            dropZone: '',
        }
    },
    computed: {
        dialog: {
            get() { return this.modelValue },
            set(value) { this.$emit('update:modelValue', value) },
        },
        filteredUnselectedItems() {
            const keyword = this.normalizeText(this.searchKeyword)
            const unselected = this.items.filter((item) => !this.isSelected(this.getItemValue(item)))
            if (!keyword) { return unselected }
            return unselected.filter(function (item) {
                return this.searchFields.some(function (field) {
                    return this.normalizeText(item[field]).includes(keyword)
                }, this)
            }, this)
        },
        unselectedItems() {
            return this.items.filter((item) => !this.isSelected(this.getItemValue(item)))
        },
        selectedItems() {
            return this.items.filter((item) => this.isSelected(this.getItemValue(item)))
        },
        changeCount() {
            const currentSet = new Set(this.selectedIds)
            const originalSet = new Set(this.originalSelectedIds)
            let diffCount = 0
            currentSet.forEach(function (id) {
                if (!originalSet.has(id)) { diffCount += 1 }
            })
            originalSet.forEach(function (id) {
                if (!currentSet.has(id)) { diffCount += 1 }
            })
            return diffCount
        },
        selectionSummaryText() {
            if (!this.selectedIds.length) {
                return this.emptySelectionText
            }
            return 'Kéo mục ra ngoài để bỏ gán, hoặc lưu để áp dụng ngay.'
        }
    },
    watch: {
        selectedValues: {
            handler(value) {
                const nextSelectedIds = Array.isArray(value) ? value.slice() : []
                this.selectedIds = nextSelectedIds
                this.originalSelectedIds = nextSelectedIds.slice()
            },
            immediate: true,
            deep: true,
        },
        modelValue(value) {
            if (!value) {
                this.resetState()
                return
            }
            this.searchKeyword = ''
            this.selectedIds = this.originalSelectedIds.slice()
        },
    },
    methods: {
        normalizeText(value) {
            return (value || '').toString().trim().toLowerCase()
        },
        getItemValue(item) {
            return item[this.itemValueKey]
        },
        getItemTitle(item) {
            return item[this.itemTitleKey]
        },
        getItemDescription(item) {
            if (this.itemDescription) { return this.itemDescription(item) }
            return ''
        },
        getSelectedName(selectedId) {
            const item = this.items.find(function (currentItem) {
                return currentItem[this.itemValueKey] === selectedId
            }, this)
            return item ? this.getItemTitle(item) : ''
        },
        isSelected(itemValue) {
            return this.selectedIds.includes(itemValue)
        },
        setDropZone(zone) {
            this.dropZone = zone
        },
        clearDropZone(zone, event) {
            const currentTarget = event && event.currentTarget
            const relatedTarget = event && event.relatedTarget
            if (currentTarget && relatedTarget && currentTarget.contains(relatedTarget)) { return }
            if (this.dropZone === zone) { this.dropZone = '' }
        },
        handleDragStart(itemValue, selected) {
            this.dragItemValue = itemValue
            this.dragItemSelected = selected
        },
        handleDragEnd() {
            this.dragItemValue = null
            this.dragItemSelected = false
            this.dropZone = ''
        },
        handleDrop(nextSelectedState) {
            if (this.dragItemValue === null) { return }
            if (this.dragItemSelected !== nextSelectedState) {
                this.toggle(this.dragItemValue, nextSelectedState)
            }
            this.handleDragEnd()
        },
        toggle(itemValue, selected) {
            if (selected) {
                if (!this.selectedIds.includes(itemValue)) { this.selectedIds.push(itemValue) }
                return
            }
            this.selectedIds = this.selectedIds.filter(function (currentValue) {
                return currentValue !== itemValue
            })
        },
        toggleSelection(itemValue) {
            this.toggle(itemValue, !this.isSelected(itemValue))
        },
        selectAll() {
            const selectedMap = {}
            this.selectedIds.forEach(function (id) {
                selectedMap[id] = true
            })
            this.filteredUnselectedItems.forEach(function (item) {
                selectedMap[item[this.itemValueKey]] = true
            }, this)
            this.selectedIds = Object.keys(selectedMap).map(function (id) {
                return Number.isNaN(Number(id)) ? id : Number(id)
            })
        },
        clearSelection() {
            this.selectedIds = []
        },
        resetState() {
            this.searchKeyword = ''
            this.selectedIds = this.originalSelectedIds.slice()
            this.handleDragEnd()
        },
        onClose() {
            this.resetState()
            this.dialog = false
        },
        onSave() {
            this.originalSelectedIds = this.selectedIds.slice()
            this.$emit('save', this.selectedIds.slice())
        },
    },
}
</script>