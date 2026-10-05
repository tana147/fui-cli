<template>
	<Global>
		<template #header>
			<v-card>
				<v-card-title class="text-primary d-flex align-center flex-wrap ga-2">
					<span>{{ isEn ? 'Semester Summary' : 'Tổng kết học kì' }}</span>
					<span v-if="vueData.CapID">• {{ titleCap }}</span>
					<v-chip variant="text" color="primary" class="font-weight-medium">
						{{ isEn ? 'Total students:' : 'Tổng số học sinh:' }} {{ vueData.DSHocSinh.length }}
					</v-chip>
					<v-spacer />
					<v-btn-toggle v-model="isEn" size="small" class="ml-auto">
						<v-btn :value="false" :disabled="!isEn" :color="!isEn ? 'green' : 'white'" @click="setLanguage(false)">
							<v-img src="/_cdn/lhbs-lms/img_page_ph/Viet.png" width="30" />
						</v-btn>
						<v-btn :value="true" :disabled="isEn" :color="isEn ? 'green' : 'white'" @click="setLanguage(true)">
							<v-img src="/_cdn/lhbs-lms/img_page_ph/Anh.png" width="30" />
						</v-btn>
					</v-btn-toggle>
				</v-card-title>
				<v-card-text>
					<!-- Hàng 1: Filters -->
					<v-row align="center">
						<v-col cols="12" sm="4">
							<v-select :key="'sem_' + isEn" v-model="vueData.Semester" :label="isEn ? 'Select semester' : 'Chọn học kì'" :items="vueData.DSSemester"
								hide-details :item-title="formatSemesterTitle" item-value="value" return-object
								:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
								<template #selection="{ item }">
									<span>{{ formatSemesterTitle(item) }}</span>
								</template>
								<template #item="{ props, item }">
									<v-list-item v-bind="props" :title="formatSemesterTitle(item)"></v-list-item>
								</template>
							</v-select>
						</v-col>
						<v-col cols="12" sm="4">
							<v-select :key="'khoi_' + isEn" v-model="vueData.KhoiItem" :label="isEn ? 'Select grade' : 'Chọn khối'"
								:items="khoiItems"
								:item-title="formatKhoiTitle" item-value="KhoiID" return-object hide-details
								:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
								<template #selection="{ item }">
									<span>{{ formatKhoiTitle(item) }}</span>
								</template>
								<template #item="{ props, item }">
									<v-list-item v-bind="props" :title="formatKhoiTitle(item)"></v-list-item>
								</template>
							</v-select>
						</v-col>
						<v-col cols="12" sm="4" v-if="!vueData.KhoiItem?.isAll">
							<v-select :key="'lop_' + isEn" v-model="vueData.LopItem" :label="isEn ? 'Select class' : 'Chọn lớp'"
								:items="lopItems"
								:item-title="formatLopTitle" item-value="LopID" return-object hide-details
								:no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
								<template #selection="{ item }">
									<span>{{ formatLopTitle(item) }}</span>
								</template>
								<template #item="{ props, item }">
									<v-list-item v-bind="props" :title="formatLopTitle(item)"></v-list-item>
								</template>
							</v-select>
						</v-col>
					</v-row>
					<!-- Hàng 2: Actions -->
					<v-row class="mt-1">
						<v-col cols="12" class="d-flex align-center ga-2 flex-wrap">
							<v-btn variant="outlined" prepend-icon="mdi-refresh" color="primary"
								:disabled="!vueData.KhoiItem || (!vueData.KhoiItem?.isAll && !vueData.LopItem)"
								@click="vueData.KhoiItem?.isAll ? vueData.getDSTatCaKhoi() : vueData.TongKet_GetDTBMonHocByKhoiLop()">
								{{ isEn ? 'Refresh' : 'Làm mới' }}
							</v-btn>
							<v-spacer />
							<v-btn variant="outlined" prepend-icon="mdi-table-arrow-down" color="teal"
								:disabled="vueData.DSHocSinh.length === 0" @click="vueData.openImportKQRL()">
								{{ isEn ? 'Import Conduct' : 'Import KQRL' }}
							</v-btn>
							<v-btn variant="outlined" prepend-icon="mdi-content-save" color="success"
								@click="vueData.onSave()" :disabled="vueData.DSHocSinh.length === 0">
								{{ isEn ? 'Save' : 'Lưu' }}
							</v-btn>
							<v-btn variant="outlined" prepend-icon="mdi-microsoft-excel" color="green"
								:disabled="vueData.DSHocSinh.length === 0" @click="vueData.exportExcel()">
								Export Excel
							</v-btn>
							<v-btn variant="outlined" prepend-icon="mdi-certificate-outline" color="orange"
								:disabled="vueData.DSHocSinh.length === 0" :loading="vueData.isLoadingExportGiayKhen"
								@click="vueData.exportGiayKhen()">
								{{ isEn ? 'Export Certificates' : 'Export Giấy khen' }}
							</v-btn>
						</v-col>
					</v-row>
				</v-card-text>
			</v-card>
		</template>

		<v-card>
			<v-card-text class="pa-0">
				<uc-xem-tong-ket-hk />
			</v-card-text>
		</v-card>

		<v-dialog v-model="vueData.loadingDialog.show" persistent width="400">
			<v-card>
				<v-card-title class="text-subtitle-1">{{ vueData.loadingDialog.title }}</v-card-title>
				<v-card-text>
					<template v-if="vueData.loadingDialog.total > 0">
						<div class="mb-1 text-body-2">
							{{ isEn ? 'Grade:' : 'Khối:' }} <strong>{{ vueData.loadingDialog.currentName }}</strong>
							({{ vueData.loadingDialog.current }}/{{ vueData.loadingDialog.total }})
						</div>
						<v-progress-linear
							:model-value="vueData.loadingDialog.total ? (vueData.loadingDialog.current / vueData.loadingDialog.total) * 100 : 0"
							color="primary" rounded height="8" class="mb-3" />
					</template>
					<div class="mb-1 text-body-2">
						{{ isEn ? 'Class:' : 'Lớp:' }} <strong>{{ vueData.loadingDialog.currentLopName }}</strong>
						<span v-if="vueData.loadingDialog.totalLop > 0">
							({{ vueData.loadingDialog.currentLop }}/{{ vueData.loadingDialog.totalLop }})
						</span>
					</div>
					<v-progress-linear
						:model-value="vueData.loadingDialog.totalLop ? (vueData.loadingDialog.currentLop / vueData.loadingDialog.totalLop) * 100 : 0"
						color="teal" rounded height="8" />
				</v-card-text>
			</v-card>
		</v-dialog>

		<v-dialog v-model="vueData.IsShowDialogImportKQRL" :width="700" persistent>
			<v-card :title="isEn ? 'Import Conduct (KQRL) from Excel' : 'Import KQRL từ Excel'">
				<v-card-text>
					<p class="text-caption text-medium-emphasis mb-2">
						<template v-if="isEn">
							Copy 2 columns <strong>HocSinhID</strong> and <strong>KQRL</strong> from Excel then paste (Ctrl+V) into the table below.
							Then click <strong>Apply</strong> to update the list.
						</template>
						<template v-else>
							Copy 2 cột <strong>HocSinhID</strong> và <strong>KQRL</strong> từ Excel rồi paste (Ctrl+V) vào bảng bên dưới.
							Sau đó nhấn <strong>Áp dụng</strong> để cập nhật danh sách.
						</template>
					</p>
					<uc-jexcel v-model="vueData.importKQRL_Instance" v-model:dataSource="vueData.ImportKQRL_Data"
						:columns="vueData.importKQRL_Columns" :key="vueData.importKQRL_Key"
						style="max-height: 400px; overflow: auto;" />
				</v-card-text>
				<v-card-actions>
					<v-spacer />
					<v-btn variant="outlined" @click="vueData.IsShowDialogImportKQRL = false">{{ isEn ? 'Close' : 'Đóng' }}</v-btn>
					<v-btn variant="flat" color="teal" @click="vueData.applyImportKQRL()">{{ isEn ? 'Apply' : 'Áp dụng' }}</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<v-dialog v-model="vueData.IsShowDialogConfirm" :width="600">
			<v-card :title="isEn ? 'Confirm before saving' : 'Xác nhận trước khi lưu'">
				<v-card-text>
					<v-list>
						<v-list-item v-for="hocSinh in vueData.renderDSHocSinhChange()"
							:title="hocSinh.HoTen + ' - ' + hocSinh.KQRenLuyen" />
					</v-list>
				</v-card-text>
				<v-card-actions>
					<v-spacer />
					<v-btn variant="outlined" @click="vueData.IsShowDialogConfirm = false">{{ isEn ? 'Close' : 'Đóng' }}</v-btn>
					<v-btn variant="flat" color="primary" @click="vueData.onSave()">{{ isEn ? 'Confirm' : 'Xác nhận' }}</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</Global>
</template>

<script>
	export default {
		inject: ['snackbarRef'],
		data() {
			return {
				isEn: JSON.parse(localStorage.getItem('IsLanguage')) ?? false,
				vueData
			}
		},
		computed: {
			titleCap() {
				const capId = parseInt(this.vueData.CapID);
				if (this.isEn) {
					if (capId === 1) return 'Primary';
					if (capId === 2) return 'Secondary';
					if (capId === 3) return 'High School';
					return 'Level ' + capId;
				}
				return renderText(capId);
			},
			khoiItems() {
				const allItem = { TenKhoiHoc: this.isEn ? 'All grades' : 'Tất cả các khối', KhoiID: '__all__', isAll: true };
				const capId = parseInt(this.vueData.CapID);
				let list = this.vueData.DSKhoi || [];
				if (capId === 2) {
					list = list.filter(item => item.KhoiID >= 6 && item.KhoiID <= 9);
				} else if (capId === 3) {
					list = list.filter(item => item.KhoiID >= 10 && item.KhoiID <= 12);
				} else {
					list = list.filter(item => item.KhoiID >= 6);
				}
				return [allItem, ...list];
			},
			lopItems() {
				const allItem = { TenLop: this.isEn ? 'View all classes' : 'Xem tất cả các lớp', LopID: 'ALL' };
				const list = (this.vueData.DSLop || []).filter(item => !item.LopID.includes('N'));
				return [allItem, ...list];
			}
		},
		watch: {
			'vueData.KhoiItem'(v) {
				if (v?.isAll) this.vueData.getDSTatCaKhoi?.();
			},
			isEn(val) {
				this.vueData.isEn = val;
				if (this.vueData.dataDiem && this.vueData.dataDiem.length > 0) {
					this.vueData.initSpread?.();
				}
			}
		},
		mounted() {
			this.vueData.snackbarRef = this.snackbarRef;
			this.vueData.isEn = this.isEn;
			window.addEventListener('storage', this.handleStorageChange);
		},
		beforeUnmount() {
			window.removeEventListener('storage', this.handleStorageChange);
		},
		methods: {
			setLanguage(val) {
				this.isEn = val;
				this.vueData.isEn = val;
				if (this.$i18n) this.$i18n.locale = val ? 'en' : 'vi';
				localStorage.setItem('IsLanguage', JSON.stringify(val));
			},
			handleStorageChange(event) {
				if (event.key === 'IsLanguage') {
					this.isEn = JSON.parse(event.newValue) ?? false;
					this.vueData.isEn = this.isEn;
				}
			},
			formatSemesterTitle(item) {
				if (!item) return '';
				const raw = (item && item.raw) ? item.raw : item;
				if (this.isEn) {
					if (raw.value === 1) return 'Semester 1';
					if (raw.value === 2) return 'Semester 2';
					if (raw.value === 0) return 'Full year';
				}
				return raw.title || '';
			},
			formatKhoiTitle(item) {
				if (!item) return '';
				const raw = (item && item.raw) ? item.raw : item;
				if (raw.isAll) return this.isEn ? 'All grades' : 'Tất cả các khối';
				const name = typeof raw === 'object' ? (raw.TenKhoiHoc || raw.title) : raw;
				if (!name) return '';
				if (!this.isEn) return name;
				return String(name).replace(/Khối/gi, 'Grade');
			},
			formatLopTitle(item) {
				if (!item) return '';
				const raw = (item && item.raw) ? item.raw : item;
				if (raw.LopID === 'ALL') return this.isEn ? 'View all classes' : 'Xem tất cả các lớp';
				return raw.TenLop || '';
			}
		}
	}
</script>