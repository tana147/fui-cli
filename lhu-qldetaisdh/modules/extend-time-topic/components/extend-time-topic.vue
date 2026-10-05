<template>
    <v-container>
        <v-expansion-panels v-model="vueData.Panel" accordion>
            <v-expansion-panel v-for="(item, index) in rootflow" :key="index">
                <v-expansion-panel-header
                    :step="index + 1"
                    @click="onLoadDetailFlow(item.Flow_ID, item.LOCK_STATUS)"
                    :class="getStepColor(item.Flow_Status, item.LOCK_STATUS)"
                    :style="item.LOCK_STATUS ? { height: '48px' } : null"
                    disable-icon-rotate
                >
                    <div class="stepperStep mt-1">
                        <h4 class="headerColorTxt">{{ index + 1 }}./ {{ item.TASK_NAME }}</h4>
                    </div>
                    <template v-slot:actions>
                        <v-icon color="white">{{ getStepIcon(item.Flow_Status, item.LOCK_STATUS) }}</v-icon>
                    </template>
                </v-expansion-panel-header>
                <v-expansion-panel-content :step="index + 1" :style="dataDetailFlow && dataDetailFlow.length > 0 ? getStyleStatusLock(item.LOCK_STATUS) : null">
                    <div class="mt-3">
                        <div v-if="dataDetailFlow.length > 0">
                            <div v-for="(itemDes, indexDes) in dataDetailFlow" :key="indexDes">
                                <div class="d-flex align-center">
                                    <span>
                                        <h4>{{ index + 1 }}.{{ indexDes + 1 }} {{ itemDes.Task_Detail_Description }}</h4>
                                    </span>
                                    <div v-if="itemDes.Data_Exp !== null && itemDes.Task_Detail_Type === 'FILE'" class="ml-auto">
                                        <a :href="itemDes.Data_Exp" download="file mẫu">
                                            <v-btn color="success" text> <v-icon>mdi-download-circle</v-icon> Tải file mẫu </v-btn>
                                        </a>
                                    </div>
                                </div>

                                <file-comp :itemdes="itemDes" :item="item" v-if="itemDes.Task_Detail_Type === 'FILE' || itemDes.Task_Detail_Type === 'FILEVIEW'" />
                                <text-comp :itemdes="itemDes" v-if="itemDes.Task_Detail_Type === 'TEXT' || itemDes.Task_Detail_Type === 'TEXTVIEW'" />
                                <!-- <v-text-field outlined dense color="success" v-model="itemDes.Text_Content"
										:hint="itemDes.Data_Exp"
										v-if="itemDes.Task_Detail_Type === 'TEXT' || itemDes.Task_Detail_Type === 'TEXTVIEW'"
										:disabled="itemDes.Task_Detail_Type === 'TEXTVIEW'" /> -->
                            </div>

                            <div class="d-flex justify-end mt-3" v-if="item.Flow_Status !== 'C' && dataDetailFlow[0].User_Input !== 'SDH'">
                                <v-btn color="success" @click="onSave(item.Flow_ID, item)" class="mb-3">Lưu</v-btn>
                            </div>
                        </div>

                        <div v-else>
                            <p>Dữ liệu không tồn tại</p>
                        </div>
                    </div>
                </v-expansion-panel-content>
            </v-expansion-panel>
        </v-expansion-panels>
    </v-container>
</template>

<script>
export default {
    props: ['defaultfLow', 'rootflow'],
    data() {
        return {
            student_id: null,
            dataDetailFlow: [],
        }
    },
    mounted() {},
    computed: {},
    watch: {
        rootflow: function (val) {
            if (val.length === 0) {
                this.confirmBox()
            }
            if (val.length > 0) {
                this.student_id = val[0].STUDENT_ID
                this.onLoadDetailFlow(vueData.DefaultFLow?.Flow_ID, vueData.DefaultFLow?.LOCK_STATUS)
                vueData.Panel = val?.findIndex((item) => item.LOCK_STATUS === 1)
            }
        },
    },
    methods: {
        confirmBox() {
            confirm({
                title: 'Tạo thủ tục gia hạn thời gian',
                content: `Bạn có muốn tạo mới thủ tục gia hạn thời gian không?`,
                action: async () => {
                    await this.onProcessStudent()
                    window.location.reload()
                },
                cancel: function () {
                    window.location.href = 'https://qldetaisdh.lhu.edu.vn/my-thesis'
                }.bind(this),
            })
        },
        onProcessStudent() {
            return new Promise((resolve, reject) => {
                ajaxCALL(
                    '/Process_Student_Ins',
                    {
                        Process_Action: 3,
                        Student_ID: vueData.user.UserID,
                        Expire_Date: new Date().getFullYear().toString() + '-12-12',
                        insert_new: 1,
                    },
                    (res) => {
                        // Vue.$toast.success(`Thêm dữ liệu thành công`, { position: 'top' });
                        console.log('Gia hạn thành công')
						resolve()
                    },
                    (error) => {
                        Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                        console.log('Fail to Process_Student_Ins', error)
						reject(error)
                    },
                )
            })
        },
        async onLoadDetailFlow(FLOW_ID, LOCK_STATUS) {
            const $this = this
            ajaxCALL(
                '/Get_FlowDetail',
                { Flow_ID: FLOW_ID },
                async (res) => {
                    // Lấy detail của flow id đó
                    let filterarr = res.data.map(async (item) => {
                        return { ...item, FILE_UPLOAD: null }
                    })

                    Promise.all(filterarr).then((res) => {
                        console.log('set..', res)
                        $this.dataDetailFlow = res
                    })
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                    console.log('Error: ', error)
                },
            )
        },
        onSave(FLOW_ID, root) {
            console.log('Data: this.dataDetailFlow', this.dataDetailFlow)
            let validationPassed = true
            this.dataDetailFlow.forEach((item) => {
                if (item.Task_Detail_Type !== 'FILE' && item.Task_Detail_Type !== 'FILEVIEW' && (item.Text_Content === null || item.Text_Content === '') && item.Task_Detail_Type !== 'FUN') {
                    Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa nhập nội dung`, { position: 'top' })
                    validationPassed = false
                    console.log('error text content', item)
                    return
                }
                if ((item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW') && item.File_ID === null && item.Task_Detail_Type !== 'FUN') {
                    Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa upload file`, { position: 'top' })
                    validationPassed = false
                    console.log('error file', item)
                    return
                }
            })

            if (validationPassed) {
                let promises = this.dataDetailFlow.map((item) => {
                    return new Promise((resolve, reject) => {
                        ajaxCALL(
                            '/FlowDetail_UpdateData',
                            {
                                Student_ID: vueData.user.UserID,
                                Process_ID: root.PROCESS_ID,
                                Flow_ID: item.Flow_ID,
                                Task_ID: item.Task_ID,
                                Task_Detail_ID: item.Task_Detail_ID,
                                Text_Content: item.Text_Content,
                                File_Name: item.Task_Detail_Type === 'FILE' ? item.FILE_UPLOAD?.File_Name ?? null : null,
                                File_Type: item.Task_Detail_Type === 'FILE' ? item.FILE_UPLOAD?.File_Type ?? null : null,
                                File_URL: item.Task_Detail_Type === 'FILE' ? item.FILE_UPLOAD?.File_URL ?? null : null,
                                File_ID: item.Task_Detail_Type === 'FILE' ? item.FILE_UPLOAD?.File_ID ?? null : null,
                            },
                            (res) => {
                                console.log('Upload success: ', this.dataDetailFlow)
                                resolve('success')
                            },
                            (error) => {
                                Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                                console.log('Error upload: ', error)
                                reject('fail')
                            },
                        )
                    })
                })
                Promise.all(promises)
                    .then((results) => {
                        if (results.includes('fail')) {
                            Vue.$toast.error(`Cập nhật ${root.TASK_NAME} thất bại`, { position: 'top' })
                        } else {
                            Vue.$toast.success(`Cập nhật ${root.TASK_NAME} thành công`, { position: 'top' })
                        }
                    })
                    .catch((err) => {
                        Vue.$toast.error(`Đã xảy ra lỗi`, { position: 'top' })
                    })
            }
        },
        getStepColor(name, lock) {
            if (lock == 0) {
                //LOCK_STATUS = 0 CHƯA ĐƯỢC LÀM, 1: ĐƯỢC LÀM
                switch (name) {
                    case 'W': //W: WAIT
                        return 'blue lighten-4'
                    case 'C': //C: COMPLETED
                        return 'green darken-1'
                    case 'P': //P:PROCESSING
                        return 'blue darken-2'
                    case 'R': //R: REJECTED
                        return 'red darken-2'
                    default:
                        return 'secondary'
                }
            } else {
                //LOCK = 1 : 1: ĐƯỢC LÀM
                switch (name) {
                    case 'W': //W: WAIT
                        return 'amber'
                    case 'P': //P:PROCESSING
                        return 'blue darken-2'
                }
            }
        },
        getStyleStatusLock(lock) {
            if (lock === 0) {
                return 'pointer-events: auto; opacity: 0.5;'
            } else {
                return 'pointer-events: auto; opacity: 1;'
            }
        },
        getStepIcon(name, lock) {
            if (lock == 0 && name == 'W') {
                //LOCK_STATUS = 0 CHƯA ĐƯỢC LÀM, 1: ĐƯỢC LÀM
                return 'mdi-lock'
            } else {
                switch (name) {
                    case 'W': //W: WAIT
                        return 'mdi-information'
                    case 'C': //C: COMPLETED
                        return 'mdi-check-bold'
                    case 'P': //P:PROCESSING
                        return 'mdi-timer-sand'
                    case 'R': //R: REJECTED
                        return 'mdi-close-thick'
                    default:
                        return 'water-boiler-alert'
                }
            }
        },
    },
}
</script>
