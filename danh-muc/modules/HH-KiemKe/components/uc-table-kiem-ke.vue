<template>
	<uc-filter-bar :DiaDiem_Id="DiaDiem_Id" :PhieuKiemKe_Id="PhieuKiemKe_Id" :DSDiaDiemTatCa="DSDiaDiemTatCa"
		:DSPhieuKiemKe="DSPhieuKiemKe" :isKiemKe="isKiemKe" :buttonKiemKe="buttonKiemKe"
		:isShowButtonKiemKe="isShowButtonKiemKe" :isDisabledKiemKe="PhieuKiemKe_Id === null || DSHangHoa.length === 0"
		:PhanTramHoanThanh="PhanTramHoanThanh" :progressColor="progressColor" :textColor="textColor"
		:hasData="DSHangHoa.length > 0" :totalItem="totalItem" :totalDaKiemKe="totalDaKiemKe"
		:tenPhieuKiemKe="tenPhieuKiemKe" :isMobile="isMobile" :searchText="searchText"
		@update:DiaDiem_Id="handleSelectedDiaDiem" @update:PhieuKiemKe_Id="PhieuKiemKe_Id = $event"
		@update:searchText="searchText = $event" @search="onGetDataKiemKe" @kiem-ke-click="handleButtonKiemKeClick" />

	<v-form ref="form">
		<uc-kiem-ke-desktop v-if="!isMobile" :DSHangHoa="filteredDSHangHoa" :isKiemKe="isKiemKe" :DSDiaDiem="DSDiaDiem"
			:DSKhuVucKho="DSKhuVucKho" :DSDonViTinh="DSDonViTinh" :mapDiaDiem="mapDiaDiem" :mapKhuVuc="mapKhuVuc"
			:mapDonViTinh="mapDonViTinh" :tableHeight="desktopTableHeight" @select-don-vi-tinh="handleSelectedDonViTinh"
			@check-kiem-ke="handleCheckKiemKeSoLuong" />
		<uc-kiem-ke-mobile v-else :DSHangHoa="filteredDSHangHoa" :isKiemKe="isKiemKe" :DSDiaDiem="DSDiaDiem"
			:DSKhuVucKho="DSKhuVucKho" :DSDonViTinh="DSDonViTinh" :mapDiaDiem="mapDiaDiem" :mapKhuVuc="mapKhuVuc"
			:mapDonViTinh="mapDonViTinh" :listHeight="mobileListHeight" @select-don-vi-tinh="handleSelectedDonViTinh"
			@check-kiem-ke="handleCheckKiemKeSoLuong" />
	</v-form>

	<div v-if="isMobile && isShowButtonKiemKe && DSHangHoa.length > 0" class="kiem-ke-bottom-bar">
		<v-btn :prepend-icon="buttonKiemKe.icon" @click="handleButtonKiemKeClick"
			:disabled="PhieuKiemKe_Id === null || DSHangHoa.length === 0" color="primary" variant="flat" block>
			{{ buttonKiemKe.title }}
		</v-btn>
	</div>
</template>

<script>
	export default {
		name: 'uc-table-kiem-ke',
		props: {
			DSPhieuKiemKe: Array,
			DSDiaDiem: Array,
			DSKhuVuc: Array,
			DSDonViTinh: Array,
			DiaDiem_Id: Number,
		},
		emits: ['update:DiaDiem_Id', 'onReload'],
		data() {
			return {
				expanded: null,
				openListGroup: null,
				totalItem: 0,
				DSHangHoa: [],
				PhieuKiemKe_Id: null,
				localPhieuKiemKe_Id: null,
				isKiemKe: false,
				searchText: '',
			}
		},
		computed: {
			filteredDSHangHoa() {
				if (!this.searchText) return this.DSHangHoa
				const keyword = this.searchText.toLowerCase().trim()
				if (!keyword) return this.DSHangHoa
				return this.DSHangHoa.filter(item =>
					item.TenHangHoa?.toLowerCase().includes(keyword)
				)
			},
			DSDiaDiemTatCa() {
				return [{ DiaDiem_Id: 0, TenDiaDiem: 'Tất cả' }, ...this.DSDiaDiem]
			},
			DSKhuVucKho() {
				return [{ KhuVuc_Id: 0, TenKhuVuc: 'Kho' }, ...this.DSKhuVuc]
			},
			mapDiaDiem() {
				const m = {}
				this.DSDiaDiem.forEach(x => { m[x.DiaDiem_Id] = x.TenDiaDiem })
				return m
			},
			mapKhuVuc() {
				const m = {}
				this.DSKhuVucKho.forEach(x => { m[x.KhuVuc_Id] = x.TenKhuVuc })
				return m
			},
			mapDonViTinh() {
				const m = {}
				this.DSDonViTinh.forEach(x => { m[x.DonViTinh_Id] = x.TenDonVi })
				return m
			},
			getTinhTrangPhieuKiemKe() {
				const res = this.DSPhieuKiemKe.find(x => x.PhieuKiemKe_Id === this.localPhieuKiemKe_Id)
				return res?.TinhTrang ?? null
			},
			isLayDuLieuLanDau() {
				const res = this.DSPhieuKiemKe.find(x => x.PhieuKiemKe_Id === this.localPhieuKiemKe_Id)
				return res?.Is_DaLayDuLieu ?? null
			},
			isShowButtonKiemKe() {
				return ['TAO_MOI', 'LUU_TAM'].includes(this.getTinhTrangPhieuKiemKe)
			},
			tenPhieuKiemKe() {
				const res = this.DSPhieuKiemKe.find(x => x.PhieuKiemKe_Id === this.localPhieuKiemKe_Id)
				return res?.TenPhieuKiemKe ?? ''
			},
			buttonKiemKe() {
				if (!this.isKiemKe) return { title: 'Tiến hành kiểm kê', icon: 'mdi-clipboard-list-outline' }
				if (this.PhanTramHoanThanh === 100) return { title: 'Hoàn thành', icon: 'mdi-check-circle-outline' }
				return { title: 'Lưu tạm', icon: 'mdi-content-save-outline' }
			},
			totalDaKiemKe() {
				let res = 0
				this.DSHangHoa.forEach(HangHoa => {
					if (HangHoa.Is_CaBiet) {
						HangHoa.DSCaBiet?.forEach(cb => { if (cb.TinhTrangKiemKe) res++ })
					} else {
						HangHoa.DSSoLuong?.forEach(sl => { if (sl.TinhTrangKiemKe) res++ })
					}
				})
				return res
			},
			PhanTramHoanThanh() {
				if (this.totalItem === 0) return 0
				return (this.totalDaKiemKe * 100 / this.totalItem)
			},
			progressColor() {
				if (this.PhanTramHoanThanh < 50) return 'red'
				if (this.PhanTramHoanThanh < 80) return 'orange'
				return 'green'
			},
			textColor() {
				return this.PhanTramHoanThanh < 50 ? 'text-black' : 'text-white'
			},
			isMobile() {
				return this.$vuetify.display.smAndDown
			},
			desktopTableHeight() {
				return this.DSHangHoa.length > 0 ? 'calc(100vh - 289px)' : 'calc(100vh - 164px)'
			},
			mobileListHeight() {
				return this.isKiemKe ? 'calc(100dvh - 360px)' : 'calc(100dvh - 310px)'
			},
		},
		watch: {
			DiaDiem_Id() {
				this.PhieuKiemKe_Id = null
			}
		},
		methods: {
			reset() {
				this.DSHangHoa = []
				this.PhieuKiemKe_Id = null
				this.isKiemKe = false
				this.searchText = ''
			},
	
			handleSelectedDiaDiem(value) {
				this.$emit('update:DiaDiem_Id', value)
				this.reset()
				this.$emit('onReload')
			},
	
			handleSelectedDonViTinh(item) {
				if (item.DonViKiemKe_Id === item.Chuan_DonViTinh_Id) {
					item.TongSauQuyDoi = item.SoLuong
					return
				}
				const QuyDoi = item.DSDonViTinh.find(x => x.DonViTinh_Id === item.DonViKiemKe_Id)
				const HeSo = QuyDoi?.HeSo ?? 1
				item.TongSauQuyDoi = Number((item.SoLuong / HeSo).toFixed(2))
				item.SoLuongKho = item.TongSauQuyDoi
			},
	
			handleCheckKiemKeSoLuong(item) {
				if (!item.TinhTrangKiemKe) return
				if (item.SoLuongThucTe === undefined) item.SoLuongThucTe = item.TongSauQuyDoi
			},
	
			async onGetDataKiemKe() {
				if (this.PhieuKiemKe_Id === null) {
					showToast.info('Vui lòng chọn phiếu kiểm kê')
					return
				}
				this.localPhieuKiemKe_Id = this.PhieuKiemKe_Id
				loadingPage.show()
				try {
					const data = await apiCallPromise('work/HH_PhieuKiemKe_Select_ById', {
						PhieuKiemKe_Id: this.PhieuKiemKe_Id
					})
					this.parseAndSetData(data)
				} catch (e) {
					showToast.error('Lỗi khi tải dữ liệu kiểm kê')
				} finally {
					loadingPage.hide()
				}
			},
	
			parseAndSetData(data) {
				let expandedIds = []
				let totalItem = 0
				const phieu = this.DSPhieuKiemKe.find(x => x.PhieuKiemKe_Id === this.localPhieuKiemKe_Id)
				const trangThai = phieu?.TinhTrang
	
				data.forEach(HangHoa => {
					if (HangHoa.Is_CaBiet) {
						const DSCaBiet = JSON.parse(HangHoa?.DanhSachCaBiet || '[]')
						DSCaBiet.forEach(CaBiet => {
							CaBiet.DonViTinh = HangHoa.TenDonVi
							CaBiet.SoLuong = 1
							CaBiet.Tong = 1
							CaBiet.DonViKiemKe_Id = HangHoa.Chuan_DonViTinh_Id
							if (trangThai === 'TAO_MOI') {
								CaBiet.DiaDiemThucTe_Id = CaBiet.DiaDiemHienTai_Id
								CaBiet.KhuVucThucTe_Id = CaBiet.KhuVucHienTai_Id
								CaBiet.TinhTrangThucTe = CaBiet.TinhTrangHienTai
							}
						})
						totalItem += DSCaBiet.length
						HangHoa.DSCaBiet = DSCaBiet
					} else {
						let DSDonViTinh = JSON.parse(HangHoa?.DonViQuyDoi || '[]')
						const DSSoLuong = JSON.parse(HangHoa?.DanhSachSoLuong || '[]')
						DSSoLuong.forEach(ItemHangHoa => {
							ItemHangHoa.DonViKiemKe_Id = ItemHangHoa.DonViKiemKe_Id ?? HangHoa.Chuan_DonViTinh_Id
							const flagBaseUnit = DSDonViTinh.find(x => x.DonViTinh_Id === HangHoa.Chuan_DonViTinh_Id)
							if (!flagBaseUnit) {
								DSDonViTinh.push({
									DonViTinh_Id: HangHoa.Chuan_DonViTinh_Id,
									HeSo: 1,
									TenDonViQuyDoi: HangHoa.TenDonVi
								})
							}
							ItemHangHoa.TongSauQuyDoi = ItemHangHoa.SoLuongKho ?? ItemHangHoa.SoLuong
							ItemHangHoa.DSDonViTinh = DSDonViTinh
						})
						HangHoa.DSSoLuong = DSSoLuong
						totalItem += DSSoLuong.length
					}
					expandedIds.push(HangHoa.HangHoa_Id)
				})
	
				this.totalItem = totalItem
				this.isKiemKe = false
				this.DSHangHoa = data
				this.expanded = []
				this.openListGroup = []
			},
	
			buildSubmitPayload() {
				let arraySoLuong = []
				let arrayCaBiet = []
				this.DSHangHoa.forEach(HangHoa => {
					if (HangHoa.Is_CaBiet) {
						HangHoa.DSCaBiet?.forEach(CaBiet => {
							arrayCaBiet.push({
								PhieuKiemKe_ChiTiet_CaBiet_Id: CaBiet.PhieuKiemKe_ChiTiet_CaBiet_Id ?? 0,
								CaBiet_Id: CaBiet.CaBiet_Id,
								TinhTrangHienTai: CaBiet.TinhTrangHienTai ?? null,
								TinhTrangThucTe: CaBiet.TinhTrangThucTe ?? null,
								DiaDiemHienTai_Id: CaBiet.DiaDiemHienTai_Id ?? null,
								DiaDiemThucTe_Id: CaBiet.DiaDiemThucTe_Id ?? null,
								KhuVucHienTai_Id: CaBiet.KhuVucHienTai_Id ?? null,
								KhuVucThucTe_Id: CaBiet.KhuVucThucTe_Id ?? null,
								GhiChu: CaBiet.GhiChu ?? null,
								TinhTrangKiemKe: CaBiet.TinhTrangKiemKe ?? null,
							})
						})
					} else {
						HangHoa.DSSoLuong?.forEach(ItemHangHoa => {
							arraySoLuong.push({
								PhieuKiemKe_ChiTiet_Id: ItemHangHoa.PhieuKiemKe_ChiTiet_Id ?? 0,
								HangHoa_Id: ItemHangHoa.HangHoa_Id,
								KhuVuc_Id: ItemHangHoa.KhuVuc_Id ?? 0,
								DonViKiemKe_Id: ItemHangHoa.DonViKiemKe_Id ?? null,
								SoLuong: ItemHangHoa.SoLuong,
								SoLuongKho: ItemHangHoa.SoLuongKho ?? ItemHangHoa.TongSauQuyDoi,
								SoLuongThucTe: ItemHangHoa.SoLuongThucTe === '' ? null : Number(ItemHangHoa.SoLuongThucTe),
								SoLuongDuyet: ItemHangHoa.SoLuongThucTe === '' ? null : Number(ItemHangHoa.SoLuongThucTe),
								GhiChu: ItemHangHoa.GhiChu ?? null,
								TinhTrangKiemKe: ItemHangHoa.TinhTrangKiemKe,
							})
						})
					}
				})
				return {
					JsonSoLuong: arraySoLuong.length > 0 ? JSON.stringify(arraySoLuong) : null,
					JsonCaBiet: arrayCaBiet.length > 0 ? JSON.stringify(arrayCaBiet) : null,
				}
			},
	
			onSubmit(TinhTrang) {
				const payload = this.buildSubmitPayload()
				payload.PhieuKiemKe_Id = this.localPhieuKiemKe_Id
				payload.TinhTrang = TinhTrang
				apiCall("work/HH_PhieuKiemKe_Update", payload, (res) => {
					if (res) showToast.success("Thành công")
					this.$emit('onReload')
					this.isKiemKe = !this.isKiemKe
				})
			},
	
			updateDaLayDuLieu(params) {
				apiCall("work/HH_PhieuKiemKe_Update_KiemKe", params, async (res) => {
					if (res) showToast.success("Thành công")
					await this.onGetDataKiemKe()
					this.$emit('onReload')
					this.isKiemKe = true
				})
			},
	
			async handleButtonKiemKeClick() {
				if (!this.isKiemKe && this.isLayDuLieuLanDau !== true) {
					let arraySoLuong = []
					let arrayCaBiet = []
					this.DSHangHoa.forEach(HangHoa => {
						if (HangHoa.Is_CaBiet) {
							HangHoa.DSCaBiet?.forEach(CaBiet => {
								arrayCaBiet.push({
									CaBiet_Id: CaBiet.CaBiet_Id,
									TinhTrangHienTai: CaBiet.TinhTrangHienTai ?? null,
									DiaDiemHienTai_Id: CaBiet.DiaDiemHienTai_Id ?? null,
									KhuVucHienTai_Id: CaBiet.KhuVucHienTai_Id ?? null,
								})
							})
						} else {
							HangHoa.DSSoLuong?.forEach(ItemHangHoa => {
								arraySoLuong.push({
									HangHoa_Id: ItemHangHoa.HangHoa_Id,
									KhuVuc_Id: ItemHangHoa.KhuVuc_Id ?? 0,
									SoLuong: ItemHangHoa.SoLuong,
								})
							})
						}
					})
					await this.updateDaLayDuLieu({
						PhieuKiemKe_Id: this.localPhieuKiemKe_Id,
						JsonSoLuong: arraySoLuong.length > 0 ? JSON.stringify(arraySoLuong) : null,
						JsonCaBiet: arrayCaBiet.length > 0 ? JSON.stringify(arrayCaBiet) : null,
					})
					return
				}
				if (!this.isKiemKe) {
					this.isKiemKe = true
					return
				}
				const TinhTrang = this.PhanTramHoanThanh === 100 ? 'CHO_DUYET' : 'LUU_TAM'
				if (TinhTrang === 'CHO_DUYET') {
					const { valid } = await this.$refs.form.validate()
					if (!valid) {
						showToast.info('Thông tin bị thiếu hoặc chưa chính xác')
						return
					}
					showConfirm(
						"Hoàn thành phiếu kiểm kê này sẽ ảnh hưởng trực tiếp tới <strong>tồn kho</strong> và <strong> tài sản thực tế</strong> </br>Bạn có thực sự muốn tiếp tục?",
						() => { this.onSubmit(TinhTrang) }
					)
				} else {
					this.onSubmit(TinhTrang)
				}
			},
		}
	}
</script>