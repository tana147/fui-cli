<template>
	<z-layout>
		<v-app-bar density="compact" :elevation="0" title="Báo cáo" class="border-b">
			<template v-slot:append>
			</template>
		</v-app-bar>

		<div class="pa-2 border-b border-t">
			<v-row dense>
				<v-col cols="12" md="1">
					<v-select v-model="Filters.Nam" density="compact" :items="DsNam" item-value="value"
						item-title="title" label="Năm">
					</v-select>
				</v-col>
				<v-col cols="12" md="1">
					<v-select v-model="Filters.Thang" density="compact" :items="DsThang" item-value="value"
						item-title="title" label="Tháng">
					</v-select>
				</v-col>
				<v-col cols="12" md="3">
					<v-autocomplete v-model="Filters.DiaDiem_Id" density="compact" :items="DsDiaDiem"
						item-value="DiaDiem_Id" item-title="TenDiaDiem" label="Địa điểm">
					</v-autocomplete>
				</v-col>
				<v-col cols="auto">
					<v-btn color="primary" prepend-icon="mdi-plus" variant="flat" @click="onCreate()"
						:disabled="isDisabled">Tạo báo
						cáo</v-btn>
				</v-col>
				<v-col cols="auto">
					<v-btn color="grey" prepend-icon="mdi-refresh" variant="flat" @click="onReload()"
						:disabled="isDisabled">Làm mới</v-btn>
				</v-col>
			</v-row>
		</div>

		<v-sheet elevation="2">
			<v-tabs v-model="tab" color="primary">
				<v-tab value="BienDongGia">Biến động giá</v-tab>
				<v-tab value="BaoMuaHangHoaDinhKi">Báo mua hàng hóa (định kì)</v-tab>
				<v-tab value="BaoMuaHangHoaMoiNgay">Báo mua hàng hóa (mỗi ngày)</v-tab>
				<v-tab value="CongNo">Công nợ</v-tab>
			</v-tabs>

			<v-divider></v-divider>

			<v-tabs-window v-model="tab">
				<v-tabs-window-item value="BienDongGia">
					<v-sheet>
						<uc-bien-dong-gia :DsBienDongGia="DsBienDongGia" />
					</v-sheet>
				</v-tabs-window-item>
				<v-tabs-window-item value="BaoMuaHangHoaDinhKi">
					<v-sheet>
						<uc-mua-hang-dinh-ki />
					</v-sheet>
				</v-tabs-window-item>
				<v-tabs-window-item value="BaoMuaHangHoaMoiNgay">
					<v-sheet>
						<uc-mua-hang-moi-ngay />
					</v-sheet>
				</v-tabs-window-item>
				<v-tabs-window-item value="CongNo">
					<v-sheet>
						<uc-cong-no />
					</v-sheet>
				</v-tabs-window-item>
			</v-tabs-window>
		</v-sheet>


	</z-layout>
</template>

<script>
	export default {
		data() {
			return {
				vueData,
				DsDiaDiem: [],
				DsNam: [],
				DsThang: [],
	
				DsBienDongGia: [],
				DsMuaHangDinhKi: [],
				DsMuaHangMoiNgay: [],
				DsCongNo: [],
	
				Filters: [
					Nam = null,
					Thang = null,
					DiaDiem_Id = null,
				],
	
				tab: "BienDongGia",
			}
		},
		mounted() {
			this.onLoadDiaDiem()
			const currentYear = new Date().getFullYear();
			const years = [];
			const count = 10;
			for (let i = 0; i < count; i++) { years.push({ title: currentYear - i, value: currentYear - i }); }
			this.DsThang = this.getMonthsByYear(currentYear)
			this.DsNam = years
			this.Filters.Nam = currentYear
			this.Filters.Thang = new Date().getMonth() + 1
		},
		computed: {
			isDisabled() {
				if (!this.Filters.Nam || !this.Filters.Thang || !this.Filters.DiaDiem_Id) {
					return true
				}
			}
		},
		methods: {
			async onLoadDiaDiem() {
				const data = await apiCallPromise('/work/HH_DiaDiem_Select')
				this.DsDiaDiem = data
			},
	
			async onCreate() {
				vueData.Nam = Number(this.Filters.Nam)
				vueData.Thang = Number(this.Filters.Thang)
				vueData.DiaDiem_Id = Number(this.Filters.DiaDiem_Id)
	
				if (this.tab === "BienDongGia") {
					const dataBienDongGia = await apiCallPromise('/work/HH_BaoCao_BienDongGia', {
						Nam: vueData.Nam,
						Thang: vueData.Thang,
						DiaDiem_Id: vueData.DiaDiem_Id
					})
					this.DsBienDongGia = dataBienDongGia
					console.log('Danh sách biến động giá: ', this.DsBienDongGia)
				}
				showToast.success('Tạo báo cáo thành công!')
			},
	
			async onReload() {
				if (this.tab === "BienDongGia") {
					const dataBienDongGia = await apiCallPromise('/work/HH_BaoCao_BienDongGia', {
						Nam: vueData.Nam,
						Thang: vueData.Thang,
						DiaDiem_Id: vueData.DiaDiem_Id
					})
					this.DsBienDongGia = dataBienDongGia
					console.log('Danh sách biến động giá: ', this.DsBienDongGia)
				}
	
				showToast.success('Làm mới thành công!')
			},
	
			onSearch() {
				vueData.Nam = this.Filters.Nam
				vueData.Thang = this.Filters.Thang
				vueData.DiaDiem_Id = this.Filters.DiaDiem_Id
			},
	
			getMonthsByYear(selectedYear) {
				const now = new Date();
				const currentYear = now.getFullYear();
				const currentMonth = now.getMonth() + 1;
	
				const maxMonth = selectedYear === currentYear ? currentMonth : 12;
	
				return Array.from({ length: maxMonth }, (_, i) => ({
					title: `Tháng ${i + 1}`,
					value: i + 1
				})).reverse()
			},
		},
	}
</script>