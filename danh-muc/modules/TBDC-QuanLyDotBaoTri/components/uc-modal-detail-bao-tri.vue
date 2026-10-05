<template>
	<v-dialog v-model="isShow" :fullscreen="isMobile" :max-width="isMobile ? '100%' : 1300"
		:transition="isMobile ? 'dialog-bottom-transition' : 'dialog-transition'">
		<v-card class="d-flex flex-column h-100">
			<v-toolbar density="compact" color="primary">
				<v-toolbar-title class="font-weight-bold text-subtitle-1 text-truncate">
					{{ selectedItem ? formatDate(selectedItem.NgayDuKien) + ' | ' +
						selectedItem.TenDotBaoTri
						: '' }}
				</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn variant="text" prepend-icon="mdi-account-group" @click="openDialogNhanSu">
					<span class="d-none d-sm-inline">Nhân sự phụ trách</span>
				</v-btn>
				<v-btn icon="mdi-close" @click="closeDialog" />
			</v-toolbar>
			<!-- Điện thoại -->
			<div v-if="isMobile" class="bg-white border-b elevation-1" style="z-index: 1;">
				<v-container class="pa-2">
					<div class="d-flex align-center mb-2">
						<v-text-field v-model="search" density="compact" variant="outlined" placeholder="Tìm tên..."
							hide-details prepend-inner-icon="mdi-magnify" bg-color="grey-lighten-5"
							class="rounded-lg flex-grow-1" />
					</div>
				</v-container>
			</div>
			<!-- Desktop -->
			<v-toolbar v-if="!isMobile" density="compact" flat color="grey-lighten-4" class="border-b">
				<v-row align="center" class="px-2 w-100">
					<v-col cols="3">
						<v-text-field class="mt-1" v-model="search" density="compact" variant="outlined"
							label="Tìm kiếm" hide-details bg-color="white" prepend-inner-icon="mdi-magnify" />
					</v-col>
				</v-row>
			</v-toolbar>

			<v-card-text class="pa-0 flex-grow-1 bg-grey-lighten-4 position-relative">
				<!-- Desktop -->
				<v-data-table v-if="!isMobile" :headers="headers" :items="selectedItem.Detail" :search="search"
					height="600" fixed-header hide-default-footer>

					<template #item.MaVach="{ item }">
						{{ item.MaVach === '' ? 'Chưa có' : item.MaVach }}
					</template>

					<template #item.TienDo="{ item }">
						<v-progress-linear :model-value="calculateProgress(item)" color="primary" height="15" rounded>
							<template v-slot:default="{ value }">
								<strong style="font-size: 10px; color: white">{{ Math.ceil(value) }}%</strong>
							</template>
						</v-progress-linear>
					</template>

					<template #item.TinhTrangSauBaoTri="{ item }">
						<div v-if="!isCheckListDone(item)" class="text-caption text-orange d-flex align-center">
							<v-icon size="small" start color="orange">mdi-alert-circle-outline</v-icon>
							<span>Chưa xong việc</span>
						</div>
						<v-chip v-if="item.TinhTrangSauBaoTri !== '' && item.TinhTrangSauBaoTri !== null"
							:color="item.TinhTrangSauBaoTri === 'BINH_THUONG' ? 'success' : 'error'" size="small"
							variant="flat">{{ item.TinhTrangSauBaoTri ===
								'BINH_THUONG' ? 'Tốt' :
								'Hỏng' }}</v-chip>
					</template>

					<template #item.ChiPhiBaoTri="{ item }">
						{{ formatCurrency(item.ChiPhiBaoTri) }}
					</template>

					<template #item.HoVaTenNhanVien="{ item }">
						<v-chip v-if="item.HoVaTenNhanVien" size="small">
							{{ item.HoVaTenNhanVien }}
						</v-chip>
					</template>
					<template #item.actions="{ item }">
						<v-btn size="small" icon="mdi-clipboard-text-outline" variant="text" color="primary"
							@click="onOpenViewDetail(item)" />
					</template>
				</v-data-table>
				<!-- Mobile -->
				<div v-else class="pa-2 pb-16" style="height: calc(100dvh - 104px); overflow-y: auto;">
					<div v-if="filteredMobileList.length === 0" class="text-center mt-10 text-grey">
						Không có dữ liệu
					</div>
					<v-card v-for="(item, i) in filteredMobileList" :key="item.CaBiet_Id"
						class="mb-3 rounded-lg elevation-2" :class="{
							'border-success': item.TinhTrangSauBaoTri === 'BINH_THUONG',
							'border-error': item.TinhTrangSauBaoTri === 'HONG',
						}" style="border-left: 4px solid transparent;">
						<div class="pa-3">
							<div class="d-flex justify-space-between mb-2" @click="toggleExpand(item)">
								<div style="max-width: 75%">
									<div class="text-subtitle-2 font-weight-bold text-primary text-truncate">{{
										item.TenHangHoa }}</div>
									<div class="text-caption text-grey-darken-2 mt-1">
										Mã: {{ item.MaVach === '' ? 'Chưa có' : item.MaVach }}
									</div>
									<div class="text-caption text-grey-darken-1 d-flex align-center mt-1">
										<v-icon size="x-small" start class="mr-1">mdi-map-marker</v-icon>
										{{ item.TenKhuVuc || 'Không rõ' }}
									</div>
									<div class="text-caption text-grey-darken-1 d-flex align-center mt-1">
										<v-chip
											v-if="item.TinhTrangSauBaoTri !== '' && item.TinhTrangSauBaoTri !== null"
											:color="item.TinhTrangSauBaoTri === 'BINH_THUONG' ? 'success' : 'error'"
											size="small" variant="flat">{{ item.TinhTrangSauBaoTri ===
												'BINH_THUONG' ? 'Tốt' :
												'Hỏng' }}</v-chip>
									</div>
									<v-chip size="x-small" v-if="item.HoVaTenNhanVien" class="mt-1">
										<v-icon size="x-small" start>mdi-account</v-icon> {{ item.HoVaTenNhanVien }}
									</v-chip>
								</div>
								<div class="text-center cursor-pointer">
									<v-progress-circular :model-value="calculateProgress(item)" size="36" width="3"
										:color="calculateProgress(item) === 100 ? 'green' : 'grey-darken-1'"
										class="mb-1">
										<span style="font-size: 10px; font-weight: bold">{{ CheckListCount(item)
										}}</span>
									</v-progress-circular>
									<div class="mt-n1">
										<v-icon :icon="item.isExpanded ? 'mdi-chevron-up' : 'mdi-chevron-down'"
											size="small" color="grey"></v-icon>
									</div>
								</div>
							</div>

							<div v-if="!isCheckListDone(item)" class="text-caption text-center text-orange mb-2">
								<v-icon size="x-small" color="orange" start>mdi-information-outline</v-icon> Chưa
								hoàn thành
							</div>
							<v-expand-transition>
								<div v-if="item.isExpanded" class="pt-2 border-t mt-2 bg-grey-lighten-5 pa-3 rounded">
									<div class="mb-3">
										<div class="d-flex align-center mb-2">
											<v-icon size="small" start color="primary">mdi-format-list-checks</v-icon>
											<span class="text-caption font-weight-bold text-uppercase text-primary">Công
												việc cần làm</span>
										</div>
										<v-card variant="outlined" class="bg-white">
											<div v-if="!item.CheckList || item.CheckList.length === 0"
												class="pa-2 text-caption text-grey font-italic text-center">Không có
												công việc cụ thể.</div>
											<div v-else v-for="(task, idx) in item.CheckList" :key="idx"
												class="d-flex align-center px-2 py-1 border-b">
												<v-icon size="small" :color="task.DaThucHien ? 'success' : 'grey'">
													{{ task.DaThucHien ? 'mdi-check-circle' : 'mdi-circle-outline'
													}}
												</v-icon>

												<span class="text-body-2 ml-2"
													:class="{ 'text-decoration-line-through text-grey': task.DaThucHien }">
													{{ task.TenCongViec }}
												</span>
											</div>
										</v-card>
									</div>
									<v-row dense>
										<v-col cols="12">
											<div class="mb-2">
												<div class="text-caption text-grey mb-1">Ghi chú / Lỗi</div>
												<div class="text-body-2">
													{{ item.GhiChu || 'Không có ghi chú' }}
												</div>
											</div>
										</v-col>
										<v-col cols="12">
											<div>
												<div class="text-caption text-grey mb-1">Chi phí</div>
												<div class="font-weight-medium text-primary">
													{{ formatCurrency(item.ChiPhiBaoTri) }}
												</div>
											</div>
										</v-col>

									</v-row>
								</div>
							</v-expand-transition>
						</div>
					</v-card>
				</div>
			</v-card-text>
			<v-footer :app="isMobile" color="white" class="border-t elevation-4 d-flex flex-column pa-2"
				style='z-index: 1200;'>

				<div class="d-flex justify-space-between w-100 mb-2 align-center px-1">
					<span class="text-body-2 text-grey-darken-1">Tổng chi phí:</span>
					<span class="text-h6 font-weight-bold text-primary">{{ formatCurrency(TongChiPhi) }}</span>
				</div>
			</v-footer>
		</v-card>

		<v-dialog v-model="isShowDialogBaoTri" max-width="600">
			<v-card>
				<v-toolbar :title="'Chi tiết: ' + (BaoTri ? BaoTri.TenHangHoa : '')" density="compact" color="primary">
					<v-btn icon="mdi-close" @click="closeDialogBaoTri"></v-btn>
				</v-toolbar>

				<v-card-text class="pt-4">
					<div class="mb-4 border rounded pa-3">

						<div class="text-subtitle-2 text-primary mb-2 font-weight-bold">
							<v-icon start size="small">mdi-checkbox-marked-outline</v-icon>
							Danh sách công việc
						</div>

						<div v-if="!BaoTri || !BaoTri.CheckList || BaoTri.CheckList.length === 0"
							class="text-grey text-caption text-center">
							Không có công việc.
						</div>

						<v-list density="compact" class="pa-0">
							<v-list-item v-for="(task, idx) in (BaoTri ? BaoTri.CheckList : [])" :key="idx"
								class="pa-0">
								<template v-slot:prepend>
									<v-checkbox-btn :model-value="task.DaThucHien" color="primary" disabled />
								</template>

								<v-list-item-title>
									{{ task.TenCongViec }}
								</v-list-item-title>
							</v-list-item>
						</v-list>

					</div>

					<v-row dense>

						<v-col cols="12">
							<div class="text-caption text-grey">Tình trạng sau bảo trì</div>

							<v-chip
								:color="BaoTri?.TinhTrangSauBaoTri === 'BINH_THUONG' ? 'success' : BaoTri?.TinhTrangSauBaoTri === 'HONG' ? 'error' : 'grey'"
								variant="tonal">
								{{
									BaoTri?.TinhTrangSauBaoTri === 'BINH_THUONG'
										? 'Bình thường'
										: BaoTri?.TinhTrangSauBaoTri === 'HONG'
											? 'Hỏng'
											: 'Chưa rõ'
								}}
							</v-chip>
						</v-col>

						<v-col cols="12">
							<div class="text-caption text-grey">Chi phí</div>
							<div class="text-body-1 font-weight-medium">
								{{ formatCurrency(BaoTri?.ChiPhiBaoTri) }}
							</div>
						</v-col>

						<v-col cols="12">
							<div class="text-caption text-grey">Ghi chú / Lỗi</div>
							<div class="text-body-2">
								{{ BaoTri?.GhiChu || 'Không có ghi chú' }}
							</div>
						</v-col>

					</v-row>
				</v-card-text>
			</v-card>
		</v-dialog>

		<!-- Phân công -->
		<v-dialog v-model="isShowDialogNhanSu" max-width="600" persistent>
			<v-card>
				<v-toolbar title="Phân công nhân sự" density="compact" color="primary">
				</v-toolbar>
				<v-card-text class="pt-4">
					<v-row dense>
						<v-col cols="12">
							<div class="font-weight-bold text-caption mb-2 text-uppercase text-grey-darken-2">
								<v-icon start size="small">mdi-account-hard-hat</v-icon> Đơn vị thực hiện
							</div>

							<v-radio-group v-model="selectedItem.LoaiHinhThucHien" inline density="compact"
								hide-details="auto" class="mb-2" :rules="[rules.required]">
								<v-radio label="Đối tác" value='THUE_NGOAI' color="primary"></v-radio>
								<v-radio label="Nội bộ" value='NOI_BO' color="primary"></v-radio>
							</v-radio-group>

							<div v-if="selectedItem.LoaiHinhThucHien == 'NOI_BO'">
								<v-autocomplete class="mb-2" v-model="selectedItem.NguoiThucHien"
									:rules="[rules.required]" :items="DSNhanVien" item-title="HoVaTenNhanVien"
									item-value="MaNhanVien" label="Chọn nhân viên thực hiện" multiple chips
									hide-details="auto" closable-chips density="compact" variant="outlined"
									persistent-hint prepend-inner-icon="mdi-account">
									<template v-slot:chip="{ props, item }">
										<v-chip v-bind="props" :text="item.raw.HoVaTenNhanVien" label
											size="small"></v-chip>
									</template>
								</v-autocomplete>
							</div>

							<div v-else>
								<v-autocomplete class="mb-2" v-model="selectedItem.DoiTacThucHien"
									:rules="[rules.required]" :items="DSDoiTacBaoTri" item-title="TenDoiTac"
									hide-details="auto" item-value="DoiTac_BaoTri_Id" label="Chọn đơn vị đối tác"
									density="compact" variant="outlined" prepend-inner-icon="mdi-domain" />
							</div>
						</v-col>
						<v-col cols="12">
							<v-autocomplete class="mb-2" v-model="selectedItem.NguoiGiamSat" :items="DSNhanVien"
								:rules="[rules.required]" item-title="HoVaTenNhanVien" item-value="MaNhanVien"
								label="Người giám sát" multiple chips closable-chips variant="outlined"
								hide-details="auto" prepend-inner-icon="mdi-account-eye">
								<template v-slot:chip="{ props, item }">
									<v-chip v-bind="props" :text="item.raw.HoVaTenNhanVien" label size="small"></v-chip>
								</template>
							</v-autocomplete>
						</v-col>
					</v-row>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn color="primary" variant="elevated" @click="onSaveNhanSu">Lưu phân công</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</v-dialog>
</template>

<script>
export default {
	props: {
		isShow: Boolean,
		selectedItem: Object,
		DSNhanVien: Array,
		DSDoiTacBaoTri: Array,
	},
	data() {
		return {
			rules: {
				required: (value) => !!value || 'Trường này không được để trống',
			},

			headers: [
				{ title: 'STT', key: 'STT', align: 'center', width: '50px' },
				{ title: 'Tên tài sản', key: 'TenHangHoa', width: '180px' },
				{ title: 'Số Series', key: 'SoSeries', width: '180px' },
				{ title: 'Mã', key: 'MaVach' },
				{ title: 'Tiến độ', key: 'TienDo', align: 'center', width: '120px' },
				{ title: 'Đánh giá', key: 'TinhTrangSauBaoTri' },
				{ title: 'Chi phí', key: 'ChiPhiBaoTri', align: 'end' },
				{ title: 'Ghi chú', key: 'GhiChuBaoTri' },
				{ title: 'Người bảo trì', key: 'HoVaTenNhanVien' },
				{ title: '', key: 'actions', align: 'center' },
			],
			search: null,
			isShowDialogNhanSu: false,
			isShowDialogBaoTri: false,

			BaoTri: {
				CheckList: [],
				ChiPhiBaoTri: null,
				GhiChu: null,
			},

		};
	},
	computed: {
		isMobile() {
			return this.$vuetify.display.smAndDown;
		},

		filteredMobileList() {
			if (!this.search) return this.selectedItem.Detail;
			var s = this.search.toLowerCase();
			return this.selectedItem.Detail.filter(function (i) {
				return i.TenHangHoa.toLowerCase().includes(s);
			});
		},
		TongChiPhi() {
			return this.selectedItem.Detail.map(item => item.ChiPhiBaoTri).reduce(
				(accumulator, currentValue) => accumulator + currentValue,
				0,
			);
		},
	},
	watch: {
	},
	mounted() {
	},
	methods: {
		formatDate: window.formatDate,

		closeDialog() {
			this.$emit('update:isShow', false)
		},

		closeDialogBaoTri() {
			this.isShowDialogBaoTri = false
		},

		closeDialogNhanSu() {
			this.isShowDialogNhanSu = false
		},

		openDialogNhanSu() {
			this.isShowDialogNhanSu = true
		},

		formatCurrency(val) {
			return val ? new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val) : '0 ₫';
		},

		calculateProgress(item) {
			if (!item.CheckList || item.CheckList.length === 0) return 0;
			var doneCount = item.CheckList.filter(function (t) { return t.DaThucHien; }).length;
			return (doneCount / item.CheckList.length) * 100;
		},

		isCheckListDone(item) {
			if (!item || !item.CheckList || item.CheckList.length === 0) return true;
			return item.CheckList.every(function (task) { return task.DaThucHien === true; });
		},

		CheckListCount(item) {
			if (!item.CheckList) return "0/0";
			var doneCount = item.CheckList.filter(t => t.DaThucHien === true).length;
			return doneCount + '/' + item.CheckList.length;
		},

		toggleExpand(item) {
			if (item.CheckList.length === 0)
				item.CheckList = this.selectedItem.TaskList.map(i => ({ ...i }))
			item.isExpanded = !item.isExpanded;
		},

		async onOpenViewDetail(item) {
			this.BaoTri = {
				...item,
				CheckList: item.CheckList?.length
					? item.CheckList.map(i => ({ ...i }))
					: this.selectedItem.TaskList.map(i => ({ ...i })),
			}
			this.isShowDialogBaoTri = true;
		},

		onSaveNhanSu() {
			if (this.selectedItem.LoaiHinhThucHien === null) return showToast.info('Chưa chọn loại hình bảo trì')
			if (this.selectedItem.LoaiHinhThucHien === 'THUE_NGOAI' && this.selectedItem.DoiTacThucHien === null) return showToast.info('Chưa chọn đối tác bảo trì')
			if (this.selectedItem.LoaiHinhThucHien === 'NOI_BO' && (this.selectedItem.NguoiThucHien === null || this.selectedItem.NguoiThucHien?.length === 0)) return showToast.info('Chưa chọn nhân viên thực hiện')
			if (this.selectedItem.NguoiGiamSat?.length === 0) return showToast.info('Chưa chọn nhân viên giám sát')

			const params = {
				DotBaoTri_Id: this.selectedItem.DotBaoTri_Id,
				LoaiHinhThucHien: this.selectedItem.LoaiHinhThucHien,
				DoiTacThucHien: this.selectedItem.LoaiHinhThucHien === 'THUE_NGOAI' ? this.selectedItem.DoiTacThucHien : 0,
				ListNguoiThucHien: this.selectedItem.LoaiHinhThucHien === 'NOI_BO' ? this.selectedItem.NguoiThucHien.join(',') : null,
				ListNguoiGiamSat: this.selectedItem.NguoiGiamSat.join(',')
			}
			const $this = this
			apiCall('work/TS_DotBaoTri_Update_NhanSu', params, () => {
				showToast.success('Cập nhật nhân sự đợt bảo trì thành công')
				$this.closeDialogNhanSu()
			})
		},
	}
}
</script>