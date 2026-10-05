<template>
	<v-dialog fullscreen>
		<template v-slot:activator="{ props: activatorProps }">
			<v-btn v-bind="activatorProps" color="primary" variant="outlined" prepend-icon="mdi-import">
				{{ currentIsEn ? 'Import' : 'Import' }}
			</v-btn>
		</template>
		<template v-slot:default="{ isActive }">
			<v-card :title="currentIsEn ? 'Import Data' : 'Import dữ liệu'">
				<v-card-text class="pa-0">
					<uc-jexcel v-model:dataSource="dataSource" :columns="columns" :minDimensions="[0, 100]"
						style="max-height: calc(100dvh - 148px); overflow: auto" />
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn color="grey" @click="isActive.value = false">{{ currentIsEn ? 'Close' : 'Đóng' }}</v-btn>
					<v-btn color="primary" @click="saveData(isActive)" variant="elevated">{{ currentIsEn ? 'Import' : 'Import' }}</v-btn>
				</v-card-actions>
			</v-card>
		</template>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			CapID: Number,
			LopItem: Object,
			onLoadFinish: Function,
			isEn: {
				type: Boolean,
				default: undefined
			}
		},
		data() {
			return {
				localIsEn: JSON.parse(localStorage.getItem('IsLanguage')) ?? false,
				dataSource: [],
				columns: [
					{ title: "HocSinhID", name: "HocSinhID" },
					{ title: "HoTen", name: "HoTen" },
					{ title: "TenLop", name: "TenLop" },
					{ title: "GioiTinh", name: "GioiTinh" },
					{ title: "NgaySinh", name: "NgaySinh" },
					{ title: "ThoiGianThi", name: "ThoiGianThi" },
					{ title: "HocKi", name: "HocKi" },
					{ title: "TenCuocThi", name: "TenCuocThi" },
					{ title: "LinhVucDuAn", name: "LinhVucDuAn" },
					{ title: "MoTaNganGonNoiDung_MucTieu", name: "MoTaNganGonNoiDung_MucTieu" },
					{ title: "GVHuongDan", name: "GVHuongDan" },
					{ title: "To_BoPhan", name: "To_BoPhan" },
					{ title: "GV_ToHoTro", name: "GV_ToHoTro" },
					{ title: "ToChucCongNhan", name: "ToChucCongNhan" },
					{ title: "CapDoGiaiThuong", name: "CapDoGiaiThuong" },
					{ title: "GiaiThuongDatDuoc", name: "GiaiThuongDatDuoc" },
					{ title: "MinhChung_SoHieuQD_LinkChungNhan", name: "MinhChung_SoHieuQD_LinkChungNhan" },
					{ title: "GhiChuBoSung", name: "GhiChuBoSung" }
				],
				DSHocSinh: [],
				vueData
			}
		},
		computed: {
			currentIsEn() {
				return this.isEn !== undefined ? this.isEn : this.localIsEn
			}
		},
		watch: {
			LopItem: function (LopItem) {
				this.onLoadHS()
			}
		},
		mounted() {
			window.addEventListener('storage', this.handleStorageChange)
		},
		beforeUnmount() {
			window.removeEventListener('storage', this.handleStorageChange)
		},
		methods: {
			handleStorageChange(e) {
				if (e.key === 'IsLanguage') {
					this.localIsEn = JSON.parse(e.newValue) ?? false
				}
			},
			async onLoadHS() {
				if (!this.LopItem?.LopID) return
				this.DSHocSinh = await ajaxCALLPromise("lms/HocSinhLop_Get_ByLopID", { NienKhoa: vueData.NienKhoa, LopID: this.LopItem.LopID })
			},
			async saveData(isActive) {
				const dataSource = this.dataSource.filter(x => !!x.HocSinhID)
				ajaxCALLPromise('lms/TongHopDuLieuCuocThi_Ins_Multiple', { JSON_HocSinh: dataSource, NienKhoa: vueData.NienKhoa })
					.then(() => {
						Vue.$toast.success(this.currentIsEn ? "Imported successfully" : "Import thành công", { position: "top" })
						this.$emit('onLoadFinish')
						isActive.value = false
					})
			},
			renderTitle(item) {
				return `[${item.HocSinhID}] ${item.HoTen} - ${item.TenLop}`
			}
		},
	}
</script>