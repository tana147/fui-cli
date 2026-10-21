<template>
	<v-dialog v-model="showDialog" max-width="900px" persistent>
		<v-card>
			<v-card-title>
				<span class="text-h5">{{ dialogTitle }}</span>
			</v-card-title>

			<v-divider></v-divider>

			<div v-if="isLoading" class="pa-6">
				<v-skeleton-loader type="article, actions"></v-skeleton-loader>
			</div>

			<v-form v-else ref="form" @submit.prevent="saveKekhai">
				<v-card-text class="pa-3 text-body-2" style="max-height: 70vh; overflow-y: auto;">
					<div>
						<v-row dense class="pa-0">
							<v-col v-for="field in FieldFillter" :key="field.FieldID" cols="12" md="6" class="py-1">
								<div v-if="fieldRenderers[field.FieldID]">
									<component :is="fieldRenderers[field.FieldID].component"
										v-model="formData[field.FieldName]" :label="field.FieldLabel"
										:items="fieldRenderers[field.FieldID].items" :required="field.IsRequired"
										:rules="field.IsRequired ? [rules.required] : []"
										:loading="fieldRenderers[field.FieldID].loading"
										v-bind="field.FieldType === 'TEXTAREA' ? { rows: 2 } : {}"
										:type="field.FieldType === 'NUMBER' ? 'number' : (field.FieldType === 'DATE' ? 'date' : 'text')"
										variant="outlined" density="compact" />
								</div>
							</v-col>
						</v-row>

						<v-divider class="my-2"></v-divider>

						<div class="d-flex justify-space-between align-center mb-1">
							<div class="text-subtitle-1">Minh chứng</div>
							<v-btn v-if="itemStatus !== 'view'" prepend-icon="mdi-plus" size="small" variant="tonal"
								@click="addMinhChung(null)">Thêm
								minh chứng</v-btn>
						</div>

						<v-row dense class="pa-0" v-for="(minhchung, index) in formData.MinhChung" :key="index"
							align="center">
							<v-col cols="4" class="py-1">
								<v-text-field label="URL minh chứng" density="compact"
									v-model="minhchung.URLMinhChung" />
							</v-col>
							<v-col cols="3" class="py-1" v-if="itemStatus !== 'view' && minhchung.FileID == null">
								<f-file-upload label="Tải file minh chứng" :url="vueData.v_Set.apiFile"
									:filters="filtersFile" @update:model-value="(file) => uploadFileMinhChung(file, index)" />
							</v-col>
							<v-col cols="4" class="py-1">
								<v-chip v-if="minhchung.FileID != null" closable label outlined
									color=" deep-purple accent-4" target="_blank"
									:href="vueData.v_Set.urlReturnFile + '/FileData/' + minhchung.FileID"
									@click:close="del_fileMinhChung(index)" style="max-width: 100%;">
									<v-icon left class="mr-1">mdi-file-check-outline</v-icon>
									<span class="d-inline-block text-truncate"
										style="max-width: 150px; vertical-align: bottom;">{{ minhchung.FileName
										}}</span>
								</v-chip>
								<v-chip v-else color="warning" label outlined>
									Upload file minh chứng (nếu có)
								</v-chip>
							</v-col>
							<v-col cols="12" md="1" class="text-center py-1">
								<v-btn v-if="index > 0 && itemStatus !== 'view'" icon="mdi-delete" variant="text"
									color="error" @click="removeMinhChung(index)" />
							</v-col>
						</v-row>

						<v-divider class="my-2"></v-divider>

						<div class="d-flex justify-space-between align-center mb-2">
							<div class="text-subtitle-1">Thành viên tham gia</div>
							<v-btn v-if="itemStatus !== 'view'" prepend-icon="mdi-plus" size="small" variant="tonal"
								@click="addThanhVien(null)">Thêm
								thành viên</v-btn>
						</div>

						<v-row dense class="pa-0" v-for="(member, index) in formData.ThanhVien" :key="index"
							align="center">
							<v-col cols="12" md="3" class="py-1">
								<v-autocomplete v-if="member.isNhanVienLHU" :items="allMaGV" v-model="member.NhanVienID"
									:label="'Mã nhân viên ' + (index + 1)" density="compact"
									:readonly="index == 0 ? true : false"
									@update:model-value="value => handleSelectionChange(value, index)" />
								<v-text-field v-else v-model="member.NhanVienID" :label="'Mã nhân viên ' + (index + 1)"
									density="compact" :readonly="index == 0 ? true : false" />
							</v-col>
							<v-col cols="12" md="4" class="py-1">
								<v-autocomplete v-if="member.isNhanVienLHU" :items="allTenGV" v-model="member.HoTen"
									label="Họ tên nhân viên" density="compact" :readonly="index == 0 ? true : false"
									@update:model-value="value => handleSelectionChange(value, index)" />
								<v-text-field v-else v-model="member.HoTen" label="Họ tên nhân viên" density="compact"
									:readonly="index == 0 ? true : false" />
							</v-col>
							<v-col cols="12" md="4" class="py-1">
								<v-select v-model="member.VaiTroID" label="Vai trò" :items="dsVaiTro" item-title="title"
									@update:model-value="handleSelectedVaiTro(member)" :rules="[rules.required]"
									item-value="value" density="compact" />
							</v-col>
							<!-- <v-col cols="12" md="1" class="py-1">
								<v-text-field v-model.number="member.ViTri" label="Vị trí" type="number"
									density="compact" />
							</v-col> -->
							<v-col cols="12" md="1" class="text-center py-1">
								<v-btn v-if="index > 0 && itemStatus !== 'view'" icon="mdi-delete" variant="text"
									color="error" @click="removeThanhVien(index)" />
							</v-col>
							<v-col cols="12" md="3" class="py-1">
								<v-checkbox v-model="member.isNhanVienLHU" label="Là giáo viên LHU" density="compact">
								</v-checkbox>
							</v-col>
							<!-- <v-col cols="12" md="3" class="py-1">
								<v-checkbox v-model="member.isTacGiaLienHe" label="Là tác giả liên hệ"
									density="compact"></v-checkbox>
							</v-col> -->
						</v-row>
					</div>
				</v-card-text>

				<v-divider></v-divider>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn v-if="itemStatus === 'view'" text @click="closeDialog">Đóng</v-btn>
					<div v-else>
						<v-btn text @click="onCancel">Hủy</v-btn>
						<v-btn type="submit" color="primary" variant="flat" :loading="isSaving">Lưu Kê khai</v-btn>
					</div>
				</v-card-actions>
			</v-form>

		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: 'uc-form-ke-khai-dong',
		emits: ['update:modelValue', 'close', 'update:formDefinition', 'update:formEditData', 'on-reload', 'update:selectedSubmissionID'],
		props: {
			modelValue: { type: Boolean, default: false },
			formDefinition: { type: Object, default: () => ({}) },
			title: { type: String, default: 'Kê khai Hoạt động Khoa học' },
			formEditData: { type: Object, default: () => ({}) },
			dsGV: { type: Array, default: () => [] },
			itemStatus: { type: String, default: null },
			selectedSubmissionID: { type: Number, default: 0 },
		},
		data() {
			return {
				vueData: typeof vueData !== 'undefined' ? vueData : { v_Set: {} },
				showDialog: false,
				isLoading: true,
				isSaving: false,
				formData: {},
				dsVaiTro: [],
				fieldRenderers: {}, // Object để lưu cấu hình render cho từng field
				rules: {
					required: value => (value !== null && value !== undefined && value !== '') || 'Trường này là bắt buộc.',
				},
				DM_GetALL: new Map(),
				fileEX: {
					max_file_size: '20mb',
					mime_types: [{ title: "All files", extensions: "*" }]
				},
				FileUpload: null,
				uploadedFileIDs: [],
				pendingDeleteFileIDs: [],
				MapVaiTro: {
					"DE_TAI_NCKH": [1, 2, 10, 11],
					"SACH_GIAO_TRINH": [0, 10],
					"BAI_BAO_KH": [4, 5, 6, 7, 8, 9],
					"HD_XET_TUYEN": [4, 5, 6, 7, 8, 9, 10],
					"SO_HUU_TRI_TUE": [2, 10],
					"PHAN_BIEN": [10],
					"HUONG_DAN_NCKH": [10],
					"HUONG_DAN_HOC_SINH_NCKH": [10],
					"HUONG_DAN_LUAN_VAN": [10],
					"CUOC_THI_KHCN": [10],
					"CGCN": [10],
					"BC_HOI_THAO": [10],
					"HOI_DONG_CHAM_THI": [10],
					"NV_KHAC": [10],
				},
				filtersFile: {
					max_file_size: '20mb',
					mime_types: [{ title: "All files", extensions: "*" }]
				},
				localDsGV: []
			};
		},
		computed: {
			mergedDsGV() {
				if (this.dsGV && this.dsGV.length > 0) return this.dsGV;
				return this.localDsGV || [];
			},
			allMaGV() {
				let res = []
				this.mergedDsGV.forEach((gv) => res.push(gv.MaNV))
				return res
			},
			allTenGV() {
				let res = []
				this.mergedDsGV.forEach((gv) => res.push(`${gv.HoNV} ${gv.TenNV}`))
				return res
			},
			FieldFillter() {
				return this.formDefinition?.Fields?.filter((x) => x?.FieldName !== 'vai_tro') || []
			},
	
			dialogTitle() {
				if (Object.keys(this.formEditData).length != 0) {
					let fields = this.formEditData[1]
					for (field of fields) {
						for (field of fields) {
							if (field.FieldType === 'SELECT')
								this.formData[field.FieldName] = parseInt(field.FieldValue)
							else
								this.formData[field.FieldName] = field.FieldValue
						}
					}
					this.formData.ThanhVien = this.formEditData[0]
					this.formData.MinhChung = this.formEditData[2]
					return this.title;
				}
				if (this.formData.ThanhVien == null) {
					this.formData.ThanhVien = [];
					this.addThanhVien(this.vueData.user?.UserID, `${this.vueData.user?.LastName} ${this.vueData.user?.FirstName}`);
				}
				if (this.formData.MinhChung == null) {
					this.formData.MinhChung = [];
					this.addMinhChung();
				}
				return this.formDefinition ? `Kê khai: ${this.formDefinition.FormTitle}` : 'Đang tải...';
			}
		},
		watch: {
			modelValue(newVal) {
				this.showDialog = newVal;
				if (newVal && this.formDefinition) {
					if (this.mergedDsGV.length === 0) {
						this.fetchDsGV();
					}
					this.initializeForm();
				} else {
					this.formData = {};
					this.fieldRenderers = {};
					this.uploadedFileIDs = [];
					this.pendingDeleteFileIDs = [];
					this.$emit('update:selectedSubmissionID', 0);
					this.$emit('update:formDefinition', {});
					this.$emit('update:formEditData', {});
				}
			},
		},
		async mounted() {
			if (this.mergedDsGV.length === 0) {
				this.fetchDsGV();
			}
			const data = await ajaxCALLPromise('/HDKH_DM_GetAll', null);
			if (!data || data.length === 0) return;
			for (let i = 0; i < data.length; i++) {
				let item = data[i] ?? {};
				this.DM_GetALL.set(item[0]?.DanhMucCode, data[i]);
			}
		},
		methods: {
			async fetchDsGV() {
				try {
					const data = await ajaxCALLPromise('/TaiKhoan_Seach', { Keyword: '' });
					this.localDsGV = data || [];
				} catch (e) {
					console.error("Lỗi fetchDsGV:", e);
				}
			},
			handleSelectionChange(value, index) {
				const res = this.mergedDsGV.find((x) => x.MaNV === value || `${x.HoNV} ${x.TenNV}` === value)
				if (res && this.formData?.ThanhVien?.[index]) {
					this.formData.ThanhVien[index].NhanVienID = res.MaNV
					this.formData.ThanhVien[index].HoTen = `${res.HoNV} ${res.TenNV}`
				}
			},
			handleSelectedVaiTro(member) {
				switch (member.VaiTroID) {
					// Tác giả chính + liên hệ
					case 7:
					case 8:
						member.ViTri = 1
						break
					case 9:
						member.ViTri = 2
						break
					case 10:
						member.ViTri = 3
						break
					case 11:
						member.ViTri = 4
						break
					case 12:
						member.ViTri = 5
						break
				}
			},
	
			async initializeForm() {
				this.isLoading = true;
				this.formData = {};
				this.fieldRenderers = {};
				this.uploadedFileIDs = [];
				this.pendingDeleteFileIDs = [];
				try {
					const tempDsVaiTro = this.DM_GetALL.get('VaiTro')
					let res = []
					const arrayNumber = this.MapVaiTro[`${this.formDefinition.FormCode}`]
					arrayNumber.forEach((number) => {
						res.push(tempDsVaiTro[number])
					})
					this.dsVaiTro = res
					this.buildFieldRenderers();
				} catch (error) {
					console.log('error', error)
					Vue.$toast.error('Không thể tải dữ liệu cần thiết cho form kê khai.', { position: 'top' });
				} finally {
					this.isLoading = false;
				}
			},
			buildFieldRenderers() {
				this.formDefinition.Fields = this.formDefinition?.json_data ? JSON.parse(this.formDefinition?.json_data) : []
				if (!this.formDefinition || !this.formDefinition.Fields.length != 0) return;
	
				this.formDefinition.Fields.forEach(field => {
					const renderer = {
						component: 'v-text-field', // Mặc định
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
							renderer.component = 'v-text-field'; // Dùng v-text-field type="date"
							break;
					}
					this.fieldRenderers[field.FieldID] = renderer;
				});
			},
			async fetchDataSourceForField(field, renderer) {
				if (!field.DataSource) return;
				renderer.loading = true;
	
				try {
					let DataSourceReplaceDM_ = field.DataSource.includes('DM_') ? field.DataSource.replace('DM_', '') : field.DataSource
					renderer.items = this.DM_GetALL.get(DataSourceReplaceDM_);
				} catch (error) {
					console.log('error', error)
					Vue.$toast.error(`Không thể tải danh sách cho trường '${field.FieldLabel}'.`, { position: 'top' });
				} finally {
					renderer.loading = false;
				}
			},
			async onCancel() {
				if (this.uploadedFileIDs && this.uploadedFileIDs.length > 0) {
					const payload = { FileIDs: this.uploadedFileIDs.join(',') };
					await ajaxCALLPromise('/FILE_FileDeleteMulti', payload);
				}
				this.$emit('update:modelValue', false);
			},
			closeDialog() {
				this.$emit('update:modelValue', false);
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
			removeThanhVien(index) {
				this.formData.ThanhVien.splice(index, 1);
			},
			addMinhChung(defaultUrl = null, defaultFileID = null) {
				if (!this.formData.MinhChung) this.formData.MinhChung = [];
				this.formData.MinhChung.push({
					URLMinhChung: defaultUrl,
					FileID: defaultFileID
				});
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
			async saveKekhai() {
				const { valid } = await this.$refs.form.validate();
				if (!valid) {
					Vue.$toast.error('Vui lòng điền đầy đủ các thông tin bắt buộc.', { position: 'top' });
					return;
				}
				const arrayMinhChung = this.formData.MinhChung ?? []
				const isEmpty = v => v == null || String(v).trim() === ""
	
				const isAllNull = arrayMinhChung.every(
					x => isEmpty(x.URLMinhChung) && isEmpty(x.FileID)
				)
				if (isAllNull) {
					Vue.$toast.error('Vui lòng thêm minh chứng để tiếp tục', { position: 'top' });
					return;
				}
				this.isSaving = true;
				try {
					let def_payload = {
						FormCode: this.formDefinition.FormCode,
						FormID: this.formDefinition.FormID,
						NamHoc: new Date().getFullYear(),
						KeKhai_LienQuan_ID: 0,
					}
					const payload = {
						SubmissionID: this.selectedSubmissionID ?? 0,
						FormCode: this.formDefinition.FormCode,
						NamHoc: new Date().getFullYear(),
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
					Vue.$toast.success('Kê khai hoạt động thành công! Đang chờ phê duyệt.', { position: 'top' });
					this.$emit('on-reload');
					this.closeDialog();
				} catch (error) {
					console.error("Lỗi khi kê khai:", error);
					Vue.$toast.error(error.message || 'Có lỗi xảy ra trong quá trình lưu.', { position: 'top' });
				} finally {
					this.isSaving = false;
				}
			},
			uploadFileMinhChung(file, index) {
				const fileID = file.Files[0].FILE_ID;
				this.uploadedFileIDs.push(fileID);
				this.formData.MinhChung[index].FileID = fileID;
				this.formData.MinhChung[index].FileName = file.Files[0].FILE_NAME;
			},
		},
	}
</script>