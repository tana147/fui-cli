<template>
	<v-dialog v-model="isShowDialogDongBoMulti" max-width="550px" persistent>
		<v-card>
			<v-card-title style="padding: 12px 12px 0px 12px">
				<v-toolbar-title>
					Thực hiện đồng bộ nhiều cửa hàng
				</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-btn icon @click="closeDialog">
					<v-icon>mdi-close</v-icon>
				</v-btn>
			</v-card-title>
			<v-card-text>
				<v-row>
					<v-col cols="auto">
						<f-date label="Ngày đồng bộ" outlined dense v-model="NgayDoiSoat" :date-add="0" hide-details />
					</v-col>
					<v-col cols="auto">
						<v-btn color="primary" elevation="0" @click="toggleChonTatCa">
							<v-icon left>mdi-checkbox-multiple-marked</v-icon>
							{{titleButton}}
						</v-btn>
					</v-col>
				</v-row>
				<v-select class="mt-2" label="Ca làm việc" outlined dense v-model="CaLamViec" :items="DsCaLamViec"
					hide-details item-value="value" item-text="text">
				</v-select>
				<p class="font-weight-bold primary--text ma-0 pt-3">
					Cửa hàng áp dụng ({{CuaHang_Selected.length}} cửa hàng)
				</p>
				<v-treeview v-model="CuaHang_Selected" selectable :items="DSCuaHang_Tree" selected-color="primary"
					hoverable="true" dense></v-treeview>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn color="primary" text @click="onSubmit">
					Đồng bộ
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: {
			isShowDialogDongBoMulti: Boolean
		},
		data() {
			return {
				vueData,
				NgayDoiSoat: null,
				CuaHang_Selected: [],
				DSCuaHang_Tree: [],
				isChonTatCa: false,
				DsCaLamViec: [
					{
						text: 'Tất cả', value: '0'
					},
					{
						text: 'Sáng', value: '1'
					},
					{
						text: 'Tối', value: '2'
					},
					{
						text: 'Đêm', value: '3'
					},
				],
				CaLamViec: null,
			}
		},
		mounted() {
			const now = moment();
			this.NgayDoiSoat = now.subtract(1, "days").format("YYYY-MM-DD")
			this.getStore()
		},
		computed: {
			titleButton() {
				return this.isChonTatCa === true ? 'Bỏ chọn tất cả cửa hàng' : 'Chọn tất cả cửa hàng'
			},
			DSCuaHang_TreeLength() {
				let res = 0
				this.DSCuaHang_Tree.forEach((item) => {
					res += item.children.length
				})
				return res
			}
		},
		watch: {
			CuaHang_Selected: function (val) {
				this.isChonTatCa = this.CuaHang_Selected.length === this.DSCuaHang_TreeLength
			}
		},
		methods: {
			closeDialog() {
				this.CuaHang_Selected = []
				this.CaLamViec = null
				this.$emit('update:isShowDialogDongBoMulti', false)
			},
			getStore() {
				const $this = this
				ajaxCALL("/eorder/CuaHang_Select_Tree", {}, (res) => {
					$this.DSCuaHang_Tree = convertJsonToTree(res.data)
				})
			},
	
			selectAll() {
				let res = []
				this.DSCuaHang_Tree.forEach((item) => {
					item.children.forEach((CuaHang) => res.push(CuaHang.id))
				})
				this.CuaHang_Selected = res
			},
	
			unselectAll() {
				this.CuaHang_Selected = []
			},
	
			toggleChonTatCa() {
				this.isChonTatCa = !this.isChonTatCa
				return this.isChonTatCa ? this.selectAll() : this.unselectAll()
			},
	
			async onSubmit() {
				console.log(this.CaLamViec)
				if (this.CuaHang_Selected.length === 0) {
					Vue.$toast.warning("Vui lòng chọn ít nhất 1 cửa hàng", { position: "top" });
					return
				}
				if (this.CaLamViec === null) {
					Vue.$toast.warning("Vui lòng chọn ca làm việc", { position: "top" });
					return
				}
	
				const CuaHangApDungID = this.CuaHang_Selected ? this.CuaHang_Selected.join(",") : ""
				const data = await this.vueData.ajaxCALLPromise('/eorder/DoiSoatDoanhThu_DongBo_Multi', {
					CuaHangApDungID: this.CuaHang_Selected ? this.CuaHang_Selected.join(",") : "",
					NgayDongBo: this.NgayDoiSoat,
					CaLamViec: this.CaLamViec
				})
				if (data) {
					Vue.$toast.success("Thành công", { position: "top" });
					this.closeDialog()
				} else
					Vue.$toast.error("Thất bại", { position: "top" });
	
			}
		},
	}
</script>