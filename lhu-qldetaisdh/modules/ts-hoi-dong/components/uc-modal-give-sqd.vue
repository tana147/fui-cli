<template>
	<v-dialog v-model="isOpen" transition="dialog-bottom-transition" max-width="1100px" persistent>
		<v-card class="rounded-xs">
			<c-toolbar @onClose="onClose">
				<template v-slot:title>
					<div class="d-flex align-center">
						<v-icon color="primary" class="mr-2">mdi-file-certificate-outline</v-icon>
						<span class="title primary--text font-weight-bold mb-0">Cập nhật Số Quyết Định Hội Đồng</span>
						<v-chip color="primary" outlined class="ml-3 font-weight-bold" small label>
							{{ HoiDong.Student_ID || dsHocVien.StudentID }}
						</v-chip>
						<span class="ml-2 font-weight-medium text--secondary">
							{{ HoiDong.Ho_SV }} {{ HoiDong.Ten_SV }}
						</span>
						<span v-if="HoiDong.Lop_ID" class="ml-1 amber--text text--darken-3 font-weight-bold">
							[{{ HoiDong.Lop_ID }}]
						</span>
					</div>
				</template>
			</c-toolbar>

			<v-card-text class="pt-4 pb-2">
				<!-- Khối nhập SQĐ & File quyết định -->
				<v-sheet color="blue-grey lighten-5" class="pa-3 rounded-xs mb-3" outlined>
					<v-row dense align="center">
						<v-col cols="12" sm="4">
							<v-text-field
								v-model="dsHocVien.Decision_SoQD"
								outlined
								dense
								hide-details
								label="Số quyết định"
								placeholder="VD: 123/QĐ-ĐHLH"
								class="rounded-xs bg-white"
							/>
						</v-col>

						<v-col cols="12" sm="4">
							<c-text-field-sqd
								outlined
								dense
								hide-details
								label="Ngày quyết định"
								:ngay.sync="dsHocVien.Decision_NgayQD"
								:thang.sync="dsHocVien.Decision_ThangQD"
								:nam.sync="dsHocVien.Decision_NamQD"
								hint="Cú pháp: DDMMYYYY (VD: 28022025)"
								class="rounded-xs bg-white"
							/>
						</v-col>

						<v-col cols="12" sm="4">
							<div class="d-flex align-center">
								<div v-if="dsHocVien.DecisionFile_ID" class="d-flex align-center">
									<v-chip small color="primary" outlined label class="font-weight-medium text-truncate" style="max-width: 260px;">
										<v-icon left x-small>mdi-file-check-outline</v-icon>
										<a
											:href="getFileUrl(dsHocVien.DecisionFile_Url)"
											target="_blank"
											class="text-decoration-none text-truncate"
										>
											{{ dsHocVien.DecisionFile_Name || fileName || 'File quyết định' }}
										</a>
										<v-btn icon x-small class="ml-1" @click="removeFile" title="Xóa file">
											<v-icon x-small>mdi-close</v-icon>
										</v-btn>
									</v-chip>
								</div>
								<div v-else>
									<f-file-upload
										label="Tải file quyết định"
										:url="apiFile"
										:filters="fileRules"
										@input="uploadFile"
										color="primary--text v-btn--outlined v-size--small rounded-xs"
									/>
								</div>
							</div>
						</v-col>
					</v-row>
				</v-sheet>

				<!-- Bảng thành viên hội đồng -->
				<v-card outlined class="rounded-xs">
					<v-data-table
						:headers="councilHeader"
						:items="dsHoiDong"
						item-key="STT"
						hide-default-footer
						dense
						class="elevation-0"
						no-data-text="Chưa có thông tin thành viên hội đồng"
					>
						<template v-slot:item.STT="{ item }">
							<span class="caption text--secondary font-weight-medium">{{ item.STT }}</span>
						</template>

						<template v-slot:item.HoTenHocHamHocVi="{ item }">
							<span class="font-weight-bold text--primary">{{ item.HoTenHocHamHocVi }}</span>
						</template>

						<template v-slot:item.ChucTrach="{ item }">
							<v-chip x-small label outlined color="primary" class="font-weight-medium">
								{{ item.ChucTrach || 'Chưa gán' }}
							</v-chip>
						</template>
					</v-data-table>
				</v-card>
			</v-card-text>

			<v-divider />

			<v-card-actions class="px-4 py-3 bg-grey-lighten-4">
				<v-spacer></v-spacer>
				<v-btn text color="grey darken-1" class="rounded-xs mr-2" @click="onClose">
					<v-icon left small>mdi-close</v-icon>
					Đóng
				</v-btn>
				<v-btn
					color="primary"
					depressed
					class="rounded-xs font-weight-bold"
					:loading="saving"
					@click="onSaveSQD"
				>
					<v-icon left small>mdi-content-save-outline</v-icon>
					Cập nhật SQĐ
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-give-sqd",
		props: {
			value: {
				type: Boolean,
				default: false
			},
			thongtinhocvien: {
				type: Object,
				default: () => ({})
			},
			dsgiangvien: {
				type: Array,
				default: () => []
			},
			editedItem: {
				type: Object,
				default: () => ({})
			}
		},
		emits: ["input", "on-reload"],
		data() {
			return {
				cloneData: null,
				fileName: "",
				saving: false,
				fileRules: {
					max_file_size: "100mb",
					mime_types: [
						{
							title: "All files",
							extensions: "jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg"
						}
					]
				},
				councilHeader: [
					{ text: "STT", value: "STT", width: 50, sortable: false, align: "center" },
					{ text: "Họ và tên", value: "HoTenHocHamHocVi" },
					{ text: "Ngành giảng dạy", value: "NganhGiangDay" },
					{ text: "Cơ quan công tác", value: "CoQuanCongTac" },
					{ text: "Chức trách", value: "ChucTrach", width: 140, align: "center" }
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
				return window.vueData?.v_Set?.apiFile || "https://file.lhu.edu.vn/qldetaisdh/upload/FileData";
			},
			urlReadFile() {
				return window.vueData?.v_Set?.urlReadFile || "https://file.lhu.edu.vn/qldetaisdh/";
			},
			dsHocVien() {
				return this.thongtinhocvien || {};
			},
			dsHoiDong() {
				if (!this.dsgiangvien) return [];
				return this.dsgiangvien
					.filter((item) => item.GiangVienID)
					.map((item, index) => ({
						...item,
						STT: index + 1
					}));
			},
			HoiDong() {
				return this.editedItem || {};
			}
		},
		watch: {
			isOpen(val) {
				if (val) {
					this.cloneData = JSON.parse(JSON.stringify(this.thongtinhocvien || {}));
				}
			}
		},
		methods: {
			getFileUrl(url) {
				if (!url) return "#";
				if (url.startsWith("http://") || url.startsWith("https://")) return url;
				const base = this.urlReadFile ? (this.urlReadFile.endsWith("/") ? this.urlReadFile : this.urlReadFile + "/") : "";
				const cleanUrl = url.startsWith("/") ? url.slice(1) : url;
				return base + cleanUrl;
			},
			removeFile() {
				if (this.dsHocVien.DecisionFile_ID && this.dsHocVien.DecisionFile_ID !== this.cloneData?.DecisionFile_ID) {
					this.deleteFile(this.dsHocVien.DecisionFile_ID);
				}
				this.dsHocVien.DecisionFile_ID = null;
				this.dsHocVien.DecisionFile_Url = null;
				this.dsHocVien.DecisionFile_Name = null;
				this.fileName = null;
			},
			uploadFile(val) {
				if (!val) return;
				const file = (val.Files && val.Files[0]) ? val.Files[0] : (Array.isArray(val) ? val[0] : val);
				if (!file) return;
				const fileId = file.FILE_ID ?? file.File_ID ?? file.id;
				const fileName = file.FILE_NAME ?? file.File_Name ?? file.name;
				const fileUrl = file.FILE_URL ?? file.File_URL ?? (fileId ? "/FileData/" + fileId : null);

				// Nếu đã upload file tạm trước đó trong phiên này thì xóa file tạm đó đi
				if (this.dsHocVien.DecisionFile_ID && this.dsHocVien.DecisionFile_ID !== this.cloneData?.DecisionFile_ID && this.dsHocVien.DecisionFile_ID !== fileId) {
					this.deleteFile(this.dsHocVien.DecisionFile_ID);
				}

				this.dsHocVien.DecisionFile_ID = fileId;
				this.dsHocVien.DecisionFile_Url = fileUrl;
				this.dsHocVien.DecisionFile_Name = fileName;
				this.fileName = fileName;
			},
			async deleteFile(fileID) {
				if (!fileID) return;
				return new Promise((resolve) => {
					ajaxCALL(
						"/FILE_FileDelete",
						{ FileID: fileID },
						() => resolve("success"),
						() => resolve("error")
					);
				});
			},
			async onSaveSQD() {
				if (!this.dsHocVien.Decision_SoQD) {
					Vue.$toast.error("Vui lòng nhập Số quyết định", { position: "top" });
					return;
				}

				this.saving = true;
				try {
					if (this.cloneData && this.cloneData.DecisionFile_ID && this.cloneData.DecisionFile_ID !== this.dsHocVien.DecisionFile_ID) {
						await this.deleteFile(this.cloneData.DecisionFile_ID);
					}

					ajaxCALL(
						"/HoiDong_Upd_SoQD",
						{
							Decision_ID: this.dsHocVien.Decision_ID,
							Decision_SoQD: this.dsHocVien.Decision_SoQD,
							Decision_NgayQD: this.dsHocVien.Decision_NgayQD,
							Decision_ThangQD: this.dsHocVien.Decision_ThangQD,
							Decision_NamQD: this.dsHocVien.Decision_NamQD,
							DecisionFile_ID: this.dsHocVien.DecisionFile_ID,
							DecisionFile_Url: this.dsHocVien.DecisionFile_Url,
							DecisionFile_Name: this.dsHocVien.DecisionFile_Name,
							HoiDong_ID: this.dsHocVien.HoiDongID,
							Student_ID: this.dsHocVien.StudentID || this.HoiDong.Student_ID
						},
						() => {
							this.saving = false;
							Vue.$toast.success("Cập nhật SQĐ thành công", { position: "top" });
							this.$emit("on-reload");
							this.isOpen = false;
						},
						(error) => {
							this.saving = false;
							Vue.$toast.error(error?.responseJSON?.Message || "Lỗi khi cập nhật SQĐ", { position: "top" });
						}
					);
				} catch (e) {
					this.saving = false;
				}
			},
			async onClose() {
				// Xóa file rác nếu đã upload nhưng đóng không lưu
				if (this.dsHocVien.DecisionFile_ID && this.dsHocVien.DecisionFile_ID !== this.cloneData?.DecisionFile_ID) {
					await this.deleteFile(this.dsHocVien.DecisionFile_ID);
				}
				this.isOpen = false;
			}
		}
	}
</script>