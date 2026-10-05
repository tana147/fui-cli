<template>
	<v-dialog v-model="vueData.isOpenViewOld" transition="dialog-bottom-transition" max-width="1000px" persistent>
        <v-card>
            <c-toolbar @onClose="vueData.isOpenViewOld = false">
                <template v-slot:title>
                    <div class="title primary--text text-left">Dữ liệu đăng kỹ cũ</div>
                </template>
            </c-toolbar>

            <v-card-text>
                <v-container>
                    <v-expansion-panels v-model="panel" accordion>
                        <v-expansion-panel v-for="(item, index) in DsOldView" :key="index">
                            <v-expansion-panel-header :step="index + 1" @click="onLoadDetailFlow(item.Flow_ID)" :class="getStepColor(item.Flow_Status)" disable-icon-rotate>
                                <div class="stepperStep mt-1">
                                    <h4>{{ index + 1 }}./ {{ item.Task_Name }}</h4>
                                </div>
                                <template v-slot:actions>
                                    <v-icon color="white">{{ getStepIcon(item.Flow_Status) }}</v-icon>
                                </template>
                            </v-expansion-panel-header>

                            <v-expansion-panel-content :step="index + 1">
                                <div v-if="DsFlowDetail.length > 0">
                                    <div v-for="(itemDes, indexDes) in DsFlowDetail" :key="indexDes">
                                        <div v-if="itemDes.Task_Detail_Display === 1">
                                            <div class="d-flex align-center mt-3">
                                                <span class="d-flex align-center">
                                                    <h4>{{ index + 1 }}.{{ indexDes + 1 }} {{ itemDes.Task_Detail_Description }}</h4>

                                                    <div v-if="itemDes.Task_Detail_Type === 'CHECKBOX'" class="ml-6">
                                                        <v-checkbox class="checkboxMod" large readonly color="success" :input-value="String(itemDes.Text_Content).toLowerCase() === 'true'" persistent-hint />
                                                    </div>
                                                </span>
                                            </div>

                                            <v-text-field
                                                v-if="itemDes.Task_Detail_Type === 'TEXT' || itemDes.Task_Detail_Type === 'TEXTVIEW'"
                                                v-model="itemDes.Text_Content"
                                                hide-details
                                                outlined
                                                readonly
                                                dense
                                                color="success"
                                            />

                                            <div class="dateWrap" v-if="itemDes.Task_Detail_Type === 'DATE' || itemDes.Task_Detail_Type === 'DATEVIEW'">
                                                <f-date v-model="itemDes.Text_Content" readonly />
                                            </div>

                                            <div v-if="itemDes.Task_Detail_Type === 'FILE' || itemDes.Task_Detail_Type === 'FILEVIEW'">
                                                <v-chip v-if="itemDes.File_ID" label outlined class="mb-3" color="deep-purple accent-4">
                                                    <v-icon left>mdi-file-check-outline</v-icon>
                                                    <a :href="vueData.v_Set.urlReadFile + itemDes.File_URL" target="_blank" style="color: deep-purple accent-4">{{ itemDes.File_Name }}</a>
                                                </v-chip>

                                                <v-chip v-if="itemDes.File_ID === null || itemDes.File_ID === ''" class="mb-3" color="deep-purple accent-4" outlined label>
                                                    Chưa upload file
                                                </v-chip>
                                            </div>

                                            <v-textarea
                                                v-if="itemDes.Task_Detail_Type === 'TEXTAREA' || itemDes.Task_Detail_Type === 'TEXTAREAVIEW' || itemDes.Task_Detail_Type === 'TEXTAREA | FUN'"
                                                v-model="itemDes.Text_Content"
                                                :class="[itemDes.Task_Detail_StyleDisplay ? 'mt-2 ' + itemDes.Task_Detail_StyleDisplay : 'mt-2']"
                                                :style="itemDes.Task_Detail_StyleDisplay ? { 'line-height': '10px' } : {}"
                                                outlined
                                                name="input-7-1"
                                                rows="1"
                                                color="green"
                                                flat="false"
                                                auto-grow
                                                dense
                                                readonly
                                                hide-details
                                            />

                                            <v-text-field
                                                v-if="itemDes.Task_Detail_Type === 'DIEM' || itemDes.Task_Detail_Type === 'FORMULAR'"
                                                class="scoreField mb-3 mt-1"
                                                color="success"
                                                outlined
                                                dense
                                                readonly
                                                v-model="itemDes.Text_Content"
                                                :hint="itemDes.Data_Exp"
                                                hide-details
                                                reverse
                                            />
                                        </div>
                                    </div>
                                </div>

                                <div v-else>
                                    <h4 class="text-center pa-5 grey--text">Không có dữ liệu</h4>
                                </div>
                            </v-expansion-panel-content>
                        </v-expansion-panel>
                    </v-expansion-panels>
                </v-container>
            </v-card-text>
        </v-card>
    </v-dialog>
</template>

<script>
	export default {
		props: [],
    data() {
        return {
            DsOldView: [],
            DsFlowDetail: [],

            panel: null,
        }
    },
    mounted() {},
    computed: {
        isOpenViewOld() {
            return vueData.isOpenViewOld
        },
    },
    watch: {
        async isOpenViewOld(val) {
            if (val) {
                this.DsOldView = await onLoadRootFlowHis(vueData.StudentDetail.StudentID)
                console.log('this.DsOldView', this.DsOldView)
            }
        },
    },
    methods: {
        async onLoadDetailFlow(flowID) {
            this.DsFlowDetail = await onLoadFlowDetailHis(flowID)
            console.log('this.DsFlowDetail', this.DsFlowDetail)
        },

        getStepColor(name, lock) {
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
        },

        getStepIcon(name, lock) {
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
        },
    },
	}
</script>