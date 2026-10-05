<template>
	<Global>
		<v-card>
			<v-card-title>
				Điểm MH theo Khối
			</v-card-title>
			<v-card-text>
				<v-row>
					<v-col cols="12" sm="6" md="3">
						<v-select v-model="HocKiItem" label="Chọn học kì" :items="DSHocKi" item-title="title"
							item-value="value" return-object no-data-text="Chưa có dữ liệu" />
					</v-col>
					<v-col cols="12" sm="6" md="3">
						<v-select v-model="KhoiItem" label="Chọn khối" :items="DSKhoi" item-title="TenKhoiHoc"
							item-value="KhoiID" return-object no-data-text="Chưa có dữ liệu" />
					</v-col>
					<v-col cols="12" sm="6" md="3">
						<v-select v-model="MonHocItem" label="Chọn môn học" :items="DSMonHoc" item-title="MonHocName"
							item-value="MonHocID" return-object no-data-text="Chưa có dữ liệu" />
					</v-col>
					<v-col cols="12" sm="6" md="3" class="d-flex align-center">
						<v-btn text="Làm mới" prepend-icon="mdi-refresh" variant="outlined" color="primary" @click="onRefresh" />
					</v-col>
				</v-row>
			</v-card-text>
		</v-card>
		<v-divider />
		<v-card title="Thống kê môn học theo khối">
			<template #append>
				<v-btn color="success" prepend-icon="mdi-microsoft-excel" variant="tonal" size="small"
					:disabled="!itemThongKe.length" @click="exportExcel">
					Xuất Excel
				</v-btn>
			</template>
			<v-data-table :headers="headerThongKe" :items="itemThongKe" :items-per-page="-1" hide-default-footer
				no-data-text="Chưa có dữ liệu" />
		</v-card>
		<v-divider />
		<v-card title="Danh sách bảng điểm học sinh">
			<template #append>
				<v-btn color="success" prepend-icon="mdi-microsoft-excel" variant="tonal" size="small"
					:disabled="!itemBangDiem.length" @click="exportExcelBangDiem">
					Xuất Excel
				</v-btn>
			</template>
			<v-data-table :headers="headerBangDiem" :items="itemBangDiem" :items-per-page="-1" hide-default-footer
				no-data-text="Chưa có dữ liệu" />
		</v-card>
	</Global>
</template>

<script>
	export default {
		props: [],
	data() {
		const urlParams = new URLSearchParams(window.location.search);
		const capIdFromUrl = urlParams.get('capid') || urlParams.get('CapID') || vueData.capid || vueData.CapID;
		const parsedCapId = capIdFromUrl ? parseInt(capIdFromUrl) : null;

		let DSHocKi = []
		if (parsedCapId === 1) {
			DSHocKi = [
				{ title: "Giữa kì 1", value: "GK_HK1", textValue: "HK1", hocKiNumber: 1 },
				{ title: "Cuối kì 1", value: "CK_HK1", textValue: "HK1", hocKiNumber: 1 },
				{ title: "Giữa kì 2", value: "GK_HK2", textValue: "HK2", hocKiNumber: 2 },
				{ title: "Cuối kì 2", value: "CK_HK2", textValue: "HK2", hocKiNumber: 2 },
			]
		}
		else {
			DSHocKi = [
				{ title: "Học kì 1", value: "HK1", textValue: "HK1", hocKiNumber: 1 },
				{ title: "Học kì 2", value: "HK2", textValue: "HK2", hocKiNumber: 2 },
			]
		}
		return {
			vueData,
			DSHocKi,
			CapID: parsedCapId,
			HocKiItem: DSHocKi[0],
			DSKhoi: [],
			KhoiItem: null,
			DSMonHoc: [],
			MonHocItem: null,
			DSBangDiem: [],
			DSThongKe: [],
			headerThongKe: [],
			itemThongKe: [],
			headerBangDiem: [],
			itemBangDiem: []
		}
	},
	async mounted() {
		this.loadSheetJS();
		await this.getKhoi();
	},
	computed: {},
	watch: {
		HocKiItem(val) {
			this.KhoiItem = null;
			this.MonHocItem = null;
			this.DSMonHoc = [];
			this.itemBangDiem = [];
			this.itemThongKe = [];
			this.getKhoi();
		},
		KhoiItem(val) {
			this.MonHocItem = null;
			this.DSMonHoc = [];
			this.itemBangDiem = [];
			this.itemThongKe = [];
			if (val?.KhoiID) {
				this.getMon();
			}
		},
		MonHocItem(val) {
			this.itemBangDiem = [];
			this.itemThongKe = [];
			if (val?.MonHocID) {
				this.initHeader();
				this.onRefresh();
			}
		},
		'vueData.NienKhoa'() {
			this.KhoiItem = null;
			this.MonHocItem = null;
			this.DSMonHoc = [];
			this.itemBangDiem = [];
			this.itemThongKe = [];
			this.getKhoi();
		}
	},
	methods: {
		// ─── Load SheetJS một lần duy nhất ───────────────────────────────
		loadSheetJS() {
			if (window.XLSX) return
			return new Promise((resolve, reject) => {
				const script = document.createElement("script")
				script.src = "https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"
				script.onload = resolve
				script.onerror = reject
				document.head.appendChild(script)
			})
		},

		// ─── Hàm xuất Excel dùng chung ───────────────────────────────────
		_exportToExcel(headers, items, sheetName, fileName) {
			const XLSX = window.XLSX
			if (!XLSX) {
				alert("Thư viện xuất Excel chưa sẵn sàng, vui lòng thử lại.")
				return
			}

			const headerRow = headers.map(h => h.title)
			const keys = headers.map(h => h.value)

			const dataRows = items.map(item =>
				keys.map(key => {
					const val = item[key]
					return val === undefined || val === null ? "" : val
				})
			)

			const wsData = [headerRow, ...dataRows]
			const ws = XLSX.utils.aoa_to_sheet(wsData)

			const colWidths = headerRow.map((h, i) => {
				const maxLen = Math.max(
					String(h).length,
					...dataRows.map(r => String(r[i] ?? "").length)
				)
				return { wch: Math.min(maxLen + 4, 50) }
			})
			ws["!cols"] = colWidths

			const wb = XLSX.utils.book_new()
			XLSX.utils.book_append_sheet(wb, ws, sheetName)
			XLSX.writeFile(wb, fileName)
		},

		// ─── Xuất bảng Thống kê ──────────────────────────────────────────
		exportExcel() {
			const hocKi = this.HocKiItem?.title ?? "HocKi"
			const khoi = this.KhoiItem?.TenKhoiHoc ?? "Khoi"
			const mon = this.MonHocItem?.MonHocName ?? "MonHoc"
			const fileName = `ThongKe_${mon}_${khoi}_${hocKi}.xlsx`
			this._exportToExcel(this.headerThongKe, this.itemThongKe, "Thống kê", fileName)
		},

		// ─── Xuất bảng Bảng điểm học sinh ───────────────────────────────
		exportExcelBangDiem() {
			const hocKi = this.HocKiItem?.title ?? "HocKi"
			const khoi = this.KhoiItem?.TenKhoiHoc ?? "Khoi"
			const mon = this.MonHocItem?.MonHocName ?? "MonHoc"
			const fileName = `BangDiem_${mon}_${khoi}_${hocKi}.xlsx`
			this._exportToExcel(this.headerBangDiem, this.itemBangDiem, "Bảng điểm", fileName)
		},

		// ─── Các method lấy dữ liệu ──────────────────────────────────────
		async getKhoi() {
			const hkNumber = this.HocKiItem?.hocKiNumber 
				?? (this.HocKiItem?.value?.includes('2') ? 2 : 1)
				?? vueData.NienKhoaItem?.HocKi 
				?? 1;

			const res = await fetchPromise("lms/KhoiHocByCapHoc_Get", {
				CapID: this.CapID,
				HocKi: hkNumber,
				NienKhoa: vueData.NienKhoa
			});
			this.DSKhoi = res ?? [];
			if (this.DSKhoi.length > 0) {
				if (!this.KhoiItem || !this.DSKhoi.some(k => k.KhoiID === this.KhoiItem?.KhoiID)) {
					this.KhoiItem = this.DSKhoi[0];
				}
			} else {
				this.KhoiItem = null;
				this.DSMonHoc = [];
				this.MonHocItem = null;
				this.itemBangDiem = [];
				this.itemThongKe = [];
			}
		},
		async getMon() {
			if (!this.KhoiItem?.KhoiID) return;
			const hkNumber = this.HocKiItem?.hocKiNumber 
				?? (this.HocKiItem?.value?.includes('2') ? 2 : 1)
				?? vueData.NienKhoaItem?.HocKi 
				?? 1;

			const res = await fetchPromise("lms/MonHoc_GetByKhoiID", {
				NienKhoa: vueData.NienKhoa,
				KhoiID: this.KhoiItem.KhoiID,
				HocKi: hkNumber
			});
			this.DSMonHoc = res ?? [];
			if (this.DSMonHoc.length > 0) {
				if (!this.MonHocItem || !this.DSMonHoc.some(m => m.MonHocID === this.MonHocItem?.MonHocID)) {
					this.MonHocItem = this.DSMonHoc[0];
				}
			} else {
				this.MonHocItem = null;
				this.itemBangDiem = [];
				this.itemThongKe = [];
			}
		},
		async onLoadHocSinhBangDiem() {
			if (!this.KhoiItem?.KhoiID || !this.MonHocItem?.TemplateBangDiemID || !this.HocKiItem?.value) return;
			const raw = await fetchPromise("lms/HocSinhBangDiem_Get_By_KhoiID_MonHocID", {
				KhoiID: this.KhoiItem.KhoiID,
				TemplateBangDiemID: this.MonHocItem.TemplateBangDiemID,
				NienKhoa: vueData.NienKhoa,
				Semester: this.HocKiItem.value,
			}, { forceRefresh: true }) || [];

			const map = {}
			const columnArr = []

			raw.forEach(item => {
				if (!map[item.HocSinhID]) {
					map[item.HocSinhID] = {
						HocSinhID: item.HocSinhID,
						SoDanhBo: item.SoDanhBo,
						HoTen: item.HoTen,
						NgaySinh: this.formatDateDisplay(item.NgaySinh),
						GioiTinh: item.Nu === true ? 'Nữ' : (item.Nu === false ? 'Nam' : '')
					}
				}
				map[item.HocSinhID][item.MaCotDiem] = item.KetQuaDanhGia_VI ?? "-"
				if (!columnArr.find(x => x.key === item.MaCotDiem)) {
					columnArr.push({
						key: item.MaCotDiem,
						title: item.TenCotDiem_VI,
						order: item.ThuTuCotDiem
					})
				}
			})

			columnArr.sort((a, b) => a.order - b.order)

			this.itemBangDiem = Object.values(map)
			this.headerBangDiem = [
				{ title: "Số danh bộ", value: "SoDanhBo", minWidth: "100px", width: "100px", align: "center" },
				{ title: "Họ tên", value: "HoTen", minWidth: "150px", width: "150px" },
				{ title: "Ngày sinh", value: "NgaySinh", minWidth: "120px", width: "120px" },
				{ title: "Giới tính", value: "GioiTinh", minWidth: "100px", width: "100px" },
				...columnArr.map(col => ({
					title: col.title,
					value: col.key,
					align: "center"
				}))
			]
		},
		async onLoadThongKeTheoCap() {
			if (!this.MonHocItem?.MonHocID || !this.HocKiItem?.value) return;
			const effectiveCapId = this.CapID 
				?? this.KhoiItem?.CapID 
				?? (this.KhoiItem?.KhoiID <= 5 ? 1 : (this.KhoiItem?.KhoiID <= 9 ? 2 : 3));
			
			const maCotDiem = effectiveCapId === 1 
				? "Diem" + this.HocKiItem.value 
				: "DiemTB_" + this.HocKiItem.value;

			this.itemThongKe = await fetchPromise("lms/ThongKeDiemTheoCap_MaCotDiem", {
				CapID: effectiveCapId,
				MonHocID: this.MonHocItem.MonHocID,
				MaCotDiem: maCotDiem,
				HocKi: this.HocKiItem.textValue ?? this.HocKiItem.value,
				NhomHocKi: this.HocKiItem.value,
				NienKhoa: vueData.NienKhoa
			}, { forceRefresh: true }) || [];
		},
		onRefresh() {
			this.onLoadHocSinhBangDiem()
			this.onLoadThongKeTheoCap()
		},
		initHeader() {
			let headers = []
			if ([106, 43, 42, 41, 40, 38, 37, 36].includes(this.MonHocItem?.MonHocID)) {
				headers = [
					{ "title": "Giai đoạn", "value": "Semester" },
					{ "title": "Khối", "value": "TenKhoiHoc" },
					{ "title": "Tổng số học sinh", "value": "TongSoHocSinh", "align": "right" },
					{ "title": "Sao < 3", "value": "SaoDuoi3" },
					{ "title": "Tỉ lệ sao < 3", "value": "TiLeSaoDuoi3" },
					{ "title": "Sao 3", "value": "Sao3" },
					{ "title": "Tỉ lệ sao 3", "value": "TiLeSao3" },
					{ "title": "Sao 4", "value": "Sao4" },
					{ "title": "Tỉ lệ sao 4", "value": "TiLeSao4" },
					{ "title": "Sao 5", "value": "Sao5" },
					{ "title": "Tỉ lệ sao 5", "value": "TiLeSao5" }
				]
			}
			else {
				headers = [
					{ "title": "Giai đoạn", "value": "Semester" },
					{ "title": "Khối", "value": "TenKhoiHoc" },
					{ "title": "Tổng số học sinh", "value": "TongSoHocSinh", "align": "right" },
					{ "title": "<5", "value": "DiemDuoi5", "align": "right" },
					{ "title": "TL <5", "value": "TiLeDiemDuoi5", "align": "right" },
					{ "title": "5", "value": "Diem5", "align": "right" },
					{ "title": "TL 5", "value": "TiLeDiem5", "align": "right" },
					{ "title": "6", "value": "Diem6", "align": "right" },
					{ "title": "TL 6", "value": "TiLeDiem6", "align": "right" },
					{ "title": "7", "value": "Diem7", "align": "right" },
					{ "title": "TL 7", "value": "TiLeDiem7", "align": "right" },
					{ "title": "8", "value": "Diem8", "align": "right" },
					{ "title": "TL 8", "value": "TiLeDiem8", "align": "right" },
					{ "title": "9", "value": "Diem9", "align": "right" },
					{ "title": "TL 9", "value": "TiLeDiem9", "align": "right" },
					{ "title": "10", "value": "Diem10", "align": "right" },
					{ "title": "TL 10", "value": "TiLeDiem10", "align": "right" }
				]
			}
			this.headerThongKe = headers
		},
		formatDateDisplay(val) {
			if (!val) return '';
			if (typeof val === 'string') {
				const trimmed = val.trim();
				// Nếu đã là dd/mm/yyyy hoặc dd-mm-yyyy thì giữ nguyên
				if (/^\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4}$/.test(trimmed)) {
					return trimmed;
				}
				// Nếu là yyyy-mm-dd (ISO)
				if (/^\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}/.test(trimmed)) {
					const parts = trimmed.split(/[\/\-T\s]/);
					if (parts.length >= 3) {
						return `${parts[2].padStart(2, '0')}/${parts[1].padStart(2, '0')}/${parts[0]}`;
					}
				}
			}
			const d = new Date(val);
			if (!isNaN(d.getTime())) {
				return d.toLocaleDateString('vi-VN');
			}
			return val;
		}
	},
	}
</script>