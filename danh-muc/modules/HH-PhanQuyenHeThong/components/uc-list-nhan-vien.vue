<template>
    <div>
        <div class="section-head--responsive d-flex align-start justify-space-between ga-3 mb-4">
            <div>
                <div class="text-h6 font-weight-bold">Nhân sự áp dụng</div>
                <div class="text-body-2 text-medium-emphasis mt-1">
                    <span v-if="selectedBoPhan">
                        {{ filteredList.length }} / {{ nhanVienList.length }} nhân viên của {{ selectedBoPhan.TenBoPhan
                        }}
                    </span>
                    <span v-else>Chọn bộ phận để bắt đầu quản lý nhân sự</span>
                </div>
            </div>

            <div class="d-flex align-center flex-wrap ga-3 w-100">
                <v-text-field v-model="searchKeyword" label="Tìm theo mã, tên hoặc văn phòng"
                    prepend-inner-icon="mdi-magnify" variant="outlined" density="comfortable" clearable hide-details
                    class="search-field--compact" />
            </div>
        </div>

        <div v-if="selectedBoPhan && filteredList.length" class="table-wrap">
            <v-table density="comfortable" class="data-table">
                <thead>
                    <tr>
                        <th>Nhân viên</th>
                        <th>Trạng thái áp dụng</th>
                        <th>Địa điểm</th>
                        <th class="text-center">Hành động</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="nhanVien in filteredList" :key="nhanVien.NhanVien_Id">
                        <td>
                            <div class="data-table__title">{{ nhanVien.HoVaTenNhanVien || nhanVien.MaNhanVien }}</div>
                            <div class="data-table__meta">{{ nhanVien.MaNhanVien }} · {{ nhanVien.TenVanPhong || 'Chưa
                                cập nhật văn phòng' }}</div>
                        </td>
                        <td>
                            <div class="d-flex flex-column align-start ga-2">
                                <v-chip size="small" :color="nhanVien.TinhTrang === 0 ? 'success' : 'warning'"
                                    variant="tonal">
                                    {{ nhanVien.TinhTrang === 0 ? 'Hoạt động' : 'Tạm khóa' }}</v-chip>
                                <v-chip size="small" :color="nhanVien.SoLuongDiaDiem > 0 ? 'success' : 'warning'"
                                    variant="tonal">
                                    {{ nhanVien.SoLuongDiaDiem > 0 ? 'Đã gán địa điểm' : 'Chưa gán địa điểm' }}
                                </v-chip>
                            </div>
                        </td>
                        <td>
                            <div v-if="nhanVien.DiaDiemNames && nhanVien.DiaDiemNames.length"
                                class="d-flex flex-wrap ga-2">
                                <v-chip v-for="tenDiaDiem in getDiaDiemPreview(nhanVien)"
                                    :key="nhanVien.NhanVien_Id + '-' + tenDiaDiem" size="x-small" color="success"
                                    variant="tonal">
                                    {{ tenDiaDiem }}
                                </v-chip>
                                <v-chip v-if="nhanVien.DiaDiemNames.length > 2" size="x-small" color="default"
                                    variant="outlined">
                                    +{{ nhanVien.DiaDiemNames.length - 2 }}
                                </v-chip>
                            </div>
                            <div v-else-if="nhanVien.SoLuongDiaDiem > 0" class="empty-inline">{{ nhanVien.SoLuongDiaDiem
                                }} địa điểm đang áp dụng</div>
                            <div v-else class="empty-inline">Chưa gán địa điểm</div>
                        </td>
                        <td class="text-center">
                            <div class="d-inline-flex align-center justify-center ga-1 flex-wrap">
                                <v-btn size="small" class="location-action-btn"
                                    :color="nhanVien.SoLuongDiaDiem > 0 ? 'success' : 'primary'"
                                    :variant="nhanVien.SoLuongDiaDiem > 0 ? 'tonal' : 'flat'"
                                    :prepend-icon="nhanVien.SoLuongDiaDiem > 0 ? 'mdi-map-marker-check-outline' : 'mdi-map-marker-plus-outline'"
                                    @click="onAssignDiaDiem(nhanVien)">
                                    <span class="location-action-btn__content">
                                        <span class="location-action-btn__label">
                                            {{ nhanVien.SoLuongDiaDiem > 0 ? 'Cập nhật địa điểm' : 'Gán địa điểm' }}
                                        </span>
                                        <span class="location-action-btn__meta">{{ getDiaDiemActionMeta(nhanVien) }}
                                        </span>
                                    </span>
                                </v-btn>
                                <v-btn size="small" variant="text" icon="mdi-pencil-outline"
                                    @click="onEditNhanVien(nhanVien)" />
                                <v-btn size="small" variant="text" icon="mdi-trash-can-outline"
                                    @click="onDeleteNhanVien(nhanVien)" />
                            </div>
                        </td>
                    </tr>
                </tbody>
            </v-table>
        </div>

        <div v-else class="empty-wrap">
            <uc-empty
                :text="selectedBoPhan ? (searchKeyword ? 'Không tìm thấy nhân viên phù hợp' : 'Bộ phận này chưa có nhân viên') : 'Vui lòng chọn bộ phận để xem danh sách nhân sự áp dụng'" />
        </div>
    </div>
</template>

<script>
    export default {
    name: 'uc-list-nhan-vien',
    props: {
        nhanVienList: { type: Array, required: true },
        selectedBoPhan: { type: Object, default: null },
    },
    emits: ['add-nhan-vien', 'edit-nhan-vien', 'delete-nhan-vien', 'assign-dia-diem'],
    data() {
        return {
            searchKeyword: '',
        }
    },
    computed: {
        filteredList() {
            const keyword = this.normalizeText(this.searchKeyword)
            if (!keyword) { return this.nhanVienList }
            return this.nhanVienList.filter(function (nhanVien) {
                return (
                    this.normalizeText(nhanVien.MaNhanVien).includes(keyword) ||
                    this.normalizeText(nhanVien.HoVaTenNhanVien).includes(keyword) ||
                    this.normalizeText(nhanVien.TenVanPhong).includes(keyword) ||
                    this.normalizeText(nhanVien.TenBoPhan).includes(keyword)
                )
            }, this)
        },
    },
    methods: {
        normalizeText(value) {
            return (value || '').toString().trim().toLowerCase()
        },
        getDiaDiemPreview(nhanVien) {
            return (nhanVien.DiaDiemNames || []).slice(0, 2)
        },
        getDiaDiemActionMeta(nhanVien) {
            const soLuongDiaDiem = Number(nhanVien && nhanVien.SoLuongDiaDiem ? nhanVien.SoLuongDiaDiem : 0)
            if (soLuongDiaDiem > 0) {
                return soLuongDiaDiem + ' địa điểm đang áp dụng'
            }
            return 'Chưa có phạm vi quản lý'
        },
        onAddNhanVien() {
            this.$emit('add-nhan-vien')
        },
        onEditNhanVien(nhanVien) {
            this.$emit('edit-nhan-vien', nhanVien)
        },
        onDeleteNhanVien(nhanVien) {
            this.$emit('delete-nhan-vien', nhanVien)
        },
        onAssignDiaDiem(nhanVien) {
            this.$emit('assign-dia-diem', nhanVien)
        },
    },
}
</script>