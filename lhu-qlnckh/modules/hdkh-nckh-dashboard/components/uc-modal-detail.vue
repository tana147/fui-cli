<template>
	<v-dialog v-model="dialog" v-if="fieldRenderers" max-width="1000" persistent>
		<v-card>
			<v-card-title class="d-flex py-1 align-center">
				<span>Chi tiết kê khai</span>
				<v-spacer></v-spacer>
				<v-btn @click="closeViewDialog()" variant="text" color="primary" icon="mdi-close"></v-btn>
			</v-card-title>

			<v-card-text class="pa-3 text-body-2" v-if="selectedItem">
				<v-row dense class="pa-0">
					<v-col v-for="field in FieldFillter" :key="field.FieldID" cols="12" md="6" class="py-1">
						<div v-if="fieldRenderers[field.FieldID]">
							<component :is="fieldRenderers[field.FieldID].component" v-model="formData[field.FieldName]"
								:label="field.FieldLabel" :items="fieldRenderers[field.FieldID].items"
								:required="field.IsRequired" :rules="[]"
								:loading="fieldRenderers[field.FieldID].loading"
								:type="field.FieldType === 'NUMBER' ? 'number' : (field.FieldType === 'DATE' ? 'date' : 'text')"
								variant="outlined" density="compact"
								v-bind="field.FieldType === 'TEXTAREA' ? { rows: 2 } : {}"
								:readonly="selectedItem.TrangThaiDuyet != 'CHO_DUYET'">
							</component>
						</div>
					</v-col>
					<v-col cols="12" v-if="formData.reason != null" class="py-1">
						<v-textarea variant="outlined" density="compact" v-model="formData.reason"
							label="Ghi chú từ chối" readonly>
						</v-textarea>
					</v-col>
				</v-row>

				<!-- MinhChung -->
				<v-divider class="my-2"></v-divider>

				<div class="d-flex justify-space-between align-center mb-1">
					<div class="text-subtitle-1">Minh chứng</div>
					<v-btn v-if="selectedItem.TrangThaiDuyet === 'CHO_DUYET'" prepend-icon="mdi-plus" size="small"
						variant="tonal" @click="addMinhChung(null)">Thêm minh chứng</v-btn>
				</div>

				<v-row dense class="pa-0" v-for="(minhchung, index) in formData.MinhChung" :key="index" align="center">
					<v-col cols="4" class="py-1">
						<v-text-field :readonly="selectedItem.TrangThaiDuyet != 'CHO_DUYET'" label="URL minh chứng"
							density="compact" v-model="minhchung.URLMinhChung" />
					</v-col>
					<v-col cols="3" v-if="selectedItem.TrangThaiDuyet === 'CHO_DUYET' && minhchung.FileID == null"
						class="py-1">
						<f-file-upload label="Tải file minh chứng" :url="vSet.apiFile"
							@update:model-value="(file) => uploadFileMinhChung(file, index)" />
					</v-col>
					<v-col cols="4" class="py-1">
						<span v-if="minhchung.FileName != null" class=" ">
							<v-chip :closable="selectedItem.TrangThaiDuyet == 'CHO_DUYET'" label outlined
								color="deep-purple accent-4" target="_blank"
								:href="vSet.urlReturnFile + '/FileData/' + minhchung.FileID"
								@click:close="del_fileMinhChung(index)">
								<v-icon left class="mr-1">mdi-file-check-outline</v-icon>
								{{ minhchung.FileName }}
							</v-chip>
						</span>
						<v-chip v-else color="warning" label outlined
							v-if="selectedItem.TrangThaiDuyet === 'CHO_DUYET'">
							Upload file minh chứng (nếu có)
						</v-chip>
					</v-col>
					<v-col cols="12" md="1" class="text-center py-1">
						<v-btn v-if="index > 0 && selectedItem.TrangThaiDuyet === 'CHO_DUYET'" icon="mdi-delete"
							variant="text" color="error" @click="removeMinhChung(index)" />
					</v-col>
				</v-row>

				<v-divider class="my-2"></v-divider>

				<div class="d-flex justify-space-between align-center mb-2">
					<div class="text-subtitle-1">Thành viên tham gia</div>
					<v-btn v-if="selectedItem.TrangThaiDuyet === 'CHO_DUYET'" prepend-icon="mdi-plus" size="small"
						variant="tonal" @click="addThanhVien(null)">Thêm thành viên</v-btn>
				</div>

				<v-row dense class="pa-0" v-for="(member, index) in formData.ThanhVien" :key="index" align="center">
					<v-col cols="12" md="3" class="py-1">
						<v-autocomplete v-if="member.isNhanVienLHU" :items="allMaGV" v-model="member.NhanVienID"
							:label="'Mã nhân viên ' + (index + 1)" density="compact" :readonly="index == 0"
							@update:model-value="value => handleSelectionChange(value, index)" />
						<v-text-field v-else v-model="member.NhanVienID" :label="'Mã nhân viên ' + (index + 1)"
							density="compact" :readonly="index == 0" />
					</v-col>
					<v-col cols="12" md="4" class="py-1">
						<v-autocomplete v-if="member.isNhanVienLHU" :items="allTenGV" v-model="member.HoTen"
							label="Họ tên nhân viên" density="compact" :readonly="index == 0"
							@update:model-value="value => handleSelectionChange(value, index)" />
						<v-text-field v-else v-model="member.HoTen" label="Họ tên nhân viên" density="compact"
							:readonly="index == 0" />
					</v-col>
					<v-col cols="12" md="3" class="py-1">
						<v-select v-model="member.VaiTroID" label="Vai trò" :items="dsVaiTro" item-title="title"
							:rules="[rules.required]" item-value="value" density="compact" />
					</v-col>
					<v-col cols="12" md="1" class="text-center py-1">
						<v-btn v-if="index > 0" icon="mdi-delete" variant="text" color="error"
							@click="removeThanhVien(index)" />
					</v-col>
					<v-col cols="12" md="3" class="py-1">
						<v-checkbox v-model="member.isNhanVienLHU" label="Là giáo viên LHU" density="compact">
						</v-checkbox>
					</v-col>
				</v-row>
			</v-card-text>
			<v-card-actions>
				<v-spacer></v-spacer>
				<div v-if="selectedItem && selectedItem.TrangThaiDuyet === 'CHO_DUYET'">
					<v-btn @click="updateSubmission(selectedItem.SubmissionID)" variant="tonal" color="success">Cập
						nhật</v-btn>
					<v-btn @click="deleteSubmission(selectedItem.SubmissionID)" variant="tonal" color="error">Xóa
					</v-btn>
				</div>
				<v-btn @click="closeViewDialog()" variant="tonal" color="primary">Đóng</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: 'uc-modal-detail',
		props: {
			modelValue: { type: Boolean, default: false },
			item: { type: Object, default: null },
			nhanVienId: [String, Number],
			dsGV: { type: Array, default: () => [] },
			dmGetAll: { type: Object, default: null },
			mapVaiTro: { type: Object, default: () => ({}) },
			vSet: { type: Object, default: () => ({}) }
		},
		emits: ['update:modelValue', 'on-reload'],
		data() {
			return {
				formData: {},
				fieldRenderers: {},
				dsVaiTro: [],
				selectedItem: null,
				uploadedFileIDs: [],
				pendingDeleteFileIDs: [],
				formDefinition: {},
				formEditData: {},
				rules: {
					required: value => (value !== null && value !== undefined && value !== '') || 'Trường này là bắt buộc.',
				}
			}
		},
		computed: {
			dialog: {
				get() {
					return this.modelValue;
				},
				set(val) {
					this.$emit('update:modelValue', val);
				}
			},
			FieldFillter() {
				return this.formDefinition.Fields?.filter((x) => x?.FieldName !== 'vai_tro') || [];
			},
			allMaGV() {
				let res = []
				if (Array.isArray(this.dsGV)) {
					this.dsGV.forEach((gv) => res.push(gv.MaNV))
				}
				return res;
			},
			allTenGV() {
				let res = []
				if (Array.isArray(this.dsGV)) {
					this.dsGV.forEach((gv) => res.push(`${gv.HoNV} ${gv.TenNV}`))
				}
				return res;
			}
		},
		watch: {
			modelValue: {
				immediate: true,
				async handler(newVal) {
					if (newVal && this.item && this.item.SubmissionID) {
						await this.loadDetail();
					}
				}
			}
		},
		methods: {
			async loadDetail() {
				this.selectedItem = this.item;
				this.uploadedFileIDs = [];
				this.pendingDeleteFileIDs = [];
				const res = await ajaxCALLPromise("/HDKH_KeKhai_GetSubmissionDetail", { SubmissionID: this.item.SubmissionID })
				if (!res || res.length < 4) return;
				
				const formID = res[0][0].FormID
				const form = await ajaxCALLPromise("/HDKH_Form_GetDefinition", { FormID: formID })
				this.formDefinition = form[0]
				this.formEditData = res[1]
				this.initializeForm()
				
				const fields = this.formEditData
				for (const field of fields) {
					if (field.FieldType === 'SELECT') {
						this.formData[field.FieldName] = parseInt(field.FieldValue)
					} else {
						this.formData[field.FieldName] = field.FieldValue
					}
				}
				this.formData.ThanhVien = res[2]
				this.formData.MinhChung = res[3]
				this.formData.reason = this.item.GhiChuTuChoi ?? null
			},
			async initializeForm() {
				this.formData = {};
				this.fieldRenderers = {};
				this.uploadedFileIDs = [];
				this.pendingDeleteFileIDs = [];
				try {
					if (this.dmGetAll) {
						const tempDsVaiTro = this.dmGetAll.get('VaiTro');
						if (tempDsVaiTro) {
							let res = []
							const arrayNumber = this.mapVaiTro[this.formDefinition.FormCode] || [10];
							arrayNumber.forEach((number) => {
								if (tempDsVaiTro[number]) {
									res.push(tempDsVaiTro[number])
								}
							})
							this.dsVaiTro = res
						}
					}
					this.buildFieldRenderers();
				} catch (error) {
					console.error('Lỗi khởi tạo form detail:', error)
					Vue.$toast.error('Không thể tải dữ liệu cần thiết cho form kê khai.', { position: 'top' });
				}
			},
			buildFieldRenderers() {
				try {
					this.formDefinition.Fields = this.formDefinition?.json_data ? JSON.parse(this.formDefinition?.json_data) : []
				} catch (e) {
					this.formDefinition.Fields = [];
				}
				
				if (!this.formDefinition || !this.formDefinition.Fields || this.formDefinition.Fields.length === 0) return;
	
				this.formDefinition.Fields.forEach(field => {
					const renderer = {
						component: 'v-text-field',
						items: [],
						loading: false
					};
					switch (field.FieldType) {
						case 'SELECT':
							renderer.component = 'v-select';
							this.fetchDataSourceForField(field, renderer);
							break;
						case 'TEXTAREA':
							renderer.component = 'v-textarea';
							break;
						case 'CHECKBOX':
							renderer.component = 'v-checkbox';
							break;
						case 'DATE':
							renderer.component = 'v-text-field';
							break;
					}
					this.fieldRenderers[field.FieldID] = renderer;
				});
			},
			async fetchDataSourceForField(field, renderer) {
				if (!field.DataSource) return;
				renderer.loading = true;
				try {
					const DataSourceReplaceDM_ = field.DataSource.includes('DM_') ? field.DataSource.replace('DM_', '') : field.DataSource
					if (this.dmGetAll) {
						renderer.items = this.dmGetAll.get(DataSourceReplaceDM_) || [];
					}
				} catch (error) {
					console.error('Lỗi fetch data source field:', error)
					Vue.$toast.error(`Không thể tải danh sách cho trường '${field.FieldLabel}'.`, { position: 'top' });
				} finally {
					renderer.loading = false;
				}
			},
			handleSelectionChange(value, index) {
				const res = this.dsGV.find((x) => x.MaNV === value || `${x.HoNV} ${x.TenNV}` === value)
				if (res) {
					this.formData.ThanhVien[index].NhanVienID = res.MaNV
					this.formData.ThanhVien[index].HoTen = `${res.HoNV} ${res.TenNV}`
				}
			},
			async updateSubmission(submissionID) {
				const arrayMinhChung = this.formData.MinhChung ?? []
				const hasFile = arrayMinhChung.some(x => x.FileID != null && String(x.FileID).trim() !== "")
				if (!hasFile) {
					Vue.$toast.error('Vui lòng tải lên ít nhất một file minh chứng để lưu cập nhật.', { position: 'top' });
					return;
				}
				let def_payload = {
					FormCode: this.formDefinition.FormCode,
					FormID: this.formDefinition.FormID,
					NamHoc: 2025,
					KeKhai_LienQuan_ID: 0,
				}
				const payload = {
					SubmissionID: submissionID,
					FormCode: this.formDefinition.FormCode,
					NamHoc: 2025,
					Fields: { ...this.formData, vai_tro: this.formData.ThanhVien[0].VaiTroID },
					ThanhVien: this.formData.ThanhVien,
					MinhChung: this.formData.MinhChung,
					sys_RawData: JSON.stringify(def_payload)
				};
				await ajaxCALLPromise('/HDKH_KeKhai_CalculateAndSave', payload);
				if (this.pendingDeleteFileIDs && this.pendingDeleteFileIDs.length > 0) {
					const delPayload = { FileIDs: this.pendingDeleteFileIDs.join(',') };
					await ajaxCALLPromise('/FILE_FileDeleteMulti', delPayload);
				}
				Vue.$toast.success('Chỉnh sửa hoạt động thành công!', { position: 'top' });
				this.$emit('on-reload', this.nhanVienId);
				this.dialog = false;
			},
			deleteSubmission(submissionID) {
				confirm({
					title: "Bạn có chắc chắn muốn xóa hoạt động này?",
					action: async () => {
						try {
							await ajaxCALLPromise('/HDKH_KeKhai_Delete', { SubmissionID: submissionID });
							Vue.$toast.success('Xóa hoạt động thành công', { position: 'top' });
							this.$emit('on-reload', this.nhanVienId);
							this.dialog = false;
						} catch (error) {
							console.error("Lỗi xóa hoạt động:", error);
						}
					}
				});
			},
			removeThanhVien(index) {
				this.formData.ThanhVien.splice(index, 1);
			},
			async removeMinhChung(index) {
				const fileID = this.formData.MinhChung[index].FileID
				if (fileID !== null && fileID !== undefined) {
					if (this.uploadedFileIDs.includes(fileID)) {
						const payload = { FileID: fileID }
						await ajaxCALLPromise('/FILE_FileDelete', payload);
						this.uploadedFileIDs = this.uploadedFileIDs.filter(id => id !== fileID);
						Vue.$toast.success('Xoá minh chứng thành công', { position: 'top' });
					} else {
						this.pendingDeleteFileIDs.push(fileID);
					}
				}
				this.formData.MinhChung.splice(index, 1);
			},
			addThanhVien(defaultUserId = null, defaultName = null) {
				if (!this.formData.ThanhVien) this.formData.ThanhVien = [];
				this.formData.ThanhVien.push({
					NhanVienID: defaultUserId,
					VaiTroID: null,
					ViTri: this.formData.ThanhVien.length + 1,
					HoTen: defaultName,
					isNhanVienLHU: true,
					isTacGiaLienHe: false
				});
			},
			addMinhChung(defaultUrl = "", defaultFileID = "") {
				if (!this.formData.MinhChung) this.formData.MinhChung = [];
				this.formData.MinhChung.push({
					URLMinhChung: defaultUrl,
					FileID: defaultFileID,
					FileName: null
				});
			},
			uploadFileMinhChung(file, index) {
				if (file && file.Files && file.Files[0]) {
					const fileID = file.Files[0].FILE_ID;
					this.uploadedFileIDs.push(fileID);
					this.formData.MinhChung[index].FileID = fileID;
					this.formData.MinhChung[index].FileName = file.Files[0].FILE_NAME;
				}
			},
			async del_fileMinhChung(index) {
				const fileID = this.formData.MinhChung[index].FileID
				if (fileID !== null && fileID !== undefined) {
					if (this.uploadedFileIDs.includes(fileID)) {
						const payload = { FileID: fileID }
						await ajaxCALLPromise('/FILE_FileDelete', payload);
						this.uploadedFileIDs = this.uploadedFileIDs.filter(id => id !== fileID);
						Vue.$toast.success('Xoá minh chứng thành công', { position: 'top' });
					} else {
						this.pendingDeleteFileIDs.push(fileID);
					}
				}
				this.formData.MinhChung[index].FileID = null;
				this.formData.MinhChung[index].FileName = null;
			},
			async closeViewDialog() {
				if (this.uploadedFileIDs && this.uploadedFileIDs.length > 0) {
					try {
						const payload = { FileIDs: this.uploadedFileIDs.join(',') };
						await ajaxCALLPromise('/FILE_FileDeleteMulti', payload);
					} catch (e) {
						console.error("Lỗi xóa file tạm:", e);
					}
				}
				this.dialog = false;
			}
		}
	}
</script>