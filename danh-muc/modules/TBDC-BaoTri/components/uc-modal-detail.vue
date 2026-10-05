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
			<div v-if="isMobile && !isLocked" class="bg-white border-b elevation-1" style="z-index: 1;">
				<v-container class="pa-2">
					<div class="d-flex align-center mb-2">
						<v-text-field v-model="search" density="compact" variant="outlined" placeholder="Tìm tên..."
							hide-details prepend-inner-icon="mdi-magnify" bg-color="grey-lighten-5"
							class="rounded-lg flex-grow-1" />
						<v-btn class="ml-2" color="primary" variant="tonal" icon="mdi-qrcode-scan" rounded="lg"
							size="large" @click="onOpenDiaglogQr"></v-btn>
					</div>
				</v-container>
			</div>
			<!-- Desktop -->
			<v-toolbar v-if="!isMobile && !isLocked" density="compact" flat color="grey-lighten-4" class="border-b">
				<v-row align="center" class="px-2 w-100">
					<v-col cols="3">
						<v-text-field class="mt-1" v-model="search" density="compact" variant="outlined"
							label="Tìm kiếm" hide-details bg-color="white" prepend-inner-icon="mdi-magnify" />
					</v-col>
				</v-row>
			</v-toolbar>

			<v-card-text class="pa-0 flex-grow-1 bg-grey-lighten-4 position-relative">
				<v-overlay :model-value="isLocked" contained persistent class="align-center justify-center">
					<div class="text-center">
						<v-icon size="40" color="grey">mdi-lock</v-icon>
						<div class="text-caption mt-2">Chưa phân công nhân sự</div>
					</div>
				</v-overlay>
				<!-- Desktop -->
				<v-data-table v-if="!isMobile" :headers="headers" :items="selectedItem.Detail" :search="search"
					height="600" fixed-header hide-default-footer>

					<template #item.MaVach="{ item }">
						{{ item.MaVach === '' ? 'Chưa có' : item.MaVach }}
					</template>

					<template #item.TienDo="{ item }">
						<div class="d-flex align-center cursor-pointer" @click="onOpenEditDetail(item)">
							<v-progress-linear :model-value="calculateProgress(item)" color="primary" height="15"
								rounded>
								<template v-slot:default="{ value }">
									<strong style="font-size: 10px; color: white">{{ Math.ceil(value) }}%</strong>
								</template>
							</v-progress-linear>
						</div>
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
						<v-btn size="small" icon="mdi-wrench-outline" variant="text" color="orange"
							@click="onOpenEditDetail(item)" />
					</template>
				</v-data-table>
				<!-- Mobile -->
				<div v-else class="pa-2 pb-16" style="height: calc(100dvh - 136px); overflow-y: auto;">
					<div v-if="filteredMobileList.length === 0" class="text-center mt-10 text-grey">
						Không có dữ liệu
					</div>
					<v-card v-for="(item, i) in filteredMobileList" :key="item.CaBiet_Id"
						class="mb-3 rounded-lg elevation-2" :class="{
							'border-success': item.TinhTrangSauBaoTri === 'BINH_THUONG',
							'border-error': item.TinhTrangSauBaoTri === 'HONG',
							'scanned-highlight': item.CaBiet_Id === CaBiet_Id_Highlight
						}" style="border-left: 4px solid transparent;">
						<v-form :ref="el => { formRefs[item.CaBiet_Id] = el }">
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
									<div v-if="item.isExpanded"
										class="pt-2 border-t mt-2 bg-grey-lighten-5 pa-3 rounded">
										<div class="mb-3">
											<div class="d-flex align-center mb-2">
												<v-icon size="small" start
													color="primary">mdi-format-list-checks</v-icon>
												<span
													class="text-caption font-weight-bold text-uppercase text-primary">Công
													việc cần làm</span>
											</div>
											<v-btn block variant="outlined" color="primary" size="small" class="mb-2"
												prepend-icon="mdi-check-all"
												:disabled="isCheckListDone(item) || !item.CheckList || item.CheckList.length === 0"
												@click.stop="() => { checkAllCheckList(item) }">
												Xong hết
											</v-btn>
											<v-card variant="outlined" class="bg-white">
												<div v-if="!item.CheckList || item.CheckList.length === 0"
													class="pa-2 text-caption text-grey font-italic text-center">Không có
													công việc cụ thể.</div>
												<div v-else v-for="(task, idx) in item.CheckList" :key="idx"
													class="d-flex align-center px-2 py-1 border-b">
													<v-checkbox-btn v-model="task.DaThucHien" density="compact"
														color="primary"
														@update:model-value="handleUpdateCheckBoxItem(item)"></v-checkbox-btn>
													<span class="text-body-2 ml-2"
														:class="{ 'text-decoration-line-through text-grey': task.DaThucHien }">{{
														task.TenCongViec }}</span>
												</div>
											</v-card>
											<div :class="{ 'opacity-60': !isCheckListDone(item) }">
												<v-btn-toggle v-model="item.TinhTrangSauBaoTri"
													class="d-flex w-100 rounded mt-2 mb-2 border" divided
													density="compact">
													<v-btn value='BINH_THUONG' class="flex-grow-1"
														:color="item.TinhTrangSauBaoTri == 'BINH_THUONG' ? 'success' : ''"
														variant="flat" height="40" :disabled="!isCheckListDone(item)">
														<v-icon start>mdi-check</v-icon>TỐT
													</v-btn>
													<v-btn value="HONG" class="flex-grow-1"
														:color="item.TinhTrangSauBaoTri == 'HONG' ? 'error' : ''"
														variant="flat" height="40" :disabled="!isCheckListDone(item)">
														<v-icon start>mdi-alert</v-icon>HỎNG
													</v-btn>
												</v-btn-toggle>
											</div>
										</div>
										<v-row dense>
											<v-col cols="12">
												<v-textarea v-model="item.GhiChu"
													:rules="[ruleGhiChu(item.TinhTrangSauBaoTri)]" label="Ghi chú / Lỗi"
													rows="3" variant="outlined" density="compact" />
											</v-col>
											<v-col cols="12">
												<uc-input-price v-model="item.ChiPhiBaoTri" :rules="[rules.required]"
													label="Chi phí"></uc-input-price>
											</v-col>

										</v-row>

										<v-row dense class="mt-2">
											<v-col cols="9">
												<v-btn block color="primary" variant="flat"
													@click="onSubmitItemDetail(item.CaBiet_Id)">
													Lưu
												</v-btn>
											</v-col>
										</v-row>
									</div>
								</v-expand-transition>
							</div>
						</v-form>
					</v-card>
				</div>
			</v-card-text>

			<v-footer v-if="!isLocked" :app="isMobile" color="white"
				class="border-t elevation-4 d-flex flex-column pa-2" style='z-index: 1200;'>

				<div class="d-flex justify-space-between w-100 mb-2 align-center px-1">
					<span class="text-body-2 text-grey-darken-1">Tổng chi phí:</span>
					<span class="text-h6 font-weight-bold text-primary">{{ formatCurrency(TongChiPhi) }}</span>
				</div>
				<div class="d-flex w-100 gap-2">
					<v-btn color="primary" class="flex-grow-1 font-weight-bold"
						:disabled="hasInvalidItem || !selectedItem.Detail.length || !isGiamSat"
						@click="onSubmitDotBaoTri">
						<v-icon start>mdi-check-all</v-icon>
						{{ isMobile ? 'Xác nhận' : 'Giám sát xác nhận' }}
					</v-btn>
				</div>
			</v-footer>
		</v-card>

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
		<!-- Desktop only -->
		<v-dialog v-model="isShowDialogBaoTri" max-width="600">
			<v-card>
				<v-form ref="BaoTriForm">
					<v-toolbar :title="'Cập nhật: ' + (BaoTri ? BaoTri.TenHangHoa : '')" density="compact"
						color="primary">
						<v-btn icon="mdi-close" @click="closeDialogBaoTri"></v-btn>
					</v-toolbar>
					<v-card-text class="pt-4">
						<div class="mb-4 border rounded pa-3">
							<div class="mb-4 border rounded pa-3">
								<div class="text-subtitle-2 text-primary mb-2 font-weight-bold">
									<v-icon start size="small">mdi-checkbox-marked-outline</v-icon> Danh sách công việc
								</div>
								<div v-if="!BaoTri || !BaoTri.CheckList || BaoTri.CheckList.length === 0"
									class="text-grey text-caption text-center">Không có công việc.
								</div>

								<v-btn block variant="tonal" color="primary" size="small" class="mb-3"
									prepend-icon="mdi-check-all"
									:disabled="isCheckListDone(BaoTri) || !BaoTri.CheckList || BaoTri.CheckList.length === 0"
									@click="checkAllCheckListInDialog">
									Xong hết CheckList
								</v-btn>
								<v-list density="compact" class="pa-0">
									<v-list-item v-for="(task, idx) in (BaoTri ? BaoTri.CheckList : [])" :key="idx"
										class="pa-0">
										<template v-slot:prepend>
											<v-checkbox-btn v-model="task.DaThucHien" color="primary"
												@update:model-value="handleUpdateCheckBox">
											</v-checkbox-btn>
										</template>
										<v-list-item-title>
											{{ task.TenCongViec }}
										</v-list-item-title>
									</v-list-item>
								</v-list>
							</div>
						</div>
						<v-row dense>
							<v-col cols="12">
								<v-btn-toggle v-model="BaoTri.TinhTrangSauBaoTri" density="compact" class="d-flex">
									<v-btn value="BINH_THUONG" class="flex-grow-1"
										:color="BaoTri.TinhTrangSauBaoTri === 'BINH_THUONG' ? 'success' : ''"
										prepend-icon="mdi-check-circle" :disabled="!isCheckListDone(BaoTri)">
										Bình thường
									</v-btn>
									<v-btn value="HONG" class="flex-grow-1"
										:color="BaoTri.TinhTrangSauBaoTri === 'HONG' ? 'error' : ''"
										prepend-icon="mdi-alert-circle"
										:disabled="!isCheckListDone(BaoTri)">Hỏng</v-btn>
								</v-btn-toggle>
								<div v-if="!isCheckListDone(BaoTri)" class="text-caption text-orange mt-1 text-center">*
									Vui lòng hoàn thành CheckList công việc.
								</div>
							</v-col>
							<v-col cols="12" class="mt-2">
								<uc-input-price v-model="BaoTri.ChiPhiBaoTri" :rules="[rules.required]"
									label="Chi phí"></uc-input-price>
							</v-col>
							<v-col cols="12">
								<v-textarea v-model="BaoTri.GhiChu" :rules="[ruleGhiChu(BaoTri.TinhTrangSauBaoTri)]"
									label="Ghi chú / Lỗi" rows="3" variant="outlined" density="compact" />
							</v-col>
						</v-row>
					</v-card-text>
					<v-card-actions>
						<v-spacer></v-spacer>
						<v-btn @click="closeDialogBaoTri" variant="text">Đóng</v-btn>
						<v-btn color="primary" variant="elevated" @click="onSubmitBaoTriDetail">
							Lưu cập nhật
						</v-btn>
					</v-card-actions>
				</v-form>
			</v-card>
		</v-dialog>

		<!-- Quét QR -->
		<v-dialog v-model="isShowQrDialog" :fullscreen="isMobile" width="500" transition="dialog-bottom-transition">
			<v-card class="bg-black">
				<v-toolbar color="transparent" theme="dark">
					<v-toolbar-title>Quét mã tài sản</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-btn icon="mdi-close" @click="closeQrDialog"></v-btn>
				</v-toolbar>
				<v-card-text class="pa-0 d-flex flex-column align-center justify-center" style="height: 100%">
					<uc-qr v-model="thongTinMaVach" @scan-success="editByQR" ref="qrScanner" :cooldown-ms="1000"
						:continuous="true" style="width: 100%; aspect-ratio: 1/1;">
					</uc-qr>
					<div class="mt-4 text-white text-center px-4">Di chuyển camera đến mã QR trên tài sản</div>
					<v-btn class="mt-4" variant="outlined" color="white" prepend-icon="mdi-image"
						@click="$refs.qrScanner?.triggerFileInput()">Chọn ảnh từ thư viện</v-btn>
				</v-card-text>
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
			DiaDiem_Id: Number
		},
		data() {
			return {
				rules: {
					required: (value) => !!value || 'Trường này không được để trống',
				},
	
				isShowDialogNhanSu: false,
				isShowDialogBaoTri: false,
				isShowQrDialog: false,
	
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
				BaoTri: {
					CheckList: [],
					ChiPhiBaoTri: null,
					GhiChu: null,
				},
	
				currentUser: vueData.user.UserID,
				formRefs: [],
	
				CaBiet_Id_Highlight: null,
				thongTinMaVach: null,
			};
		},
		computed: {
			isMobile() {
				return this.$vuetify.display.smAndDown;
			},
	
			hasInvalidItem() {
				return this.selectedItem.Detail?.some(
					({ TinhTrang, TinhTrangSauBaoTri }) =>
						TinhTrang === false || TinhTrangSauBaoTri == null
				);
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
			isLocked() {
				const { LoaiHinhThucHien, NguoiThucHien, NguoiGiamSat, DoiTacThucHien } = this.selectedItem;
	
				const isEmpty = v =>
					v == null ||
					(Array.isArray(v) && v.length === 0) ||
					v === '';
	
				if (LoaiHinhThucHien === null) return true
	
				if (LoaiHinhThucHien === 'NOI_BO') {
					return isEmpty(NguoiThucHien) || isEmpty(NguoiGiamSat);
				}
	
				if (LoaiHinhThucHien === 'THUE_NGOAI') {
					return isEmpty(DoiTacThucHien) || isEmpty(NguoiGiamSat);
				}
	
				return true;
			},
			isGiamSat() {
				return this.selectedItem.NguoiGiamSat?.includes(this.currentUser) ?? false;
			},
			isTaoMoi() {
				return this.selectedItem.TinhTrang === 'TAO_MOI'
			}
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
	
			closeQrDialog() {
				this.isShowQrDialog = false
			},
	
			onOpenDiaglogQr() {
				this.isShowQrDialog = true
			},
	
			ruleGhiChu(tinhTrang) {
				return v =>
					tinhTrang !== 'HONG' ||
					(v && v.trim().length > 0) ||
					'Vui lòng nhập ghi chú khi chọn Hỏng'
			},
	
			formatCurrency(val) {
				return val ? new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val) : '0 ₫';
			},
	
			calculateProgress(item) {
				if (!item.CheckList || item.CheckList.length === 0) return 0;
				var doneCount = item.CheckList.filter(function (t) { return t.DaThucHien; }).length;
				return (doneCount / item.CheckList.length) * 100;
			},
	
			openDialogNhanSu() {
				this.isShowDialogNhanSu = true
			},
	
			async onOpenEditDetail(item) {
				this.BaoTri = {
					...item,
					CheckList: item.CheckList?.length
						? item.CheckList.map(i => ({ ...i }))
						: this.selectedItem.TaskList.map(i => ({ ...i })),
				}
				this.isShowDialogBaoTri = true;
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
	
			checkAllCheckListInDialog() {
				if (!this.BaoTri || !this.BaoTri.CheckList || this.BaoTri.CheckList.length === 0) return;
	
				this.BaoTri.CheckList.forEach((task) => task.DaThucHien = true);
	
				if (this.isCheckListDone(this.BaoTri)) {
					this.BaoTri.TinhTrangSauBaoTri = 'BINH_THUONG';
				}
			},
	
			async checkAllCheckList(item) {
				if (!item.CheckList || item.CheckList.length === 0) return;
				item.CheckList.forEach(function (task) {
					task.DaThucHien = true;
				});
				if (this.isCheckListDone(item)) {
					item.TinhTrangSauBaoTri = 'BINH_THUONG';
				}
			},
	
			handleUpdateCheckBox() {
				this.BaoTri.TinhTrangSauBaoTri = this.isCheckListDone(this.BaoTri) ? "BINH_THUONG" : null
			},
	
			handleUpdateCheckBoxItem(item) {
				item.TinhTrangSauBaoTri = this.isCheckListDone(item) ? "BINH_THUONG" : null
			},
	
			async onSubmitBaoTriDetail() {
				const { valid } = await this.$refs.BaoTriForm.validate()
				if (!valid) return showToast.info('Thông tin chưa hợp lệ')
				const params = {
					DotBaoTri_ChiTiet_Id: this.BaoTri.DotBaoTri_ChiTiet_Id,
					ChiPhiBaoTri: this.BaoTri.ChiPhiBaoTri,
					TinhTrangSauBaoTri: this.isCheckListDone(this.BaoTri) === true ? this.BaoTri.TinhTrangSauBaoTri : null,
					GhiChu: this.BaoTri.GhiChu,
					JSONCheckList: JSON.stringify(this.BaoTri.CheckList),
					TinhTrang: this.isCheckListDone(this.BaoTri)
				}
				const $this = this
	
				if (this.isTaoMoi)
					apiCall('work/TS_DotBaoTri_Update_DangThucHien', {
						DotBaoTri_Id: this.selectedItem.DotBaoTri_Id,
						TinhTrang: 'DANG_XU_LY'
					}, () => {
						$this.selectedItem.TinhTrang = 'DANG_XU_LY'
					})
	
				apiCall('/work/TS_DotBaoTri_Update_ChiTiet_By_Id', params, () => {
					showToast.success('Thành công')
					$this.$emit('load-data-detail')
					$this.closeDialogBaoTri()
				})
			},
	
			toggleExpand(item) {
				// // Nếu đang bấm vào đúng cái đang highlight -> Bấm để đóng -> Tắt highlight luôn
				// if (this.CaBiet_Id_Highlight === item.MaCaBiet && item.isExpanded) {
				//     this.CaBiet_Id_Highlight = null;
				// }
				// // Nếu bấm vào cái khác -> Tắt highlight của cái cũ (nếu có)
				// else if (this.CaBiet_Id_Highlight !== item.MaCaBiet) {
				//     this.CaBiet_Id_Highlight = null;
				// }
				if (item.CheckList.length === 0)
					item.CheckList = this.selectedItem.TaskList.map(i => ({ ...i }))
				item.isExpanded = !item.isExpanded;
			},
	
			async onSubmitItemDetail(CaBiet_Id) {
				const form = this.formRefs[CaBiet_Id];
				if (!form) return;
				const { valid } = await form.validate();
				if (!valid) return showToast.info('Thông tin chưa hợp lệ, vui lòng kiểm tra lại')
				const item = this.filteredMobileList.find(i => i.CaBiet_Id === CaBiet_Id);
	
				const params = {
					DotBaoTri_ChiTiet_Id: item.DotBaoTri_ChiTiet_Id,
					ChiPhiBaoTri: item.ChiPhiBaoTri,
					TinhTrangSauBaoTri: this.isCheckListDone(item) === true ? item.TinhTrangSauBaoTri : null,
					GhiChu: item.GhiChu,
					JSONCheckList: JSON.stringify(item.CheckList),
					TinhTrang: this.isCheckListDone(item)
				}
				const $this = this
	
				if (this.isTaoMoi)
					apiCall('work/TS_DotBaoTri_Update_DangThucHien', {
						DotBaoTri_Id: this.selectedItem.DotBaoTri_Id,
						TinhTrang: 'DANG_XU_LY'
					}, () => {
						$this.selectedItem.TinhTrang = 'DANG_XU_LY'
					})
				apiCall('/work/TS_DotBaoTri_Update_ChiTiet_By_Id', params, () => {
					showToast.success('Thành công')
					$this.$emit('load-data-detail')
				})
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
	
			async onSubmitDotBaoTri() {
				showConfirm("Xác nhận hoàn thành đợt bảo trì", () => {
					const params = {
						DotBaoTri_Id: this.selectedItem.DotBaoTri_Id
					}
					const $this = this
					apiCall(
						'/work/TS_DotBaoTri_Update_HoanThanh', params, () => {
							showToast.success('Thành công')
							$this.closeDialog()
							$this.$emit('load-data')
						},
					)
				})
			},
	
			async editByQR() {
				this.isShowQrDialog = false;
	
				const data = JSON.parse(this.thongTinMaVach)
	
				apiCall(
					"work/TS_CaBiet_Select_By_Qr",
					{ MaVach: data.maVach, DiaDiem_Id: Number(data.diaDiem) },
					(res) => {
						const asset = res.data?.[0]
	
						if (!asset) {
							showToast.error('Mã QR này chưa được gán vào tài sản!')
							return
						}
	
						if (asset && asset.DiaDiem_Id !== this.DiaDiem_Id) {
							showToast.error('Tài sản không ở địa điểm này!')
							return
						}
	
						// Tìm tài sản
						const foundItem = this.selectedItem.Detail.find(x => x.MaVach === asset.MaVach);
						if (foundItem) {
							// Xử lý filter nếu đang bị ẩn (như code trước)
							const isVisible = this.filteredMobileList.find(x => x.CaBiet_Id === foundItem.CaBiet_Id);
							if (!isVisible) {
								this.search = '';
							}
							// --- LOGIC MỚI: Highlight và Expand ---
							// 1. Gán ID để bật hiệu ứng viền (sẽ không tự mất)
							this.CaBiet_Id_Highlight = foundItem.CaBiet_Id;
							// 2. Mở rộng thẻ
							foundItem.isExpanded = true;
							// 3. Scroll tới
							this.$nextTick(() => {
								const formComponent = this.formRefs[foundItem.CaBiet_Id];
								if (formComponent && formComponent.$el) {
									formComponent.$el.scrollIntoView({ behavior: 'smooth', block: 'center' });
								}
							});
						} else {
							showToast.error("Không tìm thấy tài sản!")
						}
					},
					(error) => {
						showToast.error(error.responseJSON?.Message || "Lỗi hệ thống")
					}
				)
			},
		}
	}
</script>