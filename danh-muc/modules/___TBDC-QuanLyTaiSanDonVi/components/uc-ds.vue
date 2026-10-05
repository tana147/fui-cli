<template>
	<v-row class="ma-0 pa-0">
		<v-col class="pa-0" cols="12" md="3">
			<v-form ref="formLoc">
				<v-card class="rounded-lg mt-2"
					style="--tw-shadow: 0 1px 2px 0 rgb(0 0 0 / 0.05); --tw-shadow-colored: 0 1px 2px 0 var(--tw-shadow-color); box-shadow: var(--tw-ring-offset-shadow, 0 0 #0000), var(--tw-ring-shadow, 0 0 #0000), var(--tw-shadow);">
					<v-card-text class="py-1">
						<v-container fluid class="pa-0">
							<v-row dense>
								<v-col cols="12" sm="6">
									<v-autocomplete clearable required :rules="[v => v>=0 || 'Vui lòng chọn dữ liệu']"
										:return-object="false" class="my-3" v-model="selectedCoSo" label="Cơ sở"
										:items="dsCoSo" item-title="TenCoSo" item-value="MaCoSo" density="compact">
									</v-autocomplete>
								</v-col>

								<v-col cols="12" sm="6">
									<v-autocomplete clearable required :rules="[v => v>=0 || 'Vui lòng chọn dữ liệu']"
										:return-object="false" class="my-3" v-model="selectedToaNha" label="Toà nhà"
										:items="dsToaNha" item-title="ToaNha" item-value="MaToaNha" density="compact">
									</v-autocomplete>
								</v-col>
							</v-row>

							<v-row dense>
								<v-col cols="12" sm="6">
									<v-autocomplete clearable required :rules="[v => !!v || 'Vui lòng chọn dữ liệu']"
										:return-object="false" class="my-3" v-model="phongBanDangChon" label="Phòng ban"
										:items="dsPhongBan" item-title="TenPhongBan" item-value="PhongBanID"
										density="compact">
									</v-autocomplete>
								</v-col>

								<v-col cols="12" sm="6">
									<v-autocomplete clearable required :rules="[v => v>=0 || 'Vui lòng chọn dữ liệu']"
										:return-object="false" class="my-3" density="compact" v-model="viTriDangChon"
										label="Vị trí" :items="dsViTri" item-title="TenViTriPhong"
										item-value="MaViTriPhong">
									</v-autocomplete>
								</v-col>
							</v-row>

							<v-row dense>
								<v-col cols="12" sm="6">
									<v-autocomplete clearable required :rules="[v => v>=0 || 'Vui lòng chọn dữ liệu']"
										:return-object="false" class="my-3" density="compact" label="Loại"
										:items="dsLoai" v-model="loaiDangChon" item-title="TenDanhMuc"
										item-value="MaDM">
									</v-autocomplete>
								</v-col>

								<v-col cols="12" sm="6" class="d-flex align-center">
									<v-btn :loading="isLoading" block
										@click="kiemTraGiaTriYeuCau('formLoc',getDanhSachTaiSan)" class="my-3"
										height="40" color="primary"> Lọc dữ liệu
									</v-btn>
								</v-col>
							</v-row>
						</v-container>
					</v-card-text>
				</v-card>
			</v-form>
		</v-col>
		<v-col class="pa-0" cols="12" md="9">
			<v-item-group v-model="tinhTrangTaiSan" mandatory selected-class="bg-primary text--white">

				<v-row align="center" align-content="center">

					<v-col cols="6" md="3">

						<v-item :value="-1" v-slot="{ isSelected, selectedClass, toggle }">
							<uc-stat-card class="mb-3" @click="toggle" :bgclass="selectedClass" @thongKe="showTaiSanCho"
								title="Tổng tài sản của đơn vị" :colortitle="isSelected ? 'white' : 'grey'"
								:value="thongKe.TongTaiSan" icon="mdi-format-list-bulleted-type"
								coloricon="green darken-2" bgicon="green-lighten-5" />
						</v-item>

						<v-item :value="-2" v-slot="{ isSelected, selectedClass, toggle }">

							<uc-stat-card @click="toggle" :bgclass="selectedClass" @thongKe="showTaiSanCho"
								title="Tài sản chờ xác nhận" :colortitle="isSelected ? 'white' : 'grey'"
								:value="thongKe.ChoXacNhan" icon="mdi-progress-check" coloricon="primary darken-2"
								bgicon="#E3F2FD" />
						</v-item>

					</v-col>
					<v-col cols="6" md="3">

						<v-item :value="-10" v-slot="{ isSelected, selectedClass, toggle }">
							<uc-stat-card class="mb-3" @click="toggle" :bgclass="selectedClass" @thongKe="showTaiSanCho"
								title="Chưa cấp cho cá nhân" :colortitle="isSelected ? 'white' : 'grey'"
								:value="thongKe.ChuaCapChoCaNhan" icon="mdi-square-rounded-badge-outline"
								coloricon="green darken-2" bgicon="green-lighten-5" />
						</v-item>

						<v-item :value="11" v-slot="{ isSelected, selectedClass, toggle }">
							<uc-stat-card @click="toggle" :bgclass="selectedClass" @thongKe="showTaiSanCho"
								title="Tài sản dùng chung" :colortitle="isSelected ? 'white' : 'grey'"
								:value="thongKe.TaiSanDungChung" icon="mdi-account-group" coloricon="lime darken-2"
								bgicon="#F0F4C3" />
						</v-item>

					</v-col>
					<v-col cols="6" md="3">
						<v-item value="-100" v-slot="{ isSelected, selectedClass, toggle }">
							<uc-stat-card class="mb-3" @click="toggle" :bgclass="selectedClass" @thongKe="showTaiSanCho"
								:colortitle="isSelected ? 'white' : 'grey'" title="Tài sản đang sửa"
								:value="thongKe.DangSua" icon="mdi-tools" coloricon="teal" bgicon="teal-lighten-5" />
						</v-item>

						<v-item value="3" v-slot="{ isSelected, selectedClass, toggle }">
							<uc-stat-card @click="toggle" :bgclass="selectedClass" @thongKe="showTaiSanCho"
								:colortitle="isSelected ? 'white' : 'grey'" title="Cá nhân trả lại"
								:value="thongKe.CaNhanTraLai" icon="mdi-account-sync" coloricon="cyan"
								bgicon="cyan-lighten-5" />
						</v-item>
					</v-col>
					<v-col cols="6" md="3">
						<v-item value="2" v-slot="{ isSelected, selectedClass, toggle }">
							<uc-stat-card class="mb-3" @click="toggle" :bgclass="selectedClass" @thongKe="showTaiSanCho"
								:colortitle="isSelected ? 'white' : 'grey'" title="Cá nhân chưa xác nhận"
								:value="thongKe.ChoCaNhanXacNhan" icon="mdi-account-clock" coloricon="primary"
								bgicon="#E3F2FD" />
						</v-item>

						<v-item v-slot="{ isSelected, selectedClass, toggle }">
							<uc-stat-card @click="openMuonTaiSan" :bgclass="selectedClass" @thongKe="showTaiSanCho"
								title="Đang cho mượn" :colortitle="isSelected ? 'white' : 'grey'"
								:value="thongKe.DangChoMuon" icon="mdi-hand-coin" coloricon="blue darken-2"
								bgicon="#E3F2FD" />
						</v-item>
					</v-col>
				</v-row>
			</v-item-group>
		</v-col>
	</v-row>

	<v-card elevation="1" class="ma-0  rounded-lg pa-0">

		<v-card-actions>

			<v-row>
				<v-col class="pa-0" cols="12" sm="3" align-self="center">
					<h4 style="" class=" mx-2 text-primary">Danh sách tài sản trong đơn vị [{{dsTaiSan.length}}]</h4>
				</v-col>
				<v-col class="pa-0" cols="12" sm="4" align-self="center">

					<v-checkbox class="mr-2 ml-1" v-model="filterEmptyMaVach" label="Lọc tài sản chưa có Mã Vạch">
					</v-checkbox>

				</v-col>
				<v-col class="pa-0" cols="12" sm="5" align-self="center">
					<v-row justify="start" justify-sm="end">
						<v-text-field style="max-width: 300px" class="ma-1" v-model="search" density="compact"
							label="Search" prepend-inner-icon="mdi-magnify" variant="solo-filled" flat hide-details
							single-line>
						</v-text-field>
					</v-row>
				</v-col>
			</v-row>
		</v-card-actions>

		<v-dialog v-model="dialogAdd" width="700px">
			<v-card rounded="lg">
				<v-toolbar color="primary">
					<v-toolbar-title>Thêm tài sản vào phiếu nhập</v-toolbar-title>
					<v-btn icon="mdi-close" @click="dialogAdd = false"></v-btn>
				</v-toolbar>
				<v-divider></v-divider>

			</v-card>
		</v-dialog>

		<v-divider></v-divider>

		<v-data-table-virtual class="pb-5 mb-5" :loading="isLoading" :group-by="groupBy" v-model="selected"
			:headers="headers" :items="filterEmptyMaVach ? filteredItems : dsTaiSan " item-value="MaCaBiet" show-select
			hide-default-footer :search="search" height="1000" density="compact" fixed-header>
			<template v-slot:group-header="{ item, columns, toggleGroup, isGroupOpen }">
				<tr>
					<td :colspan="columns.length">
						<div class="d-flex align-center">
							<v-btn :icon="isGroupOpen(item) ? '$expand' : '$next'" color="medium-emphasis"
								density="comfortable" size="small" variant="outlined" @click="toggleGroup(item)">
							</v-btn>

							<!-- <v-checkbox v-if="tinhTrangTaiSan != -1" v-model="groupSelection[item.value]" class="ms-4"
								density="compact" style="margin-top: -2px;"
								@change="toggleGroupSelection(item)"></v-checkbox> -->

							<v-checkbox v-model="groupSelection[item.value]" class="ms-4" density="compact"
								style="margin-top: -2px;" @change="toggleGroupSelection(item)"></v-checkbox>

							<!-- <span style=" cursor: pointer;" class=" ms-4" @click="toggleGroup(item)">{{
								item.items[0].raw.TenTaiSan }} - {{item.items[0].raw.TenModel}} - [
								{{item.items.length}} ]</span> -->

							<span style=" cursor: pointer;" class=" ms-4" @click="toggleGroup(item)">{{
								item.items[0].raw.TenDanhMuc }} - [
								{{item.items.length}} ]</span>

							<v-chip v-if="item.items[0].raw.TinhTrang == 8" class="ms-2" size="x-small" color="red">
								New
							</v-chip>
						</div>
					</td>
				</tr>
			</template>
			<template v-slot:item.TaiSanLienKet="{item}">
				<v-chip color="primary" variant="tonal" size="small" class="mx-1"
					v-for="i in JSON.parse(item.TaiSanLienKet)">
					<uc-asset-info :key="childKey" :tentaisan="i.TenTaiSan" :macabiet="i.MaCaBiet"></uc-asset-info>
				</v-chip>
			</template>

			<template v-slot:item.TenTaiSan="{item}">
				<uc-asset-info :key="childKey" @update="update" classforname="text-subtitle-2 "
					:tentaisan="item.TenTaiSan" :macabiet="item.MaCaBiet" :mataisan="item.MaTS"></uc-asset-info>

			</template>
			<template #item.MaVach="{item}">
				<span>{{item.MaVach}}</span>
				<v-btn prepend-icon="mdi-qrcode" size="small" class="my-1" v-if="!item.MaVach" color="primary"
					value="recent" @click="()=>{taiSanDangChon = item; isOpenUpdateQR = true}">
					<!-- <v-icon>mdi-qrcode</v-icon> -->
					Update QR
				</v-btn>
			</template>
		</v-data-table-virtual>

		<!-- nút chức năng -->
		<div>
			<v-fab absolute app v-show="selected.length>0" :color="showFabmenu ? '' : 'primary'" location="right top"
				size="large" icon>
				<v-icon>{{ showFabmenu ? 'mdi-close' : 'mdi-pencil' }}</v-icon>
				<v-speed-dial v-model="showFabmenu" location="bottom center" transition="slide-y-transition"
					activator="parent">


					<v-tooltip v-if="tinhTrangTaiSan == -2 || tinhTrangTaiSan == 3" text="Xác nhận tài sản">
						<template v-slot:activator="{ props }">

							<v-btn variant="flat" color="primary" v-bind="props" icon @click="xacNhanTaiSan">
								<v-icon size="24">mdi-check-circle</v-icon>
							</v-btn>
						</template>
					</v-tooltip>

					<v-tooltip v-if="tinhTrangTaiSan != 2 && tinhTrangTaiSan != -2 && tinhTrangTaiSan != 3"
						text="Cấp tài sản cho cá nhân">
						<template v-slot:activator="{ props }">

							<v-btn variant="flat" color="success" v-bind="props" @click="confirmTransfer" icon>
								<v-icon>mdi-swap-horizontal-bold</v-icon>
							</v-btn>
						</template>
					</v-tooltip>

					<v-tooltip v-if="tinhTrangTaiSan != 2 && tinhTrangTaiSan != -2 && tinhTrangTaiSan != 3"
						text="Chuyển vị trí">
						<template v-slot:activator="{ props }">

							<v-btn variant="flat" color="error" v-bind="props" @click="isOpenChuyenViTri = true" icon>
								<v-icon>mdi-map-marker-radius</v-icon>
							</v-btn>
						</template>
					</v-tooltip>

					<!-- <v-tooltip text="Cho mượn tài sản">
						<template v-slot:activator="{ props }">

							<v-btn variant="flat" color="warning" @click="showDialogMuonTaiSan = true" v-bind="props"
								icon>
								<v-icon>mdi-hand-coin</v-icon>
							</v-btn>
						</template>
					</v-tooltip> -->
					<v-tooltip v-if="tinhTrangTaiSan != 2 && tinhTrangTaiSan != 3" text="Trả tài sản">
						<template v-slot:activator="{ props }">

							<v-btn variant="flat" color="brown" v-bind="props" icon @click="traTaiSan">
								<v-icon>mdi-arrow-u-left-top-bold</v-icon>
							</v-btn>
						</template>
					</v-tooltip>

					<v-tooltip v-if="tinhTrangTaiSan != 2 && tinhTrangTaiSan != -2 && tinhTrangTaiSan != 3"
						text="Tạo tài sản dùng chung">
						<template v-slot:activator="{ props }">

							<v-btn variant="flat" color="warning" v-bind="props" icon
								@click="showTaoTaiSanDungChung = true">
								<v-icon>mdi-shield-star</v-icon>
							</v-btn>
						</template>
					</v-tooltip>

					<v-tooltip v-if="tinhTrangTaiSan != 2 && tinhTrangTaiSan != -2 && tinhTrangTaiSan != 3"
						text="Yêu cầu thanh lý">
						<template v-slot:activator="{ props }">

							<v-btn variant="flat" color="error" v-bind="props" icon @click="yeuCauThanhLy">
								<v-icon>mdi-delete-forever</v-icon>
							</v-btn>
						</template>
					</v-tooltip>
				</v-speed-dial>
			</v-fab>
		</div>
		<v-dialog v-model="isOpenChuyenViTri" max-width="500px">
			<v-card>
				<v-form ref="formChuyenViTri">
					<v-toolbar color="">
						<v-toolbar-title>Chuyển vị trí</v-toolbar-title>
						<v-btn size="small" icon="mdi-close" @click="isOpenChuyenViTri = false"></v-btn>
					</v-toolbar>
					<v-divider></v-divider>

					<v-card-text>
						<v-autocomplete reqired :rules="[v => !!v || 'Vui lòng vị trí']" class="my-3" density="compact"
							label="Vị trí phòng" :items="dsViTriPhong" v-model="viTriChuyenDen"
							item-title="TenViTriPhongCoSo" item-value="MaViTriPhong">
						</v-autocomplete>
					</v-card-text>
					<v-divider></v-divider>

					<v-card-actions>
						<v-spacer></v-spacer>
						<v-btn variant="tonal" @click="validate('formChuyenViTri', chuyenViTri)" color="primary">
							Chuyển
						</v-btn>
					</v-card-actions>
				</v-form>
			</v-card>
		</v-dialog>
		<v-dialog v-model="showDialogMuonTaiSan" max-width="600px">
			<v-card>
				<v-form ref="formMuonTaiSan">
					<v-toolbar color="">
						<v-toolbar-title>Cho mượn tài sản</v-toolbar-title>
						<v-btn size="small" icon="mdi-close" @click="showDialogMuonTaiSan = false"></v-btn>
					</v-toolbar>
					<v-divider></v-divider>
					<v-card-text>

						<div> <span class="text-subtitle-2 text-grey">Nhân viên cho mượn:</span> <span
								class="text-h6">{{nguoiChoMuon}}</span></div>
						<v-divider></v-divider>

						<v-combobox class="mb-3 mt-3" v-model="nguoiMuon" label="Người mượn" :items="dsNguoiMuon"
							item-title="HoTen" item-value="MaNV" density="compact" required>
						</v-combobox>

						<!-- <v-combobox class="mb-3" v-model="nguoiChoMuon" label="Người cho mượn" :items="dsNguoiMuon"
							item-title="ten" item-value="id" density="compact" required>
						</v-combobox> -->


						<v-combobox class="mb-3" v-model="taiSan" label="Tài sản" :items="dsTaiSanChoMuon"
							item-title="TenTaiSan" item-value="MaCaBiet" density="compact" required>
						</v-combobox>

						<!-- <v-text-field class="mb-3" v-model="ngayMuon" label="Ngày mượn" type="date" readonly>
						</v-text-field> -->
						<uc-date-picker class="mb-3" label="Ngày mượn" v-model="ngayMuon"></uc-date-picker>

						<v-text-field class="mb-3" v-model.number="soNgayMuon" label="Số ngày mượn" type="number"
							min="1" required>
						</v-text-field>
						<uc-date-picker :min="ngayMuon" class="mb-3" label="Hạn trả" v-model="hanTra"></uc-date-picker>

					</v-card-text>
					<v-card-actions>
						<v-spacer></v-spacer>
						<v-btn color="primary" type="submit" @click="choMuonTaiSan">Xác nhận mượn</v-btn>
					</v-card-actions>
				</v-form>
			</v-card>
		</v-dialog>

		<v-dialog v-model="showChuyenTaiSan" max-width="500px">
			<v-card>
				<v-form ref="formChuyenTaiSan">
					<v-toolbar color="">
						<v-toolbar-title>Cấp tài sản cho cá nhân</v-toolbar-title>
						<v-btn size="small" icon="mdi-close" @click="showChuyenTaiSan = false"></v-btn>
					</v-toolbar>
					<v-divider></v-divider>

					<v-card-text>
						<v-autocomplete reqired :rules="[v => !!v || 'Vui lòng vị trí']" class="my-3" density="compact"
							v-model="maNhanVien" label="Chọn nhân viên" :items="dsNhanVien" item-title="HoTen"
							item-value="MaNV">
							<template v-slot:chip="{ props, item }">
								<v-chip v-bind="props"
									:prepend-avatar="'https://file.lhbs.vn/me/avatar/' + item.raw.MaNV + '.jpg'"
									:text="item.raw.HoTen" />
							</template>


							<template #item="{ props, item }">
								<v-list-item v-bind="props"
									:prepend-avatar="'https://file.lhbs.vn/me/avatar/' + item.raw.MaNV + '.jpg'">
									<v-list-item-subtitle>{{ item.raw.MaNV }}
									</v-list-item-subtitle>
								</v-list-item>
							</template>
						</v-autocomplete>
						<!-- <v-autocomplete reqired :rules="[v => !!v || 'Vui lòng vị trí']" class="my-3" density="compact"
							label="Vị trí phòng" :items="dsViTriPhong" v-model="maViTriPhong"
							item-title="TenViTriPhongCoSo" item-value="MaViTriPhong">

						</v-autocomplete> -->
					</v-card-text>
					<v-divider></v-divider>

					<v-card-actions>
						<v-spacer></v-spacer>
						<v-btn variant="tonal" @click="validate('formChuyenTaiSan', chuyenTaiSanChoCaNhan)"
							color="primary">
							Chuyển
						</v-btn>
					</v-card-actions>
				</v-form>
			</v-card>
		</v-dialog>

		<v-dialog v-model="showTaoTaiSanDungChung" max-width="800px">
			<v-card>
				<v-form ref="formTaiSanChung">
					<v-toolbar>
						<v-toolbar-title class="text-primary">Tạo tài sản dùng chung</v-toolbar-title>
						<v-btn size="small" icon="mdi-close" @click="showTaoTaiSanDungChung = false"></v-btn>
					</v-toolbar>
					<v-divider></v-divider>

					<v-card-text>
						<v-combobox required :rules="[v => !!v || 'Item is required']" class="my-3" density="compact"
							v-model="nguoiQuanLyTaiSan" label="Chọn nhân viên quản lý" :items="dsNhanVien"
							item-title="HoTen" item-value="MaNV">
						</v-combobox>

						<v-data-table-virtual :headers="headersTaiSanDungChung" :items="dsTaiSanDungChung"
							class="elevation-1" density="compact" hide-default-footer item-key="ID"
							:search="searchTSDungChung">
							<template v-slot:top>
								<div class="d-flex my-2 mx-2">
									<h5 class="text-subtitle-1 text-primary my-2 ml-2">Danh sách tài sản đã tạo dùng
										chung
									</h5>
									<v-spacer></v-spacer>
									<v-text-field style="max-width: 300px" class="ml-1" v-model="searchTSDungChung"
										density="compact" label="Search" prepend-inner-icon="mdi-magnify"
										variant="solo-filled" flat hide-details single-line>
									</v-text-field>
								</div>

							</template>


							<template v-slot:item.CreateTime="{ item }">
								{{ item.CreateTime }}
							</template>

							<template v-slot:item.actions="{ item }">
								<v-btn size="small" icon="mdi-delete" variant="text" color="red"
									@click="xoaTaiSanDungChung(item.ID)">
								</v-btn>
							</template>
						</v-data-table-virtual>

					</v-card-text>
					<v-divider></v-divider>

					<v-card-actions>
						<v-spacer></v-spacer>
						<v-btn variant="tonal" @click="validate('formTaiSanChung',insertTaiSanDungChung)"
							color="primary">
							Cập nhật
						</v-btn>
					</v-card-actions>
				</v-form>

			</v-card>
		</v-dialog>

		<!-- Hộp thoại xác nhận chuyển tài sản liên kết -->
		<v-dialog v-model="showConfirmDialog" max-width="600">
			<v-card>
				<v-card-title class="text-h6">Xác nhận luân chuyển</v-card-title>
				<v-card-text>
					Tài sản này có tài sản liên kết.
					<br>Bạn có muốn luân chuyển cả tài sản liên kết không?
					<br>Nếu không, bạn cần vào danh sách tài sản để xóa liên kết trước khi tiếp tục.
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn variant="plain" @click="removeLinkedAssets">Trở lại</v-btn>
					<v-btn variant="tonal" color="primary" class="font-weight-bold"
						@click="()=>{showConfirmDialog = false; showChuyenTaiSan = true}">Có
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</v-card>

	<v-dialog :fullscreen="$vuetify.display.xs" v-model="showQrDialog" width="500" height="100%">
		<v-card>
			<v-toolbar color="primary">
				<v-toolbar-title>Quét mã</v-toolbar-title>
				<v-btn size="small" icon="mdi-close" @click="showQrDialog = false"></v-btn>
			</v-toolbar>
			<v-card-text :style="{padding: '0', aspectRatio: 1/1 ,width:'100%' }">
				<uc-qr v-model="qrUpdate" ref="qrScanner">
					<template #default>
						<v-row class="mt-2">
							<v-col class="px-0" cols="4"></v-col>
							<v-col class="px-0" cols="4" style="text-align: center;">
								<v-btn icon variant="flat" color="primary" @click="$refs.qrScanner?.triggerFileInput()">
									<v-icon color="white">mdi-image</v-icon>
								</v-btn>
								<div style="color: gray; font-size: 0.75rem; margin-top: 4px;">Thư viện</div>
							</v-col>
							<v-col class="px-0" cols="4"></v-col>
						</v-row>
					</template>
				</uc-qr>
			</v-card-text>
		</v-card>
	</v-dialog>

	<v-dialog v-model="isOpenUpdateQR" max-width="500px">
		<v-card>
			<v-form ref="formQR">
				<v-toolbar color="primary">
					<v-toolbar-title>{{taiSanDangChon.TenTaiSan}}</v-toolbar-title>
					<v-btn size="small" icon="mdi-close" @click="isOpenUpdateQR = false"></v-btn>
				</v-toolbar>
				<v-divider></v-divider>

				<v-card-text>

					<span class="text-subtitle-1">Mã QR hiện tại:
						{{taiSanDangChon.MaVach ? taiSanDangChon.MaVach : "Chưa có"}}</span>
					<v-autocomplete reqired :rules="[v => !!v || 'Vui lòng nhập dữ liệu']" class="my-2"
						style="min-width: 200px" v-model="qrUpdate" placeholder="Mã vạch" :items="dsMaVachChuaDung"
						item-value="MaVach" item-title="MaVach" density="compact" :clearable="false" hide-details>
					</v-autocomplete>

					<v-btn prepend-icon="mdi-qrcode-scan" variant="tonal" @click="showQrDialog=true">Quét mã
						QR</v-btn>
				</v-card-text>
				<v-divider></v-divider>

				<v-card-actions>

					<v-btn block variant="tonal" @click="validate('formQR', () => updateMaQR(taiSanDangChon.MaCaBiet))"
						color="primary">
						Cập nhật
					</v-btn>
				</v-card-actions>
			</v-form>
		</v-card>
	</v-dialog>

	<uc-confirm ref="confirm"></uc-confirm>
</template>

<script>
	export default {
		props: ["assets"],
		data() {
			return {
				filterEmptyMaVach: false,
				headersTaiSanDungChung: [
					{ title: 'Mã TS', key: 'MaVach' },
					{ title: 'Tên tài sản', key: 'TenTaiSan' },
					{ title: 'Người quản lý', key: 'NguoiQuanLy' },
					{ title: 'Ngày tạo', key: 'CreateTime' },
					{ title: 'Thao tác', key: 'actions', sortable: false }
				],
				showQrDialog: false,
				isOpenUpdateQR: false,
				qrUpdate: null,
				dsMaVachChuaDung: [],
				dsTaiSanDungChung: [],
				dsCoSo: [],
				selectedCoSo: null,
				taiSanDangChon: null,
				isLoading: false,
				searchTSDungChung: null,
				isOpenChuyenViTri: false,
				showTaoTaiSanDungChung: false,
				nguoiQuanLyTaiSan: null,
				nguoiMuon: null,
				nguoiChoMuon: vueData.user.LastName + ' ' + vueData.user.FirstName,
				taiSan: null,
				soNgayMuon: 1,
				ngayMuon: new Date().toISOString().substr(0, 10),
				hanTra: new Date().toISOString().substr(0, 10),
				ngayTra: null,
				dsNguoiMuon: [],
				dsTaiSanChoMuon: [],
				choPhepTra: false,
				dsMuon: [],
				showDialogMuonTaiSan: false,
	
				dialogAdd: false,
				search: null,
				showChuyenTaiSan: false,
				showConfirmDialog: false,
				showFabmenu: false,
				dsViTriPhong: [],
				dsNhanVien: [],
				maNhanVien: null,
				maViTriPhong: null,
				tinhTrangTaiSan: -1,
				thongKe: {
					TongTaiSan: 0,
					ChoXacNhan: 0,
					ChoCaNhanXacNhan: 0,
					ChuaCapChoCaNhan: 0,
					CaNhanTraLai: 0,
					DangSua: 0,
					DangChoMuon: 0,
					TaiSanDungChung: 0
				},
				dsViTri: [],
				dsLoai: [],
				selected: [],
				dsPhongBan: [],
				dsTaiSan: [],
				dsToaNha: [],
				selectedToaNha: null,
				phongBanDangChon: null,
				viTriDangChon: null,
				loaiDangChon: null,
				viTriChuyenDen: null,
	
				dialogChiTietTaiSan: false,
				groupSelection: {},
				groupBy: [{ key: 'MaDM', order: 'desc' }],
				headers: [
					{ title: 'Mã TS', key: 'MaVach', align: 'start' },
	
					{
						title: 'Tên',
						align: 'start',
						sortable: false,
						key: 'TenTaiSan',
						nowrap: true
					},
					{ title: 'Danh mục', key: 'TenDanhMuc' },
					{ title: 'Serial', key: 'SoSeries' },
					{ title: 'Vị trí', key: 'TenViTriPhong' },
					{ title: 'Cá nhân sử dụng', key: 'TenCaNhanDuocCap' },
					{ title: 'Tài sản liên kết', key: 'TaiSanLienKet' },
	
				],
	
				childKey: this.generateRandomKey()
	
	
			}
		},
		async mounted() {
			// this.getDanhSachTaiSan();
			await this.getCoSo();
			await this.getDanhSachDanhMucTaiSan();
			// await this.getDanhSachViTri();
	
	
		},
		computed: {
			groupedItems() {
				return this.dsTaiSan.reduce((acc, item) => {
					if (!acc[item.MaDM]) acc[item.MaDM] = [];
					acc[item.MaDM].push(item);
					return acc;
				}, {});
			},
			filteredItems() {
				if (this.filterEmptyMaVach) {
					return this.dsTaiSan.filter(
						(i) => !i.MaVach || i.MaVach.trim() === ""
					);
				}
				return this.items;
			}
		},
		watch: {
	
			isOpenUpdateQR() {
				if (this.isOpenUpdateQR) {
					this.getMaVachChuaDung();
				}
			},
			qrUpdate() {
				if (this.qrUpdate) {
					this.showQrDialog = false;
				}
			},
			selected(newVal) {
	
				this.updateGroupSelection();
			},
	
			async selectedCoSo(newVal, oldVal) {
	
				await this.getToaNhaByCoSo();
				// await this.getDanhSachPhongBan();
	
			},
			async selectedToaNha(newVal, oldVal) {
	
				await this.getDanhSachPhongBan();
				await this.getDanhSachViTri();
	
			},
	
			phongBanDangChon() {
				this.getDanhSachViTri();
	
				console.log(this.phongBanDangChon);
				// this.getDanhSachTaiSan();
				// this.getThongKe();
			},
			viTriDangChon() {
				// this.getDanhSachTaiSan();
				// this.getThongKe();
			},
			loaiDangChon() {
				// this.getDanhSachTaiSan();
				// this.getThongKe();
			},
			tinhTrangTaiSan() {
				this.getDanhSachTaiSan();
			},
			dsTaiSan() {
				this.selected = []
			},
			showChuyenTaiSan() {
				if (this.showChuyenTaiSan) {
					this.maNhanVien = null;
					this.getDanhSachNhanVien();
					this.getDanhSachViTriPhong();
				}
			},
			showDialogMuonTaiSan() {
				this.getDanhSachNhanVien();
				this.getAllNguoiMuon();
				this.getTaiSanChoMuon();
			},
	
			showTaoTaiSanDungChung() {
				this.getDanhSachNhanVien();
				this.getDanhSachTaiSanDungChung();
			},
			isOpenChuyenViTri() {
				this.getDanhSachViTriPhong();
			}
	
	
		},
		methods: {
			generateRandomKey() {
				return Math.random().toString(36).substring(2, 10)
			},
			async updateMaQR() {
				try {
					await axios
						.post("CaBietTaiSan_Insert_Mavach", {
							MaCB: this.taiSanDangChon.MaCaBiet,
							MaVach: this.qrUpdate,
						})
						.then(() => {
							CALL({ MESS: "Cập nhật thành công" });
						})
						.catch((error) => {
							showMessage({ type: "red", title: error.response.data.Message });
						});
	
					this.showCapNhatQR = false;
					await this.getDanhSachTaiSan();
					this.isOpenUpdateQR = false;
				} catch (error) {
					showMessage({ type: "red", title: "Lỗi cập nhật mã QR" });
				}
			},
			async getMaVachChuaDung() {
				this.dsMaVachChuaDung = await axios
					.post("MaVach_ChuaDung")
					.then((res) => {
						// console.log("data ne: ", res.data.data)
						return res.data.data;
					})
					.catch((err) => {
						showMessage({ type: "red", title: err.response.data.Message });
					});
			},
			openMuonTaiSan() {
				window.location.href = 'https://danhmuc.zentea.vn/TBDC-MuonTaiSan';
			},
			async update() {
				this.getThongKe();
				this.getDanhSachTaiSan();
			},
			async getDanhSachTaiSanDungChung() {
				try {
					const response = await axios.post("TS_TaiSanDungChung_Select");
					this.dsTaiSanDungChung = response.data.data || [];
				} catch (error) {
					showMessage({ type: "red", title: "Không thể lấy danh sách tài sản dùng chung" });
				}
			},
			async chuyenViTri() {
				try {
					await axios.post("TS_DonVi_ChuyenViTriTaiSan", {
						DanhSachMaCaBiet: this.selected.toString(),
						ViTriPhongID: this.viTriChuyenDen
					})
						.then(() => {
							CALL({ "MESS": "Cập nhật thành công" })
						})
						.catch((error) => {
							showMessage({ type: "red", title: error.response.data.Message })
						})
	
	
					this.getThongKe();
					this.getDanhSachTaiSan();
					this.isOpenChuyenViTri = false;
				} catch (error) {
					showMessage({ type: "red", title: "Lỗi cập nhật" })
				}
			},
			async getCoSo() {
				this.dsCoSo = await axios.post("TS_CoSo_Select_Combobox")
					.then((res) => {
						return res.data.data;
					})
					.catch((err) => {
						console.log(err);
					})
					this.dsCoSo.unshift({ "TenCoSo": "Tất cả", "MaCoSo": 0 });
			},
	
			async getToaNhaByCoSo() {
				this.dsToaNha = await axios.post("TS_ToaNha_SelectByMaCoSo_Combobox", {
					MaCoSo: this.selectedCoSo
				}
				)
					.then((res) => {
						return res.data.data;
					})
					.catch((err) => {
						console.log(err);
					})
					this.dsToaNha.unshift({ "ToaNha": "Tất cả", "MaToaNha": 0 });
			},
	
			async xoaTaiSanDungChung(id) {
				const confirmed = await this.$refs.confirm.open({
					title: 'Xác nhận',
					message: 'Bạn có chắc chắn muốn xoá tài sản dùng chung này?',
					okText: 'Xoá',
					cancelText: 'Hủy',
					okColor: 'red'
				});
	
				if (!confirmed) return;
	
				try {
					await axios.post("TS_TaiSanDungChung_Delete", { ID: id });
					CALL({ MESS: "Đã xoá thành công" });
					this.getDanhSachTaiSanDungChung();
				} catch (error) {
					showMessage({ type: "red", title: error.response?.data?.Message || "Lỗi xoá" });
				}
			},
			showTaiSanCho() {
				this.getThongKe();
			},
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
					if (reset) form.reset();
				}
			},
			async kiemTraGiaTriYeuCau(refName, callback) {
	
				const form = this.$refs[refName];
				if (!form) {
					console.warn(`Form ref "${refName}" not found.`);
					return;
				}
	
				const { valid } = await form.validate();
	
				if (valid && typeof callback === "function") {
	
					await callback();
	
				}
			},
	
			submitForm() {
				if (!this.nguoiMuon || !this.taiSan || !this.soNgayMuon) {
					alert("Vui lòng nhập đầy đủ thông tin");
					return;
				}
				const data = {
					nguoiMuon: this.nguoiMuon,
					taiSan: this.taiSan,
					soNgayMuon: this.soNgayMuon,
					ngayMuon: this.ngayMuon,
					hanTra: this.hanTra,
					ngayTra: this.ngayTra,
				};
				console.log("Dữ liệu gửi đi:", data);
			},
	
			refresh() {
				this.$emit("refresh");
			},
	
			confirmTransfer() {
				const selectedAssets = this.dsTaiSan.filter(ts => this.selected.includes(ts.MaCaBiet));
				const hasLinkedAssets = selectedAssets.some(ts => {
					const linkedAssets = ts.TaiSanLienKet ? JSON.parse(ts.TaiSanLienKet) : [];
					return linkedAssets.length > 0;
				});
	
				if (hasLinkedAssets) {
					this.showConfirmDialog = true;
				} else {
					this.showChuyenTaiSan = true;
				}
			},
			confirmAndSave() {
				this.showConfirmDialog = false;
				this.chuyenTaiSanChoCaNhan();
			},
			removeLinkedAssets() {
				this.showConfirmDialog = false;
			},
	
			// async getDanhSachTaiSan() {
			// 	try {
			// 		this.isLoading = true;
			// 		if (!this.phongBanDangChon) {
			// 			return;
			// 		}
	
	
			// 		let response = [];
			// 		if (this.tinhTrangTaiSan == -100) {
			// 			response = await axios.post("TaiSan_Select_DangSua_byPhongBan", {
			// 				"PhongBanID": this.phongBanDangChon
			// 			});
	
			// 		}
			// 		else if (this.tinhTrangTaiSan == -10) {
			// 			response = await axios.post("TaiSan_Select_PhongBan_ViTri_DanhMuc_ChuaCapChoCaNhan", {
			// 				"PhongBanID": this.phongBanDangChon,
			// 				"ViTriPhongID": this.viTriDangChon || 0,
			// 				"DanhMucID": this.loaiDangChon || 0
			// 			});
	
			// 		} else if (this.tinhTrangTaiSan == 11) {
			// 			response = await axios.post("TaiSan_Select_PhongBan_DungChung", {
			// 				"PhongBanID": this.phongBanDangChon,
			// 			});
	
			// 		} else {
			// 			response = await axios.post("TaiSan_Select_PhongBan_TinhTrang_ViTri_DanhMuc", {
			// 				"TinhTrangID": this.tinhTrangTaiSan,
			// 				"PhongBanID": this.phongBanDangChon,
			// 				"ViTriPhongID": this.viTriDangChon || 0,
			// 				"DanhMucID": this.loaiDangChon || 0
			// 			});
			// 		}
	
			// 		this.dsTaiSan = response.data.data || [];
			// 		await this.getThongKe();
			// 	} catch (error) {
			// 		console.error('Error fetching assets:', error);
			// 	}
			// 	finally {
			// 		this.isLoading = false;
			// 	}
			// },
	
	
			async getDanhSachTaiSan() {
				try {
					this.isLoading = true;
					if (!this.phongBanDangChon) {
						return;
					}
	
	
					let response = [];
					if (this.tinhTrangTaiSan == -100) {
						response = await axios.post("TS_TaiSan_Select_DangSua_byPhongBan", {
							"PhongBanID": this.phongBanDangChon
						});
	
					}
					else if (this.tinhTrangTaiSan == -10) {
						response = await axios.post("TS_TaiSan_Select_PhongBan_ViTri_DanhMuc_ChuaCapChoCaNhan", {
							"PhongBanID": this.phongBanDangChon,
							"ViTriPhongID": this.viTriDangChon || 0,
							"DanhMucID": this.loaiDangChon || 0
						});
	
					} else if (this.tinhTrangTaiSan == 11) {
						response = await axios.post("TS_TaiSan_Select_PhongBan_DungChung", {
							"PhongBanID": this.phongBanDangChon,
							"MaCoSo": this.selectedCoSo,
							"MaToaNha": this.selectedToaNha,
						});
	
					} else {
						response = await axios.post("TS_TaiSan_Select_CoSo_ToaNha_PhongBan_TinhTrang_ViTri_DanhMuc_DonVi", {
							"TinhTrangID": this.tinhTrangTaiSan,
							"MaCoSo": this.selectedCoSo,
							"MaToaNha": this.selectedToaNha,
							"PhongBanID": this.phongBanDangChon,
							"ViTriPhongID": this.viTriDangChon || 0,
							"DanhMucID": this.loaiDangChon || 0
						});
					}
	
					this.dsTaiSan = response.data.data || [];
					await this.getThongKe();
				} catch (error) {
					console.error('Error fetching assets:', error);
				}
				finally {
					this.isLoading = false;
				}
			},
	
			// async getDanhSachViTri() {
			// 	try {
			// 		const response = await axios.post("ViTriPhong_SelectByPhongBan", {
			// 			PhongBanID: this.phongBanDangChon
			// 		});
			// 		this.dsViTri = response.data.data || [];
			// 		this.dsViTri.unshift({ "TenViTriPhong": "Tất cả", "MaViTriPhong": 0 });
			// 		this.viTriDangChon = 0
			// 	} catch (error) {
			// 		console.error('Error fetching assets:', error);
			// 	}
			// },
			async getDanhSachViTri() {
				try {
					const response = await axios.post("TS_ViTriPhong_SelectByCoSo_ToaNha", {
						MaCoSo: this.selectedCoSo,
						MaToaNha: this.selectedToaNha,
						PhongBanID: this.phongBanDangChon
					});
					this.dsViTri = response.data.data || [];
					this.dsViTri.unshift({ "TenViTriPhong": "Tất cả", "MaViTriPhong": 0 });
					this.viTriDangChon = 0
				} catch (error) {
					console.error('Error fetching assets:', error);
				}
			},
	
	
			async getThongKe() {
				try {
					if (!this.phongBanDangChon) return;
					const response = await axios.post("/obj/TS_ThongKe_TaiSanDonVi_PhongBan_ViTri_DanhMuc", {
						PhongBanID: this.phongBanDangChon,
						ViTri: this.viTriDangChon ? this.viTriDangChon : 0,
						DanhMuc: this.loaiDangChon ? this.loaiDangChon : 0,
						"MaCoSo": this.selectedCoSo,
						"MaToaNha": this.selectedToaNha,
					});
					this.thongKe = response.data.data || [];
	
				} catch (error) {
					console.error('Error fetching assets:', error);
				}
			},
	
			async getDanhSachDanhMucTaiSan() {
				try {
					const response = await axios.post("TS_TS_DanhMuc_Select_Option");
					this.dsLoai = response.data.data || [];
					this.dsLoai.unshift({ "TenDanhMuc": "Tất cả", "MaDM": 0 });
					this.loaiDangChon = 0
				} catch (error) {
					console.error('Error fetching assets:', error);
				}
			},
			// async getDanhSachPhongBan() {
			// 	try {
			// 		const response = await axios.post("PhongBan_Select_ByUserID");
			// 		this.dsPhongBan = response.data.data || [];
			// 		this.dsPhongBan.unshift({ "PhongBanID": "0", "TenPhongBan": "Tất cả" });
			// 		this.phongBanDangChon = "0";
	
			// 	} catch (error) {
			// 		console.error('Error fetching assets:', error);
			// 	}
			// },
	
			async getDanhSachPhongBan() {
				try {
					const response = await axios.post("TS_PhongBan_Select_ByCoSo_UserID", {
						MaCoSo: this.selectedCoSo,
					});
					this.dsPhongBan = response.data.data || [];
					this.dsPhongBan.unshift({ "PhongBanID": "0", "TenPhongBan": "Tất cả" });
					this.phongBanDangChon = "0";
	
				} catch (error) {
					console.error('Error fetching assets:', error);
				}
			},
	
	
	
			async getDanhSachNhanVien() {
				try {
					if (!this.phongBanDangChon) return;
					const response = await axios.post("TS_NhanVien_Select_byPhongBanID", {
						PhongBanID: this.phongBanDangChon
					});
					this.dsNhanVien = response.data.data || [];
				} catch (error) {
					showMessage({ type: "red", title: "Không thể lấy danh sách nhân viên" })
				}
			},
	
			async getDanhSachViTriPhong() {
				try {
					if (!this.phongBanDangChon) return;
					const response = await axios.post("TS_ViTriPhong_SelectByPhongBan", {
						PhongBanID: this.phongBanDangChon
					});
					this.dsViTriPhong = response.data.data || [];
				} catch (error) {
					showMessage({ type: "red", title: "Không thể lấy danh sách nhân viên" })
				}
			},
			// async getDanhSachViTriPhong() {
			// 	try {
			// 		if (!this.phongBanDangChon) return;
			// 		const response = await axios.post("ViTriPhong_SelectByCoSo_ToaNha", {
			// 			MaCoSo: this.selectedCoSo,
			// 			MaToaNha: this.selectedToaNha
			// 		});
			// 		this.dsViTriPhong = response.data.data || [];
			// 	} catch (error) {
			// 		showMessage({ type: "red", title: "Không thể lấy danh sách nhân viên" })
			// 	}
			// },
	
			async xacNhanTaiSan() {
				try {
					const confirmed = await this.$refs.confirm.open(
						{
							title: 'Xác nhận',
							message: 'Bạn có muốn xác nhận tài sản?',
							okText: 'Xác nhận',
							cancelText: 'Hủy',
							okColor: 'primary',
							cancelColor: 'blue-grey'
						}
					);
					if (!confirmed) return;
					await axios.post("TS_DonVi_XacNhanTaiSan", {
						DanhSachMaCaBiet: this.selected.toString()
					})
						.then(() => {
							CALL({ "MESS": "Xác nhận thành công" })
						})
						.catch((error) => {
							showMessage({ type: "red", title: error.response.data.Message })
						})
	
					this.getThongKe();
					this.getDanhSachTaiSan();
				} catch (error) {
					showMessage({ type: "red", title: "Lỗi xác nhận tài sản" })
				}
			},
	
			async insertTaiSanDungChung() {
				try {
	
					await axios.post("TS_TaiSanDungChung_Insert", {
						DanhSachMaCaBiet: this.selected.toString(),
						NguoiQuanLy: this.nguoiQuanLyTaiSan
					})
						.then(() => {
							CALL({ "MESS": "Cập nhật thành công" })
						})
						.catch((error) => {
							showMessage({ type: "red", title: error.response.data.Message })
						})
					this.showTaoTaiSanDungChung = false;
					this.getThongKe();
					this.getDanhSachTaiSan();
					this.nguoiQuanLyTaiSan = null;
				} catch (error) {
					console.log(error);
					showMessage({ type: "red", title: "Lỗi cập nhật tài sản" })
				}
			},
	
	
			async chuyenTaiSanChoCaNhan() {
				try {
	
					await axios.post("TS_DonVi_CapTaiSanChoCaNhan", {
						DanhSachMaCaBiet: this.selected.toString(),
						MaNhanVien: this.maNhanVien,
						// MaViTriPhong: this.maViTriPhong
					})
						.then(() => {
							CALL({ "MESS": "Luân chuyển thành công" })
						})
						.catch((error) => {
							showMessage({ type: "red", title: error.response.data.Message })
						})
	
					this.getThongKe();
					this.getDanhSachTaiSan();
					this.showChuyenTaiSan = false;
				} catch (error) {
					showMessage({ type: "red", title: "Lỗi chuyển tài sản" })
				}
			},
	
			async traTaiSan() {
				try {
					const confirmed = await this.$refs.confirm.open(
						{
							title: 'Xác nhận',
							message: 'Bạn có muốn trả tài sản?',
							okText: 'Trả tài sản',
							cancelText: 'Hủy',
							okColor: 'primary',
							cancelColor: 'blue-grey'
						}
					);
					if (!confirmed) return;
					await axios.post("TS_DonVi_TraVeKho", {
						DanhSachMaCaBiet: this.selected.toString(),
						TinhTrang: this.tinhTrangTaiSan == -1 ? 5 : 3
					})
						.then(() => {
							CALL({ "MESS": "Cập nhật thành công" })
						})
						.catch((error) => {
							showMessage({ type: "red", title: error.response.data.Message })
						})
	
					this.getThongKe();
					this.getDanhSachTaiSan();
					this.showChuyenTaiSan = false;
				} catch (error) {
					showMessage({ type: "red", title: "Lỗi trả tài sản" })
				}
			},
	
			async yeuCauThanhLy() {
				try {
					const confirmed = await this.$refs.confirm.open(
						{
							title: 'Xác nhận',
							message: 'Bạn có muốn yêu cầu thanh lý tài sản này?',
							okText: 'Thanh lý',
							cancelText: 'Hủy',
							okColor: 'red',
							cancelColor: 'blue-grey'
						}
					);
					if (!confirmed) return;
					await axios.post("TS_DonVi_YeuCauThanhLy", {
						DanhSachMaCaBiet: this.selected.toString()
					})
						.then(() => {
							CALL({ "MESS": "Cập nhật thành công" })
						})
						.catch((error) => {
							showMessage({ type: "red", title: error.response.data.Message })
						})
	
	
					this.getThongKe();
					this.getDanhSachTaiSan();
					this.showChuyenTaiSan = false;
				} catch (error) {
					showMessage({ type: "red", title: "Lỗi yêu cầu thanh lý tài sản" })
				}
			},
	
			updateGroupSelection() {
				const newGroupSelection = {};
				Object.keys(this.groupedItems).forEach(group => {
					const groupItems = this.groupedItems[group];
					const allSelected = groupItems.every(item =>
						this.selected.includes(item.MaCaBiet)
					);
					newGroupSelection[group] = allSelected;
				});
				this.groupSelection = newGroupSelection;
			},
			toggleGroupSelection(group) {
				const groupItems = this.groupedItems[group.value];
				const allSelected = groupItems.every(item =>
					this.selected.includes(item.MaCaBiet)
				);
	
				if (allSelected) {
					// Remove all items from this group
					this.selected = this.selected.filter(item =>
						!groupItems.some(groupItem => groupItem.MaCaBiet === item)
					);
				} else {
					// Add all items from this group
					const groupItemIds = groupItems.map(item => item.MaCaBiet);
					this.selected = [...new Set([...this.selected, ...groupItemIds])];
				}
			},
	
	
			async getAllNguoiMuon() {
				this.dsNguoiMuon = await axios.post("TS_Select_NhanVien_AllPhongBan")
					.then((responsed) => {
						return responsed.data.data
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
			},
	
			async getTaiSanChoMuon() {
				this.dsTaiSanChoMuon = await axios.post("TS_TaiSan_TaiSanDungChung_Select")
					.then((responsed) => {
						return responsed.data.data
					})
					.catch((error) => {
						showMessage({ type: "red", title: error.response.data.Message })
					})
			},
	
			async choMuonTaiSan() {
				try {
	
					await axios.post("TS_ChiTietMuon_Insert", {
						DanhSachMaCaBiet: this.selected.toString(),
						NguoiMuon: this.nguoiMuon,
						NgayMuon: this.ngayMuon,
						HanTra: this.hanTra
					})
						.then(() => {
							CALL({ "MESS": "Cập nhật thành công" })
						})
						.catch((error) => {
							showMessage({ type: "red", title: error.response.data.Message })
						})
	
					this.getThongKe();
					this.getDanhSachTaiSan();
					this.showDialogMuonTaiSan = false;
				} catch (error) {
					showMessage({ type: "red", title: "Lỗi cho mượn tài sản" })
				}
			},
	
	
		}
	}
</script>