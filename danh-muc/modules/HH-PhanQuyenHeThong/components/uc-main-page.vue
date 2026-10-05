<template>
	<z-layout-1>
		<v-app-bar density="compact" :elevation="0" title="Quản lý phân quyền" class="page-bar">
			<template v-slot:append>
				<div class="bar-actions">
					<v-chip size="small" color="info" variant="tonal" prepend-icon="mdi-api">Danh mục quyền từ API
					</v-chip>
					<v-chip v-if="selectedBoPhan" size="small" color="primary" variant="tonal"
						prepend-icon="mdi-domain">{{ selectedBoPhan.TenBoPhan }}</v-chip>
				</div>
			</template>
		</v-app-bar>
		<div class="page-shell">
			<uc-stats-phan-quyen :statCards="statCards" />
			<uc-main-view :boPhanList="boPhanListView" :selectedBoPhanId="selectedBoPhanId"
				:selectedBoPhan="selectedBoPhan" :activeTab="activeTab"
				:selectedBoPhanQuyenSummaries="selectedBoPhanQuyenSummaries" :priorityMessage="priorityMessage"
				:nhanVienListByBoPhan="nhanVienListByBoPhan" @add-bo-phan="openBoPhanForm"
				@select-bo-phan="onSelectBoPhan" @edit-bo-phan="openBoPhanForm" @config-quyen="openQuyenForm"
				@delete-bo-phan="deleteBoPhan" @update:activeTab="updateActiveTab" @add-nhan-vien="openNhanVienForm"
				@edit-nhan-vien="openNhanVienForm" @delete-nhan-vien="deleteNhanVien"
				@assign-dia-diem="openDiaDiemForm" />

			<uc-modal-bo-phan v-if="isShowBoPhanForm" v-model="isShowBoPhanForm" :boPhanDetail="boPhanFormData"
				:isEdit="isBoPhanEdit" @save="saveBoPhan" />
			<uc-modal-quyen v-if="isShowQuyenForm && selectedBoPhan" v-model="isShowQuyenForm" :boPhan="selectedBoPhan"
				:quyenList="quyenList" :boPhanQuyenList="boPhanQuyenList" @save="saveQuyenAssignment" />
			<uc-modal-nhan-vien v-if="isShowNhanVienForm" v-model="isShowNhanVienForm"
				:nhanVienDetail="nhanVienFormData" :isEdit="isNhanVienEdit" :boPhanList="boPhanList"
				:nhanVienCatalog="nhanVienCatalog" @save="saveNhanVien" />
			<uc-modal-dia-diem v-if="isShowDiaDiemForm && selectedNhanVienForDiaDiem" v-model="isShowDiaDiemForm"
				:nhanVien="selectedNhanVienForDiaDiem" :diaDiemList="diaDiemList"
				:selectedIds="selectedNhanVienDiaDiemIds" @save="saveDiaDiemAssignment" />
		</div>
	</z-layout-1>
</template>

<script>
	export default {
	    name: 'uc-main-page',
	    data() {
	        return {
	            selectedBoPhanId: null,
	            selectedNhanVienId: null,
	            selectedNhanVienDiaDiemIds: [],
	            activeTab: 'quyen',
	            isShowBoPhanForm: false,
	            isBoPhanEdit: false,
	            boPhanFormData: null,
	            isShowQuyenForm: false,
	            isShowNhanVienForm: false,
	            isNhanVienEdit: false,
	            nhanVienFormData: null,
	            isShowDiaDiemForm: false,
	            pageData: this.createEmptyData(),
	            boPhanApiConfig: {
	                select: 'work/HH_BoPhan_Select',
	                insert: 'work/HH_BoPhan_Insert',
	                update: 'work/HH_BoPhan_Update',
	                delete: 'work/HH_BoPhan_Delete',
	            },
	            nhanVienApiConfig: {
	                catalog: 'work/HH_NhanVien_Select',
	                selectByBoPhan: 'work/HH_NhanVien_Select_PhanQuyen',
	                selectDiaDiemByNhanVienId: 'work/HH_NhanVienDiaDiem_Select_By_NhanVien_Id',
	                insert: 'work/HH_NhanVien_Insert',
	                update: 'work/HH_NhanVien_Update',
	                updateDiaDiem: 'work/HH_NhanVien_Update_CuaHang',
	                delete: 'work/HH_NhanVien_Delete',
	            },
	            diaDiemApiConfig: {
	                select: 'work/HH_DiaDiem_Select',
	            },
	            quyenApiConfig: {
	                select: 'work/HH_Quyen_Select',
	            },
	            boPhanQuyenApiConfig: {
	                selectByBoPhan: 'work/HH_BoPhanQuyen_Select_ByBoPhanId',
	                update: 'work/HH_BoPhan_Update_Quyen',
	            },
	        }
	    },
	    computed: {
	        boPhanList() { return this.getEnabledList(this.pageData.boPhanList) },
	        quyenList() { return this.getEnabledList(this.pageData.quyenList, true) },
	        boPhanQuyenList() { return this.getEnabledList(this.pageData.boPhanQuyenList) },
	        diaDiemList() { return this.getEnabledList(this.pageData.diaDiemList) },
	        nhanVienList() { return this.getEnabledList(this.pageData.nhanVienList) },
	        nhanVienCatalog() { return this.getEnabledList(this.pageData.nhanVienCatalog, true) },
	        nhanVienListView() {
	            return this.nhanVienList.map(function (nhanVien) {
	                return this.buildNhanVienView(nhanVien)
	            }, this)
	        },
	        boPhanListView() {
	            return this.boPhanList.map(function (boPhan) {
	                return this.buildBoPhanSummary(boPhan)
	            }, this)
	        },
	        selectedBoPhan() {
	            return this.boPhanListView.find(function (item) {
	                return item.BoPhan_Id === this.selectedBoPhanId
	            }, this) || null
	        },
	        selectedNhanVienForDiaDiem() {
	            return this.nhanVienListView.find(function (item) {
	                return item.NhanVien_Id === this.selectedNhanVienId
	            }, this) || null
	        },
	        nhanVienListByBoPhan() {
	            if (!this.selectedBoPhanId) { return [] }
	            return this.nhanVienListView.filter(function (item) {
	                return item.BoPhan_Id === this.selectedBoPhanId
	            }, this)
	        },
	        selectedBoPhanQuyenSummaries() {
	            const pageMap = {}
	            this.getQuyenByBoPhan(this.selectedBoPhanId).forEach(function (quyen) {
	                const pageKey = this.getPermissionPageSlug(quyen)
	                const pageLabel = this.getPermissionPageLabel(quyen)
	                const actionLabel = this.getPermissionActionLabel(this.getPermissionActionKey(quyen), quyen, pageLabel)
	                if (!pageLabel || !actionLabel) { return }
	                if (!pageMap[pageKey]) {
	                    pageMap[pageKey] = {
	                        pageLabel: pageLabel,
	                        actions: [],
	                    }
	                }
	                if (!pageMap[pageKey].actions.some(function (item) { return item.label === actionLabel })) {
	                    pageMap[pageKey].actions.push({
	                        label: actionLabel,
	                        order: Number(quyen && quyen.ThuTu !== undefined ? quyen.ThuTu : 9999),
	                    })
	                }
	            }, this)
	            return Object.values(pageMap).map(function (pageInfo) {
	                const orderedActions = pageInfo.actions
	                    .sort(function (left, right) {
	                        if (left.order !== right.order) { return left.order - right.order }
	                        return left.label.localeCompare(right.label)
	                    })
	                    .map(function (item) { return item.label })
	                return {
	                    pageLabel: pageInfo.pageLabel,
	                    statusLabel: orderedActions.length + ' quyền',
	                    actionsText: orderedActions.join(', '),
	                }
	            })
	        },
	        priorityMessage() {
	            if (!this.selectedBoPhan) { return '' }
	            if (this.selectedBoPhan.SoQuyen === 0) { return 'Cấu hình quyền trước để tránh mất thao tác' }
	            return 'Theo dõi nhân sự mới để giữ phân quyền đồng nhất'
	        },
	        statCards() {
	            const tongBoPhan = this.boPhanListView.length
	            const tongNhanVien = this.boPhanListView.reduce(function (total, boPhan) {
	                return total + Number(boPhan && boPhan.SoNhanVien ? boPhan.SoNhanVien : 0)
	            }, 0)
	            const tongLuotGanQuyen = this.boPhanListView.reduce(function (total, boPhan) {
	                return total + Number(boPhan && boPhan.SoQuyen ? boPhan.SoQuyen : 0)
	            }, 0)
	            return [
	                { key: 'bo-phan', label: 'Tổng bộ phận', value: tongBoPhan, helper: 'Quản lý theo cơ cấu bộ phận nội bộ', icon: 'mdi-domain', isTextValue: false },
	                { key: 'nhan-vien', label: 'Tổng nhân viên', value: tongNhanVien, helper: 'Tính trực tiếp từ danh sách bộ phận', icon: 'mdi-account-group-outline', isTextValue: false },
	                { key: 'quyen', label: 'Lượt gán quyền', value: tongLuotGanQuyen, helper: this.selectedBoPhan ? this.selectedBoPhan.SoQuyen + ' quyền ở scope đang chọn' : 'Chọn bộ phận để xem quyền hiệu lực', icon: 'mdi-shield-key-outline', isTextValue: false },
	                { key: 'selected', label: 'Scope đang chọn', value: this.selectedBoPhan ? this.selectedBoPhan.TenBoPhan : 'Chưa chọn bộ phận', helper: this.selectedBoPhan ? this.selectedBoPhan.SoNhanVien + ' nhân sự đang chịu ảnh hưởng' : 'Mọi thao tác bên phải sẽ theo bộ phận được chọn', icon: 'mdi-crosshairs-gps', isTextValue: true },
	            ]
	        },
	    },
	    mounted() { this.initData() },
	    methods: {
	        createEmptyData() {
	            return {
	                boPhanList: [],
	                quyenList: [],
	                boPhanQuyenList: [],
	                diaDiemList: [],
	                nhanVienList: [],
	                nhanVienCatalog: [],
	            }
	        },
	        createDataSnapshot(currentData, overrides) {
	            return {
	                boPhanList: overrides && overrides.boPhanList !== undefined ? overrides.boPhanList : currentData.boPhanList,
	                quyenList: overrides && overrides.quyenList !== undefined ? overrides.quyenList : currentData.quyenList,
	                boPhanQuyenList: overrides && overrides.boPhanQuyenList !== undefined ? overrides.boPhanQuyenList : currentData.boPhanQuyenList,
	                diaDiemList: overrides && overrides.diaDiemList !== undefined ? overrides.diaDiemList : currentData.diaDiemList,
	                nhanVienList: overrides && overrides.nhanVienList !== undefined ? overrides.nhanVienList : currentData.nhanVienList,
	                nhanVienCatalog: overrides && overrides.nhanVienCatalog !== undefined ? overrides.nhanVienCatalog : currentData.nhanVienCatalog,
	            }
	        },
	        setPageData(overrides) {
	            this.pageData = this.createDataSnapshot(this.pageData, overrides)
	        },
	        copyBoPhanFormData(source) {
	            return {
	                BoPhan_Id: source && source.BoPhan_Id ? source.BoPhan_Id : null,
	                TenBoPhan: source && source.TenBoPhan ? source.TenBoPhan : '',
	                MoTaNhiemVu: source && source.MoTaNhiemVu ? source.MoTaNhiemVu : (source && source.MoTa ? source.MoTa : ''),
	                Is_NhieuDiaDiem: Number(source && source.Is_NhieuDiaDiem ? source.Is_NhieuDiaDiem : 0),
	                TinhTrang: source && source.TinhTrang !== undefined ? Number(source.TinhTrang) : 0,
	            }
	        },
	        copyNhanVienFormData(source) {
	            return {
	                NhanVien_Id: source && source.NhanVien_Id ? source.NhanVien_Id : null,
	                MaNhanVien: source && source.MaNhanVien ? source.MaNhanVien : '',
	                BoPhan_Id: source && source.BoPhan_Id ? source.BoPhan_Id : null,
	                TinhTrang: source && source.TinhTrang !== undefined ? Number(source.TinhTrang) : 0,
	            }
	        },
	        normalizeBoPhanPayload(formData) {
	            return {
	                BoPhan_Id: formData && formData.BoPhan_Id ? formData.BoPhan_Id : null,
	                TenBoPhan: (formData && formData.TenBoPhan ? formData.TenBoPhan : '').trim(),
	                MoTaNhiemVu: (formData && formData.MoTaNhiemVu ? formData.MoTaNhiemVu : (formData && formData.MoTa ? formData.MoTa : '')).trim(),
	                Is_NhieuDiaDiem: Number(formData && formData.Is_NhieuDiaDiem ? formData.Is_NhieuDiaDiem : 0),
	                TinhTrang: formData && formData.TinhTrang !== undefined ? Number(formData.TinhTrang) : 0,
	            }
	        },
	        normalizeNhanVienPayload(formData) {
	            return {
	                NhanVien_Id: formData && formData.NhanVien_Id ? formData.NhanVien_Id : null,
	                MaNhanVien: (formData && formData.MaNhanVien ? formData.MaNhanVien : '').trim(),
	                BoPhan_Id: Number(formData && formData.BoPhan_Id ? formData.BoPhan_Id : 0),
	                TinhTrang: formData && formData.TinhTrang !== undefined ? Number(formData.TinhTrang) : 0,
	            }
	        },
	        buildDiaDiemApDungID(selectedDiaDiemIds) {
	            return (selectedDiaDiemIds || []).join(',')
	        },
	        buildQuyenApDungID(selectedQuyenIds) {
	            return this.getUniqueList((selectedQuyenIds || []).filter(function (item) { return !!item })).join(',')
	        },
	        mergeItemById(list, key, payload) {
	            return list.map(function (item) {
	                if (item[key] !== payload[key]) { return item }
	                return Object.assign({}, item, payload)
	            })
	        },
	        getUniqueList(list) { return Array.from(new Set(list)) },
	        normalizePermissionText(value) {
	            return (value || '').toString().trim().toLowerCase()
	        },
	        formatPermissionToken(value) {
	            return (value || '')
	                .toString()
	                .replace(/([a-z])([A-Z])/g, '$1 $2')
	                .replace(/[_-]+/g, ' ')
	                .replace(/\s+/g, ' ')
	                .trim()
	                .replace(/\b\w/g, function (char) { return char.toUpperCase() })
	        },
	        getPermissionDescriptionInfo(quyen) {
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
	        getPermissionActionLabel(action, quyen, pageLabel) {
	            const tenQuyen = (quyen && quyen.TenQuyen ? quyen.TenQuyen : '').toString().trim()
	            const normalizedPageLabel = this.normalizePermissionText(pageLabel)
	            if (tenQuyen && normalizedPageLabel) {
	                const normalizedTenQuyen = this.normalizePermissionText(tenQuyen)
	                const pageLabelIndex = normalizedTenQuyen.lastIndexOf(normalizedPageLabel)
	                if (pageLabelIndex >= 0) {
	                    const actionLabel = tenQuyen.slice(0, pageLabelIndex).replace(/[-:]+$/g, '').trim()
	                    if (actionLabel) { return actionLabel }
	                }
	            }
	            return this.formatPermissionToken(action)
	        },
	        getPermissionActionKey(quyen) {
	            const quyenId = (quyen && quyen.Quyen_Id ? quyen.Quyen_Id : '').toString().trim().toLowerCase()
	            if (!quyenId) { return quyen && quyen.ActionKey ? quyen.ActionKey : '' }
	            const actionKey = quyenId.split('-').pop()
	            return actionKey ? actionKey.toUpperCase() : ''
	        },
	        getPermissionPageLabel(quyen) {
	            const descriptionInfo = this.getPermissionDescriptionInfo(quyen)
	            if (descriptionInfo.pageLabel) { return descriptionInfo.pageLabel }
	
	            const pageUrl = (quyen && quyen.Page_Url ? quyen.Page_Url : '').toString().trim()
	            const pageUrlToken = pageUrl.split('/').filter(function (item) { return !!item }).pop()
	            if (pageUrlToken) { return this.formatPermissionToken(pageUrlToken) }
	
	            const tenQuyen = (quyen && quyen.TenQuyen ? quyen.TenQuyen : '').toString().trim()
	            const actionKey = this.getPermissionActionKey(quyen)
	            const actionLabel = this.formatPermissionToken(actionKey)
	            const normalizedTenQuyen = this.normalizePermissionText(tenQuyen)
	            const normalizedActionLabel = this.normalizePermissionText(actionLabel)
	            if (tenQuyen && normalizedActionLabel && normalizedTenQuyen.startsWith(normalizedActionLabel + ' ')) {
	                return tenQuyen.slice(actionLabel.length).trim()
	            }
	            return tenQuyen
	        },
	        getPermissionPageSlug(quyen) {
	            const pageUrl = (quyen && quyen.Page_Url ? quyen.Page_Url : '').toString().trim()
	            if (pageUrl) { return this.normalizePermissionText(pageUrl) }
	
	            const descriptionInfo = this.getPermissionDescriptionInfo(quyen)
	            if (descriptionInfo.pageLabel) {
	                return this.normalizePermissionText((descriptionInfo.groupLabel || quyen.NhomQuyen || '') + '-' + descriptionInfo.pageLabel)
	            }
	
	            const quyenId = (quyen && quyen.Quyen_Id ? quyen.Quyen_Id : '').toString().trim().toLowerCase()
	            if (!quyenId) { return '' }
	            const parts = quyenId.split('-').filter(function (item) { return !!item })
	            return parts.length > 1 ? parts.slice(0, parts.length - 1).join('-') : quyenId
	        },
	        getEnabledList(list, allowUndefinedEnable) {
	            return (list || []).filter(function (item) {
	                return item.Enable === 0 || (allowUndefinedEnable && item.Enable === undefined)
	            })
	        },
	        mapBoPhanFromApi(boPhan) {
	            const soNhanVien = boPhan && boPhan.SoNhanVien !== undefined
	                ? boPhan.SoNhanVien
	                : (
	                    boPhan && boPhan.SoLuongNhanVien !== undefined
	                        ? boPhan.SoLuongNhanVien
	                        : (
	                            boPhan && boPhan.TongNhanVien !== undefined
	                                ? boPhan.TongNhanVien
	                                : null
	                        )
	                )
	            return {
	                BoPhan_Id: Number(boPhan && boPhan.BoPhan_Id ? boPhan.BoPhan_Id : 0),
	                TenBoPhan: boPhan && boPhan.TenBoPhan ? boPhan.TenBoPhan : '',
	                MoTaNhiemVu: boPhan && boPhan.MoTaNhiemVu ? boPhan.MoTaNhiemVu : '',
	                Is_NhieuDiaDiem: Number(boPhan && boPhan.Is_NhieuDiaDiem ? boPhan.Is_NhieuDiaDiem : 0),
	                SoQuyen: Number(boPhan && boPhan.SoQuyen ? boPhan.SoQuyen : 0),
	                SoNhanVien: soNhanVien !== null ? Number(soNhanVien) : null,
	                TinhTrang: boPhan && boPhan.TinhTrang !== undefined ? Number(boPhan.TinhTrang) : 0,
	                NgaySua: boPhan && boPhan.NgaySua ? boPhan.NgaySua : '',
	                GioSua: boPhan && boPhan.GioSua ? boPhan.GioSua : '',
	                Enable: 0,
	            }
	        },
	        getApiRows(result) {
	            if (Array.isArray(result) && Array.isArray(result[0])) {
	                return result[0]
	            }
	            return Array.isArray(result) ? result : []
	        },
	        async fetchBoPhanList() {
	            const result = await apiCallPromise(this.boPhanApiConfig.select)
	            return this.getApiRows(result).map(function (boPhan) {
	                return this.mapBoPhanFromApi(boPhan)
	            }, this)
	        },
	        mapDiaDiemFromApi(diaDiem) {
	            return {
	                DiaDiem_Id: Number(diaDiem && diaDiem.DiaDiem_Id ? diaDiem.DiaDiem_Id : 0),
	                TenDiaDiem: diaDiem && diaDiem.TenDiaDiem ? diaDiem.TenDiaDiem : '',
	                GhiChu: diaDiem && diaDiem.GhiChu ? diaDiem.GhiChu : '',
	                Enable: 0,
	            }
	        },
	        async fetchDiaDiemList() {
	            const result = await apiCallPromise(this.diaDiemApiConfig.select)
	            return this.getApiRows(result).map(function (diaDiem) {
	                return this.mapDiaDiemFromApi(diaDiem)
	            }, this)
	        },
	        mapQuyenFromApi(quyen) {
	            return {
	                Quyen_Id: quyen && quyen.Quyen_Id ? quyen.Quyen_Id : '',
	                NhomQuyen: quyen && quyen.NhomQuyen ? quyen.NhomQuyen : '',
	                TenQuyen: quyen && quyen.TenQuyen ? quyen.TenQuyen : '',
	                MoTa: quyen && quyen.MoTa ? quyen.MoTa : '',
	                Page_Url: quyen && quyen.Page_Url ? quyen.Page_Url : '',
	                ThuTu: Number(quyen && quyen.ThuTu ? quyen.ThuTu : 0),
	                Enable: quyen && quyen.Enable !== undefined ? Number(quyen.Enable) : 0,
	            }
	        },
	        async fetchQuyenList() {
	            const result = await apiCallPromise(this.quyenApiConfig.select)
	            return this.getApiRows(result)
	                .map(function (quyen) {
	                    return this.mapQuyenFromApi(quyen)
	                }, this)
	                .filter(function (quyen) {
	                    return !!quyen.Quyen_Id
	                })
	        },
	        mapBoPhanQuyenFromApi(assignment, boPhanId) {
	            const resolvedBoPhanId = Number(
	                assignment && assignment.BoPhan_Id !== undefined
	                    ? assignment.BoPhan_Id
	                    : boPhanId
	            )
	            const quyenId = (
	                assignment && (
	                    assignment.Quyen_Id ||
	                    assignment.QuyenID ||
	                    assignment.Ma_Quyen ||
	                    assignment.PermissionId
	                )
	            ) || ''
	            return {
	                BoPhan_Id: resolvedBoPhanId,
	                Quyen_Id: quyenId.toString().trim(),
	                Enable: assignment && assignment.Enable !== undefined ? Number(assignment.Enable) : 0,
	            }
	        },
	        getAssignmentQuyenIds(rows) {
	            return this.getUniqueList((rows || []).reduce(function (result, item) {
	                const quyenApDungID = (
	                    item && (
	                        item.QuyenApDungID ||
	                        item.QuyenApDungId ||
	                        item.ListQuyen_Id ||
	                        item.ListQuyenID
	                    )
	                )
	                if (typeof quyenApDungID === 'string') {
	                    return result.concat(
	                        quyenApDungID
	                            .split(',')
	                            .map(function (quyenId) { return quyenId.toString().trim() })
	                            .filter(function (quyenId) { return !!quyenId })
	                    )
	                }
	
	                const mappedItem = this.mapBoPhanQuyenFromApi(item)
	                if (mappedItem.Quyen_Id) { result.push(mappedItem.Quyen_Id) }
	                return result
	            }.bind(this), []))
	        },
	        mapNhanVienCatalogFromApi(nhanVien) {
	            const maNhanVien = nhanVien && nhanVien.MaNhanVien ? nhanVien.MaNhanVien : ''
	            const hoVaTenNhanVien = nhanVien && nhanVien.HoVaTenNhanVien ? nhanVien.HoVaTenNhanVien : ''
	            const tenVanPhong = nhanVien && nhanVien.TenVanPhong ? nhanVien.TenVanPhong : ''
	            return {
	                MaNhanVien: maNhanVien,
	                HoVaTenNhanVien: hoVaTenNhanVien,
	                AnhDaiDien_Url: nhanVien && nhanVien.AnhDaiDien_Url ? nhanVien.AnhDaiDien_Url : '',
	                TenVanPhong: tenVanPhong,
	                NhanVienDisplay: [maNhanVien, hoVaTenNhanVien, tenVanPhong].filter(function (item) { return !!item }).join(' - '),
	            }
	        },
	        async fetchNhanVienCatalog() {
	            const result = await apiCallPromise(this.nhanVienApiConfig.catalog)
	            return this.getApiRows(result).map(function (nhanVien) {
	                return this.mapNhanVienCatalogFromApi(nhanVien)
	            }, this)
	        },
	        mapNhanVienFromApi(nhanVien) {
	            return {
	                NhanVien_Id: Number(nhanVien && nhanVien.NhanVien_Id ? nhanVien.NhanVien_Id : 0),
	                BoPhan_Id: Number(nhanVien && nhanVien.BoPhan_Id ? nhanVien.BoPhan_Id : 0),
	                TenBoPhan: nhanVien && nhanVien.TenBoPhan ? nhanVien.TenBoPhan : '',
	                MaNhanVien: nhanVien && nhanVien.MaNhanVien ? nhanVien.MaNhanVien : '',
	                TinhTrang: nhanVien && nhanVien.TinhTrang !== undefined ? Number(nhanVien.TinhTrang) : 0,
	                SoLuongDiaDiem: Number(nhanVien && nhanVien.SoLuongDiaDiem ? nhanVien.SoLuongDiaDiem : 0),
	                Enable: 0,
	            }
	        },
	        async fetchNhanVienListByBoPhan(boPhanId) {
	            if (!boPhanId) { return [] }
	            const result = await apiCallPromise(this.nhanVienApiConfig.selectByBoPhan, { BoPhan_Id: boPhanId })
	            return this.getApiRows(result).map(function (nhanVien) {
	                return this.mapNhanVienFromApi(nhanVien)
	            }, this)
	        },
	        async fetchBoPhanQuyenListByBoPhan(boPhanId) {
	            if (!boPhanId) { return [] }
	            const result = await apiCallPromise(this.boPhanQuyenApiConfig.selectByBoPhan, { BoPhan_Id: boPhanId })
	            const rows = this.getApiRows(result)
	            const quyenIds = this.getAssignmentQuyenIds(rows)
	            return quyenIds.map(function (quyenId) {
	                return {
	                    BoPhan_Id: Number(boPhanId),
	                    Quyen_Id: quyenId,
	                    Enable: 0,
	                }
	            })
	        },
	        async fetchDiaDiemIdsByNhanVien(nhanVienId) {
	            if (!nhanVienId) { return [] }
	            const result = await apiCallPromise(this.nhanVienApiConfig.selectDiaDiemByNhanVienId, { NhanVien_Id: nhanVienId })
	            return this.getApiRows(result)
	                .map(function (item) {
	                    return Number(item && item.DiaDiem_Id ? item.DiaDiem_Id : 0)
	                })
	                .filter(function (id) {
	                    return id > 0
	                })
	        },
	        buildBoPhanSaveParams(payload) {
	            return {
	                BoPhan_Id: payload.BoPhan_Id,
	                TenBoPhan: payload.TenBoPhan,
	                MoTaNhiemVu: payload.MoTaNhiemVu,
	                Is_NhieuDiaDiem: payload.Is_NhieuDiaDiem,
	                TinhTrang: payload.TinhTrang,
	            }
	        },
	        async syncBoPhanList() {
	            const boPhanList = await this.fetchBoPhanList()
	            this.setPageData({ boPhanList: boPhanList })
	            return boPhanList
	        },
	        async syncMetaData() {
	            const result = await Promise.all([
	                this.fetchDiaDiemList(),
	                this.fetchNhanVienCatalog(),
	                this.fetchQuyenList(),
	            ])
	            this.setPageData({
	                diaDiemList: result[0],
	                nhanVienCatalog: result[1],
	                quyenList: result[2],
	            })
	        },
	        async syncNhanVienListByBoPhan(boPhanId) {
	            const nhanVienList = await this.fetchNhanVienListByBoPhan(boPhanId)
	            this.setPageData({ nhanVienList: nhanVienList })
	            return nhanVienList
	        },
	        async syncBoPhanQuyenByBoPhan(boPhanId) {
	            const boPhanQuyenList = await this.fetchBoPhanQuyenListByBoPhan(boPhanId)
	            this.setPageData({
	                boPhanQuyenList: this.replaceAssignments(this.pageData.boPhanQuyenList, 'BoPhan_Id', boPhanId, 'Quyen_Id', boPhanQuyenList.map(function (item) { return item.Quyen_Id })),
	            })
	            return boPhanQuyenList
	        },
	        async syncSelectedBoPhanData(boPhanId) {
	            if (!boPhanId) {
	                this.setPageData({ nhanVienList: [] })
	                return
	            }
	            await Promise.all([
	                this.syncNhanVienListByBoPhan(boPhanId),
	                this.syncBoPhanQuyenByBoPhan(boPhanId),
	            ])
	        },
	        async initData() {
	            this.pageData = this.createEmptyData()
	            try {
	                await this.syncBoPhanList()
	                await this.syncMetaData()
	            } catch (error) {
	                console.log(error)
	            }
	            await this.ensureSelectedBoPhan()
	        },
	        async ensureSelectedBoPhan(preferredId) {
	            const boPhanList = this.boPhanList
	            if (!boPhanList.length) {
	                this.selectedBoPhanId = null
	                this.setPageData({ nhanVienList: [], boPhanQuyenList: [] })
	                return
	            }
	            let nextBoPhanId = this.selectedBoPhanId
	            if (preferredId && boPhanList.some(function (item) { return item.BoPhan_Id === preferredId })) {
	                nextBoPhanId = preferredId
	            } else if (!this.selectedBoPhanId || !boPhanList.some(function (item) { return item.BoPhan_Id === this.selectedBoPhanId }, this)) {
	                nextBoPhanId = boPhanList[0].BoPhan_Id
	            }
	            if (this.selectedBoPhanId !== nextBoPhanId) {
	                this.selectedBoPhanId = nextBoPhanId
	            }
	            await this.syncSelectedBoPhanData(this.selectedBoPhanId)
	        },
	        replaceAssignments(sourceList, ownerKey, ownerId, itemKey, selectedIds) {
	            return sourceList
	                .filter(function (item) { return item[ownerKey] !== ownerId })
	                .concat(selectedIds.map(function (itemId) {
	                    const assignment = { Enable: 0 }
	                    assignment[ownerKey] = ownerId
	                    assignment[itemKey] = itemId
	                    return assignment
	                }))
	        },
	        getBoPhanById(boPhanId) {
	            return this.boPhanList.find(function (item) { return item.BoPhan_Id === boPhanId }) || null
	        },
	        getQuyenIdsByBoPhan(boPhanId) {
	            return this.getUniqueList(this.boPhanQuyenList.filter(function (item) { return item.BoPhan_Id === boPhanId }).map(function (item) { return item.Quyen_Id }))
	        },
	        getQuyenByBoPhan(boPhanId) {
	            const quyenIds = this.getQuyenIdsByBoPhan(boPhanId)
	            return quyenIds.map(function (quyenId) {
	                return this.quyenList.find(function (item) { return item.Quyen_Id === quyenId }) || null
	            }, this).filter(function (item) { return !!item })
	        },
	        getDiaDiemByNhanVien(nhanVienId) {
	            const diaDiemIds = this.selectedNhanVienId === nhanVienId ? this.selectedNhanVienDiaDiemIds : []
	            return diaDiemIds.map(function (diaDiemId) {
	                return this.diaDiemList.find(function (item) { return item.DiaDiem_Id === diaDiemId }) || null
	            }, this).filter(function (item) { return !!item })
	        },
	        buildNhanVienView(nhanVien) {
	            const boPhan = this.getBoPhanById(nhanVien.BoPhan_Id)
	            const nhanVienCatalog = this.nhanVienCatalog.find(function (item) {
	                return item.MaNhanVien === nhanVien.MaNhanVien
	            }) || null
	            const diaDiemList = this.getDiaDiemByNhanVien(nhanVien.NhanVien_Id)
	            return Object.assign({}, nhanVien, {
	                TenBoPhan: nhanVien.TenBoPhan || (boPhan ? boPhan.TenBoPhan : 'Chưa xác định'),
	                HoVaTenNhanVien: nhanVienCatalog ? nhanVienCatalog.HoVaTenNhanVien : '',
	                AnhDaiDien_Url: nhanVienCatalog ? nhanVienCatalog.AnhDaiDien_Url : '',
	                TenVanPhong: nhanVienCatalog ? nhanVienCatalog.TenVanPhong : '',
	                DiaDiemNames: diaDiemList.map(function (item) { return item.TenDiaDiem }),
	                SoDiaDiem: diaDiemList.length,
	            })
	        },
	        buildBoPhanSummary(boPhan) {
	            const nhanVienByBoPhan = this.nhanVienListView.filter(function (nhanVien) { return nhanVien.BoPhan_Id === boPhan.BoPhan_Id })
	            return Object.assign({}, boPhan, {
	                MoTa: boPhan.MoTaNhiemVu || '',
	                SoNhanVien: boPhan.SoNhanVien !== null && boPhan.SoNhanVien !== undefined ? boPhan.SoNhanVien : nhanVienByBoPhan.length,
	                SoQuyen: Number(boPhan && boPhan.SoQuyen !== undefined ? boPhan.SoQuyen : 0),
	            })
	        },
	        async onSelectBoPhan(boPhan) {
	            this.selectedBoPhanId = boPhan ? boPhan.BoPhan_Id : null
	            this.activeTab = 'quyen'
	            this.selectedNhanVienId = null
	            this.selectedNhanVienDiaDiemIds = []
	            await this.syncSelectedBoPhanData(this.selectedBoPhanId)
	        },
	        updateActiveTab(tab) {
	            this.activeTab = tab
	        },
	        openBoPhanForm(boPhan) {
	            if (boPhan) {
	                this.isBoPhanEdit = true
	                this.boPhanFormData = this.copyBoPhanFormData(boPhan)
	            } else {
	                this.isBoPhanEdit = false
	                this.boPhanFormData = this.copyBoPhanFormData()
	            }
	            this.isShowBoPhanForm = true
	        },
	        async saveBoPhan(formData) {
	            const payload = this.normalizeBoPhanPayload(formData)
	            const params = this.buildBoPhanSaveParams(payload)
	            if (this.isBoPhanEdit) {
	                await apiCallPromise(this.boPhanApiConfig.update, params)
	                showToast.success('Cập nhật bộ phận thành công!')
	            } else {
	                await apiCallPromise(this.boPhanApiConfig.insert, params)
	                showToast.success('Thêm mới bộ phận thành công!')
	            }
	            const boPhanList = await this.syncBoPhanList()
	            const matchedBoPhan = boPhanList.find(function (item) { return item.TenBoPhan === payload.TenBoPhan })
	            this.isShowBoPhanForm = false
	            await this.ensureSelectedBoPhan(matchedBoPhan ? matchedBoPhan.BoPhan_Id : payload.BoPhan_Id)
	        },
	        deleteBoPhan(boPhan) {
	            if (!boPhan) { return }
	            showConfirm('Bạn chắc chắn muốn xóa bộ phận? <br/> <b>' + boPhan.TenBoPhan + '</b>', async () => {
	                const nhanVienList = await this.fetchNhanVienListByBoPhan(boPhan.BoPhan_Id)
	                if (nhanVienList.length > 0) {
	                    showToast.info('Không thể xóa bộ phận đang còn nhân viên. Hãy chuyển hoặc xóa nhân viên trước.')
	                    return
	                }
	                await apiCallPromise(this.boPhanApiConfig.delete, { BoPhan_Id: boPhan.BoPhan_Id })
	                await this.syncBoPhanList()
	                this.setPageData({
	                    boPhanQuyenList: this.boPhanQuyenList.filter(function (item) { return item.BoPhan_Id !== boPhan.BoPhan_Id }),
	                })
	                if (this.selectedBoPhanId === boPhan.BoPhan_Id) { this.selectedBoPhanId = null }
	                await this.ensureSelectedBoPhan()
	                showToast.success('Xóa bộ phận thành công!')
	            })
	        },
	        async openQuyenForm(boPhan) {
	            if (boPhan) { this.selectedBoPhanId = boPhan.BoPhan_Id }
	            if (!this.selectedBoPhanId) { showToast.info('Vui lòng chọn bộ phận trước khi cấu hình quyền.'); return }
	            await this.syncBoPhanQuyenByBoPhan(this.selectedBoPhanId)
	            this.isShowQuyenForm = true
	        },
	        async saveQuyenAssignment(selectedQuyenIds) {
	            const boPhanId = this.selectedBoPhanId
	            await apiCallPromise(this.boPhanQuyenApiConfig.update, {
	                BoPhan_Id: boPhanId,
	                QuyenApDungID: this.buildQuyenApDungID(selectedQuyenIds),
	            })
	            await this.syncBoPhanQuyenByBoPhan(boPhanId)
	            await this.syncBoPhanList()
	            this.isShowQuyenForm = false
	            showToast.success('Cập nhật quyền thành công!')
	        },
	        openNhanVienForm(nhanVien) {
	            if (!this.selectedBoPhanId && !nhanVien) { showToast.info('Vui lòng chọn bộ phận trước khi thêm nhân viên.'); return }
	            if (nhanVien) {
	                this.isNhanVienEdit = true
	                this.nhanVienFormData = this.copyNhanVienFormData(nhanVien)
	            } else {
	                this.isNhanVienEdit = false
	                this.nhanVienFormData = this.copyNhanVienFormData({ BoPhan_Id: this.selectedBoPhanId })
	            }
	            this.isShowNhanVienForm = true
	        },
	        async saveNhanVien(formData) {
	            const payload = this.normalizeNhanVienPayload(formData)
	            const targetBoPhanId = payload.BoPhan_Id
	            const params = {
	                NhanVien_Id: payload.NhanVien_Id,
	                BoPhan_Id: payload.BoPhan_Id,
	                MaNhanVien: payload.MaNhanVien,
	                TinhTrang: payload.TinhTrang,
	            }
	            if (this.isNhanVienEdit) {
	                await apiCallPromise(this.nhanVienApiConfig.update, params)
	                showToast.success('Cập nhật nhân viên thành công!')
	            } else {
	                await apiCallPromise(this.nhanVienApiConfig.insert, {
	                    BoPhan_Id: payload.BoPhan_Id,
	                    MaNhanVien: payload.MaNhanVien,
	                    TinhTrang: payload.TinhTrang,
	                })
	                showToast.success('Thêm mới nhân viên thành công!')
	            }
	            this.isShowNhanVienForm = false
	            await this.ensureSelectedBoPhan(targetBoPhanId)
	            this.activeTab = 'nhan-vien'
	        },
	        deleteNhanVien(nhanVien) {
	            if (!nhanVien) { return }
	            const tenNhanVien = nhanVien.HoVaTenNhanVien || nhanVien.MaNhanVien
	            showConfirm('Bạn chắc chắn muốn xóa nhân viên? <br/> <b>' + tenNhanVien + '</b>', async () => {
	                const isSelectedNhanVien = this.selectedNhanVienId === nhanVien.NhanVien_Id
	                await apiCallPromise(this.nhanVienApiConfig.delete, { NhanVien_Id: nhanVien.NhanVien_Id })
	                await this.syncNhanVienListByBoPhan(this.selectedBoPhanId)
	                if (isSelectedNhanVien) {
	                    this.selectedNhanVienId = null
	                    this.selectedNhanVienDiaDiemIds = []
	                }
	                showToast.success('Xóa nhân viên thành công!')
	            })
	        },
	        async openDiaDiemForm(nhanVien) {
	            if (!nhanVien) { return }
	            this.selectedNhanVienId = nhanVien.NhanVien_Id
	            this.selectedNhanVienDiaDiemIds = await this.fetchDiaDiemIdsByNhanVien(nhanVien.NhanVien_Id)
	            this.activeTab = 'nhan-vien'
	            this.isShowDiaDiemForm = true
	        },
	        async saveDiaDiemAssignment(selectedDiaDiemIds) {
	            const nhanVienId = this.selectedNhanVienId
	            await apiCallPromise(this.nhanVienApiConfig.updateDiaDiem, {
	                NhanVien_Id: nhanVienId,
	                DiaDiemApDungID: this.buildDiaDiemApDungID(selectedDiaDiemIds),
	            })
	            this.selectedNhanVienDiaDiemIds = selectedDiaDiemIds.slice()
	            this.isShowDiaDiemForm = false
	            await this.syncNhanVienListByBoPhan(this.selectedBoPhanId)
	            showToast.success('Cập nhật địa điểm thành công!')
	        },
	    },
	}
</script>