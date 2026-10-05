<template>
	<v-dialog v-model="isShow" persistent width="1000">
		<v-card>
			<v-toolbar density="compact" elevation="0" class="mt-2">
				<v-toolbar-title class="mb-2">
					Luân chuyển
					<div class="text-subtitle-2 ">
						Địa điểm đích: {{ itemTransfer.TenDiaDiem }}
					</div>
				</v-toolbar-title>
				<v-spacer />
				<v-btn size="small" variant="text" icon="mdi-close" @click="closeDialog" />
			</v-toolbar>
			<v-divider></v-divider>
			<v-card-text class="pt-2">
				<v-form ref="form">
					<v-row dense>
						<v-col cols="10">
							<v-autocomplete color="primary" v-model="DiaDiemHienTai_Id" density="compact"
								:items="DSDiaDiem" :rules="[rules.required]" item-value="DiaDiem_Id"
								item-title="TenDiaDiem" label="Địa điểm xuất">
							</v-autocomplete>
						</v-col>
						<v-col cols="auto">
							<v-btn prepend-icon="mdi-magnify" @click="onSearch" color="default" variant='tonal'>Tìm
							</v-btn>
						</v-col>
					</v-row>
					<!-- SO LUONG -->
					<v-data-table v-if="itemTransfer.arraySoLuong.length > 0" :items="itemTransfer.arraySoLuong"
						:headers="headerHangHoaSoLuong" fixed-header density="compact" :disable-sort="true"
						:items-per-page="-1" hide-default-footer>
						<template #top>
							<v-toolbar density="compact" elevation="0">
								<v-toolbar-title class="text-subtitle-1 font-weight-bold">
									Danh sách hàng hoá
								</v-toolbar-title>
							</v-toolbar>
						</template>
						<template #item.SoLuong="{ item }">
							<v-text-field v-model="item.SoLuong" density="compact" variant="underlined" type="number"
								hide-details reverse :rules="[maxRule(item)]" step="0.01"
								@blur="item.SoLuong = format2(item.SoLuong)">
								<template #append-inner>
									<span class="text-grey" style="min-width: 100px;">
										{{ '/' + (item.SoLuongKho ?? '0') + ' ' + item.TenDonVi }}
									</span>
								</template>
							</v-text-field>
						</template>
					</v-data-table>

					<!-- CA BIET -->
					<v-data-table v-if="itemTransfer.arrayCaBiet.length > 0" :items="itemTransfer.arrayCaBiet"
						:headers="headerHangHoaCaBiet" fixed-header density="compact" :disable-sort="true"
						:items-per-page="-1" hide-default-footer>
						<template #top>
							<v-toolbar density="compact" elevation="0">
								<v-toolbar-title class="text-subtitle-1 font-weight-bold">
									Danh sách tài sản
								</v-toolbar-title>
							</v-toolbar>
						</template>
						<template #item.CaBietChuyen="{ item }">
							<v-select v-model="item.CaBietChuyen" :items="item.DSCaBiet" item-title="title"
								:rules="[rules.required]" item-value="value" density="compact" hide-details
								variant="underlined" />
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
		DSDiaDiem: Array,
		DSKhuVuc: Array,
		itemTransfer: Object,
	},
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
			headerHangHoaSoLuong: [
				{ title: "Tên hàng hoá", key: "TenHangHoa", align: 'start', },
				{ title: "Số lượng chuyển", key: "SoLuong", align: 'start', width: 500 },
			],
			headerHangHoaCaBiet: [
				{ title: "Tên hàng hoá", key: "TenHangHoa", align: 'start' },
				{ title: "Tài sản chuyển", key: "CaBietChuyen", align: 'start', width: 500 },
			],
			DiaDiemHienTai_Id: null,
			DSHangHoaLuanChuyen: []
		}
	},
	mounted() {

	},
	computed: {
		getTenDiaDiem() {
			const res = this.DSDiaDiem.find((DiaDiem) => DiaDiem.DiaDiem_Id === this.DiaDiemHienTai_Id)
			return res?.TenDiaDiem
		},
	},
	watch: {
	},
	methods: {
		maxRule(item) {
			return v => {
				const maxValue = item.SoLuongKho
				return (Number(v) > 0 && Number(v) <= maxValue)
					|| `Tối đa ${maxValue}`
			}
		},

		format2(v) {
			const n = parseFloat(v)
			if (isNaN(n)) return ''
			return (Math.round(n * 100) / 100).toFixed(2)
		},

		async onSearch() {
			if (this.DiaDiemHienTai_Id === null) return showToast.info('Chưa chọn địa điểm xuất hàng')
			const params = {
				DiaDiem_Id: this.DiaDiemHienTai_Id
			}
			this.resetValue()
			let res = await apiCallPromise('work/HH_HangHoa_Select_ByDiaDiem_Id', params)
			let data = [...res[0]]
			data.forEach((item) => {
				const dsCaBiet = JSON.parse(item.DanhSachCaBiet ?? '[]')
				const dsSoLuong = JSON.parse(item.DanhSachSoLuong ?? '[]')
				item.DSCaBiet = dsCaBiet
				item.DSSoLuong = dsSoLuong
			})
			this.DSHangHoaLuanChuyen = data
			this.itemTransfer.arrayCaBiet.forEach((CaBiet) => {
				const res = this.DSHangHoaLuanChuyen.find(HangHoa => HangHoa.HangHoa_Id === CaBiet.HangHoa_Id)
				const DSCaBiet = res?.DSCaBiet
				CaBiet.DSCaBiet = DSCaBiet?.filter(CaBiet => CaBiet.KhuVuc_Id === 0).map(CaBiet => ({
					value: CaBiet.CaBiet_Id,
					title: `${CaBiet.SoSeries} - ${this.mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrang].text}`
				}))
			})
			this.itemTransfer.arraySoLuong.forEach((SoLuong) => {
				const res = this.DSHangHoaLuanChuyen.find(HangHoa => HangHoa.HangHoa_Id === SoLuong.HangHoa_Id)
				const DSSoLuong = res?.DSSoLuong
				const SoLuongKho = DSSoLuong?.find(KhuVuc => KhuVuc.KhuVuc_Id === 0)?.SoLuong
				SoLuong.SoLuongKho = SoLuongKho
			})
		},

		closeDialog() {
			this.DiaDiemHienTai_Id = null
			this.DSHangHoaLuanChuyen = null
			this.resetValue()
			this.$emit('update:isShow', false)
		},
		resetValue() {
			this.itemTransfer.arrayCaBiet.forEach((CaBiet) => {
				CaBiet.DSCaBiet = []
				CaBiet.CaBietChuyen = null
			})
			this.itemTransfer.arraySoLuong.forEach((SoLuong) => {
				SoLuong.SoLuongKho = null
				SoLuong.SoLuong = null
			})
		},

		async onSubmit() {
			const { valid } = await this.$refs.form.validate();
			if (!valid) {
				showToast.info('Thông tin chưa đầy đủ hoặc chưa chính xác')
				return
			}
			let tempArrayXuLy = []
			let tempArraySoLuong = []
			this.itemTransfer.arraySoLuong.forEach((item) => {
				const tempItem = {
					HangHoa_Id: item.HangHoa_Id,
					DonViChuyen_Id: item.Chuan_DonViTinh_Id,
					SoLuong: item.SoLuong,
					KhuVucHienTai_Id: 0,
					KhuVucDen_Id: 0
				}
				const tempItemXuLy = {
					DeXuat_MuaHang_ChiTiet_Id: item.DeXuat_MuaHang_ChiTiet_Id,
					SoLuong: item.SoLuong,
					XuLy: 'LUAN_CHUYEN',
				}
				tempArraySoLuong.push(tempItem)
				tempArrayXuLy.push(tempItemXuLy)
			})

			let tempArrayCaBiet = []
			this.itemTransfer.arrayCaBiet.forEach((item) => {
				const tempItem = {
					CaBiet_Id: item.CaBietChuyen,
					KhuVucHienTai_Id: 0,
					KhuVucDen_Id: 0
				}
				const tempItemXuLy = {
					DeXuat_MuaHang_ChiTiet_Id: item.DeXuat_MuaHang_ChiTiet_Id,
					SoLuong: 1,
					XuLy: 'LUAN_CHUYEN',
				}
				tempArrayCaBiet.push(tempItem)
				tempArrayXuLy.push(tempItemXuLy)
			})

			showConfirm(
				`Việc luân chuyển này ảnh hưởng trực tiếp đến tồn kho tại 
					<strong>
					${this.getTenDiaDiem}
					</strong>
					</br>Bạn có chắc chắn muốn tiếp tục?`,
				async () => {
					const params_LuanChuyen = {
						DiaDiemHienTai_Id: this.DiaDiemHienTai_Id,
						DiaDiemDen_Id: this.itemTransfer.DiaDiem_Id,
						JsonSoLuong: tempArraySoLuong?.length > 0 ? JSON.stringify(tempArraySoLuong) : null,
						JsonCaBiet: tempArrayCaBiet?.length > 0 ? JSON.stringify(tempArrayCaBiet) : null,
					}
					const res = await apiCallPromise('work/HH_Kho_LuanChuyen', params_LuanChuyen)
					if (res) {
						const params_Xuy = {
							DataJSON: JSON.stringify(tempArrayXuLy)
						}
						const res_1 = await apiCallPromise('work/HH_DeXuat_MuaHang_Update_ChiTiet_XuLy', params_Xuy)
						if (res_1) {
							showToast.success('Thành công')
							this.closeDialog()
							this.$emit('load-data-chua-xu-ly')
						}
					}
				}
			)
		}
	},
}

</script>