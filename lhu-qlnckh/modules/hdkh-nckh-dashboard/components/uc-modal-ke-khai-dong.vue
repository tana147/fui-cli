<template>
	<v-dialog v-model="showDialog" max-width="1000px" persistent @click:outside="closeDialog">
		<v-card>
			<v-card-title>
				<span class="text-h5">{{ dialogTitleText }}</span>
			</v-card-title>

			<v-divider></v-divider>

			<div v-if="isLoading" class="pa-6">
				<v-skeleton-loader type="article, actions"></v-skeleton-loader>
			</div>

			<v-form v-else ref="form" @submit.prevent="saveKekhai">
				<v-card-text style="max-height: 70vh; overflow-y: auto;" class="pa-3 text-body-2">
					<div>
						<v-row dense class="pa-0">
							<v-col v-for="field in FieldFillter" :key="field.FieldID" cols="12" md="6" class="py-1">
								<div v-if="fieldRenderers[field.FieldID]">
									<component :is="fieldRenderers[field.FieldID].component"
										v-model="formData[field.FieldName]" :label="field.FieldLabel"
										:items="fieldRenderers[field.FieldID].items" :required="field.IsRequired"
										:rules=" []" :loading="fieldRenderers[field.FieldID].loading"
										v-bind="field.FieldType === 'TEXTAREA' ? { rows: 2 } : {}"
										:type="field.FieldType === 'NUMBER' ? 'number' : (field.FieldType === 'DATE' ? 'date' : 'text')"
										variant="outlined" density="compact"></component>
								</div>
							</v-col>
						</v-row>

						<v-divider class="my-2"></v-divider>

						<div class="d-flex justify-space-between align-center mb-1">
							<div class="text-h6">Minh chứng</div>
							<v-btn prepend-icon="mdi-plus" size="small" variant="tonal" @click="addMinhChung(null)">Thêm
								minh chứng</v-btn>
						</div>
						<v-row dense class="pa-0" v-for="(minhchung, index) in formData.MinhChung" :key="index"
							align="center">
							<v-col cols="4" class="py-1">
								<v-text-field label="URL minh chứng" density="compact"
									v-model="minhchung.URLMinhChung" />
							</v-col>
							<v-col cols="3" class="py-1" v-if="minhchung.FileID == null">
								<f-file-upload label="Tải file minh chứng" :url="vSet.apiFile"
									@update:model-value="(file) => uploadFileMinhChung(file, index)" />
							</v-col>
							<v-col cols="4" class="py-1">
								<span v-if="minhchung.FileName != null" class=" ">
									<v-chip closable label outlined color=" deep-purple accent-4" target="_blank"
										:href="vSet.urlReturnFile +'/FileData/' + minhchung.FileID"
										@click:close="del_fileMinhChung(index)">
										<v-icon left class="mr-1">mdi-file-check-outline</v-icon>
										{{ minhchung.FileName }}
									</v-chip>
								</span>
								<v-chip v-else color="warning" label outlined>
									Upload file minh chứng (nếu có)
								</v-chip>
							</v-col>
							<v-col cols="12" md="1" class="text-center py-1">
								<v-btn v-if="index > 0" icon="mdi-delete" variant="text" color="error"
									@click="removeMinhChung(index)" />
							</v-col>
						</v-row>

						<v-divider class="my-2"></v-divider>

						<div class="d-flex justify-space-between align-center mb-2">
							<div class="text-subtitle-1">Thành viên tham gia</div>
							<v-btn prepend-icon="mdi-plus" size="small" variant="tonal" @click="addThanhVien(null)">Thêm
								thành viên</v-btn>
						</div>

						<v-row dense class="pa-0" v-for="(member, index) in formData.ThanhVien" :key="index"
							align="center">
							<v-col cols="12" md="3" class="py-1">
								<v-autocomplete :items="allMaGV" v-model="member.NhanVienID"
									:label="'Mã nhân viên ' + (index + 1)" density="compact"
									:readonly="index == 0 ? true : false"
									@update:model-value="value => handleSelectionChange(value, index)" />
							</v-col>
							<v-col cols="12" md="4" class="py-1">
								<v-autocomplete :items="allTenGV" v-model="member.HoTen" label="Họ tên nhân viên"
									density="compact" :readonly="index == 0 ? true : false"
									@update:model-value="value => handleSelectionChange(value, index)" />
							</v-col>
							<v-col cols="12" md="4" class="py-1">
								<v-select v-model="member.VaiTroID" label="Vai trò" :items="dsVaiTro" item-title="title"
									@update:model-value="handleSelectedVaiTro(member)" :rules="[rules.required]"
									item-value="value" density="compact" />
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
		name: 'uc-modal-ke-khai-dong',
		emits: ['update:modelValue', 'saved', 'close', 'update:formDefinition', 'update:formEditData'],
		props: {
			modelValue: { type: Boolean, default: false },
			formDefinition: { type: Object, default: () => ({}) },
			title: { type: String, default: 'Kê khai Hoạt động Khoa học' },
			formEditData: { type: Object, default: () => ({}) },
			
			// Props kiến trúc prop-emit mới
			dsGV: { type: Array, default: () => [] },
			selectedYear: { type: Number, default: () => new Date().getFullYear() },
			nhanVien: { type: Object, default: () => ({}) },
			itemStatus: { type: String, default: 'new' },
			dmGetAll: { type: [Map, Object], default: () => new Map() },
			vSet: { type: Object, default: () => ({}) },
			mapVaiTro: { type: Object, default: () => ({}) }
		},
		data() {
			return {
				showDialog: false,
				isLoading: true,
				isSaving: false,
				formData: {
					ThanhVien: [],
					MinhChung: []
				},
				dsVaiTro: [],
				fieldRenderers: {},
				rules: {
					required: value => (value !== null && value !== undefined && value !== '') || 'Trường này là bắt buộc.',
				},
				fileEX: {
					max_file_size: '20mb',
					mime_types: [{ title: "All files", extensions: "*" }]
				}
			};
		},
		computed: {
			FieldFillter() {
				return this.formDefinition.Fields?.filter((x) => x?.FieldName !== 'vai_tro')
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
			},
			dialogTitleText() {
				if (this.formEditData && Object.keys(this.formEditData).length !== 0) {
					return this.title || 'Chỉnh sửa kê khai';
				}
				return this.formDefinition ? `Kê khai: ${this.formDefinition.FormTitle} - ${this.nhanVien?.NhanVienID || ''}` : 'Đang tải...';
			}
		},
		watch: {
			modelValue(newVal) {
				this.showDialog = newVal;
				if (newVal && this.formDefinition) {
					this.initializeForm();
				} else {
					this.$emit('update:formDefinition', {})
					this.$emit('update:formEditData', {})
				}
			},
		},
		methods: {
			handleSelectionChange(value, index) {
				if (!Array.isArray(this.dsGV)) return;
				const res = this.dsGV.find((x) => x.MaNV === value || `${x.HoNV} ${x.TenNV}` === value)
				if (res) {
					this.formData.ThanhVien[index].NhanVienID = res.MaNV
					this.formData.ThanhVien[index].HoTen = `${res.HoNV} ${res.TenNV}`
				}
			},
			handleSelectedVaiTro(member) {
				switch (member.VaiTroID) {
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
				this.formData = {
					ThanhVien: [],
					MinhChung: []
				};
				this.fieldRenderers = {};
				try {
					// 1. Tải danh sách vai trò
					const tempDsVaiTro = this.dmGetAll ? this.dmGetAll.get('VaiTro') : null;
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
					
					// 2. Khởi tạo dữ liệu form
					if (this.formEditData && Object.keys(this.formEditData).length !== 0) {
						const fields = this.formEditData[0] || [];
						for (const field of fields) {
							this.formData[field.FieldName] = field.FieldValue
						}
						this.formData.ThanhVien = this.formEditData[1] || [];
						this.formData.MinhChung = this.formEditData[2] || [];
					} else {
						this.formData = {
							ThanhVien: [],
							MinhChung: []
						};
						if (this.nhanVien) {
							this.addThanhVien(this.nhanVien.NhanVienID, this.nhanVien.HoTen);
						}
						this.addMinhChung();
					}

					this.buildFieldRenderers();
				} catch (error) {
					console.error('Lỗi khởi tạo form:', error)
					Vue.$toast.error('Không thể tải dữ liệu cần thiết cho form kê khai.', { position: 'top' });
				} finally {
					this.isLoading = false;
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
					console.error('Lỗi load DataSource field:', error)
					Vue.$toast.error(`Không thể tải danh sách cho trường '${field.FieldLabel}'.`, { position: 'top' });
				} finally {
					renderer.loading = false;
				}
			},
			async onCancel() {
				const arrayMinhChung = this.formData.MinhChung ?? []
				const isEmpty = v => v == null || String(v).trim() === ""
				const isAllNull = arrayMinhChung.every(
					x => isEmpty(x.URLMinhChung) && isEmpty(x.FileID)
				)
				if (!isAllNull) {
					const FileIDs = this.formData.MinhChung.map(f => f.FileID).filter(Boolean).join(',')
					if (FileIDs) {
						try {
							await ajaxCALLPromise('/FILE_FileDeleteMulti', { FileIDs });
						} catch (e) {
							console.error("Lỗi delete file khi cancel:", e);
						}
					}
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
			addMinhChung(defaultUrl = null, defaultFileID = null) {
				if (!this.formData.MinhChung) this.formData.MinhChung = [];
				this.formData.MinhChung.push({
					URLMinhChung: defaultUrl,
					FileID: defaultFileID,
					FileName: null
				});
			},
			removeThanhVien(index) {
				this.formData.ThanhVien.splice(index, 1);
			},
			uploadFileMinhChung(file, index) {
				if (file && file.Files && file.Files[0]) {
					this.formData.MinhChung[index].FileID = file.Files[0].FILE_ID
					this.formData.MinhChung[index].FileName = file.Files[0].FILE_NAME
				}
			},
			async removeMinhChung(index) {
				const fileID = this.formData.MinhChung[index].FileID
				if (fileID !== null && fileID !== undefined && String(fileID).trim() !== "") {
					try {
						await ajaxCALLPromise('/FILE_FileDelete', { FileID: fileID });
						Vue.$toast.success('Xoá minh chứng thành công', { position: 'top' });
					} catch (e) {
						console.error("Lỗi xóa minh chứng:", e);
					}
				}
				this.formData.MinhChung.splice(index, 1);
			},
			async del_fileMinhChung(index) {
				const fileID = this.formData.MinhChung[index].FileID;
				if (fileID !== null && fileID !== undefined && String(fileID).trim() !== "") {
					try {
						await ajaxCALLPromise('/FILE_FileDelete', { FileID: fileID });
						Vue.$toast.success('Xoá minh chứng thành công', { position: 'top' });
					} catch (e) {
						console.error("Lỗi xóa file:", e);
					}
				}
				this.formData.MinhChung[index].FileID = null
				this.formData.MinhChung[index].FileName = null
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
						NamHoc: this.selectedYear,
						KeKhai_LienQuan_ID: 0,
					}
					const payload = {
						FormCode: this.formDefinition.FormCode,
						NamHoc: this.selectedYear,
						Fields: { ...this.formData, vai_tro: this.formData.ThanhVien[0].VaiTroID },
						ThanhVien: this.formData.ThanhVien,
						MinhChung: this.formData.MinhChung,
						sys_RawData: JSON.stringify(def_payload)
					};
					await ajaxCALLPromise('/HDKH_KeKhai_CalculateAndSave', payload);
					Vue.$toast.success('Kê khai hoạt động thành công! Đang chờ phê duyệt.', { position: 'top' });
					this.$emit('saved');
					this.closeDialog();
				} catch (error) {
					console.error("Lỗi khi kê khai:", error);
					Vue.$toast.error(error.message || 'Có lỗi xảy ra trong quá trình lưu.', { position: 'top' });
				} finally {
					this.isSaving = false;
				}
			}
		}
	}
</script>