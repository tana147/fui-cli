<template>
	<v-dialog v-model="modelValue" max-width="1300" scrollable>
		<v-card>
			<template v-slot:title>Cập nhật nguyên liệu</template>
			<template v-slot:append>
				<v-btn size="small" variant="text" icon="mdi-close" @click="onClose" />
			</template>

			<v-card-text class="pa-0" style="padding-top: 0 !important">
				<v-sheet class="d-flex supplier-tabs-sheet" elevation="0">
					<v-tabs v-model="activeTab" color="primary" direction="vertical" class="supplier-tabs-nav">
						<v-tab value="info" prepend-icon="mdi-information-slab-circle-outline">Thông tin</v-tab>
						<v-tab value="conversion" prepend-icon="mdi-swap-horizontal">Chuyển đổi đơn vị</v-tab>
						<v-tab value="minimum-stock" prepend-icon="mdi-warehouse">Tồn tối thiểu</v-tab>
						<v-tab value="location" prepend-icon="mdi-map-marker-outline">Địa điểm áp dụng</v-tab>
					</v-tabs>
					<v-divider vertical></v-divider>
					<v-tabs-window v-model="activeTab" class="flex-fill supplier-tabs-window">
						<v-tabs-window-item value="info">
							<uc-modal-update-nguyen-lieu-tab-info ref="infoTab" :record-data="recordData"
								:LoaiThanhPhanList="LoaiThanhPhanList" :DsTrangThai="DsTrangThai"
								:on-load-nhom-tinh-chat="onLoadNhomTinhChat" :on-load-nhom-vat-tu="onLoadNhomVatTu"
								:on-load-nhom-ten-san-pham="onLoadNhomTenSanPham" @saved="onTabSaved" />
						</v-tabs-window-item>

						<v-tabs-window-item value="conversion">
							<uc-modal-update-nguyen-lieu-tab-conversion :record-data="recordData"
								:active="activeTab === 'conversion'" @reloaded="onTabSaved" />
						</v-tabs-window-item>

						<v-tabs-window-item value="minimum-stock">
							<uc-modal-update-nguyen-lieu-tab-minimum-stock :record-data="recordData"
								:active="activeTab === 'minimum-stock'" @reloaded="onTabSaved" />
						</v-tabs-window-item>

						<v-tabs-window-item value="location">
							<uc-modal-update-nguyen-lieu-tab-location ref="locationTab" :record-data="recordData"
								:active="activeTab === 'location'" @reloaded="onTabSaved" />
						</v-tabs-window-item>
					</v-tabs-window>
				</v-sheet>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn v-if="activeTab === 'info' || activeTab === 'location'" color="primary"
					prepend-icon="mdi-content-save-outline" variant="flat" @click="onSaveActiveTab">Lưu</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
	    props: ['modelValue', 'record', 'initialTab', 'onLoadNhomTinhChat', 'onLoadNhomVatTu', 'onLoadNhomTenSanPham', 'onLoadNguyenLieu', 'LoaiThanhPhanList', 'DsTrangThai'],
	    emits: ['update:modelValue', 'onReload', 'loadnhomnguyenlieu'],
	    data() {
	        return {
	            activeTab: 'info',
	            recordData: null,
	        }
	    },
	    watch: {
	        modelValue(val) {
	            if (val && this.record) {
	                this.activeTab = this.initialTab || 'info'
	                this.recordData = JSON.parse(JSON.stringify(this.record))
	                this.recordData.DonGia_ApDung = this.recordData.DonGia_ApDung?.toLocaleString('vi-VN')
	                this.recordData.GiaBan = this.recordData.GiaBan?.toLocaleString('vi-VN')
	                this.recordData.PhanLoai_NhomSanPham_Id = this.recordData.PhanLoai_NhomSanPham_Id ? this.recordData.PhanLoai_NhomSanPham_Id : 0
	            } else if (!val) {
	                this.recordData = null
	            }
	        },
	    },
	    methods: {
	        onTabSaved() {
	            this.$emit('onReload')
	        },
	        onSaveActiveTab() {
	            if (this.activeTab === 'info') {
	                this.$refs.infoTab?.save?.()
	                return
	            }
	            if (this.activeTab === 'location') {
	                this.$refs.locationTab?.save?.()
	            }
	        },
	        onClose() {
	            this.activeTab = 'info'
	            this.recordData = null
	            this.$emit('update:modelValue', false)
	        },
	    },
	}
</script>