<template>
    <div class="panel panel--detail">
        <div class="detail-hero">
            <div class="detail-hero__content">
                <div class="detail-hero__kicker">Scope phân quyền đang chọn</div>
                <div class="detail-hero__title">{{ selectedBoPhan.TenBoPhan }}</div>
                <div class="detail-hero__description">
                    {{ selectedBoPhan.MoTa || 'Chưa cập nhật mô tả cho bộ phận này.' }}</div>
                <div class="d-flex flex-wrap ga-2">
                    <v-chip size="small" color="primary" variant="tonal" prepend-icon="mdi-account-group-outline">{{
                        selectedBoPhan.SoNhanVien }} nhân viên</v-chip>
                    <v-chip size="small" color="info" variant="tonal" prepend-icon="mdi-shield-check-outline">{{
                        selectedBoPhan.SoQuyen }} quyền hiệu lực</v-chip>
                </div>
            </div>

            <div class="detail-hero__actions">
                <v-btn color="primary" variant="flat" prepend-icon="mdi-plus" @click="onAddNhanVien">Thêm nhân
                    viên</v-btn>
                <v-btn color="primary" variant="outlined" prepend-icon="mdi-lock-outline" @click="onConfigQuyen">Cấu
                    hình quyền</v-btn>
                <v-btn color="default" variant="text" prepend-icon="mdi-pencil-outline" @click="onEditBoPhan">Sửa bộ
                    phận</v-btn>
            </div>
        </div>

        <div v-if="selectedBoPhan.SoQuyen === 0" class="warning-banner">
            <v-icon size="18" color="warning">mdi-alert-outline</v-icon>
            <span>Bộ phận này chưa có quyền hiệu lực. Nhân viên thuộc bộ phận có thể đang không thao tác được gì trên hệ
                thống.</span>
        </div>

        <div class="impact-strip">
            <div class="impact-strip__item">
                <div class="impact-strip__label">Phạm vi áp dụng</div>
                <div class="impact-strip__value">Toàn bộ {{ selectedBoPhan.SoNhanVien }} nhân sự của bộ phận
                </div>
            </div>
            <div class="impact-strip__item">
                <div class="impact-strip__label">Ảnh hưởng hiện tại</div>
                <div class="impact-strip__value">{{ selectedBoPhan.SoQuyen }} quyền đang áp dụng cho bộ phận
                    này</div>
            </div>
            <div class="impact-strip__item">
                <div class="impact-strip__label">Ưu tiên xử lý</div>
                <div class="impact-strip__value">{{ priorityMessage }}</div>
            </div>
        </div>

        <v-tabs v-model="activeTabStr" color="primary" class="detail-tabs">
            <v-tab value="quyen">Quyền hệ thống</v-tab>
            <v-tab value="nhan-vien">Nhân sự áp dụng</v-tab>
        </v-tabs>

        <v-window v-model="activeTabStr">
            <v-window-item value="quyen">
                <div class="info-card">
                    <div class="text-subtitle-1 font-weight-bold mb-1">Quyền đang có hiệu lực</div>
                    <div class="text-body-2 text-medium-emphasis mb-3">{{ selectedBoPhanQuyenSummaries.length }} màn
                        hình đang
                        áp dụng cho toàn bộ nhân sự thuộc bộ phận này</div>
                    <div v-if="selectedBoPhanQuyenSummaries.length" class="d-flex flex-wrap ga-2">
                        <v-tooltip v-for="permissionSummary in selectedBoPhanQuyenSummaries"
                            :key="permissionSummary.pageLabel" location="top">
                            <template v-slot:activator="{ props }">
                                <v-chip v-bind="props" size="small" color="primary" variant="tonal">
                                    {{ permissionSummary.pageLabel }} · {{ permissionSummary.statusLabel }}
                                </v-chip>
                            </template>
                            {{ permissionSummary.actionsText }}
                        </v-tooltip>
                    </div>
                    <div v-else class="empty-inline">Bộ phận này chưa được gán quyền nào.</div>
                </div>
            </v-window-item>

            <v-window-item value="nhan-vien">
                <uc-list-nhan-vien :nhanVienList="nhanVienList" :selectedBoPhan="selectedBoPhan"
                    @add-nhan-vien="onAddNhanVien" @edit-nhan-vien="onEditNhanVien" @delete-nhan-vien="onDeleteNhanVien"
                    @assign-dia-diem="onAssignDiaDiem" />
            </v-window-item>
        </v-window>
    </div>
</template>

<script>
    export default {
    name: 'uc-detail-bo-phan',
    props: {
        selectedBoPhan: {
            type: Object,
            required: true
        },
        selectedBoPhanQuyenSummaries: {
            type: Array,
            default: () => []
        },
        priorityMessage: {
            type: String,
            default: ''
        },
        nhanVienList: {
            type: Array,
            default: () => []
        },
        activeTab: {
            type: String,
            default: 'quyen'
        }
    },
    emits: ['edit-bo-phan', 'config-quyen', 'add-nhan-vien', 'edit-nhan-vien', 'delete-nhan-vien', 'assign-dia-diem', 'update:activeTab'],
    computed: {
        activeTabStr: {
            get() {
                return this.activeTab
            },
            set(val) {
                this.$emit('update:activeTab', val)
            }
        }
    },
    methods: {
        onEditBoPhan() {
            this.$emit('edit-bo-phan', this.selectedBoPhan)
        },
        onConfigQuyen() {
            this.$emit('config-quyen', this.selectedBoPhan)
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
    }
}
</script>