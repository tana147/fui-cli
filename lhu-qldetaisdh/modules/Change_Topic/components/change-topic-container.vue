<template>
	<v-container>
        <div class="d-flex align-center justify-end mb-3">
            <v-btn color="teal" dark @click="changeThesisAgain">Đổi/Điều chỉnh đề tài</v-btn>
        </div>
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

                                <!-- Kiểm tra in hoa -->
                                <v-alert
                                    v-if="
                                        itemDes.isInHoa &&
                                        (itemDes.User_Input === 'SDH' ||
                                            itemDes.Task_Detail_Type === 'TEXT' ||
                                            itemDes.Task_Detail_Type === 'TEXTAREA' ||
                                            itemDes.Task_Detail_Type === 'TEXTAREA | FUN')
                                    "
                                    border="right"
                                    colored-border
                                    type="error"
                                    elevation="2"
                                    dense
                                >
                                    {{ itemDes.InHoaError }}
                                </v-alert>

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
            DsHocHamHocVi: [],
        }
    },
    mounted() {
        this.onLoadHocHamHocVi()
    },
    computed: {},
    watch: {
        rootflow: function (val) {
            console.log('val xxxx', val)
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
        onLoadHocHamHocVi() {
            ajaxCALL(
                '/HocViHocHam_Get',
                null,
                (res) => {
                    vueData.DsHocHamHocVi = res.data
                    console.log('this.DsHocHamHocVi', vueData.DsHocHamHocVi)
                },
                (error) => {
                    Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' })
                    console.log('Fail to load hoc ham hoc vi', error)
                },
            )
        },
        changeThesisAgain() {
            confirm({
                title: 'Bạn có muốn tạo mới thủ tục đổi đề tài/GVHD không?',
                action: async () => {
                    await this.onProcessStudent()
                    window.location.reload()
                },
                cancel: function () {}.bind(this),
            })
        },
        confirmBox() {
            confirm({
                title: 'Bạn có muốn tạo mới thủ tục đổi đề tài/GVHD không?',
                action: async () => {
                    await this.onProcessStudent()
                    window.location.reload()
                },
                cancel: function () {
                    window.location.href = 'https://qldetaisdh.lhu.edu.vn/my-thesis'
                }.bind(this),
            })
        },
        async onProcessStudent() {
            return new Promise((resolve, reject) => {
                ajaxCALL(
                    '/Process_Student_Ins',
                    {
                        // Process_Action 2 là cây đổi đề tài,
                        Process_Action: 2,
                        Student_ID: vueData.user.UserID,
                        Expire_Date: new Date().getFullYear().toString() + '-12-12',
                        insert_new: 1,
                    },
                    (res) => {
                        console.log('Tạo mới thủ tục thành công')
                        resolve() // Giải quyết Promise khi thành công
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
                (res) => {
                    // Lấy detail của flow id đó
                    let filterarr = res.data.map((item) => ({ ...item, FILE_UPLOAD: null, InHoaError: '', isInHoa: false }))
                    $this.dataDetailFlow = filterarr
                },
                (error) => {
                    console.log('Error: ', error)
                },
            )
        },

        validateText(str) {
            if (str === null || str === undefined || str === '' || str === true || str === false) {
                return false
            }
            // Regex kiểm tra ký tự đầu tiên
            const lowercaseRegex = /^[a-zàáâãèéêìíòóôõùúăđĩũơỳỷỹýỵ]$/
            console.log('strxxx', str)
            // Chữ cái đầu tiên viết thường
            if (lowercaseRegex.test(str.charAt(0))) {
                return 0
            }
            let totalLatinChars = 0
            let upperCaseCount = 0

            // Loại bỏ hoặc mở rộng regex
            const vietnameseRegex = /[a-zA-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂƠÊÒÓÔĐêềệễẵặạảấầẩẫậếềểễệỳỷỹỳýỳỵ]/

            for (let i = 0; i < str.length; i++) {
                const char = str.charAt(i)
                const charCode = str.charCodeAt(i)

                // Chỉ đếm các ký tự Latin hoặc tiếng Việt
                if (vietnameseRegex.test(char)) {
                    totalLatinChars++

                    // Kiểm tra in hoa
                    if ((charCode >= 65 && charCode <= 90) || (char >= 'À' && char <= 'Ỵ')) {
                        upperCaseCount++
                    }
                }
            }

            const totalChars = totalLatinChars

            // Phần còn lại của logic giữ nguyên
            if (totalChars === 0) {
                return false
            }

            const upperCaseRatio = upperCaseCount / totalChars

            return upperCaseRatio > 0.9
        },

        async onSave(FLOW_ID, root) {
            let validationPassed = true
            this.dataDetailFlow.forEach((item) => {
                if (
                    item.AllowNull === '0' &&
                    item.Task_Detail_Type !== 'FILE' &&
                    item.Task_Detail_Type !== 'FILEVIEW' &&
                    (item.Text_Content === null || item.Text_Content === '') &&
                    item.Task_Detail_Type !== 'FUN'
                ) {
                    Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa nhập nội dung`, { position: 'top' })
                    validationPassed = false
                    return
                }
                if (item.AllowNull === '0' && (item.Task_Detail_Type === 'FILE' || item.Task_Detail_Type === 'FILEVIEW') && item.File_ID === null && item.Task_Detail_Type !== 'FUN') {
                    Vue.$toast.error(`Task "${item.Task_Detail_Description}" chưa upload file`, { position: 'top' })
                    validationPassed = false
                    return
                }

                if (item.FieldName === 'ThesisNameNew') {
                    const validationResult = this.validateText(item.Text_Content)
                    if (validationResult && validationResult !== 0) {
                        item.isInHoa = true
                        item.InHoaError = 'Không được nhập toàn bộ in hoa'
                        validationPassed = false
                    } else if (validationResult === 0 && item.Task_Detail_StyleDisplay !== 'email') {
                        item.isInHoa = true
                        item.InHoaError = 'Chữ cái đầu tiên phải viết hoa'
                        validationPassed = false
                    } else {
                        item.isInHoa = false
                        item.InHoaError = ''
                    }
                }
            })
            console.log('dataDetailFlow', this.dataDetailFlow)
            console.log('validationPassed', validationPassed)

            if (validationPassed) {
                const payloadDetails = this.dataDetailFlow.map((item) => ({
                    Task_Detail_ID: item.Task_Detail_ID,
                    Text_Content: typeof item.Text_Content === 'string' && item.Text_Content ? item.Text_Content.trim() : (item.Text_Content ?? ''),
                    File_Name: item.Task_Detail_Type === 'FILE' ? (item.FILE_UPLOAD?.File_Name ?? item.File_Name ?? null) : null,
                    File_Type: item.Task_Detail_Type === 'FILE' ? (item.FILE_UPLOAD?.File_Type ?? item.File_Type ?? null) : null,
                    File_URL: item.Task_Detail_Type === 'FILE' ? (item.FILE_UPLOAD?.File_URL ?? item.File_URL ?? null) : null,
                    File_ID: item.Task_Detail_Type === 'FILE' ? (item.FILE_UPLOAD?.File_ID ?? item.File_ID ?? null) : null,
                    Flow_Detail_Status: 'P'
                }))

                try {
                    await ajaxCALLPromise('/FlowDetail_UpdateMulti', {
                        Student_ID: this.student_id || vueData.studentId || vueData.user.UserID,
                        Process_ID: root.PROCESS_ID,
                        Flow_ID: root.Flow_ID || this.dataDetailFlow[0]?.Flow_ID || FLOW_ID,
                        Task_ID: root.Children_Task_ID || root.TASK_ID || this.dataDetailFlow[0]?.Task_ID,
                        JsonDetails: JSON.stringify(payloadDetails),
                        IsApproveAll: 0
                    })
                    Vue.$toast.success(`Cập nhật ${root.TASK_NAME} thành công`, { position: 'top' })
                    this.onLoadDetailFlow(FLOW_ID, root.LOCK_STATUS)
                } catch (err) {
                    console.error('Fail to save', err)
                    Vue.$toast.error(err?.responseJSON?.Message || `Cập nhật ${root.TASK_NAME} thất bại`, { position: 'top' })
                }
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