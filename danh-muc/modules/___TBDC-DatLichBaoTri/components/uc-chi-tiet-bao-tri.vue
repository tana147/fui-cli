<template>
	<v-dialog v-model="dialog" :fullscreen="isMobile" :max-width="isMobile ? '100%' : 1300"
		:transition="isMobile ? 'dialog-bottom-transition' : 'dialog-transition'">

		<v-card class="d-flex flex-column h-100">
			<v-toolbar density="compact" color="primary">

				<v-toolbar-title class="font-weight-bold text-subtitle-1 text-truncate">
					{{ event ? event.start.toLocaleDateString('en-GB') + ' | ' + event.title : '' }}
				</v-toolbar-title>

				<v-spacer></v-spacer>

				<v-btn variant="text" class="mr-1" @click="deleteMaintenanceEvent">
					<v-icon :start="!isMobile">mdi-delete-forever</v-icon>
					<span class="d-none d-sm-inline">Xóa đợt bảo trì</span>
				</v-btn>
				<v-btn variant="text" prepend-icon="mdi-account-group" @click="openStaffDialog">
					<span class="d-none d-sm-inline">Nhân sự phụ trách</span>
				</v-btn>
				<v-btn icon="mdi-close" @click="dialog = false" />
			</v-toolbar>

			<!-- Điện thoại -->
			<div v-if="isMobile" class="bg-white border-b elevation-1" style="z-index: 1;">
				<v-container class="pa-2">
					<div class="d-flex align-center mb-2">
						<v-text-field v-model="search" density="compact" variant="outlined" placeholder="Tìm tên..."
							hide-details prepend-inner-icon="mdi-magnify" bg-color="grey-lighten-5"
							class="rounded-lg flex-grow-1" />

						<v-btn class="ml-2" color="primary" variant="tonal" icon="mdi-qrcode-scan" rounded="lg"
							size="large" @click="showQrDialog = true"></v-btn>
					</div>
					<v-row dense align="center">
						<v-col cols="7">
							<v-autocomplete v-model="viTriFilter" :items="viTriList" item-title="TenViTriPhong"
								item-value="MaViTriPhong" label="Vị trí" density="compact" variant="outlined"
								hide-details bg-color="white" return-object
								@update:model-value="getDanhSachTaiSanBaoTri"
								prepend-inner-icon="mdi-map-marker-outline" />
						</v-col>
						<v-col cols="5">
							<v-checkbox v-model="locChuaXacNhan" density="compact" color="red" hide-details class="ml-1"
								@change="getDanhSachTaiSanBaoTri">
								<template v-slot:label>
									<span style="font-size: 11px">Chưa làm: {{ countChuaXacNhan }}/{{ countTong }}</span>
								</template>
							</v-checkbox>
						</v-col>
					</v-row>
				</v-container>
			</div>

			<!-- Desktop -->
			<v-toolbar v-if="!isMobile" density="compact" flat color="grey-lighten-4" class="border-b">
				<v-row align="center" class="px-2 w-100">
					<v-col cols="auto" class="mr-3">
						<v-combobox class="mt-1" v-model="viTriFilter" :items="viTriList" item-title="TenViTriPhong"
							item-value="MaViTriPhong" label="Lọc vị trí" density="compact" variant="outlined"
							hide-details bg-color="white" style="width: 250px" return-object
							@update:model-value="getDanhSachTaiSanBaoTri" />
					</v-col>
					<v-col cols="auto">
						<v-checkbox v-model="locChuaXacNhan" density="compact" hide-details color="red"
							@change="getDanhSachTaiSanBaoTri"
							:label="'Chưa bảo trì: ' + countChuaXacNhan + '/' + countTong" />
					</v-col>
					<v-spacer></v-spacer>
					<v-col cols="3">
						<v-text-field class="mt-1" v-model="search" density="compact" variant="outlined"
							label="Tìm kiếm" hide-details bg-color="white" prepend-inner-icon="mdi-magnify" />
					</v-col>
				</v-row>

			</v-toolbar>

			<v-card-text class="pa-0 flex-grow-1 bg-grey-lighten-4" style="overflow-y: auto;">
				<!-- Desktop -->
				<v-data-table-virtual v-if="!isMobile" :headers="headers" :items="dsTaiSan" :search="search"
					height="100%" fixed-header :loading="loading" item-value="MaCaBiet">
					<template #item.TenTaiSan="{ item }">
						<!-- <uc-asset-info :tentaisan="item.TenTaiSan" :macabiet="item.MaCaBiet"
							classforname="font-weight-medium" /> -->
					</template>

					<template #item.TienDo="{ item }">
						<div class="d-flex align-center cursor-pointer" @click="openUpdateAsset(item)">
							<v-progress-linear :model-value="calculateProgress(item)" color="primary" height="15"
								rounded>
								<template v-slot:default="{ value }">
									<strong style="font-size: 10px; color: white">{{ Math.ceil(value) }}%</strong>
								</template>
							</v-progress-linear>
						</div>
					</template>

					<template #item.TinhTrangSauBaoTri="{ item }">
						<div v-if="!isChecklistDone(item)" class="text-caption text-orange d-flex align-center">
							<v-icon size="small" start color="orange">mdi-alert-circle-outline</v-icon>
							<span>Chưa xong việc</span>
						</div>
						<v-chip :color="item.TinhTrangSauBaoTri === 1 ? 'success' : 'error'" size="small" variant="flat"
							v-if="item.TinhTrangSauBaoTri >= 0">{{ item.TinhTrangSauBaoTri === 1 ? 'Tốt' :
								'Hỏng' }}</v-chip>
					</template>

					<template #item.TrangThai="{ item }">
						<v-chip :color="item.TrangThai === 1 ? 'success' : 'warning'" size="small" label variant="flat">
							{{ item.TrangThai === 1 ? 'Đã lưu' : 'Chưa lưu' }}
						</v-chip>
					</template>
					<template #item.ChiPhiBaoTri="{ item }"> {{ item.ChiPhiBaoTri ? formatCurrency(item.ChiPhiBaoTri) :
						'' }} </template>
					<template #item.NguoiThucHien="{ item }"> <v-chip v-if="item.NguoiThucHien"
							size="small">{{ item.NguoiThucHien }}</v-chip> </template>
					<template #item.edit="{ item }">
						<div class="d-flex justify-center">
							<v-btn size="small" icon="mdi-pencil-box-outline" variant="text" color="blue"
								@click="openUpdateAsset(item)" class="mr-1" />

							<v-btn size="small" icon="mdi-delete-outline" variant="text" color="red"
								@click="deleteAsset(item)" />
						</div>
					</template>
				</v-data-table-virtual>

				<!-- Mobile -->
				<div v-else class="pa-2 pb-16">
					<div v-if="filteredMobileList.length === 0" class="text-center mt-10 text-grey">Không có dữ liệu
					</div>

					<v-card v-for="(item, i) in filteredMobileList" :key="item.MaCaBiet"
						class="mb-3 rounded-lg elevation-2" :class="{
							'border-success': item.TinhTrangSauBaoTri === 1,
							'border-error': item.TinhTrangSauBaoTri === 2,
							'scanned-highlight': item.MaCaBiet === highlightedItemId
						}" style="border-left: 4px solid transparent;">
						<v-form :ref="el => { formRefs[item.MaCaBiet] = el }">

							<div class="pa-3">
								<div class="d-flex justify-space-between mb-2" @click="toggleExpand(item)">
									<div style="max-width: 75%">
										<div class="text-subtitle-2 font-weight-bold text-primary text-truncate">{{
											item.TenTaiSan }}</div>
										<div class="text-caption text-grey-darken-2 mt-1">
											Mã: {{ item.MaVach }}
										</div>
										<div class="text-caption text-grey-darken-1 d-flex align-center mt-1">
											<v-icon size="x-small" start class="mr-1">mdi-map-marker</v-icon>
											{{ item.TenViTriPhong || 'Không rõ' }}
										</div>
										<v-chip size="x-small" v-if="item.NguoiThucHien" class="mt-1">
											<v-icon size="x-small" start>mdi-account</v-icon> {{ item.NguoiThucHien }}
										</v-chip>

									</div>
									<div class="text-center cursor-pointer">

										<v-progress-circular :model-value="calculateProgress(item)" size="36" width="3"
											:color="calculateProgress(item) === 100 ? 'green' : 'grey-darken-1'"
											class="mb-1">
											<span style="font-size: 10px; font-weight: bold">{{ checklistCount(item)
											}}</span>
										</v-progress-circular>
										<div class="mt-n1">
											<v-icon :icon="item.isExpanded ? 'mdi-chevron-up' : 'mdi-chevron-down'"
												size="small" color="grey"></v-icon>
										</div>
									</div>
								</div>



								<div v-if="!isChecklistDone(item)" class="text-caption text-center text-orange mb-2">
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
												:disabled="isChecklistDone(item) || !item.Checklist || item.Checklist.length === 0"
												@click.stop="() => { checkAllChecklist(item); item.TinhTrangSauBaoTri = 1 }">
												Xong hết
											</v-btn>
											<v-card variant="outlined" class="bg-white">
												<div v-if="!item.Checklist || item.Checklist.length === 0"
													class="pa-2 text-caption text-grey font-italic text-center">Không có
													công việc cụ thể.</div>
												<div v-else v-for="(task, idx) in item.Checklist" :key="idx"
													class="d-flex align-center px-2 py-1 border-b">
													<v-checkbox-btn v-model="task.DaThucHien" density="compact"
														color="primary"
														@change="() => { checklistCount(item); item.TinhTrangSauBaoTri = isChecklistDone(item) ? 1 : null }"></v-checkbox-btn>
													<span class="text-body-2 ml-2"
														:class="{ 'text-decoration-line-through text-grey': task.DaThucHien }">{{
															task.TenCongViec }}</span>
												</div>
											</v-card>
											<div :class="{ 'opacity-60': !isChecklistDone(item) }">
												<v-btn-toggle v-model="item.TinhTrangSauBaoTri"
													class="d-flex w-100 rounded mt-2 mb-2 border" divided
													density="compact">
													<v-btn :value="1" class="flex-grow-1"
														:color="item.TinhTrangSauBaoTri == 1 ? 'success' : ''"
														variant="flat" height="40" :disabled="!isChecklistDone(item)">
														<v-icon start>mdi-check</v-icon>TỐT
													</v-btn>
													<v-btn :value="2" class="flex-grow-1"
														:color="item.TinhTrangSauBaoTri == 2 ? 'error' : ''"
														variant="flat" height="40" :disabled="!isChecklistDone(item)">
														<v-icon start>mdi-alert</v-icon>HỎNG
													</v-btn>
												</v-btn-toggle>
											</div>
										</div>
										<v-row dense>
											<v-col cols="12">
												<v-textarea v-model="item.GhiChuBaoTri"
													:rules="[v => item.TinhTrangSauBaoTri === 1 || (item.TinhTrangSauBaoTri === 2 && v && v.trim().length > 0) || 'Vui lòng nhập ghi chú khi chọn Hỏng']"
													label="Ghi chú / Lỗi" rows="2" density="compact" variant="outlined"
													bg-color="white" hide-details placeholder="Nhập ghi chú..." />
											</v-col>
											<v-col cols="12" v-if="item.TinhTrangSauBaoTri === 2">
												<v-text-field v-model="item.displayCostMobile" label="Chi phí phát sinh"
													prefix="₫" density="compact" variant="outlined" bg-color="white"
													type="tel" hide-details placeholder="0"
													@input="onMobileCostInput(item, $event)" />
											</v-col>

										</v-row>

										<v-row dense class="mt-2">
											<v-col cols="3">
												<v-btn block color="red-lighten-5" variant="flat" class="text-error"
													@click="deleteAsset(item)">
													<v-icon>mdi-delete-outline</v-icon>
												</v-btn>
											</v-col>

											<v-col cols="9">
												<v-btn block color="primary" variant="flat" :loading="cmdLoading"
													@click="validateForm(item.MaCaBiet)">
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

			<v-footer :app="isMobile" color="white" class="border-t elevation-4 d-flex flex-column pa-2">
				<div class="d-flex justify-space-between w-100 mb-2 align-center px-1">
					<span class="text-body-2 text-grey-darken-1">Tổng chi phí:</span>
					<span class="text-h6 font-weight-bold text-primary">{{ formatCurrency(chiPhiTong) }}</span>
				</div>
				<div class="d-flex w-100 gap-2">
					<v-btn v-if="!isMobile" prepend-icon="mdi-printer" variant="outlined" class="flex-grow-0">In
						phiếu</v-btn>
					<v-btn color="primary" class="flex-grow-1 font-weight-bold" :disabled="!hasUnconfirmed"
						@click="confirmBatch">
						<v-icon start>mdi-check-all</v-icon>
						{{ isMobile ? 'Giám sát xác nhận' : 'Giám sát xác nhận' }}
					</v-btn>

				</div>
			</v-footer>
		</v-card>

		<!-- Phân công -->
		<v-dialog v-model="dialogStaff" max-width="600">
			<v-card>
				<v-toolbar title="Phân công nhân sự" density="compact" color="primary">
					<v-btn icon="mdi-close" @click="dialogStaff = false"></v-btn>
				</v-toolbar>
				<v-card-text class="pt-4">
					<v-row dense>
						<v-col cols="12">
							<div class="font-weight-bold text-caption mb-2 text-uppercase text-grey-darken-2">
								<v-icon start size="small">mdi-account-hard-hat</v-icon> Đơn vị thực hiện
							</div>

							<v-radio-group v-model="donViThucHien" inline density="compact" hide-details class="mb-2">
								<v-radio label="Đối tác" :value=2 color="primary"></v-radio>
								<v-radio label="Nội bộ" :value=1 color="primary"></v-radio>
							</v-radio-group>

							<div v-if="donViThucHien == 1">
								<v-autocomplete class="my-3" v-model="staffConfig.thucHien" :items="dsNhanVien"
									item-title="HoTen" item-value="MaNV" label="Chọn nhân viên thực hiện" multiple chips
									closable-chips density="compact" variant="outlined" hint="Có thể chọn nhiều người"
									persistent-hint>
									<template v-slot:chip="{ props, item }">
										<v-chip v-bind="props" :text="item.raw.HoTen" label size="small"></v-chip>
									</template>
								</v-autocomplete>
							</div>

							<div v-else>
								<v-autocomplete class="my-3"  :items="dsNhaCungCap"
									item-title="TenNCC" item-value="MaNCC" label="Chọn đơn vị đối tác" density="compact"
									variant="outlined" hide-details prepend-inner-icon="mdi-domain" />
							</div>
						</v-col>
						<v-col cols="12">
							<v-autocomplete class="my-3" v-model="staffConfig.giamSat" :items="dsNhanVien"
								item-title="HoTen" item-value="MaNV" label="Người giám sát" multiple chips
								closable-chips variant="outlined" prepend-inner-icon="mdi-account-eye">
								<template v-slot:chip="{ props, item }">
									<v-chip v-bind="props" :text="item.raw.HoTen" label size="small"></v-chip>
								</template>
							</v-autocomplete>
						</v-col>
					</v-row>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn color="grey" variant="text" @click="dialogStaff = false">Hủy</v-btn>
					<v-btn color="primary" variant="elevated" @click="saveStaffConfig">Lưu phân công</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<v-dialog v-model="dialogUpdate" max-width="600">
			<v-card>
				<v-form ref="updateFormEdit">
					<v-toolbar :title="'Cập nhật: ' + (editItem ? editItem.TenTaiSan : '')" density="compact"
						color="primary">
						<v-btn icon="mdi-close" @click="dialogUpdate = false"></v-btn>
					</v-toolbar>
					<v-card-text class="pt-4">
						<div class="mb-4 border rounded pa-3">
							<div class="mb-4 border rounded pa-3">
								<div class="text-subtitle-2 text-primary mb-2 font-weight-bold">
									<v-icon start size="small">mdi-checkbox-marked-outline</v-icon> Danh sách công việc
								</div>
								<div v-if="!editItem || !editItem.Checklist || editItem.Checklist.length === 0"
									class="text-grey text-caption text-center">Không có công việc.
								</div>

								<v-btn block variant="tonal" color="primary" size="small" class="mb-3"
									prepend-icon="mdi-check-all"
									:disabled="isChecklistDone(editItem) || !editItem.Checklist || editItem.Checklist.length === 0"
									@click="checkAllChecklistInDialog">
									Xong hết Checklist
								</v-btn>
								<v-list density="compact" class="pa-0">
									<v-list-item v-for="(task, idx) in (editItem ? editItem.Checklist : [])" :key="idx"
										class="pa-0">
										<template v-slot:prepend>
											<v-checkbox-btn v-model="task.DaThucHien" color="primary"
												@change="() => { updateChecklistInDialog(task); editItem.TinhTrangSauBaoTri = isChecklistDone(editItem) ? 1 : null }">
											</v-checkbox-btn>
										</template>
										<v-list-item-title>{{ task.TenCongViec
										}}</v-list-item-title>
									</v-list-item>
								</v-list>
							</div>
						</div>
						<v-row dense>
							<v-col cols="12">
								<v-btn-toggle v-model="editItem.TinhTrangSauBaoTri" density="compact" class="d-flex">
									<v-btn :value="1" class="flex-grow-1"
										:color="editItem.TinhTrangSauBaoTri === 1 ? 'success' : ''"
										prepend-icon="mdi-check-circle" :disabled="!isChecklistDone(editItem)">Bình
										thường</v-btn>
									<v-btn :value="2" class="flex-grow-1"
										:color="editItem.TinhTrangSauBaoTri === 2 ? 'error' : ''"
										prepend-icon="mdi-alert-circle"
										:disabled="!isChecklistDone(editItem)">Hỏng</v-btn>
								</v-btn-toggle>
								<div v-if="!isChecklistDone(editItem)"
									class="text-caption text-orange mt-1 text-center">*
									Vui lòng hoàn thành checklist công việc.</div>
							</v-col>
							<v-col cols="12" class="mt-2">
								<v-text-field v-model="editDisplayCost" label="Chi phí" @keypress="onlyNumberInput"
									variant="outlined" suffix="VND" density="compact" />
							</v-col>
							<v-col cols="12">
								<v-textarea v-model="editNote"
									:rules="[v => editItem.TinhTrangSauBaoTri === 1 || (editItem.TinhTrangSauBaoTri === 2 && v && v.trim().length > 0) || 'Vui lòng nhập ghi chú khi chọn Hỏng']"
									label="Ghi chú" rows="3" variant="outlined" density="compact" />
							</v-col>
						</v-row>
					</v-card-text>
					<v-card-actions>
						<v-spacer></v-spacer>
						<v-btn @click="dialogUpdate = false" variant="text">Đóng</v-btn>
						<v-btn color="primary" variant="elevated"
							@click="validate('updateFormEdit', submitUpdateAsset)">Lưu cập
							nhật</v-btn>
					</v-card-actions>
				</v-form>
			</v-card>
		</v-dialog>

		<v-dialog v-model="deleteDialog" max-width="550">
			<v-card>
				<v-toolbar color="red-lighten-5" density="compact">
					<v-toolbar-title class="text-red font-weight-bold">
						<v-icon start>mdi-alert-outline</v-icon> Xác nhận xóa
					</v-toolbar-title>
					<v-btn icon="mdi-close" @click="deleteDialog = false" variant="text" density="compact"></v-btn>
				</v-toolbar>

				<v-card-text class="pt-4">
					<div class="mb-2">
						Bạn đang thực hiện xóa tài sản:
						<strong class="text-primary">{{ itemToDelete?.TenTaiSan }} ({{ itemToDelete?.MaVach }})</strong>
					</div>
					<div class="text-caption text-grey-darken-1 mb-4">
						Vui lòng chọn phạm vi xóa dữ liệu:
					</div>

					<v-radio-group v-model="deleteType" color="red" hide-details>
						<v-radio :value="1">
							<template v-slot:label>
								<div>
									<div class="font-weight-bold text-black">Chỉ xóa trong đợt này</div>
									<div class="text-caption">Giữ lại tài sản này ở các đợt bảo trì định kỳ sau (nếu
										có).</div>
								</div>
							</template>
						</v-radio>

						<v-divider class="my-2 border-dashed"></v-divider>

						<v-radio :value="2">
							<template v-slot:label>
								<div>
									<div class="font-weight-bold text-black">Xóa đợt này & các đợt sau</div>
									<div class="text-caption">Xóa khỏi đợt hiện tại và hủy lịch định kỳ tương lai chưa
										thực
										hiện.</div>
								</div>
							</template>
						</v-radio>
					</v-radio-group>
				</v-card-text>
				<v-divider></v-divider>
				<v-card-actions class="pa-3">
					<v-spacer></v-spacer>
					<v-btn variant="text" @click="deleteDialog = false">Hủy bỏ</v-btn>
					<v-btn color="red" variant="elevated" :loading="loading" @click="submitDeleteAsset">
						Thực hiện xóa
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- Quét QR -->
		<v-dialog :fullscreen="$vuetify.display.xs" v-model="showQrDialog" width="500"
			transition="dialog-bottom-transition">
			<v-card class="bg-black">
				<v-toolbar color="transparent" theme="dark">
					<v-toolbar-title>Quét mã tài sản</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-btn icon="mdi-close" @click="showQrDialog = false"></v-btn>
				</v-toolbar>
				<v-card-text class="pa-0 d-flex flex-column align-center justify-center" style="height: 100%">
					<uc-qr v-model="maCaBietQuet" @scan-success="editByQR" ref="qrScanner" :cooldown-ms="1000"
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
	data() {
		return {
			showQrDialog: false,
			highlightedItemId: null,
			currentUser: vueData.user.UserID,
			maCaBietQuet: null,
			dialog: false, dialogUpdate: false, dialogStaff: false, loading: false,
			event: null, dsTaiSan: [], viTriList: [], dsNhanVien: [], search: '',
			viTriFilter: { TenViTriPhong: "Tất cả", MaViTriPhong: 0 }, locChuaXacNhan: false,
			countTong: 0, countChuaXacNhan: 0, chiPhiTong: 0,
			editItem: { Checklist: [] }, editCost: 0, editNote: '', editDisplayCost: '',
			donViThucHien: null, // đối tác, nội bộ
			formRefs: [],
			staffConfig: { thucHien: [], giamSat: [] },
			dsNhaCungCap: [],
			deleteDialog: false,
			deleteType: 1,
			itemToDelete: null,
			doiTacThucHien: null,
			logo: null,
			cmdLoading: false,
			footer: null,
			isGiamSat: false,
			headers: [
				{ title: 'STT', key: 'STT' },
				{ title: 'Tên tài sản', key: 'TenTaiSan', width: '180px' },
				{ title: 'Mã', key: 'MaVach' },
				{ title: 'Vị trí', key: 'TenViTriPhong' },
				{ title: 'Tiến độ', key: 'TienDo', align: 'center', width: '120px' },
				// { title: 'Trạng thái', key: 'TrangThai', align: 'center' },
				{ title: 'Đánh giá', key: 'TinhTrangSauBaoTri' },

				{ title: 'Chi phí', key: 'ChiPhiBaoTri', align: 'end' },
				{ title: 'Ghi chú', key: 'GhiChuBaoTri' },
				{ title: 'Người bảo trì', key: 'NguoiThucHien' },

				{ title: 'Sửa', key: 'edit', align: 'center' },

			]
		};
	},
	computed: {
		isMobile() { return this.$vuetify.display.smAndDown; },
		hasUnconfirmed() { return this.dsTaiSan.some(function (i) { return i.TrangThai !== 1; }); },
		filteredMobileList() {
			if (!this.search) return this.dsTaiSan;
			var s = this.search.toLowerCase();
			return this.dsTaiSan.filter(function (i) {
				return i.TenTaiSan.toLowerCase().includes(s) || (i.TenViTriPhong && i.TenViTriPhong.toLowerCase().includes(s));
			});
		},
		isGiamSatxx() {
			return this.staffConfig.giamSat.some(x => x.MaNhanVien === this.currentUser)
		}
	},
	watch: {
		editDisplayCost(val) {
			this.editCost = val ? Number(String(val).replace(/[^0-9]/g, '')) : 0;
		}
	},
	async mounted() {
		await this.getStaffAssignment()
	},
	methods: {
		async open(event) {
			this.dialog = true; this.event = event;
			this.donViThucHien = this.event.TinhTrangTrachNhiem;

			this.viTriFilter = { TenViTriPhong: "Tất cả", MaViTriPhong: 0 };

			// Load dữ liệu song song
			await Promise.all([this.getThongKe(), this.getDanhSachTaiSanBaoTri()]);
		},

		// --- NHÂN SỰ (Thêm mới) ---
		async openStaffDialog() {
			this.dialogStaff = true;
			// await this.getNhaCungCap();
			// await this.getNhanVien();
			// await this.getStaffAssignment();
		},
		async getNhanVien() {
			try {
				const res = await axios.post("NhanVien_Select_BaoTri");
				this.dsNhanVien = res.data.data || [];
			} catch (e) { }
		},
		async getStaffAssignment() {
			try {
				const res = await axios.post("DotBaoTri_Select_NhanSu", { MaDotBaoTri: this.event.MaDotBaoTri });
				const data = res.data.data || [];
				// LoaiTrachNhiem: 1 (Thực hiện), 2 (Giám sát)
				this.staffConfig.thucHien = data.filter(function (x) { return x.LoaiTrachNhiem === 1; }).map(function (x) { return x.MaNhanVien; });
				this.staffConfig.giamSat = data.filter(function (x) { return x.LoaiTrachNhiem === 2; }).map(function (x) { return x.MaNhanVien; });
				this.isGiamSat = this.staffConfig.giamSat.some(x => x.MaNhanVien === this.currentUser)
			} catch (e) {
				this.staffConfig.thucHien = []; this.staffConfig.giamSat = [];
			}
		},
		async saveStaffConfig() {
			try {
				// Dùng join(',') để nối chuỗi ID
				await axios.post("DotBaoTri_Update_NhanSu", {
					MaDotBaoTri: this.event.MaDotBaoTri,
					DonViThucHien: this.donViThucHien,
					MaDoiTac: this.event.MaDoiTac || undefined,
					DSThucHien: this.staffConfig.thucHien.join(','),
					DSGiamSat: this.staffConfig.giamSat.join(',')
				});
				this.dialogStaff = false;
			} catch (e) { console.error(e); }
		},

		// --- LOGIC CŨ ---
		isChecklistDone(item) {
			if (!item || !item.Checklist || item.Checklist.length === 0) return true;
			// console.log(item.Checklist.every(function (task) { return task.IsDone === true; }))
			return item.Checklist.every(function (task) { return task.DaThucHien === true; });
		},
		async getThongKe() {
			const res = await axios.post("ChiTietDotBaoTri_SelectTongTinhTrang", { MaDotBaoTri: this.event.MaDotBaoTri });
			if (res.data.data && res.data.data[0] && res.data.data[0][0]) {
				this.countTong = res.data.data[0][0].TongTaiSan;
				this.countChuaXacNhan = res.data.data[0][0].TongTaiSanChuaXacNhan;
			}
			this.viTriList = [{ TenViTriPhong: "Tất cả", MaViTriPhong: 0 }].concat(res.data.data[1] || []);
		},

		async getDanhSachTaiSanBaoTri() {
			this.loading = true;
			try {
				const res = await axios.post("BaoTri_Select_ChiTietDotBaoTri", {
					MaDotBaoTri: this.event.MaDotBaoTri, MaViTriPhong: this.viTriFilter.MaViTriPhong, TrangThai: this.locChuaXacNhan ? 0 : 3
				});
				const raw = res.data.data || [];
				this.dsTaiSan = raw.map(function (item) {
					if (typeof item.Checklist === 'string') { try { item.Checklist = JSON.parse(item.Checklist); } catch (e) { item.Checklist = []; } }
					if (!item.Checklist) item.Checklist = [];
					item.displayCostMobile = item.ChiPhiBaoTri ? Number(item.ChiPhiBaoTri).toLocaleString('vi-VN') : '';
					item.isExpanded = false;
					return item;
				});
				this.chiPhiTong = this.dsTaiSan.reduce(function (sum, item) { return sum + (item.ChiPhiBaoTri || 0); }, 0);


			} finally { this.loading = false; }
		},
		calculateProgress(item) {
			if (!item.Checklist || item.Checklist.length === 0) return 0;
			var doneCount = item.Checklist.filter(function (t) { return t.DaThucHien; }).length;
			return (doneCount / item.Checklist.length) * 100;
		},
		checklistCount(item) {
			if (!item.Checklist) return "0/0";
			var doneCount = item.Checklist.filter(function (t) { return t.DaThucHien; }).length;

			return doneCount + '/' + item.Checklist.length;
		},
		async capNhatTinhTrang(item, val) {
			const old = item.TinhTrangSauBaoTri; item.TinhTrangSauBaoTri = val;
			if (val === 2) this.openUpdateAsset(item);
			else {
				try { await axios.post("ChiTietDotBaoTri_Update_TinhTrangSauBaoTri", { MaDotBaoTri: item.MaDotBaoTri, MaCaBiet: item.MaCaBiet, TinhTrangSauBaoTri: val }); }
				catch { item.TinhTrangSauBaoTri = old; }
			}
		},

		async editByQR(content) {
			this.showQrDialog = false;

			// Tìm tài sản
			const foundItem = this.dsTaiSan.find(x => x.MaVach == content || x.MaCaBiet == content);

			if (foundItem) {
				// Xử lý filter nếu đang bị ẩn (như code trước)
				const isVisible = this.filteredMobileList.find(x => x.MaCaBiet === foundItem.MaCaBiet);
				if (!isVisible) {
					this.search = '';
					this.viTriFilter = { TenViTriPhong: "Tất cả", MaViTriPhong: 0 };
					this.locChuaXacNhan = false;
					await this.getDanhSachTaiSanBaoTri();
				}

				// --- LOGIC MỚI: Highlight và Expand ---

				// 1. Gán ID để bật hiệu ứng viền (sẽ không tự mất)
				this.highlightedItemId = foundItem.MaCaBiet;

				// 2. Mở rộng thẻ
				foundItem.isExpanded = true;

				// 3. Scroll tới
				this.$nextTick(() => {
					const formComponent = this.formRefs[foundItem.MaCaBiet];
					if (formComponent && formComponent.$el) {
						formComponent.$el.scrollIntoView({ behavior: 'smooth', block: 'center' });
					}
				});



			} else {
				showMessage({ type: "error", title: "Không tìm thấy tài sản" });
			}
		},
		toggleExpand(item) {
			// Nếu đang bấm vào đúng cái đang highlight -> Bấm để đóng -> Tắt highlight luôn
			if (this.highlightedItemId === item.MaCaBiet && item.isExpanded) {
				this.highlightedItemId = null;
			}
			// Nếu bấm vào cái khác -> Tắt highlight của cái cũ (nếu có)
			else if (this.highlightedItemId !== item.MaCaBiet) {
				this.highlightedItemId = null;
			}

			// Logic cũ: Đóng/Mở
			item.isExpanded = !item.isExpanded;
		},

		async deleteMaintenanceEvent() {
			// 1. Kiểm tra nếu sự kiện chưa load xong
			if (!this.event || !this.event.MaDotBaoTri) return;

			const confirmed = await this.$refs.confirm.open({
				title: 'XÁC NHẬN XÓA',
				message: `Bạn có muốn xóa đợt bảo trì "${this.event.title} ngày ${this.event.start.toLocaleDateString('en-GB')}" không?`,
				color: 'red',
				icon: 'mdi-alert'
			});

			if (!confirmed) return;

			try {
				this.loading = true;


				await axios.post("DotBaoTri_Delete", {
					MaDotBaoTri: this.event.MaDotBaoTri
				});

				if (typeof showMessage === 'function') {
					showMessage({ type: "success", title: "Đã xóa đợt bảo trì thành công!" });
				}

				this.dialog = false;
				this.$emit('refresh');

			} catch (error) {
				const errorMsg = error.response?.data?.Message || "Lỗi không thể xóa đợt bảo trì.";
				if (typeof showMessage === 'function') {
					showMessage({ type: "error", title: errorMsg });
				} else {
					alert(errorMsg);
				}
			} finally {
				this.loading = false;
			}
		},

		// --- CẬP NHẬT CHO DESKTOP/DIALOG CHỈNH SỬA ---
		checkAllChecklistInDialog() {
			if (!this.editItem || !this.editItem.Checklist || this.editItem.Checklist.length === 0) return;

			this.editItem.Checklist.forEach(function (task) {
				task.DaThucHien = true;
			});

			// Cập nhật giao diện (Bắt buộc phải forceUpdate để v-list-item nhận thay đổi)
			this.$forceUpdate();

			// Tự động set trạng thái là TỐT nếu chưa được đánh giá
			if (this.isChecklistDone(this.editItem) && this.editItem.TinhTrangSauBaoTri === null) {
				this.editItem.TinhTrangSauBaoTri = 1;
			}
		},

		// Hàm xử lý khi check/uncheck từng công việc trong dialog (để cập nhật trạng thái/progress)
		updateChecklistInDialog() {
			// Tự động set trạng thái là TỐT nếu checklist đã xong (và chưa có trạng thái nào)
			if (this.isChecklistDone(this.editItem) && this.editItem.TinhTrangSauBaoTri === null) {
				this.editItem.TinhTrangSauBaoTri = 1;
			} else if (!this.isChecklistDone(this.editItem)) {
				// Nếu chưa xong, xóa trạng thái đã đánh giá (nếu có)
				this.editItem.TinhTrangSauBaoTri = null;
			}
			this.$forceUpdate(); // Bắt buộc phải forceUpdate để v-list-item nhận thay đổi
		},


		async submitDeleteAsset() {
			if (!this.itemToDelete) return;

			try {
				this.loading = true; // Bật loading chung hoặc tạo loading riêng

				// Gọi API với tham số LoaiXoa vừa chọn
				await axios.post("ChiTietDotBaoTri_Delete", {
					MaChiTietDotBaoTri: this.itemToDelete.MaChiTietDotBaoTri,
					MaCaBiet: this.itemToDelete.MaCaBiet,
					LoaiXoa: this.deleteType
				});

				// Thông báo thành công
				if (typeof showMessage === 'function') {
					showMessage({ type: "success", title: "Đã xóa tài sản thành công!" });
				}

				// Đóng dialog và load lại dữ liệu
				this.deleteDialog = false;
				await Promise.all([this.getThongKe(), this.getDanhSachTaiSanBaoTri()]);

			} catch (error) {
				const errorMsg = error.response?.data?.Message || "Lỗi không thể xóa tài sản.";
				if (typeof showMessage === 'function') {
					showMessage({ type: "error", title: errorMsg });
				} else {
					alert(errorMsg);
				}
			} finally {
				this.loading = false;
			}
		},

		deleteAsset(item) {
			this.itemToDelete = item;
			this.deleteType = 1; // Reset về mặc định: chỉ xóa 1 cái
			this.deleteDialog = true; // Mở dialog
		},

		// --- CẬP NHẬT CHO MOBILE ---
		async checkAllChecklist(item) {
			if (!item.Checklist || item.Checklist.length === 0) return;

			// 1. Set tất cả các công việc là đã thực hiện
			item.Checklist.forEach(function (task) {
				task.DaThucHien = true;
			});

			// 2. Lưu lại vào backend (dùng hàm saveChecklist đã có)
			// await this.saveChecklist(item);

			// 3. Tự động set trạng thái là TỐT nếu chưa được đánh giá
			if (this.isChecklistDone(item) && item.TinhTrangSauBaoTri === null) {
				this.filteredMobileList.forEach(element => {
					if (element.MaCaBiet == item.MaCaBiet) {
						element.TinhTrangSauBaoTri = 1;
					}
				});
				// this.onMobileStatusChange(item, 1);
			}

		},

		// Cập nhật lại logic onMobileStatusChange để tự động lưu Checklist nếu có
		async onMobileStatusChange(item, val) {
			if (val === undefined) return;

			// Lưu trạng thái mới
			item.TinhTrangSauBaoTri = val;
			item.isExpanded = (val === 2); // Mở rộng nếu chọn Hỏng

			// Nếu checklist chưa xong, nhưng người dùng đã chọn Tốt/Hỏng, phải lưu checklist là xong
			if (!this.isChecklistDone(item)) {
				item.Checklist.forEach(task => task.DaThucHien = true);
			}

			try {
				await this.saveDataToBackend(item, item.ChiPhiBaoTri, item.GhiChuBaoTri);
				item.TrangThai = 1;
			} catch (e) {
				console.error("Lỗi cập nhật trạng thái mobile:", e);
			}
		},

		async saveMobileItem(item) {
			const cost = item.displayCostMobile ? Number(String(item.displayCostMobile).replace(/[^0-9]/g, '')) : 0;
			await this.saveDataToBackend(item, cost, item.GhiChuBaoTri);
		},
		async saveChecklist(item) {
			await this.saveDataToBackend(item, item.ChiPhiBaoTri, item.GhiChuBaoTri);
			// this.checklistCount(item)
			if (this.isChecklistDone(item) && !item.TinhTrangSauBaoTri) { this.onMobileStatusChange(item, 1); }
		},
		async openUpdateAsset(item) {
			await this.getChiTietDotBaoTri(item.MaChiTietDotBaoTri)

			// this.editItem = JSON.parse(JSON.stringify(kq));
			// this.editItem = kq;

			this.editCost = this.editItem.ChiPhiBaoTri;
			this.editDisplayCost = this.formatCurrency(this.editItem.ChiPhiBaoTri);
			this.editNote = this.editItem.GhiChuBaoTri;
			this.dialogUpdate = true;
		},
		async getChiTietDotBaoTri(maChiTietDotBaoTri) {
			try {

				const res = await axios.post("obj/TS_ChiTietDotBaoTri_Select_byMaChiTiet", {
					MaChiTietDotBaoTri: maChiTietDotBaoTri
				})
				this.editItem = res.data.data;
				this.editItem.Checklist = JSON.parse(this.editItem.Checklist)

			} catch (error) {
				const errorMsg = error.response?.data?.Message || "Lỗi lấy chi tiết đợt bảo trì.";
				showMessage({ type: "red", title: errorMsg });
			}
		},

		async getNhaCungCap() {
			try {
				const res = await axios.post("NhaCungCap_Select")
				this.dsNhaCungCap = res.data.data;
			} catch (error) {
				const errorMsg = error.response?.data?.Message || "Lỗi lấy chi tiết đợt bảo trì.";
				showMessage({ type: "red", title: errorMsg });
			}
		},

		async submitUpdateAsset() {
			await this.saveDataToBackend(this.editItem, this.editCost, this.editNote);
			this.dialogUpdate = false; this.getDanhSachTaiSanBaoTri();
		},
		async saveDataToBackend(item, cost, note) {
			try {
				this.cmdLoading = true;
				await axios.post("ChiTietDotBaoTri_Update", {
					MaChiTietDotBaoTri: item.MaChiTietDotBaoTri,
					MaCaBiet: item.MaCaBiet, MaDotBaoTri: this.event.MaDotBaoTri,
					GhiChu: note ? note.trim() : undefined, ChiPhiBaoTri: cost, TinhTrangSauBaoTri: item.TinhTrangSauBaoTri,
					Checklist: item.Checklist
				});
				this.getThongKe();
				this.getDanhSachTaiSanBaoTri();
			} catch (error) {
				const errorMsg = error.response?.data?.Message || "Lỗi cập nhật bảo trì";
				showMessage({ type: "red", title: errorMsg });
			} finally {
				this.cmdLoading = false;
			}

		},
		async confirmBatch() {
			if (!await this.$refs.confirm.open({ title: 'Xác nhận', message: 'Hoàn thành đợt bảo trì?' })) return;
			// Nối chuỗi ID bằng join
			// var listID = this.dsTaiSan.map(function (x) { return x.MaCaBiet; }).join(",");
			await axios.post("DotBaoTri_GiamSat_XacNhan", { MaDotBaoTri: this.event.MaDotBaoTri });
			this.dialog = false; this.$emit('refresh');
		},
		formatCurrency(val) { return val ? new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val) : '0 ₫'; },
		onlyNumberInput(e) { if (e.key < '0' || e.key > '9') e.preventDefault(); },
		print() { this.$refs.pdf.printpdf(); },

		async validate(refName, callback, confirmText = "Bạn có muốn lưu dữ liệu?", reset = true) {
			const form = this.$refs[refName];
			if (!form) {
				console.warn(`Form ref "${refName}" not found.`);
				return;
			}

			const { valid } = await form.validate();

			if (valid && typeof callback === "function") {
				const confirmed = await this.$refs.confirm.open(confirmText);
				if (!confirmed) return;
				await callback();
				if (reset) { console.log("reset"); form.reset() };
			}
		},

		async validateForm(maCaBiet) {
			const formComponent = this.formRefs[maCaBiet];

			if (formComponent) {
				const { valid } = await formComponent.validate();

				if (valid) {
					// Nếu form hợp lệ, gọi hàm lưu
					this.saveMobileItem(this.filteredMobileList.find(i => i.MaCaBiet === maCaBiet));
				} else {
					console.log('Form không hợp lệ');
				}
			}
		},
		async urlToBase64(url) {
			try {
				const res = await fetch(url);
				const blob = await res.blob();
				return await new Promise((resolve, reject) => {
					const reader = new FileReader();
					reader.readAsDataURL(blob);
					reader.onloadend = () => resolve(reader.result);
					reader.onerror = reject;
				});
			} catch (error) {
				console.error("Lỗi tải ảnh:", url, error);
				return null;
			}
		},
		// Utils
		getShortName(n) { return n ? n.split(" ").map(w => w[0]).join("").substring(0, 2).toUpperCase() : "DV" },
		isToday(d) { return d?.startsWith(new Date().toISOString().substr(0, 10)) },
		formatDate(d) { return d ? new Date(d).toLocaleDateString('vi-VN') : "" },
		formatCurrency(v) { return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(v || 0) },
		getStatusColor(s) {
			return s === 1 ? 'orange-darken-1' : s === 2 ? 'green-darken-1' : s === 3 ? 'red-darken-1' : 'grey'
		},
	}
}
</script>