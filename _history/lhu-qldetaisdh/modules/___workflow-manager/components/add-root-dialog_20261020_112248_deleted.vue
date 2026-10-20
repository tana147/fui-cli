<template>
	<div>
		<!-- add new root -->

		<v-dialog v-model="vueData.isAddRootDialog" transition="dialog-bottom-transition" max-width="900px" persistent>
			<v-card>
				<c-toolbar @onClose="vueData.isAddRootDialog = false">
					<template v-slot:title>
						<p class="title mb-0 primary--text">Tạo task mới</p>
					</template>
				</c-toolbar>
				<v-card-text>
					<div class="d-flex justify-center align-center">
						<v-btn @click="addTask" color="primary" text>
							<v-icon>mdi-plus-circle-outline</v-icon> Thêm task mới
						</v-btn>
					</div>
					<div class="mt-3" v-for="(item, index) in taskArr" :key="index" v-if="taskArr.length > 0">
						<div class="mb-3 d-flex align-center">
							<h4 class="justify-start">Task {{index + 1}}</h4>

							<div class="ml-auto">
								<v-btn @click="swapItemUp(index)" v-if="index > 0" text x-small fab icon>
									<v-icon>mdi-menu-up</v-icon>
								</v-btn>
								<v-btn @click="swapItemDown(index)" v-if="index < taskArr.length - 1" text x-small fab
									icon>
									<v-icon>mdi-menu-down</v-icon>
								</v-btn>
								<v-btn @click="deleteTask(index)" x-small fab icon>
									<v-icon color="red">mdi-trash-can-outline</v-icon>
								</v-btn>
							</div>
						</div>
						<v-row>
							<v-col cols="12">
								<v-text-field v-model="item.TaskName" label="Tên task" placeholder="Nhập tên root"
									outlined dense hide-details color="success" />
							</v-col>
							<v-col cols="12">
								<v-text-field v-model="item.TaskCode" label="Task code" placeholder="Nhập task code"
									outlined dense hide-details color="success" />
							</v-col>
							<v-col cols="12">
								<v-text-field v-model="item.TaskDescript" label="Ghi chú" outlined color="success" dense
									placeholder="Nhập ghi chú task" hide-details />
							</v-col>
						</v-row>

						<div class="mt-3 d-flex align-center roleHeight">
							<p>HV có bắt buộc phải làm bước này không:</p>
							<!-- {{taskRequire}} -->
							<v-radio-group v-model="item.Task_Require" class="mb-3 ml-3 wrapRadioGroup" row>
								<v-radio label="Có" value="1" color="success" />
								<v-radio label="Không" value="0" color="success" />
							</v-radio-group>
						</div>
						<hr class="mb-3" v-if="index < taskArr.length - 1" />
				</v-card-text>

				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn @click="onsSave" color="success">Tạo</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: ["tasklist"],
		data() {
			return {
				taskArr: [
					{
						TaskName: null,
						TaskCode: null,
						TaskDescript: null,
						Task_Require: null
					}
				],
	
				AddData: {
					Task_Name: null,
					Task_Code: null,
					Task_Require: null
				}
			}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {
			addTask() {
				const newTask = {
					TaskName: null,
					TaskCode: null,
					TaskDescript: null,
					Task_Require: null
				};
	
				this.taskArr.push(newTask)
			},
			deleteTask(index) {
				if (index > -1) {
					this.taskArr.splice(index, 1)
				}
			},
			onsSave() {
				console.log("this.taskArr", this.taskArr)
			},
	
			swapItemUp(index) {
				if (index > 0) {
					const temp = this.taskArr[index];
					this.$set(this.taskArr, index, this.taskArr[index - 1]);
					this.$set(this.taskArr, index - 1, temp);
					console.log("this.taskArr", this.taskArr);
				}
			},
			swapItemDown(index) {
				if (index < this.taskArr.length - 1) {
					const temp = this.taskArr[index];
					this.$set(this.taskArr, index, this.taskArr[index + 1]);
					this.$set(this.taskArr, index + 1, temp);
					console.log("this.taskArr", this.taskArr);
				}
			},
		},
	}
</script>