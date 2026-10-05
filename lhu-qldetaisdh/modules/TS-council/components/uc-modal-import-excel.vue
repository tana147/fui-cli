<template>
	<v-dialog persistent eager v-model="isOpen" transition="dialog-bottom-transition" max-width="1700px">
		<v-card class="rounded-xs">
			<!-- Header Toolbar -->
			<c-toolbar @onClose="closeDialog">
				<template v-slot:title>
					<div class="d-flex align-center flex-wrap">
						<v-icon color="success" class="mr-2">mdi-file-excel-box</v-icon>
						<span class="title primary--text font-weight-bold mb-0">Lập danh sách hội đồng bằng File Excel</span>
						
						<!-- Nút tải template mẫu -->
						<v-btn color="primary" outlined small class="ml-4 text-none font-weight-bold rounded-xs" @click="downloadTemplate(3)">
							<v-icon left small>mdi-download</v-icon> Template 3 thành viên (Chuyên đề)
						</v-btn>
						<v-btn color="primary" outlined small class="ml-2 text-none font-weight-bold rounded-xs" @click="downloadTemplate(5)">
							<v-icon left small>mdi-download</v-icon> Template 5 thành viên (Luận án TS)
						</v-btn>
					</div>
				</template>
			</c-toolbar>

			<v-card-text class="pt-4 pb-2">
				<!-- Khối cấu hình & Chọn file -->
				<v-sheet color="blue-grey lighten-5" class="pa-3 rounded-xs mb-3" outlined>
					<v-row dense align="center">
						<v-col cols="12" md="3">
							<v-select
								v-model="selectedLoaiHoiDong"
								:items="dsLoaiHoiDong"
								item-text="name"
								item-value="id"
								outlined
								dense
								hide-details
								label="Loại hội đồng"
								prepend-inner-icon="mdi-format-list-checks"
								class="rounded-xs bg-white"
							/>
						</v-col>
						<v-col cols="12" md="3">
							<v-select
								v-model="templateType"
								:items="dsTemplateType"
								item-text="name"
								item-value="id"
								outlined
								dense
								hide-details
								label="Cơ cấu hội đồng"
								prepend-inner-icon="mdi-account-group"
								class="rounded-xs bg-white"
							/>
						</v-col>
						<v-col cols="12" md="3">
							<v-file-input
								v-model="fileUpload"
								dense
								hide-details
								accept=".xlsx, .xls, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/vnd.ms-excel"
								label="Chọn file Excel để import"
								outlined
								prepend-icon=""
								prepend-inner-icon="mdi-file-upload-outline"
								clearable
								@change="onFileChange"
								class="rounded-xs bg-white"
							/>
						</v-col>
						<v-col cols="12" md="3">
							<f-date
								v-model="councilTime"
								color="primary"
								label="Ngày bảo vệ"
								placeholder="Chọn ngày bảo vệ"
								outlined
								dense
								hide-details
								prepend-inner-icon="mdi-calendar"
								class="rounded-xs bg-white"
							/>
						</v-col>
					</v-row>
				</v-sheet>

				<!-- Bảng xem trước dữ liệu từ Excel -->
				<v-card outlined class="rounded-xs">
					<v-card-title class="py-2 px-3 grey lighten-4 d-flex align-center flex-wrap" style="min-height: 52px;">
						<v-icon color="primary" small class="mr-1">mdi-table-check</v-icon>
						<span class="subtitle-2 font-weight-bold primary--text">Dữ liệu đọc từ Excel</span>
						
						<!-- Thống kê trạng thái -->
						<v-chip small color="primary" outlined class="ml-2 font-weight-bold" label>
							Tổng: {{ parsedList.length }} dòng
						</v-chip>
						<v-chip small color="success" outlined class="ml-2 font-weight-bold" label v-if="parsedList.length > 0">
							<v-icon left x-small>mdi-check-circle</v-icon> Hợp lệ: {{ validRowsCount }}
						</v-chip>
						<v-chip small color="error" outlined class="ml-2 font-weight-bold" label v-if="invalidRowsCount > 0">
							<v-icon left x-small>mdi-alert-circle</v-icon> Lỗi: {{ invalidRowsCount }}
						</v-chip>

						<v-spacer></v-spacer>
						<div style="width: 250px;">
							<v-text-field
								v-model="searchPreview"
								prepend-inner-icon="mdi-magnify"
								label="Tìm kiếm nhanh..."
								outlined
								dense
								single-line
								hide-details
								class="rounded-xs bg-white"
							/>
						</div>
					</v-card-title>

					<v-data-table
						:headers="currentHeaders"
						:items="parsedList"
						:search="searchPreview"
						class="elevation-0"
						:items-per-page="50"
						height="420"
						fixed-header
						dense
						no-data-text="Chưa có dữ liệu. Vui lòng tải template mẫu, điền dữ liệu và chọn file Excel để tải lên."
					>
						<template v-slot:item.STT="{ index }">
							<span class="font-weight-bold text--secondary caption">{{ index + 1 }}</span>
						</template>

						<!-- Cột trạng thái kiểm tra -->
						<template v-slot:item.Status="{ item }">
							<v-tooltip bottom v-if="!item.isValid">
								<template v-slot:activator="{ on, attrs }">
									<v-chip x-small label color="error" class="font-weight-bold" v-bind="attrs" v-on="on">
										<v-icon left x-small>mdi-alert-circle</v-icon> Lỗi dữ liệu
									</v-chip>
								</template>
								<div>
									<div v-for="(err, i) in item.errors" :key="i">• {{ err }}</div>
								</div>
							</v-tooltip>
							<v-chip x-small label color="success" class="font-weight-bold" v-else>
								<v-icon left x-small>mdi-check-circle</v-icon> Hợp lệ
							</v-chip>
						</template>

						<!-- Cột Học viên -->
						<template v-slot:item.Student_ID="{ item }">
							<div class="font-weight-bold primary--text">{{ item.Ho_SV }} {{ item.Ten_SV }}</div>
							<div class="caption font-weight-bold text--secondary">
								{{ item.Student_ID }} <span v-if="item.Lop_ID" class="amber--text text--darken-3">[{{ item.Lop_ID }}]</span>
							</div>
						</template>

						<!-- Cột Tên đề tài -->
						<template v-slot:item.Thesis_Name="{ item }">
							<div class="text-caption font-weight-medium">{{ item.Thesis_Name || 'Chưa có' }}</div>
						</template>

						<!-- Cột GVHD -->
						<template v-slot:item.GVHD="{ item }">
							<div class="text-caption">
								<div>{{ item.GVHD1 || 'Chưa có' }}</div>
								<div v-if="item.GVHD2" class="text--secondary">{{ item.GVHD2 }}</div>
							</div>
						</template>

						<!-- Các cột thành viên hội đồng -->
						<template v-slot:item.ChuTich="{ item }">
							<div :class="item.ChuTichObj ? 'font-weight-bold text--primary caption' : 'red--text text-caption font-weight-bold'">
								{{ item.ChuTich || 'Trống' }}
								<v-icon v-if="!item.ChuTichObj" x-small color="error">mdi-alert</v-icon>
							</div>
						</template>

						<template v-slot:item.PhanBien1="{ item }">
							<div :class="item.PB1Obj ? 'font-weight-bold text--primary caption' : 'red--text text-caption font-weight-bold'">
								{{ item.PhanBien1 || item.PhanBien || 'Trống' }}
								<v-icon v-if="!item.PB1Obj" x-small color="error">mdi-alert</v-icon>
							</div>
						</template>

						<template v-slot:item.PhanBien2="{ item }">
							<div :class="item.PB2Obj ? 'font-weight-bold text--primary caption' : 'red--text text-caption font-weight-bold'">
								{{ item.PhanBien2 || 'Trống' }}
								<v-icon v-if="!item.PB2Obj" x-small color="error">mdi-alert</v-icon>
							</div>
						</template>

						<template v-slot:item.UyVien="{ item }">
							<div :class="item.UyVienObj ? 'font-weight-bold text--primary caption' : 'red--text text-caption font-weight-bold'">
								{{ item.UyVien || 'Trống' }}
								<v-icon v-if="!item.UyVienObj" x-small color="error">mdi-alert</v-icon>
							</div>
						</template>

						<template v-slot:item.ThuKy="{ item }">
							<div :class="item.ThuKyObj ? 'font-weight-bold text--primary caption' : 'red--text text-caption font-weight-bold'">
								{{ item.ThuKy || 'Trống' }}
								<v-icon v-if="!item.ThuKyObj" x-small color="error">mdi-alert</v-icon>
							</div>
						</template>
					</v-data-table>
				</v-card>
			</v-card-text>

			<v-divider></v-divider>

			<!-- Actions Footer -->
			<v-card-actions class="px-4 py-3 bg-grey-lighten-4">
				<span class="caption text--secondary font-italic">
					* Chỉ các dòng dữ liệu hợp lệ (tất cả thành viên hội đồng được nhận diện chính xác) mới được lập hội đồng.
				</span>
				<v-spacer></v-spacer>
				<v-btn text color="grey darken-1" class="rounded-xs mr-2" @click="closeDialog">
					<v-icon left small>mdi-close</v-icon> Đóng
				</v-btn>
				<v-btn
					:disabled="validRowsCount === 0 || !councilTime || isImporting"
					color="primary"
					depressed
					class="rounded-xs px-4 font-weight-bold"
					:loading="isImporting"
					@click="importCouncilData"
				>
					<v-icon left small>mdi-content-save-all</v-icon> Nhập vào hệ thống ({{ validRowsCount }} hội đồng)
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-import-excel",
		props: {
			value: {
				type: Boolean,
				default: false
			},
			dshoidonggiangvien: {
				type: Array,
				default: () => []
			},
			dsdetai: {
				type: Array,
				default: () => []
			},
			hearr: {
				type: Array,
				default: () => []
			},
			dshdchuctrach: {
				type: Array,
				default: () => []
			}
		},
		emits: ["input", "on-reload"],
		data() {
			return {
				selectedLoaiHoiDong: 2,
				templateType: 3,
				dsLoaiHoiDong: [
					{ id: 2, name: "Chuyên đề 1 NCS", minMembers: 3 },
					{ id: 3, name: "Chuyên đề 2 NCS", minMembers: 3 },
					{ id: 4, name: "Chuyên đề 3 NCS", minMembers: 3 },
					{ id: 5, name: "Luận án TS", minMembers: 5 }
				],
				dsTemplateType: [
					{ id: 3, name: "Hội đồng 3 thành viên (Chuyên đề NCS)" },
					{ id: 5, name: "Hội đồng 5 thành viên (Luận án TS)" }
				],
				fileUpload: null,
				councilTime: "",
				parsedList: [],
				searchPreview: "",
				isImporting: false
			};
		},
		computed: {
			isOpen: {
				get() {
					return this.value;
				},
				set(val) {
					this.$emit("input", val);
				}
			},
			validRowsCount() {
				return this.parsedList.filter((r) => r.isValid).length;
			},
			invalidRowsCount() {
				return this.parsedList.filter((r) => !r.isValid).length;
			},
			currentHeaders() {
				const base = [
					{ text: "STT", value: "STT", align: "center", width: 45, sortable: false },
					{ text: "Trạng thái", value: "Status", align: "center", width: 110 },
					{ text: "Học viên", value: "Student_ID", width: 170 },
					{ text: "Tên đề tài / Luận án", value: "Thesis_Name", minWidth: 200 },
					{ text: "GVHD", value: "GVHD", width: 150 },
					{ text: "Chủ tịch", value: "ChuTich", width: 170 },
					{ text: this.templateType === 3 ? "Phản biện" : "Phản biện 1", value: "PhanBien1", width: 170 }
				];

				if (this.templateType === 5) {
					base.push(
						{ text: "Phản biện 2", value: "PhanBien2", width: 170 },
						{ text: "Ủy viên", value: "UyVien", width: 170 }
					);
				}

				base.push({ text: "Thư ký", value: "ThuKy", width: 170 });
				return base;
			}
		},
		watch: {
			selectedLoaiHoiDong(val) {
				this.templateType = val === 5 ? 5 : 3;
				if (this.fileUpload) {
					this.parseExcel(this.fileUpload);
				}
			},
			templateType() {
				if (this.fileUpload) {
					this.parseExcel(this.fileUpload);
				}
			}
		},
		methods: {
			cleanString(str) {
				if (!str) return "";
				return str
					.toString()
					.normalize("NFD")
					.replace(/[\u0300-\u036f]/g, "")
					.replace(/[^a-zA-Z0-9]/g, "")
					.toUpperCase();
			},
			findLecturer(name) {
				if (!name) return null;
				const cleanTarget = this.cleanString(name);
				const gvList = this.dshoidonggiangvien || [];

				// 1. Khớp nguyên văn HoTenHocHamHocVi
				let found = gvList.find((gv) => this.cleanString(gv.HoTenHocHamHocVi) === cleanTarget);
				if (found) return found;

				// 2. Khớp nguyên văn HoTenGiangVien
				found = gvList.find((gv) => this.cleanString(gv.HoTenGiangVien) === cleanTarget);
				if (found) return found;

				// 3. Khớp chuỗi chứa
				found = gvList.find((gv) => {
					const cleanGVName = this.cleanString(gv.HoTenGiangVien);
					return cleanGVName.length >= 4 && (cleanTarget.includes(cleanGVName) || cleanGVName.includes(cleanTarget));
				});
				return found || null;
			},
			ensureXLSX() {
				if (typeof XLSX !== "undefined") return Promise.resolve(true);
				return new Promise((resolve) => {
					const script = document.createElement("script");
					script.src = "https://cdn.jsdelivr.net/npm/xlsx-js-style@1.2.0/dist/xlsx.min.js";
					script.onload = () => resolve(true);
					script.onerror = () => {
						Vue.$toast.error("Không thể tải thư viện XLSX. Vui lòng kiểm tra kết nối mạng.", { position: "top" });
						resolve(false);
					};
					document.head.appendChild(script);
				});
			},
			async downloadTemplate(type) {
				const isReady = await this.ensureXLSX();
				if (!isReady || typeof XLSX === "undefined") {
					Vue.$toast.error("Thư viện Excel (XLSX) chưa sẵn sàng trên trình duyệt", { position: "top" });
					return;
				}

				const wb = XLSX.utils.book_new();
				let data = [];
				let fileName = "";

				if (type === 3) {
					fileName = "Template_HoiDong_ChuyenDe_3_ThanhVien.xlsx";
					data = [
						["STT", "Mã NCS", "Họ đệm", "Tên", "Lớp", "Tên đề tài", "GVHD 1", "GVHD 2", "Chủ tịch", "Phản biện", "Thư ký"],
						["1", "991000001", "Nguyễn Văn", "A", "21TS111", "Nghiên cứu ứng dụng trí tuệ nhân tạo", "PGS.TS. Trần Văn Lăng", "", "PGS.TS. Lâm Thành Hiển", "PGS.TS. Vũ Đức Lung", "TS. Huỳnh Cao Tuấn"],
						["2", "991000002", "Trần Thị", "B", "21TS111", "Phân tích dữ liệu lớn trong y tế", "PGS.TS. Lâm Thành Hiển", "", "PGS.TS. Trần Văn Lăng", "TS. Nguyễn Quốc Chính", "TS. Lê Hoàng Anh"]
					];
				} else {
					fileName = "Template_HoiDong_LuanAn_5_ThanhVien.xlsx";
					data = [
						["STT", "Mã NCS", "Họ đệm", "Tên", "Lớp", "Tên đề tài", "GVHD 1", "GVHD 2", "Chủ tịch", "Phản biện 1", "Phản biện 2", "Ủy viên", "Thư ký"],
						["1", "991000001", "Nguyễn Văn", "A", "21TS111", "Nghiên cứu mô hình học sâu trong xử lý ảnh y khoa", "PGS.TS. Trần Văn Lăng", "", "PGS.TS. Lâm Thành Hiển", "PGS.TS. Vũ Đức Lung", "TS. Huỳnh Cao Tuấn", "TS. Nguyễn Quốc Chính", "TS. Lê Hoàng Anh"],
						["2", "991000002", "Trần Thị", "B", "21TS111", "Nghiên cứu tối ưu hóa hiệu năng hệ thống phân tán", "PGS.TS. Lâm Thành Hiển", "", "PGS.TS. Trần Văn Lăng", "TS. Nguyễn Quốc Chính", "TS. Lê Hoàng Anh", "TS. Huỳnh Cao Tuấn", "PGS.TS. Vũ Đức Lung"]
					];
				}

				const ws = XLSX.utils.aoa_to_sheet(data);
				ws["!cols"] = [
					{ wch: 6 },
					{ wch: 14 },
					{ wch: 16 },
					{ wch: 10 },
					{ wch: 12 },
					{ wch: 45 },
					{ wch: 25 },
					{ wch: 20 },
					{ wch: 25 },
					{ wch: 25 },
					...(type === 5 ? [{ wch: 25 }, { wch: 25 }] : []),
					{ wch: 25 }
				];
				XLSX.utils.book_append_sheet(wb, ws, "DanhSachHoiDong");
				XLSX.writeFile(wb, fileName);
				Vue.$toast.success("Đã tải xuống template mẫu: " + fileName, { position: "top" });
			},
			onFileChange(file) {
				if (file) {
					this.parseExcel(file);
				} else {
					this.parsedList = [];
				}
			},
			async parseExcel(file) {
				if (!file) return;
				const isReady = await this.ensureXLSX();
				if (!isReady || typeof XLSX === "undefined") {
					Vue.$toast.error("Thư viện Excel (XLSX) chưa sẵn sàng trên trình duyệt", { position: "top" });
					return;
				}
				const reader = new FileReader();
				reader.onload = (e) => {
					try {
						const arrayBuffer = e.target.result;
						const workbook = XLSX.read(arrayBuffer, { type: "array" });
						const firstSheetName = workbook.SheetNames[0];
						const worksheet = workbook.Sheets[firstSheetName];
						const rawData = XLSX.utils.sheet_to_json(worksheet, { header: 1, defval: "" });

						if (!rawData || rawData.length === 0) {
							Vue.$toast.error("File Excel không có dữ liệu", { position: "top" });
							this.parsedList = [];
							return;
						}

						let headerRowIndex = 0;
						for (let i = 0; i < Math.min(10, rawData.length); i++) {
							const rowStr = rawData[i].map((c) => (c || "").toString().toUpperCase()).join(" ");
							if (rowStr.includes("STT") || rowStr.includes("MA") || rowStr.includes("NCS") || rowStr.includes("CHU TICH")) {
								headerRowIndex = i;
								break;
							}
						}

						const rows = rawData.slice(headerRowIndex + 1);
						const result = [];

						for (let i = 0; i < rows.length; i++) {
							const r = rows[i];
							if (!r || r.length === 0 || !r[1]) continue;

							const studentId = (r[1] || "").toString().trim();
							const hoSV = (r[2] || "").toString().trim();
							const tenSV = (r[3] || "").toString().trim();
							const lopID = (r[4] || "").toString().trim();
							const thesisName = (r[5] || "").toString().trim();
							const gvhd1 = (r[6] || "").toString().trim();
							const gvhd2 = (r[7] || "").toString().trim();

							let chuTich = "", pb1 = "", pb2 = "", uyVien = "", thuKy = "";

							if (this.templateType === 3) {
								chuTich = (r[8] || "").toString().trim();
								pb1 = (r[9] || "").toString().trim();
								thuKy = (r[10] || "").toString().trim();
							} else {
								chuTich = (r[8] || "").toString().trim();
								pb1 = (r[9] || "").toString().trim();
								pb2 = (r[10] || "").toString().trim();
								uyVien = (r[11] || "").toString().trim();
								thuKy = (r[12] || "").toString().trim();
							}

							const chuTichObj = this.findLecturer(chuTich);
							const pb1Obj = this.findLecturer(pb1);
							const pb2Obj = this.templateType === 5 ? this.findLecturer(pb2) : null;
							const uyVienObj = this.templateType === 5 ? this.findLecturer(uyVien) : null;
							const thuKyObj = this.findLecturer(thuKy);

							const errors = [];
							if (!studentId) errors.push("Thiếu Mã NCS");
							if (!chuTichObj) errors.push(`Không nhận diện được Chủ tịch: "${chuTich || "Trống"}"`);
							if (!pb1Obj) errors.push(`Không nhận diện được Phản biện: "${pb1 || "Trống"}"`);
							if (this.templateType === 5) {
								if (!pb2Obj) errors.push(`Không nhận diện được Phản biện 2: "${pb2 || "Trống"}"`);
								if (!uyVienObj) errors.push(`Không nhận diện được Ủy viên: "${uyVien || "Trống"}"`);
							}
							if (!thuKyObj) errors.push(`Không nhận diện được Thư ký: "${thuKy || "Trống"}"`);

							const assignedMembers = [
								chuTichObj ? { ...chuTichObj, ChucTrach: "Chủ tịch" } : null,
								pb1Obj ? { ...pb1Obj, ChucTrach: "Phản biện 1" } : null,
								...(this.templateType === 5 ? [
									pb2Obj ? { ...pb2Obj, ChucTrach: "Phản biện 2" } : null,
									uyVienObj ? { ...uyVienObj, ChucTrach: "Ủy viên" } : null
								] : []),
								thuKyObj ? { ...thuKyObj, ChucTrach: "Thư ký" } : null
							].filter(Boolean);

							const ids = assignedMembers.map((m) => m.GiangVienID);
							const hasDuplicate = new Set(ids).size !== ids.length;
							if (hasDuplicate) {
								errors.push("Trùng giảng viên trong cùng một hội đồng");
							}

							result.push({
								STT: i + 1,
								Student_ID: studentId,
								Ho_SV: hoSV,
								Ten_SV: tenSV,
								Lop_ID: lopID,
								Thesis_Name: thesisName,
								GVHD1: gvhd1,
								GVHD2: gvhd2,
								ChuTich: chuTich,
								PhanBien1: pb1,
								PhanBien2: pb2,
								UyVien: uyVien,
								ThuKy: thuKy,
								ChuTichObj: chuTichObj,
								PB1Obj: pb1Obj,
								PB2Obj: pb2Obj,
								UyVienObj: uyVienObj,
								ThuKyObj: thuKyObj,
								HoiDongThanhVienObj_Arr: assignedMembers,
								isValid: errors.length === 0,
								errors: errors
							});
						}

						this.parsedList = result;
						if (result.length > 0) {
							Vue.$toast.success(`Đã đọc ${result.length} dòng từ file Excel`, { position: "top" });
						} else {
							Vue.$toast.warning("Không tìm thấy dòng dữ liệu học viên nào trong file", { position: "top" });
						}
					} catch (err) {
						console.error("Lỗi khi đọc file Excel:", err);
						Vue.$toast.error("Không thể đọc file Excel: " + (err.message || err), { position: "top" });
					}
				};
				reader.readAsArrayBuffer(file);
			},
			async importCouncilData() {
				if (!this.councilTime) {
					Vue.$toast.error("Vui lòng chọn Ngày bảo vệ", { position: "top" });
					return;
				}

				const validRows = this.parsedList.filter((r) => r.isValid);
				if (validRows.length === 0) {
					Vue.$toast.error("Không có dòng dữ liệu hợp lệ nào để nhập", { position: "top" });
					return;
				}

				this.isImporting = true;
				let successCount = 0;
				let failCount = 0;

				for (const row of validRows) {
					try {
						await new Promise((resolve, reject) => {
							ajaxCALL(
								"/HoiDong_Ins",
								{
									Student_ID: row.Student_ID,
									HoiDongThanhVienObj_Arr: row.HoiDongThanhVienObj_Arr,
									ThoiGianBaoVe: this.councilTime,
									LoaiHoiDong: this.selectedLoaiHoiDong
								},
								(res) => resolve(res),
								(err) => reject(err)
							);
						});
						successCount++;
					} catch (err) {
						failCount++;
						console.error("Lỗi import hội đồng cho NCS " + row.Student_ID, err);
					}
				}

				this.isImporting = false;
				if (successCount > 0) {
					Vue.$toast.success(`Đã lập thành công ${successCount} hội đồng`, { position: "top" });
					this.$emit("on-reload");
					this.closeDialog();
				} else {
					Vue.$toast.error(`Lập hội đồng thất bại (${failCount} lỗi)`, { position: "top" });
				}
			},
			closeDialog() {
				this.isOpen = false;
				this.fileUpload = null;
				this.parsedList = [];
			}
		}
	}
</script>