<template>
	<v-dialog v-model="vueData.isOpenReset" transition="dialog-bottom-transition" max-width="600px" persistent>
		<v-card>
			<c-toolbar @onClose="vueData.isOpenReset = false">
				<template v-slot:title>
					<div class="title primary--text text-left">Xác nhận đăng ký mới "{{vueData.StudentDetail.HoTen}}"
					</div>
				</template>
			</c-toolbar>

			<v-card-text>
				<v-text-field v-model="LyDo" label="Lý do" placeholder="Nhập lý do" outlined color="primary" dense
					hide-details />
			</v-card-text>

			<v-card-actions>
				<v-spacer></v-spacer>
				<v-btn @click='onReset' color="success">
					<v-icon left>mdi-content-save</v-icon>Xác nhận
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		props: [],
	    data() {
	        return {
	            LyDo: null,
	        }
	    },
	    mounted() { },
	    computed: {},
	    watch: {},
	    methods: {
	        async ajaxPromise(url, data) {
	            return new Promise((resolve, reject) => {
	                ajaxCALL(
	                    url,
	                    data,
	                    res => resolve(res),
	                    err => reject(err)
	                )
	            })
	        },
	
	        async onReset() {
	            const $this = this
	
	            if ($this.LyDo === '' || $this.LyDo === null) {
	                Vue.$toast.error('Không được bỏ trống "Lý do"', { position: 'top' })
	                return
	            }
	
	            try {
	                await $this.ajaxPromise('/Reset_Student_Process', {
	                    Student_ID: vueData.StudentDetail.StudentID,
	                    LyDo: $this.LyDo
	                })
	
	                await $this.ajaxPromise('/Student_Remove', {
	                    StudentID: vueData.StudentDetail.StudentID
	                })
	
	                await $this.ajaxPromise('/Student_INS_obj', {
	                    StudentObjArr: vueData.StudentDetail,
	                    Process_Action: 1,
	                })
	
	                Vue.$toast.success('Đăng ký mới thành công', { position: 'top' })
	                $this.onClose()
	            } catch (error) {
	                Vue.$toast.error(error?.responseJSON?.Message || 'Có lỗi xảy ra', {
	                    position: 'top'
	                })
	                console.log('API error', error)
	            }
	        },
	
	        onClose() {
	            this.LyDo = null,
	                vueData.isOpenReset = false
	        },
	    },
	}
</script>