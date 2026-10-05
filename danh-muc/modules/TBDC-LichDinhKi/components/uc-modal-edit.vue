<template>
	<v-dialog v-model="isShow" width="1200">
		<v-card>
			<v-toolbar density="compact" elevation="0">
				<v-toolbar-title>
					Cập nhật
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
									<v-text-field :rules="[rules.required]" v-model="selectedItem.TenLichDinhKi"
										label="Tên phiếu định kì" hide-details density="compact"></v-text-field>
								</v-col>
								<v-col cols="12" class="mt-1">
									<v-select v-model="selectedItem.LoaiDinhKi" :items="DSLoaiDinhKi" label="Lặp lại"
										:rules="[rules.required]" hide-details density="compact" item-title="title"
										item-value="value">
									</v-select>
								</v-col>
								<v-col cols="12" class="mt-1">
									<v-select v-model="selectedItem.LoaiHangHoa" label="Loại tài sản"
										:rules="[rules.required]" hide-details density="compact" :items="DSLoaiHangHoa"
										item-title="title" item-value="value">
									</v-select>
								</v-col>
								<v-col cols="12" class="mt-1">
									<v-select v-model="selectedItem.selectedDiaDiem" :items="DSDiaDiem"
										label="Địa điểm áp dụng" :rules="[rules.requiredSelectMulti]" hide-details
										density="compact" item-value='DiaDiem_Id' item-title="TenDiaDiem" multiple>
										<template v-slot:selection="{ item, index }">
											<v-chip v-if="index < 2" :text="item.title"></v-chip>

											<span v-if="index === 2" class="text-grey text-caption align-self-center">
												(+{{ selectedItem.selectedDiaDiem.length - 2 }} địa điểm)
											</span>
										</template>
									</v-select>
								</v-col>
								<template v-if="selectedItem.LoaiDinhKi === 'TUAN'">
									<v-col cols='12' class="mt-1">
										<v-select v-model="selectedItem.NgayTrongTuan" label="Ngày trong tuần" chips
											multiple :rules="[rules.required]" hide-details density="compact"
											:items="DSNgayTrongTuan" item-title="title" item-value="value"></v-select>
									</v-col>
								</template>
								<template v-if="selectedItem.LoaiDinhKi === 'THANG'">
									<v-col cols='12' class="mt-1">
										<v-radio-group v-model="selectedItem.optionLoaiDinhKiThang" inline
											hide-details='auto' :rules="[rules.required]">
											<v-radio v-for="Option in DSOptionsLoaiDinhKiThang" :label="Option.title"
												:value="Option.value" :key="Option.value"></v-radio>
										</v-radio-group>
									</v-col>
									<v-col cols='12' class="mt-1">
										<v-text-field v-if="selectedItem.optionLoaiDinhKiThang === 'NGAY_TRONG_THANG'"
											:rules="[rules.required]" v-model="selectedItem.NgayTrongThang"
											@blur="normalizeDays" label="Ngày trong tháng" placeholder="1,15,20"
											hide-details density="compact"></v-text-field>
										<template
											v-if="selectedItem.optionLoaiDinhKiThang === 'NGAY_TRONG_TUAN_TRONG_THANG'">
											<v-row dense>
												<v-col cols='6'>
													<v-select v-model="selectedItem.NgayTrongTuan"
														label="Ngày trong tuần" :rules="[rules.required]" hide-details
														density="compact" :items="DSNgayTrongTuan" item-title="title"
														item-value="value"></v-select>
												</v-col>
												<v-col cols='6'>
													<v-select v-model="selectedItem.TuanThuTrongThang"
														label="Tuần trong tháng" :rules="[rules.required]" hide-details
														density="compact" :items="DSTuanTrongThang" item-title="title"
														item-value="value"></v-select>
												</v-col>
											</v-row>
										</template>
										<v-select v-if="selectedItem.optionLoaiDinhKiThang === 'DAU_CUOI_THANG'"
											v-model="selectedItem.ViTriTrongKy" label="Đầu / Cuối tháng"
											:rules="[rules.required]" hide-details density="compact"
											:items="DSDauCuoiThang" item-title="title" item-value="value"></v-select>
									</v-col>
								</template>
								<template v-if="selectedItem.LoaiDinhKi === 'NAM'">
									<v-col cols='12' class="mt-1">
										<v-radio-group v-model="selectedItem.optionLoaiDinhKiNam" inline
											hide-details='auto' :rules="[rules.required]">
											<v-radio v-for="Option in DSOptionsLoaiDinhKiNam" :label="Option.title"
												:value="Option.value" :key="Option.value">
											</v-radio>
										</v-radio-group>
									</v-col>
									<v-col cols='12' class="mt-1">
										<template v-if="selectedItem.optionLoaiDinhKiNam === 'THANG_TRONG_NAM'">
											<v-row dense>
												<v-col cols="6">
													<v-text-field :rules="[rules.required]"
														v-model="selectedItem.ThangTrongNam" @blur="normalizeMonths"
														label="Tháng trong năm" placeholder="1,3,5" hide-details
														density="compact"></v-text-field>
												</v-col>
												<v-col cols="6">
													<v-select label="Đầu / Cuối tháng" :rules="[rules.required]"
														v-model="selectedItem.ViTriTrongKy" hide-details
														density="compact" :items="DSDauCuoiThang" item-title="title"
														item-value="value"></v-select>
												</v-col>
											</v-row>
										</template>
										<template v-if="selectedItem.optionLoaiDinhKiNam === 'NGAY_TRONG_NAM'">
											<v-text-field :rules="[rules.required]" v-model="selectedItem.NgayTrongNam"
												@blur="normalizeDayMonths" label="Ngày trong năm"
												placeholder="1/1,15/6,20/11" hide-details
												density="compact"></v-text-field>
										</template>

									</v-col>
								</template>
								<v-col cols='12' class="mt-1">
									<v-text-field v-model="selectedItem.ChuKiLap"
										:rules="[rules.required, rules.greaterThanZero, rules.smallerThan12]"
										label="Lặp lại sau" type="number" hide-details density="compact">
										<template v-slot:append-inner>
											{{ mapLoaiDinhKi[selectedItem.LoaiDinhKi] }}
										</template>
									</v-text-field>
								</v-col>
								<v-col cols='12' class="mt-1">
									<uc-date-picker v-model="selectedItem.NgayBatDau" label="Ngày bắt đầu"
										:rules="[rules.required]"></uc-date-picker>
								</v-col>
								<v-col cols='12'>
									<v-checkbox v-model="selectedItem.Is_TamKhoa" label="Tạm khoá" density="compact"
										color="primary" />
								</v-col>
								<!-- <v-col cols='6'>
									<v-checkbox v-model="selectedItem.Is_TuDong" label="Tự động" density="compact"
										color="primary" />
								</v-col> -->
								<v-col cols="12" class="mt-1">
									<v-card variant="outlined" class="bg-grey-lighten-5"
										style="max-height:200px; overflow-y:auto;">
										<div class="d-flex justify-space-between align-center px-3 pt-3 pb-2">
											<span class="text-subtitle-2 font-weight-medium">
												Danh sách công việc
											</span>

											<v-btn prepend-icon="mdi-plus" size="small" variant="text" color="secondary"
												@click="addTask(selectedItem)">
												Thêm
											</v-btn>
										</div>

										<v-divider />

										<div v-if="selectedItem.taskList.length === 0"
											class="text-caption text-center text-grey py-4">
											Chưa có công việc nào
										</div>

										<div class="px-3 py-2">
											<div v-for="(task, index) in selectedItem.taskList" :key="index"
												class="d-flex align-center mb-2" style="gap:8px;">
												<span class="text-caption text-grey font-weight-bold"
													style="min-width:16px;">
													{{ index + 1 }}.
												</span>

												<v-text-field v-model="task.taskName" placeholder="Tên công việc..."
													density="compact" variant="outlined" bg-color="white"
													hide-details />

												<v-btn icon="mdi-delete" size="small" color="error" variant="text"
													@click="removeTask(index)" />
											</div>
										</div>
									</v-card>
								</v-col>
								<v-col cols=" 12" class="mt-1">
									<v-textarea v-model="selectedItem.GhiChu" label="Ghi chú" density="compact" />
								</v-col>
							</v-row>
						</v-col>
						<v-col cols="8">
							<v-data-table :headers="headers" v-model:expanded="selectedItem.expanded"
								:items="filterDSHangHoa" :search="search" class="border custom-lich-dinh-ki-table"
								:class="{ 'table-disabled': selectedItem.LoaiHangHoa !== 'TUY_CHINH' }"
								:height="getHeightTable || 463" density="compact" show-expand show-select fixed-header
								items-per-page="20" :items-per-page-options="[20, 50, 100]"
								items-per-page-text="Bản ghi">
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
				<v-btn color="primary" variant="flat" @click="onSubmit">Cập nhật</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
export default {
	props: {
		isShow: Boolean,
		selectedItem: Object,
		loadDSLichDinhKi: Function,
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
			DSLoaiHangHoa: [
				{
					title: 'Tất cả', value: 'TAT_CA'
				},
				{
					title: 'Tuỳ chỉnh', value: 'TUY_CHINH'
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
			search: null,
			filterMode: 'DA_CHON',
		}
	},
	mounted() {
	},
	computed: {
		getHeightTable() {
			switch (this.selectedItem.LoaiDinhKi) {
				case "NGAY":
					return 631
				case "TUAN":
					return 679
				case "THANG":
					return 735
				case "NAM":
					return 695
				default:
					return 631
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
		'selectedItem.LoaiDinhKi': function (newVal, oldVal) {
			if (newVal !== oldVal && oldVal !== undefined && oldVal !== null && newVal !== undefined && newVal !== null)
				this.resetValue()
		},
		'selectedItem.optionLoaiDinhKiThang': function (newVal, oldVal) {
			if (newVal !== oldVal && oldVal !== undefined && oldVal !== null && newVal !== undefined && newVal !== null)
				this.resetValue()
		},
		'selectedItem.optionLoaiDinhKiNam': function (newVal, oldVal) {
			if (newVal !== oldVal && oldVal !== undefined && oldVal !== null && newVal !== undefined && newVal !== null)
				this.resetValue()
		},
		'selectedItem.LoaiHangHoa': function (newVal, oldVal) {
			if (oldVal === 'TUY_CHINH') {
				this.selectedItem.DSDaChon.forEach((HangHoa) => HangHoa.Is_Selected = false)
				this.DSHangHoaTree.forEach((HangHoa) => {
					HangHoa.Is_Selected = false
					const children = HangHoa.children
					if (children.length > 0) children.forEach((child) => child.Is_Selected = false)
				})
			}
		}
	},
	methods: {
		closeDialog() {
			this.$refs.form?.reset()
			this.$refs.form?.resetValidation()
			this.$emit('update:isShow', false)
			this.filterMode = 'DA_CHON'
		},

		resetValue() {
			this.selectedItem.NgayTrongNam = null
			this.selectedItem.NgayTrongThang = null
			this.selectedItem.NgayTrongTuan = null
			this.selectedItem.ThangTrongNam = null
			this.selectedItem.TuanThuTrongThang = null
			this.selectedItem.ViTriTrongKy = null
			this.selectedItem.taskList = [{ taskName: 'Kiểm tra hoạt động' }]

		},

		addTask() {
			this.selectedItem.taskList.push({ taskName: '' });
		},
		removeTask(index) {
			this.selectedItem.taskList.splice(index, 1);
		},

		normalizeWeekDays() {
			this.item.NgayTrongTuan = [... new Set(this.item.NgayTrongTuan
				.split(',')
				.map(s => s.trim())
				.filter(s => /^\d+$/.test(s))
				.map(Number)
				.filter(n => n >= 1 && n <= 7))]
				.sort((a, b) => a - b)

		},

		normalizeDays() {
			this.selectedItem.NgayTrongThang = [... new Set(this.selectedItem.NgayTrongThang
				.split(',')
				.map(s => s.trim())
				.filter(s => /^\d+$/.test(s))
				.map(Number)
				.filter(n => n >= 1 && n <= 31))]
				.sort((a, b) => a - b)
				.join(',')
		},
		normalizeMonths() {
			this.selectedItem.ThangTrongNam = [... new Set(this.selectedItem.ThangTrongNam
				.split(',')
				.map(s => s.trim())
				.filter(s => /^\d+$/.test(s))
				.map(Number)
				.filter(n => n >= 1 && n <= 12))].sort((a, b) => a - b)
				.join(',')
		},

		normalizeDayMonths() {
			const daysInMonth = (m) => new Date(new Date().getFullYear(), m, 0).getDate()
			this.selectedItem.NgayTrongNam = [...new Set(this.selectedItem.NgayTrongNam
				.split(',')
				.map(s => s.trim())
				.filter(s => /^\d{1,2}\/\d{1,2}$/.test(s))
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
			const parent = this.DSHangHoaTree.find(p => p.id === item.value)
			parent.Is_Selected = value
			if (value === true) {
				if (item.raw.children?.length === 0) await this.loadChildren(item.raw)
				const children = item.raw.children
				children.forEach((child) => {
					if (child.Is_Selected === false) {
						child.Is_Selected = true
						this.selectedItem.DSDaChon.push(child)
					}
				})
			} else {
				const temp = this.selectedItem.DSDaChon.filter(child => {
					if (child.parent_Id === item.value) {
						child.Is_Selected = false
						return false
					}
					return true
				})
				this.selectedItem.DSDaChon = temp
				item.raw.children.forEach((child) => child.Is_Selected = false)
			}
		},

		handleSelected(HangHoa, val, item) {
			HangHoa.Is_Selected = val
			if (HangHoa.Is_Selected) {
				this.selectedItem.DSDaChon.push(HangHoa)
			} else {
				this.selectedItem.DSDaChon = this.selectedItem.DSDaChon.filter(
					item => item.id !== HangHoa.id
				)
			}
			const parent = this.DSHangHoaTree.find(p => p.id === item.id)
			const totalSelectedChild = parent.children.filter(c => c.Is_Selected).length
			parent.Is_Selected = totalSelectedChild === parent.children.length && parent.children.length > 0
		},

		async loadChildren(item) {
			let data = await apiCallPromise('work/TS_HangHoa_Select_Tree_Children', {
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
			if (this.selectedItem.DSDaChon.length === 0 && this.selectedItem.LoaiHangHoa === 'TUY_CHINH') {
				showToast.info('Vui lòng chọn ít nhất 1 hàng hoá')
				return
			}
			const DATA_JSON = {
				DSDiaDiem: this.selectedItem.selectedDiaDiem.join(','),
				DSHangHoa: this.selectedItem.LoaiHangHoa === 'TUY_CHINH' ? this.selectedItem.DSDaChon.map(HangHoa => HangHoa.id).join(',') : ''
			}
			const cleanTaskList = this.selectedItem.taskList.filter(t => t.taskName && t.taskName.trim() !== '').map(t => t.taskName);
			const jsonTaskList = cleanTaskList.join(',');
			const params = {
				LichDinhKi_Id: this.selectedItem.LichDinhKi_Id,
				TenLichDinhKi: this.selectedItem.TenLichDinhKi,
				LoaiDinhKi: this.selectedItem.LoaiDinhKi,
				LoaiHangHoa: this.selectedItem.LoaiHangHoa,
				ChuKiLap: this.selectedItem.ChuKiLap,
				NgayBatDau: dayjs(this.selectedItem.NgayBatDau).format('YYYY-MM-DD'),
				NgayTrongNam: this.selectedItem.NgayTrongNam,
				NgayTrongThang: this.selectedItem.NgayTrongThang,
				NgayTrongTuan: Array.isArray(this.selectedItem.NgayTrongTuan) ? this.selectedItem.NgayTrongTuan.join(',') : this.selectedItem.NgayTrongTuan,
				ThangTrongNam: this.selectedItem.ThangTrongNam,
				TuanThuTrongThang: this.selectedItem.TuanThuTrongThang,
				ViTriTrongKy: this.selectedItem.ViTriTrongKy,
				GhiChu: this.selectedItem.GhiChu,
				Is_TamKhoa: this.selectedItem.Is_TamKhoa ?? false,
				Is_TuDong: this.selectedItem.Is_TuDong ?? false,
				DATA_JSON: JSON.stringify(DATA_JSON),
				ListTask: jsonTaskList,
			}
			apiCall("work/TS_LichDinhKi_Update", params, (res) => {
				if (res) showToast.success("Thành công");
				this.closeDialog()
				this.loadDSLichDinhKi()
			})
		},


	},
}
</script>