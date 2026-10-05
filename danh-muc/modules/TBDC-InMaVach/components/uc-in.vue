<template>
	<z-layout>
		<v-app-bar density="compact" :elevation="0" title="Quản Lý In Tem Tài Sản" class="border-b">
			<template v-slot:append>
				<v-menu>
					<template v-slot:activator="{ props }">
						<v-btn @click="exportMaVach('excel')" prepend-icon="mdi-file-excel-outline" variant="flat"
							color="primary">Xuất excel</v-btn>
						<v-btn @click="onClickCreateQR()" prepend-icon="mdi-printer" variant="flat" color="primary">In
							mã QR</v-btn>
					</template>
					<v-list density="compact">

					</v-list>
				</v-menu>
			</template>
		</v-app-bar>

		<div class="pa-2 border-b border-t">
			<v-row dense>
				<v-col cols="2">
					<v-autocomplete v-model="selectedDiaDiem" label="Chọn địa điểm" :items="DsDiaDiemSanXuat"
						item-title="TenDiaDiem" item-value="DiaDiem_Id" />
				</v-col>
				<v-col cols="2">
					<v-text-field v-model="search" append-inner-icon="mdi-magnify" label="Tìm kiếm mã..." hide-details
						density="compact" variant="outlined" />
				</v-col>
				<v-col cols="2">
					<v-text-field ref="soLuongInput" v-model.number="soLuong" label="Số lượng mã cần tạo" type="number"
						min="1" variant="outlined" hide-details
						:rules="[v => Number.isInteger(v) && v > 0 || 'Nhập số nguyên > 0']"
						@keydown="e => ['.', '-', 'e'].includes(e.key) && e.preventDefault()" />
				</v-col>
				<v-col cols="2">
					<div class="d-flex gap-dense">
						<v-btn color="primary" prepend-icon="mdi-barcode" @click="onInsertMaVach()" variant="flat">
							Tạo mã QR
						</v-btn>
						<v-btn color="grey" @click="onReload()" variant="flat" prepend-icon="mdi-reload">
							Làm mới
						</v-btn>
						<v-btn :disabled="selectedUnused.length === 0" color="red" prepend-icon="mdi-delete"
							@click="onDelete()" variant="flat">
							Xóa mã đã chọn
						</v-btn>
					</div>
				</v-col>
			</v-row>
		</div>

		<v-divider></v-divider>

		<v-toolbar class="pl-1">
			<v-sheet>
				<v-toolbar-title class="text-primary text-subtitle-1">
					<b>Danh sách mã QR</b>
					<v-chip size="small" variant="tonal" color="primary">
						Đã chọn: <strong class="mx-1">{{ selectedUnused.length }}</strong> mã
					</v-chip>
				</v-toolbar-title>
			</v-sheet>

			<v-spacer></v-spacer>
		</v-toolbar>

		<v-data-table v-model="selectedUnused" v-model:items-per-page="itemsPerPage" :headers="headers"
			:items="DsMaVach" :search="search" item-value="MaVach" show-select return-object fixed-header
			select-strategy="all" height="calc(100vh - 230px)" density="compact" hover items-per-page-text="Bản ghi"
			:items-per-page-options="[10, 50, 100, 150, 200]" no-data-text="Không tìm thấy dữ liệu">
			<template v-slot:item.status="{ item }">
				<div class="text-center">
					<v-chip v-if="!item.CaBiet_Id" color="grey" size="x-small" variant="flat">
						Chưa gán
					</v-chip>

					<v-chip v-else color="success" size="x-small" variant="flat">
						<!-- {{ item.CaBiet_Id }} -->
						Đã gán
					</v-chip>
				</div>
			</template>

			<template v-slot:no-data>
				<div class="pa-4 text-center text-grey">
					Không có mã nào đang treo.
				</div>
			</template>

			<template v-slot:item.action="{ item }">
				<v-btn variant="text" color="red" @click="onDelete(item)">
					<v-icon :size="24">mdi-trash-can-outline</v-icon>
				</v-btn>
			</template>
		</v-data-table>

		<v-select v-if="showPrinterSelect" v-model="selectedPrinter" :items="printerList"
			label="Chọn máy in Godex (Cho in trực tiếp)" prepend-inner-icon="mdi-printer" variant="underlined"
			density="compact" class="mt-3"></v-select>

		<!-- Vùng in thật -->
	</z-layout>

	<div style="visibility: hidden" id="printArea"></div>
</template>

<script>
	export default {
		data() {
			return {
				DsDiaDiemSanXuat: [],
				DsMaVach: [],      // Danh sách lấy từ API
	
				itemsPerPage: 50,
	
				// Dữ liệu cho sinh mã mới
				soLuong: null,
				dsMaVach: [],
	
				// Dữ liệu cho mã chưa dùng
				selectedUnused: [],  // Danh sách user tích chọn
				selectAll: false,
				search: '',
	
				// Cấu hình chung
				loading: false,
				printerList: [],
				selectedPrinter: '',
				showPrinterSelect: false,
				headers: [
					{ title: 'Mã vạch', align: 'start', key: 'MaVach', sortable: true, width: 80 },
					{ title: 'Số serial', key: 'SoSeries', sortable: false, width: 200 },
					{ title: 'Trạng thái', align: 'center', key: 'status', sortable: false, width: 50 },
					{ title: '', align: 'center', key: 'action', sortable: false, width: 70 },
				],
	
				selectedDiaDiem: null,
	
			};
		},
		computed: {
			isPrint() {
				return this.selectedUnused.length > 0
			},
	
			tenDiaDiem() {
				const d = this.DsDiaDiemSanXuat.find(i => i.DiaDiem_Id === this.selectedDiaDiem)
				return d ? d.TenDiaDiem : ""
			}
		},
		watch: {
			selectedDiaDiem(val) {
				if (val) {
					this.onLoadMaVach(val)
				}
			}
		},
		mounted() {
			// this.connectQzTray()
			this.onLoadDiaDiemSanXuat()
		},
		methods: {
			// Load mã vạch chưa dùng
			async onLoadMaVach(diaDiem_Id) {
				if (!this.selectedDiaDiem) {
					showToast.error('Chưa chọn địa điểm!');
					return
				}
	
				this.selectedUnused = []
				this.DsMaVach = await apiCallPromise("/work/TS_MaVach_Select", { DiaDiem_Id: diaDiem_Id })
			},
	
			async onLoadDiaDiemSanXuat() {
				this.DsDiaDiemSanXuat = await apiCallPromise('/work/HH_DiaDiem_Select', null)
				this.selectedDiaDiem = this.DsDiaDiemSanXuat[0].DiaDiem_Id
			},
	
			// Sinh mã vạch
			async onInsertMaVach() {
				if (!this.soLuong || this.soLuong <= 0) {
					showToast.error('Vui lòng nhập số lượng > 0!');
					this.$nextTick(() => {
						this.$refs.soLuongInput.focus();
					});
					return;
				}
	
				try {
					await apiCall("/work/TS_MaVach_Insert", {
						SoLuong: Number(this.soLuong),
						DiaDiem_Id: Number(this.selectedDiaDiem)
					});
	
					showToast.success("Tạo mã thành công!");
	
					// reload danh sách
					await this.onLoadMaVach(this.selectedDiaDiem);
	
					// reset input
					this.soLuong = null;
	
				} catch (err) {
					console.error(err);
					showToast.error("Sinh mã vạch thất bại!");
				}
			},
	
			// --- 1. KẾT NỐI MÁY IN ---
			async connectQzTray() {
				if (!window.qz) return;
				try {
					if (!qz.websocket.isActive()) await qz.websocket.connect();
					this.printerList = await qz.printers.find();
					// this.selectedPrinter = this.printerList.find(p => p.toLowerCase().includes('godex')) || '';
					this.selectedPrinter =
						this.printerList.find(p =>
							p.toLowerCase().includes('xprinter') ||
							p.toLowerCase().includes('xp')
						) || '';
					this.showPrinterSelect = true;
				} catch (err) {
					console.warn("Lỗi QZ Tray:", err);
				}
			},
	
			// async connectQzTray() {
	
			// 	if (!window.qz) {
			// 		console.error("QZ Tray chưa load")
			// 		return
			// 	}
	
			// 	try {
	
			// 		if (!qz.websocket.isActive()) {
			// 			await qz.websocket.connect()
			// 		}
	
			// 		this.printerList = await qz.printers.find()
	
			// 		console.log("Printers:", this.printerList)
	
			// 		this.selectedPrinter =
			// 			this.printerList.find(p =>
			// 				/xp|xprinter/i.test(p)
			// 			) || this.printerList[0]
	
			// 		this.showPrinterSelect = true
	
			// 	} catch (err) {
			// 		console.error("Không kết nối được QZ Tray", err)
			// 	}
	
			// },
	
			// --- Xử lý in / xuất mã vạch ---
			async exportMaVach(type) {
				if (!this.selectedUnused || this.selectedUnused.length === 0) {
					showToast.error('Vui lòng chọn ít nhất 1 mã để in/xuất!')
					return;
				}
	
				try {
					const listData = this.selectedUnused;
	
					if (type === "excel") {
						this.runExportExcel(listData);
					} else {
						await this.runDirectPrint(listData);
					}
	
				} catch (error) {
					alert("Lỗi: " + error.message);
				}
			},
	
	
			onReload() {
				this.selectedUnused = []
				this.onLoadMaVach(this.selectedDiaDiem)
				showToast.success('Làm mới thành công!')
			},
	
			onDelete(item) {
	
				let listDelete = []
	
				// nếu bấm icon ở 1 dòng
				if (item) {
					listDelete = [item.MaVach]
					console.log('item.MaVach: ', item)
					console.log(listDelete)
				}
				// nếu xóa các dòng đã tick
				else {
					if (!this.selectedUnused.length) {
						showToast.error("Vui lòng chọn mã cần xóa!")
						return
					}
					listDelete = this.selectedUnused.map(x => x.MaVach)
				}
	
				showConfirm(
					`Bạn chắc chắn muốn xóa ${listDelete.length} mã vạch?`,
					() => {
						apiCall(
							"/work/TS_MaVach_Delete",
							{
								DiaDiem_Id: this.selectedDiaDiem,
								List_MaVach: listDelete.join(",")
							},
							() => {
								this.onLoadMaVach(this.selectedDiaDiem)
								this.selectedUnused = []
								showToast.success("Xóa mã thành công!")
							}
						)
					}
				)
			},
	
			// --- 4. CÁC HÀM XỬ LÝ CHUNG (REUSABLE) ---
			toggleSelectAll() {
				if (this.selectAll) {
					this.selectedUnused = [...this.DsMaVach];
				} else {
					this.selectedUnused = [];
				}
			},
	
			// Gọi API đánh dấu (Chỉ dùng cho mã mới)
			async insertMaVach(list) {
				try {
					const str = list.map(i => i.MaVach).join(",");
					await apiCall("/work/InsertMaVachDaIn", { DanhSachMaVach: str });
				} catch (err) { console.error(err); }
			},
	
			// Hàm xuất Excel (1 Cột - dùng chung)
			runExportExcel(dataList) {
				const rows = [["MaVach"]];
				dataList.forEach(item => rows.push([item.MaVach]));
	
				const ws = window.XLSX.utils.aoa_to_sheet(rows);
				const wb = window.XLSX.utils.book_new();
				window.XLSX.utils.book_append_sheet(wb, ws, "MaVach");
	
				// Tạo tên file theo thời gian
				const now = new Date();
				const d = String(now.getDate()).padStart(2, '0');
				const m = String(now.getMonth() + 1).padStart(2, '0');
				const y = now.getFullYear();
				const h = String(now.getHours()).padStart(2, '0');
				const min = String(now.getMinutes()).padStart(2, '0');
	
				const fileName = `MaVach_Godex_${d}-${m}-${y}_${h}h${min}.xlsx`;
	
				window.XLSX.writeFile(wb, fileName);
			},
	
			// Hàm in trực tiếp (Godex 2 tem - dùng chung)
			async runDirectPrint(dataList) {
				if (!this.selectedPrinter) {
					alert("Chưa chọn máy in!"); return;
				}
				try {
					const config = qz.configs.create(this.selectedPrinter);
					const commandData = [];
	
					for (let i = 0; i < dataList.length; i += 2) {
						const item1 = dataList[i];
						const item2 = dataList[i + 1];
						// commandData.push(this.generateEZPL(item1, item2));
						commandData.push(this.generateTSPL(item1, item2))
					}
					console.log("config", config)
					console.log("commandData", commandData)
					console.log("dataList", dataList)
					await qz.print(config, commandData);
					alert(`Đã gửi lệnh in ${dataList.length} tem!`);
				} catch (err) {
					alert("Lỗi in: " + err);
				}
			},
	
			generateEZPL(item1, item2) {
				let cmd = `^Q22,3\r\n^W75\r\n^H10\r\n^P1\r\n^L\r\n`;
	
				if (item1) {
					cmd +=
						`AT,2,10,20,20,0,0A,LHBS\r\n` +
						`BQ,2,35,4,2,0,0,2,${item1.MaVach}\r\n` + // model 2, EC=2, module size=4
						`AT,2,110,20,20,0,0A,${item1.MaVach}\r\n`;
				}
	
				if (item2) {
					const shiftX = 380;
					cmd +=
						`AT,${2 + shiftX},10,20,20,0,0A,LHBS\r\n` +
						`BQ,${2 + shiftX},35,4,2,0,0,2,${item2.MaVach}\r\n` +
						`AT,${2 + shiftX},110,20,20,0,0A,${item2.MaVach}\r\n`;
				}
	
				cmd += `E\r\n`;
				return cmd;
			},
	
			generateTSPL(item1, item2) {
	
				let cmd = `
																																																																																																																										SIZE 80 mm,40 mm
																																																																																																																										GAP 2 mm,0
																																																																																																																										CLS
																																																																																																																										`
	
				if (item1) {
					cmd += `
																																																																																																																										QRCODE 80,20,L,5,A,0,"${item1.MaVach}"
																																																																																																																										TEXT 110,200,"0",0,1,1,"${item1.MaVach}"
																																																																																																																										`
				}
	
				if (item2) {
					cmd += `
																																																																																																																										QRCODE 360,20,L,5,A,0,"${item2.MaVach}"
																																																																																																																										TEXT 390,200,"0",0,1,1,"${item2.MaVach}"
																																																																																																																										`
				}
	
				cmd += `
																																																																																																																										PRINT 1
																																																																																																																										`
	
				return cmd
			},
	
			// --------- QR CODE -----------------
			// onClickCreateQR() {
	
			// 	const printArea = document.getElementById("printArea")
			// 	printArea.innerHTML = ""
	
			// 	if (!Array.isArray(this.selectedUnused) || this.selectedUnused.length === 0) {
			// 		showToast.error("Chưa chọn mã nào để in")
			// 		return
			// 	}
	
	
			// 	console.log(this.selectedUnused)
			// 	console.log(this.selectedUnused.length)
	
			// 	this.selectedUnused.forEach(item => {
	
			// 		const page = document.createElement("div")
			// 		page.className = "page"
	
			// 		const label = document.createElement("div")
			// 		label.className = "label"
	
			// 		const temp = document.createElement("div")
	
			// 		$(temp).qrcode({
			// 			text: item.MaVach,
			// 			render: "canvas",
			// 			width: 512,
			// 			height: 512,
			// 			correctLevel: 3
			// 		})
	
			// 		const canvas = temp.querySelector("canvas")
	
			// 		const img = document.createElement("img")
			// 		img.src = canvas.toDataURL("image/png")
			// 		img.className = "qr-img"
	
			// 		label.appendChild(img)
			// 		page.appendChild(label)
			// 		printArea.appendChild(page)
	
			// 	})
	
			// 	console.log("pages:", printArea.children.length)
	
			// 	setTimeout(() => window.print(), 100)
	
			// }
	
			onClickCreateQR() {
	
				const printArea = document.getElementById("printArea")
				printArea.innerHTML = ""
	
				if (!Array.isArray(this.selectedUnused) || this.selectedUnused.length === 0) {
					showToast.error("Chưa chọn mã nào để in")
					return
				}
	
				for (let i = 0; i < this.selectedUnused.length; i += 2) {
	
					const page = document.createElement("div")
					page.className = "page"
	
					for (let j = 0; j < 2; j++) {
	
						const item = this.selectedUnused[i + j]
						if (!item) break
	
						const label = document.createElement("div")
						label.className = "label"
	
						const temp = document.createElement("div")
	
						$(temp).qrcode({
							text: JSON.stringify({
								maVach_Id: item.Id,
								maVach: item.MaVach,
								diaDiem: this.selectedDiaDiem
							}),
							render: "canvas",
							width: 512,
							height: 512,
							correctLevel: 3
						})
	
						const canvas = temp.querySelector("canvas")
	
						const img = document.createElement("img")
						img.src = canvas.toDataURL("image/png")
						img.className = "qr-img"
	
						const info = document.createElement("div")
						info.className = "asset-info"
	
						info.innerHTML = `
							<div class="asset-code">${item.MaVach}</div>
							<div>${this.tenDiaDiem}</div>
							`
	
						label.appendChild(img)
						label.appendChild(info)
	
						page.appendChild(label)
					}
	
					printArea.appendChild(page)
	
				}
	
				// setTimeout(() => window.print(), 100)
				setTimeout(() => {
					$("#printArea").printThis({
						importCSS: true,
						importStyle: true,
						printContainer: true,
						loadCSS: "", // nếu có css riêng cho print
						pageTitle: "QR Code",
						removeInline: false,
						removeScripts: true
					})
				}, 100)
	
			}
		}
	}
</script>