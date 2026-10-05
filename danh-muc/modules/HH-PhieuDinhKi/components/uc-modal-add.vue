<template>
	<v-dialog v-model="isShow" width="1200">
		<v-card>
			<v-toolbar density="compact" elevation="0">
				<v-toolbar-title>
					Thêm mới
				</v-toolbar-title>
				<v-spacer />
				<v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
			</v-toolbar>
			<v-card-text class="pt-0">
				<v-form ref="form">
					<v-row dense>
						<v-col cols="4">
							<v-row dense>
								<v-col cols="12">
									<v-text-field :rules="[rules.required]" v-model="item.TenPhieuDinhKi"
										label="Tên phiếu định kì" hide-details density="compact"></v-text-field>
								</v-col>
								<v-col cols="12" class="mt-1">
									<v-select v-model="item.LoaiPhieu" label="Loại phiếu" :rules="[rules.required]"
										hide-details density="compact" :items="DSLoaiPhieu" item-title="title"
										item-value="value">
									</v-select>
								</v-col>
								<v-col cols="12" class="mt-1">
									<v-select v-model="item.LoaiHangHoa" label="Loại hàng hoá" :rules="[rules.required]"
										hide-details density="compact" :items="DSLoaiHangHoa" item-title="title"
										item-value="value">
									</v-select>
								</v-col>
								<v-col cols="12" class="mt-1">
									<v-select v-model="item.LoaiDinhKi" :items="DSLoaiDinhKi" label="Lặp lại"
										:rules="[rules.required]" hide-details density="compact" item-title="title"
										item-value="value">
									</v-select>
								</v-col>
								<v-col cols="12" class="mt-1">
									<v-select v-model="selectedDiaDiem" :items="DSDiaDiem" label="Địa điểm áp dụng"
										:rules="[rules.requiredSelectMulti]" hide-details density="compact"
										item-value='DiaDiem_Id' item-title="TenDiaDiem" multiple>
										<template v-slot:selection="{ item, index }">
											<v-chip v-if="index < 2" :text="item.title"></v-chip>

											<span v-if="index === 2" class="text-grey text-caption align-self-center">
												(+{{ selectedDiaDiem.length - 2 }} địa điểm)
											</span>
										</template>
									</v-select>
								</v-col>
								<template v-if="item.LoaiDinhKi === 'TUAN'">
									<v-col cols='12' class="mt-1">
										<v-select v-model="item.NgayTrongTuan" label="Ngày trong tuần" chips multiple
											:rules="[rules.required]" hide-details density="compact"
											:items="DSNgayTrongTuan" item-title="title" item-value="value"></v-select>
									</v-col>
								</template>
								<template v-if="item.LoaiDinhKi === 'THANG'">
									<v-col cols='12' class="mt-1">
										<v-radio-group v-model="item.optionLoaiDinhKiThang" inline hide-details='auto'
											:rules="[rules.required]">
											<v-radio v-for="Option in DSOptionsLoaiDinhKiThang" :label="Option.title"
												:value="Option.value" :key="Option.value"></v-radio>
										</v-radio-group>
									</v-col>
									<v-col cols='12' class="mt-1">
										<v-text-field v-if="item.optionLoaiDinhKiThang === 'NGAY_TRONG_THANG'"
											:rules="[rules.required]" v-model="item.NgayTrongThang"
											@blur="normalizeDays" label="Ngày trong tháng" placeholder="1,15,20"
											hide-details density="compact"></v-text-field>
										<template v-if="item.optionLoaiDinhKiThang === 'NGAY_TRONG_TUAN_TRONG_THANG'">
											<v-row dense>
												<v-col cols='6'>
													<v-select v-model="item.NgayTrongTuan" label="Ngày trong tuần"
														:rules="[rules.required]" hide-details density="compact"
														:items="DSNgayTrongTuan" item-title="title"
														item-value="value"></v-select>
												</v-col>
												<v-col cols='6'>
													<v-select v-model="item.TuanThuTrongThang" label="Tuần trong tháng"
														:rules="[rules.required]" hide-details density="compact"
														:items="DSTuanTrongThang" item-title="title"
														item-value="value"></v-select>
												</v-col>
											</v-row>
										</template>
										<v-select v-if="item.optionLoaiDinhKiThang === 'DAU_CUOI_THANG'"
											v-model="item.ViTriTrongKy" label="Đầu / Cuối tháng"
											:rules="[rules.required]" hide-details density="compact"
											:items="DSDauCuoiThang" item-title="title" item-value="value"></v-select>
									</v-col>
								</template>
								<template v-if="item.LoaiDinhKi === 'NAM'">
									<v-col cols='12' class="mt-1">
										<v-radio-group v-model="item.optionLoaiDinhKiNam" inline hide-details='auto'
											:rules="[rules.required]">
											<v-radio v-for="Option in DSOptionsLoaiDinhKiNam" :label="Option.title"
												:value="Option.value" :key="Option.value">
											</v-radio>
										</v-radio-group>
									</v-col>
									<v-col cols='12' class="mt-1">
										<template v-if="item.optionLoaiDinhKiNam === 'THANG_TRONG_NAM'">
											<v-row dense>
												<v-col cols="6">
													<v-text-field :rules="[rules.required]" v-model="item.ThangTrongNam"
														@blur="normalizeMonths" label="Tháng trong năm"
														placeholder="1,3,5" hide-details
														density="compact"></v-text-field>
												</v-col>
												<v-col cols="6">
													<v-select label="Đầu / Cuối tháng" :rules="[rules.required]"
														v-model="item.ViTriTrongKy" hide-details density="compact"
														:items="DSDauCuoiThang" item-title="title"
														item-value="value"></v-select>
												</v-col>
											</v-row>
										</template>
										<template v-if="item.optionLoaiDinhKiNam === 'NGAY_TRONG_NAM'">
											<v-text-field :rules="[rules.required]" v-model="item.NgayTrongNam"
												@blur="normalizeDayMonths" label="Ngày trong năm"
												placeholder="1/1,15/6,20/11" hide-details
												density="compact"></v-text-field>
										</template>

									</v-col>
								</template>
								<v-col cols='12' class="mt-1">
									<v-text-field v-model="item.ChuKiLap"
										:rules="[rules.required, rules.greaterThanZero, rules.smallerThan12]"
										label="Lặp lại sau" type="number" hide-details density="compact">
										<template v-slot:append-inner>
											{{ mapLoaiDinhKi[item.LoaiDinhKi] }}
										</template>
									</v-text-field>
								</v-col>
								<v-col cols='12' class="mt-1">
									<uc-date-picker v-model="item.NgayBatDau" label="Ngày bắt đầu"
										:rules="[rules.required]"></uc-date-picker>
								</v-col>
								<v-col cols='12'>
									<v-checkbox v-model="item.Is_TamKhoa" label="Tạm khoá" dense color="primary" />
								</v-col>
								<!-- <v-col cols='6'>
									<v-checkbox v-model="item.Is_TuDong" label="Tự động" dense color="primary" />
								</v-col> -->
								<v-col cols=" 12" class="mt-1">
									<v-textarea v-model="item.GhiChu" label="Ghi chú" dense />
								</v-col>
							</v-row>
						</v-col>
						<v-col cols="8">
							<v-data-table :headers="headers" :items="filterDSHangHoa" :search="search"
								class="border custom-phieu-dinh-ki-table"
								:class="{ 'table-disabled': item.LoaiHangHoa !== 'TUY_CHINH' }"
								:height="getHeightTable || 463" density="compact" show-expand show-select fixed-header
								items-per-page="20" :disabled="item.LoaiHangHoa !== 'TUY_CHINH'"
								:items-per-page-options="[20, 50, 100]" items-per-page-text="Bản ghi">

								<template v-slot:header.data-table-select>
								</template>

								<template v-slot:header.name="{ column }">
									<div class="d-flex align-center justify-center">
										<span>
											{{ column.title }}
										</span>
										<v-spacer></v-spacer>
										<v-chip-group v-model="filterMode" mandatory selected-class="text-primary">
											<v-chip value="TAT_CA" filter variant="outlined" color="primary">
												Tất cả
											</v-chip>

											<v-chip value="DA_CHON" filter variant="outlined" color="success">
												Đã chọn
											</v-chip>
										</v-chip-group>
										<v-text-field v-model="search" density="compact" variant="underlined"
											label="Tìm kiếm" prepend-inner-icon="mdi-magnify" single-line
											style="max-width:400px" clearable></v-text-field>
									</div>
								</template>

								<template v-slot:item.data-table-select="{ internalItem }">
									<v-checkbox :model-value="internalItem.raw.Is_Selected"
										@update:model-value="val => handleParentSelected(internalItem, val)" />
								</template>

								<template v-slot:item.data-table-expand="{ internalItem, isExpanded, toggleExpand }">
									<v-btn :icon="isExpanded(internalItem) ? 'mdi-chevron-up' : 'mdi-chevron-down'"
										size="small" @click="() => handledExpanded(toggleExpand, internalItem)"
										variant="text"></v-btn>
								</template>

								<template v-slot:item.name="{ item }">
									<span class="ms-4 font-weight-medium">
										{{ item.name }}
									</span>
									<v-chip size="x-small">
										{{ item.totalChildren }}
									</v-chip>
								</template>

								<template v-slot:expanded-row="{ columns, item }">
									<tr v-if="item.children?.length">
										<td :colspan="columns.length" class="pa-0">
											<v-sheet class="overflow-hidden pl-12">
												<v-virtual-scroll :items="item.children" density="compact"
													:item-height="40">
													<template #default="{ item: HangHoa }">
														<div class="d-flex align-center px-3" style="height: 40px">
															<v-checkbox density="compact" hide-details
																:model-value="HangHoa.Is_Selected"
																@update:model-value="val => handleSelected(HangHoa, val, item)" />
															<span>{{ HangHoa.name }}</span>
														</div>
													</template>
												</v-virtual-scroll>
											</v-sheet>
										</td>
									</tr>
								</template>
							</v-data-table>
						</v-col>
					</v-row>
				</v-form>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn color="primary" variant="flat" @click="onSubmit">Thêm mới</v-btn>
			</v-card-actions>

		</v-card>
	</v-dialog>
</template>

<script>
export default {
	props: {
		isShow: Boolean,
		loadDSPhieuDinhKi: Function,
		DSHangHoaTree: Array,
		DSDiaDiem: Array,
	},
	data() {
		return {
			rules: {
				required: v =>
					(v !== null && v !== undefined && v !== '') ||
					'Trường này không được để trống',
				requiredSelectMulti: v => (Array.isArray(v) && v.length > 0) || 'Trường này không được để trống',
				greaterThanZero: v => v > 0 || 'Giá trị phải lớn hơn 0',
				noSpecialChar: v =>
					/^[a-zA-Z0-9\s]+$/.test(v) || 'Không được chứa ký tự đặc biệt',
				smallerThan12: v => (v > 0 && v < 12) || 'Giá trị phải lớn hơn 0',
			},

			headers: [
				{ width: 1, key: 'data-table-expand', align: 'start' },
				{ title: 'Tên nhóm hàng hoá', align: 'start', key: 'name', sortable: false },
			],
			DSLoaiPhieu: [
				{
					title: 'Phiếu kiểm kê định kì (Chốt sổ)', value: 'KIEM_KE_DINH_KI'
				},
				{
					title: 'Phiếu kiểm kê hằng ngày', value: 'KIEM_KE_HANG_NGAY'
				}
			],
			DSLoaiHangHoa: [
				// {
				// 	title: 'Tất cả', value: 'TAT_CA'
				// },
				{
					title: 'Nguyên vật liệu', value: 'NVL'
				},
				{
					title: 'Công cụ dụng cụ', value: 'CCDC'
				},
				{
					title: 'Tuỳ chỉnh', value: 'TUY_CHINH'
				},
			],

			DSLoaiDinhKi: [
				{
					title: 'Theo ngày', value: 'NGAY'
				},
				{
					title: 'Theo tuần', value: 'TUAN'
				},
				{
					title: 'Theo tháng', value: 'THANG'
				},
				{
					title: 'Theo năm', value: 'NAM'
				},
			],
			DSNgayTrongTuan: [
				{
					title: 'Chủ nhật', value: '1'
				},
				{
					title: 'Thứ 2', value: '2'
				},
				{
					title: 'Thứ 3', value: '3'
				},
				{
					title: 'Thứ 4', value: '4'
				},
				{
					title: 'Thứ 5', value: '5'
				},
				{
					title: 'Thứ 6', value: '6'
				},
				{
					title: 'Thứ 7', value: '7'
				},
			],
			DSTuanTrongThang: [
				{
					title: 'Tuần 1', value: '1'
				},
				{
					title: 'Tuần 2', value: '2'
				},
				{
					title: 'Tuần 3', value: '3'
				},
				{
					title: 'Tuần 4', value: '4'
				},
			],
			DSThangTrongNam: [
				{
					title: 'Tháng 1', value: '1'
				},
				{
					title: 'Tháng 2', value: '2'
				},
				{
					title: 'Tháng 3', value: '3'
				},
				{
					title: 'Tháng 4', value: '4'
				},
				{
					title: 'Tháng 5', value: '5'
				},
				{
					title: 'Tháng 6', value: '6'
				},
				{
					title: 'Tháng 7', value: '7'
				},
				{
					title: 'Tháng 8', value: '8'
				},
				{
					title: 'Tháng 9', value: '9'
				},
				{
					title: 'Tháng 10', value: '10'
				},
				{
					title: 'Tháng 11', value: '11'
				},
				{
					title: 'Tháng 12', value: '12'
				},
			],
			DSOptionsLoaiDinhKiThang: [
				{
					title: 'Ngày tháng',
					value: 'NGAY_TRONG_THANG'
				},
				{
					title: 'Thứ trong tháng',
					value: 'NGAY_TRONG_TUAN_TRONG_THANG'
				},
				{
					title: 'Đầu/Cuối',
					value: 'DAU_CUOI_THANG'
				},
			],
			DSOptionsLoaiDinhKiNam: [
				{
					title: 'Ngày trong năm',
					value: 'NGAY_TRONG_NAM'
				},
				{
					title: 'Tháng trong năm',
					value: 'THANG_TRONG_NAM'
				},
			],
			DSDauCuoiThang: [
				{
					title: 'Đầu tháng',
					value: 'DAU_KI'
				},
				{
					title: 'Cuối tháng',
					value: 'CUOI_KI'
				},
			],
			mapLoaiDinhKi: {
				'NGAY': 'ngày',
				'TUAN': 'tuần',
				'THANG': 'tháng',
				'NAM': 'năm',
			},
			DSDaChon: [],
			selectedDiaDiem: [],
			search: null,
			filterMode: 'TAT_CA',

			item: {
				TenPhieuDinhKi: null,
				LoaiDinhKi: null,
				LoaiHangHoa: null,
				LoaiPhieu: null,
				ChuKiLap: null,
				NgayBatDau: new Date(),
				NgayTrongNam: null,
				NgayTrongThang: null,
				NgayTrongTuan: null,
				ThangTrongNam: null,
				ViTriTrongKy: null,
				Is_TamKhoa: false,
				Is_TuDong: false,
				GhiChu: null,
				optionLoaiDinhKiThang: null,
				optionLoaiDinhKiNam: null,
			},
		}
	},
	mounted() {
	},
	computed: {
		getHeightTable() {
			switch (this.item.LoaiDinhKi) {
				case "NGAY":
					return 463
					break;
				case "TUAN":
					return 511
					break;
				case "THANG":
					return 567
					break;
				case "NAM":
					return 527
					break
				default:
					return 463
			}
		},
		filterDSHangHoa() {
			if (this.filterMode === 'TAT_CA') return this.DSHangHoaTree

			const res = this.DSHangHoaTree
				.map(item => {
					const children = (item.children ?? [])
					const tempChildren = children.filter(child => child.Is_Selected)
					if (tempChildren.length > 0) {
						const totalSelectedChild = item.children.filter(c => c.Is_Selected).length
						item.Is_Selected = totalSelectedChild === item.children.length && item.children.length > 0
						return {
							...item,
							children
						}
					}

					return null
				})
				.filter(Boolean)

			return res
		}
	},
	watch: {
		'item.LoaiDinhKi': function () {
			this.resetValue()
		},
		'item.optionLoaiDinhKiThang': function () {
			this.resetValue()
		},
		'item.optionLoaiDinhKiNam': function () {
			this.resetValue()
		},
		'item.LoaiHangHoa': function (newVal, oldVal) {
			if (oldVal === 'TUY_CHINH') {
				this.DSDaChon.forEach((HangHoa) => HangHoa.Is_Selected = false)
				this.DSHangHoaTree.forEach((HangHoa) => HangHoa.Is_Selected = false)
			}
		}
	},
	methods: {
		closeDialog() {
			this.$refs.form?.reset()
			this.$refs.form?.resetValidation()
			this.$emit('update:isShow', false)
		},

		resetValue() {
			this.item.NgayTrongNam = null
			this.item.NgayTrongThang = null
			this.item.NgayTrongTuan = null
			this.item.ThangTrongNam = null
			this.item.TuanThuTrongThang = null;
			this.item.ViTriTrongKy = null
		},

		normalizeDays() {
			this.item.NgayTrongThang = [... new Set(this.item.NgayTrongThang
				.split(',')
				.map(s => s.trim())
				.filter(s => /^\d+$/.test(s))
				.map(Number)
				.filter(n => n >= 1 && n <= 31))]
				.sort((a, b) => a - b)
				.join(',')
		},

		normalizeMonths() {
			this.item.ThangTrongNam = [... new Set(this.item.ThangTrongNam
				.split(',')
				.map(s => s.trim())
				.filter(s => /^\d+$/.test(s))
				.map(Number)
				.filter(n => n >= 1 && n <= 12))].sort((a, b) => a - b)
				.join(',')
		},

		normalizeDayMonths() {
			const daysInMonth = (m) => new Date(new Date().getFullYear(), m, 0).getDate()
			this.item.NgayTrongNam = [...new Set(this.item.NgayTrongNam
				.split(',')
				.map(s => s.trim())
				.filter(s => /^\d{1,2}\/\d{1,2}$/.test(s)) // đúng dạng d/m
				.map(s => {
					const [d, m] = s.split('/').map(Number)
					return { d, m }
				})
				.filter(({ d, m }) =>
					m >= 1 && m <= 12 && d >= 1 && d <= daysInMonth(m)).map(({ d, m }) => `${d}/${m}`))]
				.sort((a, b) => {
					const [da, ma] = a.split('/').map(Number)
					const [db, mb] = b.split('/').map(Number)
					return ma - mb || da - db
				})
				.join(',')
		},

		handledExpanded(toggleExpandFn, item) {
			toggleExpandFn(item)
			const childrenLength = item.raw.children.length
			if (childrenLength > 0) return
			else {
				this.loadChildren(item.raw)
			}
		},

		async handleParentSelected(item, value) {
			const parent = this.DSHangHoaTree.find(p => p.id === item.raw.id)
			parent.Is_Selected = value
			if (value === true) {
				if (item.raw.children?.length === 0) await this.loadChildren(item.raw)
				const children = item.raw.children
				children.forEach((child) => {
					if (child.Is_Selected === false) {
						child.Is_Selected = true
						this.DSDaChon.push(child)
					}
				})
			} else {
				const temp = this.DSDaChon.filter(child => {
					if (child.parent_Id === item.value) {
						child.Is_Selected = false
						return false
					}
					return true
				})
				this.DSDaChon = temp
			}
		},

		handleSelected(HangHoa, val, item) {
			HangHoa.Is_Selected = val
			if (HangHoa.Is_Selected) {
				this.DSDaChon.push(HangHoa)
			} else {
				this.DSDaChon = this.DSDaChon.filter(
					item => item.id !== HangHoa.id
				)
			}
			const parent = this.DSHangHoaTree.find(p => p.id === item.id)

			const totalSelectedChild = parent.children.filter(c => c.Is_Selected).length
			parent.Is_Selected = totalSelectedChild === parent.children.length && parent.children.length > 0
		},

		async loadChildren(item) {
			let data = await apiCallPromise('work/HH_HangHoa_Select_Tree_Children', {
				NhomTenSanPham_Id: item.id
			})
			data.forEach((item) => item.Is_Selected = false)
			item.children = data
		},

		async onSubmit() {
			const { valid } = await this.$refs.form.validate();
			if (!valid) {
				showToast.info('Thông tin phiếu định kì chưa đầy đủ')
				return
			}
			if (this.DSDaChon.length === 0 && this.item.LoaiHangHoa === 'TUY_CHINH') {
				showToast.info('Vui lòng chọn ít nhất 1 hàng hoá')
				return
			}
			const DATA_JSON = {
				DSDiaDiem: this.selectedDiaDiem.join(','),
				DSHangHoa: this.item.LoaiHangHoa === 'TUY_CHINH' ? this.DSDaChon.map(HangHoa => HangHoa.id).join(',') : ''
			}
			const params = {
				TenPhieuDinhKi: this.item.TenPhieuDinhKi,
				LoaiDinhKi: this.item.LoaiDinhKi,
				LoaiPhieu: this.item.LoaiPhieu,
				LoaiHangHoa: this.item.LoaiHangHoa,
				ChuKiLap: this.item.ChuKiLap,
				NgayBatDau: dayjs(this.item.NgayBatDau).format('YYYY-MM-DD'),
				NgayTrongNam: this.item.NgayTrongNam,
				NgayTrongThang: this.item.NgayTrongThang,
				NgayTrongTuan: Array.isArray(this.item.NgayTrongTuan) ? this.item.NgayTrongTuan.join(',') : this.item.NgayTrongTuan,
				ThangTrongNam: this.item.ThangTrongNam,
				TuanThuTrongThang: this.item.TuanThuTrongThang,
				ViTriTrongKy: this.item.ViTriTrongKy,
				GhiChu: this.item.GhiChu,
				Is_TamKhoa: this.item.Is_TamKhoa ?? false,
				Is_TuDong: this.item.Is_TuDong ?? false,
				DATA_JSON: JSON.stringify(DATA_JSON)
			}
			apiCall("work/HH_PhieuDinhKi_Insert", params, (res) => {
				if (res) showToast.success("Thành công");
				this.closeDialog()
				this.loadDSPhieuDinhKi()
			})
		},


	},
}
</script>