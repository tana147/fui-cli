<template>
    <v-row v-if="recordData" class="pa-4">
        <v-col cols="12" class="pb-0">
            <div class="font-weight-bold">Phân loại theo nhóm</div>
        </v-col>

        <v-col cols="3">
            <v-select v-model="recordData.LoaiNguyenLieu" label="* Loại nguyên liệu" :items="LoaiThanhPhanList"
                item-title="text" item-value="value" density="compact" hide-details="auto" />
        </v-col>
        <v-col cols="3">
            <v-autocomplete v-model="recordData.PhanLoai_TinhChat_Id" label="* Nhóm tính chất"
                :items="danhSachNhomTinhChat" item-title="TenTinhChat" item-value="PhanLoai_TinhChat_Id"
                density="compact" hide-details="auto" />
        </v-col>
        <v-col cols="3">
            <v-autocomplete v-model="recordData.PhanLoai_NhomVatTu_Id" label="* Nhóm vật tư" :items="danhSachNhomVatTu"
                item-title="TenNhomVatTu" item-value="PhanLoai_NhomVatTu_Id" density="compact" hide-details="auto" />
        </v-col>
        <v-col cols="3">
            <v-autocomplete v-model="recordData.PhanLoai_NhomSanPham_Id" label="* Nhóm sản phẩm"
                :items="danhSachNhomSanPham" item-title="TenNhomSanPham" item-value="PhanLoai_NhomSanPham_Id"
                density="compact" hide-details="auto" />
        </v-col>

        <v-col cols="12" class="pb-0">
            <div class="font-weight-bold">Thông tin nguyên liệu</div>
        </v-col>

        <v-col cols="4">
            <v-text-field v-model="recordData.MaNoiBo" label="* Mã nội bộ" density="compact" hide-details="auto" />
        </v-col>
        <v-col cols="8">
            <v-text-field v-model="recordData.TenHangHoa" label="* Tên nguyên liệu" density="compact"
                hide-details="auto" />
        </v-col>
        <v-col cols="3">
            <v-text-field v-model="recordData.DonGia_ApDung" class="text-right-input" label="Đơn giá nhập" type="text"
                inputmode="numberic" density="compact" hide-details="auto"
                @update:model-value="formatPrice($event, 'DonGia_ApDung')" @keydown="onPrevent" />
        </v-col>
        <v-col cols="3">
            <uc-select-don-vi v-model:value="recordData.Chuan_DonViTinh_Id" label="* Đơn vị nhập"
                placeholder="Đơn vị nhập"
                :initValue="{ title: recordData.TenDonVi, value: recordData.Chuan_DonViTinh_Id }" />
        </v-col>
        <v-col cols="3">
            <v-text-field v-model="recordData.GiaBan" class="text-right-input" label="Đơn giá bán" type="text"
                inputmode="numberic" density="compact" hide-details="auto"
                @update:model-value="formatPrice($event, 'GiaBan')" @keydown="onPrevent" />
        </v-col>
        <v-col cols="3">
            <uc-select-don-vi v-model:value="recordData.Ban_DonViTinh_Id" label="Đơn vị bán" placeholder="Đơn vị bán"
                :initValue="{ title: recordData.TenDonViBan, value: recordData.Ban_DonViTinh_Id }" />
        </v-col>

        <v-col cols="12" class="pb-0">
            <div class="font-weight-bold">Thông tin bổ sung</div>
        </v-col>

        <v-col cols="3">
            <v-text-field v-model="recordData.DoUuTien" label="Độ ưu tiên" inputmode="numberic" density="compact"
                hide-details="auto" @keydown="onPrevent" />
        </v-col>
        <v-col cols="3">
            <v-select v-model="recordData.TrangThai" label="Trạng thái" :items="DsTrangThai" density="compact"
                hide-details="auto" />
        </v-col>
        <v-col cols="3">
            <v-text-field v-model="recordData.HanSuDung_Gio" label="Hạn sử dụng (giờ)" type="number" min="0" step="0.01"
                inputmode="decimal" density="compact" hide-details="auto" @keydown="preventNegative" />
        </v-col>
        <v-col cols="3">
            <v-text-field v-model="recordData.NguonGoc" label="Nguồn gốc" density="compact" hide-details="auto" />
        </v-col>
        <v-col cols="3">
            <v-text-field v-model="recordData.MauSac" label="Màu sắc" density="compact" hide-details="auto" />
        </v-col>
        <v-col cols="3">
            <v-text-field v-model="recordData.HinhThai" label="Hình thái" density="compact" hide-details="auto" />
        </v-col>
        <v-col cols="3">
            <v-text-field v-model="recordData.ThuongHieu" label="Thương hiệu" density="compact" hide-details="auto" />
        </v-col>
        <v-col cols="3">
            <v-text-field v-model="recordData.BaoQuan_NhietDo" label="Nhiệt độ bảo quản" type="number" step="0.01"
                inputmode="decimal" density="compact" hide-details="auto"
                @update:model-value="checkMinValue($event, 'BaoQuan_NhietDo')" />
        </v-col>
        <v-col cols="3">
            <v-text-field v-model="recordData.DacTinh" label="Đặc tính" density="compact" hide-details="auto" />
        </v-col>
        <v-col cols="3">
            <v-text-field v-model="recordData.BaoQuan_ThietBi" label="Thiết bị bảo quản" density="compact"
                hide-details="auto" />
        </v-col>
        <v-col cols="3">
            <v-text-field v-model="recordData.BaoQuan_NoiBaoQuan" label="Nơi bảo quản" density="compact"
                hide-details="auto" />
        </v-col>
        <v-col cols="12">
            <v-textarea v-model="recordData.MoTa" label="Mô tả" auto-grow :rows="3" no-resize density="compact"
                hide-details="auto" />
        </v-col>
        <v-col cols="12">
            <v-checkbox v-model="recordData.Is_TamKhoa" label="Tạm khóa" color="primary" density="compact"
                hide-details="auto" />
        </v-col>
    </v-row>
</template>

<script>
    export default {
		props: {
			recordData: { type: Object, default: null },
			LoaiThanhPhanList: { type: Array, default: () => [] },
			DsTrangThai: { type: Array, default: () => [] },
			onLoadNhomTinhChat: { type: Function, default: null },
			onLoadNhomVatTu: { type: Function, default: null },
			onLoadNhomTenSanPham: { type: Function, default: null },
		},
		emits: ['saved'],
		data() {
			return {
				countSelect: 0,
				danhSachNhomTinhChat: [],
				danhSachNhomVatTu: [],
				danhSachNhomSanPham: [],
			}
		},
		watch: {
			recordData: {
				immediate: true,
				async handler(val) {
					if (!val?.HangHoa_Id) {
						this.danhSachNhomTinhChat = []
						this.danhSachNhomVatTu = []
						this.danhSachNhomSanPham = []
						this.countSelect = 0
						return
					}
					await this.initData()
				},
			},
			async 'recordData.PhanLoai_TinhChat_Id'(val) {
				if (!this.recordData || val === null || val === undefined || !this.onLoadNhomVatTu) return
				if (this.countSelect > 0) {
					this.recordData.PhanLoai_NhomVatTu_Id = null
					this.recordData.PhanLoai_NhomSanPham_Id = 0
				}
				this.danhSachNhomVatTu = await this.onLoadNhomVatTu(val)
				this.countSelect += 1
			},
		},
		methods: {
			async initData() {
				if (this.onLoadNhomTinhChat) {
					this.danhSachNhomTinhChat = await this.onLoadNhomTinhChat()
				}
				if (this.onLoadNhomTenSanPham) {
					this.danhSachNhomSanPham = [
						{ PhanLoai_NhomSanPham_Id: 0, TenNhomSanPham: '- Chưa xác định -' },
						...(await this.onLoadNhomTenSanPham()),
					]
				}
				if (this.recordData?.PhanLoai_TinhChat_Id && this.onLoadNhomVatTu) {
					this.danhSachNhomVatTu = await this.onLoadNhomVatTu(this.recordData.PhanLoai_TinhChat_Id)
				}
			},
			save() {
				if (!this.recordData) return
				const requiredFields = [
					{ key: 'Chuan_DonViTinh_Id', label: 'Đơn vị tính chuẩn' },
					{ key: 'LoaiNguyenLieu', label: 'Loại nguyên liệu' },
					{ key: 'MaNoiBo', label: 'Mã nội bộ' },
					{ key: 'TenHangHoa', label: 'Tên hàng hóa' },
				]

				for (const field of requiredFields) {
					const value = this.recordData[field.key]
					if (value === null || value === '' || value === undefined) {
						showToast.error(`Vui lòng nhập ${field.label}`)
						return
					}
				}

				apiCall(
					'/work/MT_NguyenLieu_Update',
					{
						HangHoa_Id: this.recordData.HangHoa_Id,
						EORDER_SanPham_Id: 0,
						PhanLoai_TinhChat_Id: this.recordData.PhanLoai_TinhChat_Id,
						PhanLoai_NhomVatTu_Id: this.recordData.PhanLoai_NhomVatTu_Id,
						PhanLoai_NhomSanPham_Id: this.recordData.PhanLoai_NhomSanPham_Id,
						Chuan_DonViTinh_Id: this.recordData.Chuan_DonViTinh_Id,
						Ban_DonViTinh_Id: this.recordData.Ban_DonViTinh_Id ? this.recordData.Ban_DonViTinh_Id : '',
						LoaiNguyenLieu: this.recordData.LoaiNguyenLieu,
						TrangThai: this.recordData.TrangThai,
						MaNoiBo: this.recordData.MaNoiBo !== null && this.recordData.MaNoiBo !== '' ? this.recordData.MaNoiBo.trim() : this.recordData.MaNoiBo,
						TenHangHoa: this.recordData.TenHangHoa !== null && this.recordData.TenHangHoa !== '' ? this.recordData.TenHangHoa.trim() : this.recordData.TenHangHoa,
						ThuongHieu: this.recordData.ThuongHieu,
						NguonGoc: this.recordData.NguonGoc,
						MauSac: this.recordData.MauSac,
						HinhThai: this.recordData.HinhThai,
						DacTinh: this.recordData.DacTinh,
						MoTa: this.recordData.MoTa,
						BaoQuan_NoiBaoQuan: this.recordData.BaoQuan_NoiBaoQuan,
						BaoQuan_NhietDo: this.recordData.BaoQuan_NhietDo,
						BaoQuan_ThietBi: this.recordData.BaoQuan_ThietBi,
						DoUuTien: this.recordData.DoUuTien ? this.recordData.DoUuTien : '',
						HanSuDung_Gio: this.recordData.HanSuDung_Gio ? this.recordData.HanSuDung_Gio : null,
						DonGia_ApDung: this.recordData.DonGia_ApDung ? this.recordData.DonGia_ApDung.replace(/\./g, '').replace(/\,/g, '.') : 0,
						GiaBan: this.recordData.GiaBan ? this.recordData.GiaBan.replace(/\./g, '').replace(/\,/g, '.') : 0,
						Is_TamKhoa: this.recordData.Is_TamKhoa ? 1 : 0,
					},
					() => {
						showToast.success('Cập nhật thành công')
						this.$emit('saved')
					},
					(error) => {
						showToast.error(error.responseJSON?.Message || 'Có lỗi xảy ra')
					},
				)
			},
			onPrevent(e) {
				this.preventNegative(e)
				this.onlyNumber(e)
			},
			preventNegative(e) {
				if (e.key === '-' || e.key === 'e' || e.key === '+') {
					e.preventDefault()
				}
			},
			checkMinValue(val, name) {
				const num = Number(val)
				if (!isNaN(num) && num < -273) {
					this.recordData[name] = -273
				}
			},
			onlyNumber(e) {
				if (e.ctrlKey) {
					const allowCtrlKeys = ['a', 'c', 'v', 'x']
					if (allowCtrlKeys.includes(e.key.toLowerCase())) return
				}
				const allowKeys = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Tab']
				if (allowKeys.includes(e.key)) return
				const value = e.target.value
				if (/^\d$/.test(e.key)) return
				if (e.key === ',') {
					if (value.includes(',')) e.preventDefault()
					return
				}
				e.preventDefault()
			},
			formatPrice(val, name) {
				if (val === null || val === '') {
					this.recordData[name] = val
					return
				}
				const raw = String(val).replace(/\./g, '')
				const number = Number(raw)
				if (isNaN(number)) return
				this.recordData[name] = number.toLocaleString('vi-VN')
			},
		},
	}
</script>