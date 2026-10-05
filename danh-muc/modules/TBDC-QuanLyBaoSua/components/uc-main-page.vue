<template>
	<z-layout>
		<uc-top-bar v-if="isMobile" @load-bao-sua-moi="onLoadBaoSuaMoi"></uc-top-bar>
		<uc-table :DSBaoSuaMoi="DSBaoSuaMoi" :DSBaoSua="DSBaoSua" :Stats="Stats"
			@on-open-dialog-tiep-nhan-bao-sua='onOpenDialogTiepNhanBaoSua'
			@on-open-dialog-chi-tiet-bao-sua='onOpenDialogChiTietBaoSua' @load-bao-sua-moi="onLoadBaoSuaMoi"></uc-table>

		<uc-modal-tiep-nhan-bao-sua v-model:isShow="isShowDialogTiepNhanBaoSua" :selectedBaoSua="selectedBaoSua"
			@load-data="onLoadData"></uc-modal-tiep-nhan-bao-sua>

		<uc-modal-chi-tiet-bao-sua v-model:isShow="isShowDialogChiTietBaoSua" :selectedBaoSua="selectedBaoSua"
			@load-data="onLoadData" @load-detail="onLoadDetail"></uc-modal-chi-tiet-bao-sua>
	</z-layout>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				isShowDialogTiepNhanBaoSua: false,
				isShowDialogChiTietBaoSua: false,
	
				DSBaoSuaMoi: [],
				DSBaoSua: [],
				Stats: {
					DaTiepNhan: 0,
					DaKiemTra: 0,
					DangSua: 0,
					DaSuaXong: 0,
					Hu: 0,
					BaoSai: 0
				},
				selectedBaoSua: {},
			}
		},
		mounted() {
			this.loadData()
		},
		computed: {
			isMobile() {
				return this.$vuetify.display.smAndDown
			},
		},
		watch: {},
		methods: {
			formatDateTime: window.formatDateTime,
	
			loadData() {
				this.loadDSBaoSuaMoi()
				this.loadDSBaoSua()
			},
	
			async loadDSBaoSuaMoi() {
				let data = await apiCallPromise('work/TS_BaoSua_Select_BaoSuaMoi')
				data.forEach((item) => item.ThoiGianBaoSua = this.formatDateTime(item.ThoiGianBaoSua))
				this.DSBaoSuaMoi = data
			},
	
			async loadDSBaoSua() {
				let res = await apiCallPromise('work/TS_BaoSua_Select')
				this.Stats = {
					DaTiepNhan: res[0][0].DaTiepNhan,
					DaKiemTra: res[0][0].DaKiemTra,
					DangSua: res[0][0].DangSua,
					DaSuaXong: res[0][0].DaSuaXong,
					Hu: res[0][0].Hu,
					BaoSai: res[0][0].BaoSai
				}
				let data = res[1]
				data.forEach((item) => {
					const logs = JSON.parse(item.TinhTrang ?? '[]')
					const result = {
						TiepNhan: null,
						KiemTra: null,
						DangSua: null,
						DaXong: null,
						BaoSai: null,
						Hu: null
					}
					logs.forEach(x => {
						switch (x.TinhTrangXuLy) {
							case "TIEP_NHAN":
								result.TiepNhan = {
									TenNhanVienXuLy: x.TenNhanVienXuLy,
									ThoiGianXuLy: this.formatDateTime(x.ThoiGianXuLy),
									AnhDaiDien_Url: x.AnhDaiDien_Url,
									GhiChuXyLy: x.GhiChuXyLy,
								}
								break
	
							case "KIEM_TRA":
								result.KiemTra = {
									TenNhanVienXuLy: x.TenNhanVienXuLy,
									ThoiGianXuLy: this.formatDateTime(x.ThoiGianXuLy),
									AnhDaiDien_Url: x.AnhDaiDien_Url,
									GhiChuXyLy: x.GhiChuXyLy,
								}
								break
	
							case "DANG_SUA":
								result.DangSua = {
									TenNhanVienXuLy: x.TenNhanVienXuLy,
									ThoiGianXuLy: this.formatDateTime(x.ThoiGianXuLy),
									AnhDaiDien_Url: x.AnhDaiDien_Url,
									GhiChuXyLy: x.GhiChuXyLy,
								}
								break
	
							case "DA_XONG":
								result.DaXong = {
									TenNhanVienXuLy: x.TenNhanVienXuLy,
									ThoiGianXuLy: this.formatDateTime(x.ThoiGianXuLy),
									AnhDaiDien_Url: x.AnhDaiDien_Url,
									GhiChuXyLy: x.GhiChuXyLy,
								}
								break
							case "BAO_SAI":
								result.BaoSai = {
									TenNhanVienXuLy: x.TenNhanVienXuLy,
									ThoiGianXuLy: this.formatDateTime(x.ThoiGianXuLy),
									AnhDaiDien_Url: x.AnhDaiDien_Url,
									GhiChuXyLy: x.GhiChuXyLy,
								}
								break
							case "HU":
								result.Hu = {
									TenNhanVienXuLy: x.TenNhanVienXuLy,
									ThoiGianXuLy: this.formatDateTime(x.ThoiGianXuLy),
									AnhDaiDien_Url: x.AnhDaiDien_Url,
									GhiChuXyLy: x.GhiChuXyLy,
								}
								break
						}
					})
					item.TinhTrangXuLy = result
					item.ThoiGianBaoSua = this.formatDateTime(item.ThoiGianBaoSua)
				})
				this.DSBaoSua = data
			},
	
			async loadBaoSuaDetail() {
				const params = {
					BaoSua_Id: this.selectedBaoSua.BaoSua_Id
				}
				const data = await apiCallPromise('work/TS_BaoSua_Select_By_Id', params)
				const temp_data = data[0]
				const logs = JSON.parse(temp_data?.TinhTrang ?? '[]')
				let result = {
					TiepNhan: null,
					KiemTra: null,
					DangSua: null,
					DaXong: null,
					BaoSai: null,
					Hu: null
				}
				logs.forEach(x => {
					switch (x.TinhTrangXuLy) {
						case "TIEP_NHAN":
							result.TiepNhan = {
								TenNhanVienXuLy: x.TenNhanVienXuLy,
								ThoiGianXuLy: this.formatDateTime(x.ThoiGianXuLy),
								AnhDaiDien_Url: x.AnhDaiDien_Url,
								GhiChuXyLy: x.GhiChuXyLy,
							}
							break
	
						case "KIEM_TRA":
							result.KiemTra = {
								TenNhanVienXuLy: x.TenNhanVienXuLy,
								ThoiGianXuLy: this.formatDateTime(x.ThoiGianXuLy),
								AnhDaiDien_Url: x.AnhDaiDien_Url,
								GhiChuXyLy: x.GhiChuXyLy,
							}
							break
	
						case "DANG_SUA":
							result.DangSua = {
								TenNhanVienXuLy: x.TenNhanVienXuLy,
								ThoiGianXuLy: this.formatDateTime(x.ThoiGianXuLy),
								AnhDaiDien_Url: x.AnhDaiDien_Url,
								GhiChuXyLy: x.GhiChuXyLy,
							}
							break
	
						case "DA_XONG":
							result.DaXong = {
								TenNhanVienXuLy: x.TenNhanVienXuLy,
								ThoiGianXuLy: this.formatDateTime(x.ThoiGianXuLy),
								AnhDaiDien_Url: x.AnhDaiDien_Url,
								GhiChuXyLy: x.GhiChuXyLy,
							}
							break
						case "BAO_SAI":
							result.BaoSai = {
								TenNhanVienXuLy: x.TenNhanVienXuLy,
								ThoiGianXuLy: this.formatDateTime(x.ThoiGianXuLy),
								AnhDaiDien_Url: x.AnhDaiDien_Url,
								GhiChuXyLy: x.GhiChuXyLy,
							}
							break
						case "HU":
							result.Hu = {
								TenNhanVienXuLy: x.TenNhanVienXuLy,
								ThoiGianXuLy: this.formatDateTime(x.ThoiGianXuLy),
								AnhDaiDien_Url: x.AnhDaiDien_Url,
								GhiChuXyLy: x.GhiChuXyLy,
							}
							break
					}
				})
				temp_data.TinhTrangXuLy = result
				temp_data.ThoiGianBaoSua = this.formatDateTime(temp_data.ThoiGianBaoSua)
				this.selectedBaoSua = temp_data
			},
	
			onOpenDialogTiepNhanBaoSua(item) {
				this.selectedBaoSua = { ...item, DSFiles: item.FilesID ? item.FilesID.split(",") : [] }
				this.isShowDialogTiepNhanBaoSua = true
			},
	
			onOpenDialogChiTietBaoSua(item) {
				this.selectedBaoSua = { ...item, DSFiles: item.FilesID ? item.FilesID.split(",") : [] }
				this.isShowDialogChiTietBaoSua = true
			},
	
			onLoadBaoSuaMoi() {
				this.loadData()
			},
	
			onLoadData() {
				this.loadData()
			},
	
			onLoadDetail() {
				this.loadBaoSuaDetail()
			},
	
		},
	}
</script>