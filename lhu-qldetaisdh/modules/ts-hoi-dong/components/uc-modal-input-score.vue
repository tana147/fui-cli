<template>
	<v-dialog v-model="isOpen" transition="dialog-bottom-transition" max-width="1400px" persistent>
		<v-card class="rounded-xs">
			<c-toolbar @onClose="closeDialog">
				<template v-slot:title>
					<div class="d-flex align-center">
						<v-icon color="teal darken-2" class="mr-2">mdi-scoreboard-outline</v-icon>
						<span class="title primary--text font-weight-bold mb-0">Nhập điểm & Biên bản hội đồng</span>
						<v-chip color="primary" outlined class="ml-3 font-weight-bold" small label>
							{{ thongTinHocVien.Student_ID || thongTinHocVien.StudentID }}
						</v-chip>
						<span class="ml-2 font-weight-medium text--secondary">
							{{ thongTinHocVien.Ho_SV }} {{ thongTinHocVien.Ten_SV }}
						</span>
						<span v-if="thongTinHocVien.Lop_ID" class="ml-1 amber--text text--darken-3 font-weight-bold">
							[{{ thongTinHocVien.Lop_ID }}]
						</span>
						<v-chip
							v-if="isPublished"
							small
							color="success"
							class="ml-3 font-weight-bold"
						>
							<v-icon left x-small>mdi-check-decagram</v-icon>
							Đã công bố điểm
						</v-chip>
					</div>
				</template>
			</c-toolbar>

			<v-card-text class="pt-3 pb-1">
				<!-- Banner Biên bản & Điểm trung bình -->
				<v-sheet color="blue-grey lighten-5" class="pa-3 rounded-xs mb-3" outlined>
					<v-row dense align="center">
						<!-- Biên bản họp -->
						<v-col cols="12" sm="4">
							<div class="text-caption grey--text text--darken-2 font-weight-bold text-uppercase mb-1">
								Biên bản họp hội đồng
							</div>
							<div v-if="hoiDongObj.FILE_UPLOAD_HOP && hoiDongObj.FILE_UPLOAD_HOP.File_ID" class="d-flex align-center">
								<v-chip small color="primary" outlined label class="font-weight-medium text-truncate" style="max-width: 280px;">
									<v-icon left x-small>mdi-file-document-outline</v-icon>
									<a :href="getFileUrl(hoiDongObj.FILE_UPLOAD_HOP.File_URL)" target="_blank" class="text-decoration-none text-truncate">
										{{ hoiDongObj.FILE_UPLOAD_HOP.File_Name || 'Xem biên bản họp' }}
									</a>
									<v-btn icon x-small class="ml-1" @click="removeHopFile" v-if="!isPublished" title="Xóa file">
										<v-icon x-small>mdi-close</v-icon>
									</v-btn>
								</v-chip>
							</div>
							<div v-else-if="!isPublished">
								<f-file-upload
									label="Tải lên biên bản họp"
									:url="apiFile"
									:filters="fileRules"
									@input="uploadHopFile"
									color="primary--text v-btn--outlined v-size--small rounded-xs"
								/>
							</div>
							<div v-else class="caption grey--text font-italic">Chưa có biên bản họp</div>
						</v-col>

						<!-- Biên bản kiểm phiếu -->
						<v-col cols="12" sm="4">
							<div class="text-caption grey--text text--darken-2 font-weight-bold text-uppercase mb-1">
								Biên bản kiểm phiếu
							</div>
							<div v-if="hoiDongObj.FILE_UPLOAD_KIEMPHIEU && hoiDongObj.FILE_UPLOAD_KIEMPHIEU.File_ID" class="d-flex align-center">
								<v-chip small color="teal" outlined label class="font-weight-medium text-truncate" style="max-width: 280px;">
									<v-icon left x-small>mdi-file-check-outline</v-icon>
									<a :href="getFileUrl(hoiDongObj.FILE_UPLOAD_KIEMPHIEU.File_URL)" target="_blank" class="text-decoration-none text-truncate">
										{{ hoiDongObj.FILE_UPLOAD_KIEMPHIEU.File_Name || 'Xem biên bản kiểm phiếu' }}
									</a>
									<v-btn icon x-small class="ml-1" @click="removeKiemPhieuFile" v-if="!isPublished" title="Xóa file">
										<v-icon x-small>mdi-close</v-icon>
									</v-btn>
								</v-chip>
							</div>
							<div v-else-if="!isPublished">
								<f-file-upload
									label="Tải biên bản kiểm phiếu"
									:url="apiFile"
									:filters="fileRules"
									@input="uploadKiemPhieuFile"
									color="teal--text v-btn--outlined v-size--small rounded-xs"
								/>
							</div>
							<div v-else class="caption grey--text font-italic">Chưa có biên bản kiểm phiếu</div>
						</v-col>

						<!-- Điểm trung bình -->
						<v-col cols="12" sm="4" class="text-right">
							<div class="text-caption grey--text text--darken-2 font-weight-bold text-uppercase">
								Điểm trung bình hội đồng
							</div>
							<div class="text-h4 font-weight-black red--text text--darken-1">
								{{ isNaN(DiemTrungBinh) ? '0.00' : DiemTrungBinh }}
							</div>
						</v-col>
					</v-row>

					<v-divider class="my-2" />

					<!-- Ghi chú chung -->
					<v-text-field
						v-model="hoiDongObj.NhanXet"
						outlined
						dense
						hide-details
						label="Ghi chú chung của hội đồng"
						placeholder="Nhập ghi chú chung hoặc đánh giá tổng thể..."
						class="rounded-xs bg-white"
						:readonly="isPublished"
					/>
				</v-sheet>

				<!-- Bảng điểm chi tiết từng thành viên -->
				<v-card outlined class="rounded-xs">
					<v-data-table
						:headers="headertable"
						:items="dsHoiDong"
						hide-default-footer
						dense
						class="elevation-0"
						no-data-text="Chưa có thành viên nào trong hội đồng"
					>
						<template v-slot:item.stt="{ index }">
							<span class="caption text--secondary font-weight-medium">{{ index + 1 }}</span>
						</template>

						<template v-slot:item.HoTenHocHamHocVi="{ item }">
							<span class="font-weight-bold text--primary">{{ item.HoTenHocHamHocVi }}</span>
						</template>

						<template v-slot:item.ChucTrach="{ item }">
							<v-chip x-small label outlined color="primary" class="font-weight-medium">
								{{ item.ChucTrach || 'Chưa gán' }}
							</v-chip>
						</template>

						<!-- File nhận xét -->
						<template v-slot:item.FileNhanXet="{ item }">
							<div class="d-flex align-center justify-center py-1">
								<v-chip
									v-if="item.FILE_UPLOAD_NHANXET && item.FILE_UPLOAD_NHANXET.File_ID"
									small
									label
									color="indigo"
									outlined
									class="font-weight-medium text-truncate"
									style="max-width: 160px;"
								>
									<v-icon left x-small>mdi-file-document-outline</v-icon>
									<a :href="getFileUrl(item.FILE_UPLOAD_NHANXET.File_URL)" target="_blank" class="text-decoration-none text-truncate">
										{{ item.FILE_UPLOAD_NHANXET.File_Name || 'Nhận xét' }}
									</a>
									<v-btn icon x-small class="ml-1" @click="item.FILE_UPLOAD_NHANXET = { File_ID: null, File_Name: null, File_URL: null }" v-if="!isPublished">
										<v-icon x-small>mdi-close</v-icon>
									</v-btn>
								</v-chip>
								<f-file-upload
									v-else-if="!isPublished"
									label="Tải file"
									:url="apiFile"
									:filters="fileRules"
									@input="(files) => onUploadMemberFile(item, 'FILE_UPLOAD_NHANXET', files)"
									color="indigo--text v-btn--outlined v-size--small rounded-xs"
								/>
								<span v-else class="caption text--secondary font-italic">-</span>
							</div>
						</template>

						<!-- File điểm -->
						<template v-slot:item.FileDiem="{ item }">
							<div class="d-flex align-center justify-center py-1">
								<v-chip
									v-if="item.FILE_UPLOAD_DIEM && item.FILE_UPLOAD_DIEM.File_ID"
									small
									label
									color="teal"
									outlined
									class="font-weight-medium text-truncate"
									style="max-width: 160px;"
								>
									<v-icon left x-small>mdi-file-table-outline</v-icon>
									<a :href="getFileUrl(item.FILE_UPLOAD_DIEM.File_URL)" target="_blank" class="text-decoration-none text-truncate">
										{{ item.FILE_UPLOAD_DIEM.File_Name || 'Phiếu điểm' }}
									</a>
									<v-btn icon x-small class="ml-1" @click="item.FILE_UPLOAD_DIEM = { File_ID: null, File_Name: null, File_URL: null }" v-if="!isPublished">
										<v-icon x-small>mdi-close</v-icon>
									</v-btn>
								</v-chip>
								<f-file-upload
									v-else-if="!isPublished"
									label="Tải file"
									:url="apiFile"
									:filters="fileRules"
									@input="(files) => onUploadMemberFile(item, 'FILE_UPLOAD_DIEM', files)"
									color="teal--text v-btn--outlined v-size--small rounded-xs"
								/>
								<span v-else class="caption text--secondary font-italic">-</span>
							</div>
						</template>

						<!-- Ô nhập điểm -->
						<template v-slot:item.Diem="{ item }">
							<div class="d-flex align-center justify-center py-1">
								<v-text-field
									v-model="item.Diem"
									type="number"
									step="0.1"
									min="0"
									max="10"
									dense
									outlined
									hide-details
									class="rounded-xs text-center"
									style="max-width: 90px;"
									:readonly="isPublished"
									@input="updateDiem(item)"
									@blur="formatDiem(item)"
								/>
							</div>
						</template>

						<!-- Ghi chú thành viên -->
						<template v-slot:item.NhanXet="{ item }">
							<div class="py-1">
								<v-text-field
									v-model="item.NhanXet"
									dense
									outlined
									hide-details
									placeholder="Nhận xét..."
									class="rounded-xs"
									:readonly="isPublished"
								/>
							</div>
						</template>
					</v-data-table>
				</v-card>
			</v-card-text>

			<v-divider />

			<v-card-actions class="px-4 py-3 bg-grey-lighten-4">
				<v-spacer></v-spacer>
				<v-btn text color="grey darken-1" class="rounded-xs mr-2" @click="closeDialog">
					<v-icon left small>mdi-close</v-icon>
					Đóng
				</v-btn>
				<v-btn
					v-if="!isPublished"
					color="success"
					depressed
					class="rounded-xs font-weight-bold mr-2"
					:loading="saving"
					@click="onSave"
				>
					<v-icon left small>mdi-content-save-outline</v-icon>
					Lưu tạm
				</v-btn>
				<v-btn
					v-if="!isPublished"
					color="warning"
					depressed
					class="rounded-xs font-weight-bold"
					:loading="publishing"
					@click="publicScore"
				>
					<v-icon left small>mdi-check-decagram-outline</v-icon>
					Công bố điểm
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-input-score",
		props: {
			value: {
				type: Boolean,
				default: false
			},
			editedItem: {
				type: Object,
				default: () => ({})
			},
			dshoidonggiangvien: {
				type: Array,
				default: () => []
			},
			getdiem: {
				type: Array,
				default: () => []
			},
			dshoidongId: {
				type: Object,
				default: () => ({})
			}
		},
		emits: ["input", "on-reload"],
		data() {
			return {
				saving: false,
				publishing: false,
				dsHoiDong: [],
				hoiDongObj: {
					FILE_UPLOAD_HOP: { File_ID: null, File_Name: null, File_Type: null, File_URL: null },
					FILE_UPLOAD_KIEMPHIEU: { File_ID: null, File_Name: null, File_Type: null, File_URL: null },
					DiemHoiDong: 0,
					FileNhanXetID: null,
					FileNhanXetName: null,
					Is_PublishDiem: 0,
					FileKiemPhieuID: null,
					FileKiemPhieuName: null,
					NhanXet: ""
				},
				fileRules: {
					max_file_size: "100mb",
					mime_types: [{ title: "All files", extensions: "jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg" }]
				},
				headertable: [
					{ text: "STT", value: "stt", sortable: false, align: "center", width: 45 },
					{ text: "Thành viên", value: "HoTenHocHamHocVi", width: 180 },
					{ text: "Chức trách", value: "ChucTrach", width: 110, align: "center" },
					{ text: "File nhận xét", value: "FileNhanXet", align: "center", sortable: false, width: 180 },
					{ text: "File Điểm", value: "FileDiem", align: "center", sortable: false, width: 180 },
					{ text: "Điểm", value: "Diem", align: "center", sortable: false, width: 100 },
					{ text: "Ghi chú", value: "NhanXet", sortable: false }
				]
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
			apiFile() {
				return window.vueData?.v_Set?.apiFile || "";
			},
			urlReadFile() {
				return window.vueData?.v_Set?.urlReadFile || "";
			},
			thongTinHocVien() {
				return this.editedItem || {};
			},
			isPublished() {
				return (
					this.dshoidongId?.Is_PublishDiem === 1 ||
					this.thongTinHocVien?.Is_PublishDiem === 1 ||
					this.hoiDongObj.Is_PublishDiem === 1
				);
			},
			DiemTrungBinh() {
				const filterDiem = (this.dsHoiDong || []).filter(
					(item) => item.Diem !== null && item.Diem !== undefined && parseFloat(item.Diem) > 0
				);
				if (filterDiem.length === 0) return "0.00";
				const sum = filterDiem.reduce((acc, cur) => acc + parseFloat(cur.Diem), 0);
				return (sum / filterDiem.length).toFixed(2);
			}
		},
		watch: {
			isOpen(val) {
				if (val) {
					this.initFromProps();
				}
			},
			getdiem: {
				handler() {
					if (this.isOpen) {
						this.initFromProps();
					}
				},
				deep: true
			}
		},
		methods: {
			closeDialog() {
				this.isOpen = false;
			},
			getFileUrl(url) {
				if (!url) return "#";
				if (url.startsWith("http://") || url.startsWith("https://")) return url;
				const base = this.urlReadFile ? (this.urlReadFile.endsWith("/") ? this.urlReadFile : this.urlReadFile + "/") : "";
				const cleanUrl = url.startsWith("/") ? url.slice(1) : url;
				return base + cleanUrl;
			},
			extractFileData(val) {
				if (!val) return null;
				const file = (val.Files && val.Files[0]) ? val.Files[0] : (Array.isArray(val) ? val[0] : val);
				if (!file) return null;
				const fileId = file.FILE_ID ?? file.File_ID ?? file.id ?? null;
				const fileName = file.FILE_NAME ?? file.File_Name ?? file.name ?? null;
				const fileType = file.FILE_CONTENTTYPE ?? file.File_Type ?? file.type ?? "pdf";
				const fileUrl = file.FILE_URL ?? file.File_URL ?? (fileId ? "/FileData/" + fileId : null);
				if (!fileId && !fileUrl && !fileName) return null;
				return {
					File_ID: fileId,
					File_Name: fileName,
					File_Type: fileType,
					File_URL: fileUrl
				};
			},
			uploadHopFile(val) {
				const data = this.extractFileData(val);
				if (data) {
					this.hoiDongObj.FILE_UPLOAD_HOP = data;
				}
			},
			removeHopFile() {
				this.hoiDongObj.FILE_UPLOAD_HOP = { File_ID: null, File_Name: null, File_Type: null, File_URL: null };
			},
			uploadKiemPhieuFile(val) {
				const data = this.extractFileData(val);
				if (data) {
					this.hoiDongObj.FILE_UPLOAD_KIEMPHIEU = data;
				}
			},
			removeKiemPhieuFile() {
				this.hoiDongObj.FILE_UPLOAD_KIEMPHIEU = { File_ID: null, File_Name: null, File_Type: null, File_URL: null };
			},
			onUploadMemberFile(item, field, val) {
				const data = this.extractFileData(val);
				if (data) {
					item[field] = data;
				}
			},
			updateDiem(item) {
				if (item.Diem !== null && item.Diem !== undefined && item.Diem !== "") {
					item.Diem = Number(item.Diem);
				}
			},
			formatDiem(item) {
				if (item.Diem !== null && item.Diem !== undefined && item.Diem !== "") {
					item.Diem = Number(item.Diem).toFixed(2);
				}
			},
			sortThanhVien(arr) {
				if (!Array.isArray(arr)) return arr;
				if (arr.length === 3) {
					const order = ["Chủ tịch", "Phản biện 1", "Thư ký"];
					return arr.slice().sort((a, b) => order.indexOf(a.ChucTrach) - order.indexOf(b.ChucTrach));
				}
				if (arr.length === 5) {
					const order = ["Chủ tịch", "Phản biện 1", "Phản biện 2", "Ủy viên", "Thư ký"];
					return arr.slice().sort((a, b) => order.indexOf(a.ChucTrach) - order.indexOf(b.ChucTrach));
				}
				return arr;
			},
			initFromProps() {
				// 1. Map biên bản họp & kiểm phiếu từ getdiem[0]
				if (this.getdiem && this.getdiem[0] && this.getdiem[0][0]) {
					const diemHop = this.getdiem[0][0];
					this.hoiDongObj.NhanXet = diemHop.NhanXet || "";
					this.hoiDongObj.Is_PublishDiem = diemHop.Is_PublishDiem || 0;
					this.hoiDongObj.FILE_UPLOAD_HOP = {
						File_ID: diemHop.FileNhanXetID || null,
						File_Name: diemHop.FileNhanXetName || null,
						File_URL: diemHop.FileNhanXetURL || null,
						File_Type: diemHop.FileNhanXetType || "pdf"
					};
					this.hoiDongObj.FILE_UPLOAD_KIEMPHIEU = {
						File_ID: diemHop.FileKiemPhieuID || null,
						File_Name: diemHop.FileKiemPhieuName || null,
						File_URL: diemHop.FileKiemPhieuURL || null,
						File_Type: diemHop.FileKiemPhieuType || "pdf"
					};
				}

				// 2. Map thành viên & điểm từ dshoidonggiangvien và getdiem[1]
				let baseMembers = (this.dshoidonggiangvien || []).filter((item) => item.GiangVienID);
				const diemMembers = (this.getdiem && this.getdiem[1]) || [];

				this.dsHoiDong = baseMembers.map((item) => {
					const gvDiem = diemMembers.find((d) => d.GiangVienID === item.GiangVienID);
					return {
						...item,
						HoTenHocHamHocVi: `${item.HocViHocHam ? item.HocViHocHam + ". " : ""}${item.HoTenGiangVien || ""}`,
						Diem: gvDiem ? gvDiem.Diem : item.Diem,
						NhanXet: gvDiem ? gvDiem.NhanXet : item.NhanXet,
						FILE_UPLOAD_NHANXET: {
							File_ID: gvDiem?.FileNhanXetID || null,
							File_Name: gvDiem?.FileNhanXetName || null,
							File_URL: gvDiem?.FileNhanXetURL || null,
							File_Type: "pdf"
						},
						FILE_UPLOAD_DIEM: {
							File_ID: gvDiem?.FileDiemID || null,
							File_Name: gvDiem?.FileDiemName || null,
							File_URL: gvDiem?.FileDiemURL || null,
							File_Type: "pdf"
						}
					};
				});

				this.dsHoiDong = this.sortThanhVien(this.dsHoiDong);
			},
			async onSave() {
				this.hoiDongObj.FileNhanXetID = this.hoiDongObj.FILE_UPLOAD_HOP?.File_ID || null;
				this.hoiDongObj.FileNhanXetName = this.hoiDongObj.FILE_UPLOAD_HOP?.File_Name || null;
				this.hoiDongObj.FileKiemPhieuID = this.hoiDongObj.FILE_UPLOAD_KIEMPHIEU?.File_ID || null;
				this.hoiDongObj.FileKiemPhieuName = this.hoiDongObj.FILE_UPLOAD_KIEMPHIEU?.File_Name || null;

				this.dsHoiDong.forEach((item) => {
					item.FileNhanXetID = item.FILE_UPLOAD_NHANXET?.File_ID || null;
					item.FileNhanXetName = item.FILE_UPLOAD_NHANXET?.File_Name || null;
					item.FileDiemID = item.FILE_UPLOAD_DIEM?.File_ID || null;
					item.FileDiemName = item.FILE_UPLOAD_DIEM?.File_Name || null;
				});

				const hoiDongId = this.thongTinHocVien.HoiDongID || this.thongTinHocVien.HoiDong_ID;
				const studentId = this.thongTinHocVien.Student_ID || this.thongTinHocVien.StudentID;

				this.saving = true;
				try {
					await ajaxCALLPromise("/HoiDong_GiangVien_Upd_Diem", {
						HoiDongID: hoiDongId,
						StudentID: studentId,
						DiemHoiDongObj: this.hoiDongObj,
						HoiDongThanhVienObj_Arr: this.dsHoiDong
					});

					Vue.$toast.success("Lưu điểm thành công", { position: "top" });
					this.$emit("on-reload");
					this.closeDialog();
				} catch (error) {
					console.error("Save score error:", error);
					Vue.$toast.error(`${error?.responseJSON?.Message || error}`, { position: "top" });
				} finally {
					this.saving = false;
				}
			},
			async publicScore() {
				if (!this.hoiDongObj.FILE_UPLOAD_HOP?.File_ID && !this.hoiDongObj.FILE_UPLOAD_KIEMPHIEU?.File_ID) {
					Vue.$toast.error("Vui lòng tải lên biên bản họp hoặc kiểm phiếu trước khi công bố", { position: "top" });
					return;
				}

				for (const item of this.dsHoiDong) {
					if (item.Diem === null || item.Diem === undefined || item.Diem === "") {
						Vue.$toast.error(`Giảng viên ${item.HoTenHocHamHocVi} chưa được nhập điểm`, { position: "top" });
						return;
					}
				}

				const hoiDongId = this.thongTinHocVien.HoiDongID || this.thongTinHocVien.HoiDong_ID;
				const studentId = this.thongTinHocVien.Student_ID || this.thongTinHocVien.StudentID;

				this.publishing = true;
				try {
					await this.onSave();
					await ajaxCALLPromise("/HoiDong_Pub_Diem", {
						HoiDong_ID: hoiDongId,
						Student_ID: studentId
					});

					Vue.$toast.success("Công bố điểm thành công", { position: "top" });
					this.$emit("on-reload");
					this.closeDialog();
				} catch (error) {
					console.error("Publish score error:", error);
					Vue.$toast.error(`${error?.responseJSON?.Message || error}`, { position: "top" });
				} finally {
					this.publishing = false;
				}
			}
		}
	}
</script>