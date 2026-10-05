<template>
	<v-dialog v-model="isShow" width="1200">
		<v-card rounded="lg">
			<v-toolbar>
				<v-toolbar-title class="text-primary d-flex align-center ga-2">
					Cập nhật phiếu nhập
					<v-chip size="small" color="grey" variant="tonal">{{ selectedItem.TenDiaDiem }}</v-chip>
					<v-chip v-if="selectedItem.TenNhaCungCap" size="small" color="primary" variant="tonal">
						{{ selectedItem.TenNhaCungCap }}
					</v-chip>
					<v-chip v-if="selectedItem.NgayMua" size="small" color="grey" variant="outlined">
						{{ formatLocalDate(new Date(selectedItem.NgayMua)) }}
					</v-chip>
				</v-toolbar-title>
				<v-btn icon="mdi-close" @click="closeDialog"></v-btn>
			</v-toolbar>
			<v-divider></v-divider>
			<v-card-text>
				<v-form ref="form">
					<v-row dense>
						<!-- Tạm ẩn cho phép sửa ngày mua, do ảnh hưởng FIFO chưa có hướng xử lí -->
						<v-col cols='12' md="3">
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
												<span v-else class="text-caption font-weight-medium text-white">
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
												<span v-else class="text-caption font-weight-medium text-white">
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
						<v-col cols='12' md="3">
							<v-select color="primary" v-model="selectedItem.TinhTrang" density="compact"
								:items="DSTinhTrangPhieuNhap" :rules="[rules.required]" item-value="value"
								item-title="title" label="Tình trạng">
							</v-select>
						</v-col>
						<v-col cols='12' md="3">
							<v-text-field color="primary" v-model="selectedItem.SoHoaDon"
								:rules="[rules.required, rules.noSpecialChar]" density="compact" label="Số hóa đơn">
							</v-text-field>
						</v-col>
						<v-col cols='12' md="3">
							<v-select color="primary" v-model="selectedItem.TinhTrangHoaDon" density="compact"
								:items="DSTinhTrangHoaDon" :rules="[rules.required]" item-value="value"
								item-title="title" label="Tình trạng hoá đơn">
							</v-select>
						</v-col>
					</v-row>
					<v-row dense>
						<v-col cols='12' md="4">
							<v-select color="primary" v-model="selectedItem.NhaCungCap_Id" density="compact"
								:items="DSNhaCungCap" :rules="[rules.required]" item-value="NhaCungCap_Id"
								item-title="TenNhaCungCap" label="Nhà cung cấp">
							</v-select>
						</v-col>
						<v-col cols="12" md="4">
							<uc-input-file-multi v-model='newFiles' :multiple="true" :show-size="true">
							</uc-input-file-multi>
						</v-col>
						<v-col cols="auto">
							<uc-file-chip :items='selectedItem.DSFile' :closable="true" @close="handleDeleteFile">
							</uc-file-chip>
						</v-col>
					</v-row>

					<v-divider class="mb-2"></v-divider>
					<div class="text-subtitle-2 font-weight-bold mb-2 d-flex align-center ga-2">
						DANH SÁCH HÀNG HOÁ
						<v-chip size="x-small" color="primary" variant="tonal">
							{{ selectedItem.arrayHangHoa?.length ?? 0 }}
						</v-chip>
					</div>
					<v-data-table :headers="headerHangHoa" :items="selectedItem.arrayHangHoa" density="compact"
						fixed-header :items-per-page="-1" hide-default-footer height="320">
						<template #item.SoLuongNhap="{ item }">
							<v-text-field v-model="item.SoLuongNhap" variant="underlined" type="number" reverse
								:rules="[rules.required, rules.greaterThanZero]" step="0.01"
								@blur="item.SoLuongNhap = format2(item.SoLuongNhap)">
							</v-text-field>
						</template>
						<template #item.DonGia="{ item }">
							<uc-input-price v-model="item.DonGia" variant='underlined' :reverse='true'
								:rules="[rules.required]"></uc-input-price>
						</template>
					</v-data-table>

					<v-card-actions class="mt-1 pa-0">
						<v-spacer></v-spacer>
						<v-btn color="primary" @click="onSubmit" variant="flat">
							Cập nhật
						</v-btn>
					</v-card-actions>
				</v-form>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
	props: {
		isShow: Boolean,
		loadDSPhieuNhap: Function,
		DSNhanVien: Array,
		DSNhaCungCap: Array,
		DSDiaDiem: Array,
		selectedItem: Object,
	},
	emits: ['update:isShow'],
	data() {
		return {
			rules: {
				required: v => !!v || 'Trường này không được để trống',
				greaterThanZero: v => v > 0 || 'Giá trị phải lớn hơn 0',
				noSpecialChar: v =>
					/^[a-zA-Z0-9\s]+$/.test(v) || 'Không được chứa ký tự đặc biệt',
			},
			DSTinhTrangPhieuNhap: [
				{ title: 'Chờ hoá đơn', value: 'CHO_HOA_DON' },
				{ title: 'Hoàn thành', value: 'HOAN_THANH' },
			],
			DSTinhTrangHoaDon: [
				{ title: 'Nhận kèm hoá đơn', value: 'NHAN_KEM_HOA_DON' },
				{ title: 'Không kèm hoá đơn', value: 'KHONG_KEM_HOA_DON' },
				{ title: 'Không có hoá đơn', value: 'KHONG_CO_HOA_DON' },
			],
			newFiles: [],
			headerHangHoa: [
				{ title: "Tên hàng hoá", key: "TenHangHoa" },
				{ title: "Số lượng", key: "SoLuongNhap", width: '130px', align: 'end' },
				{ title: "ĐVT", key: "TenDonVi", align: 'start' },
				{ title: "Đơn giá", key: "DonGia", width: '200px', align: 'end' },
			],
		}
	},
	methods: {
		closeDialog() {
			this.$refs.form?.reset()
			this.$refs.form?.resetValidation()
			this.$emit('update:isShow', false)
			this.newFiles = []
		},
		formatLocalDate(date) {
			const y = date.getFullYear();
			const m = String(date.getMonth() + 1).padStart(2, "0");
			const d = String(date.getDate()).padStart(2, "0");
			return `${y}-${m}-${d}`;
		},
		getMonthRange(dateStr) {
			const d = new Date(dateStr);

			const minDate = new Date(d.getFullYear(), d.getMonth(), 1);
			const maxDate = new Date(d.getFullYear(), d.getMonth() + 1, 0);

			return {
				min: this.formatLocalDate(minDate),
				max: this.formatLocalDate(maxDate)
			};
		},

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

		async deleteFileByListID(ListIDs) {
			const data = await apiCallPromise('work/HH_FileData_Del_ByListFileID', {
				ListIDs: ListIDs
			})
			return data
		},

		async processFile() {
			const DSFileDelete = this.selectedItem.DSFile.filter((File) => File.Is_Delete === true)
			const DSFileSave = this.selectedItem.DSFile.filter((File) => File.Is_Delete !== true)
			// Nếu không có sự thay đổi file
			if (DSFileDelete.length === 0 && this.newFiles.length === 0) {
				return this.selectedItem.DSFile.map(f => f.FileID).join(',')
			}
			let DSNewFile = []
			if (DSFileDelete.length > this.newFiles.length) {
				// Xoá file
				const SoFileChenhLech = DSFileDelete.length - this.newFiles.length
				const DSFileXoa = DSFileDelete.slice(-SoFileChenhLech)
				const ListIDs = DSFileXoa.map(File => File.FileID).join(',')
				await this.deleteFileByListID(ListIDs)
			} else {
				const replaceFileIds = DSFileDelete.map(File => File.FileID).join(',')
				const res = await apiFile.insertAndUpdate(
					{
						file: [...this.newFiles],
						List_FileID: replaceFileIds
					},
					{
						maxFileSize: 2,
						showToast: true,
						validateFileSize: true
					})
				if (!res.isSuccess) return
				DSNewFile = res.data
			}

			const bothSaveAndNew = [...DSFileSave, ...DSNewFile]
			let filesID = bothSaveAndNew.map(File => File.FileID).join(',')
			return filesID
		},

		handleDeleteFile(item) {
			this.selectedItem.DSFile[item.index].Is_Delete = true
		},

		async onSubmit() {
			const { valid } = await this.$refs.form.validate();
			if (!valid) {
				showToast.info('Thông tin chưa đầy đủ hoặc chưa chính xác')
				return
			}
			const filesID = await this.processFile()
			if (filesID === undefined) return
			let tempArraySoLuong = []
			this.selectedItem.arrayHangHoa.forEach((HangHoa) => {
				const tempItem = {
					PhieuNhap_ChiTiet_Id: HangHoa.PhieuNhap_ChiTiet_Id,
					SoLuongNhap: HangHoa.SoLuongNhap,
					DonGia: HangHoa.DonGia,
				}
				tempArraySoLuong.push(tempItem)
			})
			const JsonSoLuong = JSON.stringify(tempArraySoLuong ?? '[]')
			const params = {
				PhieuNhap_Id: this.selectedItem.PhieuNhap_Id,
				NgayMua: this.selectedItem.NgayMua,
				MaNguoiMua: this.selectedItem.MaNguoiMua,
				TinhTrang: this.selectedItem.TinhTrang,
				TinhTrangHoaDon: this.selectedItem.TinhTrangHoaDon,
				SoHoaDon: this.selectedItem.SoHoaDon,
				NhaCungCap_Id: this.selectedItem.NhaCungCap_Id,
				FilesID: filesID,
				JsonSoLuong: JsonSoLuong
			}
			apiCall("work/HH_PhieuNhap_Update", params, (res) => {
				if (res) showToast.success("Thành công");
				this.closeDialog()
				this.loadDSPhieuNhap()
			})
		},

	},
}
</script>