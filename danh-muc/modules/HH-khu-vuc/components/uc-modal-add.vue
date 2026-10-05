<template>
	<v-dialog v-model="modelValue" max-width="980">
		<v-card>
			<template v-slot:title>Thêm mới khu vực</template>
			<template v-slot:append>
				<v-btn size="small" variant="text" icon="mdi-close" @click="closeModal"></v-btn>
			</template>
			<v-card-text>
				<v-row>
					<v-col cols="12" md="5">
						<!-- <v-text-field
							:model-value="selectedDiaDiemSummary"
							label="Địa điểm đã chọn"
							readonly
							hide-details="auto"
							class="mb-3"
						/> -->
						<v-text-field v-model="formData.tenKhuVuc" label="Tên khu vực" required autofocus
							:rules="[rules.required]" hide-details="auto" class="mb-3" />
						<v-textarea v-model="formData.ghiChu" label="Ghi chú" rows="3" auto-grow density="comfortable"
							variant="outlined" hide-details="auto" />
					</v-col>

					<v-col cols="12" md="7">
						<div class="d-flex ga-2 align-center mb-2">
							<v-text-field v-model="pickerKeyword" label="Tìm địa điểm" prepend-inner-icon="mdi-magnify"
								hide-details="auto" clearable />
							<v-btn variant="tonal" color="primary" @click="toggleSelectAllFiltered">
								{{ isAllFilteredSelected ? 'Bỏ chọn' : 'Chọn tất cả' }}
							</v-btn>
						</div>

						<div class="border rounded" style="max-height: 430px; overflow: auto;">
							<v-table density="compact" fixed-header>
								<thead>
									<tr>
										<th style="width: 56px">
											<v-checkbox-btn :model-value="isAllFilteredSelected"
												:indeterminate="isSomeFilteredSelected"
												@click="toggleSelectAllFiltered" />
										</th>
										<th>Tên địa điểm</th>
									</tr>
								</thead>
								<tbody>
									<tr v-for="item in filteredDiaDiemList" :key="item.DiaDiem_Id">
										<td>
											<v-checkbox :model-value="formData.diaDiemIds.includes(item.DiaDiem_Id)"
												@update:model-value="toggleItem(item.DiaDiem_Id, $event)" hide-details
												density="compact" color="primary" />
										</td>
										<td>{{ item.TenDiaDiem }}</td>
									</tr>
									<tr v-if="!filteredDiaDiemList.length">
										<td colspan="2" class="text-center text-medium-emphasis py-6">Không có địa điểm
											phù hợp</td>
									</tr>
								</tbody>
							</v-table>
						</div>
					</v-col>
				</v-row>
			</v-card-text>
			<v-card-actions>
				<div class="text-medium-emphasis">Đã chọn {{ formData.diaDiemIds.length }} địa điểm</div>
				<v-spacer></v-spacer>
				<v-btn variant="text" @click="closeModal()">Hủy</v-btn>
				<v-btn color="primary" @click="save" prepend-icon="mdi-content-save-outline" variant="flat">Lưu</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
	    props: ["modelValue", "diaDiemList"],
	    emits: ["update:modelValue", "onReload", "onLoadDiaDiem"],
	    data() {
	        return {
	            formData: {
	                diaDiemIds: [],
	                tenKhuVuc: "",
	                ghiChu: "",
	            },
	            pickerKeyword: "",
	            rules: {
	                required: (value) => !!value || "Trường này không được để trống",
	            },
	        }
	    },
	    computed: {
	        selectedDiaDiemSummary() {
	            const count = this.formData.diaDiemIds.length
	            if (!count) return "Chưa chọn địa điểm"
	            if (count === 1) {
	                const selected = (this.diaDiemList || []).find((x) => x.DiaDiem_Id === this.formData.diaDiemIds[0])
	                return selected?.TenDiaDiem || "Đã chọn 1 địa điểm"
	            }
	            return `Đã chọn ${count} địa điểm`
	        },
	        filteredDiaDiemList() {
	            const keyword = (this.pickerKeyword || "").trim().toLowerCase()
	            if (!keyword) return this.diaDiemList || []
	            return (this.diaDiemList || []).filter((item) =>
	                String(item.TenDiaDiem || "").toLowerCase().includes(keyword),
	            )
	        },
	        isAllFilteredSelected() {
	            if (!this.filteredDiaDiemList.length) return false
	            return this.filteredDiaDiemList.every((item) => this.formData.diaDiemIds.includes(item.DiaDiem_Id))
	        },
	        isSomeFilteredSelected() {
	            if (!this.filteredDiaDiemList.length) return false
	            const selectedCount = this.filteredDiaDiemList.filter((item) => this.formData.diaDiemIds.includes(item.DiaDiem_Id)).length
	            return selectedCount > 0 && selectedCount < this.filteredDiaDiemList.length
	        },
	    },
	    watch: {
	        modelValue(isOpen) {
	            if (isOpen) {
	                this.$emit("onLoadDiaDiem")
	            }
	        },
	    },
	    methods: {
	        toggleItem(id, checked) {
	            if (checked) {
	                if (!this.formData.diaDiemIds.includes(id)) {
	                    this.formData.diaDiemIds.push(id)
	                }
	                return
	            }
	            this.formData.diaDiemIds = this.formData.diaDiemIds.filter((x) => x !== id)
	        },
	        toggleSelectAllFiltered() {
	            const filteredIds = this.filteredDiaDiemList.map((item) => item.DiaDiem_Id)
	            if (this.isAllFilteredSelected) {
	                this.formData.diaDiemIds = this.formData.diaDiemIds.filter((id) => !filteredIds.includes(id))
	                return
	            }
	            const set = new Set(this.formData.diaDiemIds)
	            filteredIds.forEach((id) => set.add(id))
	            this.formData.diaDiemIds = Array.from(set)
	        },
	        closeModal() {
	            this.$emit("update:modelValue", false)
	            this.resetForm()
	        },
	        save() {
	            if (!this.formData.diaDiemIds.length) {
	                showToast.error("Vui lòng chọn ít nhất một địa điểm.")
	                return
	            }
	
	            if (!this.formData.tenKhuVuc.trim()) {
	                showToast.error("Vui lòng nhập tên khu vực.")
	                return
	            }
	
	            const params = {
	                ListDiaDiem_Id: this.formData.diaDiemIds.join(","),
	                TenKhuVuc: this.formData.tenKhuVuc.trim(),
	                GhiChu: this.formData.ghiChu,
	            }
	
	            apiCall(
	                "/work/HH_KhuVuc_Insert_Multiple",
	                params,
	                () => {
	                    this.$emit("onReload")
	                    this.resetForm()
	                    this.closeModal()
	                    showToast.success("Thêm khu vực thành công cho các địa điểm đã chọn.")
	                },
	                () => {
	                    showToast.error("Không thể thêm khu vực. Vui lòng thử lại.")
	                },
	            )
	        },
	        resetForm() {
	            this.formData.diaDiemIds = []
	            this.formData.tenKhuVuc = ""
	            this.formData.ghiChu = ""
	            this.pickerKeyword = ""
	        },
	    },
	}
</script>