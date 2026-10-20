<template>
	<div>
		<v-dialog v-model="vueData.isAddFlowDialog" transition="dialog-bottom-transition" max-width="900px" persistent>
			<v-card>
				<c-toolbar @onClose="vueData.isAddFlowDialog = false">
					<template v-slot:title>
						<p class="title mb-0 primary--text">Tạo task detail mới</p>
					</template>
				</c-toolbar>
				<v-card-text>
					<div class="d-flex justify-center align-center">
						<v-btn @click="addTaskDetail" color="primary" text>
							<v-icon>mdi-plus-circle-outline</v-icon> Thêm task detail mới
						</v-btn>
					</div>
					<div v-for="(item, index) in taskDetailArr" :key="index" v-if="taskDetailArr.length > 0">
						<div class="mb-3 d-flex align-center">
							<h4 class="justify-start">Task {{index + 1}}</h4>
							<div class="ml-auto">
								<v-btn @click="swapItemUp(index)" v-if="index > 0" text x-small fab icon>
									<v-icon>mdi-menu-up</v-icon>
								</v-btn>
								<v-btn @click="swapItemDown(index)" v-if="index < taskDetailArr.length - 1" text x-small
									fab icon>
									<v-icon>mdi-menu-down</v-icon>
								</v-btn>
								<v-btn @click="deleteTask(index)" x-small fab icon>
									<v-icon color="red">mdi-trash-can-outline</v-icon>
								</v-btn>
							</div>
						</div>

						<v-row>
							<v-col cols="12">
								<v-text-field v-model="item.Task_Detail_Description" label="Tên task detail" outlined
									dense hide-details color="primary" />
							</v-col>
							<v-col cols="12">
								<v-text-field v-model="item.Data_Exp" label="VD nhập mẫu" outlined dense hide-details
									color="primary" />
							</v-col>
							<v-col cols="12">
								<v-text-field v-model="item.Task_Help" label="Lưu ý nhập task detail" outlined dense
									hide-details color="primary" />
							</v-col>
							<v-col cols="12">
								<v-text-field v-model="item.FieldName" label="Field name" outlined dense hide-details
									color="primary" />
							</v-col>
							<v-col cols="3">
								<v-autocomplete v-model="item.Task_Detail_Type" label="Loại trường nhập"
									:items="detailType" item-text="name" item-value="name" outlined dense hide-details
									color="primary" />
							</v-col>
							<v-col cols="5"
								v-if="item.Task_Detail_Type !== null && (item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW')">
								<v-text-field v-model="item.AllowFileType" label="Loại file nộp" outlined dense
									hint="Vd: pdf,docx,png,jpeg,..."
									placeholder="Loại file nộp chỉ định (để rỗng là tất cả)" color="primary" />
							</v-col>
							<v-col cols="4">
								<v-autocomplete v-model="item.FN_Check" label="Loại hàm kiểm tra" :items="fnCheck"
									item-text="name" item-value="name" outlined dense hide-details color="primary"
									placeholder="Chọn loại trường nhập" />
							</v-col>

						</v-row>
						<v-row>
							<v-col class="pt-0 mt-1" cols="5">
								<div class=" d-flex align-center roleHeight">
									<p>Cho phép bỏ trống:</p>
									<v-radio-group v-model="item.AllowNull" class="mb-3 ml-3 wrapRadioGroup" row>
										<v-radio label="Có" value="1" color="primary" />
										<v-radio label="Không" value="0" color="primary" />
									</v-radio-group>
								</div>
							</v-col>
							<v-col class="pt-0 mt-1">
								<div class="d-flex align-center roleHeight">
									<p>Task này dành cho:</p>
									<v-radio-group v-model="item.User_Input" class="mb-3 ml-3 wrapRadioGroup" row>
										<v-radio label="HV" value="HV" color="primary" />
										<v-radio label="SDH" value="SDH" color="primary" />
									</v-radio-group>
								</div>
							</v-col>
						</v-row>
						<hr class="mb-3" v-if="index < taskDetailArr.length - 1" />
					</div>

				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn @click="onSave" color="success">Tạo</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: ["detailtype", "fncheck"],
		data() {
			return {
				taskDetailArr: [
					{
						Task_Detail_Description: null,
						Data_Exp: null,
						Task_Help: null,
						FieldName: null,
						Task_Detail_Type: null,
						AllowFileType: null,
						FN_Check: null,
						AllowNull: null,
						User_Input: null,
					}
				],
	
			}
		},
		mounted() { },
		computed: {
			fnCheck: function () {
				return this.fncheck
			},
			detailType: function () {
				return this.detailtype
			}
		},
		watch: {
			"vueData.isAddFlowDialog": function (val) {
				console.log("val", val)
			}
		},
		methods: {
			addTaskDetail() {
				const newTaskDetail = {
					Task_Detail_Description: null,
					Data_Exp: null,
					Task_Help: null,
					FieldName: null,
					Task_Detail_Type: null,
					AllowFileType: null,
					FN_Check: null,
					AllowNull: null,
					User_Input: null,
				};
	
				this.taskDetailArr.push(newTaskDetail)
			},
			deleteTask(index) {
				if (index > -1) {
					this.taskDetailArr.splice(index, 1)
				}
			},
			swapItemUp(index) {
				if (index > 0) {
					const temp = this.taskDetailArr[index];
					this.$set(this.taskDetailArr, index, this.taskDetailArr[index - 1]);
					this.$set(this.taskDetailArr, index - 1, temp);
					console.log("this.taskDetailArr", this.taskDetailArr);
				}
			},
			swapItemDown(index) {
				if (index < this.taskDetailArr.length - 1) {
					const temp = this.taskDetailArr[index];
					this.$set(this.taskDetailArr, index, this.taskDetailArr[index + 1]);
					this.$set(this.taskDetailArr, index + 1, temp);
					console.log("this.taskDetailArr", this.taskDetailArr);
				}
			},
			onSave() {
				console.log("this.taskDetailArr", this.taskDetailArr)
			}
		},
	}
</script>