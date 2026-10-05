<template>
	<v-dialog v-model="isShow" fullscreen>
		<v-card>
			<v-toolbar density="compact" class="px-4 border-b" color="white">
				<v-toolbar-title class="text-subtitle-1 font-weight-medium">
					Import Excel
				</v-toolbar-title>
				<v-spacer />
				<v-btn prepend-icon="mdi-trash-can-outline" variant="tonal" color="error" size="small"
					class="mr-2 text-none" @click="XoaDongHienTai">
					Xoá dòng
					<span class="ml-1 text-caption text-medium-emphasis">(F2)</span>
				</v-btn>
				<v-btn prepend-icon="mdi-plus" variant="tonal" color="primary" size="small" class="mr-2"
					@click="ThemNhanhHangHoa">
					Thêm hàng hoá (F9)
				</v-btn>

				<v-btn prepend-icon="mdi-file-import" variant="flat" color="success" size="small" class="mr-2"
					@click="handleImport">
					Hoàn thành (F10)
				</v-btn>

				<v-btn icon="mdi-close" variant="text" size="small" @click="closeDialog" />
			</v-toolbar>
			<v-card-text class="pt-0 px-0">
				<hot-table ref="hotTable" :settings="settings" :data="tableData" :afterChange="afterChange">
					<hot-column title="ID" data="HangHoa_Id" type="numeric">
					</hot-column>
					<hot-column title="Loại hàng hoá" data="LoaiHangHoa" type="text">
					</hot-column>
					<hot-column title="DVT_Id" data="DVT_Id" type="text">
					</hot-column>
					<hot-column title="DSDonViTinh" data="DSDonViTinh" type="text">
					</hot-column>
					<hot-column title="Is_CaBiet" data="Is_CaBiet" type="text">
					</hot-column>
					<hot-column title="ThueGTGT" data="ThueGTGT" type="text">
					</hot-column>
					<hot-column title="ThueKhac" data="ThueKhac" type="text">
					</hot-column>
					<hot-column title="ThueNhapKhau" data="ThueNhapKhau" type="text">
					</hot-column>
					<!-- main table -->
					<hot-column title="Mã hàng" data="MaNoiBo" type="autocomplete" :strict="true" :filter="true"
						:source="getHangHoaByKeyword" width="150" :trimDropdown="false" />
					<hot-column title="Tên hàng" data="TenHangHoa" :readOnly="true">
					</hot-column>
					<hot-column title="ĐVT" data="DVT" :readOnly="true">
					</hot-column>
					<hot-column title="Số lượng" data="SoLuong" type="numeric" :allowEmpty="false"
						:allowInvalid="false">
					</hot-column>
					<hot-column title="Đơn giá" data="DonGia" type="numeric" :numericFormat="{
						pattern: '0,0',
						culture: 'vi-VN'
					}" :allowEmpty="false" :allowInvalid="false">
					</hot-column>
					<hot-column title="Phần trăm khác" data="PhanTramKhac" type="numeric" :allowEmpty="true"
						:allowInvalid="false">
					</hot-column>
					<hot-column title="Chi phí khác" data="ChiPhiKhac" type="numeric" :numericFormat="{
						pattern: '0,0',
						culture: 'vi-VN'
					}" :allowEmpty="true" :allowInvalid="false">
					</hot-column>
					<hot-column title="Thành tiền" data="ThanhTien" type="numeric" :numericFormat="{
						pattern: '0,0',
						culture: 'vi-VN'
					}" :allowEmpty="true" :allowInvalid="false">
					</hot-column>
				</hot-table>
			</v-card-text>
		</v-card>
	</v-dialog>
	<v-dialog v-model="isShowDialogThemNhanh" width="500" @after-enter="focusTenHangHoa" @after-leave="focusHotTable">
		<v-card>
			<v-toolbar density="compact" class="px-4 border-b">
				<v-toolbar-title class="text-subtitle-1 font-weight-medium">
					Thêm nhanh hàng hoá
				</v-toolbar-title>
				<v-spacer />
				<v-btn icon="mdi-close" variant="text" size="small" @click="closeDialogThemNhanh" />
			</v-toolbar>
			<v-card-text class="pt-1 pb-2">
				<v-form ref="form">
					<v-row dense>
						<v-col cols="12" md="6" class="mt-1">
							<v-text-field ref="TenHangHoa" label="* Tên hàng hoá" v-model="item.TenHangHoa"
								density="compact" :rules="[rules.required]" />
						</v-col>
						<v-col cols="12" md="6" class="mt-1">
							<v-autocomplete label="* Loại hàng hoá" :items="DSLoaiHangHoa" v-model="item.LoaiHangHoa"
								item-title="title" item-value="value" density="compact" :rules="[rules.required]" />
						</v-col>
						<v-col cols="12" md="6" class="mt-1">
							<v-text-field label="* Mã nội bộ" v-model="item.MaNoiBo" density="compact"
								:rules="[rules.required]" />
						</v-col>
						<v-col cols="12" md="6" class="mt-1">
							<v-autocomplete label="* Đơn vị nhập" :items="DSDonViTinh" v-model="item.Chuan_DonViTinh_Id"
								item-title="TenDonVi" item-value="DonViTinh_Id" density="compact"
								:rules="[rules.required]" />
						</v-col>
					</v-row>
				</v-form>
			</v-card-text>
			<v-card-actions class="pt-0">
				<v-spacer></v-spacer>
				<v-btn color="primary" variant="flat" @click="onThemNhanh">
					Thêm
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
	components: {
		HotTable: Handsontable?.vue.HotTable,
		HotColumn: Handsontable?.vue.HotColumn,
	},
	props: {
		isShow: Boolean,
		DSDonViTinh: Array,
	},
	emits: ['on-finish', 'update:isShow'],
	data() {
		return {
			rules: {
				required: v => v !== null && v !== undefined || 'Trường này không được để trống',
				greaterThanZero: v => v > 0 || 'Giá trị phải lớn hơn 0',
				noSpecialChar: v =>
					/^[a-zA-Z0-9\s]+$/.test(v) || 'Không được chứa ký tự đặc biệt',
			},

			settings: {
				hiddenColumns: {
					columns: [0, 1, 2, 3, 4, 5, 6, 7],
					indicators: false
				},
				minSpareRows: 20,
				height: 'calc(100vh - 76px)',
				width: '100%',
				rowHeaders: true,
				autoWrapRow: true,
				autoWrapCol: true,
				licenseKey: 'non-commercial-and-evaluation',
				themeName: 'ht-theme-main',
				stretchH: "all",
			},
			DSLoaiHangHoa: [
				{ title: 'Nguyên vật liệu', value: "NVL" },
				{ title: 'Công cụ dụng cụ', value: "CCDC" },
			],

			timeout: null,
			hangHoaCache: [],
			tableData: [{
				HangHoa_Id: null,
				LoaiHangHoa: null,
				MaNoiBo: null,
				TenHangHoa: null,
				DVT: null,
				DVT_Id: null,
				DSDonViTinh: null,
				SoLuong: null,
				DonGia: null,
				PhanTramKhac: null,
				ChiPhiKhac: null
			}],
			isShowDialogThemNhanh: false,
			item: {
				MaNoiBo: null,
				TenHangHoa: null,
				Chuan_DonViTinh_Id: null,
				LoaiHangHoa: null,
			},
		}
	},
	mounted() {
		setTimeout(() => {
			const hot = this.getHotTable
			const colIndex = hot.propToCol('MaNoiBo')

			if (colIndex >= 0) {
				hot.selectCell(0, colIndex)
				hot.listen()
			}
		}, 0)
		window.addEventListener('keydown', this.handleKey)
	},
	beforeUnmount() {
		window.removeEventListener('keydown', this.handleKey)
	},
	computed: {
		getHotTable() {
			return this.$refs.hotTable.hotInstance
		}
	},
	watch: {
	},
	methods: {
		closeDialog() {
			this.$emit('update:isShow', false)
		},

		closeDialogThemNhanh() {
			this.$refs.form?.reset()
			this.$refs.form?.resetValidation()
			this.isShowDialogThemNhanh = false
		},

		handleKey(e) {
			if (!this.isShow) return

			if (this.isShowDialogThemNhanh) return

			if (e.key === 'F2') {
				e.preventDefault()
				this.XoaDongHienTai()
			}

			if (e.key === 'F9') {
				e.preventDefault()
				const hot = this.$refs.hotTable?.hotInstance
				hot?.getActiveEditor()?.finishEditing?.()
				hot?.deselectCell?.()
				setTimeout(() => {
					this.ThemNhanhHangHoa()
				}, 0)
			}

			if (e.key === 'F10') {
				e.preventDefault()
				this.handleImport()
			}
		},

		focusTenHangHoa() {
			this.$refs.TenHangHoa?.focus()
		},

		focusHotTable(row = 0) {
			requestAnimationFrame(() => {
				const hot = this.getHotTable
				if (!hot) return

				const colIndex = hot.propToCol('MaNoiBo')

				if (colIndex >= 0) {
					hot.selectCell(row, colIndex)
				}

				hot.rootElement?.focus?.()
			})
		},

		async getHangHoaByKeyword(query, process) {
			if (!query || !query.trim()) {
				process([])
				return
			}
			const trimmed = query.trim()
			const existsInCache = this.hangHoaCache.some(x => `${x.MaNoiBo} - ${x.TenHangHoa} - Giá nhập cuối: ${x?.GiaNhapCuoi.toLocaleString('vi-VN') ?? ''}` === trimmed)
			const existsInCache_MaNoiBo = this.hangHoaCache.some(x => x.MaNoiBo === trimmed)

			if (existsInCache || existsInCache_MaNoiBo) {
				return process(
					this.hangHoaCache.map(x =>
						`${x.MaNoiBo} - ${x.TenHangHoa} - Giá nhập cuối: ${x?.GiaNhapCuoi.toLocaleString('vi-VN') ?? ''}`
					)
				)
			}

			if (this.timeout) clearTimeout(this.timeout)
			this.timeout = setTimeout(async () => {
				try {
					const params = {
						TimKiem: query.trim()
					}
					const data = await apiCallPromise('work/HH_HangHoa_Select_By_Keyword', params)
					if (!Array.isArray(data)) {
						process([])
						return
					}
					this.hangHoaCache = data
					process(data.map(x => `${x?.MaNoiBo ?? ''} - ${x?.TenHangHoa ?? ''} - Giá nhập cuối: ${x?.GiaNhapCuoi.toLocaleString('vi-VN') ?? ''}`))
				} catch (err) {
					console.error(err)
					process([])
				}
			}, 500)
		},

		afterChange(changes, source) {
			if (!changes || source === 'loadData') return
			const hot = this.getHotTable
			changes.forEach(([row, prop, oldVal, newVal]) => {
				if (prop !== 'MaNoiBo' && prop !== 'SoLuong' && prop !== 'DonGia' && prop !== 'PhanTramKhac' && prop !== 'ChiPhiKhac') return
				// if (!newVal?.trim()) return
				if (oldVal === newVal) return
				const found = this.hangHoaCache.find(x => `${x.MaNoiBo} - ${x.TenHangHoa} - Giá nhập cuối: ${x?.GiaNhapCuoi.toLocaleString('vi-VN') ?? ''}` === newVal)
				if (found) {
					hot.setDataAtRowProp(row, 'HangHoa_Id', found.HangHoa_Id)
					hot.setDataAtRowProp(row, 'LoaiHangHoa', found.LoaiHangHoa)
					hot.setDataAtRowProp(row, 'DVT_Id', found.Chuan_DonViTinh_Id)
					hot.setDataAtRowProp(row, 'DSDonViTinh', JSON.parse(found.DonViQuyDoi ?? '[]'))
					hot.setDataAtRowProp(row, 'Is_CaBiet', found.Is_CaBiet)
					hot.setDataAtRowProp(row, 'ThueGTGT', found.ThueGTGT)
					hot.setDataAtRowProp(row, 'ThueKhac', found.ThueKhac)
					hot.setDataAtRowProp(row, 'ThueNhapKhau', found.ThueNhapKhau)
					// main table
					hot.setDataAtRowProp(row, 'MaNoiBo', found.MaNoiBo)
					hot.setDataAtRowProp(row, 'DVT', found.TenDonVi)
					hot.setDataAtRowProp(row, 'TenHangHoa', found.TenHangHoa)

				}
				if (prop === 'SoLuong' || prop === 'DonGia' || prop === 'PhanTramKhac' || prop === 'ChiPhiKhac') {

					const soLuong = Number(hot.getDataAtRowProp(row, 'SoLuong')) || 0
					const donGia = Number(hot.getDataAtRowProp(row, 'DonGia')) || 0
					const phanTramKhac = Number(hot.getDataAtRowProp(row, 'PhanTramKhac')) || 0
					const chiPhiKhac = Number(hot.getDataAtRowProp(row, 'ChiPhiKhac')) || 0

					const thanhTienGoc = soLuong * donGia
					const tienPhanTram = thanhTienGoc * (phanTramKhac / 100)

					const thanhTien = thanhTienGoc + tienPhanTram + chiPhiKhac

					hot.setDataAtRowProp(row, 'ThanhTien', thanhTien, 'calc')
				}
			})
		},
		XoaDongHienTai() {
			const hot = this.getHotTable
			const selected = hot.getSelectedLast()
			if (!selected) {
				this.$toast?.warning('Vui lòng chọn 1 dòng để xoá')
				return
			}

			const [row] = selected

			hot.alter('remove_row', row)
			this.focusHotTable(row)
		},

		ThemNhanhHangHoa() {
			this.isShowDialogThemNhanh = true
		},
		async onThemNhanh() {
			const { valid } = await this.$refs.form.validate();
			if (!valid) {
				showToast.info('Thông tin hàng hoá chưa đầy đủ')
				return
			}
			const $this = this
			const params = {
				MaNoiBo: this.item.MaNoiBo,
				TenHangHoa: this.item.TenHangHoa,
				Chuan_DonViTinh_Id: this.item.Chuan_DonViTinh_Id,
				LoaiHangHoa: this.item.LoaiHangHoa,
			}
			apiCall("work/HH_HangHoa_Insert_Nhanh", params, (res) => {
				if (res) showToast.success("Thành công");
				$this.closeDialogThemNhanh()
			})
		},

		handleImport() {
			const hot = this.getHotTable
			const raw_data = hot.getSourceData()
			const data = raw_data.filter((item) => item.HangHoa_Id !== null &&
				item.LoaiHangHoa !== null &&
				item.MaNoiBo !== null &&
				item.DVT !== null &&
				item.TenHangHoa !== null)
			hot.loadData([]);
			this.closeDialog()
			this.$emit('on-finish', data)
		}
	}
}
</script>