<template>
	<v-dialog v-model="isShowDialogMapping" max-width="800px" persistent>
		<v-card>
			<v-card-title style="padding: 12px 12px 0px 12px">
				<span class="primary--text">
					Liên kết hoá đơn
				</span>
				<v-spacer></v-spacer>
				<v-icon color="primary" @click="closeDialog">
					mdi-close
				</v-icon>
			</v-card-title>
			<v-card-text class="d-flex flex-column">
				<v-form ref="form">
					<v-row>
						<v-col cols="7">
							<v-select label=" Cửa hàng" outlined dense v-model="CuaHangID" :items="vueData.DSCuaHang"
								:rules="[rules.required]" hide-details item-value="CuaHangID" item-text="TenCuaHang">
							</v-select>
						</v-col>
						<v-col cols="3">
							<f-date label="Ngày" outlined dense v-model="Ngay" :date-add="0" hide-details />
						</v-col>
						<v-col cols="2">
							<v-btn color="primary" elevation="0" @click="onSearch">
								<v-icon left>mdi-filter</v-icon>Tìm
							</v-btn>
						</v-col>
					</v-row>
				</v-form>
				<v-data-table class="table-log" fixed-header :headers="headers" :items="dataTable" :search='search'
					height='300px' dense items-per-page="-1" hide-default-footer="true">
					<template v-slot:top>
						<div class="d-flex align-center px-3 py-3 ">
							<div class="title-text">
								Danh sách hóa đơn
								<span class="count">({{ dataTable.length }})</span>
							</div>

							<v-spacer></v-spacer>
							<v-text-field v-model="search" prepend-inner-icon="mdi-magnify" dense elevation="0"
								hide-details style="max-width: 200px" />
						</div>
					</template>

					<template v-slot:item.KhachTra_CK="{ item }">
						{{item.KhachTra_CK?.toLocaleString('vi-VN')}}
					</template>

					<template v-slot:item.NgayThemMoi="{ item }">
						{{ moment(
						item.NgayThemMoi.split('T')[0] + ' ' + item.GioThemMoi.split('.')[0],
						'YYYY-MM-DD HH:mm:ss'
						).format('DD/MM/YYYY HH:mm:ss') }}
					</template>

					<template v-slot:item.actions="{ item }">
						<v-btn text class="pa-0" color="success" @click='onClickHoaDon(item)'>
							Liên kết
						</v-btn>
					</template>
				</v-data-table>
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			item: Object,
			isShowDialogMapping: Boolean
		},
		data() {
			return {
				vueData,
				rules: {
					required: v => !!v || 'Không được để trống'
				},
				headers: [
					{
						text: 'Mã hoá đơn',
						align: 'start',
						value: 'MaHoaDon',
					},
					{
						text: 'Tiền phải trả',
						align: 'end',
						value: 'KhachTra_CK',
					},
					{
						text: 'Thời gian',
						align: 'center',
						value: 'NgayThemMoi',
					},
					{
						text: '',
						align: 'center',
						value: 'actions',
						filterable: false
					}
				],
				CuaHangID: null,
				Ngay: null,
				search: null,
				dataTable: []
			};
		},
		computed: {
	
		},
	
		methods: {
			closeDialog() {
				this.$emit('update:isShowDialogMapping', false)
				this.dataTable = []
				this.CuaHangID = null
				// this.Ngay = null
				this.$refs.form.resetValidation()
			},
	
			async onSearch() {
				if (this.$refs.form.validate()) {
					const params = {
						CuaHangID: this.CuaHangID,
						Ngay: this.Ngay
					}
					const data = await this.vueData.ajaxCALLPromise('/eorder/HoaDon_Bank_Select_HoaDon_ByCuaHangID', params)
					this.dataTable = data
				}
			},
			async onClickHoaDon(item) {
				const params = {
					TransID: this.item.TransID,
					HoaDonID: item.HoaDonID
				}
				const data = await this.vueData.ajaxCALLPromise('/eorder/HoaDon_Bank_Update_HoaDon', params)
				if (data) {
					Vue.$toast.success("Thành công", { position: "top" });
					this.closeDialog()
				} else
					Vue.$toast.error("Thất bại", { position: "top" });
			}
	
		}
	}
</script>