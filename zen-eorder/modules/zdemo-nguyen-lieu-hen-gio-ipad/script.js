Vue.component("order-component", {
    data: function () {
        return {
            DSCheBien: [
                {
                    HoaDonID: 1,
                    TenKhu: "Khu A",
                    TenBan: "Bàn 3",
                    LoaiCheBien: 1,
                    LoaiCheBien_Ten: "Mang đi",
                    MaHoaDon: "HD001",
                    GioThemMoi: "10:30",
                    NhanVienThemMoi: "NV00001",
                    TenMon: "Trân châu tươi",
                    TrangThai: "Chưa nấu",
                    BuocHienTai: 0
                },
                {
                    HoaDonID: 2,
                    TenKhu: "Khu B",
                    TenBan: "Bàn 7",
                    LoaiCheBien: 2,
                    LoaiCheBien_Ten: "Khu B-Bàn 2",
                    MaHoaDon: "HD002",
                    GioThemMoi: "11:15",
                    NhanVienThemMoi: "NV00002",
                    TenMon: "Trà sữa matcha",
                    TrangThai: "Đang nấu",
                    BuocHienTai: 2
                },
                {
                    HoaDonID: 3,
                    TenKhu: "Khu B",
                    TenBan: "Bàn 7",
                    LoaiCheBien: 2,
                    LoaiCheBien_Ten: "Khu C-Bàn 3",
                    MaHoaDon: "HD003",
                    GioThemMoi: "13:45",
                    NhanVienThemMoi: "NV00003",
                    TenMon: "Kem mật thốt nốt",
                    TrangThai: "Đã nấu",
                    BuocHienTai: 3
                }
            ]
        }
    },
    watch: {
    },
    mounted() {
    },
    template: /*html*/ `
        <div class="d-flex ga-2 mt-2 ms-2">
            <v-card
                v-for="(item, index) in DSCheBien"
                :key="index"
                outlined
                class="card-order pa-0 mb-4"
            >
                <v-card-text style="font-size: 14px; color: black; padding: 12px">
                    <v-row
                       class="white--text py-2 font-weight-bold"
                        :style="StyleStatus(item)"
                    >
                        <v-col class="text-center" style="border-right: 2px dashed;">
                            <span v-if="item.LoaiCheBien === 1">{{item.TenKhu}}-{{item.TenBan}}</span>
                            <span v-else>{{item.LoaiCheBien_Ten}}</span>
                        </v-col>
                        <v-col class="text-center" cols="3" style="border-right: 2px dashed;">{{item.MaHoaDon}}</v-col>
                        <v-col class="text-center">{{item.GioThemMoi}}</v-col>
                    </v-row>
                    <v-row justify="space-between" class="pt-1">
                     <v-alert
                        dense
                        dark
                        :color="AlertColor(item.TrangThai)"
                        style="width: 100%"
                        class="mb-0"
                        :icon="AlertIcon(item.TrangThai)"
                    >
                        <v-row align="center">
                            <v-col cols="5" class="py-0 pa-0">Trạng thái:</v-col>
                            <v-col cols="7" class="text-right py-0 font-weight-bold">
                                {{ item.TrangThai }}
                                <template v-if="item.TrangThai === 'Đang nấu'">
                                    - <span class="white--text">Bước {{ item.BuocHienTai }}</span>
                                </template>
                            </v-col>
                        </v-row>
                    </v-alert>
                    </v-row>
                    <v-row justify="space-between">
                        <v-col cols="6">Nhân viên thực hiện:</v-col>
                        <v-col class="text-right">{{item.NhanVienThemMoi}}</v-col>
                    </v-row>
                    <v-row justify="space-between">
                        <v-col cols="5">Tên thực phẩm:</v-col>
                        <v-col class="text-right font-weight-bold blue--text">{{item.TenMon}}</v-col>
                    </v-row>
                    <v-row justify="space-between">
                        <v-col cols="6">Thời gian chế biến:</v-col>
                        <v-col class="text-right font-weight-bold">10 phút</v-col>
                    </v-row>
                    <v-row justify="space-between">
                        <v-col cols="6">Thời gian sử dụng:</v-col>
                        <v-col class="text-right font-weight-bold">3 tiếng</v-col>
                    </v-row>
                    <v-row justify="space-between">
                        <v-col cols="5">Cảnh báo hết hạn:</v-col>
                        <v-col class="text-right font-weight-bold">trước 60 phút</v-col>
                    </v-row>
                    <v-row justify="space-between">
                        <v-col cols="5">Số lượng:</v-col>
                        <v-col class="text-right font-weight-bold">30 phần</v-col>
                    </v-row>
                    <v-row>
                        <v-col cols="12" class="d-flex justify-center pa-0">
                            <v-btn style="width: 100%; color: white"  elevation="0" v-if="item.TrangThai === 'Chưa nấu'" color="#2196f3" @click="onStartCooking">
                                <v-icon left>mdi-play</v-icon>Bắt đầu
                            </v-btn>
                            <v-btn style="width: 100%; color: white"  elevation="0" v-else-if="item.TrangThai === 'Đang nấu'" color="#F44336" @click="onStartCooking">
                                <v-icon left>mdi-eye</v-icon>Xem chi tiết
                            </v-btn>
                            <v-btn style="width: 100%; color: white"  elevation="0" v-else-if="item.TrangThai === 'Đã nấu'" color="success"  @click="onConfirm()">
                                <v-icon left>mdi-check</v-icon>Hoàn thành
                            </v-btn>
                        </v-col>
                    </v-row>
                </v-card-text>
            </v-card>
        </div>
    `,
    computed: {
        StyleStatus() {
            return (item) => {
                let baseStyle = "color: #fff!important; font-size: 16px";
                switch (item.TrangThai) {
                    case "Chưa nấu":
                        baseStyle += "; background-color: #2196f3"; // xanh biển
                        break;
                    case "Đang nấu":
                        baseStyle += "; background-color:#f44336"; // đỏ
                        break;
                    case "Đã nấu":
                        baseStyle += "; background-color: #4caf50"; // xanh lá
                        break;
                    default:
                        baseStyle += "; background-color: #9e9e9e"; // xám mặc định
                        break;
                }
                return baseStyle;
            };
        }
    },
    methods: {
        onConfirm() {
            // this.stopBeep();
            Vue.$toast.success('Đã xác nhận!');
        },
        formatAsCurrency(value, dec) {
            dec = dec || 0
            if (value === null) {
                return 0
            }
            return "" + value.toFixed(dec).replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,")
        },
        onOpenDetail() {
            const $this = this
            const params = { HoaDonID: $this.item.HoaDonID }
            ajaxCALL("/eordertest/HoaDonChiTiet_Select_ByHoaDonId", params, (res) => {
                if (res.data) {
                    vueData.CTHoaDon = $this.item
                    vueData.DSChiTietHoaDon = res.data
                    vueData.IsShowDialogDetail = true
                }
            })
        },
        onStartCooking() {
            vueData.TabProduct = 1;  // <-- chuyển tab
        },
        onOpenOnPos() {
            const $this = this
            window.open(`/pos?chid=${$this.item.CuaHangID}&hdid=${$this.item.HoaDonID}`, "_blank")
        },
        AlertColor(trangThai) {
            switch (trangThai) {
                case "Chưa nấu":
                    return "blue darken-2"; // xanh biển
                case "Đang nấu":
                    return "red darken-2"; // đỏ
                case "Đã nấu":
                    return "green darken-2"; // xanh lá
                default:
                    return "grey darken-2";
            }
        },
        AlertIcon(trangThai) {
            switch (trangThai) {
                case "Chưa nấu":
                    return "mdi-alert-circle";
                case "Đang nấu":
                    return "mdi-fire";
                case "Đã nấu":
                    return "mdi-check-circle";
                default:
                    return "mdi-information";
            }
        }
    },
})
function redirectToPos(item) {
    const detail = item.data
    window.location.href = `/pos?chid=${detail.CuaHangID}&hdid=${detail.HoaDonID}`
}
function onOpenDetailTable(item) {
    const detail = item.data
    const params = { HoaDonID: detail.HoaDonID }
    ajaxCALL("/eordertest/HoaDonChiTiet_Select_ByHoaDonId", params, (res) => {
        if (res.data) {
            vueData.CTHoaDon = detail
            vueData.DSChiTietHoaDon = res.data
            vueData.IsShowDialogDetail = true
        }
    })
}
Vue.component("tab-history-component", {
    props: ["chid"],
    data: () => ({
        steps: [
            {
                title: "Bước 1: Nhào bột",
                description: `
                            <ul>
                                <li>Nguyên liệu: 100g bột năng, 30g đường</li>
                                <li>Thêm muối rồi trộn đều</li>
                                <li>Thời gian: 5 phút</li>
                                <li>Cách làm:</li>
                                <ol>
                                    <li>Trộn đều bột năng và đường trong một tô lớn.</li>
                                    <li>Từ từ đổ nước sôi vào (chia làm 2 – 3 lần) và trộn nhanh tay để bột không bị chín cục.</li>
                                    <li>Nhồi bột thành một khối dẻo, không dính tay.</li>
                                </ol>
                            </ul>
                            `,
                totalSeconds: 1,
                secondsLeft: 1,
                isCounting: false,
                isPaused: false,
                completed: false,
                hasConfirmed: false,
                intervalId: null,
            },
            {
                title: "Bước 2: Tạo hình trân châu",
                description: `
                            <ul>
                                <li>Thời gian: 10 – 15 phút</li>
                                <li>Cách làm:</li>
                                <ol>
                                    <li>Vo bột thành những viên nhỏ vừa ăn (khoảng 3–5mm).</li>
                                    <li>Lăn qua một ít bột năng khô để không bị dính.</li>
                                </ol>
                            </ul>
                            `,
                totalSeconds: 420,
                secondsLeft: 420,
                isCounting: false,
                isPaused: false,
                completed: false,
                hasConfirmed: false,
                intervalId: null,
            },
            {
                title: "Bước 3: Luộc trân châu tươi",
                description: `
                            <ul>
                                <li>Thời gian: 15 – 20 phút</li>
                                <li>Cách làm:</li>
                                <ol>
                                    <li>Đun sôi một nồi nước lớn.</li>
                                    <li>Cho trân châu vào, khuấy nhẹ để không dính đáy nồi.</li>
                                    <li>Luộc đến khi trân châu nổi lên và trong lại (khoảng 15–20 phút tùy kích cỡ).</li>
                                    <li>Tắt bếp, đậy nắp, ủ thêm 5 – 10 phút cho trân châu chín mềm đều.</li>
                                </ol>
                            </ul>
                            `,
                totalSeconds: 600,
                secondsLeft: 600,
                isCounting: false,
                isPaused: false,
                completed: false,
                hasConfirmed: false,
                intervalId: null,
            },
            {
                title: "Bước 4: Ủ trân châu",
                description: `
                            <ul>
                                <li>Thời gian: 2 – 5 phút</li>
                                <li>Cách làm:</li>
                                <ol>
                                    <li>Vớt trân châu ra, cho vào tô nước đá lạnh hoặc nước lọc để nguội.</li>
                                    <li>Ngâm 2 – 5 phút để trân châu không bị dính và giòn hơn.</li>
                                </ol>
                            </ul>
                            `,
                totalSeconds: 1200,
                secondsLeft: 1200,
                isCounting: false,
                isPaused: false,
                completed: false,
                hasConfirmed: false,
                intervalId: null,
             },
             {
                 title: "Bước 5: Ướp đường (tuỳ chọn)",
                 description: `
                            <ul>
                                <li>Thời gian: 10 phút</li>
                                <li>Cách làm:</li>
                                <ol>
                                    <li>Trộn trân châu với một ít nước đường nấu loãng để tăng vị ngọt và giúp bảo quản tốt hơn.</li>
                                </ol>
                            </ul>
                            `,
                totalSeconds: 300,
                secondsLeft: 300,
                isCounting: false,
                isPaused: false,
                completed: false,
                hasConfirmed: false,
                intervalId: null,
            }
            // Thêm bước mới ở đây nếu cần
        ],
        beepAudio: null,
        beepAudioReady: false,
        beepIntervalId: null,
    }),
    computed: {
        activeStepIndex() {
            return this.steps.findIndex(step => step.isCounting);
        }
    },
    template: /*html*/ `
        <div>
            <div class="page-section">
                <v-row>
                    <v-col cols="4">
                        <v-row style="height:100%; position: relative;">
                            <v-col cols="12">
                               <ul><h3><b>Thông tin chế biến</b></h3>
                                    <li><b>Nhân viên thực hiện:</b> NV00001</li>
                                    <li><b>Tên thực phẩm:</b> Trân châu tươi</li>
                                    <li><b>Thời gian chế biến:</b> 10 phút</li>
                                    <li><b>Thời gian sử dụng:</b> 3 tiếng</li>
                                    <li><b>Cảnh báo hết hạn:</b> Trước 60 phút</li>
                                    <li><b>Số lượng:</b> 30 phần</li>
                                </ul>
                                <v-img src="" aspect-ratio="1.7"></v-img>
                                <ul class="mt-3"><h3><b>Lưu ý:</b></h3>
                                    <li><b>Không nấu quá lâu:</b> trân châu tươi chỉ cần luộc khoảng 5–7 phút (tùy loại), nếu nấu quá lâu sẽ bị nhão, mất độ giòn.</li>
                                    <li><b>Ngâm nước lạnh sau khi nấu: </b> Giúp giữ độ giòn và tránh dính vào nhau.</li>
                                    <li><b>Bảo quản ngắn hạn: </b> Sau khi nấu, nên bảo quản trong nước đường hoặc siro và dùng trong vòng 4–6 tiếng để giữ độ tươi ngon.</li>
                                    <li><b>Không để tủ lạnh:</b>trân châu tươi để tủ lạnh dễ bị cứng lại và mất vị ngon.</li>
                                    <li><b>Hương vị:</b> trân châu tươi để tủ lạnh dễ bị cứng lại và mất vị ngon.</li>
                                </ul>
                            </v-col>
                            <v-col cols="12">
                                 <v-btn color="success" class="ml-2" @click="confirmAction()">
                                    <v-icon left>mdi-check</v-icon>Hoàn thành
                                </v-btn>
                            </v-col>
                        </v-row>
                    </v-col>
                    <v-col style="height:calc(100vh - 113px); border-left: 1px solid;" cols="8">
                    <h3><b>Các bước chế biến</b></h3>
                    <v-expansion-panels focusable>
                    <v-expansion-panel
                        v-for="(step, index) in steps"
                        :key="index"
                        :disabled="!isStepAvailable(index)"
                        :class="{ blinking: step.completed && !step.hasConfirmed }"
                    >
                       <v-expansion-panel-header>
                            {{ step.title }}
                            <!-- ICON: Hoàn thành -->
                            <v-icon v-if="step.hasConfirmed" color="green" class="ml-2 d-flex justify-end" small>mdi-check-circle</v-icon>
                            <!-- ICON: Cảnh báo chưa xác nhận -->
                            <v-icon
                            v-else-if="step.completed && !step.hasConfirmed"
                            color="red"
                            class="ml-2 d-flex justify-end"
                            small
                            >mdi-alert-circle</v-icon>
                            <!-- ICON: Cảnh báo chưa làm -->
                            <v-icon
                            v-else-if="!step.completed"
                            color="orange"
                            class="ml-2 d-flex justify-end"
                            small
                            >mdi-alert-circle</v-icon>
                        </v-expansion-panel-header>
                        <v-expansion-panel-content>
                        <p class="mb-2" v-html="step.description"></p>
                        <v-sheet class="d-flex justify-center" style="background-color:unset">
                            <v-progress-circular
                            :value="progressValue(step)"
                            :size="180"
                            :rotate="-90"
                            color="primary"
                            width="10"
                            >
                            <p class="mb-0 text-center font-weight-bold">
                                {{ formattedTime(step) }}
                            </p>
                            </v-progress-circular>
                        </v-sheet>
                        <div class="mt-4 text-center">
                            <v-btn
                            color="primary"
                            :disabled="step.secondsLeft !== step.totalSeconds"
                            @click="startCountdown(index)"
                            >
                                <v-icon left>mdi-play</v-icon>Bắt đầu
                            </v-btn>
                            <v-btn
                            class="ml-2"
                            :disabled="step.secondsLeft === step.totalSeconds || step.secondsLeft === 0"
                            @click="togglePause(index)"
                            >
                                <v-icon left>{{ step.isPaused ? 'mdi-play' : 'mdi-pause' }}</v-icon>
                                {{ step.isPaused ? 'Tiếp tục' : 'Tạm dừng' }}
                            </v-btn>
                            <v-btn class="ml-2" @click="refreshStep(index)">
                                <v-icon left>mdi-refresh</v-icon>Làm mới
                            </v-btn>
                            <v-btn
                            color="success"
                            class="ml-2"
                            :disabled="!step.completed || step.hasConfirmed"
                            @click="confirmAction(index)"
                            >
                                <v-icon left>mdi-check</v-icon>Hoàn thành
                            </v-btn>
                        </div>
                        </v-expansion-panel-content>
                    </v-expansion-panel>
                    </v-expansion-panels>
                    </v-col>
                </v-row>
            </div>
        </div>
    `,
    mounted() {
        this.getTableOrder()
    },
    watch: {
        chid(val) {
            this.getTableOrder()
        },
        secondsLeft(newVal) {
            if (newVal === 0) {
                this.isCounting = false;
                this.showTimeUpMessage();
                this.$emit('finished');
                clearInterval(this.intervalId);
            }
        }
    },
    beforeDestroy() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
        }
        this.stopBeep();
    },
    methods: {
        isStepAvailable(index) {
            if (index === 0) return true; // Luôn cho phép bước đầu
            return this.steps[index - 1].hasConfirmed; // Mở bước tiếp theo khi bước trước đã xác nhận
        },
        getTableOrder() {
            if (this.intervalId) {
                clearInterval(this.intervalId);
                this.intervalId = null;
            }
            this.isCounting = false;
            this.secondsLeft = 30;
            this.totalSeconds = 30;
            this.stopBeep(); // 🛑 Dừng beep khi load lại
            // Gọi API lấy dữ liệu ở đây nếu cần
        },
        showTimeUpMessage() {
            if (this.beepAudioReady && this.beepAudio) {
                this.beepIntervalId = setInterval(() => {
                    this.beepAudio.currentTime = 0;
                    this.beepAudio.play().catch(err => {
                    });
                }, 1000);
            }
            Vue.$toast.success('Hết giờ');
        },
        playBeep() {
            if (this.beepAudioReady && this.beepAudio) {
                // Tránh tạo nhiều interval trùng nhau
                if (this.beepIntervalId) return;
                this.beepIntervalId = setInterval(() => {
                    this.beepAudio.currentTime = 0;
                    this.beepAudio.play().catch(err => {
                    });
                }, 1000); // phát mỗi 1 giây
            }
        },
        stopBeep() {
            if (this.beepAudio) {
                this.beepAudio.pause();
                this.beepAudio.currentTime = 0;
            }
            if (this.beepIntervalId) {
                clearInterval(this.beepIntervalId);
                this.beepIntervalId = null;
            }
        },
        startCountdown(index) {
            const step = this.steps[index];
            if (step.isCounting || step.secondsLeft !== step.totalSeconds) return;
            step.isCounting = true;
            step.isPaused = false;
            if (!this.beepAudio) {
                this.beepAudio = new Audio('/_cdn/zen-eorder/beep.mp3');
                this.beepAudio.load();
                this.beepAudioReady = true;
            }
            step.intervalId = setInterval(() => {
                if (step.isPaused) return;
                if (step.secondsLeft > 1) {
                    step.secondsLeft--;
                } else if (step.secondsLeft === 1) {
                    step.secondsLeft = 0;
                    clearInterval(step.intervalId);
                    step.isCounting = false;
                    step.completed = true;
                    this.playBeep();
                }
            }, 1000);
        },
        confirmAction(index) {
            const step = this.steps[index];
            if (!step.completed || step.hasConfirmed) return;
            step.hasConfirmed = true;
            this.stopBeep();
            Vue.$toast.success('Xác nhận hoàn thành bước!');
        },
        togglePause(index) {
            const step = this.steps[index];
            if (!step.isCounting || step.secondsLeft === 0) return;
            step.isPaused = !step.isPaused;
        },
        refreshStep(index) {
            const step = this.steps[index];
            clearInterval(step.intervalId);
            step.secondsLeft = step.totalSeconds;
            step.isCounting = false;
            step.isPaused = false;
            step.completed = false;
            step.hasConfirmed = false;
        },
        formattedTime(step) {
            const hrs = Math.floor(step.secondsLeft / 3600);
            const mins = Math.floor((step.secondsLeft % 3600) / 60);
            const secs = step.secondsLeft % 60;
            return `${String(hrs).padStart(2, '0')}:${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
        },
        progressValue(step) {
            return Math.min(100, Math.round(((step.totalSeconds - step.secondsLeft) / step.totalSeconds) * 100));
        },
        beforeDestroy() {
            this.steps.forEach(step => {
                if (step.intervalId) clearInterval(step.intervalId);
            });
            this.stopBeep();
        }
    }
})