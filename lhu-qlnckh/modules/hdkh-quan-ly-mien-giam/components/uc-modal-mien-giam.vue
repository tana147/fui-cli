<template>
	<v-dialog v-model="dialog" max-width="1000px" persistent>
		<v-card>
			<v-toolbar dense flat>
				<v-toolbar-title>Chi tiết miễn giảm: {{ nhanVien ? nhanVien.HoTen : '' }}</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon variant="text" @click="closeDialog">
					<v-icon>mdi-close</v-icon>
				</v-btn>
			</v-toolbar>
			<v-card-text class="pt-4">
				<div class="d-flex mb-3 align-center ga-3">
					<v-spacer></v-spacer>
					<v-text-field v-model="search" variant="underlined" prepend-inner-icon="mdi-filter-outline"
						label="Tìm kiếm" single-line hide-details dense style="max-width: 300px;"></v-text-field>
					<v-btn icon outlined color="primary" height="24" width="24" title="Thêm mới" @click="openAddForm">
						<v-icon size="18">mdi-plus</v-icon>
					</v-btn>
				</div>
				<v-data-table :headers="headers" :items="details" :search="search" dense class="elevation-1"
					hide-default-footer :items-per-page="-1">
					<template v-slot:item.File="{ item }">
						<v-chip v-if="item.FileID && item.FileID != ''" label outlined small
							color="deep-purple accent-4" target="_blank"
							:href="vueData.v_Set.urlReturnFile + '/FileData/' + item.FileID">
							<v-icon left size="16" class="mr-1">mdi-file-check-outline</v-icon>
							{{ item.FileName || 'Tải file' }}
						</v-chip>
						<v-chip v-else label outlined small color="grey">
							Chưa có
						</v-chip>
					</template>
					<template v-slot:item.actions="{ item }">
						<v-btn icon variant="text" height="24" width="24" color="primary" title="Sửa"
							@click="openEditForm(item)">
							<v-icon size="18">mdi-square-edit-outline</v-icon>
						</v-btn>
						<v-btn icon variant="text" height="24" width="24" color="error" title="Xoá"
							@click="deleteItem(item)">
							<v-icon size="18">mdi-trash-can-outline</v-icon>
						</v-btn>
					</template>
				</v-data-table>
			</v-card-text>
		</v-card>

		<v-dialog v-model="isFormOpen" max-width="500px" persistent>
			<v-card>
				<v-card-title>{{ isEdit ? 'Cập nhật miễn giảm' : 'Thêm mới miễn giảm' }}</v-card-title>
				<v-card-text class="pt-4">
					<v-row dense>
						<v-col cols="12" class="pb-2">
							<v-text-field v-model="form.LyDo" label="Lý do" dense hide-details></v-text-field>
						</v-col>
						<v-col cols="12" class="pb-2">
							<v-text-field v-model="form.SoGioMienGiam" label="Số giờ miễn giảm" type="number" dense
								hide-details></v-text-field>
						</v-col>
						<v-col cols="12" class="pb-2">
							<v-text-field v-model="form.SoQuyetDinh" label="Số quyết định" dense hide-details>
							</v-text-field>
						</v-col>
						<v-col cols="12">
							<f-file-upload v-if="!form.FileID" label="Tải file minh chứng" :url="vueData.v_Set.apiFile"
								@update:model-value="uploadFile" />
							<v-chip v-else closable label outlined color="deep-purple accent-4" target="_blank"
								:href="vueData.v_Set.urlReturnFile + '/FileData/' + form.FileID"
								@click:close="removeFile">
								<v-icon left class="mr-1">mdi-file-check-outline</v-icon>
								{{ form.FileName || 'File minh chứng' }}
							</v-chip>
						</v-col>
					</v-row>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn text @click="cancelForm">Hủy</v-btn>
					<v-btn color="primary" :loading="saving" @click="saveItem">Lưu</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</v-dialog>
</template>

<script>
	export default {
		name: "uc-modal-mien-giam",
		props: {
			value: { type: Boolean, default: false },
			modelValue: { type: Boolean, default: null },
			nhanVien: { type: Object, default: () => ({}) },
			details: { type: Array, default: () => [] },
			selectedYear: { type: [Number, String], default: null }
		},
		emits: ["input", "update:modelValue", "on-reload"],
		data() {
			return {
				vueData,
				search: "",
				headers: [
					{ title: "Lý do", value: "LyDo" },
					{ title: "Số giờ miễn giảm", value: "SoGioMienGiam", align: "right" },
					{ title: "Số quyết định", value: "SoQuyetDinh" },
					{ title: "Minh chứng", value: "File", align: "center", sortable: false, width: 150 },
					{ title: "Thao tác", value: "actions", align: "center", sortable: false, width: 100 },
				],
				isFormOpen: false,
				isEdit: false,
				saving: false,
				form: {
					MienGiamID: 0,
					LyDo: "",
					SoGioMienGiam: 0,
					SoQuyetDinh: "",
					FileID: null,
					FileName: null
				}
			}
		},
		computed: {
			dialog: {
				get() { return this.modelValue !== null ? this.modelValue : this.value; },
				set(val) {
					this.$emit("input", val);
					this.$emit("update:modelValue", val);
				}
			}
		},
		methods: {
			closeDialog() {
				this.dialog = false;
			},
			resetForm() {
				this.form = {
					MienGiamID: 0,
					LyDo: "",
					SoGioMienGiam: 0,
					SoQuyetDinh: "",
					FileID: null,
					FileName: null
				};
			},
			openAddForm() {
				this.isEdit = false;
				this.resetForm();
				this.isFormOpen = true;
			},
			openEditForm(item) {
				this.isEdit = true;
				this.form = { FileID: null, FileName: null, ...item };
				this.isFormOpen = true;
			},
			async saveItem() {
				this.saving = true;
				try {
					const payload = {
						MienGiamID: this.form.MienGiamID || 0,
						NhanVienID: this.nhanVien.NhanVienID,
						NamHoc: this.selectedYear,
						LyDo: this.form.LyDo,
						SoGioMienGiam: this.form.SoGioMienGiam,
						SoQuyetDinh: this.form.SoQuyetDinh,
						FileID: this.form.FileID || null,
						FileName: this.form.FileName || null
					};
					await ajaxCALLPromise("/HDKH_Admin_MienGiam_Save", payload);
					Vue.$toast.success(this.isEdit ? "Cập nhật thành công" : "Thêm mới thành công", { position: "top" });
					this.isFormOpen = false;
					this.$emit("on-reload");
				} finally {
					this.saving = false;
				}
			},
			deleteItem(item) {
				confirm({
					title: `Bạn có muốn xóa miễn giảm <br/><b>${item.LyDo}</b>?`,
					action: async () => {
						await ajaxCALLPromise("/HDKH_Admin_MienGiam_Delete", { MienGiamID: item.MienGiamID });
						Vue.$toast.success("Xóa thành công", { position: "top" });
						this.$emit("on-reload");
					}
				});
			},
			async cancelForm() {
				if (!this.isEdit && this.form.FileID) {
					try {
						await ajaxCALLPromise('/FILE_FileDelete', { FileID: this.form.FileID });
					} catch (e) {
						console.error("Lỗi khi xóa file tạm:", e);
					}
				}
				this.isFormOpen = false;
			},
			uploadFile(file) {
				this.form.FileID = file.Files[0].FILE_ID;
				this.form.FileName = file.Files[0].FILE_NAME;
			},
			async removeFile() {
				if (this.form.FileID) {
					await ajaxCALLPromise('/FILE_FileDelete', { FileID: this.form.FileID });
					Vue.$toast.success('Xoá file thành công', { position: 'top' });
					this.form.FileID = null;
					this.form.FileName = null;
				}
			}
		}
	}
</script>