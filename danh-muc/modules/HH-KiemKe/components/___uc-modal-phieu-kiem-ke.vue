<template>
	<v-dialog v-model="isShow" fullscreen>
		<v-card rounded="lg">
			<v-toolbar>
				<v-toolbar-title class="text-primary">Phiếu kiểm kê
				</v-toolbar-title>
				<v-btn icon="mdi-close" @click="closeDialog"></v-btn>
			</v-toolbar>
			<v-divider></v-divider>
			<v-card-text>
				<v-card>
					<v-card-title>Nhập thông tin phiếu kiểm kê </v-card-title>
					<v-card-text>
						<v-row dense>
							<v-col cols="6" md="2">
								<v-autocomplete color="primary" :model-value="DiaDiem_Id"
									@update:model-value="handleSelectedDiaDiem" density="compact"
									:items="DSDiaDiemTatCa" item-value="DiaDiem_Id" item-title="TenDiaDiem"
									label="Địa điểm kiểm kê">
								</v-autocomplete>
							</v-col>
							<v-col cols="6" md="3">
								<v-text-field :rules="[rules.required]" density="compact" label="Tên phiếu"
									v-model="TenPhieuKiemKe">
								</v-text-field>
							</v-col>
							<v-col cols="auto">
								<v-btn :disabled="DiaDiem_Id === 0" color="primary" variant="tonal"
									@click="loadDSHangHoaByDiaDiem">
									Lấy danh sách hàng hoá hiện tại
								</v-btn>
							</v-col>
							<v-col cols="auto">
								<v-btn :disabled="selectedPhieuKiemKe_Id !== null || DSHangHoa.length === 0 || DiaDiem_Id === null
									|| DSDaChonHangHoa.length === 0" color="primary" variant="tonal" @click="onAddPhieuKiemKe">
									Tạo mới
								</v-btn>
							</v-col>
						</v-row>
					</v-card-text>
				</v-card>

				<v-row dense>
					<v-col cols="12" md="6">
						<v-card class="mt-4">
							<v-card-title>
								Thông tin phiếu kiểm kê đã tạo
							</v-card-title>
							<v-card-text>
								<v-data-table-server v-model:items-per-page="itemsPerPage" v-model:page="page"
									:items-length="tableInfo.TotalRow ?? 0" :headers="headerPhieuKiemKe"
									:items="DSPhieuKiemKe" :height="isMobile ? 300 : 'calc(100vh - 332px)'"
									density="compact" :disable-sort="true" items-per-page-text="Bản ghi" fixed-header
									:items-per-page="50" :items-per-page-options="[15, 20, 50, 100]"
									@update:page="onPageChange" @update:items-per-page="onItemsPerPageChange">

									<template v-slot:item.NgayTao="{ item }">
										{{ formatDate(item.NgayTao) }}
									</template>

									<template v-slot:item.TinhTrang="{ item }">
										<v-chip :color="mapTinhTrangPhieu[item.TinhTrang].color" size="small">
											{{ mapTinhTrangPhieu[item.TinhTrang].text }}
										</v-chip>
									</template>

									<template v-slot:item.actions="{ item }">
										<v-menu>
											<template v-slot:activator="{ props }">
												<v-btn size="small" variant="text" v-bind="props"
													icon="mdi-dots-vertical"></v-btn>
											</template>
											<v-list density="compact">
												<v-list-item @click="onViewDetail(item)" prepend-icon="mdi-eye"
													title="Xem chi tiết"></v-list-item>
												<v-divider />
												<v-list-item
													v-if="item.TinhTrang !== 'HOAN_THANH' && item.NguoiTao === vueData.user.UserID"
													@click="onDelete(item)" prepend-icon="mdi-trash-can"
													title="Xóa"></v-list-item>
											</v-list>
										</v-menu>
									</template>

									<template #no-data>
										<uc-empty text="Chưa có phiếu kiểm kê để hiển thị" />
									</template>
								</v-data-table-server>
							</v-card-text>
						</v-card>
					</v-col>

					<v-col cols="12" md="6">
						<v-card class="mt-4">
							<v-card-title :class="isMobile ? 'd-inline-block text-truncate' : 'd-flex'">
								{{ getTitleTableHangHoa }}
								<v-spacer></v-spacer>
								<v-btn v-if="selectedPhieuKiemKe_Id === null" :disabled="DSHangHoa.length === 0" rounded
									size="small" color="primary" prepend-icon="mdi-checkbox-multiple-marked"
									@click="onSelectedAll" text="Chọn tất cả" variant="tonal"></v-btn>

							</v-card-title>
							<v-card-text>
								<v-data-table v-model="DSDaChonHangHoa" :items="DSHangHoa" :headers="headerHangHoa"
									v-model:expanded="expanded" hide-default-footer show-expand
									:height="isMobile ? 300 : 'calc(100vh - 269px)'" density="compact"
									:disable-sort="true" items-per-page-text="Bản ghi" fixed-header
									item-value="HangHoa_Id" item-key="HangHoa_Id" :items-per-page="-1">

									<template
										v-slot:item.data-table-expand="{ internalItem, isExpanded, toggleExpand }">
										<v-btn :icon="isExpanded(internalItem) ? 'mdi-chevron-up' : 'mdi-chevron-down'"
											size="small" @click="toggleExpand(internalItem)" variant="text"></v-btn>
									</template>

									<template v-slot:expanded-row="{ columns, item }">
										<tr v-if="item.DSCaBiet?.length > 0">
											<td :colspan="columns.length" class="pa-0">
												<v-sheet rounded="lg" border>
													<v-table density="compact">
														<tbody class="bg-surface-light">
															<tr>
																<th class="text-center">
																</th>
																<th class="text-center">Mã vạch</th>
																<th class="text-start" style="width:150px">Số Serial
																</th>
																<th class="text-start">Địa điểm</th>
																<th class="text-start">Khu vực</th>
																<th class="text-center">Tình trạng</th>
																<th class="text-right">Khấu hao (tháng)</th>
																<th class="text-center">Ngày bắt đầu bảo hành</th>
																<th class="text-center">Ngày kết thúc bảo hành</th>
															</tr>
														</tbody>

														<tbody>
															<tr v-for="(CaBiet, index) in item.DSCaBiet" :key="index">
																<td>
																	<v-checkbox v-if="selectedPhieuKiemKe_Id === null"
																		v-model="CaBiet.Is_Selected"
																		@update:model-value="handleSelectedCaBiet(CaBiet)" />
																</td>
																<td class="text-center">
																	{{ CaBiet.MaVach === '' ? 'Chưa có' : CaBiet.MaVach
																	}}
																</td>
																<td class="text-start">
																	{{ CaBiet.SoSeries }}
																</td>
																<td class="text-start">
																	{{ CaBiet.TenDiaDiem }}
																</td>
																<td class="text-start">
																	{{ CaBiet.TenKhuVuc ?? 'Chưa có' }}
																</td>
																<td class="text-center">
																	<v-chip
																		:color="mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrang]?.color"
																		size="small">
																		{{
																			mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrang]?.text
																			?? 'Chưa rõ'
																		}}
																	</v-chip>
																</td>
																<td class="text-right">
																	{{ CaBiet.ThoiGianKhauHao }}
																</td>
																<td class="text-center">
																	{{ formatDate(CaBiet.NgayBatDauBaoHanh) }}
																</td>
																<td class="text-center">
																	{{ formatDate(CaBiet.NgayKetThucBaoHanh) }}
																</td>
															</tr>
														</tbody>
													</v-table>
												</v-sheet>
											</td>
										</tr>
										<tr v-if="item.DSSoLuong?.length > 0">
											<td :colspan="columns.length" class="pa-0">
												<v-sheet rounded="lg" border>
													<v-table density="compact">
														<tbody class="bg-surface-light">
															<tr>
																<th class="text-center">
																</th>
																<th class="text-start">Tên địa điểm</th>
																<th class="text-start">Tên khu vực</th>
																<th class="text-right">Số lượng</th>
															</tr>
														</tbody>

														<tbody>
															<tr v-for="(HangHoa, index) in item.DSSoLuong" :key="index">
																<td>
																	<v-checkbox v-if="selectedPhieuKiemKe_Id === null"
																		v-model="HangHoa.Is_Selected"
																		@update:model-value="handleSelectedSoLuong(HangHoa)" />
																</td>
																<td class="text-start">
																	{{ HangHoa.TenDiaDiem }}
																</td>
																<td class="text-start">
																	{{ HangHoa.TenKhuVuc }}
																</td>
																<td class="text-right">
																	{{ HangHoa.SoLuong }}
																</td>
															</tr>
														</tbody>
													</v-table>
												</v-sheet>
											</td>
										</tr>
									</template>

									<template v-slot:item.Is_CaBiet="{ item }">
										<template v-if="item.Is_CaBiet">
											<v-icon color="primary">mdi-check </v-icon>
										</template>
									</template>

									<template #no-data>
										<uc-empty text="Chưa có hàng hoá để hiển thị" />
									</template>
								</v-data-table>
							</v-card-text>
						</v-card>
					</v-col>
				</v-row>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
export default {
	props: {
		isShow: Boolean,
		DSPhieuKiemKe: Array,
		DSDiaDiem: Array,
		DiaDiem_Id: Number,
		loadDSPhieuKiemKe: Function,
		tableInfo: Object,
	},
	data() {
		return {
			vueData,
			mapTinhTrangHangHoaCaBiet,
			mapTinhTrangPhieu,
			rules: {
				required: v => !!v || 'Trường này không được để trống',
				greaterThanZero: v => v > 0 || 'Giá trị phải lớn hơn 0',
				noSpecialChar: v =>
					/^[a-zA-Z0-9\s]+$/.test(v) || 'Không được chứa ký tự đặc biệt',
			},

			headerPhieuKiemKe: [
				{ title: 'Tên phiếu kiểm kê', key: 'TenPhieuKiemKe' },
				{ title: 'Ngày tạo', key: 'NgayTao' },
				{ title: 'Tình trạng', key: 'TinhTrang' },
				{ title: '', key: 'actions' },
			],

			headerHangHoa: [
				{ width: 1, key: 'data-table-expand', align: 'start' },
				{ title: "Tên hàng hoá", key: "TenHangHoa", align: 'start' },
				{ title: "Đơn vị tính", key: "TenDonVi", align: 'center' },
				{ title: "Số lượng", key: "Tong", align: 'end' },
				{ title: "Trong kho", key: "TrongKho", align: 'end' },
				{ title: "Đang sử dụng", key: "DangSuDung", align: 'end' },
				{ title: "Cá biệt", key: "Is_CaBiet", align: 'center' },
			],

			itemsPerPage: 50,
			page: 1,
			expanded: null,

			selectedPhieuKiemKe_Id: null,
			TenPhieuKiemKe: null,

			DSHangHoa: [],
			DSDaChonHangHoa: [],
		}
	},
	mounted() {
	},
	computed: {
		getTenDiaDiem() {
			if (this.DiaDiem_Id === null) return
			const res = this.DSDiaDiem.find((x) => x.DiaDiem_Id === this.DiaDiem_Id)
			return res?.TenDiaDiem
		},
		DSDiaDiemTatCa() {
			return [
				{ DiaDiem_Id: 0, TenDiaDiem: 'Tất cả' },
				...this.DSDiaDiem
			]
		},
		getTitleTableHangHoa() {
			const res = 'Danh sách hàng hoá'
			if (this.selectedPhieuKiemKe_Id === null && this.DiaDiem_Id === null) return res
			if (this.selectedPhieuKiemKe_Id !== null) {
				const itemKiemKe = this.DSPhieuKiemKe.find((KiemKe) => KiemKe.PhieuKiemKe_Id === this.selectedPhieuKiemKe_Id)
				return `${res} thuộc phiếu kiểm kê: ${itemKiemKe.TenPhieuKiemKe}`
			} else {
				return `${res} ${this.getTenDiaDiem === undefined ? '' : 'tại ' + this.getTenDiaDiem}`
			}
		},
		isMobile() {
			return this.$vuetify.display.smAndDown
		}
	},
	watch: {
	},
	methods: {
		formatDate: window.formatDate,

		reset() {
			this.DSHangHoa = []
			this.TenPhieuKiemKe = null
			this.DSDaChonHangHoa = []
			this.selectedPhieuKiemKe_Id = null
		},

		closeDialog() {
			this.$emit('update:isShow', false)
			this.reset()
		},

		handleSelectedDiaDiem(value) {
			this.$emit('update:DiaDiem_Id', value)
			this.reset()
			this.loadDSPhieuKiemKe()
		},

		handleSelectedCaBiet(CaBiet) {
			if (CaBiet.Is_Selected) {
				this.DSDaChonHangHoa.push(CaBiet)
			} else {
				this.DSDaChonHangHoa = this.DSDaChonHangHoa.filter(
					item => item.CaBiet_Id !== CaBiet.CaBiet_Id
				)
			}
		},

		handleSelectedSoLuong(HangHoa) {
			if (HangHoa.Is_Selected) {
				this.DSDaChonHangHoa.push(HangHoa)
			} else {
				const idx = this.DSDaChonHangHoa.findIndex((x) => x.DiaDiem_Id === HangHoa.DiaDiem_Id &&
					x.KhuVuc_Id === HangHoa.KhuVuc_Id &&
					x.HangHoa_Id === HangHoa.HangHoa_Id)
				if (idx !== -1) {
					this.DSDaChonHangHoa.splice(idx, 1)
				}
			}
		},

		async loadDSHangHoaByDiaDiem() {
			let data = await apiCallPromise('work/HH_HangHoa_Select_ByDiaDiem_Id', {
				DiaDiem_Id: this.DiaDiem_Id
			})
			let res = []
			data.forEach((HangHoa) => {
				const DSCaBiet = JSON.parse(HangHoa?.DanhSachCaBiet || '[]')
				if (DSCaBiet.length > 0) {
					DSCaBiet.forEach((CaBiet) => {
						CaBiet.DonViTinh = HangHoa.TenDonVi
						CaBiet.DonViKiemKe_Id = HangHoa.Chuan_DonViTinh_Id
						CaBiet.SoLuong = 1
						CaBiet.Tong = 1
						CaBiet.Is_CaBiet = 1
					})
					HangHoa.DSCaBiet = DSCaBiet
				}
				HangHoa.DSCaBiet = DSCaBiet

				const DSSoLuong = JSON.parse(HangHoa?.DanhSachSoLuong || '[]')
				HangHoa.DSSoLuong = DSSoLuong
				res.push(HangHoa.HangHoa_Id)
			})
			const toDay = dayjs().format('DD/MM/YYYY')
			const tempTenPhieuKiemKe = `Kiểm kê ${this.getTenDiaDiem} - ${toDay}`
			this.TenPhieuKiemKe = this.TenPhieuKiemKe?.length > 0 ? this.TenPhieuKiemKe : tempTenPhieuKiemKe
			this.DSHangHoa = data
			this.DSDaChonHangHoa = []
			this.selectedPhieuKiemKe_Id = null
			this.expanded = res
		},

		async loadDSHangHoaByPhieuKiemKe() {
			const data = apiCallPromise('work/HH_PhieuKiemKe_Select_ById', {
				PhieuKiemKe_Id: this.selectedPhieuKiemKe_Id
			})
			this.DSHangHoa = data
		},

		onSelectedAll() {
			// selected all
			if (this.DSDaChonHangHoa.length === 0) {
				let res = []
				this.DSHangHoa.forEach((item) => {
					if (item.Is_CaBiet) {
						// hang hoa ca biet
						const DSCaBiet = item.DSCaBiet
						DSCaBiet.forEach((CaBiet) => {
							CaBiet.Is_Selected = true
							res.push(CaBiet)
						})
					} else {
						// hang hoa so luong
						const DSSoLuong = item.DSSoLuong
						DSSoLuong.forEach((HangHoa) => {
							HangHoa.Is_Selected = true
							res.push(HangHoa)
						})
					}
				})
				this.DSDaChonHangHoa = res
			} else {
				// unselected all
				this.DSDaChonHangHoa = []
				this.DSHangHoa.forEach((item) => {
					if (item.Is_CaBiet) {
						// hang hoa ca biet
						const DSCaBiet = item.DSCaBiet
						DSCaBiet.forEach((CaBiet) => {
							CaBiet.Is_Selected = false
						})
					} else {
						// hang hoa so luong
						const DSSoLuong = item.DSSoLuong
						DSSoLuong.forEach((HangHoa) => {
							HangHoa.Is_Selected = false
						})
					}
				})
			}
		},

		async onAddPhieuKiemKe() {
			if (this.DSDaChonHangHoa.length === 0) {
				showToast.info('Vui lòng chọn hàng hoá để kiểm kê')
				return
			}
			let res = []
			this.DSDaChonHangHoa.forEach((item) => {
				if (!item.Is_CaBiet) {
					const data = this.DSHangHoa.find((e) => e.HangHoa_Id === item.HangHoa_Id)
					item.DonViQuyDoi = data.DonViQuyDoi
					item.TenHangHoa = data.TenHangHoa
					item.Chuan_DonViTinh_Id = data.Chuan_DonViTinh_Id
					item.TenDonVi = data.TenDonVi
				}
				res.push(item)
			})
			let arraySoLuong = []
			let arrayCaBiet = []
			res.forEach((item) => {
				if (!item.Is_CaBiet && item.CaBiet_Id === undefined) {
					let DSDonViTinh = JSON.parse(item?.DonViQuyDoi || '[]')
					const flagBaseUnit = DSDonViTinh?.find((x) => x.DonViTinh_Id === item.Chuan_DonViTinh_Id)
					if (!flagBaseUnit) {
						DSDonViTinh.push({
							DonViTinh_Id: item.Chuan_DonViTinh_Id,
							HeSo: 1,
							TenDonViQuyDoi: item.TenDonVi
						})
						item.TongSauQuyDoi = item.SoLuong
					} else
						item.TongSauQuyDoi = Number((item.SoLuong / flagBaseUnit.HeSo).toFixed(2))
					item.DSDonViTinh = DSDonViTinh
					arraySoLuong.push(item)
				}
				else arrayCaBiet.push(item)
			})

			let tempArraySoLuong = []
			arraySoLuong.forEach((item) => {
				const tempItem = {
					HangHoa_Id: item.HangHoa_Id,
					KhuVuc_Id: item.KhuVuc_Id,
					Chuan_SoLuongTon: item.SoLuong,
				}
				tempArraySoLuong.push(tempItem)
			})

			let tempArrayCaBiet = []
			arrayCaBiet.forEach((item) => {
				const tempItem = {
					CaBiet_Id: item.CaBiet_Id,
					TinhTrangHienTai: item.TinhTrang,
					DiaDiemHienTai_Id: item.DiaDiem_Id,
					KhuVucHienTai_Id: item.KhuVuc_Id ?? 0
				}
				tempArrayCaBiet.push(tempItem)
			})

			let params = {
				TenPhieuKiemKe: this.TenPhieuKiemKe,
				DiaDiem_Id: this.DiaDiem_Id,
				JsonSoLuong: tempArraySoLuong.length > 0 ? JSON.stringify(tempArraySoLuong) : null,
				JsonCaBiet: tempArrayCaBiet.length > 0 ? JSON.stringify(tempArrayCaBiet) : null,
			}
			apiCall("work/HH_PhieuKiemKe_Insert", params, (res) => {
				if (res) showToast.success("Thành công");
				this.reset()
				this.loadDSPhieuKiemKe()
			})
		},

		emitLoadData() {
			this.$emit('load-data', {
				PageIndex: this.page ?? 1,
				PageSize: this.itemsPerPage ?? 50,
			})
		},

		onPageChange(newPage) {
			this.emitLoadData()
		},

		onItemsPerPageChange(newPerPage) {
			this.emitLoadData()
		},

		async onViewDetail(item) {
			const data = await apiCallPromise('work/HH_PhieuKiemKe_Select_ById', {
				PhieuKiemKe_Id: item.PhieuKiemKe_Id
			})
			let res = []
			data.forEach((HangHoa) => {
				const DSCaBiet = JSON.parse(HangHoa?.DanhSachCaBiet || '[]')
				if (DSCaBiet.length > 0) {
					DSCaBiet.forEach((CaBiet) => {
						CaBiet.DonViTinh = HangHoa.TenDonVi
						CaBiet.DonViKiemKe_Id = HangHoa.Chuan_DonViTinh_Id
						CaBiet.SoLuong = 1
						CaBiet.Tong = 1
						CaBiet.Is_CaBiet = 1
					})
					HangHoa.DSCaBiet = DSCaBiet
				}
				HangHoa.DSCaBiet = DSCaBiet

				const DSSoLuong = JSON.parse(HangHoa?.DanhSachSoLuong || '[]')
				HangHoa.DSSoLuong = DSSoLuong
				res.push(HangHoa.HangHoa_Id)
			})
			this.DSHangHoa = data
			this.DSDaChonHangHoa = []
			this.selectedPhieuKiemKe_Id = item.PhieuKiemKe_Id
			this.TenPhieuKiemKe = null
			this.expanded = res
		},

		onDelete(item) {
			const $this = this
			const params = {
				PhieuKiemKe_Id: item.PhieuKiemKe_Id,
			}
			showConfirm(
				`Xác nhận phiếu kiểm kê: <b>${item.TenPhieuKiemKe}</b>`,
				() => {
					apiCall("work/HH_PhieuKiemKe_Delete", params, (res) => {
						if (res) showToast.success("Thành công");;
						$this.reset()
						$this.loadDSPhieuKiemKe()
					})
				}
			)
		},
	},
}
</script>