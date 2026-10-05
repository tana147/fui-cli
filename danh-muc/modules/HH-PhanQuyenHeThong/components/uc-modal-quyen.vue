<template>
    <v-dialog v-model="dialog" max-width="1160">
        <v-card class="dialog-card">
            <template v-slot:title>
                {{ 'Cấu hình quyền - ' + boPhan.TenBoPhan }}
            </template>
            <template v-slot:append>
                <v-btn size="small" variant="text" icon="mdi-close" @click="onClose" />
            </template>

            <v-card-text class="dialog-card__body permission-dialog__body">
                <div class="dialog-head">
                    <div>
                        <div class="dialog-head__title">Phân quyền theo màn hình nghiệp vụ</div>
                        <div class="dialog-head__subtitle">
                            Chọn page ở panel trái, rồi cấu hình chi tiết action ở panel phải để giảm nhiễu khi số quyền
                            lớn.
                        </div>
                    </div>
                </div>

                <div class="impact-banner mb-4">
                    <v-icon size="18" color="primary">mdi-shield-check-outline</v-icon>
                    <span>{{ impactText }}</span>
                </div>

                <div class="summary-grid mb-4">
                    <div class="summary-grid__item">
                        <div class="summary-grid__label">Module hiển thị</div>
                        <div class="summary-grid__value">{{ filteredPermissionGroups.length }}</div>
                    </div>
                    <div class="summary-grid__item">
                        <div class="summary-grid__label">Page đang có quyền</div>
                        <div class="summary-grid__value">{{ selectedPageCount }}</div>
                    </div>
                    <div class="summary-grid__item">
                        <div class="summary-grid__label">Quyền đã chọn</div>
                        <div class="summary-grid__value">{{ selectedIds.length }}</div>
                    </div>
                    <div class="summary-grid__item">
                        <div class="summary-grid__label">Thay đổi chưa lưu</div>
                        <div class="summary-grid__value">{{ changeCount }}</div>
                    </div>
                </div>

                <div v-if="filteredPermissionGroups.length" class="master-detail">
                    <div class="master-panel">
                        <div class="master-panel__toolbar">
                            <v-text-field v-model="searchKeyword" label="Tìm module hoặc page"
                                prepend-inner-icon="mdi-magnify" variant="outlined" density="comfortable" clearable
                                hide-details />
                        </div>

                        <div class="master-panel__body">
                            <div v-for="group in filteredPermissionGroups" :key="group.groupKey" class="master-group">
                                <div class="master-group__head">
                                    <div>
                                        <div class="master-group__title">{{ group.groupLabel }}</div>
                                        <div class="master-group__subtitle">
                                            {{ group.items.length }} page, {{ getSelectedCount(group.items) }} quyền
                                            đang bật
                                        </div>
                                    </div>
                                    <v-btn size="small" variant="text" color="primary" @click="selectFirstPage(group)">
                                        Mở nhóm
                                    </v-btn>
                                </div>

                                <div class="master-group__list">
                                    <button v-for="page in group.items" :key="page.pageKey" type="button"
                                        class="master-item" :class="{ 'is-active': selectedPageKey === page.pageKey }"
                                        @click="selectPage(page.pageKey)">
                                        <div class="master-item__title">{{ page.pageLabel }}</div>
                                        <div class="master-item__meta">
                                            {{ getSelectedCount([page]) }}/{{ getPagePermissionIds(page).length }} quyền
                                        </div>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="detail-panel">
                        <div v-if="selectedPageDetail" class="detail-card">
                            <div class="detail-card__head">
                                <div>
                                    <div class="detail-card__eyebrow">{{ selectedPageDetail.groupLabel }}
                                    </div>
                                    <div class="detail-card__title">{{ selectedPageDetail.pageLabel }}</div>
                                    <div class="detail-card__subtitle">
                                        {{ selectedPageDetail.permissionCodes.join(', ') }}
                                    </div>
                                </div>
                                <div class="chip-list">
                                    <v-tooltip text="Bật toàn bộ quyền của page này" location="top">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" size="small" variant="text" color="primary"
                                                @click="selectAllInPage(selectedPageDetail)">Toàn quyền</v-btn>
                                        </template>
                                    </v-tooltip>
                                    <v-tooltip text="Chỉ giữ quyền mặc định hoặc quyền xem của page này" location="top">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" size="small" variant="text" color="warning"
                                                @click="selectViewOnlyInPage(selectedPageDetail)">Chỉ quyền gốc</v-btn>
                                        </template>
                                    </v-tooltip>
                                    <v-tooltip text="Bỏ toàn bộ quyền đang chọn của page này" location="top">
                                        <template v-slot:activator="{ props }">
                                            <v-btn v-bind="props" size="small" variant="text" color="error"
                                                @click="clearPage(selectedPageDetail)">Bỏ hết</v-btn>
                                        </template>
                                    </v-tooltip>
                                </div>
                            </div>

                            <div class="detail-actions">
                                <v-card v-for="action in visibleActionColumns"
                                    :key="selectedPageDetail.pageKey + '-' + action.key" :elevation="0"
                                    class="action-card" :class="{
                                        'is-disabled': !selectedPageDetail.actions[action.key],
                                        'is-selected': selectedPageDetail.actions[action.key] && isSelected(selectedPageDetail.actions[action.key].Quyen_Id),
                                    }">
                                    <v-card-text
                                        class="action-card__body d-flex align-center justify-space-between px-3 py-2">
                                        <div class="action-card__content">
                                            <div class="action-card__title">{{ action.label }}</div>
                                            <div class="action-card__meta">
                                                {{ getActionDescription(selectedPageDetail, action.key) }}
                                            </div>
                                        </div>
                                        <v-switch v-if="selectedPageDetail.actions[action.key]"
                                            class="action-card__switch flex-grow-0 flex-shrink-0"
                                            :model-value="isSelected(selectedPageDetail.actions[action.key].Quyen_Id)"
                                            density="compact" color="primary" base-color="grey-lighten-1" hide-details
                                            inset
                                            @update:model-value="togglePermission(selectedPageDetail.actions[action.key].Quyen_Id, $event, selectedPageDetail)" />
                                        <span v-else class="action-card__empty">Không áp dụng</span>
                                    </v-card-text>
                                </v-card>
                            </div>

                            <div class="detail-footer">
                                <v-tooltip text="Bật toàn bộ quyền của tất cả page trong module này" location="top">
                                    <template v-slot:activator="{ props }">
                                        <v-btn v-bind="props" size="small" variant="text" color="primary"
                                            @click="selectAllInGroup(selectedPageDetail.groupItems)">
                                            Toàn quyền module
                                        </v-btn>
                                    </template>
                                </v-tooltip>
                                <v-tooltip text="Chỉ giữ quyền mặc định hoặc quyền xem của toàn bộ module này"
                                    location="top">
                                    <template v-slot:activator="{ props }">
                                        <v-btn v-bind="props" size="small" variant="text" color="warning"
                                            @click="selectViewOnlyInGroup(selectedPageDetail.groupItems)">
                                            Chỉ quyền gốc module
                                        </v-btn>
                                    </template>
                                </v-tooltip>
                                <v-tooltip text="Bỏ toàn bộ quyền đang chọn trong module này" location="top">
                                    <template v-slot:activator="{ props }">
                                        <v-btn v-bind="props" size="small" variant="text" color="error"
                                            @click="clearGroup(selectedPageDetail.groupItems)">
                                            Bỏ module
                                        </v-btn>
                                    </template>
                                </v-tooltip>
                            </div>
                        </div>

                        <div v-else class="empty-wrap">
                            <uc-empty text="Chọn một page ở panel trái để cấu hình quyền chi tiết" />
                        </div>
                    </div>
                </div>

                <div v-else class="empty-wrap">
                    <uc-empty
                        :text="searchKeyword ? 'Không tìm thấy nhóm quyền phù hợp' : 'Chưa có quyền nào để cấu hình'" />
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
    name: 'uc-modal-quyen',
    props: {
        modelValue: { type: Boolean, required: true },
        boPhan: { type: Object, required: true },
        quyenList: { type: Array, required: true },
        boPhanQuyenList: { type: Array, required: true },
    },
    emits: ['update:modelValue', 'save'],
    data() {
        return {
            searchKeyword: '',
            selectedIds: [],
            originalSelectedIds: [],
            selectedPageKey: '',
            groupLabels: {
                HE_THONG: 'Hệ thống',
                DANH_MUC: 'Danh mục',
                KHO: 'Kho',
                PHIEU: 'Phiếu',
                BAO_CAO: 'Báo cáo',
                MUA_HANG: 'Mua hàng',
                BANG_CONG_THUC: 'Bảng công thức',
                CONG_THUC: 'Công thức',
                NGUYEN_LIEU: 'Nguyên liệu',
                TAI_SAN: 'Tài sản',
                DE_XUAT: 'Đề xuất',
            },
        }
    },
    computed: {
        dialog: {
            get() { return this.modelValue },
            set(value) { this.$emit('update:modelValue', value) },
        },
        impactText() {
            return 'Mọi nhân viên trong bộ phận ' + this.boPhan.TenBoPhan + ' sẽ kế thừa tập quyền này sau khi lưu.'
        },
        permissionGroups() {
            const groupMap = {}

            this.quyenList.forEach(function (quyen) {
                const normalized = this.normalizePermission(quyen)
                if (!groupMap[normalized.groupKey]) {
                    groupMap[normalized.groupKey] = {
                        groupKey: normalized.groupKey,
                        groupLabel: normalized.groupLabel,
                        items: [],
                    }
                }

                let pageItem = groupMap[normalized.groupKey].items.find(function (item) {
                    return item.pageKey === normalized.pageKey
                })

                if (!pageItem) {
                    pageItem = {
                        pageKey: normalized.pageKey,
                        pageLabel: normalized.pageLabel,
                        pageSearchText: normalized.searchText,
                        permissionCodes: [],
                        actions: {},
                    }
                    groupMap[normalized.groupKey].items.push(pageItem)
                }

                pageItem.permissionCodes.push(quyen.Quyen_Id || quyen.Ma_Quyen || quyen.TenQuyen)
                pageItem.actions[normalized.actionKey] = Object.assign({}, quyen, {
                    ActionKey: normalized.actionKey,
                    ActionLabel: normalized.actionLabel,
                    ActionOrder: normalized.actionOrder,
                })
            }, this)

            return Object.values(groupMap).map(function (group) {
                return Object.assign({}, group, {
                    items: group.items.sort(function (a, b) { return a.pageLabel.localeCompare(b.pageLabel) }),
                })
            }).sort(function (a, b) { return a.groupLabel.localeCompare(b.groupLabel) })
        },
        filteredPermissionGroups() {
            const keyword = this.normalizeText(this.searchKeyword)
            if (!keyword) { return this.permissionGroups }

            return this.permissionGroups
                .map(function (group) {
                    const groupMatched = this.normalizeText(group.groupLabel).includes(keyword)
                    const items = group.items.filter(function (page) {
                        return groupMatched || page.pageSearchText.includes(keyword)
                    })
                    return Object.assign({}, group, { items: items })
                }, this)
                .filter(function (group) { return group.items.length > 0 })
        },
        allVisiblePages() {
            return this.filteredPermissionGroups.reduce(function (result, group) {
                return result.concat(group.items.map(function (page) {
                    return Object.assign({}, page, { groupLabel: group.groupLabel, groupItems: group.items })
                }))
            }, [])
        },
        selectedPageDetail() {
            return this.allVisiblePages.find(function (page) {
                return page.pageKey === this.selectedPageKey
            }, this) || this.allVisiblePages[0] || null
        },
        visibleActionColumns() {
            const actionMap = {}
            this.permissionGroups.forEach(function (group) {
                group.items.forEach(function (page) {
                    Object.values(page.actions).forEach(function (action) {
                        if (!action) { return }
                        if (!actionMap[action.ActionKey] || action.ActionOrder < actionMap[action.ActionKey].order) {
                            actionMap[action.ActionKey] = {
                                key: action.ActionKey,
                                label: action.ActionLabel,
                                order: action.ActionOrder,
                            }
                        }
                    })
                })
            })
            return Object.values(actionMap).sort(function (left, right) {
                if (left.order !== right.order) { return left.order - right.order }
                return left.label.localeCompare(right.label)
            })
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
        selectedPageCount() {
            return this.permissionGroups.reduce(function (count, group) {
                return count + group.items.filter(function (page) {
                    return Object.values(page.actions).some(function (quyen) {
                        return this.isSelected(quyen.Quyen_Id)
                    }, this)
                }, this).length
            }.bind(this), 0)
        },
    },
    watch: {
        modelValue(value) {
            if (!value) {
                this.resetState()
                return
            }
            this.searchKeyword = ''
            this.selectedIds = this.originalSelectedIds.slice()
            this.ensureSelectedPage()
        },
        boPhanQuyenList: {
            handler() {
                const nextSelectedIds = this.boPhanQuyenList
                    .filter((item) => item.BoPhan_Id === this.boPhan.BoPhan_Id && item.Enable === 0)
                    .map(function (item) { return item.Quyen_Id })
                this.selectedIds = nextSelectedIds
                this.originalSelectedIds = nextSelectedIds.slice()
                this.ensureSelectedPage()
            },
            immediate: true,
            deep: true,
        },
        searchKeyword() {
            this.ensureSelectedPage()
        },
    },
    methods: {
        normalizeText(value) {
            return (value || '').toString().trim().toLowerCase()
        },
        normalizePermission(quyen) {
            const code = (quyen.Quyen_Id || quyen.Ma_Quyen || '').toString().trim()
            const name = (quyen.TenQuyen || '').toString().trim()
            const delimiter = quyen.Quyen_Id ? /[-]/ : (/[.:/_-]/.test(code) ? /[.:/_-]/ : /[_-]/)
            const rawTokens = code ? code.split(delimiter).filter(function (token) { return !!token }) : []
            const actionKey = this.getPermissionActionKey(quyen, rawTokens)
            const descriptionInfo = this.getDescriptionInfo(quyen)
            const groupLabel = this.getGroupLabel(quyen, descriptionInfo, rawTokens)
            const pageLabel = this.getPermissionPageLabel(quyen, descriptionInfo, rawTokens)
            const pageKey = this.getPermissionPageKey(quyen, pageLabel, code, rawTokens)
            const actionLabel = this.getPermissionActionLabel(quyen, actionKey, pageLabel)
            const searchText = this.normalizeText([groupLabel, pageLabel, code, name].join(' '))

            return {
                groupKey: this.normalizeText(groupLabel),
                groupLabel: groupLabel,
                pageKey: pageKey,
                pageLabel: pageLabel,
                actionKey: actionKey,
                actionLabel: actionLabel,
                actionOrder: Number(quyen && quyen.ThuTu !== undefined ? quyen.ThuTu : 9999),
                searchText: searchText,
            }
        },
        getDescriptionInfo(quyen) {
            const moTa = (quyen && quyen.MoTa ? quyen.MoTa : '').toString().trim()
            if (!moTa) { return { groupLabel: '', pageLabel: '' } }
            const parts = moTa.split(' - ').map(function (item) { return item.trim() }).filter(function (item) { return !!item })
            if (parts.length >= 2) {
                return {
                    groupLabel: parts[0],
                    pageLabel: parts.slice(1).join(' - '),
                }
            }
            return {
                groupLabel: '',
                pageLabel: moTa,
            }
        },
        getPermissionActionKey(quyen, rawTokens) {
            if (quyen && quyen.ActionKey) {
                return quyen.ActionKey.toString().trim().toUpperCase()
            }
            if (rawTokens.length) {
                return rawTokens[rawTokens.length - 1].toString().trim().toUpperCase()
            }
            return 'DEFAULT'
        },
        getGroupLabel(quyen, descriptionInfo, rawTokens) {
            if (quyen && quyen.NhomQuyen) {
                const rawGroupCode = this.normalizeText(quyen.NhomQuyen).replace(/-/g, '_').toUpperCase()
                return this.groupLabels[rawGroupCode] || this.formatToken(quyen.NhomQuyen)
            }
            if (descriptionInfo.groupLabel) { return descriptionInfo.groupLabel }
            return rawTokens.length ? this.formatToken(rawTokens[0]) : 'Khác'
        },
        getPermissionPageLabel(quyen, descriptionInfo, rawTokens) {
            if (descriptionInfo.pageLabel) { return descriptionInfo.pageLabel }
            const pageUrl = (quyen && quyen.Page_Url ? quyen.Page_Url : '').toString().trim()
            const pageUrlToken = pageUrl.split('/').filter(function (item) { return !!item }).pop()
            if (pageUrlToken) { return this.formatToken(pageUrlToken) }

            const name = (quyen && quyen.TenQuyen ? quyen.TenQuyen : '').toString().trim()
            const actionKey = this.getPermissionActionKey(quyen, rawTokens)
            const actionLabel = this.formatToken(actionKey)
            const normalizedName = this.normalizeText(name)
            const normalizedAction = this.normalizeText(actionLabel)
            if (name && normalizedAction && normalizedName.startsWith(normalizedAction + ' ')) {
                return name.slice(actionLabel.length).trim()
            }

            const pageTokens = rawTokens.slice(0, rawTokens.length > 1 ? rawTokens.length - 1 : rawTokens.length)
            if (pageTokens.length) { return pageTokens.map(this.formatToken).join(' / ') }
            return name || 'Quyền chung'
        },
        getPermissionPageKey(quyen, pageLabel, code, rawTokens) {
            const pageUrl = (quyen && quyen.Page_Url ? quyen.Page_Url : '').toString().trim()
            if (pageUrl) { return this.normalizeText(pageUrl) }
            if (quyen && quyen.MoTa) { return this.normalizeText((quyen.NhomQuyen || '') + '-' + pageLabel) }
            const pageTokens = rawTokens.slice(0, rawTokens.length > 1 ? rawTokens.length - 1 : rawTokens.length)
            return this.normalizeText(pageTokens.join('_') || pageLabel || code || String(quyen.Quyen_Id))
        },
        getPermissionActionLabel(quyen, actionKey, pageLabel) {
            const tenQuyen = (quyen && quyen.TenQuyen ? quyen.TenQuyen : '').toString().trim()
            const normalizedPageLabel = this.normalizeText(pageLabel)
            if (tenQuyen && normalizedPageLabel) {
                const normalizedTenQuyen = this.normalizeText(tenQuyen)
                const pageLabelIndex = normalizedTenQuyen.lastIndexOf(normalizedPageLabel)
                if (pageLabelIndex >= 0) {
                    const actionLabel = tenQuyen.slice(0, pageLabelIndex).replace(/[-:]+$/g, '').trim()
                    if (actionLabel) { return actionLabel }
                }
            }
            return this.formatToken(actionKey)
        },
        formatToken(token) {
            return token
                .toString()
                .replace(/([a-z])([A-Z])/g, '$1 $2')
                .replace(/[_-]+/g, ' ')
                .replace(/\s+/g, ' ')
                .trim()
                .replace(/\b\w/g, function (char) { return char.toUpperCase() })
        },
        ensureSelectedPage() {
            if (!this.allVisiblePages.length) {
                this.selectedPageKey = ''
                return
            }
            if (this.selectedPageKey && this.allVisiblePages.some(function (page) { return page.pageKey === this.selectedPageKey }, this)) {
                return
            }
            this.selectedPageKey = this.allVisiblePages[0].pageKey
        },
        selectPage(pageKey) {
            this.selectedPageKey = pageKey
        },
        selectFirstPage(group) {
            if (group && group.items.length) {
                this.selectedPageKey = group.items[0].pageKey
            }
        },
        isSelected(quyenId) {
            return this.selectedIds.includes(quyenId)
        },
        togglePermission(quyenId, selected, page) {
            if (selected) {
                if (!this.selectedIds.includes(quyenId)) { this.selectedIds.push(quyenId) }
                if (page) { this.ensureBasePermission(page) }
                return
            }
            this.selectedIds = this.selectedIds.filter(function (id) { return id !== quyenId })
        },
        getDefaultPermission(page) {
            if (!page) { return null }
            const permissions = Object.values(page.actions).filter(function (item) { return !!item })
            const viewPermission = permissions.find(function (item) { return item.ActionKey === 'VIEW' })
            if (viewPermission) { return viewPermission }
            if (!permissions.length) { return null }
            return permissions.sort(function (left, right) {
                if (left.ActionOrder !== right.ActionOrder) { return left.ActionOrder - right.ActionOrder }
                return left.ActionLabel.localeCompare(right.ActionLabel)
            })[0]
        },
        ensureBasePermission(page) {
            const defaultPermission = this.getDefaultPermission(page)
            if (defaultPermission && !this.selectedIds.includes(defaultPermission.Quyen_Id)) {
                this.selectedIds.push(defaultPermission.Quyen_Id)
            }
        },
        selectPermissions(permissionIds) {
            const selectedMap = {}
            this.selectedIds.forEach(function (id) { selectedMap[id] = true })
            permissionIds.forEach(function (id) { selectedMap[id] = true })
            this.selectedIds = Object.keys(selectedMap)
        },
        removePermissions(permissionIds) {
            const permissionIdSet = new Set(permissionIds)
            this.selectedIds = this.selectedIds.filter(function (id) { return !permissionIdSet.has(id) })
        },
        getPagePermissionIds(page) {
            return Object.values(page.actions).map(function (quyen) { return quyen.Quyen_Id })
        },
        getPageViewIds(page) {
            const defaultPermission = this.getDefaultPermission(page)
            return defaultPermission ? [defaultPermission.Quyen_Id] : []
        },
        getGroupPermissionIds(items) {
            return items.reduce(function (result, page) {
                return result.concat(this.getPagePermissionIds(page))
            }.bind(this), [])
        },
        getGroupViewIds(items) {
            return items.reduce(function (result, page) {
                return result.concat(this.getPageViewIds(page))
            }.bind(this), [])
        },
        getSelectedCount(items) {
            return items.reduce(function (count, page) {
                return count + this.getPagePermissionIds(page).filter(function (id) {
                    return this.selectedIds.includes(id)
                }, this).length
            }.bind(this), 0)
        },
        getActionDescription(page, actionKey) {
            const permission = page.actions[actionKey]
            if (!permission) { return 'Action này không áp dụng cho page này' }
            return permission.Quyen_Id || permission.Ma_Quyen || permission.TenQuyen
        },
        selectAllInPage(page) {
            this.selectPermissions(this.getPagePermissionIds(page))
            this.ensureBasePermission(page)
        },
        selectViewOnlyInPage(page) {
            this.removePermissions(this.getPagePermissionIds(page))
            this.selectPermissions(this.getPageViewIds(page))
        },
        clearPage(page) {
            this.removePermissions(this.getPagePermissionIds(page))
        },
        selectAllInGroup(items) {
            this.selectPermissions(this.getGroupPermissionIds(items))
            items.forEach(function (page) { this.ensureBasePermission(page) }, this)
        },
        selectViewOnlyInGroup(items) {
            this.removePermissions(this.getGroupPermissionIds(items))
            this.selectPermissions(this.getGroupViewIds(items))
        },
        clearGroup(items) {
            this.removePermissions(this.getGroupPermissionIds(items))
        },
        resetState() {
            this.searchKeyword = ''
            this.selectedIds = this.originalSelectedIds.slice()
            this.ensureSelectedPage()
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