<template>
	<v-dialog v-model="vueData.IsDefineNewClassModal" transition="dialog-bottom-transition" max-width="900" persistent>
		<v-card>
			<c-toolbar @onClose="closeDialog">
				<template v-slot:title>
					<p class="title mb-0 primary--text">Định nghĩa lớp mới</p>
				</template>
			</c-toolbar>

			<v-card-text>
				<v-row>
					<v-col>
						<v-text-field v-model="selectField.lopID" outlined dense hide-details label="LopID"
							placeholder="Nhập ID lớp" />
					</v-col>
					<v-col>
						<v-select v-model="selectField.loaiThS" label="Loại thạc sĩ" outlined dense hide-details
							:items="LoaiThS" />
					</v-col>
					<v-col>
						<v-select disabled v-model="selectField.loaiThaoTac" label="Loại thao tác" outlined dense
							hide-details :items="LoaiThaoTac" />
					</v-col>
				</v-row>
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn @click="defindClass" color="success">Thêm định nghĩa</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
	    props: [],
	    data() {
	        return {
	            selectField: {
	                lopID: null,
	                loaiThS: 1,
	                loaiThaoTac: 1,
	            },
	
	            LoaiThS: [
	                // Prcess_ID
	                {
	                    text: 'Thạc sĩ nghiên cứu',
	                    value: 1,
	                },
	                {
	                    text: 'Thạc sĩ ứng dụng',
	                    value: 4,
	                },
	                {
	                    text: 'Đổi đề tài luận văn',
	                    value: 2,
	                },
	                {
	                    text: 'Gia hạn đề tài luận văn',
	                    value: 3,
	                },
	                {
	                    text: 'Đổi đề tài đồ án',
	                    value: 5,
	                },
	            ],
	            LoaiThaoTac: [
	                // Process_Action
	                {
	                    text: 'Làm Luận văn/Đồ án',
	                    value: 1,
	                },
	                {
	                    text: 'Đổi đề tài Luận văn/Đồ án',
	                    value: 2,
	                },
	                {
	                    text: 'Gia hạn đề tài luận văn',
	                    value: 3,
	                },
	            ],
	        }
	    },
	    mounted() { },
	    computed: {},
	    watch: {
	        'selectField.loaiThS': function (val) {
	            if (val == 1 || val == 4) {
	                this.selectField.loaiThaoTac = 1
	            } else if (val == 2 || val == 5) {
	                this.selectField.loaiThaoTac = 2
	            } else if (val == 3) {
	                this.selectField.loaiThaoTac = 3
	            }
	        },
	    },
	    methods: {
	        async defindClass() {
	            if (!this.selectField.lopID) {
	                Vue.$toast.error('Vui lòng nhập ID lớp', { position: 'top' })
	                return
	            }

                // Thạc sĩ nghiên cứu
	            if (this.selectField.loaiThS === 1) {
	                // Làm luận văn
	                await this.insertNewProcess(this.selectField.loaiThS, this.selectField.loaiThaoTac)
	                // Đổi/Điều chỉnh đề tài
	                await this.insertNewProcess(2, 2)
	                // Gia hạn đề tài
	                await this.insertNewProcess(3, 3)
                // Thạc sĩ ứng dụng
	            } else if (this.selectField.loaiThS === 4) {
	                // Làm đồ án
	                await this.insertNewProcess(this.selectField.loaiThS, this.selectField.loaiThaoTac)
	                // Đổi/Điều chỉnh đề tài
	                await this.insertNewProcess(5, 2)
	            } else {
	                await this.insertNewProcess(this.selectField.loaiThS, this.selectField.loaiThaoTac)
	            }
	
	            this.$emit('reload-class-process')
	        },
	
	        insertNewProcess(processId, processAction) {
	            return new Promise((resolve, reject) => {
	                ajaxCALL(
	                    '/Process_Class_Ins',
	                    {
	                        Lop_ID: this.selectField.lopID.trim(),
	                        Prcoess_ID: processId,
	                        Process_Action: processAction,
	                    },
	                    (res) => {
	                        Vue.$toast.success('Thêm định dạng lớp thành công', { position: 'top' })
	                        console.log('Add class process success', res)
	                        resolve('success')
	                    },
	                    (error) => {
	                        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
	                        console.log('Add class process fail', error)
	                        reject(error)
	                    },
	                )
	            })
	        },
	
	        closeDialog() {
	            vueData.IsDefineNewClassModal = false
	            this.selectField = {
	                lopID: null,
	                loaiThS: 1,
	                loaiThaoTac: 1,
	            }
	        },
	    },
	}
</script>