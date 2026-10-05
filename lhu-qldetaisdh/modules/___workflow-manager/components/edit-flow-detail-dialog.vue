<template>
	<div>
		<v-dialog v-model="vueData.isEditDialog" transition="dialog-bottom-transition" max-width="900px" persistent>
			<v-card>
				<c-toolbar @onClose="vueData.isEditDialog = false">
					<template v-slot:title>
						<p class="title mb-0 primary--text">Cập nhật task detail</p>
					</template>
				</c-toolbar>
				<v-card-text>
					<v-row>
						<v-col cols="12">
							<v-text-field v-model="itemDetail.Task_Detail_Description" label="Tên task detail" outlined
								dense hide-details color="primary" />
						</v-col>
						<v-col cols="12">
							<v-text-field v-model="itemDetail.Data_Exp" label="VD nhập mẫu" outlined dense hide-details
								color="primary" />
						</v-col>
						<v-col cols="12">
							<v-text-field v-model="itemDetail.Task_Help" label="Lưu ý nhập task detail" outlined dense
								hide-details color="primary" />
						</v-col>
						<v-col cols="12">
							<v-text-field v-model="itemDetail.FieldName" label="Field name" outlined dense hide-details
								color="primary" />
						</v-col>
						<v-col cols="3">
							<v-autocomplete v-model="itemDetail.Task_Detail_Type" label="Loại trường nhập"
								:items="detailType" item-text="name" item-value="name" outlined dense hide-details
								color="primary" placeholder="Chọn loại hàm kiểm tra (có thể rỗng)" />
						</v-col>
						<v-col cols="5"
							v-if="itemDetail.Task_Detail_Type === 'FILE' || itemDetail.Task_Detail_Type === 'FILEVIEW'">
							<v-text-field v-model="itemDetail.AllowFileType" label="Loại file nộp" outlined dense
								hint="Vd: pdf,docx,png,jpeg,..."
								placeholder="Loại file nộp chỉ định (để rỗng là tất cả)" color="primary" />
						</v-col>
						<v-col cols="4">
							<v-autocomplete v-model="itemDetail.FN_Check" label="Loại hàm kiểm tra" :items="fnCheck"
								item-text="name" item-value="name" outlined dense hide-details color="primary"
								placeholder="Chọn loại trường nhập" />
						</v-col>
					</v-row>
					<v-row>
						<v-col class="pt-0 mt-1" cols="5">
							<div class="d-flex align-center roleHeight">
								<p>Cho phép bỏ trống:</p>
								<v-radio-group class="mb-3 ml-3 wrapRadioGroup" v-model="itemDetail.AllowNull" row>
									<v-radio label="Có" value="1" color="primary" />
									<v-radio label="Không" value="0" color="primary" />
								</v-radio-group>
							</div>
						</v-col>
						<v-col class="pt-0 mt-1">
							<div class="d-flex align-center roleHeight">
								<p>Task này dành cho:</p>
								<v-radio-group class="mb-3 ml-3 wrapRadioGroup" v-model="itemDetail.User_Input" row>
									<v-radio label="HV" value="HV" color="primary" />
									<v-radio label="SDH" value="SDH" color="primary" />
								</v-radio-group>
							</div>
						</v-col>
					</v-row>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn @click="onSave" color="success">Cập nhật</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: ["itemdetail", "fncheck", "detailtype"],
		data() {
			return {
	
			}
		},
		mounted() { },
		computed: {
			itemDetail: function () {
				return this.itemdetail
			},
			fnCheck: function () {
				return this.fncheck
			},
			detailType: function () {
				return this.detailtype
			},
	
		},
		watch: {},
		methods: {
			onSave() {
				console.log("itemDetail", this.itemDetail)
			}
		},
	}
</script>