<template>
	<v-dialog :fullscreen="true" v-model="dialogLichSu">

		<v-toolbar>
			<v-toolbar-title class="text-primary">Lịch sử báo sửa</v-toolbar-title>
			<v-btn icon="mdi-close" @click="dialogLichSu = false"></v-btn>
		</v-toolbar>
		<template v-slot:activator="{ props: activatorProps }">
			<div @click="async () => { await getBaoSuaByNguoiBaoSua(); }" v-bind="activatorProps"
				style=" cursor: pointer;">
				<v-btn color="grey-darken-3" prepend-icon="mdi-history" variant="tonal" :class="classForBtn">Lịch
					sử</v-btn>
			</div>
		</template>

		<v-card color="basil" style="border-radius: 0px; background-color:#F3F4F6;">

			<v-card-text class="px-2 pt-2" v-if="$vuetify.display.smAndDown">
				<v-row>
					<v-col>
						<v-text-field class="mb-2" style="background-color:white;" color="primary"
							prepend-inner-icon="mdi-magnify" v-model="timKiem" label="Tìm kiếm">
						</v-text-field>

					</v-col>
					<v-col cols="4" class="pl-0">
						<!-- <v-menu>
							<template v-slot:activator="{ props }">
								<v-btn color="primary" v-bind="props">
									{{tenTinhTrang}}
								</v-btn>
							</template>

							<v-list>
								<v-list-item v-for="(item, index) in dsTinhTrang" v-model="tinhTrangChon" :key="index" :value="index">
									<v-list-item-title>{{ item.ten }}</v-list-item-title>
								</v-list-item>
							</v-list>
						</v-menu> -->
						<v-select style="background-color:white;" flat v-model="tinhTrangChon" :items="dsTinhTrang"
							item-value="id" item-title="ten"></v-select>
					</v-col>
				</v-row>
				<v-skeleton-loader v-if="isLoadingLichSu" type="card, avatar">
				</v-skeleton-loader>
				<uc-thongtin-baosua v-for="(item, index) in dsLichSuMobile" :key="index" :item="item"
					@update="getBaoSuaByNguoiBaoSua" />
			</v-card-text>


			<v-card-text v-else>
				<v-toolbar density="default" color="white">
					<v-spacer></v-spacer>
					<v-sheet max-width="100%">
						<v-select label="Lọc tình trạng" color="primary" v-model="tinhTrangChon" :items="dsTinhTrang"
							item-value="id" item-title="ten"></v-select>
						<!-- <v-item-group v-model="tinhTrangChon" mandatory selected-class="bg-primary text--white"
							class="mr-2">
							<v-item v-for="(item,index) in dsTinhTrang" :key="item.id" :value="item.id"
								v-slot="{ isSelected, selectedClass, toggle }">
								<v-btn size="small" :prepend-icon="isSelected ? 'mdi-check' : '' "
									:class="selectedClass" @click="toggle" variant="tonal" class="rounded-pill ml-2">
									{{item.ten}}
								</v-btn>
							</v-item>
						</v-item-group> -->
					</v-sheet>
					<v-text-field style="max-width: 245px" class="mx-2" color="primary" prepend-inner-icon="mdi-magnify"
						v-model="timKiem" label="Tìm kiếm"></v-text-field>
				</v-toolbar>
				<v-divider></v-divider>
				<v-data-table-virtual :search="timKiem" :headers="headers" :items="dsLichSuLoc" item-value="STT"
					hide-default-footer height="400" density="compact" fixed-header>
					<template v-slot:item.STT="{ item, index }">
						<span>{{+ + index }}</span>
					</template>
					<template v-slot:item.TinhTrang="{ item }">
						<v-chip :color="statusToColor(item.MaTinhTrang)">
							{{ item.TenTinhTrang }}</v-chip>
					</template>

					<template v-slot:item.TGBaoSua="{ item }">
						{{ formatTime(item.TGBaoSua) }}
					</template>
					<template v-slot:item.CapNhat="{ item }">
						<div v-if="item.MaTinhTrang < 2" class="d-flex">
							<v-btn color="primary" variant="text" size="x-small" icon="mdi-pencil"
								@click="editBaoSua(item)"></v-btn>
							<v-btn variant="text" color="red" size="x-small" @click="deleteBaoSua(item)"
								icon="mdi-delete"></v-btn>
						</div>
					</template>
				</v-data-table-virtual>
				<v-dialog width="400" v-model="isOpenEditBaoSua">
					<v-toolbar>
						<v-toolbar-title>Cập nhật</v-toolbar-title>
						<v-btn icon="mdi-close" @click="() => { hinhAnh = []; isOpenEditBaoSua = false; }"></v-btn>
					</v-toolbar>
					<v-card flat>
						<v-card-text>
							<v-form ref="form1">
								<v-text-field inputmode="numeric" style="background-color:white;" color="primary"
									type="number" v-model="maVach" :clearable="false" class="mb-3"
									label="Mã tài sản (nếu có)" autofocus></v-text-field>

								<v-select v-model="coSo" :items="dsCoSo" item-value="MaCoSo" item-title="TenCoSo"
									style="background-color:white;" color="primary" class="mb-3" density="compact"
									:clearable="false" label="Cơ sở" :loading="isLoadingCoSo">
								</v-select>

								<v-autocomplete v-model="viTriPhong" :items="dsViTriPhong" item-value="MaViTriPhong"
									item-title="TenViTriPhong" style="background-color:white;" color="primary"
									class="mb-3" return-object density="compact" :clearable="false" label="Phòng">
								</v-autocomplete>

								<v-autocomplete style="background-color:white;" color="primary" class="mb-3"
									return-object v-model="loaiDanhMuc" :items="dsLoaiDanhMuc" density="compact"
									item-value="MaLoai" item-title="TenLoai" :clearable="false" label="Loại danh mục">
								</v-autocomplete>

								<v-autocomplete :items="dsTaiSan" item-value="MaCaBiet" item-title="TenTaiSan"
									style="background-color:white;" color="primary" class="mb-3" return-object
									density="compact" :clearable="false" label="Thiết bị" v-model="taiSan">
								</v-autocomplete>
							</v-form>

							<uc-image :loading="isLoadingImage" v-model="hinhAnh" max-images="1" classs="py-3">
							</uc-image>

							<v-textarea v-model="ghiChu" color="primary" label="Mô tả lỗi" outlined dense classs="mb-10"
								:style="{ background: '#fff', borderRadius: '4px' }"></v-textarea>
						</v-card-text>
						<v-card-actions>
							<v-btn variant="flat" @click='updateBaoSua' color="primary">Cập nhật</v-btn>
						</v-card-actions>
					</v-card>
				</v-dialog>
			</v-card-text>
		</v-card>
	</v-dialog>
	<uc-confirm ref="confirm"></uc-confirm>
</template>

<script>
export default {
	props: {
		classForBtn: {
			type: String
		}
	},
	data() {
		return {
			dialogLichSu: false,
			dsLichSu: [],
			hinhAnh: [],
			timKiem: '',
			isLoadingImage: false,
			isOpenEditBaoSua: false,
			isLoadingLichSu: false,
			tinhTrangChon: -1,
			isLoadingCoSo: false,
			isLoadingViTri: false,
			isLoadingLoai: false,
			isLoadingTaiSan: false,

			ghiChu: '',
			maVach: null,
			coSo: null,
			viTriPhong: {},
			loaiDanhMuc: {},
			taiSan: {},
			// image:[]

			dsLoaiDanhMuc: [],
			dsCoSo: [],
			dsViTriPhong: [],
			dsTaiSan: [],
			maBaoSua: null,
			headers: [
				{
					title: 'STT',
					align: 'start',
					sortable: true,
					key: 'STT',
				},
				{ title: 'Phòng', key: 'TenViTriPhong', nowrap: true },
				{ title: 'Tên tài sản', key: 'TenTaiSan' },
				{ title: 'Tình trạng', key: 'TinhTrang' },
				{ title: 'Ghi chú', key: 'GhiChu' },
				{ title: 'Thời gian gửi', key: 'TGBaoSua' },
				{ title: 'Cập nhật', key: 'CapNhat' },

			],
			dsTinhTrang: [
				{ id: -1, ten: 'Tất cả' },
				{ id: 0, ten: 'Báo sửa mới' },
				{ id: 1, ten: 'Đã tiếp nhận' },
				{ id: 2, ten: 'Đang kiểm tra' },
				{ id: 6, ten: 'Báo sửa sai' },
				{ id: 3, ten: 'Đang sửa chữa' },
				{ id: 4, ten: 'Đã sửa xong' },
				{ id: 5, ten: 'Không sửa được' }
			]
		}
	},
	async mounted() {
		// await this.getBaoSuaByNguoiBaoSua();
	},
	computed: {
		tenTinhTrang() {
			const item = this.dsTinhTrang.find(i => i.id === this.tinhTrangChon);
			return item ? item.ten : '';
		},
		getTenCoSo() {
			const tenCoSo = this.dsCoSo.find(coSo => coSo.MaCoSo == this.coSo);
			return tenCoSo ? tenCoSo.TenCoSo : 'Cơ sở không tồn tại';
		},
		dsLichSuLoc() {
			if (this.tinhTrangChon == -1) {
				return this.dsLichSu;
			}
			const ketQuaLoc = this.dsLichSu.filter(item => {
				return item.MaTinhTrang == this.tinhTrangChon;
			});
			return ketQuaLoc;
		},
		dsLichSuMobile() {
			if (this.timKiem == '') return this.dsLichSuLoc
			return this.dsLichSuLoc.filter(item =>
				Object.values(item).some(val =>
					String(val).toLowerCase().includes(this.timKiem.toLowerCase())
				)
			)
		}
	},
	watch: {
		tinhTrangChon(newVal, oldVal) {
			console.log(newVal)
		},
		// hinhAnh(newVal, oldVal) {
		// 	console.error(newVal)
		// }
	},
	methods: {
		formatTime: window.formatTime,

		async updateBaoSua() {
			try {
				// this.isLoadingUpdate = true;
				const res = await axios.post("BaoSua_Update_New", {
					MaBaoSua: this.maBaoSua.MaBaoSua,
					MaCaBiet: this.taiSan.MaCaBiet,
					MoTa: this.ghiChu,
					HinhAnh: this.hinhAnh[0]
				})
				this.isOpenEditBaoSua = false;
				this.hinhAnh = [];

			} catch (err) {
				showMessage({ type: "red", title: err })
				// this.isLoadingUpdate = true;
			}
		},
		editBaoSua(item) {
			if (item.KiemTraHinhAnh == 1) { this.getHinhAnh(item.MaBaoSua); }
			this.maBaoSua = item;
			this.coSo = item;
			this.getDSCoSo();
			this.maVach = item.MaVach;
			this.viTriPhong = item;
			this.loaiDanhMuc = item;
			this.taiSan = item;
			this.ghiChu = item.GhiChu
			console.log(item);
			this.isOpenEditBaoSua = true;
		},
		statusToColor(id) {
			switch (id) {
				case 0:
					return 'error';
					break;
				case 1:
					return 'light-green';
					break;
				case 2:
					return 'orange';
					break;
				case 3:
					return 'green';
					break;
				case 4:
					return 'light-blue-accent-3';
					break;

				default:
					return 'green';
					break;
			}
		},
		async getBaoSuaByNguoiBaoSua() {
			this.isLoadingLichSu = true;
			try {
				const res = await axios.post("/BaoSua_SelectByNguoiBaoSua", {});
				this.dsLichSu = res.data.data;
				this.dialogLichSu = true;

			} catch (err) {
				console.error("Lỗi khi lấy lịch sử báo sửa:", err);
			}
			this.isLoadingLichSu = false;
		},

		async getHinhAnh(maBaoSua) {
			try {
				this.isLoadingImage = true;
				const res = await axios.post("/obj/BaoSua_SelectHinhAnh", {
					MaBaoSua: maBaoSua
				})
				// console.error(res.data.data.HinhAnh)
				const data = res.data.data.HinhAnh;
				this.hinhAnh = [...this.hinhAnh, data];
				// this.hinhAnh.push(data);
				console.error(this.hinhAnh)
				this.isLoadingImage = false;
			}
			catch (err) {
				this.isLoadingImage = false;
				console.error(err)
			}
		},

		// async getDSCoSo() {
		// 	console.log("Hàm cơ sở");
		// 	this.isLoadingCoSo = true;
		// 	this.dsCoSo = await axios.post("/CoSo_Select")
		// 		.then((res) => {
		// 			console.log("API cơ sở");
		// 			if (typeof this.maCoSo !== 'undefined') {
		// 				this.coSo = parseInt(this.maCoSo);
		// 			}
		// 			return res.data.data;
		// 		})
		// 		.catch((err) => { console.error(err) })
		// 	this.isLoadingCoSo = false;
		// },
		async getDSCoSo() {
			this.isLoadingCoSo = true;
			this.dsCoSo = await axios.post("/CoSo_Select")
				.then((res) => {
					return res.data.data;
				})
				.catch((err) => { console.error(err) })
			this.isLoadingCoSo = false;
		},
		async deleteBaoSua(item) {
			try {
				const confirmed = await this.$refs.confirm.open(
					{
						title: 'Xác nhận',
						message: 'Bạn có muốn xoá không?',
						okText: 'Xoá',
						cancelText: 'Hủy',
						okColor: 'red',
						cancelColor: 'blue-grey'
					}
				);
				if (!confirmed) return;
				const res = await axios.post("BaoSua_Delete", {
					MaBaoSua: item.MaBaoSua
				})
				CALL(webSocket_Send({
					group: "BaoSua",
					data: {
						ThongBao: 123,
					}
				}));
				this.$emit('update');
				await this.getBaoSuaByNguoiBaoSua();
				CALL({ "MESS": "Xoá thành công" })
			} catch (err) {
				showMessage({ type: "red", title: err.response.data.Message })
			}
		}
	}
}
</script>