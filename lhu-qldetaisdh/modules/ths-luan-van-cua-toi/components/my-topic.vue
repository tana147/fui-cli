<template>
    <div class="container">
        <v-dialog v-model="isInfo" transition="dialog-bottom-transition" max-width="600">
            <v-card>
                <v-card-title>Thông tin giảng viên</v-card-title>
                <v-card-text>
                    <p>Họ tên:</p>
                    <p>email:</p>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn color="success" @click="isInfo = false">Ok</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
        <div class="d-flex align-center justify-end mb-5" style="gap: 15px">
            <v-btn color="primary" :disabled="state === 1 ? false : true" @click="isDelayTime = true">Đơn gia hạn thời gian</v-btn>
            <v-btn color="warning" :disabled="state === 1 ? false : true" @click="isChangeTopic = true">Đơn thay đổi đề tài</v-btn>
        </div>
        <v-card max-width="1250">
            <div class="d-flex align-center">
                <v-card-title class="titleTxt mx-auto">
                    {{ userRole === 0 ? 'Thông tin đề tài luận văn thạc sĩ' : 'Thông tin đề tài luận văn tiến sĩ' }}
                </v-card-title>
                <div class="d-flex flex-grow-1 justify-end mr-3">
                    <v-chip v-if="state === 0" class="ma-2" color="primary"> Chờ duyệt </v-chip>
                    <v-chip v-if="state === 1" class="ma-2" color="success"> Đã duyệt </v-chip>
                    <v-chip v-if="state === 2" class="ma-2" color="error"> Từ chối </v-chip>
                </div>
            </div>
            <v-card-text>
                <div class="mb-5">
                    <h2>Số quyết định: {{ passCode === '' ? '../../..' : passCode }}</h2>
                </div>
                <h3>Tên đề tài</h3>
                <v-textarea class="mt-2" outlined name="input-7-1" rows="2" color="green" flat="false" auto-grow value="abc" :disabled="true" />
                <div class="d-flex align-center justify-center" style="gap: 15px">
                    <div class="inputContainer">
                        <h3 class="teacherTitle">{{ userRole === 1 ? 'Tên Giảng Viên Hướng Dẫn 1' : 'Tên Giảng Viên Hướng Dẫn' }}</h3>
                        <v-text-field outlined placeholder="Nhập tên Giảng Viên Hướng Dẫn" color="green" :disabled="true" />
                    </div>
                    <v-icon large class="mb-6" style="cursor: pointer" color="success" @click="isInfo = true"> mdi-information </v-icon>
                </div>
                <div class="d-flex align-center justify-center" style="gap: 15px" v-if="userRole === 1">
                    <div class="selectBox">
                        <v-select :items="professorship" label="Học hàm" solo :disabled="true" />
                    </div>
                    <div class="inputContainer">
                        <h3 class="teacherTitle">Tên Giảng Viên Hướng Dẫn 2</h3>
                        <v-text-field outlined placeholder="Nhập tên Giảng Viên Hướng Dẫn" color="green" :disabled="true" />
                    </div>
                    <v-icon large class="mb-6" style="cursor: pointer" color="success" @click="isInfo = true"> mdi-information </v-icon>
                </div>
                <div>
                    <v-file-input v-model="files" chips color="success" multiple show-size label="Thêm file" truncate-length="20" :disabled="true">
                        <template v-slot:selection="{ index, text }">
                            <v-chip close color="success" @click:close="deleteChip(index, text)">
                                {{ text }}
                            </v-chip>
                        </template>
                    </v-file-input>
                </div>
            </v-card-text>
        </v-card>
        <v-dialog v-model="isDelayTime" max-width="600" transition="dialog-top-transition">
            <v-card class="container">
                <v-toolbar color="success" dark> Đơn xin gia hạn thời gian làm luận văn </v-toolbar>
                <v-card-text class="d-flex justify-center align-center flex-column mt-5">
                    <v-alert type="info" outlined v-if="showAlert">{{ delayAlert(timeInp) }}</v-alert>
                    <v-time-picker format="24hr" color="success" class="mt-3" v-model="timeInp"></v-time-picker>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn @click="delayBtn" color="success" :disabled="timeInp === null ? true : false">Ok</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
        <v-dialog v-model="isChangeTopic" max-width="1100" transition="dialog-top-transition">
            <v-card>
                <v-toolbar color="success" dark> Đơn xin thay đổi đề tài </v-toolbar>
                <v-card-text class="mt-5">
                    <div class="d-flex align-center justify-center" style="gap: 15px">
                        <div class="inputContainer">
                            <h3 class="teacherTitle">Tên đề tài</h3>
                            <v-textarea solo name="input-7-4" label="Nhập tên đề tài" rows="2" outlined color="green" v-model="topicTxt" :rules="topicRule" auto-grow flat="false" />
                        </div>
                        <div v-if="isProgress">
                            <v-progress-circular indeterminate color="green"></v-progress-circular>
                        </div>
                        <div v-else>
                            <v-btn class="mb-8" color="warning" @click="checkBtn">Kiểm tra</v-btn>
                        </div>
                    </div>
                    <div class="d-flex align-center justify-center" style="gap: 15px">
                        <div class="selectBox">
                            <v-select :items="professorship" label="Học hàm" solo v-model="sb1" />
                        </div>
                        <div class="inputContainer">
                            <h3 class="teacherTitle">{{ userRole === 1 ? 'Tên Giảng Viên Hướng Dẫn 1' : 'Tên Giảng Viên Hướng Dẫn' }}</h3>
                            <v-text-field outlined placeholder="Nhập tên Giảng Viên Hướng Dẫn" color="green" v-model="teacher1Txt" :rules="teacherRule" />
                        </div>
                    </div>
                    <div class="d-flex align-center justify-center" style="gap: 15px" v-if="userRole === 1">
                        <div class="selectBox">
                            <v-select :items="professorship" label="Học hàm" solo v-model="sb2" />
                        </div>
                        <div class="inputContainer">
                            <h3 class="teacherTitle">Tên Giảng Viên Hướng Dẫn 2</h3>
                            <v-text-field outlined placeholder="Nhập tên Giảng Viên Hướng Dẫn" color="green" v-model="teacher2Txt" :rules="teacherRule" />
                        </div>
                    </div>
                    <div>
                        <v-file-input v-model="files" chips color="success" multiple show-size label="Thêm file" truncate-length="20" :rules="userRole === 0 ? fileRules : fileTypeRules">
                            <template v-slot:selection="{ index, text }">
                                <v-chip close color="success" @click:close="deleteChip(index, text)">
                                    {{ text }}
                                </v-chip>
                            </template>
                        </v-file-input>
                    </div>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn @click="submitBtn" color="success" :disabled="!validateField()">Nộp</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </div>
</template>

<script>
export default {
    props: [],
    data() {
        return {
            userRole: 0,
            isInfo: false,
            passCode: '',
            files: [],
            state: 1,
            isDelayTime: false,
            isChangeTopic: false,
            timeInp: null,
            isProgress: false,
            professorship: ['TS', 'PGSTS', 'GSTS'],
            fileRules: [
                (v) => !!v || 'Không được để trống',
                (v) => (v && v.length > 0) || 'Tiến sĩ phải nộp ít nhất 1 tệp',
                (v) => {
                    const validTypes = [
                        'application/pdf',
                        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                    ]
                    for (let i = 0; i < v.length; i++) {
                        if (!validTypes.includes(v[i].type)) {
                            return 'Loại tệp không hợp lệ'
                        }
                    }
                    return true
                },
                (v) => {
                    // Kiểm tra kích thước tệp
                    const maxSize = 5 * 1024 * 1024 // 5MB
                    for (let i = 0; i < v.length; i++) {
                        if (v[i].size > maxSize) {
                            return 'Kích thước tệp quá lớn'
                        }
                    }
                    return true
                },
            ],
            fileTypeRules: [
                (v) => {
                    const validTypes = [
                        'application/pdf',
                        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                    ]
                    for (let i = 0; i < v.length; i++) {
                        if (!validTypes.includes(v[i].type)) {
                            return 'Loại tệp không hợp lệ'
                        }
                    }
                    return true
                },
                (v) => {
                    // Kiểm tra kích thước tệp
                    const maxSize = 5 * 1024 * 1024 // 5MB
                    for (let i = 0; i < v.length; i++) {
                        if (v[i].size > maxSize) {
                            return 'Kích thước tệp quá lớn'
                        }
                    }
                    return true
                },
            ],
            topicTxt: '',
            teacher1Txt: '',
            teacher2Txt: '',
            sb1: null,
            sb2: null,
            topicRule: [(v) => !!v || 'Tên đề tài không được để trống', (v) => (v && v.length >= 3) || 'Đề tài phải có 3 ký tự trở lên'],
            teacherRule: [(v) => !!v || 'Tên GVHD không được để trống'],
        }
    },
    computed: {
        showAlert() {
            return this.timeInp === null // Hiển thị alert khi timeInp là null
        },
    },
    watch: {},
    methods: {
        validateField: function () {
            let sb1Valid,
                sb2Valid,
                teacher2Valid,
                fileValid = true
            const topicValid = this.topicRule.every((rule) => rule(this.topicTxt) === true)
            const teacher1Valid = this.teacherRule.every((rule) => rule(this.teacher1Txt) === true)
            if (this.userRole === 1) teacher2Valid = this.teacherRule.every((rule) => rule(this.teacher2Txt) === true)
            else teacher2Valid = true
            if (this.sb1 !== null) sb1Valid = true
            else sb1Valid = false
            if (this.userRole === 1) {
                if (this.sb2 !== null) sb2Valid = true
                else sb2Valid = false
            } else {
                sb2Valid = true
            }
            if (this.userRole === 1) {
                fileValid = this.fileRules.every((rule) => rule(this.files) === true)
            }
            if (this.userRole === 0) {
                fileValid = this.fileTypeRules.every((rule) => rule(this.files) === true)
            }
            return topicValid && teacher1Valid && teacher2Valid && sb1Valid && sb2Valid && fileValid
        },
        checkBtn: function () {
            this.isProgress = true
            //
            this.isProgress = false
        },
        deleteChip(index, text) {
            this.files.splice(index, 1)
        },
        delayBtn() {
            this.isDelayTime = false
        },
        delayAlert(time) {
            if (time === null) return 'Hãy chọn thời gian'
        },
        submitBtn() {
            this.teacher1Txt = ''
            this.teacher2Txt = ''
            this.topicTxt = ''
            this.files = []
            this.sb1 = null
            this.sb2 = null
            this.isChangeTopic = false
            Vue.$toast.success(`Nộp thành công`, { position: 'bottom-right' })
        },
    },
}
</script>
