<template>
    <v-dialog v-model="vueData.IsShowDialogPushMenu" scrollable width="900">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>Đồng bộ menu lên Grab</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IsShowDialogPushMenu = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <v-row>
                    <v-col md="5" style="border-right: 1px solid #d1d1d1">
                        <p class="mb-0 font-weight-bold">
                            Cửa hàng <span class="success--text ml-1">({{ CuaHangID_Selected.length }} cửa hàng)</span>
                        </p>
                        <v-checkbox :key="0" class="mt-1" v-model="CuaHangID_Selected_All" :disabled="isProcessPushMenu" label="Tất cả cửa hàng" color="success" hide-details></v-checkbox>
                        <v-checkbox v-for="item in CuaHangFiltered" :key="item.CuaHangID" class="mt-1" v-model="CuaHangID_Selected" :disabled="isProcessPushMenu" :label="item.TenCuaHang" :value="item.CuaHangID" color="success" hide-details></v-checkbox>
                    </v-col>
                    <v-col md="7" class="pl-4">
                        <p class="mb-2 font-weight-bold">Đồng bộ menu lên Grab</p>
                        <v-row>
                            <v-col md="12">
                                <p class="mb-2">
                                    <b>Thời gian đồng bộ:</b> ≈ 3 giây / cửa hàng
                                </p>
                                <v-btn elevation="0" color="success" :disabled="isProcessPushMenu" @click="onPushMenuGrab()">
                                    <v-icon left>mdi-cloud-upload</v-icon>
                                    Bắt đầu đồng bộ
                                </v-btn>
                                <v-btn elevation="0" color="error" :disabled="!isProcessPushMenu" @click="onCancelPushMenu()" class="ml-2">
                                    <v-icon left>mdi-stop</v-icon>
                                    Dừng
                                </v-btn>
                            </v-col>
                        </v-row>
                        <div class="d-flex justify-space-between mt-4 mb-1">
                            <div>
                                <span class="font-weight-bold">Danh sách cửa hàng đồng bộ</span>
                                <span v-if="isProcessPushMenu" class="ml-2 primary--text font-weight-bold">{{ currentCuaHang }}/{{ totalCuaHang }}</span>
                            </div>
                            <span><span class="success--text font-weight-bold">✓ {{ successCount }}</span> - <span class="error--text font-weight-bold">✗ {{ errorCount }}</span></span>
                        </div>
                        <v-progress-linear v-if="isProcessPushMenu" class="mb-1" :value="numProcessPushMenu"></v-progress-linear>
                        <v-card ref="logContainer" outlined style="height: 420px; background: #f5f5f5; overflow-y: auto; border: 1px solid #ddd;">
                            <v-list style="padding: 0;">
                                <v-list-item v-for="(item, index) in cuaHangProcessList" :key="index" dense class="px-3 py-2" :style="{backgroundColor: item.status === 'processing' ? '#e3f2fd' : 'transparent', borderBottom: '1px solid #e0e0e0', fontWeight: item.status === 'processing' ? 'bold' : 'normal'}">
                                    <v-list-item-icon class="mr-2 my-0" style="min-width: 24px;">
                                        <v-progress-circular v-if="item.status === 'processing'" indeterminate size="16" width="2" color="orange"></v-progress-circular>
                                        <v-icon v-else x-small :class="getStatusClass(item.status)">{{ getStatusIcon(item.status) }}</v-icon>
                                    </v-list-item-icon>
                                    <v-list-item-content class="py-0">
                                        <v-list-item-title class="caption text--darken-2" :class="getStatusClass(item.status)">
                                            {{ item.tenCuaHang }} <span v-if="item.status !== 'pending'">- {{ getStatusText(item.status) }}</span>
                                        </v-list-item-title>
                                        <v-list-item-subtitle class="grey--text text--darken-2" style="font-size: 0.65rem; margin-top: 2px;">
                                            <span v-if="item.status === 'pending'">{{ getStatusText(item.status) }}</span>
                                            <span v-if="item.startTime">[{{ item.startTime }}]</span>
                                            <span class="ml-1" v-if="item.message">{{ item.message }}</span>
                                        </v-list-item-subtitle>
                                    </v-list-item-content>
                                </v-list-item>
                            </v-list>
                        </v-card>
                    </v-col>
                </v-row>
            </v-card-text>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    data() {
        return {
            isProcessPushMenu: false,
            numProcessPushMenu: 0,
            CuaHangID_Selected_All: false,
            CuaHangID_Selected: [],
            cancelPushMenu: false,
            successCount: 0,
            errorCount: 0,
            totalCuaHang: 0,
            currentCuaHang: 0,
            cuaHangProcessList: [],
            vueData
        }
    },
    watch: {
        CuaHangID_Selected_All(data) {
            if (data) {
                this.CuaHangID_Selected = this.CuaHangFiltered.map((item) => item.CuaHangID)
            } else {
                this.CuaHangID_Selected = []
            }
        },
        'vueData.IsShowDialogPushMenu'(isShow) {
            if (isShow) {
                const currentCuaHangID = vueData?.CuaHangID
                if (currentCuaHangID) {
                    this.CuaHangID_Selected = [currentCuaHangID]
                    this.CuaHangID_Selected_All = false
                } else {
                    this.CuaHangID_Selected = []
                    this.CuaHangID_Selected_All = false
                }
            }
        },
        cuaHangProcessList: {
            handler() {
                this.$nextTick(() => {
                    const processingItem = this.cuaHangProcessList.find(item => item.status === 'processing')
                    if (processingItem && this.$refs.logContainer) {
                        const container = this.$refs.logContainer.$el
                        const processingIndex = this.cuaHangProcessList.indexOf(processingItem)
                        const itemHeight = 48
                        const scrollTop = processingIndex * itemHeight - 100
                        container.scrollTop = Math.max(0, scrollTop)
                    }
                })
            },
            deep: true
        }
    },
    computed: {
        CuaHangFiltered() {
            const allStores = vueData?.DSCuaHang.filter(ch => ch.MerchantID !== null) ?? []
            const currentCuaHangID = vueData?.CuaHangID

            if (!currentCuaHangID) return allStores

            const currentStore = allStores.find(ch => ch.CuaHangID === currentCuaHangID)
            const otherStores = allStores.filter(ch => ch.CuaHangID !== currentCuaHangID)

            return currentStore ? [currentStore, ...otherStores] : allStores
        }
    },
    methods: {
        async onPushMenuGrab() {
            if (this.CuaHangID_Selected.length === 0) {
                showToast({ type: "warning", title: "Vui lòng chọn cửa hàng" })
                return
            }

            this.cancelPushMenu = false
            this.isProcessPushMenu = true
            this.totalCuaHang = 0
            this.currentCuaHang = 0

            const DS_CuaHang_Merchent = this.CuaHangFiltered
                .filter((ch) => this.CuaHangID_Selected.includes(ch.CuaHangID))
                .filter((ch) => ch.MerchantID != "" && ch.MerchantID != null)

            if (DS_CuaHang_Merchent.length === 0) {
                showToast({ type: "warning", title: "Không có cửa hàng nào có MerchantID" })
                this.isProcessPushMenu = false
                return
            }

            this.totalCuaHang = DS_CuaHang_Merchent.length
            const percentProcess = 100 / DS_CuaHang_Merchent.length
            this.successCount = 0
            this.errorCount = 0

            this.cuaHangProcessList = DS_CuaHang_Merchent.map(ch => ({
                CuaHangID: ch.CuaHangID,
                tenCuaHang: ch.TenCuaHang,
                status: 'pending',
                message: '',
                startTime: ''
            }))

            for (let i = 0; i < DS_CuaHang_Merchent.length; i++) {
                if (this.cancelPushMenu) break

                const merchant = DS_CuaHang_Merchent[i]
                this.currentCuaHang = i + 1

                const itemIndex = this.cuaHangProcessList.findIndex(ch => ch.CuaHangID === merchant.CuaHangID)
                if (itemIndex !== -1) {
                    this.cuaHangProcessList[itemIndex].status = 'processing'
                    this.cuaHangProcessList[itemIndex].startTime = new Date().toLocaleTimeString('vi-VN')
                    this.cuaHangProcessList[itemIndex].message = 'Đang đẩy menu lên GRAB'
                    this.$forceUpdate()
                }

                if (i < DS_CuaHang_Merchent.length - 1) {
                    const timeDelay = 3
                    for (let j = 0; j < timeDelay; j++) {
                        if (this.cancelPushMenu) break
                        await this.sleep(1000)
                    }
                }

                try {
                    const params = {
                        Json_Data: JSON.stringify({
                            merchantID: merchant.MerchantID,
                        }),
                    }

                    await new Promise((resolve) => {
                        ajaxCALL("/eorder/GRABPUSH_Menu_Notification", params, (res) => {
                            const statusIndex = this.cuaHangProcessList.findIndex(ch => ch.CuaHangID === merchant.CuaHangID)
                            if (res?.httpErrorCode) {
                                if (statusIndex !== -1) {
                                    this.cuaHangProcessList[statusIndex].status = "error"
                                    this.cuaHangProcessList[statusIndex].message = res?.responseData.message || "Lỗi không xác định"
                                }
                                this.$forceUpdate()
                                this.errorCount++
                            } else {
                                if (statusIndex !== -1) {
                                    this.cuaHangProcessList[statusIndex].status = "success"
                                    this.cuaHangProcessList[statusIndex].message = "Đã đẩy menu lên GRAB"
                                }
                                this.$forceUpdate()
                                this.successCount++
                            }
                            resolve()
                        })
                    })

                    this.numProcessPushMenu += percentProcess

                } catch (ex) {
                    const statusIndex = this.cuaHangProcessList.findIndex(ch => ch.CuaHangID === merchant.CuaHangID)
                    if (statusIndex !== -1) {
                        this.cuaHangProcessList[statusIndex].status = "error"
                        this.cuaHangProcessList[statusIndex].message = ex.message
                    }
                    this.$forceUpdate()
                    this.errorCount++
                }
            }

            this.isProcessPushMenu = false
            this.numProcessPushMenu = 0

            showToast({
                type: "green",
                title: `Push menu hoàn tất: ${this.successCount} thành công, ${this.errorCount} lỗi`,
            })
        },
        onCancelPushMenu() {
            this.cancelPushMenu = true
            this.isProcessPushMenu = false
            this.numProcessPushMenu = 0
            showToast({ type: "warning", title: "Đã dừng push menu" })
        },
        sleep(ms) {
            return new Promise((resolve) => setTimeout(resolve, ms))
        },
        getStatusIcon(status) {
            if (status === 'success') return 'mdi-check-circle'
            if (status === 'error') return 'mdi-alert-circle'
            if (status === 'processing') return 'mdi-loading'
            return 'mdi-clock-outline'
        },
        getStatusClass(status) {
            if (status === 'success') return 'success--text'
            if (status === 'error') return 'error--text'
            if (status === 'processing') return 'orange--text'
            return 'grey--text'
        },
        getStatusText(status) {
            if (status === 'success') return 'Thành công'
            if (status === 'error') return 'Thất bại'
            if (status === 'processing') return 'Đang đồng bộ'
            return 'Đang chờ'
        },
    },
}
</script>