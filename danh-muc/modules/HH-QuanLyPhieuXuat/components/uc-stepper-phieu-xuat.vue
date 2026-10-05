<template>
	<v-stepper class="stepper-flat" v-model="step">
		<template v-slot:default="{ prev, next }">
			<v-stepper-header class="stepper-flat">
				<template v-for="(step, index) in steps" :key="index + 1">
					<v-stepper-item :value="index + 1" :complete="step > index + 1" :title="step"
						:color="step > index + 1 ? 'primary' : ''" :class="step > index + 1 ? 'text-primary' : ''">
					</v-stepper-item>
					<v-divider :class="step > index + 1 ? 'border-opacity-99' : ''" :thickness="3"
						:color="step > index + 1 ? 'primary' : ''" v-if="index !== steps.length - 1" :key="index">
					</v-divider>
				</template>
			</v-stepper-header>

			<v-stepper-window class="mt-0">
				<v-stepper-window-item :key="1" :value="1">
					<v-card class="form-card-item">
						<v-card-text>
							<div class="form-section-label mb-3">Thông tin chung</div>
							<v-form ref="formStep1" v-model="isValidStep">
								<v-row dense>
									<v-col cols='6'>
										<uc-date-picker icon-color="primary" :rules="[rules.required]"
											:max="new Date().toISOString().substr(0, 10)" v-model="NgayXuat"
											label="Ngày xuất"></uc-date-picker>
									</v-col>
									<v-col cols='6'>
										<v-autocomplete v-model="MaNguoiXuat" label="Người xuất"
											:rules="[rules.required]" :items="DSNhanVien" item-title="HoVaTenNhanVien"
											item-value="MaNhanVien" density="compact">
											<template #chip="{ props, item }">
												<v-chip v-bind="props" :text="item.raw.HoVaTenNhanVien">
													<template #prepend>
														<v-avatar size="24" :color="!item.raw.AnhDaiDien_Url
															? stringToColor(item.raw.HoVaTenNhanVien)
															: undefined">
															<v-img v-if="item.raw.AnhDaiDien_Url"
																:src="'https://file.zentea.vn/work/FileData/' + item.raw.AnhDaiDien_Url" />
															<span v-else
																class="text-caption font-weight-medium text-white">
																{{ getInitials(item.raw.HoVaTenNhanVien) }}
															</span>
														</v-avatar>
													</template>
												</v-chip>
											</template>

											<template #item="{ props, item }">
												<v-list-item v-bind="props">
													<template #prepend>
														<v-avatar :color="!item.raw.AnhDaiDien_Url
															? stringToColor(item.raw.HoVaTenNhanVien)
															: undefined">
															<v-img v-if="item.raw.AnhDaiDien_Url"
																:src="'https://file.zentea.vn/work/FileData/' + item.raw.AnhDaiDien_Url" />
															<span v-else
																class="text-caption font-weight-medium text-white">
																{{ getInitials(item.raw.HoVaTenNhanVien) }}
															</span>
														</v-avatar>
													</template>
													<v-list-item-title>
														{{ item.raw.MaNhanVien }} - {{ item.raw.TenVanPhong }}
													</v-list-item-title>
												</v-list-item>
											</template>
										</v-autocomplete>
									</v-col>
									<v-col cols='6'>
										<v-text-field color="primary" v-model="SoPhieuXuat"
											:rules="[rules.required, rules.noSpecialChar]" maxlength="20"
											placeholder="Tối đa 20 kí tự" label="Số phiếu xuất"></v-text-field>
									</v-col>
									<v-col cols='6'>
										<v-select color="primary" v-model="LoaiPhieuXuat" density="compact"
											:items="DSLoaiPhieuXuat" :rules="[rules.required]" item-value="value"
											item-title="title" label="Loại phiếu xuất">
										</v-select>
									</v-col>
								</v-row>

								<div class="form-section-label mb-3 mt-2">Địa điểm & Ghi chú</div>
								<v-row dense>
									<v-col cols='6'>
										<v-autocomplete color="primary" v-model="DiaDiem_Id" density="compact"
											:items="DSDiaDiem" :rules="[rules.required]" item-value="DiaDiem_Id"
											item-title="TenDiaDiem" label="Địa điểm">
										</v-autocomplete>
									</v-col>
									<v-col cols='6'>
										<v-textarea full-width rows="1" v-model="GhiChu" label="Ghi chú"></v-textarea>
									</v-col>
								</v-row>
							</v-form>
						</v-card-text>
					</v-card>
				</v-stepper-window-item>

				<v-stepper-window-item :key="2" :value="2">
					<!-- Summary bar -->
					<div class="stepper-summary-bar mb-3">
						<div class="stepper-summary-item">
							<span class="label">Đã chọn</span>
							<span class="value">{{ soMatHangDaChon }}</span>
						</div>
					</div>

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
							color="blue" prepend-icon="mdi-check-circle-outline" class="ml-2"
							@click="showOnlySelected = !showOnlySelected">
							Đã chọn ({{ DSDaChon.length }})
						</v-chip>
						<v-text-field v-model="search" density="compact" variant="underlined" label="Tìm kiếm"
							prepend-inner-icon="mdi-magnify" flat hide-details single-line
							style="max-width:200px"></v-text-field>
					</v-toolbar>
					<v-form ref="formStep2" v-model="isValidStep">
						<v-card class="form-card-item mt-1">
							<v-card-text>
								<v-data-table v-model="DSDaChon" :items="filterDSHangHoa" :headers="headerHangHoa"
									:search="search" v-model:expanded="expanded" fixed-header height="500" show-expand
									density="compact" :disable-sort="true" item-value="HangHoa_Id" :items-per-page="itemsPerPage"
									items-per-page-text="Số dòng" :items-per-page-options="[20, 50, 100]">

									<template v-slot:expanded-row="{ columns, item }">
										<tr v-if="item.DSCaBiet.length > 0">
											<td :colspan="columns.length" class="pa-0">
												<v-sheet border class="ma-2">
													<v-table density="compact" class="text-body-2">
														<thead class="bg-surface-light">
															<tr>
																<th class="text-center" style="width: 48px;"></th>
																<th class="text-start font-weight-medium"
																	style="width: 150px;">Mã
																	vạch</th>
																<th class="text-start font-weight-medium">Số Serial</th>
																<th class="text-center font-weight-medium"
																	style="width: 300px;">
																	Tình trạng</th>
															</tr>
														</thead>

														<tbody>
															<tr v-for="(CaBiet, index) in item.DSCaBiet" :key="index">
																<td class="text-center" style="width: 48px;">
																	<v-checkbox v-model="CaBiet.Is_Selected"
																		density="compact" hide-details
																		@update:model-value="handleSelectedCaBiet(CaBiet)" />
																</td>

																<td class="text-start text-grey-darken-1"
																	style="width: 150px;">
																	{{ CaBiet.MaVach || 'Chưa có' }}
																</td>

																<td class="text-start">
																	{{ CaBiet.SoSeries }}
																</td>

																<td class="text-center" style="width: 300px;">
																	<v-chip
																		:color="mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrang].color"
																		size="small" variant="tonal">
																		{{
																		mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrang].text
																		}}
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
																<th class="text-start font-weight-medium">Tên khu vực
																</th>
																<th class="text-center font-weight-medium"
																	style="width: 250px;">Đơn
																	vị tính</th>
																<th class="text-end font-weight-medium"
																	style="width: 150px;"></th>
															</tr>
														</thead>

														<tbody>
															<tr v-for="(HangHoa, index) in item.DSSoLuong" :key="index">
																<td class="text-center" style="width: 50px;">
																	<v-checkbox v-model="HangHoa.Is_Selected"
																		density="compact" hide-details
																		@update:model-value="handleSelectedSoLuong(HangHoa)" />
																</td>

																<td class="text-start">
																	{{ HangHoa.TenKhuVuc }}
																</td>

																<td style="width: 250px;">
																	<v-select v-model="HangHoa.DonViXuat_Id"
																		:items="HangHoa.DSDonViTinh"
																		item-title="TenDonViQuyDoi"
																		item-value="DonViTinh_Id" density="compact"
																		variant="underlined" hide-details
																		@update:model-value="handleSelectedDonViTinh(HangHoa)" />
																</td>

																<td class="text-end" style="width: 150px;">
																	<v-text-field v-model="HangHoa.SoLuongXuat"
																		density="compact" variant="underlined"
																		type="number" hide-details reverse
																		:rules="[maxRule(HangHoa)]"
																		:disabled="HangHoa.DonViXuat_Id === null"
																		step="0.01"
																		@blur="HangHoa.SoLuongXuat = format2(HangHoa.SoLuongXuat)">
																		<template #append-inner>
																			<span class="text-grey"> {{ '/' +
																				(HangHoa.TongSauQuyDoi ?? HangHoa.Tong)
																				}}
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

									<template
										v-slot:item.data-table-expand="{ internalItem, isExpanded, toggleExpand }">
										<v-btn :icon="isExpanded(internalItem) ? 'mdi-chevron-up' : 'mdi-chevron-down'"
											size="small" @click="toggleExpand(internalItem)" variant="text"></v-btn>
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
					</v-form>
				</v-stepper-window-item>
			</v-stepper-window>

			<v-stepper-actions class="d-flex justify-end">
				<template v-slot:prev>
					<v-btn v-if="step > 1" color="grey-darken-3" variant="outlined" @click="handleClickPrev"
						class="mr-2">
						Trở về
					</v-btn>
				</template>
				<template v-slot:next>
					<v-btn color="primary" variant="flat" @click="handleClickNext" :disabled="!isValidStep">
						{{ step === steps.length ? "Hoàn tất" : "Tiếp tục" }}
					</v-btn>
				</template>
			</v-stepper-actions>
		</template>
	</v-stepper>
</template>

<script>
	export default {
	
		props: {
			DSNhanVien: Array,
			DSDiaDiem: Array,
			loadDSPhieuXuat: Function,
			closeDialog: Function,
		},
	
		data() {
			return {
				mapTinhTrangHangHoaCaBiet,
				step: 1,
				steps: ["Bước 1: Tạo phiếu xuất", "Bước 2: Chọn hàng hoá"],
				rules: {
					required: v => v !== null && v !== undefined || 'Trường này không được để trống',
					greaterThanZero: v => v > 0 || 'Giá trị phải lớn hơn 0',
					noSpecialChar: v =>
						/^[a-zA-Z0-9\s]+$/.test(v) || 'Không được chứa ký tự đặc biệt',
				},
				isValidStep: null,
				headerHangHoa: [
					{ width: 1, key: 'data-table-expand', align: 'start' },
					{ title: "Tên hàng hoá", key: "TenHangHoa", align: 'start' },
				],
	
				DSLoaiPhieuXuat: [
					{ title: 'Huỷ', value: 'HUY' },
					{ title: 'Sử dụng', value: 'SU_DUNG' },
					{ title: 'Sản xuất', value: 'SAN_XUAT' },
				],
	
				DSHangHoa: [],
				DSDaChon: [{}],
	
				NgayXuat: new Date(),
				MaNguoiXuat: null,
				DiaDiem_Id: null,
				SoPhieuXuat: null,
				LoaiPhieuXuat: null,
				search: null,
				GhiChu: null,
				expanded: [],
				filterMode: 'TAT_CA',
				showOnlySelected: false,
				itemsPerPage: 50
			}
		},
	
		mounted() {
		},
		computed: {
			getTenDiaDiem() {
				const res = this.DSDiaDiem.find((DiaDiem) => DiaDiem.DiaDiem_Id === this.DiaDiem_Id)
				return res.TenDiaDiem
			},
			filterDSHangHoa() {
				var list = this.DSHangHoa || []

				if (this.filterMode !== 'TAT_CA') {
					var mode = this.filterMode
					list = list.filter(function (HangHoa) { return HangHoa.LoaiHangHoa === mode })
				}

				if (this.showOnlySelected) {
					list = list.filter(function (HangHoa) {
						var hasCaBiet = HangHoa.DSCaBiet && HangHoa.DSCaBiet.some(function (cb) { return cb.Is_Selected })
						var hasSoLuong = HangHoa.DSSoLuong && HangHoa.DSSoLuong.some(function (sl) { return sl.Is_Selected })
						return hasCaBiet || hasSoLuong
					})
				}

				return list
			},
			soMatHangDaChon() {
				return this.DSDaChon.length
			},
		},
	
		watch: {
		},
	
		methods: {
			formatDate: window.formatDate,
	
			getInitials(name) {
				if (!name) return ''
				const parts = name.trim().split(/\s+/)
				return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
			},
	
			stringToColor(str) {
				if (!str) return 'grey'
				let hash = 0
				for (let i = 0; i < str.length; i++) {
					hash = str.charCodeAt(i) + ((hash << 5) - hash)
				}
				const colors = [
					'red', 'pink', 'purple', 'deep-purple',
					'indigo', 'blue', 'cyan', 'teal',
					'green', 'light-green', 'lime',
					'amber', 'orange', 'deep-orange'
				]
				return colors[Math.abs(hash) % colors.length]
			},
	
			format2(v) {
				const n = parseFloat(v)
				if (isNaN(n)) return ''
				return (Math.round(n * 100) / 100).toFixed(2)
			},
	
			handleClickPrev() {
				switch (this.step) {
					case 1:
						break;
					case 2:
						this.step--
						break;
				}
			},
	
			async handleClickNext() {
				switch (this.step) {
					case 1:
						// Load HangHoa thuộc cửa hàng
						let res = await apiCallPromise('work/HH_HangHoa_Select_ByDiaDiem_Id', {
							DiaDiem_Id: this.DiaDiem_Id,
							ThoiGian: this.NgayXuat
						})
						let data = res[0]
						let temp_expanded = []
						data.forEach((HangHoa) => {
							const DSCaBiet = JSON.parse(HangHoa?.DanhSachCaBiet || '[]')
							DSCaBiet.forEach((CaBiet) => {
								CaBiet.DonViTinh = HangHoa.TenDonVi
								CaBiet.DonViXuat_Id = HangHoa.Chuan_DonViTinh_Id
								CaBiet.SoLuong = 1
								CaBiet.Tong = 1
								CaBiet.Is_CaBiet = 1
							})
							HangHoa.DSCaBiet = DSCaBiet
							// HangHoa SoLuong
							let DSSoLuong = JSON.parse(HangHoa?.DanhSachSoLuong || '[]')
							DSSoLuong.forEach((item) => {
								item.DonViXuat_Id = HangHoa.Chuan_DonViTinh_Id
								let DSDonViTinh = JSON.parse(HangHoa?.DonViQuyDoi || '[]')
								const flagBaseUnit = DSDonViTinh?.find((x) => x.DonViTinh_Id === item.Chuan_DonViTinh_Id)
								if (!flagBaseUnit) {
									DSDonViTinh.push({
										DonViTinh_Id: HangHoa.Chuan_DonViTinh_Id,
										HeSo: 1,
										TenDonViQuyDoi: HangHoa.TenDonVi
									})
								}
								item.TongSauQuyDoi = item.SoLuong
								item.DSDonViTinh = DSDonViTinh
							})
							HangHoa.DSSoLuong = DSSoLuong
							temp_expanded.push(HangHoa.HangHoa_Id)
						})
						this.expanded = temp_expanded
						this.DSHangHoa = data
						this.DSDaChon = []
						this.step++
						break;
					case 2:
						this.onSubmit()
	
				}
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
					const idx = this.DSDaChon.findIndex((x) => x.DiaDiem_Id === HangHoa.DiaDiem_Id &&
						x.KhuVuc_Id === HangHoa.KhuVuc_Id &&
						x.HangHoa_Id === HangHoa.HangHoa_Id)
					if (idx !== -1) {
						this.DSDaChon.splice(idx, 1)
					}
				}
			},
	
			maxRule(item) {
				return v => {
					if (!item.Is_Selected) return true
	
					const maxValue = item.TongSauQuyDoi ?? item.Tong
					return (Number(v) > 0 && Number(v) <= maxValue)
						|| `Tối đa ${maxValue}`
				}
			},
	
			handleSelectedDonViTinh(item) {
				if (item.DonViXuat_Id === item.Chuan_DonViTinh_Id) {
					item.TongSauQuyDoi = item.SoLuong
					return
				}
				const QuyDoi = item.DSDonViTinh.find((x) => x.DonViTinh_Id === item.DonViXuat_Id)
				const HeSo = QuyDoi?.HeSo ?? 1
				item.TongSauQuyDoi = Number((item.SoLuong / HeSo).toFixed(2))
			},
	
			async onSubmit() {
				const { valid } = await this.$refs.formStep2.validate();
				if (!valid) {
					showToast.info('Thông tin chưa đầy đủ hoặc chưa chính xác')
					return
				}
	
				if (this.DSDaChon.length === 0) {
					showToast.info('Chưa chọn hàng hoá để xuất')
					return 0
				}
				let tempArraySoLuong = []
				const arraySoLuong = this.DSDaChon.filter((HangHoa) => HangHoa.Is_CaBiet !== 1)
				const arrayCaBiet = this.DSDaChon.filter((HangHoa) => HangHoa.Is_CaBiet === 1)
				const HangHoaChuaNhapSoLuong = arraySoLuong.filter((HangHoa) => HangHoa?.SoLuongXuat == null)
	
				if (HangHoaChuaNhapSoLuong.length > 0) {
					showToast.info('Có hàng hoá chưa nhập số lượng, vui lòng kiểm tra lại')
					return 0
				}
				arraySoLuong.forEach((item) => {
					const tempItem = {
						HangHoa_Id: item.HangHoa_Id,
						DonViXuat_Id: item.DonViXuat_Id,
						SoLuong: item.SoLuongXuat,
						KhuVuc_Id: item.KhuVuc_Id
					}
					tempArraySoLuong.push(tempItem)
				})
	
				let tempArrayCaBiet = []
				arrayCaBiet.forEach((item) => {
					const tempItem = {
						CaBiet_Id: item.CaBiet_Id,
						DonViXuat_Id: item.DonViXuat_Id,
						KhuVuc_Id: item.KhuVuc_Id,
					}
					tempArrayCaBiet.push(tempItem)
				})
	
				showConfirm(
					`Việc lập phiếu xuất này ảnh hưởng trực tiếp đến tồn kho 
								tại 
								<strong>
								${this.getTenDiaDiem}
								</strong>
								</br>Bạn có chắc chắn muốn tiếp tục?`,
					() => {
						const params = {
							DiaDiem_Id: this.DiaDiem_Id,
							SoPhieuXuat: this.SoPhieuXuat,
							LoaiPhieuXuat: this.LoaiPhieuXuat,
							NgayXuat: dayjs(this.NgayXuat).format('YYYY-MM-DD'),
							MaNguoiXuat: this.MaNguoiXuat,
							GhiChu: this.GhiChu,
							JsonSoLuong: tempArraySoLuong.length > 0 ? JSON.stringify(tempArraySoLuong) : null,
							JsonCaBiet: tempArrayCaBiet.length > 0 ? JSON.stringify(tempArrayCaBiet) : null,
						}
						apiCall("work/HH_PhieuXuat_Insert", params, (res) => {
							if (res) showToast.success("Thành công");
							this.closeDialog()
							this.loadDSPhieuXuat()
						})
					}
				)
			},
	
		}
	
	}
</script>