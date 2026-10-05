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
					<v-card>
						<v-card-title>Tạo phiếu nhập</v-card-title>
						<v-card-text>
							<v-form ref="formStep1" v-model="isValidStep">
								<v-row dense class="mt-1">
									<v-col cols='12' md="4">
										<uc-date-picker icon-color="primary" :rules="[rules.required]"
											:max="new Date().toISOString().substr(0, 10)"
											v-model="selectedItem.NgayDatHang" label="Ngày mua"></uc-date-picker>
									</v-col>
									<v-col cols='12' md="4">
										<v-autocomplete v-model="selectedItem.MaNguoiMua" label="Người mua"
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
									<v-col cols='12' md="4">
										<v-select color="primary" v-model="selectedItem.TinhTrangPhieuNhap"
											density="compact" :items="DSTinhTrangPhieuNhap" :rules="[rules.required]"
											item-value="value" item-title="title" label="Tình trạng">
										</v-select>
									</v-col>
									<v-col cols='12' md="6">
										<v-text-field color="primary" v-model="selectedItem.SoHoaDon" maxlength="20"
											:rules="[rules.required, rules.noSpecialChar]" placeholder="Tối đa 20 kí tự"
											label="Số hóa đơn"></v-text-field>
									</v-col>
									<v-col cols='12' md="6">
										<v-select color="primary" v-model="selectedItem.TinhTrangHoaDon"
											density="compact" :items="DSTinhTrangHoaDon" :rules="[rules.required]"
											item-value="value" item-title="title" label="Tình trạng hoá đơn">
										</v-select>
									</v-col>
									<v-col cols='12' md="6">
										<v-autocomplete color="primary" v-model="selectedItem.NhaCungCap_Id"
											density="compact" :items="DSNhaCungCap" :rules="[rules.required]"
											item-value="NhaCungCap_Id" item-title="TenNhaCungCap" label="Nhà cung cấp">
										</v-autocomplete>
									</v-col>
									<v-col cols='12' md="6">
										<v-autocomplete color="primary" v-model="selectedItem.DiaDiem_Id"
											density="compact" :items="DSDiaDiem" :rules="[rules.required]"
											item-value="DiaDiem_Id" item-title="TenDiaDiem" label="Địa điểm">
										</v-autocomplete>
									</v-col>
									<v-col cols="12">
										<uc-input-file-multi v-model='files' :multiple="true" :show-size="true">
										</uc-input-file-multi>
									</v-col>
								</v-row>
							</v-form>
						</v-card-text>
					</v-card>
				</v-stepper-window-item>

				<v-stepper-window-item :key="2" :value="2">
					<v-row>
						<v-col class="pa-0 pt-4 pl-3" cols='11' md="6">
							<div class="sticky-toolbar d-flex">
								<div class="v-toolbar-title">
									Danh sách hàng hoá
								</div>
							</div>

							<v-form ref="formStep2" style="height: calc(100vh - 300px); overflow-y: auto;">
								<v-card v-for="(form, index) in selectedItem.arrayHangHoa" :key="index"
									class="form-card-item mt-1">
									<v-card-text class='position-relative '>
										<v-row class="d-flex justify-center align-center">
											<v-col cols="12">
												<span class="form-label-inline">Loại hàng hoá:</span>
												<span class="form-text">{{ form.LoaiHangHoa }}</span>
											</v-col>
										</v-row>
										<template v-if="form.LoaiHangHoa === 'NVL'">
											<v-row dense class="mt-1 align-center">
												<v-col cols="12">
													<span class="form-label-inline">Tên hàng hoá:</span>
													<span class="form-text">
														{{ form.MaNoiBo + ' - ' + form.TenHangHoa }}
													</span>
												</v-col>
												<v-col cols="4">
													<v-text-field :model-value="form.TenDonVi" label="Đơn vị tính"
														density="compact" variant="outlined" readonly tabindex="-1"
														class="no-focus-field" :clearable='false' />
												</v-col>
												<v-col cols="4">
													<v-text-field :model-value="form.SoLuongDat" label="Số lượng"
														density="compact" variant="outlined" readonly tabindex="-1"
														class="no-focus-field" :clearable='false' />
												</v-col>
												<v-col cols="4">
													<uc-input-price-multi v-model="form.DonGia" label="Đơn giá"
														:items="getDSGiaGanDay(form)" :rules="[rules.required]" />
												</v-col>
												<v-col cols="12" class="d-flex flex-wrap ga-2">
													<v-chip color="primary" variant="tonal">
														Thuế GTGT: {{ form.ThueGTGT ?? 0 }}%
													</v-chip>

													<v-chip color="orange" variant="tonal">
														Thuế khác: {{ form.ThueKhac ?? 0 }}%
													</v-chip>

													<v-chip color="green" variant="tonal">
														Thuế nhập khẩu: {{ form.ThueNhapKhau ?? 0 }}%
													</v-chip>
												</v-col>

												<v-col cols="6">
													<v-text-field :clearable="false" v-model="form.PhanTramKhac"
														type="number" :rules="[rules.noSpecialChar]"
														label="Thuế khác (%)">
													</v-text-field>
												</v-col>

												<v-col cols="6">
													<uc-input-price v-model="form.ChiPhiKhac" label="Chi phí khác">
													</uc-input-price>
												</v-col>
												<v-col cols="12">
													<v-textarea full-width rows="2" v-model="form.GhiChu"
														label="Ghi chú"></v-textarea>
												</v-col>

											</v-row>
										</template>
										<template v-else-if="form.LoaiHangHoa === 'CCDC'">
											<v-row dense class="mt-1">
												<v-col cols="12">
													<span class="form-label-inline">Tên hàng hoá:</span>
													<span class="form-text">
														{{ form.MaNoiBo + ' - ' + form.TenHangHoa }}
													</span>
												</v-col>
												<v-col cols="4">
													<v-text-field :model-value="form.TenDonVi" label="Đơn vị tính"
														density="compact" variant="outlined" readonly tabindex="-1"
														class="no-focus-field" :clearable='false' />
												</v-col>
												<v-col cols="4">
													<v-text-field :model-value="form.SoLuongDat" label="Số lượng"
														density="compact" variant="outlined" readonly tabindex="-1"
														class="no-focus-field" :clearable='false' />
												</v-col>
												<v-col cols="4">
													<uc-input-price-multi v-model="form.DonGia" label="Đơn giá"
														:items="getDSGiaGanDay(form)" :rules="[rules.required]" />
												</v-col>
												<template v-if="form?.Is_CaBiet">
													<v-col cols="4">
														<v-text-field :clearable="false" type="number"
															v-model="form.ThoiGianKhauHao"
															:rules="[rules.required, rules.greaterThanZero, rules.noSpecialChar]"
															label="Thời gian khấu hao" suffix="Tháng">
														</v-text-field>
													</v-col>
													<v-col cols="4">
														<uc-date-picker label="Ngày bắt đầu bảo hành"
															v-model="form.NgayBatDauBaoHanh" :rules="[rules.required]"
															:max="form.NgayKetThucBaoHanh"></uc-date-picker>
													</v-col>
													<v-col cols="4">
														<uc-date-picker v-model="form.NgayKetThucBaoHanh"
															label="Ngày kết thúc bảo hành" :rules="[rules.required]"
															:min="form.NgayBatDauBaoHanh"></uc-date-picker>
													</v-col>
													<v-col cols='12'>
														<v-alert type="info" variant="tonal" density="compact"
															class="py-2 px-3">
															Nguyên giá tài sản: {{ (getNguyenGia(form) ?? 0).
															toLocaleString('vi-VN') }}
														</v-alert>
													</v-col>
												</template>
												<v-col cols="12" class="d-flex flex-wrap ga-2">
													<v-chip color="primary" variant="tonal">
														Thuế GTGT: {{ form.ThueGTGT ?? 0 }}%
													</v-chip>

													<v-chip color="orange" variant="tonal">
														Thuế khác: {{ form.ThueKhac ?? 0 }}%
													</v-chip>

													<v-chip color="green" variant="tonal">
														Thuế nhập khẩu: {{ form.ThueNhapKhau ?? 0 }}%
													</v-chip>
												</v-col>

												<v-col cols="6">
													<v-text-field :clearable="false" v-model="form.PhanTramKhac"
														type="number" :rules="[rules.noSpecialChar]"
														label="Thuế khác (%)">
													</v-text-field>
												</v-col>

												<v-col cols="6">
													<uc-input-price v-model="form.ChiPhiKhac" label="Chi phí khác">
													</uc-input-price>
												</v-col>
												<v-col cols="12">
													<v-textarea full-width rows="2" v-model="form.GhiChu"
														label="Ghi chú"></v-textarea>
												</v-col>
											</v-row>
										</template>
										<template v-else>
											<uc-empty text="Chưa chọn loại hàng hoá"></uc-empty>
										</template>
									</v-card-text>
								</v-card>
							</v-form>
						</v-col>

						<!-- Cá biệt  -->
						<v-col class="pt-4" cols='12' md="6">
							<div class="sticky-toolbar d-flex">
								<div class="v-toolbar-title">
									Danh sách tài sản
								</div>
							</div>
							<v-data-table :group-by="groupBy" :items="DSCaBiet" :headers="headersCaBiet"
								height="calc(100vh - 300px)" :disable-sort="true" item-key="MaCaBiet"
								:items-per-page="-1" hide-default-footer fixed-header>
								<template v-slot:group-header="{ item, columns, toggleGroup, isGroupOpen }">
									<tr>
										<td :colspan="columns.length">
											<div class="d-flex align-center">
												<v-btn :icon="isGroupOpen(item) ? '$expand' : '$next'"
													color="medium-emphasis" density="comfortable" size="small"
													variant="outlined" @click="toggleGroup(item)" />

												<span class="ms-4 font-weight-medium" style="cursor: pointer"
													@click="toggleGroup(item)">
													{{ item.items[0].raw.TenHangHoa }}
												</span>

												<v-chip class="mx-2" size="x-small">
													{{ item.items.length }}
												</v-chip>

												<v-spacer />
											</div>
										</td>
									</tr>
								</template>

								<template v-slot:item.TenHangHoa="{ item }">
									<v-tooltip :text="item.TenHangHoa" location="top">
										<template #activator="{ props }">
											<v-list-item v-bind="props" density="compact">
												<v-list-item-title>
													{{ item.TenHangHoa }}
												</v-list-item-title>
											</v-list-item>
										</template>
									</v-tooltip>
								</template>

								<template v-slot:item.SoSeries="{ item }">
									<template v-if="item?.isEdit">
										<v-text-field v-model="item.SoSeries" placeholder="Serial" density="compact"
											hide-details style="min-width: 200px" />
									</template>
									<template v-else>
										{{ item?.SoSeries }}
									</template>
								</template>

								<template v-slot:item.actions="{ item }">
									<div class="d-flex justify-end">
										<v-btn v-if="!item?.isEdit" icon="mdi-square-edit-outline"
											color="green darken-2" variant="text" density="compact" class="mx-1"
											@click="onEdit(item)" />
										<v-btn v-else icon="mdi-content-save" color="primary" variant="text"
											density="compact" class="mx-1" @click="onSave(item)" />
									</div>
								</template>

								<template #no-data>
									<uc-empty text="Chưa có tài sản" />
								</template>
							</v-data-table>
						</v-col>
					</v-row>
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
		DSNhaCungCap: Array,
		DSDiaDiem: Array,
		DSDonViTinh: Array,
		selectedItem: Object,
		closeDialog: Function,
		onReloadDSPhieuDatHang: Function,
	},
	data() {
		return {
			step: 1,
			steps: ["Bước 1: Tạo phiếu nhập", "Bước 2: Thêm hàng hoá"],
			rules: {
				required: v => !!v || 'Trường này không được để trống',
				greaterThanZero: v => v > 0 || 'Giá trị phải lớn hơn 0',
				noSpecialChar: v =>
					!v || /^[a-zA-Z0-9\s]+$/.test(v) || 'Không được chứa ký tự đặc biệt',
			},
			isValidStep: null,
			headersCaBiet: [
				{ title: '', key: 'data-table-group', width: '50px' },
				{ title: "Tên", key: "TenTaiSan" },
				{ title: "Số Serial", key: "SoSeries" },
				{ title: "", key: "actions", align: "end" }
			],
			groupBy: [{ key: 'HangHoa_Id', order: 'desc' }],

			DSLoaiHangHoa: [
				{ title: 'Nguyên vật liệu', value: 'NVL' },
				{ title: 'Công cụ dụng cụ', value: 'CCDC' }
			],
			DSTinhTrangPhieuNhap: [
				{ title: 'Chờ duyệt', value: 'CHO_DUYET' },
				{ title: 'Chờ hoá đơn', value: 'CHO_HOA_DON' }
			],
			DSTinhTrangHoaDon: [
				{ title: 'Nhận kèm hoá đơn', value: 'NHAN_KEM_HOA_DON' },
				{ title: 'Không kèm hoá đơn', value: 'KHONG_KEM_HOA_DON' },
				{ title: 'Không có hoá đơn', value: 'KHONG_CO_HOA_DON' }
			],

			files: [],
		}
	},

	computed: {
		DSCaBiet() {
			return this.selectedItem.arrayHangHoa?.flatMap(form => form.DSCaBiet || [])
		},
	},

	watch: {
		'selectedItem.arrayHangHoa': function (val) {
			if (val !== undefined) {
				this.selectedItem.arrayHangHoa?.forEach(item => {
					this.handleSoLuongHangHoa(item)
				})
			}
		}
	},

	methods: {
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

		getNguyenGia(form) {
			const DonGia = Number(form.DonGia ?? 0)
			// const ThueGTGT = Number(form.ThueGTGT ?? 0) * DonGia / 100
			const ThueKhac = Number(form.ThueKhac ?? 0) * DonGia / 100
			const ThueNhapKhau = Number(form.ThueNhapKhau ?? 0) * DonGia / 100
			const PhanTramKhac = Number(form.PhanTramKhac ?? 0) * DonGia / 100
			const ChiPhiKhac = Number(form.ChiPhiKhac ?? 0)
			const res = Number(DonGia + ThueKhac + ThueNhapKhau + PhanTramKhac + ChiPhiKhac)
			return res
		},

		handleClickPrev() {
			if (this.step > 1) this.step--
		},

		handleClickNext() {
			if (this.step === this.steps.length) {
				this.onSubmit()
			} else {
				this.step++
			}
		},

		onEdit(item) {
			item.isEdit = true
		},

		checkExistSerial(item) {
			const existItem = this.DSCaBiet.find((CaBiet) => CaBiet.SoSeries === item.SoSeries && CaBiet.MaCaBiet !== item.MaCaBiet)
			return existItem ? true : false
		},

		onSave(item) {
			const existItem = this.checkExistSerial(item)
			if (existItem) {
				showToast.info(`${item.SoSeries} bị trùng, vui lòng kiểm tra lại`)
				return
			}
			item.isEdit = false
		},
		handleSoLuongHangHoa(form) {
			if (form.Is_CaBiet) {
				let res = []
				const length = Number(form.SoLuongDat)
				if (length > 20) {
					showToast.info('Số lượng phải nhỏ hơn 20')
					return
				}
				for (let i = 0; i < length; i++) {
					res.push({
						MaCaBiet: crypto.randomUUID(),
						HangHoa_Id: form.HangHoa_Id,
						TenHangHoa: form.TenHangHoa,
						SoSeries: form.TenHangHoa + ' ' + crypto.getRandomValues(new Uint32Array(1))[0].toString(36),
						isEdit: false,
					})
				}
				form.DSCaBiet = res
			}
		},

		findFormItem(HangHoa_Id) {
			return this.selectedItem.arrayHangHoa.find((form) => form.HangHoa_Id === HangHoa_Id)
		},

		async processFile() {
			if (this.files.length < 0) return {
				status: true,
				data: null
			}
			const res = await apiFile.insertAndUpdate(
				{
					file: this.files,
					List_FileID: ''
				},
				{
					maxFileSize: 2, // MB
					showToast: true,
					validateFileSize: true
				})
			if (!res.isSuccess) return {
				status: false,
				data: null
			}
			else return {
				status: true,
				data: res.data
			}
		},

		async onSubmit() {
			const { valid } = await this.$refs.formStep2.validate();
			if (!valid) {
				showToast.info('Thông tin chưa đầy đủ hoặc chưa chính xác')
				return
			}
			let arraySoLuong = []
			let arrayCaBiet = []
			if (this.selectedItem.arrayHangHoa.length === 1 && this.selectedItem.arrayHangHoa[0].LoaiHangHoa === null) {
				showToast.info("Chưa có hàng hoá")
				return
			}
			const res = await this.processFile()
			if (res.status === false) return
			const DSFiles = res.data
			let filesID = DSFiles.map(File => File.FileID).join(',')
			this.selectedItem.arrayHangHoa.forEach((item) => {
				if (item.Is_CaBiet) {
					arrayCaBiet.push(...item.DSCaBiet)
				}
				else {
					arraySoLuong.push({
						HangHoa_Id: item.HangHoa_Id,
						DonViNhap_Id: item.DonViDat_Id,
						SoLuong: Number(item.SoLuongDat),
						DonGia: item.DonGia,
						GhiChu: item.GhiChu,
						PhanTramKhac: item.PhanTramKhac,
						ChiPhiKhac: item.ChiPhiKhac,
					})
				}
			})
			arrayCaBiet.forEach((CaBiet) => {
				const formItem = this.findFormItem(CaBiet.HangHoa_Id)

				CaBiet.DonViNhap_Id = formItem.DonViDat_Id
				CaBiet.GhiChu = formItem.GhiChu
				CaBiet.DonGia = formItem.DonGia
				CaBiet.PhanTramKhac = formItem.PhanTramKhac
				CaBiet.ChiPhiKhac = formItem.ChiPhiKhac
				CaBiet.ThoiGianKhauHao = formItem.ThoiGianKhauHao
				CaBiet.NgayBatDauBaoHanh = formItem.NgayBatDauBaoHanh
				CaBiet.NgayKetThucBaoHanh = formItem.NgayKetThucBaoHanh
			})

			const params = {
				PhieuDatHang_Id: this.selectedItem.PhieuDatHang_Id,
				TinhTrang: this.selectedItem.TinhTrangPhieuNhap,
				TinhTrangHoaDon: this.selectedItem.TinhTrangHoaDon,
				NgayMua: dayjs(this.selectedItem.NgayDatHang).format('YYYY-MM-DD'),
				MaNguoiMua: this.selectedItem.MaNguoiMua,
				NhaCungCap_Id: this.selectedItem.NhaCungCap_Id,
				SoHoaDon: this.selectedItem.SoHoaDon,
				DiaDiem_Id: this.selectedItem.DiaDiem_Id,
				FilesID: filesID,
				JsonSoLuong: JSON.stringify(arraySoLuong),
				JsonCaBiet: JSON.stringify(arrayCaBiet)
			}
			const $this = this
			apiCall("work/HH_PhieuDatHang_HoanThanh", params, (res) => {
				if (res) showToast.success("Thành công");
				$this.onReloadDSPhieuDatHang()
				$this.closeDialog()
			})
		},
		getDSGiaGanDay(form) {
			const DSGiaGanDay = this.parseGiaGanDay(form?.DanhSachGiaNhapGanNhat)
			return DSGiaGanDay
		},

		parseGiaGanDay(str) {
			try {
				return JSON.parse(str || '[]')
					.sort((a, b) => new Date(b.NgayNhap) - new Date(a.NgayNhap))
					.filter((v, i, arr) =>
						arr.findIndex(x => x.DonGia === v.DonGia) === i
					)
					.map(x => ({
						title: `${Number(x.DonGia).toLocaleString('vi-VN')} • ${dayjs(x.NgayNhap).format('DD/MM/YYYY')}`,
						value: Number(x.DonGia)
					}))
			} catch {
				return []
			}
		}
	}

}
</script>