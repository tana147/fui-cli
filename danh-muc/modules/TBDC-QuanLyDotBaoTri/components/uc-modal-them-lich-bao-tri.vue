<template>
	<v-dialog v-model="isShow" fullscreen persistent transition="dialog-bottom-transition">
		<v-card>
			<v-toolbar density="compact" color="primary" class="sticky-toolbar">
				<v-toolbar-title>Thiết lập đợt bảo trì</v-toolbar-title>
				<v-btn icon="mdi-close" variant="text" @click="closeDialog" />
			</v-toolbar>

			<v-form ref="form">
				<v-card-text class="pa-4">
					<v-row>
						<v-col cols="12" md="4" lg="4">
							<div class="text-subtitle-2 text-primary mb-2 text-uppercase">1. Thông tin chung</div>
							<v-card variant="outlined" class="pa-3 mb-2 bg-grey-lighten-5">
								<v-text-field v-model="item.TenDotBaoTri" label="Tên đợt bảo trì " density="compact"
									variant="outlined" :rules="[rules.required]" class="mb-2" bg-color="white" />

								<uc-date-picker icon-color="primary" :rules="[rules.required]"
									:min="new Date().toISOString().substr(0, 10)" v-model="item.NgayDuKien"
									label="Ngày dự kiến"></uc-date-picker>
							</v-card>

							<div class="d-flex justify-space-between align-center mb-2">
								<div class="text-subtitle-2 text-primary text-uppercase">2. Checklist công việc</div>
								<v-btn size="x-small" color="primary" variant="text" prepend-icon="mdi-plus"
									@click="addTask">Thêm</v-btn>
							</div>
							<v-card variant="outlined" class="pa-3 bg-grey-lighten-5 mb-2" :style="{
                                overflowY: 'auto',
                                height: !isMobile ? '211px' : null,
                                maxHeight: isMobile ? '200px' : null
                            }">
								<div v-if="item.taskList.length === 0" class="text-caption text-center text-grey py-2">
									Chưa có công việc nào.</div>
								<div v-for="(task, index) in item.taskList" :key="index"
									class="d-flex align-center mb-2">
									<span class="text-caption mr-2 text-grey font-weight-bold">{{ index + 1 }}.</span>
									<v-text-field v-model="task.taskName" placeholder="Tên công việc..."
										density="compact" variant="outlined" bg-color="white" hide-details />
									<v-btn icon="mdi-delete" size="small" color="red" variant="text" class="ml-1"
										@click="removeTask(index)"></v-btn>
								</div>
							</v-card>
							<div class="text-subtitle-2 text-primary mb-2 text-uppercase">3. Phân công trách nhiệm</div>
							<v-card variant="outlined" class="pa-3 bg-grey-lighten-5">
								<v-row>
									<v-col cols="12" md="6" class="border-e-md">
										<div
											class="font-weight-bold text-caption mb-2 text-uppercase text-grey-darken-2">
											<v-icon start size="small">mdi-account-hard-hat</v-icon>
											Đơn vị thực hiện
										</div>

										<v-radio-group v-model="item.OptionsChiuTrachNhiem" inline density="compact"
											hide-details class="mb-2">
											<v-radio label="Đối tác" value="1" color="primary" />
											<v-radio label="Nội bộ" value="2" color="primary" />
										</v-radio-group>

										<v-autocomplete v-if="item.OptionsChiuTrachNhiem === '2'"
											v-model="item.DSNhanVienThucHien" :items="DSNhanVien"
											item-title="HoVaTenNhanVien" item-value="MaNhanVien"
											label="Chọn nhân viên thực hiện" prepend-inner-icon="mdi-account" multiple
											chips closable-chips density="compact" variant="outlined" bg-color="white"
											persistent-hint />

										<v-autocomplete v-else v-model="item.DoiTac_BaoTri_Id" :items="DSDoiTac"
											item-title="TenDoiTac" item-value="DoiTac_BaoTri_Id"
											label="Chọn đơn vị đối tác" prepend-inner-icon="mdi-domain"
											density="compact" variant="outlined" bg-color="white" hide-details />
									</v-col>


									<v-col cols="12" md="6">
										<div
											class="font-weight-bold text-caption mb-2 text-uppercase text-grey-darken-2">
											<v-icon start size="small">mdi-account-eye</v-icon>
											Người giám sát (Nội bộ)
										</div>

										<div style="height: 36px" class="d-none d-md-block"></div>

										<v-autocomplete v-model="item.DSNguoiGiamSat" :items="DSNhanVien"
											item-title="HoVaTenNhanVien" item-value="MaNhanVien"
											label="Chọn người giám sát" prepend-inner-icon="mdi-account-check" multiple
											chips closable-chips density="compact" variant="outlined" bg-color="white"
											persistent-hint />
									</v-col>
								</v-row>
							</v-card>
						</v-col>

						<v-col cols="12" md="8" lg="8">
							<div class="d-flex justify-space-between align-center mb-2">
								<div class="text-subtitle-2 text-primary text-uppercase">4. Chọn tài sản bảo trì</div>
								<div class="text-caption text-grey">Đã chọn: <b class="text-primary">{{
										DSDaChon.length }}</b> tài sản</div>
							</div>

							<v-row dense class="mb-2">
								<v-col cols="12" md="4">
									<v-autocomplete v-model="DiaDiem_Id" density="compact" :items="DSDiaDiem"
										item-value="DiaDiem_Id" item-title="TenDiaDiem" label="Địa điểm">
									</v-autocomplete>
								</v-col>

								<v-col cols="8" md="4">
									<v-text-field v-model="search" density="compact" variant="outlined" label="Tìm kiếm"
										hide-details bg-color="white" prepend-inner-icon="mdi-magnify" />
								</v-col>

								<v-col cols="4" md="4">
									<v-btn color="primary" prepend-icon="mdi-refresh" @click="onLoadData">
										Tải dữ liệu
									</v-btn>
								</v-col>
							</v-row>

							<v-card border class="mb-2">
								<v-data-table v-model="DSDaChon" :headers="headers" :items="DSCaBiet" :search="search"
									show-select item-value="CaBiet_Id" height="350" fixed-header :items-per-page="50"
									items-per-page-text="Bản ghi" :items-per-page-options="[50, 100, 150, 200]" hover>
									<template #item.TinhTrang="{ item }">
										<v-chip :color="mapTinhTrangHangHoaCaBiet[item.TinhTrang].color" size="small"
											variant="tonal">
											{{ mapTinhTrangHangHoaCaBiet[item.TinhTrang].text }}
										</v-chip>
									</template>

									<template #item.ThoiGianKhauHao="{ item }">
										{{ item.ThoiGianKhauHao }} tháng
									</template>

									<template #item.NgayBatDauSuDung="{ item }">
										{{ formatDate(item.NgayBatDauSuDung) }}
									</template>

									<template #item.NgayBatDauBaoHanh="{ item }">
										{{ formatDate(item.NgayBatDauBaoHanh) }}
									</template>

									<template #item.NgayKetThucBaoHanh="{ item }">
										{{ formatDate(item.NgayKetThucBaoHanh) }}
									</template>
								</v-data-table>
							</v-card>

							<v-textarea v-model="item.GhiChu" label="Ghi chú chung" rows="2" variant="outlined"
								density="compact" hide-details class="mt-3" />
						</v-col>
					</v-row>
				</v-card-text>

				<v-divider></v-divider>
				<v-card-actions class="pt-2">
					<v-spacer></v-spacer>
					<v-btn color="grey-darken-1" variant="text" @click="dialog = false">Hủy bỏ</v-btn>
					<v-btn color="primary" variant="elevated" prepend-icon="mdi-check" @click="onSubmit">
						Hoàn tất
					</v-btn>
				</v-card-actions>
			</v-form>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
	    props: {
	        isShow: Boolean,
	        DSDiaDiem: Array,
	        DSDoiTac: Array,
	        DSNhanVien: Array,
	        loadDSDotBaoTri: Function,
	    },
	    data() {
	        return {
	            mapTinhTrangHangHoaCaBiet,
	            search: null,
	            DSDaChon: [],
	
	            rules: {
	                required: v => !!v || 'Trường này không được để trống',
	                greaterThanZero: v => v > 0 || 'Giá trị phải lớn hơn 0',
	                noSpecialChar: v =>
	                    /^[a-zA-Z0-9\s]+$/.test(v) || 'Không được chứa ký tự đặc biệt',
	            },
	            headers: [
	                { title: 'Số series', key: 'SoSeries' },
	                { title: 'Tên tài sản', key: 'TenHangHoa' },
	                { title: 'Địa điểm', key: 'TenDiaDiem' },
	                { title: 'Khu vực', key: 'TenKhuVuc' },
	                { title: 'Tình trạng', key: 'TinhTrang' },
	                { title: 'Khấu hao', key: 'ThoiGianKhauHao' },
	                { title: 'BĐ sử dụng', key: 'NgayBatDauSuDung' },
	                { title: 'BĐ bảo hành', key: 'NgayBatDauBaoHanh' },
	                { title: 'KT bảo hành', key: 'NgayKetThucBaoHanh' },
	            ],
	
	            item: {
	                taskList: [{ taskName: 'Kiểm tra hoạt động' }],
	                DSNguoiGiamSat: [],
	                ChiPhi: null,
	                GhiChu: null,
	                NgayDuKien: new Date()
	            },
	            DSCaBiet: [],
	            DiaDiem_Id: null,
	            localDiaDiem_Id: null
	        };
	    },
	    computed: {
	        isMobile() {
	            return this.$vuetify.display.smAndDown
	        },
	    },
	
	    methods: {
	        formatDate: window.formatDate,
	        closeDialog() {
	            this.item = {
	                taskList: [{ taskName: 'Kiểm tra hoạt động' }],
	                DSNguoiGiamSat: [],
	                ChiPhi: null,
	                GhiChu: null,
	                NgayThucHien: new Date()
	            }
	            this.$emit('update:isShow', false)
	        },
	        addTask() {
	            this.item.taskList.push({ taskName: '' });
	        },
	        removeTask(index) {
	            this.item.taskList.splice(index, 1);
	        },
	
	        async onLoadData() {
	            if (this.DiaDiem_Id === null || this.DiaDiem_Id === undefined) return showToast.info('Vui lòng chọn địa điểm')
	            const params = {
	                DiaDiem_Id: this.DiaDiem_Id
	            }
	            const data = await apiCallPromise('work/TS_CaBiet_Select_By_DiaDiem_Id', params)
	            this.localDiaDiem_Id = this.DiaDiem_Id
	            this.DSDaChon = []
	            this.DSCaBiet = data
	        },
	
	        async onSubmit() {
	            const { valid } = await this.$refs.form.validate();
	            if (!valid || this.DSDaChon.length === 0) return showToast.info("Vui lòng kiểm tra lại thông tin!");
	
	            const cleanTaskList = this.item.taskList.filter(t => t.taskName && t.taskName.trim() !== '').map(t => t.taskName);
	            const jsonTaskList = cleanTaskList.join(',');
	
	            let strNhanVien = "";
	            if (this.item.OptionsChiuTrachNhiem === '2') {
	                strNhanVien = this.item.DSNhanVienThucHien.join(',');
	            }
	            let strGiamSat = this.item.DSNguoiGiamSat.join(',');
	            const params = {
	                TenDotBaoTri: this.item.TenDotBaoTri,
	                DiaDiem_Id: this.localDiaDiem_Id,
	                NgayDuKien: this.item.NgayDuKien,
	                DoiTac_BaoTri_Id: this.item.OptionsChiuTrachNhiem === '1' ? this.item.DoiTac_BaoTri_Id : undefined,
	                GhiChu: this.item.GhiChu,
	                OptionsChiuTrachNhiem: this.item.OptionsChiuTrachNhiem ?? 0,
	                ListNhanVienThucHien: this.item.OptionsChiuTrachNhiem === '2' ? strNhanVien : undefined,
	                ListTaskList: jsonTaskList,
	                ListNhanVienGiamSat: strGiamSat,
	                ListCaBiet: this.DSDaChon.join(',')
	            }
	            const $this = this
	            apiCall('work/TS_DotBaoTri_Insert', params, () => {
	                showToast.success('Tạo mới đợt bảo trì thành công')
	                $this.loadDSDotBaoTri()
	                $this.closeDialog()
	            })
	
	        },
	    }
	}
</script>