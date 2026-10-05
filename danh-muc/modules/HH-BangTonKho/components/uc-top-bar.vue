<template>
	<v-app-bar density="compact" :elevation="0" class="border-b">
		<template v-slot:title>
			<span class="text-body-1 font-weight-bold">Bảng tồn kho</span>
			<v-chip v-if="hasData" size="x-small" color="primary" variant="tonal" class="ml-2">
				{{ dataTable.length }} sản phẩm
			</v-chip>
		</template>
		<template v-slot:append>
			<v-btn v-if="hasData" variant="tonal" color="success" size="small" prepend-icon="mdi-file-excel"
				class="mr-1" @click="$emit('on-export')">
				Xuất Excel
			</v-btn>
		</template>
	</v-app-bar>

	<div class="filter-bar pa-2 border-b d-flex align-center ga-2 flex-wrap">
		<v-select v-model="Nam" density="compact" :items="DSNam" item-value="value" item-title="title"
			label="Năm" hide-details style="max-width: 100px; min-width: 80px">
		</v-select>

		<v-select v-model="Thang" density="compact" :items="DSThang" item-value="value" item-title="title"
			label="Tháng" hide-details style="max-width: 180px; min-width: 130px">
		</v-select>

		<v-autocomplete v-model="DiaDiem_Id" density="compact" :items="DSDiaDiem" item-value="DiaDiem_Id"
			item-title="TenDiaDiem" label="Địa điểm" hide-details style="max-width: 400px; min-width: 180px">
		</v-autocomplete>

		<v-select v-model="LoaiHangHoa" density="compact" :items="DSLoaiHangHoa" item-value="value"
			item-title="title" label="Loại hàng hoá" hide-details style="max-width: 200px; min-width: 140px">
		</v-select>

		<v-btn color="primary" variant="flat" prepend-icon="mdi-magnify" size="small"
			:loading="isLoading" @click="onSearch">
			Tìm
		</v-btn>

		<v-divider vertical class="mx-1" />

		<v-btn v-if="isShowQuyDoi && LoaiHangHoa === 'NVL'" variant="tonal" size="small"
			:prepend-icon="isQuyDoi ? 'mdi-view-grid-outline' : 'mdi-filter-variant-remove'"
			@click="toggleQuyDoi">
			{{ isQuyDoi ? 'Hiện NVL, TP, BTP' : 'Chỉ NVL' }}
		</v-btn>

		<v-btn v-if="hasData && canChot" variant="tonal" size="small" color="warning"
			:prepend-icon="isChuaChot ? 'mdi-lock-outline' : 'mdi-lock-open-outline'"
			@click="onChot">
			{{ isChuaChot ? 'Chốt sổ' : 'Mở khoá sổ' }}
		</v-btn>
	</div>

	<div v-if="hasData" class="summary-bar d-flex align-center ga-4 px-4 py-1 border-b bg-grey-lighten-5">
		<span class="text-caption text-grey-darken-1">
			<v-icon size="14">mdi-package-variant</v-icon>
			Tồn: <b class="text-primary">{{ tongTonSoLuong }}</b>
		</span>
		<v-divider vertical />
		<span class="text-caption text-grey-darken-1">
			<v-icon size="14">mdi-currency-usd</v-icon>
			Giá trị tồn: <b class="text-primary">{{ tongTonGiaTri }}</b>
		</span>
		<v-divider vertical />
		<span v-if="soChenhLech > 0" class="text-caption text-orange-darken-2">
			<v-icon size="14" color="orange-darken-2">mdi-alert-outline</v-icon>
			{{ soChenhLech }} chênh lệch
		</span>
		<span v-else class="text-caption text-green-darken-2">
			<v-icon size="14" color="green-darken-2">mdi-check-circle-outline</v-icon>
			Tất cả đều khớp
		</span>
	</div>
</template>

<script>
export default {
	props: {
		DSDiaDiem: Array,
		isLoading: Boolean,
		dataTable: Array,
	},
	emits: ['on-search', 'on-chot', 'on-export', 'on-quy-doi'],
	data() {
		return {
			Nam: null,
			Thang: null,
			DiaDiem_Id: null,
			LoaiHangHoa: 'NVL',
			isQuyDoi: false,

			DSNam: [],
			DSThang: [],
			DSLoaiHangHoa: [
				{ title: 'Nguyên vật liệu', value: 'NVL' },
				{ title: 'Công cụ dụng cụ', value: 'CCDC' },
			],
		}
	},
	mounted() {
		var currentYear = new Date().getFullYear()
		var years = []
		for (var i = 0; i < 10; i++) {
			years.push({ title: currentYear - i, value: currentYear - i })
		}
		this.DSNam = years
		this.Nam = currentYear
		this.DSThang = this.getMonthsByYear(currentYear)
		this.Thang = new Date().getMonth() + 1
		this.$nextTick(this.onSearch)
	},
	computed: {
		hasData() {
			return this.dataTable && this.dataTable.length > 0
		},
		isShowQuyDoi() {
			if (!this.hasData) return false
			return this.dataTable.some(function (x) { return x.LoaiNguyenLieu === 'TP' || x.LoaiNguyenLieu === 'BTP' })
		},
		canChot() {
			if (!this.hasData) return false
			return this.dataTable.some(function (item) { return item.TinhTrang === 'DA_CHOT' || item.TinhTrang === 'CHUA_CHOT' })
		},
		isChuaChot() {
			if (!this.hasData) return false
			return this.dataTable.some(function (item) { return item.TinhTrang === 'CHUA_CHOT' })
		},
		tongTonSoLuong() {
			var total = (this.dataTable || []).reduce(function (sum, item) {
				return sum + (Number(item.Ton_SoLuong) || 0)
			}, 0)
			return total.toLocaleString('vi-VN')
		},
		tongTonGiaTri() {
			var total = (this.dataTable || []).reduce(function (sum, item) {
				return sum + (Number(item.Ton_GiaTri) || 0)
			}, 0)
			return total.toLocaleString('vi-VN') + ' đ'
		},
		soChenhLech() {
			return (this.dataTable || []).filter(function (item) {
				var a = Number(item.Ton_KiemKe)
				var b = Number(item.Ton_SoLuong)
				if (isNaN(a) || isNaN(b)) return false
				return a !== b
			}).length
		},
	},
	watch: {
		Nam(newYear, oldYear) {
			if (newYear === oldYear) return
			this.DSThang = this.getMonthsByYear(newYear)
			if (!this.DSThang.some(function (m) { return m.value === this.Thang }.bind(this))) {
				this.Thang = null
			}
		},
		LoaiHangHoa() {
			if (this.isQuyDoi) {
				this.isQuyDoi = false
				this.$emit('on-quy-doi', false)
			}
		},
	},
	methods: {
		getMonthsByYear(selectedYear) {
			var now = new Date()
			var currentYear = now.getFullYear()
			var currentMonth = now.getMonth() + 1
			var maxMonth = selectedYear === currentYear ? currentMonth : 12
			return Array.from({ length: maxMonth }, function (_, i) {
				return { title: 'Tháng ' + (i + 1), value: i + 1 }
			}).reverse()
		},

		onSearch() {
			if (!this.DiaDiem_Id || !this.Nam || !this.Thang || !this.LoaiHangHoa) return
			this.$emit('on-search', {
				DiaDiem_Id: this.DiaDiem_Id,
				Nam: this.Nam,
				Thang: this.Thang,
				LoaiHangHoa: this.LoaiHangHoa,
			})
		},

		onChot() {
			this.$emit('on-chot', {
				Nam: this.Nam,
				Thang: this.Thang,
				DiaDiem_Id: this.DiaDiem_Id,
				TinhTrang: this.isChuaChot ? 'DA_CHOT' : 'CHUA_CHOT',
				LoaiHangHoa: this.LoaiHangHoa,
			})
		},

		toggleQuyDoi() {
			this.isQuyDoi = !this.isQuyDoi
			this.$emit('on-quy-doi', this.isQuyDoi)
		},
	},
}
</script>
