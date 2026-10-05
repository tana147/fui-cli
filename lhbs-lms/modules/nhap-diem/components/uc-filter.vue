<template>
	<v-row>
		<v-col cols="6" sm="6" md="4" lg="2">
			<v-select :key="'khoi_' + isEn" :label="isEn ? 'Select grade' : 'Chọn khối'" v-model="form.KhoiItem" :items="DSKhoi"
				:item-title="formatKhoiHienThi" item-value="KhoiID" return-object
				:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
				<template #selection="{ item }">
					<span>{{ formatKhoiHienThi(item) }}</span>
				</template>
				<template #item="{ props, item }">
					<v-list-item v-bind="props" :title="formatKhoiHienThi(item)"></v-list-item>
				</template>
			</v-select>
		</v-col>
		<v-col cols="6" sm="6" md="4" lg="2">
			<v-select :key="'lop_' + isEn" :label="isEn ? 'Select class' : 'Chọn lớp'" v-model="form.LopItem" :items="DSLop"
				item-title="TenLop" item-value="LopID" return-object :disabled="!form.KhoiItem"
				:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'" />
		</v-col>
		<v-col cols="6" sm="6" md="4" lg="2">
			<v-select :key="'mon_' + isEn" :label="isEn ? 'Select subject' : 'Chọn môn học'" v-model="form.MonHocItem" :items="DSMonHoc"
				item-title="TenMonHoc_HienThi" item-value="MonHocID" return-object :disabled="!form.LopItem"
				:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'" />
		</v-col>
		<v-col cols="6" sm="6" md="4" lg="2">
			<v-select :key="'nhom_' + isEn" :label="isEn ? 'Select column group' : 'Chọn mã nhóm'" v-model="form.MaNhomCotDiemItem"
				:items="DSMaNhom" :item-title="formatNhomHienThi" item-value="MaNhomCotDiem" return-object
				:disabled="!form.MonHocItem" :no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
				<template #selection="{ item }">
					<span>{{ formatNhomHienThi(item) }}</span>
				</template>
				<template #item="{ props, item }">
					<v-list-item v-bind="props" :title="formatNhomHienThi(item)"></v-list-item>
				</template>
			</v-select>
		</v-col>
		<v-col cols="6" sm="6" md="4" lg="2">
			<v-btn @click="onRefreshFilter" variant="outlined" color="primary">
				<v-icon start>mdi-reload</v-icon>{{ isEn ? 'Refresh' : 'Làm mới' }}
			</v-btn>
		</v-col>
	</v-row>
</template>

<script>
	export default {
		props: {
			modelValue: Object,
			onRefresh: Function,
			isEn: {
				type: Boolean,
				default: () => JSON.parse(localStorage.getItem('IsLanguage')) ?? false
			}
		},
		data() {
			return {
				vueData,
				form: {
					KhoiItem: null,
					LopItem: null,
					MonHocItem: null,
					MaNhomCotDiemItem: null
				},
				DSKhoi: [],
				DSLop: [],
				DSMonHoc: [],
				DSMaNhom: []
			}
		},
		mounted() {
			this.getKhoi()
		},
		computed: {},
		watch: {
			modelValue: function (v) {
				this.form = v
			},
			'vueData.NienKhoa': function () {
				// Khi niên khoá thay đổi, reset toàn bộ filter và load lại khối
				this.form.KhoiItem = null
				this.form.LopItem = null
				this.form.MonHocItem = null
				this.form.MaNhomCotDiemItem = null
				this.DSKhoi = []
				this.DSLop = []
				this.DSMonHoc = []
				this.DSMaNhom = []
				this.$emit("update:modelValue", this.form)
				this.getKhoi()
			},
			'form.KhoiItem': function (newVal, oldVal) {
				// Khi chọn lại Khối, clear tất cả các cấp dưới
				if (newVal?.KhoiID !== oldVal?.KhoiID) {
					this.form.LopItem = null
					this.form.MonHocItem = null
					this.form.MaNhomCotDiemItem = null
					this.DSLop = []
					this.DSMonHoc = []
					this.DSMaNhom = []
	
					if (newVal?.KhoiID) {
						this.getLop()
						this.$emit("update:modelValue", this.form)
					}
				}
			},
			'form.LopItem': function (newVal, oldVal) {
				// Khi chọn lại Lớp, clear Môn học và Mã nhóm
				if (newVal?.LopID !== oldVal?.LopID) {
					this.form.MonHocItem = null
					this.form.MaNhomCotDiemItem = null
					this.DSMonHoc = []
					this.DSMaNhom = []
	
					if (newVal?.LopID) {
						this.getMonHoc()
						this.$emit("update:modelValue", this.form)
					}
				}
			},
			'form.MonHocItem': function (newVal, oldVal) {
				// Khi chọn lại Môn học, clear Mã nhóm
				if (newVal?.MonHocID !== oldVal?.MonHocID) {
					this.form.MaNhomCotDiemItem = null
					this.DSMaNhom = []
	
					if (newVal?.MonHocID) {
						this.getMaNhom()
						this.$emit("update:modelValue", this.form)
					}
				}
			},
			'form.MaNhomCotDiemItem': function (newVal) {
				if (newVal?.MaNhomCotDiem) {
					this.$emit("update:modelValue", this.form)
					this.$emit("onRefresh")
				}
			}
		},
		methods: {
			formatKhoiHienThi(item) {
				if (!item) return '';
				const raw = (item && item.raw) ? item.raw : item;
				const name = typeof raw === 'object' ? (raw.TenKhoiHoc || raw.title) : raw;
				if (!name) return '';
				if (!this.isEn) return name;
				return String(name).replace(/Khối/gi, 'Grade');
			},
			formatNhomHienThi(item) {
				if (!item) return '';
				const raw = (item && item.raw) ? item.raw : item;
				if (typeof raw === 'string') return raw;
				if (this.isEn && raw.TenNhomCotDiem_EN) return raw.TenNhomCotDiem_EN;
				return raw.TenNhomCotDiem_VI || raw.TenNhomCotDiem || raw.title || '';
			},
			onRefreshFilter() {
				// Reset toàn bộ form
				this.$emit("update:modelValue", this.form)
				this.$emit("onRefresh")
			},
			async getKhoi() {
				this.DSKhoi = await ajaxCALLPromise("lms/KhoiHocByCapHoc_Get", {
					CapID: vueData.CapID,
					HocKi: vueData.NienKhoaItem.HocKi,
					NienKhoa: vueData.NienKhoa
				})
			},
			async getLop() {
				this.DSLop = await ajaxCALLPromise("lms/Lop_Get_ByKhoiID", {
					KhoiID: this.form.KhoiItem.KhoiID,
					NienKhoa: vueData.NienKhoa,
					HocKi: vueData.NienKhoaItem.HocKi,
				})
			},
			async getMonHoc() {
				this.DSMonHoc = await ajaxCALLPromise("lms/MonHoc_Get_ByLopID", {
					NienKhoa: vueData.NienKhoa,
					HocKi: vueData.NienKhoaItem.HocKi,
					LopID: this.form.LopItem.LopID
				})
			},
			async getMaNhom() {
				this.DSMaNhom = await ajaxCALLPromise("lms/NhomCauTrucDiem_Get_ByTemplateBangDiemID", {
					TemplateBangDiemID: this.form.MonHocItem.TemplateBangDiemID
				})
			}
		},
	}
</script>