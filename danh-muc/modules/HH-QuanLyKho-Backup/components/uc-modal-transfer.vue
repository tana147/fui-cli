<template>
	<v-dialog v-model="isShow" persistent width="1000">
		<v-card>
			<v-toolbar density="compact" elevation="0" class="mt-2">
				<v-toolbar-title class="mb-2">
					Luân chuyển
					<div class="text-subtitle-2 ">
						Địa điểm hiện tại: {{ getTenDiaDiem }}
					</div>
				</v-toolbar-title>
				<v-spacer />
				<v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
			</v-toolbar>
			<v-divider></v-divider>
			<v-card-text class="pt-2">
				<v-form ref="form">
					<v-row dense>
						<v-col cols="6">
							<v-autocomplete color="primary" v-model="DiaDiemDen_Id" density="compact" :items="DSDiaDiem"
								:rules="[rules.required]" item-value="DiaDiem_Id" item-title="TenDiaDiem"
								label="Địa điểm đích">
							</v-autocomplete>
						</v-col>
						<v-col cols="6">
							<v-autocomplete color="primary" v-model="KhuVucDen_Id" density="compact"
								:items="DSKhuVucFilter" :rules="[rules.required]" item-value="KhuVuc_Id"
								item-title="TenKhuVuc" label="Khu vực đến" :disabled="DiaDiemDen_Id === null">
							</v-autocomplete>
						</v-col>
					</v-row>
					<v-toolbar density="compact" elevation="0">
						<v-toolbar-title>
							Danh sách hàng hoá
						</v-toolbar-title>
						<v-spacer></v-spacer>
						<v-chip-group v-model="filterMode" mandatory selected-class="text-primary">
							<v-chip value="TAT_CA" filter variant="outlined" color="primary">
								Tất cả
							</v-chip>
							<v-chip value="NVL" filter variant="outlined" color="success">
								NVL
							</v-chip>
							<v-chip value="CCDC" filter variant="outlined" color="error">
								CCDC
							</v-chip>
						</v-chip-group>
						<v-chip v-if="DSDaChon.length > 0" :variant="showOnlySelected ? 'flat' : 'outlined'"
							color="primary" prepend-icon="mdi-check-circle-outline" class="ml-2"
							@click="showOnlySelected = !showOnlySelected">
							Đã chọn ({{ DSDaChon.length }})
						</v-chip>
						<v-text-field v-model="search" density="compact" variant="underlined" label="Tìm kiếm"
							prepend-inner-icon="mdi-magnify" flat hide-details single-line
							style="max-width:200px"></v-text-field>
					</v-toolbar>
					<v-data-table v-model="DSDaChon" :items="filterDSHangHoa" :headers="headerHangHoa" :search="search"
						v-model:expanded="itemTransfer.expanded" fixed-header height="500" show-expand density="compact"
						:disable-sort="true" item-value="HangHoa_Id" :items-per-page="itemsPerPage"
						items-per-page-text="Số dòng" :items-per-page-options="[20, 50, 100]">

						<template v-slot:expanded-row="{ columns, item }">
							<tr v-if="item.DSCaBiet.length > 0">
								<td :colspan="columns.length" class="pa-0">
									<v-sheet border class="ma-2">
										<v-table density="compact" class="text-body-2">
											<thead class="bg-surface-light">
												<tr>
													<th class="text-center" style="width: 48px;"></th>
													<th class="text-start font-weight-medium" style="width: 150px;">Mã
														vạch</th>
													<th class="text-start font-weight-medium">Số Serial</th>
													<th class="text-center font-weight-medium" style="width: 300px;">
														Tình trạng</th>
												</tr>
											</thead>

											<tbody>
												<tr v-for="(CaBiet, index) in item.DSCaBiet" :key="index">
													<td class="text-center" style="width: 48px;">
														<v-checkbox v-model="CaBiet.Is_Selected" density="compact"
															hide-details
															@update:model-value="handleSelectedCaBiet(CaBiet)" />
													</td>

													<td class="text-start text-grey-darken-1" style="width: 150px;">
														{{ CaBiet.MaVach || 'Chưa có' }}
													</td>

													<td class="text-start">
														{{ CaBiet.SoSeries }}
													</td>

													<td class="text-center" style="width: 300px;">
														<v-chip
															:color="mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrang]?.color"
															size="small" variant="tonal">
															{{ mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrang]?.text }}
														</v-chip>
													</td>
												</tr>
											</tbody>
										</v-table>
									</v-sheet>
								</td>
							</tr>

							<tr v-if="item.DSSoLuong.length > 0">
								<td :colspan="columns.length" class="pa-0">
									<v-sheet border class="ma-2">
										<v-table density="compact" class="text-body-2">
											<thead class="bg-surface-light">
												<tr>
													<th class="text-center" style="width: 50px;"></th>
													<th class="text-start font-weight-medium">Tên khu vực</th>
													<th class="text-center font-weight-medium" style="width: 250px;">Đơn
														vị tính</th>
													<th class="text-end font-weight-medium" style="width: 150px;"></th>
												</tr>
											</thead>

											<tbody>
												<tr v-for="(HangHoa, index) in item.DSSoLuong" :key="index">
													<td class="text-center" style="width: 50px;">
														<v-checkbox v-model="HangHoa.Is_Selected" density="compact"
															hide-details
															@update:model-value="handleSelectedSoLuong(HangHoa)" />
													</td>

													<td class="text-start">
														{{ HangHoa.TenKhuVuc }}
													</td>

													<td style="width: 250px;">
														<v-select v-model="HangHoa.DonViChuyen_Id"
															:items="HangHoa.DSDonViTinh" item-title="TenDonViQuyDoi"
															item-value="DonViTinh_Id" density="compact"
															variant="underlined" hide-details
															@update:model-value="handleSelectedDonViTinh(HangHoa)" />
													</td>

													<td class="text-end" style="width: 150px;">
														<v-text-field v-model="HangHoa.SoLuongChuyen" density="compact"
															variant="underlined" type="number" hide-details reverse
															:rules="[maxRule(HangHoa)]"
															:disabled="HangHoa.DonViChuyen_Id === null" step="0.01"
															@blur="HangHoa.SoLuongChuyen = format2(HangHoa.SoLuongChuyen)">
															<template #append-inner>
																<span class="text-grey"> {{ '/' +
																	(HangHoa.TongSauQuyDoi ?? HangHoa.Tong) }}
																</span>
															</template>
														</v-text-field>
													</td>
												</tr>
											</tbody>
										</v-table>
									</v-sheet>
								</td>
							</tr>
						</template>

						<template v-slot:item.data-table-expand="{ internalItem, isExpanded, toggleExpand }">
							<v-btn :icon="isExpanded(internalItem) ? 'mdi-chevron-up' : 'mdi-chevron-down'" size="small"
								@click="toggleExpand(internalItem)" variant="text"></v-btn>
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
				</v-form>
			</v-card-text>
			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn color="primary" @click="onSubmit" variant="flat">
					Luân chuyển
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
export default {
	props: {
		isShow: Boolean,
		itemTransfer: Object,
		DSDiaDiem: Array,
		DSKhuVuc: Array,
	},

	emits: ['update:isShow', 'onReload'],

	data() {
		return {
			mapTinhTrangHangHoaCaBiet,
			formatDate: window.formatDate,
			rules: {
				required: v => v !== null && v !== undefined || 'Trường này không được để trống',
				greaterThanZero: v => v > 0 || 'Giá trị phải lớn hơn 0',
				noSpecialChar: v =>
					/^[a-zA-Z0-9\s]+$/.test(v) || 'Không được chứa ký tự đặc biệt',
			},
			headerHangHoa: [
				{ width: 1, key: 'data-table-expand', align: 'start' },
				{ title: "Tên hàng hoá", key: "TenHangHoa", align: 'start' },
			],
			DSDaChon: [],
			DiaDiemDen_Id: null,
			KhuVucDen_Id: null,
			search: null,
			filterMode: 'TAT_CA',
			showOnlySelected: false,
			itemsPerPage: 50
		}
	},
	computed: {
		DSDiaDiemFilter() {
			return this.DSDiaDiem.filter((DiaDiem) => DiaDiem.DiaDiem_Id !== this.itemTransfer.DiaDiem_Id)
		},
		getTenDiaDiem() {
			const res = this.DSDiaDiem.find((DiaDiem) => DiaDiem.DiaDiem_Id === this.itemTransfer.DiaDiem_Id)
			return res?.TenDiaDiem
		},
		DSKhuVucFilter() {
			let res = this.DSKhuVuc.filter((KhuVuc) => KhuVuc.DiaDiem_Id === this.DiaDiemDen_Id)
			return [
				{ KhuVuc_Id: 0, TenKhuVuc: 'Kho' },
				...res
			]
		},
		filterDSHangHoa() {
			var list = this.itemTransfer.DSHangHoa || []

			if (this.filterMode !== 'TAT_CA') {
				list = list.filter(function (HangHoa) { return HangHoa.LoaiHangHoa === this }.bind(this.filterMode))
			}

			if (this.showOnlySelected) {
				list = list.filter(function (HangHoa) {
					var hasCaBiet = HangHoa.DSCaBiet && HangHoa.DSCaBiet.some(function (cb) { return cb.Is_Selected })
					var hasSoLuong = HangHoa.DSSoLuong && HangHoa.DSSoLuong.some(function (sl) { return sl.Is_Selected })
					return hasCaBiet || hasSoLuong
				})
			}

			return list
		}
	},
	watch: {
		DiaDiemDen_Id: function () {
			this.KhuVucDen_Id = 0
		},
	},
	methods: {
		closeDialog() {
			this.DiaDiemDen_Id = null
			this.KhuVucDen_Id = null
			this.DSDaChon = []
			this.showOnlySelected = false
			this.$emit('update:isShow', false)
		},

		maxRule(item) {
			return v => {
				if (!item.Is_Selected) return true

				const maxValue = item.TongSauQuyDoi ?? item.Tong
				return (Number(v) > 0 && Number(v) <= maxValue)
					|| `Tối đa ${maxValue}`
			}
		},

		format2(v) {
			const n = parseFloat(v)
			if (isNaN(n)) return ''
			return (Math.round(n * 100) / 100).toFixed(2)
		},

		handleSelectedDonViTinh(item) {
			if (item.DonViChuyen_Id === item.Chuan_DonViTinh_Id) {
				item.TongSauQuyDoi = item.SoLuong
				return
			}
			const QuyDoi = item.DSDonViTinh.find((x) => x.DonViTinh_Id === item.DonViChuyen_Id)
			item.TongSauQuyDoi = Number((item.SoLuong / QuyDoi.HeSo).toFixed(2))
		},

		handleSelectedCaBiet(CaBiet) {
			if (CaBiet.Is_Selected) {
				this.DSDaChon.push(CaBiet)
			} else {
				this.DSDaChon = this.DSDaChon.filter(
					item => item.CaBiet_Id !== CaBiet.CaBiet_Id
				)
			}
		},

		handleSelectedSoLuong(HangHoa) {
			if (HangHoa.Is_Selected) {
				this.DSDaChon.push(HangHoa)
			} else {
				HangHoa.SoLuongChuyen = undefined
				const idx = this.DSDaChon.findIndex((x) => x.DiaDiem_Id === HangHoa.DiaDiem_Id &&
					x.KhuVuc_Id === HangHoa.KhuVuc_Id &&
					x.HangHoa_Id === HangHoa.HangHoa_Id)
				if (idx !== -1) {
					this.DSDaChon.splice(idx, 1)
				}
			}
		},

		async onSubmit() {
			const { valid } = await this.$refs.form.validate();
			if (!valid) {
				showToast.info('Thông tin chưa đầy đủ hoặc chưa chính xác')
				return
			}

			if (this.DSDaChon.length === 0) {
				showToast.info('Chưa chọn hàng hoá để luân chuyển')
				return 0
			}

			const arraySoLuong = this.DSDaChon.filter((HangHoa) => HangHoa.Is_CaBiet !== 1)
			const arrayCaBiet = this.DSDaChon.filter((HangHoa) => HangHoa.Is_CaBiet === 1)

			const HangHoaChuaNhapSoLuong = arraySoLuong.filter((HangHoa) => HangHoa?.SoLuongChuyen == null)

			if (HangHoaChuaNhapSoLuong.length > 0) {
				showToast.info('Có hàng hoá chưa nhập số lượng, vui lòng kiểm tra lại')
				return 0
			}

			let tempArraySoLuong = []
			arraySoLuong.forEach((item) => {
				const tempItem = {
					HangHoa_Id: item.HangHoa_Id,
					DonViChuyen_Id: item.DonViChuyen_Id,
					SoLuong: item.SoLuongChuyen,
					KhuVucHienTai_Id: item.KhuVuc_Id,
					KhuVucDen_Id: this.KhuVucDen_Id
				}
				tempArraySoLuong.push(tempItem)
			})

			let tempArrayCaBiet = []
			arrayCaBiet.forEach((item) => {
				const tempItem = {
					CaBiet_Id: item.CaBiet_Id,
					KhuVucHienTai_Id: item.KhuVuc_Id,
					KhuVucDen_Id: this.KhuVucDen_Id
				}
				tempArrayCaBiet.push(tempItem)
			})
			showConfirm(
				`Việc luân chuyển này ảnh hưởng trực tiếp đến tồn kho  
								tại 
								<strong>
								${this.getTenDiaDiem}
								</strong>
								</br>Bạn có chắc chắn muốn tiếp tục?`,
				() => {
					const params = {
						DiaDiemHienTai_Id: this.itemTransfer.DiaDiem_Id,
						DiaDiemDen_Id: this.DiaDiemDen_Id,
						JsonSoLuong: tempArraySoLuong?.length > 0 ? JSON.stringify(tempArraySoLuong) : null,
						JsonCaBiet: tempArrayCaBiet?.length > 0 ? JSON.stringify(tempArrayCaBiet) : null,
					}
					apiCall("work/HH_Kho_LuanChuyen", params, (res) => {
						if (res) showToast.success("Thành công");
						this.closeDialog()
						this.$emit('onReload')
					})
				}
			)
		}
	},
}

</script>